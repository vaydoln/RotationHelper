local _, addonTable = ...;

--- @type RotationHelper
if not RotationHelper then return end

local RotationHelper = RotationHelper;
local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;
local GetPowerRegen = GetPowerRegen;
local InCombatLockdown = InCombatLockdown;
local ComboPoints = Enum.PowerType.ComboPoints;
local Energy = Enum.PowerType.Energy;
local Rogue = addonTable.Rogue;

local SB = {
	Shadowstrike		= 185438,
	Stealth				= 1784,
	SliceAndDice		= 315496,
	Rupture				= 1943,
	Eviscerate			= 196819,
	Backstab			= 53,
	ShadowDance			= 185313,
	ShadowDanceBuff		= 185422,
	Gloomblade			= 200758,
	SymbolsOfDeath		= 212283,
	ShurikenStorm		= 197835,
	MarkedForDeath		= 137619,
};

setmetatable(SB, Rogue.spellMeta);

function Rogue:createSubtletyEffectsTable()
   local effects = {};

   -- TODO: spec - sub rogue

   -- effects[SB.BarbedShot] = function(fd)
   --    fd = RotationHelper:startCooldown(fd, SB.BarbedShot);
   --    fd = RotationHelper:reduceCooldown(fd, SB.BestialWrath, 12);
   --    fd = RotationHelper:addTargetDebuff(fd, SB.BarbedShotAura);
   --    return fd;
   -- end

   -- effects[SB.Multishot] = function(fd)
   --    fd.focus = fd.focus - 40;
   --    return fd;
   -- end

   -- effects[SB.ResonatingArrow] = RotationHelper:normalCooldownEffect(SB.ResonatingArrow);

   return effects;
end

local SBEffect = Rogue:createSubtletyEffectsTable();

function Rogue:SubtletyAfterSpell(fd)
   return fd;
end

function Rogue:SubtletyPrep(fd)
	fd.energy = UnitPower('player', 3);
	fd.energyMax = UnitPowerMax('player', 3);
	fd.energyDeficit = fd.energyMax - fd.energy;
	fd.energyRegen = GetPowerRegen();
	fd.combo = UnitPower('player', 4);
	fd.comboMax = UnitPowerMax('player', 4);
	fd.comboDeficit = fd.comboMax - fd.combo;
	fd.targets = RotationHelper:SmartAoe();

   if (fd.currentSpell and SBEffect[fd.currentSpell]) then
      local updateFrameData = SBEffect[fd.currentSpell];
      fd = updateFrameData(fd);
   end

	RotationHelper:GlowEssences(fd);

   return fd;
end

function Rogue:Subtlety(fd)
   local spellId = Rogue:chooseSubtletySpellId(fd);
   local retVal = {
      id = spellId,
   };

   if (spellId and SBEffect[spellId]) then
      retVal.updateFrameData = SBEffect[spellId];
   end

   return retVal;
end

function Rogue:chooseSubtletySpellId(fd)
	if fd.targets >= 2 then
		return Rogue:SubtletyAOE(fd);
	end
	return Rogue:SubtletySingle(fd);
end

function Rogue:SubtletySingle(fd)
   local cooldown = fd.cooldown;
   local buff = fd.buff;
   local debuff = fd.debuff;
   local talents = fd.talents;
	local energy = fd.energy;
	local comboDeficit = fd.comboDeficit;

	--if cooldown[SB.MarkedForDeath].up and comboDeficit >= 4 and talents[SB.MarkedForDeath] then
	if talents[SB.MarkedForDeath] and cooldown[SB.MarkedForDeath].ready then
		return SB.MarkedForDeath;
	end
	if buff[SB.Stealth].up and energy >= 40 then
		return SB.Shadowstrike;
	end
	if cooldown[SB.ShadowDance].ready and not buff[SB.ShadowDanceBuff].up then
		return SB.ShadowDance;
	end
	if buff[SB.SliceAndDice].refreshable and comboDeficit == 0 and energy >= 25 then
		return SB.SliceAndDice;
	end
	if debuff[SB.Rupture].refreshable and comboDeficit == 0 and energy >= 25 then
		return SB.Rupture;
	end
	--SYMBOLS OF DEATH AND SECRET TECHNIQUE SYNERGY
	if comboDeficit == 0 and energy >= 35 then
		return SB.Eviscerate;
	end
	if buff[SB.ShadowDanceBuff].up and cooldown[SB.SymbolsOfDeath].ready then
		return SB.SymbolsOfDeath;
	end
	if buff[SB.ShadowDanceBuff].up and energy >= 65 then
		return SB.Shadowstrike;
	end
	if comboDeficit > 0 and energy >= 65 and not talents[SB.Gloomblade] then
		return SB.Backstab;
	end
	if comboDeficit > 0 and energy >= 65 and talents[SB.Gloomblade] then
		return SB.Gloomblade;
	end
end

function Rogue:SubtletyAOE(fd)
   local cooldown = fd.cooldown;
   local buff = fd.buff;
   local debuff = fd.debuff;
	local energy = fd.energy;
	local comboDeficit = fd.comboDeficit;
	local targets = fd.targets;

   if buff[SB.SliceAndDice].refreshable and comboDeficit == 0 and energy >= 25 and targets < 6 then
		return SB.SliceAndDice;
	end
	if debuff[SB.Rupture].refreshable and comboDeficit == 0 and energy >= 25 and targets < 6 then
		return SB.Rupture;
	end
	if targets >= 4 and cooldown[SB.SymbolsOfDeath].ready then
		return SB.SymbolsOfDeath;
	end
	if energy > 35 then
		return SB.ShurikenStorm;
	end
end