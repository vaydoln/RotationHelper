local addonName, addonTable = ...;
_G[addonName] = addonTable;

--- @type RotationHelper
if not RotationHelper then return end

local RotationHelper = RotationHelper;

local DemonHunter = RotationHelper:NewModule('DemonHunter');
addonTable.DemonHunter = DemonHunter;

DemonHunter.spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
}

function DemonHunter:Enable()
   local specFunctions = {
      [1] = {
         Name = 'DemonHunter - Havoc';
         NextSpell = DemonHunter.Havoc;
         -- AfterNextSpell = DemonHunter.HavocAfterSpell;
         EnrichFrameData = DemonHunter.HavocPrep;
      },
   };

   DemonHunter.playerLevel = UnitLevel('player');
   RotationHelper.ModuleRef = specFunctions[RotationHelper.Spec];
   return RotationHelper.ModuleRef ~= nil;
end
