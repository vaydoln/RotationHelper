local addonName, RotationHelper = ...;

LibStub('AceAddon-3.0'):NewAddon(RotationHelper, 'RotationHelper', 'AceConsole-3.0', 'AceEvent-3.0', 'AceTimer-3.0');

--- @class RotationHelper
_G[addonName] = RotationHelper;

local TableInsert = tinsert;
local TableRemove = tremove;
local TableContains = tContains;
local TableIndexOf = tIndexOf;

local UnitIsFriend = UnitIsFriend;
local IsPlayerSpell = IsPlayerSpell;
local UnitClass = UnitClass;
local GetSpecialization = GetSpecialization;
local CreateFrame = CreateFrame;
local GetAddOnInfo = GetAddOnInfo;
local IsAddOnLoaded = IsAddOnLoaded;
local LoadAddOn = LoadAddOn;
local GetTime = GetTime;

local spellHistoryBlacklist = {
	[75] = true; -- Auto shot
};

function RotationHelper:OnInitialize()
   self.db = LibStub('AceDB-3.0'):New('RotationHelperOptions', self.defaultOptions);

	self:AddToBlizzardOptions();
end

function RotationHelper:GetTexture()
	self.FinalTexture = self.db.global.texture;
	if self.FinalTexture == '' or self.FinalTexture == nil then
		self.FinalTexture = 'Interface\\Cooldown\\ping4';
	end

	return self.FinalTexture;
end

RotationHelper.DefaultPrint = RotationHelper.Print;
function RotationHelper:Print(...)
	if self.db.global.disabledInfo then
		return
	end

	RotationHelper:DefaultPrint(...);
end

RotationHelper.profilerStatus = 0;
function RotationHelper:ProfilerStart()
	local profiler = self:GetModule('Profiler');
	profiler:StartProfiler();
	self.profilerStatus = 1;
end

function RotationHelper:ProfilerStop()
	local profiler = self:GetModule('Profiler');
	profiler:StopProfiler();
	self.profilerStatus = 0;
end

function RotationHelper:ProfilerToggle()
	if self.profilerStatus == 0 then
		self:ProfilerStart();
	else
		self:ProfilerStop();
	end
end

function RotationHelper:OnEnable()
	self:RegisterEvent('PLAYER_TARGET_CHANGED');
	self:RegisterEvent('PLAYER_TALENT_UPDATE');
	self:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED');
	self:RegisterEvent('PLAYER_REGEN_DISABLED');
	self:RegisterEvent('AZERITE_ESSENCE_ACTIVATED');

	self:RegisterEvent('UNIT_ENTERED_VEHICLE');
	self:RegisterEvent('UNIT_EXITED_VEHICLE');

	self:RegisterEvent('NAME_PLATE_UNIT_ADDED');
	self:RegisterEvent('NAME_PLATE_UNIT_REMOVED');

	if not self.playerUnitFrame then
		self.spellHistory = {};

		self.playerUnitFrame = CreateFrame('Frame');
		self.playerUnitFrame:RegisterUnitEvent('UNIT_SPELLCAST_SUCCEEDED', 'player');
		self.playerUnitFrame:SetScript('OnEvent', function(_, _, _, _, spellId)
			-- event, unit, lineId
			if IsPlayerSpell(spellId) and not spellHistoryBlacklist[spellId] then
				TableInsert(self.spellHistory, 1, spellId);

				if #self.spellHistory > 5 then
					TableRemove(self.spellHistory);
				end
			end
		end);
	end

	self:Print(self.Colors.Info .. 'Initialized');
end

RotationHelper.visibleNameplates = {};
function RotationHelper:NAME_PLATE_UNIT_ADDED(_, nameplateUnit)
	if not TableContains(self.visibleNameplates, nameplateUnit) then
		TableInsert(self.visibleNameplates, nameplateUnit);
	end
end

function RotationHelper:NAME_PLATE_UNIT_REMOVED(_, nameplateUnit)
	local index = TableIndexOf(self.visibleNameplates, nameplateUnit);
	if index ~= nil then
		TableRemove(self.visibleNameplates, index)
	end
end

function RotationHelper:PLAYER_TALENT_UPDATE()
	self:DisableRotation();
end

function RotationHelper:PLAYER_SPECIALIZATION_CHANGED()
	self:DisableRotation();
end

function RotationHelper:AZERITE_ESSENCE_ACTIVATED()
	self:DisableRotation();
end

