local _, addonTable = ...;

--- @type RotationHelper
if not RotationHelper then
	return
end
local RotationHelper = RotationHelper;
local UnitPower = UnitPower;
local GetTotemInfo = GetTotemInfo;
local GetTime = GetTime;

local Necrolord = Enum.CovenantType.Necrolord;
local Venthyr = Enum.CovenantType.Venthyr;
local NightFae = Enum.CovenantType.NightFae;
local Kyrian = Enum.CovenantType.Kyrian;

local Shaman = addonTable.Shaman;

local EH = {
	WindfuryWeapon      = 33757,
	FlametongueWeapon   = 318038,
	LightningShield     = 192106,
	Stormkeeper         = 320137,
	WindfuryTotem       = 8512,
	DoomWinds           = 335903,
	Bloodlust           = 2825,
	WindShear           = 57994,
	FeralSpirit         = 51533,
	Ascendance          = 114051,
	Windstrike          = 115356,
	CrashLightning      = 187874,
	CrashLightningAura  = 333964,
	FaeTransfusion      = 328923,
	FrostShock          = 196840,
	Hailstorm           = 210853,
	FlameShock          = 188389,
	FireNova            = 333974,
	LashingFlames       = 334046,
	PrimordialWave      = 326059,
	VesperTotem         = 324386,
	LightningBolt       = 188196,
	MaelstromWeapon     = 344179,
	CrashingStorm       = 192246,
	LavaLash            = 60103,
	Stormstrike         = 17364,
	ChainLightning      = 188443,
	ChainHarvest        = 320674,
	ElementalBlast      = 117014,
	Sundering           = 197214,
	IceStrike           = 342240,
	EarthenSpike        = 188089,
	EarthElemental      = 198103,
	HotHand             = 201900,
	PrimalLavaActuators = 335896,

	-- soulbind abilities
	GroveInvigoration   = 322721,
	FieldOfBlossoms     = 319191,

	-- leggos
	DoomWindsBonusId           = 6993,
	DoomWindsDebuff            = 335904,
	PrimalLavaActuatorsBonusId = 6996,
};

setmetatable(EH, Shaman.spellMeta);

local TotemIcons = {
	[136114] = 'Windfury'
}

