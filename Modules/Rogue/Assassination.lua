local _, addonTable = ...;

--- @type RotationHelper
if not RotationHelper then return end

local RotationHelper = RotationHelper;
local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;
local GetPowerRegen = GetPowerRegen;
local InCombatLockdown = InCombatLockdown;
local ComboPoints = Enum.PowerType.ComboPoints;
local Energy = Enum.PowerType.Energy;
local Rogue = addonTable.Rogue;


-- Assassination
local AS = {
	Stealth          = 1784,
	StealthAlt       = 115191,
	MarkedForDeath   = 137619,
	Vendetta         = 79140,
	Subterfuge       = 108208,
	Garrote          = 703,
	Rupture          = 1943,
	Nightstalker     = 14062,
	Exsanguinate     = 200806,
	DeeperStratagem  = 193531,
	Vanish           = 1856,
	VanishAura       = 11327,
	MasterAssassin   = 255989,
	ToxicBlade       = 245388,
	PoisonedKnife    = 185565,
	FanOfKnives      = 51723,
	HiddenBlades     = 270061,
	Blindside        = 111240,
	BlindsideAura    = 121153,
	VenomRush        = 152152,
	CrimsonTempest   = 121411,
	DeadlyPoison     = 2823,
	DeadlyPoisonAura = 2818,
	Mutilate         = 1329,
	Envenom          = 32645,

	SharpenedBlades  = 272916,
	InternalBleeding = 154904,

	-- Auras
	StealthAura        = 1784
};

local A = {
	DoubleDose = 273007,
	ShroudedSuffocation = 278666,
}

setmetatable(AS, Rogue.spellMeta);
setmetatable(A, Rogue.spellMeta);


local auraMetaTable = {
	__index = function()
		return {
			up          = false,
			count       = 0,
			remains     = 0,
			refreshable = true,
		};
	end
};

function Rogue:PoisonedBleeds(timeShift)
	local poisoned = 0;
	for i, frame in pairs(C_NamePlate.GetNamePlates()) do
		local unit = frame.UnitFrame.unit;

		if frame:IsVisible() then
			local debuff = setmetatable({}, auraMetaTable);

			RotationHelper:CollectAura(unit, timeShift, debuff, 'PLAYER|HARMFUL');

			if debuff[AS.DeadlyPoisonAura].up then
				poisoned = poisoned +
					debuff[AS.Rupture].count +
					debuff[AS.Garrote].count +
					debuff[AS.InternalBleeding].count;
			end

		end
	end

	return poisoned;
end

function Rogue:createAssassinationEffectsTable()
   local effects = {};

   -- TODO: spec - sin rogue

   -- effects[AS.BarbedShot] = function(fd)
   --    fd = RotationHelper:startCooldown(fd, AS.BarbedShot);
   --    fd = RotationHelper:reduceCooldown(fd, AS.BestialWrath, 12);
   --    fd = RotationHelper:addTargetDebuff(fd, AS.BarbedShotAura);
   --    fd.pet = RotationHelper:addAura(fd.pet, AS.Frenzy);
   --    return fd;
   -- end

   -- effects[AS.Multishot] = function(fd)
   --    fd.focus = fd.focus - 40;
   --    return fd;
   -- end

   -- effects[AS.ResonatingArrow] = RotationHelper:normalCooldownEffect(AS.ResonatingArrow);

   return effects;
end

local ASEffect = Rogue:createAssassinationEffectsTable();

function Rogue:AssassinationAfterSpell(fd)
   return fd;
end

function Rogue:AssassinationPrep(fd)
	fd.combo = UnitPower('player', 4);
	fd.comboMax = UnitPowerMax('player', 4);
   fd.targets = RotationHelper:SmartAoe();
   fd.stealthed = fd.buff[AS.StealthAura].up or fd.buff[AS.StealthAlt].up or fd.buff[AS.VanishAura].up;
   fd.cpMaxSpend = fd.talents[AS.DeeperStratagem] and 5 or 6;
   fd.poisonedBleeds = Rogue:PoisonedBleeds(fd.timeShift);
   fd.spellHaste = RotationHelper:AttackHaste();
	fd.energy = UnitPower('player', 3);
	fd.energyMax = UnitPowerMax('player', 3);
   fd.energyRegen = GetPowerRegen();

   if (fd.currentSpell and ASEffect[fd.currentSpell]) then
      local updateFrameData = ASEffect[fd.currentSpell];
      fd = updateFrameData(fd);
   end

	RotationHelper:GlowEssences(fd);

	-- vendetta,if=!stealthed.rogue&dot.rupture.ticking&(!talent.subterfuge.enabled|!azerite.shrouded_suffocation.enabled|dot.garrote.pmultiplier>1)&(!talent.nightstalker.enabled|!talent.exsanguinate.enabled|cooldown.exsanguinate.remains<5-2*talent.deeper_stratagem.enabled);
	RotationHelper:GlowCooldown(
		AS.Vendetta,
		fd.cooldown[AS.Vendetta].ready and not fd.stealthed and fd.debuff[AS.Rupture].up and fd.energy < 80
	);

	RotationHelper:GlowCooldown(AS.Vanish, fd.cooldown[AS.Vanish].ready and not fd.stealthed);

   return fd;
