local _, addonTable = ...;

--- @type RotationHelper
if not RotationHelper then return end

local Mage = addonTable.Mage;
local RotationHelper = RotationHelper;
local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;
local Mana = Enum.PowerType.Mana;
local ArcaneCharges = Enum.PowerType.ArcaneCharges;

local Arc = {
	RuneofPower = 116011,
	RuneofPowerAura = 116014,
	ArcaneOrb = 153626,
	Evocation = 12051,
	ArcanePower = 12042,
	TouchoftheMagi = 321507,
	ArcaneBarrage = 44425,
	NetherTempest = 114923,
	PresenceofMind = 205025,
	ArcaneBlast = 30451,
	ArcaneMissiles = 5143,
	Clearcasting = 263725,
	ArcaneExplosion = 1449,
	AlterTime = 342245,
	Enlightened = 321387,
	Resonance = 205028,
	ArcaneFamiliar = 205022,
	ArcaneEcho = 342231,
	ArcaneFamiliarAura = 210126,
	TouchoftheMagiDebuff = 210824
};

function Mage:createArcaneEffectsTable()
   local effects = {};

   -- TODO: spec - arcane mage

   -- effects[Arc.BarbedShot] = function(fd)
   --    fd = RotationHelper:startCooldown(fd, Arc.BarbedShot);
   --    fd = RotationHelper:reduceCooldown(fd, Arc.BestialWrath, 12);
   --    fd = RotationHelper:addTargetDebuff(fd, Arc.BarbedShotAura);
   --    fd.pet = RotationHelper:addAura(fd.pet, Arc.Frenzy);
   --    return fd;
   -- end

   -- effects[Arc.Multishot] = function(fd)
   --    fd.focus = fd.focus - 40;
   --    return fd;
   -- end

   -- effects[Arc.ResonatingArrow] = RotationHelper:normalCooldownEffect(Arc.ResonatingArrow);

   return effects;
end

local ArcEffect = Mage:createArcaneEffectsTable();

function Mage:ArcaneAfterSpell(fd)
   return fd;
end

function Mage:ArcanePrep(fd)
	fd.mana = UnitPower(playerTargetString, Mana)
	fd.maxMana = UnitPowerMax(playerTargetString, Mana);
	fd.arcaneCharges = UnitPower(playerTargetString, ArcaneCharges);
	fd.arcaneChargesMax = UnitPowerMax(playerTargetString, ArcaneCharges);
	fd.targets = RotationHelper:SmartAoe();

   if (fd.currentSpell and ArcEffect[fd.currentSpell]) then
      local updateFrameData = ArcEffect[fd.currentSpell];
      fd = updateFrameData(fd);
   end

   return fd;
end

function Mage:Arcane(fd)
   local spellId = Mage:chooseArcaneSpellId(fd);
   local retVal = {
      id = spellId,
   };

   if (spellId and ArcEffect[spellId]) then
      retVal.updateFrameData = ArcEffect[spellId];
   end

	RotationHelper:GlowEssences(fd);

   return retVal;
end

function Mage:chooseArcaneSpellId(fd)
	local cooldowns = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local mana = fd.mana;
	local maxMana = fd.maxMana;
	local arcaneCharges = fd.arcaneCharges;
	local targets = fd.targets;

	-- talents
	local arcaneEchoTalent = talents[Arc.ArcaneEcho];
	local arcaneOrbTalent = talents[Arc.ArcaneOrb];
	local runeOfPowerTalent = talents[Arc.RuneofPower];

	-- resources
	local manaPercentage = mana / maxMana;

	--procs
	local clearCasting = buff[Arc.Clearcasting].up;

	--status
	local arcaneMissilesReady = cooldowns[Arc.ArcaneMissiles].ready;
	local touchOfMagiDebuff = debuff[Arc.TouchoftheMagiDebuff].up;
	local arcanePowerBurn = buff[Arc.ArcanePower].up;
	local runeOfPowerReady = cooldowns[Arc.RuneofPower].ready;
	local runeOfPowerBuff = buff[Arc.RuneofPowerAura].up
	local arcaneOrbReady = cooldowns[Arc.ArcaneOrb].ready;

	if touchOfMagiDebuff then
		-- todo: arcane orb function
		if arcaneOrbTalent and arcaneOrbReady and arcaneCharges < 4 then
			return Arc.ArcaneOrb;
		end

		if runeOfPowerTalent and runeOfPowerReady and not runeOfPowerBuff then
			return Arc.RuneofPower;
		end

		if targets >= 3 then
			if arcaneCharges == 4 then
				return Arc.ArcaneBarrage;
			else
				return Arc.ArcaneExplosion;
			end
		end

		if arcanePowerBurn and cooldowns[Arc.PresenceofMind].ready and buff[Arc.ArcanePower].remains <= 2 then
			return Arc.PresenceofMind;
		end

		if arcaneEchoTalent and arcaneMissilesReady then
			return Arc.ArcaneMissiles;
		end

	end

	if targets >= 3 then
		if arcaneCharges == 4 then
			return Arc.ArcaneBarrage;
		else
			return Arc.ArcaneExplosion;
		end
	end

	if clearCasting and arcaneMissilesReady and currentSpell ~= Arc.ArcaneMissiles then
		return Arc.ArcaneMissiles;
	end

	-- arcane orb function
	if arcaneOrbTalent and arcaneOrbReady and arcaneCharges < 4 then
		return Arc.ArcaneOrb;
	end

	if cooldowns[Arc.Evocation].ready and manaPercentage < 0.1 then
		return Arc.Evocation;
	end

	if arcaneCharges == 4 and not arcanePowerBurn and not touchOfMagiDebuff and not runeOfPowerBuff then
		return Arc.ArcaneBarrage;
	end

	if manaPercentage < 0.1 then
		return Arc.ArcaneBarrage;
	end

	return Arc.ArcaneBlast;
end