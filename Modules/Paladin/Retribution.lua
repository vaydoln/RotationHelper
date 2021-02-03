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
	Inquisition       = 84963,
	Crusade           = 231895,
	ExecutionSentence = 343527,
	ESTalent 		  = 23467,
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
	SelflessHealer	  = 85804,
	FlashOfLight      = 19750,
};
setmetatable(RT, Paladin.spellMeta);

function Paladin:createRetributionEffectsTable()
   local effects = {};

   -- TODO: spec - ret pally

   -- effects[RT.BarbedShot] = function(fd)
   --    fd = RotationHelper:startCooldown(fd, RT.BarbedShot);
   --    fd = RotationHelper:reduceCooldown(fd, RT.BestialWrath, 12);
   --    fd = RotationHelper:addTargetDebuff(fd, RT.BarbedShotAura);
   --    fd.pet = RotationHelper:addAura(fd.pet, RT.Frenzy);
   --    return fd;
   -- end

   -- effects[RT.Multishot] = function(fd)
   --    fd.focus = fd.focus - 40;
   --    return fd;
   -- end

   -- effects[RT.ResonatingArrow] = RotationHelper:normalCooldownEffect(RT.ResonatingArrow);

   return effects;
end

local RTEffect = Paladin:createRetributionEffectsTable();

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

   return retVal;
end

function Paladin:chooseRetributionSpellId(fd)
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local targets = fd.targets;
   local targetHp = RotationHelper:TargetPercentHealth() * 100;
	local holyPower = fd.holyPower;

	-- Essences
	RotationHelper:GlowEssences();

	if talents[RT.Crusade] then
		RotationHelper:GlowCooldown(RT.Crusade, cooldown[RT.Crusade].ready);
	else RotationHelper:GlowCooldown(RT.AvengingWrath, cooldown[RT.AvengingWrath].ready);
	end

	if talents[RT.FinalReckoning] and holyPower >=3 then
		RotationHelper:GlowCooldown(RT.FinalReckoning, cooldown[RT.FinalReckoning].ready);
	end

	if talents[RT.HolyAvenger] then
		RotationHelper:GlowCooldown(RT.HolyAvenger, cooldown[RT.HolyAvenger].ready);
	end

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
