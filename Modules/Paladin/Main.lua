local addonName, addonTable = ...;
_G[addonName] = addonTable;

if not RotationHelper then return end

--- @type RotationHelper
local RotationHelper = RotationHelper;
local Paladin = RotationHelper:NewModule('Paladin');
addonTable.Paladin = Paladin;

Paladin.spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
}

function Paladin:Enable()
   local specFunctions = {
      -- [3] = {
      --    Name = 'Paladin - Retribution',
      -- 	NextSpell = Paladin.Retribution,
      --    AfterNextSpell = Paladin.RetributionAfterSpell,
      --    EnrichFrameData = Paladin.RetributionPrep,
      -- },
   };

	Paladin.playerLevel = UnitLevel('player');
   RotationHelper.ModuleRef = specFunctions[RotationHelper.Spec];
   return RotationHelper.ModuleRef ~= nil;
end
