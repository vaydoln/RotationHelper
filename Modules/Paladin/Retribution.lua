local _, addonTable = ...;

--- @type RotationHelper
if not RotationHelper then return end

local Paladin = addonTable.Paladin;
local RotationHelper = RotationHelper;
local UnitPower = UnitPower;
local HolyPower = Enum.PowerType.HolyPower;
local RT = {
	Rebuke            = 96231,
	ShieldOfVengeance = 184662,
	AvengingWrath     = 31884,
	Crusade           = 231895,
	ExecutionSentence = 343527,
	DivineStorm       = 53385,
	DivinePurpose     = 223817,
	TemplarsVerdict   = 85256,
	HammerOfWrath     = 24275,
	WakeOfAshes       = 255937,
	BladeOfJustice    = 184575,
	Judgment          = 20271,
	JudgmentAura      = 197277,
	Consecration      = 26573,
	CrusaderStrike    = 35395,
	DivineRight       = 277678,
	RighteousVerdict  = 267610,
	EmpyreanPower     = 326732,
	HolyAvenger       = 105809,
	Seraphim		  = 152262,
	FinalReckoning	  = 343721,
	FiresOfJusticeAura	  = 209785,
};
setmetatable(RT, Paladin.spellMeta);

function Paladin:createRetributionEffectsTable()
   local effects = {};

   effects[RT.AvengingWrath] = function(fd)
      fd = RotationHelper:startCooldown(fd, RT.AvengingWrath);
      fd = RotationHelper:addSelfBuff(fd, RT.AvengingWrath);
      return fd;
   end

   effects[RT.Crusade] = function(fd)
      fd = RotationHelper:startCooldown(fd, RT.Crusade);
      fd = RotationHelper:addSelfBuff(fd, RT.Crusade);
      return fd;
   end

   effects[RT.ExecutionSentence] = function(fd)
      fd = RotationHelper:startCooldown(fd, RT.ExecutionSentence);
      fd = Paladin:retSpendHolyPower(fd, 3);
      return fd;
   end

   effects[RT.TemplarsVerdict] = function(fd)
      fd = Paladin:retSpendHolyPower(fd, 3);
      fd = RotationHelper:addSelfBuff(fd, RT.RighteousVerdict);
      return fd;
   end

   effects[RT.DivineStorm] = function(fd)
      fd = Paladin:retSpendHolyPower(fd, 3);
      return fd;
   end

   effects[RT.HammerOfWrath] = function(fd)
      fd = Paladin:retGainHolyPower(fd, 1);
      fd = RotationHelper:startCooldown(fd, RT.HammerOfWrath);
      return fd;
   end

   effects[RT.Seraphim] = function(fd)
      fd = RotationHelper:startCooldown(fd, RT.Seraphim);
      fd = RotationHelper:addSelfBuff(fd, RT.Seraphim);
      return fd;
   end

   effects[RT.HolyAvenger] = function(fd)
      fd = RotationHelper:startCooldown(fd, RT.HolyAvenger);
      fd = RotationHelper:addSelfBuff(fd, RT.HolyAvenger);
      return fd;
   end

   effects[RT.Judgment] = function(fd)
      fd = Paladin:retGainHolyPower(fd, 1);
      fd = RotationHelper:startCooldown(fd, RT.Judgment);
      fd = RotationHelper:addTargetDebuff(fd, RT.JudgmentAura);
      return fd;
   end

   effects[RT.BladeOfJustice] = function(fd)
      fd = Paladin:retGainHolyPower(fd, 2);
      fd = RotationHelper:startCooldown(fd, RT.BladeOfJustice);
      return fd;
   end

   effects[RT.WakeOfAshes] = function(fd)
      fd = Paladin:retGainHolyPower(fd, 3);
      fd = RotationHelper:startCooldown(fd, RT.WakeOfAshes);
      return fd;
   end

   effects[RT.CrusaderStrike] = function(fd)
      fd = Paladin:retGainHolyPower(fd, 1);
      fd = RotationHelper:startCooldown(fd, RT.CrusaderStrike);
      return fd;
   end

   effects[RT.FinalReckoning] = RotationHelper:normalCooldownEffect(RT.FinalReckoning);
   effects[RT.Consecration] = RotationHelper:normalCooldownEffect(RT.Consecration);
   effects[RT.Rebuke] = RotationHelper:normalCooldownEffect(RT.Rebuke);
   effects[RT.ShieldOfVengeance] = RotationHelper:normalCooldownEffect(RT.ShieldOfVengeance);

   return effects;
