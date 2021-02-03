local addonName, addonTable = ...;
_G[addonName] = addonTable;

--- @type RotationHelper
if not RotationHelper then return end

local RotationHelper = RotationHelper;
local Monk = RotationHelper:NewModule('Monk');
addonTable.Monk = Monk;

-- Auras
local _HitComboAura = 196741;
local _BlackoutKickAura = 116768;
local _RushingJadeWindAura = 148187;

Monk.spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
}

function Monk:Enable()
   local specFunctions = {
      -- [3] = {
      --    Name = 'Monk - Windwalker',
      -- 	NextSpell = Monk.Windwalker,
      --    AfterNextSpell = Monk.WindwalkerAfterSpell,
      --    EnrichFrameData = Monk.WindwalkerPrep,
      -- },
   };

	Monk.playerLevel = UnitLevel('player');
   RotationHelper.ModuleRef = specFunctions[RotationHelper.Spec];
   return RotationHelper.ModuleRef ~= nil;
end