function Shaman:createEnhancementEffectsTable()
   local effects = {};

   effects[EH.WindfuryTotem] = function(fd)
      fd = RotationHelper:startCooldown(fd, EH.WindfuryTotem);
      fd = RotationHelper:removeSelfBuff(fd, EH.DoomWinds);
      fd = RotationHelper:addSelfBuff(fd, EH.WindfuryWeapon);
      fd.totems.Windfury = 120;
      return fd;
   end

   effects[EH.Stormkeeper] = function(fd)
      fd = RotationHelper:startCooldown(fd, EH.Stormkeeper);
      fd = RotationHelper:addSelfBuff(fd, EH.Stormkeeper, 2);
      return fd;
   end

   effects[EH.LightningBolt] = function(fd)
      fd = RotationHelper:removeSelfBuff(fd, EH.Stormkeeper);
      return fd;
   end

   effects[EH.ChainLightning] = function(fd)
      fd = RotationHelper:removeSelfBuff(fd, EH.ChainLightning);
      return fd;
   end

   effects[EH.Ascendance] = function(fd)
      fd = RotationHelper:startCooldown(fd, EH.Ascendance);
      fd = RotationHelper:addSelfBuff(fd, EH.Ascendance);
      return fd;
   end

   effects[EH.Stormstrike] = function(fd)
      fd = RotationHelper:startCooldown(fd, EH.Stormstrike);
      fd = RotationHelper:startCooldown(fd, EH.Windstrike);
      return fd;
   end

   effects[EH.Windstrike] = effects[EH.Stormstrike]

   effects[EH.CrashLightning] = function(fd)
      fd = RotationHelper:startCooldown(fd, EH.CrashLightning);
      fd = RotationHelper:addTargetDebuff(fd, EH.CrashLightningAura);
      return fd;
   end

   effects[EH.FrostShock] = function(fd)
      fd = RotationHelper:startCooldown(fd, EH.FrostShock);
      fd = RotationHelper:startCooldown(fd, EH.FlameShock);
      return fd;
   end

   effects[EH.FlameShock] = function(fd)
      fd = RotationHelper:startCooldown(fd, EH.FrostShock);
      fd = RotationHelper:startCooldown(fd, EH.FlameShock);
      fd = RotationHelper:addTargetDebuff(fd, EH.FlameShock);
      fd.activeFlameShock = max(1, fd.activeFlameShock);
      return fd;
   end

   effects[EH.PrimordialWave] = function(fd)
      fd = RotationHelper:startCooldown(fd, EH.PrimordialWave);
      fd = RotationHelper:addTargetDebuff(fd, EH.FlameShock);
      fd.activeFlameShock = max(1, fd.activeFlameShock);
      return fd;
   end

   effects[EH.IceStrike] = function(fd)
      fd = RotationHelper:startCooldown(fd, EH.IceStrike);
      fd = RotationHelper:endCooldown(fd, EH.FlameShock);
      fd = RotationHelper:endCooldown(fd, EH.FrostShock);
      return fd;
   end

   effects[EH.EarthenSpike] = RotationHelper:normalCooldownEffect(EH.EarthenSpike);
   effects[EH.Sundering] = RotationHelper:normalCooldownEffect(EH.Sundering);
   effects[EH.ChainHarvest] = RotationHelper:normalCooldownEffect(EH.ChainHarvest);
   effects[EH.VesperTotem] = RotationHelper:normalCooldownEffect(EH.VesperTotem);
   effects[EH.FireNova] = RotationHelper:normalCooldownEffect(EH.FireNova);
   effects[EH.LavaLash] = RotationHelper:normalCooldownEffect(EH.LavaLash);
   effects[EH.FaeTransfusion] = RotationHelper:normalCooldownEffect(EH.FaeTransfusion);
   effects[EH.FeralSpirit] = RotationHelper:normalCooldownEffect(EH.FeralSpirit);
   effects[EH.WindShear] = RotationHelper:normalCooldownEffect(EH.WindShear);
   effects[EH.ElementalBlast] = RotationHelper:normalCooldownEffect(EH.ElementalBlast);
   effects[EH.EarthElemental] = RotationHelper:normalCooldownEffect(EH.EarthElemental);
   effects[EH.Bloodlust] = RotationHelper:normalCooldownEffect(EH.Bloodlust);

   return effects;
end

local EHEffect = Shaman:createEnhancementEffectsTable();

function Shaman:enhGainMaelstrom(fd, count)
   return fd;
end

function Shaman:EnhancementPrep(fd)
	fd.totems = Shaman:Totems();
	fd.targets = RotationHelper:SmartAoe();
	fd.activeFlameShock = RotationHelper:DebuffCounter(EH.FlameShock, fd.timeShift);
	fd.doomWindsDebuff = RotationHelper:IntUnitAura('player', EH.DoomWindsDebuff, 'HARMFUL', fd.timeShift);

   if (fd.currentSpell and EHEffect[fd.currentSpell]) then
      local updateFrameData = EHEffect[fd.currentSpell];
      fd = updateFrameData(fd);
   end

	-- feral_spirit;
	RotationHelper:GlowCooldown(EH.FeralSpirit, fd.cooldown[EH.FeralSpirit].ready);
	RotationHelper:GlowCooldown(EH.EarthElemental, fd.cooldown[EH.EarthElemental].ready);

	-- ascendance;
	if fd.talents[EH.Ascendance] then
		RotationHelper:GlowCooldown(EH.Ascendance, fd.cooldown[EH.Ascendance].ready);
	end

   return fd;
end

function Shaman:Enhancement(fd)
   local spellId = Shaman:chooseEnhancementSpellId(fd);
   local retVal = {
      id = spellId,
   };

   if (spellId and EHEffect[spellId]) then
      retVal.updateFrameData = EHEffect[spellId];
   end

   return retVal;