end

function Rogue:Assassination(fd)
   local spellId = Rogue:chooseAssassinationSpellId(fd);
   local retVal = {
      id = spellId,
   };

   if (spellId and ASEffect[spellId]) then
      retVal.updateFrameData = ASEffect[spellId];
   end

   return retVal;
end

function Rogue:chooseAssassinationSpellId(fd)
   local cooldown = fd.cooldown;
   local buff = fd.buff;
   local debuff = fd.debuff;
   local talents = fd.talents;
	local energy = fd.energy;
	local combo = fd.combo;
   local targets = fd.targets;
   local stealthed = fd.stealthed;
   local cpMaxSpend = fd.cpMaxSpend;
	local comboDeficit = fd.comboMax - fd.combo;
   local effectiveEnergy = fd.energy + fd.energyRegen * min(fd.gcd, fd.timeShift);

   if not buff[AS.DeadlyPoison].up then
		return AS.DeadlyPoison;
	end

	if not InCombatLockdown() and buff[AS.DeadlyPoison].remains < 5 * 60 then
		return AS.DeadlyPoison;
	end

	-- stealth;
	if not InCombatLockdown() and not stealthed then
		return RotationHelper:FindSpell(AS.Stealth) and AS.Stealth or AS.StealthAlt;
	end

	if stealthed then
		return Rogue:AssassinationStealthed();
	end

	-- marked_for_death,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit*1.5|combo_points.deficit>=cp_max_spend);
	if talents[AS.MarkedForDeath] and cooldown[AS.MarkedForDeath].ready and (comboDeficit >= cpMaxSpend) then
		return AS.MarkedForDeath;
	end

	-- rupture,if=talent.exsanguinate.enabled&((combo_points>=cp_max_spend&cooldown.exsanguinate.remains<1)|(!ticking&(time>10|combo_points>=2)));
	if talents[AS.Exsanguinate] and
		(
			(combo >= cpMaxSpend and cooldown[AS.Exsanguinate].remains < 1) or
				(not debuff[AS.Rupture].up and (combo >= 2))
		)
	then
		return AS.Rupture;
	end

	--actions.dot+=/garrote,cycle_targets=1,if=(!talent.subterfuge.enabled|!(cooldown.vanish.up&cooldown.vendetta.remains<=4))&combo_points.deficit>=1&refreshable&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(target.time_to_die-remains>4&spell_targets.fan_of_knives<=1|target.time_to_die-remains>12)
	if cooldown[AS.Garrote].ready and
		(not talents[AS.Subterfuge] or not (cooldown[AS.Vanish].ready and cooldown[AS.Vendetta].remains <= 4)) and
		comboDeficit >= 1 and
		debuff[AS.Garrote].refreshable
	then
		return AS.Garrote;
	end

	-- crimson_tempest,if=spell_targets>=2&remains<2+(spell_targets>=5)&combo_points>=4;
	if talents[AS.CrimsonTempest] and effectiveEnergy >= 35 and
		targets >= 2 and
		debuff[AS.CrimsonTempest].remains < 2 + (targets >= 5 and 1 or 0) and
		combo >= 4
	then
		return AS.CrimsonTempest;
	end

	--actions.dot+=/rupture,cycle_targets=1,if=combo_points>=4&refreshable&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&target.time_to_die-remains>4
	if combo >= 4 and debuff[AS.Rupture].refreshable then
		return AS.Rupture;
	end

	-- exsanguinate,if=dot.rupture.remains>4+4*cp_max_spend&!dot.garrote.refreshable;
	if talents[AS.Exsanguinate] and
		cooldown[AS.Exsanguinate].ready and
		energy >= 35 and
		debuff[AS.Rupture].remains > 4 + 4 * cpMaxSpend and
		not debuff[AS.Garrote].refreshable
	then
		return AS.Exsanguinate;
	end

	-- toxic_blade,if=dot.rupture.ticking;
	if talents[AS.ToxicBlade] and cooldown[AS.ToxicBlade].ready and debuff[AS.Rupture].up then
		return AS.ToxicBlade;
	end

	return Rogue:AssassinationDirect();
