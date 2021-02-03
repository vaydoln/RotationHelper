local addonName, addonTable = ...;
_G[addonName] = addonTable;

--- @type RotationHelper
if not RotationHelper then return end
local RotationHelper = RotationHelper;
local IsActionInRange = IsActionInRange;
local GetPowerRegen = GetPowerRegen;
local UnitPowerMax = UnitPowerMax;
local UnitPower = UnitPower;
local GetActionInfo = GetActionInfo;
local TableContains = tContains;
local PowerTypeFocus = Enum.PowerType.Focus;
local ipairs = ipairs;
local select = select;

local Hunter = RotationHelper:NewModule('Hunter');
addonTable.Hunter = Hunter;

Hunter.spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
}

local _PetBasics = {
	49966, -- Smack
	16827, -- Claw
	17253 -- Bite
}

function Hunter:Enable()
   local specFunctions = {
      [1] = {
         Name = 'Hunter - Beast Mastery',
         NextSpell = Hunter.BeastMastery,
         AfterNextSpell = Hunter.AdvancePetAuras,
         EnrichFrameData = Hunter.BeastMasteryPrep,
      },
      [2] = {
         Name = 'Hunter - Marksmanship',
         NextSpell = Hunter.Marksmanship,
         AfterNextSpell = Hunter.AdvancePetAuras,
         EnrichFrameData = Hunter.MarksmanshipPrep,
      },
      -- [3] = {
      --    Name = 'Hunter - Survival',
      -- 	NextSpell = Hunter.Survival,
      --    AfterNextSpell = Hunter.AdvancePetAuras,
      --    EnrichFrameData = Hunter.SurvivalPrep,
      -- },
   };

	Hunter:InitializeDatabase();
	Hunter:CreateConfig();

	Hunter.playerLevel = UnitLevel('player');
   RotationHelper.ModuleRef = specFunctions[RotationHelper.Spec];
   return RotationHelper.ModuleRef ~= nil;
end

function Hunter:AdvancePetAuras(fd)
   if (fd.pet) then
      fd.pet = RotationHelper:advanceAuras(fd.pet, fd.timeShift, fd.removedAuras);
   end
   return fd;
end

function Hunter:Focus(minus, timeShift)
	local casting = GetPowerRegen();
	local powerMax = UnitPowerMax('player', PowerTypeFocus);
	local power = UnitPower('player', PowerTypeFocus); -- + (casting * timeShift)
	if power > powerMax then
		power = powerMax;
	end ;
	power = power - minus;
	return power, powerMax, casting;
end

function Hunter:FocusTimeToMax(fd)
	local regen = GetPowerRegen();

	local ttm = (fd.focusMax - fd.focus) / regen;
	if ttm < 0 then
		ttm = 0;
	end

	return ttm;
end

local function isHunterPetBasic(slot)
	local id = select(2, GetActionInfo(slot));
	return TableContains(_PetBasics, id);
end

function Hunter:FindPetBasicSlot()
	if self.PetBasicSlot and isHunterPetBasic(self.PetBasicSlot) then
		return self.PetBasicSlot;
	end

	for slot = 1, 120 do
		if isHunterPetBasic(slot) then
			self.PetBasicSlot = slot;
			return slot;
		end
	end

	return nil;
end

-- Requires a pet's basic ability to be on an action bar somewhere.
local lastWarning;
function Hunter:TargetsInPetRange()
	local slot = self:FindPetBasicSlot();

	if slot == nil then
		local t = GetTime();
		if not lastWarning or t - lastWarning > 5 then
			RotationHelper:Print(RotationHelper.Colors.Error .. 'At lest one pet basic ability needs to be on YOUR action bar (One of those: Smack, Claw, Bite).');
			RotationHelper:Print(RotationHelper.Colors.Error .. 'Read this for more information: goo.gl/ZF6FXt');
			lastWarning = t;
		end
		return 1;
	end

	local count = 0;
	for _, unit in ipairs(RotationHelper.visibleNameplates) do
		if IsActionInRange(slot, unit) then
			count = count + 1;
		end
	end

	return count;
end