end

local RTEffect = Paladin:createRetributionEffectsTable();

function Paladin:retGainHolyPower(fd, count)
   if (fd.talents[RT.HolyAvenger] and fd.buff[RT.HolyAvenger].up) then
      count = (count * 3);
   end

   fd.holyPower = min(fd.holyPowerMax, fd.holyPower + count);
   return fd;
end

function Paladin:retSpendHolyPower(fd, count)
   if (fd.buff[RT.DivinePurpose].up) then
      fd = RotationHelper:removeSelfBuff(fd, RT.DivinePurpose);
   elseif (fd.buff[RT.FiresOfJusticeAura].up) then
      fd = RotationHelper:removeSelfBuff(fd, RT.FiresOfJusticeAura);
   else
      fd.holyPower = fd.holyPower - count;
   end
   return fd;
end

function Paladin:RetributionAfterSpell(fd)
   return fd;
end

function Paladin:RetributionPrep(fd)
	fd.holyPower = UnitPower('player', HolyPower);
	fd.holyPowerMax = UnitPowerMax('player', HolyPower);
	fd.targets = RotationHelper:SmartAoe();

   if (fd.currentSpell and RTEffect[fd.currentSpell]) then
      local updateFrameData = RTEffect[fd.currentSpell];
      fd = updateFrameData(fd);
   end

   return fd;
end

function Paladin:Retribution(fd)
   local spellId = Paladin:chooseRetributionSpellId(fd);
   local retVal = {
      id = spellId,
   };

   if (spellId and RTEffect[spellId]) then
      retVal.updateFrameData = RTEffect[spellId];
   end

	-- Essences
	RotationHelper:GlowEssences(fd);

	if fd.talents[RT.Crusade] then
		RotationHelper:GlowCooldown(RT.Crusade, fd.cooldown[RT.Crusade].ready);
	else RotationHelper:GlowCooldown(RT.AvengingWrath, fd.cooldown[RT.AvengingWrath].ready);
	end

	if fd.talents[RT.FinalReckoning] and fd.holyPower >=3 then
		RotationHelper:GlowCooldown(RT.FinalReckoning, fd.cooldown[RT.FinalReckoning].ready);
	end

	if fd.talents[RT.HolyAvenger] then
		RotationHelper:GlowCooldown(RT.HolyAvenger, fd.cooldown[RT.HolyAvenger].ready);
	end

   return retVal;
end

function Paladin:chooseRetributionSpellId(fd)
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local targets = fd.targets;
   local targetHp = RotationHelper:TargetPercentHealth() * 100;
	local holyPower = fd.holyPower;

	--- Spenders
	if talents[RT.Seraphim] and cooldown[RT.Seraphim].ready and holyPower >=3 then
		return RT.Seraphim;
	end

	if talents[RT.ExecutionSentence] and holyPower >= 3 and cooldown[RT.ExecutionSentence].ready then
		return RT.ExecutionSentence;
	end

	if holyPower >= 3 and targets <= 2 then
		return RT.TemplarsVerdict;
	elseif buff[RT.DivinePurpose].up then
		return RT.TemplarsVerdict;
	end

	if holyPower >= 3 and targets >= 3 then
		return RT.DivineStorm;
	end
	-- Generators
	if cooldown[RT.WakeOfAshes].ready and holyPower <= 2 then
		return RT.WakeOfAshes;
	end

	if cooldown[RT.BladeOfJustice].ready then
		return RT.BladeOfJustice;
	end

	if targetHp <= 20 and cooldown[RT.HammerOfWrath].ready then
		return RT.HammerOfWrath;
	end

	if cooldown[RT.Judgment].ready then
		return RT.Judgment;
	end

	if cooldown[RT.CrusaderStrike].ready then
		return RT.CrusaderStrike;
	end

	if cooldown[RT.Consecration].ready then
		return RT.Consecration;
	end
end