end

function Rogue:AssassinationCds(fd)
   local cooldown = fd.cooldown;
   local buff = fd.buff;
   local debuff = fd.debuff;
   local talents = fd.talents;
   local azerite = fd.azerite;
	local combo = fd.combo;
   local targets = fd.targets;
   local stealthed = fd.stealthed;
   local cpMaxSpend = fd.cpMaxSpend;
	local comboDeficit = fd.comboMax - fd.combo;

	if cooldown[AS.Vanish].ready then
		-- vanish,if=talent.subterfuge.enabled&!dot.garrote.ticking&variable.single_target;
		if talents[AS.Subterfuge] and not debuff[AS.Garrote].up and targets < 2 then
			return AS.Vanish;
		end

		-- vanish,if=talent.exsanguinate.enabled&(talent.nightstalker.enabled|talent.subterfuge.enabled&variable.single_target)&combo_points>=cp_max_spend&cooldown.exsanguinate.remains<1&(!talent.subterfuge.enabled|!azerite.shrouded_suffocation.enabled|dot.garrote.pmultiplier<=1);
		if talents[AS.Exsanguinate] and
			(talents[AS.Nightstalker] or talents[AS.Subterfuge] and targets < 2) and
			combo >= cpMaxSpend and
			cooldown[AS.Exsanguinate].remains < 1 and
			(not talents[AS.Subterfuge] or azerite[A.ShroudedSuffocation] == 0)
		then
			return AS.Vanish;
		end

		-- vanish,if=talent.nightstalker.enabled&!talent.exsanguinate.enabled&combo_points>=cp_max_spend&debuff.vendetta.up;
		if talents[AS.Nightstalker] and
			not talents[AS.Exsanguinate] and
			combo >= cpMaxSpend and
			debuff[AS.Vendetta].up
		then
			return AS.Vanish;
		end

		-- vanish,if=talent.subterfuge.enabled&(!talent.exsanguinate.enabled|!variable.single_target)&!stealthed.rogue&cooldown.garrote.up&dot.garrote.refreshable&(spell_targets.fan_of_knives<=3&combo_points.deficit>=1+spell_targets.fan_of_knives|spell_targets.fan_of_knives>=4&combo_points.deficit>=4);
		if talents[AS.Subterfuge] and
			(not talents[AS.Exsanguinate] or not targets < 2) and
			not stealthed and
			cooldown[AS.Garrote].up and
			debuff[AS.Garrote].refreshable and
			(targets <= 3 and comboDeficit >= 1 + targets or targets >= 4 and comboDeficit >= 4)
		then
			return AS.Vanish;
		end

		-- vanish,if=talent.master_assassin.enabled&!stealthed.all&master_assassin_remains<=0&!dot.rupture.refreshable;
		if talents[AS.MasterAssassin] and
			not stealthed and
			buff[AS.MasterAssassin].remains <= 0 and
			not debuff[AS.Rupture].refreshable
		then
			return AS.Vanish;
		end
	end
end

