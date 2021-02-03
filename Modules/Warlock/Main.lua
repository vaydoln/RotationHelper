local addonName, addonTable = ...;
_G[addonName] = addonTable;

--- @type RotationHelper
if not RotationHelper then return end

local Warlock = RotationHelper:NewModule('Warlock', 'AceEvent-3.0');
addonTable.Warlock = Warlock;

local RotationHelper = RotationHelper;

Warlock.spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
}

function Warlock:Enable()
   local specFunctions = {
      [1] = {
         Name = 'Warlock - Affliction',
         NextSpell = Warlock.Affliction,
         -- AfterNextSpell = Warlock.AfflictionAfterSpell,
         EnrichFrameData = Warlock.AfflictionPrep,
      },
      -- [2] = {
      --    Name = 'Warlock - Demonology',
      -- 	NextSpell = Warlock.Demonology,
      --    -- AfterNextSpell = Warlock.DemonologyAfterSpell,
      --    EnrichFrameData = Warlock.DemonologyPrep,
      -- },
      [3] = {
         Name = 'Warlock - Destruction',
         NextSpell = Warlock.Destruction,
         -- AfterNextSpell = Warlock.DestructionAfterSpell,
         EnrichFrameData = Warlock.DestructionPrep,
      },
   };

	Warlock.playerLevel = UnitLevel('player');
   RotationHelper.ModuleRef = specFunctions[RotationHelper.Spec];
   return RotationHelper.ModuleRef ~= nil;
end

function Warlock:Disable()
	self:UnregisterAllEvents();
end