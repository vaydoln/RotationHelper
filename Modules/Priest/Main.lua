local addonName, addonTable = ...;
_G[addonName] = addonTable;

--- @type RotationHelper
if not RotationHelper then return end

local RotationHelper = RotationHelper;

local Priest = RotationHelper:NewModule('Priest');
addonTable.Priest = Priest;

Priest.spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
};

function Priest:Enable()
   local specFunctions = {
      -- [3] = {
      --    Name = 'Priest - Shadow',
      -- 	NextSpell = Priest.Shadow,
      --    AfterNextSpell = Priest.ShadowAfterSpell,
      --    EnrichFrameData = Priest.ShadowPrep,
      -- },
   };

	Priest.playerLevel = UnitLevel('player');
   RotationHelper.ModuleRef = specFunctions[RotationHelper.Spec];
   return RotationHelper.ModuleRef ~= nil;
end