function RotationHelper:UNIT_ENTERED_VEHICLE(_, unit)
	if unit == 'player' and self.rotationEnabled then
		self:DisableRotation();
	end
end

function RotationHelper:UNIT_EXITED_VEHICLE(_, unit)
	if unit == 'player' then
		self:MaybeInitRotations(false);
	end
end

function RotationHelper:PLAYER_TARGET_CHANGED()
   self:MaybeInitRotations(false);

	if self.rotationEnabled then
      self:InvokeNextSpell();
	end
end

function RotationHelper:PLAYER_REGEN_DISABLED()
   self:MaybeInitRotations(true);
end

function RotationHelper:copyTableValues(srcTable)
   if (srcTable) then
      local dstTable = {};
      for k, v in pairs(srcTable) do
         dstTable[k] = v;
      end
      return dstTable;
   else
      return nil;
   end
end

function RotationHelper:PrepareFrameData()
   local FrameData = {};
   FrameData.tempCooldowns = {};
   FrameData.tempDots = {};

	FrameData.timeShift, FrameData.currentSpell, FrameData.gcdRemains = RotationHelper:EndCast();
   FrameData.buff, FrameData.debuff = RotationHelper:CollectAuras(FrameData.timeShift);
	FrameData.gcd = self:GlobalCooldown();
   
	-- FrameData.buff, FrameData.debuff = RotationHelper:CollectAuras(FrameData.timeShift);
   FrameData.cooldown  = setmetatable({}, {
      __index = function(table, key)
         if (FrameData.tempCooldowns[key] ~= nil) then
            return FrameData.tempCooldowns[key];
         end
         return RotationHelper:CooldownConsolidated(key, FrameData.timeShift);
      end
   });

	FrameData.talents = self.PlayerTalents;
	FrameData.azerite = self.AzeriteTraits;
	FrameData.essences = self.AzeriteEssences;
	FrameData.covenant = self.CovenantInfo;
	FrameData.runeforge = self.LegendaryBonusIds;
	FrameData.spellHistory = self:copyTableValues(self.spellHistory);
   FrameData.timeToDie = self:GetTimeToDie();

   if (self.ModuleRef.EnrichFrameData ~= nil) then
      FrameData = self.ModuleRef:EnrichFrameData(FrameData);
   end

   return FrameData;
end

function RotationHelper:InvokeNextSpell()
   local enabled = UnitExists("target")
      and (not UnitIsFriend('player', 'target')) 
      and (not UnitIsDead('target'));

   if (enabled) then
      local FrameData = self:PrepareFrameData();
      self:RecurseNextSpell(FrameData, 1, 3);
   else
      self:ClearRemainingSpells(1, 3);
   end
end

function RotationHelper:RecurseNextSpell(FrameData, Index, MaxDepth)
   FrameData.recurseIndex = Index;

   -- invoke spell check
   local newSkill = self.ModuleRef:NextSpell(FrameData);
   self:GlowSpell(Index, newSkill.id);

   if (Index < MaxDepth) then
      FrameData = self:UseNextSpell(FrameData, newSkill);
      if (FrameData ~= nil) then
         self:RecurseNextSpell(FrameData, Index + 1, MaxDepth);
      else
         self:ClearRemainingSpells(Index + 1, MaxDepth);
      end
   end
end

function RotationHelper:ClearRemainingSpells(Index, MaxDepth)
   self:GlowClear(Index);

   if (Index < MaxDepth) then
      self:ClearRemainingSpells(Index + 1, MaxDepth);
   end
end

function RotationHelper:UseNextSpell(FrameData, Spell)
   if (Spell and Spell.id) then
      if (Spell.updateFrameData) then
         FrameData = Spell.updateFrameData(FrameData);
      end

      FrameData = self:updateFrameDataCommon(FrameData, Spell);

      if (self.ModuleRef.AfterNextSpell) then
         FrameData = self.ModuleRef:AfterNextSpell(FrameData);
      end
   else
      FrameData = nil;
   end

   return FrameData;
end

function RotationHelper:updateFrameDataCommon(FrameData, Spell)
   local castTime = FrameData.gcd;

   local spellInfo = GetSpellInfo(Spell.id);
   if (spellInfo and spellInfo.castTime) then
      castTime = max(FrameData.gcd, spellInfo.castTime);
   end

   FrameData.currentSpell = Spell.id;
   FrameData.timeShift = FrameData.timeShift + castTime;
   FrameData.removedAuras = {};
   FrameData.buff = self:advanceAuras(FrameData.buff, FrameData.timeShift, FrameData.removedAuras);
   FrameData.debuff = self:advanceAuras(FrameData.debuff, FrameData.timeShift, FrameData.removedAuras);

   TableInsert(FrameData.spellHistory, 1, Spell.id);
   if #FrameData.spellHistory > 5 then
      TableRemove(FrameData.spellHistory);
   end

   return FrameData;
