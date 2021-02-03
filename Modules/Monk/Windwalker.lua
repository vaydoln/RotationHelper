local _, addonTable = ...;

--- @type RotationHelper
if not RotationHelper then return end

local RotationHelper = RotationHelper;
local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;
local GetPowerRegen = GetPowerRegen;
local Chi = Enum.PowerType.Chi;
local Energy = Enum.PowerType.Energy;
local Monk = addonTable.Monk;

local WW = {
	ChiBurst                = 123986,
	Serenity                = 152173,
	FistOfTheWhiteTiger     = 261947,
	ChiWave                 = 115098,
	SpearHandStrike         = 116705,
	RushingJadeWind         = 261715,
	TouchOfKarma            = 122470,
	GoodKarma               = 280195,
	TigerPalm               = 100780,
	WhirlingDragonPunch     = 152175,
	EnergizingElixir        = 115288,
	FistsOfFury             = 113656,
	RisingSunKick           = 107428,
	SpinningCraneKick       = 101546,
	HitCombo                = 196740,
	FlyingSerpentKick       = 101545,
	BlackoutKick            = 100784,
	TouchOfDeath            = 115080,
	InvokeXuenTheWhiteTiger = 123904,
	StormEarthAndFire       = 137639,
	SwiftRoundhouse         = 277669,
	BokProc                 = 116768
};

setmetatable(WW, Monk.spellMeta);

function Monk:createWindwalkerEffectsTable()
   local effects = {};

   -- TODO: spec - windwalker monk

   -- effects[WW.BarbedShot] = function(fd)
   --    fd = RotationHelper:startCooldown(fd, WW.BarbedShot);
   --    fd = RotationHelper:reduceCooldown(fd, WW.BestialWrath, 12);
   --    fd = RotationHelper:addTargetDebuff(fd, WW.BarbedShotAura);
   --    return fd;
   -- end

   -- effects[WW.Multishot] = function(fd)
   --    fd.focus = fd.focus - 40;
   --    return fd;
   -- end

   -- effects[WW.ResonatingArrow] = RotationHelper:normalCooldownEffect(WW.ResonatingArrow);

   return effects;
end

local WWEffect = Monk:createWindwalkerEffectsTable();

function Monk:WindwalkerAfterSpell(fd)
   return fd;
end

function Monk:WindwalkerPrep(fd)
	fd.targets = RotationHelper:SmartAoe();
	fd.chi = UnitPower('player', Chi);
	fd.chiMax = UnitPowerMax('player', Chi);
	fd.energy = UnitPower('player', Energy);
	fd.energyRegen = GetPowerRegen();
	fd.energyMax = UnitPowerMax('player', Energy);
	fd.energyTimeToMax = (fd.energyMax - fd.energy) / fd.energyRegen;

   if (fd.currentSpell and WWEffect[fd.currentSpell]) then
      local updateFrameData = WWEffect[fd.currentSpell];
      fd = updateFrameData(fd);
   end

   return fd;
end

function Monk:Windwalker(fd)
   local spellId = Monk:chooseWindwalkerSpellId(fd);
   local retVal = {
      id = spellId,
   };

   if (spellId and WWEffect[spellId]) then
      retVal.updateFrameData = WWEffect[spellId];
   end

   return retVal;
end

