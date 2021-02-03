local addonName, addonTable = ...;
_G[addonName] = addonTable;

--- @type RotationHelper
if not RotationHelper then return end
local RotationHelper = RotationHelper;
local GetSpellInfo = GetSpellInfo;
local GetTotemInfo = GetTotemInfo;
local GetTime = GetTime;

local Shaman = RotationHelper:NewModule('Shaman');
addonTable.Shaman = Shaman;

Shaman.spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
};

function Shaman:Enable()
   local specFunctions = {
      [1] = {
         Name = 'Shaman - Elemental',
         NextSpell = Shaman.Elemental,
         AfterNextSpell = Shaman.ElementalAfterSpell,
         EnrichFrameData = Shaman.ElementalPrep,
      },
      -- [2] = {
      --    Name = 'Shaman - Enhancement',
      -- 	NextSpell = Shaman.Enhancement,
      --    AfterNextSpell = Shaman.EnhancementAfterSpell,
      --    EnrichFrameData = Shaman.EnhancementPrep,
      -- },
   };

	Shaman.playerLevel = UnitLevel('player');
   RotationHelper.ModuleRef = specFunctions[RotationHelper.Spec];
   return RotationHelper.ModuleRef ~= nil;
end

function Shaman:TotemMastery(totem)
	local tmName = GetSpellInfo(totem);

	for i = 1, 4 do
		local haveTotem, totemName, startTime, duration = GetTotemInfo(i);

		if haveTotem and totemName == tmName then
			return startTime + duration - GetTime();
		end
	end

	return 0;
end