end

function RotationHelper:advanceAuras(auraSet, timeShift, removedAuras)
   for spellId, aura in pairs(auraSet) do
      if (aura.remains < timeShift) then
         auraSet = self:removeAura(auraSet, spellId);
         removedAuras[spellId] = true;
      end
   end
   return auraSet;
end

function RotationHelper:normalCooldownEffect(spellId)
   return function(fd)
      return RotationHelper:startCooldown(fd, spellId);
   end
end

function RotationHelper:normalAddSelfBuff(spellId)
   return function(fd)
      return RotationHelper:addSelfBuff(fd, spellId);
   end
end

function RotationHelper:normalAddTargetDebuff(spellId)
   return function(fd)
      return RotationHelper:addTargetDebuff(fd, spellId);
   end
end

function RotationHelper:startCooldown(FrameData, spellId)
   local cd = FrameData.tempCooldowns[spellId];
   if (cd == nil) then
      cd = RotationHelper:CooldownConsolidated(spellId, FrameData.timeShift);
   end

   local duration = (cd.duration == 0 and 20) or cd.duration;
   if (cd.charges == nil) then
      cd.ready = false;
      cd.remains = duration;
		cd.fullRecharge = duration;
		cd.partialRecharge = duration;
   elseif (cd.charges == cd.maxCharges) then
      cd.charges = cd.charges - 1;
      cd.ready = cd.charges >= 1;
      cd.remains = duration;
		cd.fullRecharge = duration;
		cd.partialRecharge = duration;
   else
      cd.charges = cd.charges - 1;
      cd.ready = cd.charges >= 1;
		cd.fullRecharge = cd.fullRecharge + duration;
   end

   FrameData.tempCooldowns[spellId] = cd;
   return FrameData;
end

function RotationHelper:reduceCooldown(FrameData, spellId, seconds)
   local cd = FrameData.tempCooldowns[spellId];
   if (cd == nil) then
      cd = RotationHelper:CooldownConsolidated(spellId, FrameData.timeShift);
   end

   if (cd.charges == nil) then
      cd.remains = cd.remains - seconds;
      cd.fullRecharge = cd.fullRecharge - seconds;
      cd.partialRecharge = cd.partialRecharge - seconds;
      cd.ready = cd.remains <= 0;
   elseif (cd.charges < cd.maxCharges) then
      local tempRemains = cd.remains - seconds;

      if (tempRemains <= 0) then
         cd.charges = min(cd.maxCharges, cd.charges + 1);

         if (cd.charges < cd.maxCharges) then
            cd.partialRecharge = cd.partialRecharge - seconds + cd.duration;
            cd.fullRecharge = cd.fullRecharge - seconds;
         else
            cd.remains = 0;
            cd.fullRecharge = 0;
            cd.partialRecharge = 0;
         end
      else
         cd.remains = cd.remains - seconds;
         cd.partialRecharge = cd.partialRecharge - seconds;
         cd.fullRecharge = cd.fullRecharge - seconds;
      end
   end

   FrameData.tempCooldowns[spellId] = cd;
   return FrameData;
end

function RotationHelper:endCooldown(FrameData, spellId, chargesGranted)
   if (chargesGranted == nil) then
      chargesGranted = 1;
   end

   local cd = FrameData.tempCooldowns[spellId];
   if (cd == nil) then
      cd = RotationHelper:CooldownConsolidated(spellId, FrameData.timeShift);
   end

   if (cd.charges == nil) then
      cd.ready = true;
      cd.remains = 0;
      cd.fullRecharge = 0;
      cd.partialRecharge = 0;
   elseif (cd.charges < cd.maxCharges) then
      cd.charges = min(cd.maxCharges, cd.charges + chargesGranted);
      if (cd.charges < cd.maxCharges) then
		   cd.fullRecharge = cd.fullRecharge - cd.duration;
      else
         cd.remains = 0;
         cd.fullRecharge = 0;
         cd.partialRecharge = 0;
      end
   end

   FrameData.tempCooldowns[spellId] = cd;
   return FrameData;
end