function Rogue:AssassinationDirect(fd)
   local cooldown = fd.cooldown;
   local buff = fd.buff;
   local debuff = fd.debuff;
   local talents = fd.talents;
   local azerite = fd.azerite;
	local combo = fd.combo;
   local targets = fd.targets;
   local stealthed = fd.stealthed;
	local comboDeficit = fd.comboMax - fd.combo;
	local energyDeficit = fd.energyMax - fd.energy;
   local energyRegenCombined = fd.energyRegen + fd.poisonedBleeds * 7 % (2 * fd.spellHaste);
   local effectiveEnergy = fd.energy + fd.energyRegen * min(fd.gcd, fd.timeShift);

	-- envenom,if=combo_points>=4+talent.deeper_stratagem.enabled&(debuff.vendetta.up|debuff.toxic_blade.up|energy.deficit<=25+variable.energy_regen_combined|!variable.single_target)&(!talent.exsanguinate.enabled|cooldown.exsanguinate.remains>2);
	if combo >= 4 + (talents[AS.DeeperStratagem] and 1 or 0) and
		(debuff[AS.Vendetta].up or debuff[AS.ToxicBlade].up or energyDeficit <= 25 + energyRegenCombined or targets >= 2) and
		(not talents[AS.Exsanguinate] or cooldown[AS.Exsanguinate].remains > 2)
	then
		return AS.Envenom;
	end

	-- variable,name=use_filler,value=combo_points.deficit>1|energy.deficit<=25+variable.energy_regen_combined|!variable.single_target;
	local useFiller = comboDeficit > 1 or energyDeficit <= 25 + energyRegenCombined or targets >= 2;

	-- poisoned_knife,if=variable.use_filler&buff.sharpened_blades.stack>=29;
	if effectiveEnergy >= 40 and useFiller and buff[AS.SharpenedBlades].count >= 29 then
		return AS.PoisonedKnife;
	end

	-- fan_of_knives,if=variable.use_filler&(buff.hidden_blades.stack>=19|spell_targets.fan_of_knives>=4+(azerite.double_dose.rank>2)+stealthed.rogue);
	if useFiller and (
		buff[AS.HiddenBlades].count >= 19 or
			targets >= 4 + (azerite[A.DoubleDose] > 2 and 1 or 0) + (stealthed and 1 or 0)
	) then
		return AS.FanOfKnives;
	end

	-- fan_of_knives,target_if=!dot.deadly_poison_dot.ticking,if=variable.use_filler&spell_targets.fan_of_knives>=3;
	if useFiller and targets >= 3 then
		return AS.FanOfKnives;
	end

	-- blindside,if=variable.use_filler&(buff.blindside.up|!talent.venom_rush.enabled);
	local thp = RotationHelper:TargetPercentHealth();
	if talents[AS.Blindside] and
		useFiller and
		(buff[AS.BlindsideAura].up or (not talents[AS.VenomRush] and thp <= 0.3))
	then
		return AS.Blindside;
	end

	-- mutilate,if=variable.use_filler;
	if useFiller then
		return AS.Mutilate;
	end
end

function Rogue:AssassinationStealthed(fd)
   local cooldown = fd.cooldown;
   local debuff = fd.debuff;
   local talents = fd.talents;
   local azerite = fd.azerite;
	local combo = fd.combo;
   local targets = fd.targets;
   local cpMaxSpend = fd.cpMaxSpend;
   local effectiveEnergy = fd.energy + fd.energyRegen * min(fd.gcd, fd.timeShift);

	-- rupture,if=combo_points>=4&(talent.nightstalker.enabled|talent.subterfuge.enabled&(talent.exsanguinate.enabled&cooldown.exsanguinate.remains<=2|!ticking)&variable.single_target)&target.time_to_die-remains>6;
	if effectiveEnergy >= 25 and combo >= 4 and (
		talents[AS.Nightstalker] or talents[AS.Subterfuge] and
			(talents[AS.Exsanguinate] and cooldown[AS.Exsanguinate].remains <= 2 or not debuff[AS.Rupture].up) and
			targets < 2
	) then
		return AS.Rupture;
	end

	-- rupture,if=talent.subterfuge.enabled&azerite.shrouded_suffocation.enabled&!dot.rupture.ticking;
	if effectiveEnergy >= 25 and combo >= 1 and
		talents[AS.Subterfuge] and
		azerite[A.ShroudedSuffocation] > 0 and
		not debuff[AS.Rupture].up
	then
		return AS.Rupture;
	end

	-- garrote,if=talent.subterfuge.enabled&talent.exsanguinate.enabled&cooldown.exsanguinate.remains<1&prev_gcd.1.rupture&dot.rupture.remains>5+4*cp_max_spend;
	if cooldown[AS.Garrote].ready and talents[AS.Subterfuge] and
		talents[AS.Exsanguinate] and
		cooldown[AS.Exsanguinate].remains < 1 and
		spellHistory[1] == AS.Rupture and
		debuff[AS.Rupture].remains > 5 + 4 * cpMaxSpend
	then
		return AS.Garrote;
	end

	if combo >= 1 and not debuff[AS.Rupture].up then
		return AS.Rupture;
	end

	if cooldown[AS.Garrote].ready then
		return AS.Garrote;
	end
end