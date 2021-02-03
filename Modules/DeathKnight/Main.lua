local addonName, addonTable = ...;
_G[addonName] = addonTable;

--- @type RotationHelper
if not RotationHelper then return end

local RotationHelper = RotationHelper;
local GetTime = GetTime;
local GetRuneCooldown = GetRuneCooldown;
local GetInventoryItemLink = GetInventoryItemLink;
local DeathKnight = RotationHelper:NewModule('DeathKnight');
addonTable.DeathKnight = DeathKnight;

DeathKnight.spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
}

DeathKnight.weaponRunes = {
	Hysteria 			 = 6243,
	Razorice 			 = 3370,
	Sanguination 		 = 6241,
	Spellwarding 		 = 6242,
	TheApocalypse 		 = 6245,
	TheFallenCrusader 	 = 3368,
	TheStoneskinGargoyle = 3847,
	UndendingThirst 	 = 6244,
};

DeathKnight.hasEnchant = {};

function DeathKnight:Enable()
   local specFunctions = {
      [2] = {
         Name = 'Death Knight - Frost',
      	NextSpell = DeathKnight.Frost,
         AfterNextSpell = DeathKnight.FrostAfterSpell,
         EnrichFrameData = DeathKnight.FrostPrep,
      },
      [3] = {
         Name = 'Death Knight - Unholy',
         NextSpell = DeathKnight.Unholy,
         AfterNextSpell = DeathKnight.UnholyAfterSpell,
         EnrichFrameData = DeathKnight.UnholyPrep,
      },
   };

   DeathKnight:InitializeDatabase();
	DeathKnight:CreateConfig();
   DeathKnight:InitializeWeaponRunes();

	DeathKnight.playerLevel = UnitLevel('player');
   RotationHelper.ModuleRef = specFunctions[RotationHelper.Spec];
   return RotationHelper.ModuleRef ~= nil;
end

function DeathKnight:InitializeWeaponRunes()
	DeathKnight.hasEnchant = {};

	local mainHand = GetInventoryItemLink('player', 16);
	if mainHand ~= nil then
		local _, _, eid = strsplit(":", string.match(mainHand, "item[%-?%d:]+"));
		eid = tonumber(eid);
		if eid then
			DeathKnight.hasEnchant[tonumber(eid)] = true;
		end
	end

	local offhand = GetInventoryItemLink('player', 17);
	if offhand ~= nil then
		local _, _, eid = strsplit(":", string.match(offhand, "item[%-?%d:]+"));
		eid = tonumber(eid);
		if eid then
			DeathKnight.hasEnchant[tonumber(eid)] = true;
		end
	end
end

function DeathKnight:Runes(timeShift)
	local count = 0;
	local time = GetTime();

	for i = 1, 10 do
		local start, duration, runeReady = GetRuneCooldown(i);
		if start and start > 0 then
			local rcd = duration + start - time;
			if rcd < timeShift then
				count = count + 1;
			end
		elseif runeReady then
			count = count + 1;
		end
	end
	return count;
end

function DeathKnight:prepRunes(fd)
	fd.runes = DeathKnight:Runes(fd.timeShift);
	fd.runicPower = UnitPower('player', RunicPower);
   fd.runicPowerMax = UnitPowerMax('player', RunicPower);
   fd.runeCd = DeathKnight:RuneCooldownDuration();
	fd.timeTo2Runes = DeathKnight:TimeToRunes(2);
	fd.timeTo3Runes = DeathKnight:TimeToRunes(3);
	fd.timeTo4Runes = DeathKnight:TimeToRunes(4);
   fd.timeTo5Runes = DeathKnight:TimeToRunes(5);
   return fd;
end

function DeathKnight:gainRunes(fd, runeCount)
   fd.runes = min(6, fd.runes + runeCount);

   if (fd.runes >= 5) then
      fd.timeTo2Runes = 0;
      fd.timeTo3Runes = 0;
      fd.timeTo4Runes = 0;
      fd.timeTo5Runes = 0;
   elseif (fd.runes >= 4) then
      fd.timeTo2Runes = 0;
      fd.timeTo3Runes = 0;
      fd.timeTo4Runes = 0;
   elseif (fd.runes >= 3) then
      fd.timeTo2Runes = 0;
      fd.timeTo3Runes = 0;
   elseif (fd.runes >= 2) then
      fd.timeTo2Runes = 0;
   end

   return fd;
end

function DeathKnight:spendRunes(fd, runeCount)
   fd.runes = fd.runes - runeCount;
   fd.runicPower = min(fd.runicPowerMax, fd.runicPower + (10 * runeCount));

   if (fd.runes < 2) then
      fd.timeTo2Runes = fd.runeCd;
      fd.timeTo3Runes = fd.runeCd;
      fd.timeTo4Runes = fd.runeCd;
      fd.timeTo5Runes = fd.runeCd;
   elseif (fd.runes < 3) then
      fd.timeTo3Runes = fd.runeCd;
      fd.timeTo4Runes = fd.runeCd;
      fd.timeTo5Runes = fd.runeCd;
   elseif (fd.runes < 4) then
      fd.timeTo4Runes = fd.runeCd;
      fd.timeTo5Runes = fd.runeCd;
   elseif (fd.runes < 5) then
      fd.timeTo5Runes = fd.runeCd;
   end

   return fd;
end

function DeathKnight:RuneCooldownDuration()
   local maxDuration = 0;
	for i = 1, 6 do
      local start, duration, runeReady = GetRuneCooldown(i);
      maxDuration = max(maxDuration, duration);
   end
   return maxDuration;
end

function DeathKnight:TimeToRunes(desiredRunes)
	local time = GetTime()

	if desiredRunes == 0 then
		return 0;
	end

	if desiredRunes > 6 then
		return 99999;
	end

	local runes = {};
	local readyRuneCount = 0;
	for i = 1, 6 do
		local start, duration, runeReady = GetRuneCooldown(i);
		runes[i] = {
			start = start,
			duration = duration
		}
		if runeReady then
			readyRuneCount = readyRuneCount + 1;
		end
	end

	if readyRuneCount >= desiredRunes then
		return 0;
	end

	-- Sort the table by remaining cooldown time, ascending
	table.sort(runes, function(l,r)
		if l == nil then
			return true;
		elseif r == nil then
			return false;
		else
			return l.duration + l.start < r.duration + r.start;
		end
	end);

	-- How many additional runes need to come off cooldown before we hit our desired count?
	local neededRunes = desiredRunes - readyRuneCount;

	-- If it's three or fewer (since three runes regenerate at a time), take the remaining regen time of the Nth rune
	if neededRunes <= 3 then
		local rune = runes[desiredRunes];
		return rune.duration + rune.start - time;
	end

	-- Otherwise, we need to wait for the slowest of our three regenerating runes, plus the full regen time needed for the remaining rune(s)
	local rune = runes[readyRuneCount + 3];
	return rune.duration + rune.start - time + rune.duration;
end