function RotationHelper:addSelfBuff(FrameData, spellId, count)
   FrameData.buff = self:addAura(FrameData.buff, spellId, nil, nil, count);
   return FrameData;
end

function RotationHelper:removeSelfBuff(FrameData, spellId, count)
   FrameData.buff = self:removeAura(FrameData.buff, spellId, count);
   return FrameData;
end

function RotationHelper:addTargetDebuff(FrameData, spellId, count)
   FrameData.debuff = self:addAura(FrameData.debuff, spellId, nil, nil, count);
   return FrameData;
end

function RotationHelper:removeTargetDebuff(FrameData, spellId, count)
   FrameData.debuff = self:removeAura(FrameData.debuff, spellId, count);
   return FrameData;
end

function RotationHelper:addAura(auraSet, spellId, duration, resetDuration, count)
   if (resetDuration == nil) then
      resetDuration = true;
   end

   -- just picking a time, we could look it up but this is fake anyways
   local defaultDuration = duration or 20;
   local defaultCount = count or 1;

   local aura = auraSet[spellId];
   if (aura ~= nil) then
      aura.up = true;
      aura.refreshable = false;
      if (resetDuration) then
         if (aura.duration ~= nil and aura.duration > 0) then
            aura.remains = aura.duration;
         else
            aura.remains = defaultDuration;
         end
      end
      aura.count = aura.count + defaultCount;
   else
      local t = GetTime();
      aura = {
         name           = 'dummy',
         up             = true,
         upMath         = defaultCount,
         count          = defaultCount,
         expirationTime = t + defaultDuration,
         remains        = defaultDuration,
         duration       = defaultDuration,
         refreshable    = false,
      };
   end

   auraSet[spellId] = aura;
   return auraSet;
end

function RotationHelper:removeAura(auraSet, spellId, count)
   local defaultCount = count or 1;

   local aura = auraSet[spellId];
   if (aura ~= nil and aura.up) then
      aura.count = max(0, aura.count - defaultCount);
      if (aura.count <= 0) then
         aura.up = false;
         aura.remains = 0;
         aura.refreshable = true;
      end
   end

   auraSet[spellId] = aura;
   return auraSet;
end

function RotationHelper:MaybeInitRotations(fromCombat)
   if (not self.rotationEnabled) then
      if (fromCombat or (not self.db.global.onCombatEnter)) then
         self:InitRotations();
         self:EnableRotation();
      end
   end
end

function RotationHelper:InitRotations()
	self:Print(self.Colors.Info .. 'Initializing rotations');

	local _, _, classId = UnitClass('player');
	local spec = GetSpecialization();
	self.ClassId = classId;
	self.Spec = spec;

	self:LoadModule();
end

function RotationHelper:LoadModule()
	if self.Classes[self.ClassId] == nil then
		self:Print(self.Colors.Error .. 'Unsupported player class.');
		return
	end

	local className = self.Classes[self.ClassId];
   self:EnableRotationModule(className);
end

function RotationHelper:EnableRotationModule(className)
   self.ModuleRef = nil;
   
	local loaded = self:EnableModule(className);
	if (loaded) then
		self:Print(self.Colors.Info .. 'Loaded module ' .. className);
	else
		self:Print(self.Colors.Error .. 'Could not load module ' .. className);
	end
end

function RotationHelper:EnableRotation()
	if self.ModuleRef == nil or self.rotationEnabled then
		self:Print(self.Colors.Error .. 'Failed to enable addon!');
		return
   end

   self:Print(self.Colors.Info .. 'Enabled rotation: ' .. self.ModuleRef.Name);

	self:CheckTalents();
	self:GetAzeriteTraits();
	self:GetAzeriteEssences();
	self:GetCovenantInfo();
	self:GetLegendaryEffects();
	self:CheckIsPlayerMelee();
	if self.ModuleOnEnable then
		self.ModuleOnEnable();
	end

	self:EnableRotationTimer();

	self.rotationEnabled = true;
end

function RotationHelper:EnableRotationTimer()
	self.RotationTimer = self:ScheduleRepeatingTimer('InvokeNextSpell', self.db.global.interval);
end

function RotationHelper:DisableRotation()
	if not self.rotationEnabled then
		return
	end

	self:DisableRotationTimer();

	self:HideAllOverlays();
	self:Print(self.Colors.Info .. 'Disabling');

	self.rotationEnabled = false;
end

function RotationHelper:DisableRotationTimer()
	if self.RotationTimer then
		self:CancelTimer(self.RotationTimer);
	end
end