function Monk:chooseWindwalkerSpellId(fd)
   local cooldown = fd.cooldown;
   local buff = fd.buff;
   local debuff = fd.debuff;
   local talents = fd.talents;
   local azerite = fd.azerite;
   local currentSpell = fd.currentSpell;
   local gcd = fd.gcd;
	local targets = fd.targets;
	local chi = fd.chi;
	local chiMax = fd.chiMax;
	local energy = fd.energy;
	local energyRegen = fd.energyRegen;
	local energyMax = fd.energyMax;
	local energyTimeToMax = (energyMax - energy) / energyRegen;

	-- fd.chi, fd.chiMax, fd.energy, fd.energyRegen, fd.energyMax, fd.energyTimeToMax, fd.targets =
	-- chi, chiMax, energy, energyRegen, energyMax, energyTimeToMax, targets;

	if talents[WW.InvokeXuenTheWhiteTiger] then
		RotationHelper:GlowCooldown(WW.InvokeXuenTheWhiteTiger, cooldown[WW.InvokeXuenTheWhiteTiger].ready);
	end

	RotationHelper:GlowEssences();
	RotationHelper:GlowCooldown(WW.TouchOfDeath, cooldown[WW.TouchOfDeath].ready);

	if not talents[WW.Serenity] then
		-- storm_earth_and_fire,if=cooldown.storm_earth_and_fire.charges=2|(cooldown.fists_of_fury.remains<=6&chi>=3&cooldown.rising_sun_kick.remains<=1)|target.time_to_die<=15;
		RotationHelper:GlowCooldown(
			WW.StormEarthAndFire,
			cooldown[WW.StormEarthAndFire].charges == 2 or
				(cooldown[WW.StormEarthAndFire].ready and cooldown[WW.FistsOfFury].remains <= 6 and chi >= 3 and cooldown[WW.RisingSunKick].remains <= 1)
		);
	else
		-- serenity,if=cooldown.rising_sun_kick.remains<=2|target.time_to_die<=12;
		RotationHelper:GlowCooldown(
			WW.Serenity,
			cooldown[WW.Serenity].ready and cooldown[WW.RisingSunKick].remains <= 2
		);
	end

	-- rushing_jade_wind,if=talent.serenity.enabled&cooldown.serenity.remains<3&energy.time_to_max>1&buff.rushing_jade_wind.down;
	if talents[WW.RushingJadeWind] and
		talents[WW.Serenity] and
		cooldown[WW.Serenity].remains < 3 and
		energyTimeToMax > 1 and
		not buff[WW.RushingJadeWind].up
	then
		return WW.RushingJadeWind;
	end

	if buff[WW.Serenity].up then
		return Monk:WindwalkerSerenity();
	end

	-- fist_of_the_white_tiger,if=(energy.time_to_max<1|(talent.serenity.enabled&cooldown.serenity.remains<2))&chi.max-chi>=3;
	if talents[WW.FistOfTheWhiteTiger] and cooldown[WW.FistOfTheWhiteTiger].ready and
		energy >= 40 and
		(energyTimeToMax < 1 or (talents[WW.Serenity] and cooldown[WW.Serenity].remains < 2)) and
		chiMax - chi >= 3 then
		return WW.FistOfTheWhiteTiger;
	end

	-- tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=(energy.time_to_max<1|(talent.serenity.enabled&cooldown.serenity.remains<2))&chi.max-chi>=2&!prev_gcd.1.tiger_palm;
	if (energyTimeToMax < 1 or (talents[WW.Serenity] and cooldown[WW.Serenity].remains < 2)) and
		chiMax - chi >= 2 and spellHistory[1] ~= WW.TigerPalm
	then
		return WW.TigerPalm;
	end

	if targets < 3 then
		return Monk:WindwalkerSingleTarget();
	end

	if targets >= 3 then
		return Monk:WindwalkerAoe();
	end
end

