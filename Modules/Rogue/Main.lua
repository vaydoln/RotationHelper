local addonName, addonTable = ...;
_G[addonName] = addonTable;

--- @type RotationHelper
if not RotationHelper then return end
local RotationHelper = RotationHelper;
local Rogue = RotationHelper:NewModule('Rogue');
addonTable.Rogue = Rogue;

Rogue.spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
}

function Rogue:Enable()
   local specFunctions = {
      -- [1] = {
      --    Name = 'Rogue - Assassination',
      -- 	NextSpell = Rogue.Assassination,
      --    AfterNextSpell = Rogue.AssassinationAfterSpell,
      --    EnrichFrameData = Rogue.AssassinationPrep,
      -- },
      -- [2] = {
      --    Name = 'Rogue - Outlaw',
      -- 	NextSpell = Rogue.Outlaw,
      --    AfterNextSpell = Rogue.OutlawAfterSpell,
      --    EnrichFrameData = Rogue.OutlawPrep,
      -- },
      -- [3] = {
      --    Name = 'Rogue - Subtlety',
      -- 	NextSpell = Rogue.Subtlety,
      --    AfterNextSpell = Rogue.SubtletyAfterSpell,
      --    EnrichFrameData = Rogue.SubtletyPrep,
      -- },
   };

	Rogue:InitializeDatabase();
	Rogue:CreateConfig();
	Rogue.playerLevel = UnitLevel('player');

   RotationHelper.ModuleRef = specFunctions[RotationHelper.Spec];
   return RotationHelper.ModuleRef ~= nil;
end