end

function Shaman:chooseEnhancementSpellId(fd)
	local runeforge = fd.runeforge;

	-- windfury_totem,if=runeforge.doom_winds.equipped&buff.doom_winds_debuff.down;
	if runeforge[EH.DoomWindsBonusId] and not fd.doomWindsDebuff.up then
		return EH.WindfuryTotem;
	end

	-- call_action_list,name=single,if=active_enemies=1;
	if fd.targets <= 1 then
		return Shaman:EnhancementSingle(fd);
	else
	-- call_action_list,name=aoe,if=active_enemies>1;
		return Shaman:EnhancementAoe(fd);
	end
end

function Shaman:EnhancementAoe(fd)
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local covenant = fd.covenant;
	local runeforge = fd.runeforge;
	local covenantId = covenant.covenantId;
	local totems = fd.totems;
	local activeFlameShock = fd.activeFlameShock;
	-- 2021-01-06 Laag - Added targets variable
	local targets = RotationHelper:SmartAoe();

	-- windstrike,if=buff.crash_lightning.up;
	local Windstrike = RotationHelper:FindSpell(EH.Windstrike) and EH.Windstrike or EH.Stormstrike;
	if buff[EH.Ascendance].up and cooldown[EH.Windstrike].ready and buff[EH.CrashLightningAura].up then
		return Windstrike;
	end

	-- fae_transfusion,if=soulbind.grove_invigoration|soulbind.field_of_blossoms;
	if covenantId == NightFae and cooldown[EH.FaeTransfusion].ready and currentSpell ~= EH.FaeTransfusion and
		(covenant.soulbindAbilities[EH.GroveInvigoration] or covenant.soulbindAbilities[EH.FieldOfBlossoms])
	then
		return EH.FaeTransfusion;
	end

	-- 2021-01-06 Laag - Added Crash Lightning when DoomWinds buff is up
	-- Crash Lightning,if=runeforge.doom_winds.equipped&buff.doom_winds.up);
	if cooldown[EH.CrashLightning].ready and runeforge[EH.DoomWindsBonusId] and buff[EH.DoomWinds].up then
		return EH.CrashLightning;
	end

	-- frost_shock,if=buff.hailstorm.up;
	if cooldown[EH.FrostShock].ready and buff[EH.Hailstorm].up then
		return EH.FrostShock;
	end

	-- 2021-01-06 Laag - Moved Sundering to earlier in rotation
	-- sundering;
	if talents[EH.Sundering] and cooldown[EH.Sundering].ready then
		return EH.Sundering;
	end

	-- flame_shock,target_if=refreshable,cycle_targets=1,if=talent.fire_nova.enabled|talent.lashing_flames.enabled|covenant.necrolord;
	if cooldown[EH.FlameShock].ready and debuff[EH.FlameShock].refreshable and
		(talents[EH.FireNova] or talents[EH.LashingFlames] or covenantId == Necrolord)
	then
		return EH.FlameShock;
	end

	-- primordial_wave,target_if=min:dot.flame_shock.remains,cycle_targets=1,if=!buff.primordial_wave.up;
	if covenantId == Necrolord and cooldown[EH.PrimordialWave].ready and (not buff[EH.PrimordialWave].up) then
		return EH.PrimordialWave;
	end

	-- fire_nova,if=active_dot.flame_shock>=3;
	-- TODO
	if talents[EH.FireNova] and cooldown[EH.FireNova].ready and activeFlameShock >= 3 then
		return EH.FireNova;
	end

	-- vesper_totem;
	if covenantId == Kyrian and cooldown[EH.VesperTotem].ready then
		return EH.VesperTotem;
	end

	-- lightning_bolt,if=buff.primordial_wave.up&(buff.stormkeeper.up|buff.maelstrom_weapon.stack>=5);
	if buff[EH.PrimordialWave].up and (buff[EH.Stormkeeper].up or buff[EH.MaelstromWeapon].count >= 5) then
		return EH.LightningBolt;
	end

	-- crash_lightning,if=talent.crashing_storm.enabled|buff.crash_lightning.down;
	if cooldown[EH.CrashLightning].ready and (talents[EH.CrashingStorm] or not buff[EH.CrashLightningAura].up) then
		return EH.CrashLightning;
	end

	-- lava_lash,target_if=min:debuff.lashing_flames.remains,cycle_targets=1,if=talent.lashing_flames.enabled;
	if cooldown[EH.LavaLash].ready and (talents[EH.LashingFlames]) then
		return EH.LavaLash;
	end

	-- stormstrike,if=buff.crash_lightning.up;
	if cooldown[EH.Stormstrike].ready and buff[EH.CrashLightningAura].up then
		return EH.Stormstrike;
	end

	-- crash_lightning;
	if cooldown[EH.CrashLightning].ready then
		return EH.CrashLightning;
	end

	-- chain_lightning,if=buff.stormkeeper.up;
	if currentSpell ~= EH.ChainLightning and buff[EH.Stormkeeper].up then
		return EH.ChainLightning;
	end

	-- chain_harvest,if=buff.maelstrom_weapon.stack>=5;
	if covenantId == Venthyr and
		cooldown[EH.ChainHarvest].ready and
		currentSpell ~= EH.ChainHarvest and
		buff[EH.MaelstromWeapon].count >= 5
	then
		return EH.ChainHarvest;
	end

	-- elemental_blast,if=buff.maelstrom_weapon.stack>=5;
	if talents[EH.ElementalBlast] and
		cooldown[EH.ElementalBlast].ready and
		currentSpell ~= EH.ElementalBlast and
		buff[EH.MaelstromWeapon].count >= 5
	then
		return EH.ElementalBlast;
	end

	-- stormkeeper,if=buff.maelstrom_weapon.stack>=5;
	if talents[EH.Stormkeeper] and
		cooldown[EH.Stormkeeper].ready and
		currentSpell ~= EH.Stormkeeper and
		buff[EH.MaelstromWeapon].count >= 5
	then
		return EH.Stormkeeper;
	end

	-- chain_lightning,if=buff.maelstrom_weapon.stack=10;
	if currentSpell ~= EH.ChainLightning and buff[EH.MaelstromWeapon].count >= 10 then
		return EH.ChainLightning;
	end

	-- flame_shock,target_if=refreshable,cycle_targets=1,if=talent.fire_nova.enabled;
	if cooldown[EH.FlameShock].ready and debuff[EH.FlameShock].refreshable and talents[EH.FireNova] then
		return EH.FlameShock;
	end

	-- lava_lash,target_if=min:debuff.lashing_flames.remains,cycle_targets=1,if=runeforge.primal_lava_actuators.equipped&buff.primal_lava_actuators.stack>6;
	if cooldown[EH.LavaLash].ready and
		runeforge[EH.PrimalLavaActuatorsBonusId] and
		buff[EH.PrimalLavaActuators].count > 6
	then
		return EH.LavaLash;
	end

	-- 2021-01-06 Laag - Chain Lightning if targets >= 3
	-- chain_lightning,if=buff.maelstrom_weapon.stack>=5&active_enemies>=3;
	if currentSpell ~= EH.ChainLightning and buff[EH.MaelstromWeapon].count >= 5 and targets >= 3 then
		return EH.ChainLightning;
	end

	-- windstrike;
	if buff[EH.Ascendance].up and cooldown[EH.Windstrike].ready then
		return Windstrike;
	end

	-- stormstrike;
	if cooldown[EH.Stormstrike].ready then
		return EH.Stormstrike;
	end

	-- lava_lash;
	if cooldown[EH.LavaLash].ready then
		return EH.LavaLash;
	end

	-- flame_shock,target_if=refreshable,cycle_targets=1;
	if cooldown[EH.FlameShock].ready and debuff[EH.FlameShock].refreshable then
		return EH.FlameShock;
	end

	-- fae_transfusion;
	if covenantId == NightFae and cooldown[EH.FaeTransfusion].ready and currentSpell ~= EH.FaeTransfusion then
		return EH.FaeTransfusion;
	end

	-- frost_shock;
	if cooldown[EH.FrostShock].ready then
		return EH.FrostShock;
	end

	-- ice_strike;
	if talents[EH.IceStrike] and cooldown[EH.IceStrike].ready then
		return EH.IceStrike;
	end

	-- chain_lightning,if=buff.maelstrom_weapon.stack>=5;
	if currentSpell ~= EH.ChainLightning and buff[EH.MaelstromWeapon].count >= 5 then
		return EH.ChainLightning;
	end

	-- fire_nova,if=active_dot.flame_shock>1;
	if talents[EH.FireNova] and cooldown[EH.FireNova].ready and activeFlameShock > 1 then
		return EH.FireNova;
	end

	-- earthen_spike;
	if talents[EH.EarthenSpike] and cooldown[EH.EarthenSpike].ready then
		return EH.EarthenSpike;
	end

	-- windfury_totem,if=buff.windfury_totem.remains<30;
	if totems.Windfury < 30 then
		return EH.WindfuryTotem;
	end