function Monk:WindwalkerAoe(fd)
   local cooldown = fd.cooldown;
   local buff = fd.buff;
   local debuff = fd.debuff;
   local talents = fd.talents;
   local azerite = fd.azerite;
   local currentSpell = fd.currentSpell;
   local gcd = fd.gcd;
	local targets = fd.targets;
	local chi = fd.chi;
	local chiMax = fd.chiMax;
	local energy = fd.energy;
	local energyRegen = fd.energyRegen;
	local energyMax = fd.energyMax;
	local energyTimeToMax = (energyMax - energy) / energyRegen;

	-- whirling_dragon_punch;
	if talents[WW.WhirlingDragonPunch] and cooldown[WW.WhirlingDragonPunch].ready and
		not cooldown[WW.FistsOfFury].ready and not cooldown[WW.RisingSunKick].ready
	then
		return WW.WhirlingDragonPunch;
	end

	-- energizing_elixir,if=!prev_gcd.1.tiger_palm&chi<=1&energy<50;
	if talents[WW.EnergizingElixir] and cooldown[WW.EnergizingElixir].ready and spellHistory[1] ~= WW.TigerPalm and chi <= 1 and energy < 50 then
		return WW.EnergizingElixir;
	end

	-- fists_of_fury,if=energy.time_to_max>3;
	if cooldown[WW.FistsOfFury].ready and chi >= 3 and energyTimeToMax > 3 then
		return WW.FistsOfFury;
	end

	-- rushing_jade_wind,if=buff.rushing_jade_wind.down&energy.time_to_max>1;
	if talents[WW.RushingJadeWind] and not buff[WW.RushingJadeWind].up and energyTimeToMax > 1 then
		return WW.RushingJadeWind;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=(talent.whirling_dragon_punch.enabled&cooldown.whirling_dragon_punch.remains<5)&cooldown.fists_of_fury.remains>3;
	if cooldown[WW.RisingSunKick].ready and chi >= 2 and
		(talents[WW.WhirlingDragonPunch] and cooldown[WW.WhirlingDragonPunch].remains < 5) and
		cooldown[WW.FistsOfFury].remains > 3
	then
		return WW.RisingSunKick;
	end

	-- spinning_crane_kick,if=!prev_gcd.1.spinning_crane_kick&(((chi>3|cooldown.fists_of_fury.remains>6)&(chi>=5|cooldown.fists_of_fury.remains>2))|energy.time_to_max<=3);
	if chi >= 2 and spellHistory[1] ~= WW.SpinningCraneKick and (
		((chi > 3 or cooldown[WW.FistsOfFury].remains > 6) and (chi >= 5 or cooldown[WW.FistsOfFury].remains > 2)) or
			energyTimeToMax <= 3
	)
	then
		return WW.SpinningCraneKick;
	end

	-- chi_burst,if=chi<=3;
	if talents[WW.ChiBurst] and cooldown[WW.ChiBurst].ready and chi <= 3 then
		return WW.ChiBurst;
	end

	-- fist_of_the_white_tiger,if=chi.max-chi>=3&(energy>46|buff.rushing_jade_wind.down);
	if talents[WW.FistOfTheWhiteTiger] and cooldown[WW.FistOfTheWhiteTiger].ready and
		energy >= 40 and
		chiMax - chi >= 3 and
		(energy > 46 or not buff[WW.RushingJadeWind].up)
	then
		return WW.FistOfTheWhiteTiger;
	end

	-- tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=chi.max-chi>=2&(energy>56|buff.rushing_jade_wind.down)&(!talent.hit_combo.enabled|!prev_gcd.1.tiger_palm);
	if energy >= 50 and chiMax - chi >= 2 and
		(energy > 56 or not buff[WW.RushingJadeWind].up) and
		(not talents[WW.HitCombo] or spellHistory[1] ~= WW.TigerPalm)
	then
		return WW.TigerPalm;
	end

	-- chi_wave;
	if talents[WW.ChiWave] and cooldown[WW.ChiWave].ready then
		return WW.ChiWave;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick&(buff.bok_proc.up|(talent.hit_combo.enabled&prev_gcd.1.tiger_palm&chi<4));
	if chi >= 1 and
		spellHistory[1] ~= WW.BlackoutKick and
		(buff[WW.BokProc].up or (talents[WW.HitCombo] and spellHistory[1] == WW.TigerPalm and chi < 4))
	then
		return WW.BlackoutKick;
	end
end

function Monk:WindwalkerSerenity(fd)
   local cooldown = fd.cooldown;
   local buff = fd.buff;
   local debuff = fd.debuff;
   local talents = fd.talents;
   local azerite = fd.azerite;
   local currentSpell = fd.currentSpell;
   local gcd = fd.gcd;
	local targets = fd.targets;
	local chi = fd.chi;
	local chiMax = fd.chiMax;
	local energy = fd.energy;
	local energyRegen = fd.energyRegen;
	local energyMax = fd.energyMax;
	local energyTimeToMax = (energyMax - energy) / energyRegen;

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=active_enemies<3|prev_gcd.1.spinning_crane_kick;
	if targets < 3 or spellHistory[1] == WW.SpinningCraneKick then
		return WW.RisingSunKick;
	end

	-- fists_of_fury,if=(buff.bloodlust.up&prev_gcd.1.rising_sun_kick&!azerite.swift_roundhouse.enabled)|buff.serenity.remains<1|(active_enemies>1&active_enemies<5);
	if (buff[WW.Bloodlust].up and spellHistory[1] == WW.RisingSunKick and not azerite[WW.SwiftRoundhouse] > 0) or buff[WW.Serenity].remains < 1 or (targets > 1 and targets < 5) then
		return WW.FistsOfFury;
	end

	-- spinning_crane_kick,if=!prev_gcd.1.spinning_crane_kick&(active_enemies>=3|(active_enemies=2&prev_gcd.1.blackout_kick));
	if spellHistory[1] ~= WW.SpinningCraneKick and (targets >= 3 or (targets == 2 and spellHistory[1] == WW.BlackoutKick)) then
		return WW.SpinningCraneKick;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains;
	return WW.BlackoutKick;
