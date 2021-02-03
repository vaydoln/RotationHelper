local addonName, addonTable = ...;
_G[addonName] = addonTable;

--- @type RotationHelper
if not RotationHelper then return end
local RotationHelper = RotationHelper;
local UnitPower = UnitPower;

local Druid = RotationHelper:NewModule('Druid', 'AceEvent-3.0');
addonTable.Druid = Druid;

Druid.spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
}

function Druid:Enable()
   local specFunctions = {
      [1] = {
         Name = 'Druid - Balance',
         NextSpell = Druid.Balance,
         AfterNextSpell = Druid.BalanceStep,
         EnrichFrameData = Druid.BalancePrep,
      },
      -- [2] = {
      --    Name = 'Druid - Feral',
      -- 	NextSpell = Druid.Feral,
      --    EnrichFrameData = Druid.FeralPrep,
      -- },
   };

	Druid.playerLevel = UnitLevel('player');
   RotationHelper.ModuleRef = specFunctions[RotationHelper.Spec];

	Druid:UnregisterEvent('UNIT_SPELLCAST_SUCCEEDED');
   if RotationHelper.Spec == 2 then
      Druid:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED');
      return true;
   end

   return RotationHelper.ModuleRef ~= nil;
end