end

function Shaman:EnhancementSingle(fd)
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local runeforge = fd.runeforge;
	local totems = fd.totems;
	local activeFlameShock = fd.activeFlameShock;
	local covenantId = fd.covenant.covenantId;

	-- windstrike;
	local Windstrike = RotationHelper:FindSpell(EH.Windstrike) and EH.Windstrike or EH.Stormstrike;
	if buff[EH.Ascendance].up and cooldown[EH.Windstrike].ready then
		return Windstrike;
	end

	-- primordial_wave,if=!buff.primordial_wave.up;
	if covenantId == Necrolord and cooldown[EH.PrimordialWave].ready and not buff[EH.PrimordialWave].up then
		return EH.PrimordialWave;
	end

	-- stormstrike,if=runeforge.doom_winds.equipped&buff.doom_winds.up;
	if cooldown[EH.Stormstrike].ready and runeforge[EH.DoomWindsBonusId] and buff[EH.DoomWinds].up then
		return EH.Stormstrike;
	end

	-- crash_lightning,if=runeforge.doom_winds.equipped&buff.doom_winds.up;
	if cooldown[EH.CrashLightning].ready and runeforge[EH.DoomWindsBonusId] and buff[EH.DoomWinds].up then
		return EH.CrashLightning;
	end

	-- ice_strike,if=runeforge.doom_winds.equipped&buff.doom_winds.up;
	if talents[EH.IceStrike] and
		cooldown[EH.IceStrike].ready and
		runeforge[EH.DoomWindsBonusId] and
		buff[EH.DoomWinds].up
	then
		return EH.IceStrike;
	end

	-- 2021-01-06 Laag - Added Sundering when DoomWinds buff is up
	-- Sundering,if=runeforge.doom_winds.equipped&buff.doom_winds.up);
	if talents[EH.Sundering] and cooldown[EH.Sundering].ready and runeforge[EH.DoomWindsBonusId] and buff[EH.DoomWinds].up then
		return EH.Sundering;
	end

	-- flame_shock,if=!ticking;
	if cooldown[EH.FlameShock].ready and not debuff[EH.FlameShock].up then
		return EH.FlameShock;
	end

	-- vesper_totem;
	if covenantId == Kyrian and cooldown[EH.VesperTotem].ready then
		return EH.VesperTotem;
	end

	-- frost_shock,if=buff.hailstorm.up;
	if cooldown[EH.FrostShock].ready and (buff[EH.Hailstorm].up) then
		return EH.FrostShock;
	end

	-- earthen_spike;
	if talents[EH.EarthenSpike] and cooldown[EH.EarthenSpike].ready then
		return EH.EarthenSpike;
	end

	-- fae_transfusion;
	if covenantId == NightFae and cooldown[EH.FaeTransfusion].ready and currentSpell ~= EH.FaeTransfusion then
		return EH.FaeTransfusion;
	end

	-- lightning_bolt,if=buff.stormkeeper.up;
	if buff[EH.Stormkeeper].up then
		return EH.LightningBolt;
	end

	-- elemental_blast,if=buff.maelstrom_weapon.stack>=5;
	if talents[EH.ElementalBlast] and
		cooldown[EH.ElementalBlast].ready and
		currentSpell ~= EH.ElementalBlast and
		buff[EH.MaelstromWeapon].count >= 5
	then
		return EH.ElementalBlast;
	end

	-- chain_harvest,if=buff.maelstrom_weapon.stack>=5;
	if covenantId == Venthyr and
		cooldown[EH.ChainHarvest].ready and
		currentSpell ~= EH.ChainHarvest and
		buff[EH.MaelstromWeapon].count >= 5
	then
		return EH.ChainHarvest;
	end

	-- lightning_bolt,if=buff.maelstrom_weapon.stack=10;
	if buff[EH.MaelstromWeapon].count >= 10 then
		return EH.LightningBolt;
	end

	-- lava_lash,if=buff.hot_hand.up|(runeforge.primal_lava_actuators.equipped&buff.primal_lava_actuators.stack>6);
	if cooldown[EH.LavaLash].ready and
		(
			buff[EH.HotHand].up or
			(runeforge[EH.PrimalLavaActuatorsBonusId] and buff[EH.PrimalLavaActuators].count > 6)
		)
	then
		return EH.LavaLash;
	end

	-- stormstrike;
	if cooldown[EH.Stormstrike].ready then
		return EH.Stormstrike;
	end

	-- stormkeeper,if=buff.maelstrom_weapon.stack>=5;
	if talents[EH.Stormkeeper] and
		cooldown[EH.Stormkeeper].ready and
		currentSpell ~= EH.Stormkeeper and
		buff[EH.MaelstromWeapon].count >= 5
	then
		return EH.Stormkeeper;
	end

	-- lava_lash;
	if cooldown[EH.LavaLash].ready then
		return EH.LavaLash;
	end

	-- crash_lightning;
	if cooldown[EH.CrashLightning].ready then
		return EH.CrashLightning;
	end

	-- flame_shock,target_if=refreshable;
	if cooldown[EH.FlameShock].ready and debuff[EH.FlameShock].refreshable then
		return EH.FlameShock;
	end

	-- frost_shock;
	if cooldown[EH.FrostShock].ready then
		return EH.FrostShock;
	end

	-- ice_strike;
	if talents[EH.IceStrike] and cooldown[EH.IceStrike].ready then
		return EH.IceStrike;
	end

	-- sundering;
	if talents[EH.Sundering] and cooldown[EH.Sundering].ready then
		return EH.Sundering;
	end

	-- fire_nova,if=active_dot.flame_shock;
	-- TODO
	if talents[EH.FireNova] and cooldown[EH.FireNova].ready and activeFlameShock > 0 then
		return EH.FireNova;
	end

	-- lightning_bolt,if=buff.maelstrom_weapon.stack>=5;
	if buff[EH.MaelstromWeapon].count >= 5 then
		return EH.LightningBolt;
	end

	-- windfury_totem,if=buff.windfury_totem.remains<30;
	if totems.Windfury < 30 then
		return EH.WindfuryTotem;
	end
end


function Shaman:Totems()
	local pets = {
		Windfury = 0,
	};

	for index = 1, MAX_TOTEMS do
		local hasTotem, totemName, startTime, duration, icon = GetTotemInfo(index);
		if hasTotem then
			local totemUnifiedName = TotemIcons[icon];
			if totemUnifiedName then
				local remains = startTime + duration - GetTime();
				pets[totemUnifiedName] = remains;
			end
		end
	end

	return pets;
end