end

function Monk:WindwalkerSingleTarget(fd)
   local cooldown = fd.cooldown;
   local buff = fd.buff;
   local debuff = fd.debuff;
   local talents = fd.talents;
   local azerite = fd.azerite;
   local currentSpell = fd.currentSpell;
   local gcd = fd.gcd;
	local targets = fd.targets;
	local chi = fd.chi;
	local chiMax = fd.chiMax;
	local energy = fd.energy;
	local energyRegen = fd.energyRegen;
	local energyMax = fd.energyMax;
	local energyTimeToMax = (energyMax - energy) / energyRegen;

	-- cancel_buff,name=rushing_jade_wind,if=active_enemies=1&(!talent.serenity.enabled|cooldown.serenity.remains>3);
	if talents[WW.RushingJadeWind] and targets == 1 and buff[WW.RushingJadeWind].up and
		(not talents[WW.Serenity] or cooldown[WW.Serenity].remains > 3) then
		return WW.RushingJadeWind;
	end

	-- whirling_dragon_punch;
	if talents[WW.WhirlingDragonPunch] and cooldown[WW.WhirlingDragonPunch].ready and
		not cooldown[WW.FistsOfFury].ready and not cooldown[WW.RisingSunKick].ready
	then
		return WW.WhirlingDragonPunch;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=chi>=5;
	if cooldown[WW.RisingSunKick].ready and chi >= 5 then
		return WW.RisingSunKick;
	end

	-- fists_of_fury,if=energy.time_to_max>3;
	if cooldown[WW.FistsOfFury].ready and chi >= 3 and energyTimeToMax > 3 then
		return WW.FistsOfFury;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains;
	if cooldown[WW.RisingSunKick].ready and chi >= 2 then
		return WW.RisingSunKick;
	end

	-- rushing_jade_wind,if=buff.rushing_jade_wind.down&energy.time_to_max>1&active_enemies>1;
	if talents[WW.RushingJadeWind] and not buff[WW.RushingJadeWind].up and energyTimeToMax > 1 and targets > 1 then
		return WW.RushingJadeWind;
	end

	-- fist_of_the_white_tiger,if=chi<=2&(buff.rushing_jade_wind.down|energy>46);
	if talents[WW.FistOfTheWhiteTiger] and cooldown[WW.FistOfTheWhiteTiger].ready and
		energy >= 40 and chi <= 2 and (not buff[WW.RushingJadeWind].up or energy > 46) then
		return WW.FistOfTheWhiteTiger;
	end

	-- energizing_elixir,if=chi<=3&energy<50;
	if talents[WW.EnergizingElixir] and cooldown[WW.EnergizingElixir].ready and chi <= 3 and energy < 50 then
		return WW.EnergizingElixir;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.blackout_kick&(cooldown.rising_sun_kick.remains>3|chi>=3)&(cooldown.fists_of_fury.remains>4|chi>=4|(chi=2&prev_gcd.1.tiger_palm))&buff.swift_roundhouse.stack<2;
	if chi >= 1 and
		spellHistory[1] ~= WW.BlackoutKick and
		(cooldown[WW.RisingSunKick].remains > 3 or chi >= 3) and
		(cooldown[WW.FistsOfFury].remains > 4 or chi >= 4 or (chi == 2 and spellHistory[1] == WW.TigerPalm)) and
		buff[WW.SwiftRoundhouse].count < 2
	then
		return WW.BlackoutKick;
	end

	-- chi_wave;
	if talents[WW.ChiWave] and cooldown[WW.ChiWave].ready then
		return WW.ChiWave;
	end

	-- chi_burst,if=chi.max-chi>=1&active_enemies=1|chi.max-chi>=2;
	if talents[WW.ChiBurst] and cooldown[WW.ChiBurst].ready and
		(chiMax - chi >= 1 and targets == 1 or chiMax - chi >= 2)
	then
		return WW.ChiBurst;
	end

	-- tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=!prev_gcd.1.tiger_palm&chi.max-chi>=2&(buff.rushing_jade_wind.down|energy>56);
	if spellHistory[1] ~= WW.TigerPalm and chiMax - chi >= 2 and (not buff[WW.RushingJadeWind].up or energy > 56) then
		return WW.TigerPalm;
	end
end