local addonName, addonTable = ...;
_G[addonName] = addonTable;

--- @type RotationHelper
if not RotationHelper then return end

local RotationHelper = RotationHelper;

local Warrior = RotationHelper:NewModule('Warrior');
addonTable.Warrior = Warrior;

Warrior.spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
}

function Warrior:Enable()
   local specFunctions = {
      [1] = {
         Name = 'Warrior - Arms',
      	NextSpell = Warrior.Arms,
         AfterNextSpell = Warrior.ArmsAfterSpell,
         EnrichFrameData = Warrior.ArmsPrep,
      },
      [2] = {
         Name = 'Warrior - Fury',
         NextSpell = Warrior.Fury,
         AfterNextSpell = Warrior.FuryAfterSpell,
         EnrichFrameData = Warrior.FuryPrep,
      },
   };
   
	Warrior.playerLevel = UnitLevel('player');
   RotationHelper.ModuleRef = specFunctions[RotationHelper.Spec];
   return RotationHelper.ModuleRef ~= nil;
end
