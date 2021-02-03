local addonName, addonTable = ...;
_G[addonName] = addonTable;

--- @type RotationHelper
if not RotationHelper then return end

local RotationHelper = RotationHelper;
local Mage = RotationHelper:NewModule('Mage', 'AceEvent-3.0');
addonTable.Mage = Mage;

Mage.spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
}

function Mage:Enable()
   local specFunctions = {
      -- [1] = {
      --    Name = 'Mage - Arcane',
      -- 	NextSpell = Mage.Arcane,
      --    AfterNextSpell = Mage.ArcaneAfterSpell,
      --    EnrichFrameData = Mage.ArcanePrep,
      -- },
      -- [2] = {
      --    Name = 'Mage - Fire',
      -- 	NextSpell = Mage.Fire,
      --    AfterNextSpell = Mage.FireAfterSpell,
      --    EnrichFrameData = Mage.FirePrep,
      -- },
      [3] = {
         Name = 'Mage - Frost',
         NextSpell = Mage.Frost,
         AfterNextSpell = Mage.FrostAfterSpell,
         EnrichFrameData = Mage.FrostPrep,
      },
   };

	Mage.playerLevel = UnitLevel('player');
   RotationHelper.ModuleRef = specFunctions[RotationHelper.Spec];

   Mage:UnregisterEvent('UNIT_SPELLCAST_SUCCEEDED');
	if RotationHelper.Spec == 3 then
		Mage:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED');
   end

   return RotationHelper.ModuleRef ~= nil;
end

function Mage:Disable()
	self:UnregisterAllEvents();
end

