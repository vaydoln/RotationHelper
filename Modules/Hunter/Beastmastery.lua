local _, addonTable = ...;

--- @type RotationHelper
if not RotationHelper then return end
local RotationHelper = RotationHelper;
local Hunter = addonTable.Hunter;

local BM = {
	TarTrap         = 187698,
	SoulforgeEmbers = 336745,
	BestialWrath    = 19574,
	ScentOfBlood    = 193532,
	CounterShot     = 147362,
	AspectOfTheWild = 193530,
	BarbedShot      = 217200,
	Multishot       = 2643,
	Flare           = 1543,
	DeathChakram    = 325028,
	WildSpirits     = 328231,
	ResonatingArrow = 308491,
	Stampede        = 201430,
	FlayedShot      = 324149,
	KillShot        = 53351,
	ChimaeraShot    = 53209,
	Bloodshed       = 321530,
	AMurderOfCrows  = 131894,
	Barrage         = 120360,
	KillCommand     = 34026,
	DireBeast       = 120679,
	CobraShot       = 193455,
	FreezingTrap    = 187650,
	FlayersMark     = 324156,
	KillerCobra     = 199532,

	-- Pet Auras
	BeastCleave     = 268877,
	Frenzy          = 272790,

	-- Target Auras
	BarbedShotAura  = 217200,
};

-- BM
--local BM = {
--	SpittingCobra    = 194407,
--	MultiShot        = 2643,
--	CounterShot      = 147362,
--	AspectOfTheWild  = 193530,
--	DireBeast        = 120679,
--	AutoShot         = 75,
--	Stampede         = 201430,
--	ChimaeraShot     = 53209,
--	AMurderOfCrows   = 131894,
--	BestialWrath     = 19574,
--	CobraShot        = 193455,
--	KillCommand      = 34026,
--	BarbedShot       = 217200,
--	Barrage          = 120360,
--	PrimalInstincts  = 279810,
--	OneWithThePack   = 199528,
--
--	-- Player Auras
--	DanceOfDeath     = 274443,
--	--BestialWrath   = 19574,
--	--BarbedShot     = 246152,
--	--DireBeast      = 281036,
--	--BarbedShot     = 246852,
--
--	-- Pet Auras
--	BeastCleave      = 268877,
--	Frenzy           = 272790,
--
--	-- Target Auras
--	BarbedShotAura   = 217200,
--}

setmetatable(BM, Hunter.spellMeta);

local auraMetaTable = {
	__index = function()
		return {
			up          = false,
			count       = 0,
			remains     = 0,
			duration    = 0,
			refreshable = true,
		};
	end
};

function Hunter:createBeastMasteryEffectsTable()
   local effects = {};

   effects[BM.BarbedShot] = function(fd)
      fd = RotationHelper:startCooldown(fd, BM.BarbedShot);
      fd = RotationHelper:reduceCooldown(fd, BM.BestialWrath, 12);
      fd = RotationHelper:addTargetDebuff(fd, BM.BarbedShotAura);
      fd.pet = RotationHelper:addAura(fd.pet, BM.Frenzy);
      return fd;
   end

   effects[BM.KillShot] = function(fd)
      fd.focus = fd.focus - 10;
      fd = RotationHelper:startCooldown(fd, BM.KillShot);
      return fd;
   end

   effects[BM.Multishot] = function(fd)
      fd.focus = fd.focus - 40;
      return fd;
   end

   effects[BM.KillCommand] = function(fd)
      fd.focus = fd.focus - 30;
      fd = RotationHelper:startCooldown(fd, BM.KillCommand);
      return fd;
   end

   effects[BM.Barrage] = function(fd)
      fd.focus = fd.focus - 60;
      fd = RotationHelper:startCooldown(fd, BM.Barrage);
      return fd;
   end

   effects[BM.CobraShot] = function(fd)
      fd.focus = fd.focus - 35;
      if (fd.talents[BM.KillerCobra] and fd.buff[BM.BestialWrath].up) then
         fd = RotationHelper:endCooldown(fd, BM.KillCommand);
      else
         fd = RotationHelper:reduceCooldown(fd, BM.KillCommand, 1);
      end
      return fd;
   end

   effects[BM.ChimaeraShot] = function(fd)
      fd.focus = min(fd.focusMax, fd.focus + 10);
      fd = RotationHelper:startCooldown(fd, BM.ChimaeraShot);
      return fd;
   end

   effects[BM.AMurderOfCrows] = function(fd)
      fd.focus = fd.focus - 30;
      fd = RotationHelper:startCooldown(fd, BM.AMurderOfCrows);
      return fd;
   end

   effects[BM.FlayedShot] = function(fd)
      fd.focus = fd.focus - 10;
      fd = RotationHelper:startCooldown(fd, BM.FlayedShot);
      return fd;
   end

   effects[BM.BestialWrath] = function(fd)
      fd = RotationHelper:startCooldown(fd, BM.BestialWrath);
      fd = RotationHelper:addSelfBuff(fd, BM.BestialWrath);
      fd.pet = RotationHelper:addAura(fd.pet, BM.BestialWrath);
      if (fd.talents[BM.ScentOfBlood]) then
         fd = RotationHelper:endCooldown(fd, BM.BarbedShot, 2);
      end
      return fd;
   end

   effects[BM.ResonatingArrow] = RotationHelper:normalCooldownEffect(BM.ResonatingArrow);
   effects[BM.Bloodshed] = RotationHelper:normalCooldownEffect(BM.Bloodshed);
   effects[BM.DeathChakram] = RotationHelper:normalCooldownEffect(BM.DeathChakram);
   effects[BM.WildSpirits] = RotationHelper:normalCooldownEffect(BM.WildSpirits);
   effects[BM.CounterShot] = RotationHelper:normalCooldownEffect(BM.CounterShot);
   effects[BM.DireBeast] = RotationHelper:normalCooldownEffect(BM.DireBeast);
   effects[BM.AspectOfTheWild] = RotationHelper:normalCooldownEffect(BM.AspectOfTheWild);
   effects[BM.Flare] = RotationHelper:normalCooldownEffect(BM.Flare);
   effects[BM.Stampede] = RotationHelper:normalCooldownEffect(BM.Stampede);
   effects[BM.TarTrap] = RotationHelper:normalCooldownEffect(BM.TarTrap);
   effects[BM.FreezingTrap] = RotationHelper:normalCooldownEffect(BM.FreezingTrap);

   return effects;
end

local BMEffect = Hunter:createBeastMasteryEffectsTable();

function Hunter:BeastMasteryPrep(fd)
	fd.focus, fd.focusMax, fd.focusRegen = Hunter:Focus(0, fd.timeShift);

	local targets;
	if Hunter.db.advancedAoeBM then
		targets = Hunter:TargetsInPetRange();
	else
		targets = RotationHelper:SmartAoe();
	end

	if not fd.pet then
		fd.pet = {};
		setmetatable(fd.pet, auraMetaTable);
	end
	RotationHelper:CollectAura('pet', fd.timeShift, fd.pet);

	fd.targets = targets;

   if (fd.currentSpell and BMEffect[fd.currentSpell]) then
      local updateFrameData = BMEffect[fd.currentSpell];
      fd = updateFrameData(fd);
   end

   return fd;
end

function Hunter:BeastMastery(fd)
   local spellId = Hunter:chooseBeastMasterySpellId(fd);
   local retVal = {
      id = spellId,
   };

   if (spellId and BMEffect[spellId]) then
      retVal.updateFrameData = BMEffect[spellId];
   end

   return retVal;
end

function Hunter:chooseBeastMasterySpellId(fd)
	fd.targetHp = RotationHelper:TargetPercentHealth();
	fd.focusTimeToMax = Hunter:FocusTimeToMax(fd);

	-- call_action_list,name=cds;
	Hunter:BeastMasteryCds(fd);

	-- call_action_list,name=st,if=active_enemies<2;
	if fd.targets < 2 then
		return Hunter:BeastMasterySt(fd);
	else
	-- call_action_list,name=cleave,if=active_enemies>1;
		return Hunter:BeastMasteryCleave(fd);
	end
end

function Hunter:BeastMasteryCds(fd)
	local cooldown = fd.cooldown;
	local talents = fd.talents;
	local covenantId = fd.covenant.covenantId;

	RotationHelper:GlowCooldown(BM.AspectOfTheWild, cooldown[BM.AspectOfTheWild].ready);
	RotationHelper:GlowCooldown(BM.Stampede, talents[BM.Stampede] and cooldown[BM.Stampede].ready);

	if covenantId == Enum.CovenantType.Kyrian then
		RotationHelper:GlowCooldown(BM.ResonatingArrow, cooldown[BM.ResonatingArrow].ready);
	elseif covenantId == Enum.CovenantType.NightFae then
		RotationHelper:GlowCooldown(BM.WildSpirits, cooldown[BM.WildSpirits].ready);
	elseif covenantId == Enum.CovenantType.Necrolord then
		RotationHelper:GlowCooldown(BM.DeathChakram, cooldown[BM.DeathChakram].ready);
	elseif covenantId == Enum.CovenantType.Venthyr then
		RotationHelper:GlowCooldown(BM.FlayedShot, cooldown[BM.FlayedShot].ready);
	end
end

function Hunter:BeastMasteryCleave(fd)
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local gcd = fd.gcd;
	local timeToDie = fd.timeToDie;
	local focus = fd.focus;
	local targetHp = fd.targetHp;
	local pet = fd.pet;

	-- barbed_shot,target_if=min:dot.barbed_shot.remains,if=pet.main.buff.frenzy.up&pet.main.buff.frenzy.remains<=gcd;
	if cooldown[BM.BarbedShot].ready and pet[BM.Frenzy].up and pet[BM.Frenzy].remains <= gcd then
		return BM.BarbedShot;
	end

	-- multishot,if=gcd-pet.main.buff.beast_cleave.remains>0.25;
	if gcd - buff[BM.BeastCleave].remains > 0.25 then
		return BM.Multishot;
	end

	-- barbed_shot,target_if=min:dot.barbed_shot.remains,if=full_recharge_time<gcd&cooldown.bestial_wrath.remains|cooldown.bestial_wrath.remains<12+gcd&talent.scent_of_blood;
	if
		cooldown[BM.BarbedShot].fullRecharge < gcd and not cooldown[BM.BestialWrath].ready or
		cooldown[BM.BarbedShot].ready and cooldown[BM.BestialWrath].remains < 12 + gcd and talents[BM.ScentOfBlood]
	then
		return BM.BarbedShot;
	end

	-- bestial_wrath;
	if cooldown[BM.BestialWrath].ready then
		return BM.BestialWrath;
	end

	-- kill_shot;
	if cooldown[BM.KillShot].ready and targetHp < 0.2 then
		return BM.KillShot;
	end

	-- chimaera_shot;
	if talents[BM.ChimaeraShot] and cooldown[BM.ChimaeraShot].ready then
		return BM.ChimaeraShot;
	end

	-- bloodshed;
	if talents[BM.Bloodshed] and cooldown[BM.Bloodshed].ready then
		return BM.Bloodshed;
	end

	-- a_murder_of_crows;
	if talents[BM.AMurderOfCrows] and cooldown[BM.AMurderOfCrows].ready then
		return BM.AMurderOfCrows;
	end

	-- barrage,if=pet.main.buff.frenzy.remains>execute_time;
	if talents[BM.Barrage] and cooldown[BM.Barrage].ready and pet[BM.Frenzy].remains > 2 then
		return BM.Barrage;
	end

	-- kill_command,if=focus>cost+action.multishot.cost;
	if cooldown[BM.KillCommand].remains < 0.5 and (focus > (30 + 40)) then
		return BM.KillCommand;
	end

	-- dire_beast;
	if talents[BM.DireBeast] and cooldown[BM.DireBeast].ready and focus >= 25 then
		return BM.DireBeast;
	end

	-- barbed_shot,target_if=min:dot.barbed_shot.remains,if=target.time_to_die<9;
	if cooldown[BM.BarbedShot].ready and not debuff[BM.BarbedShotAura].up and timeToDie < 9 then
		return BM.BarbedShot;
	end

	-- cobra_shot,if=focus.time_to_max<gcd*2;
	if fd.focusTimeToMax < (gcd * 2) then
		return BM.CobraShot;
	end
end

function Hunter:BeastMasterySt(fd)
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local targetHp = fd.targetHp;
	local covenantId = fd.covenant.covenantId;
	local gcd = fd.gcd;
	local focus = fd.focus;
	local pet = fd.pet;
	local timeToDie = fd.timeToDie;
	local focusRegen = fd.focusRegen;

	-- barbed_shot,if=pet.main.buff.frenzy.up&pet.main.buff.frenzy.remains<=gcd;
   if cooldown[BM.BarbedShot].ready and pet[BM.Frenzy].up and pet[BM.Frenzy].remains <= gcd then
		return BM.BarbedShot;
	end

	-- bloodshed;
	if talents[BM.Bloodshed] and cooldown[BM.Bloodshed].ready then
		return BM.Bloodshed;
	end

	-- kill_shot,if=buff.flayers_mark.remains<5|target.health.pct<=20;
	if cooldown[BM.KillShot].ready and (buff[BM.FlayersMark].up and buff[BM.FlayersMark].remains < 5 or targetHp <= 0.2) then
		return BM.KillShot;
	end

	-- barbed_shot,if=(cooldown.wild_spirits.remains>full_recharge_time|!covenant.night_fae)&(cooldown.bestial_wrath.remains<12*charges_fractional+gcd&talent.scent_of_blood|full_recharge_time<gcd&cooldown.bestial_wrath.remains)|target.time_to_die<9;
	--if
	--	--( -- CAN'T CHECK THIS BECAUSE ITS COOLDOWN
	--	--	cooldown[BM.WildSpirits].remains > cooldown[BM.BarbedShot].fullRecharge
	--	--		or
	--	--	covenantId ~= Enum.CovenantType.NightFae
	--	--)
	--	--	and
	--	(
	--		cooldown[BM.BestialWrath].remains < 12 * cooldown[BM.BarbedShot].charges + gcd and talents[BM.ScentOfBlood]
	--			or
	--		cooldown[BM.BarbedShot].fullRecharge < gcd and not cooldown[BM.BestialWrath].ready
	--	)
	--		or
	--	timeToDie < 9
	--then
	--	return BM.BarbedShot;
	--end
	if cooldown[BM.BarbedShot].ready and (
		(pet[BM.Frenzy].up and pet[BM.Frenzy].remains < gcd) or
		(cooldown[BM.BestialWrath].remains > 0 and cooldown[BM.BarbedShot].fullRecharge < gcd)
   ) then
      return BM.BarbedShot;
	end

	-- a_murder_of_crows;
	if talents[BM.AMurderOfCrows] and cooldown[BM.AMurderOfCrows].ready then
		return BM.AMurderOfCrows;
	end

	-- bestial_wrath,if=cooldown.wild_spirits.remains>15|!covenant.night_fae|target.time_to_die<15;
	if cooldown[BM.BestialWrath].ready
		--and ( -- can't check because its cooldown
		--cooldown[BM.WildSpirits].remains > 15 or -- CAN'T check because its cooldown
		--covenantId ~= Enum.CovenantType.NightFae or
		--timeToDie < 15)
	then
		return BM.BestialWrath;
	end

	-- chimaera_shot;
	if talents[BM.ChimaeraShot] and cooldown[BM.ChimaeraShot].ready then
		return BM.ChimaeraShot;
	end

	-- kill_command;
   if cooldown[BM.KillCommand].remains < 0.3 then
		return BM.KillCommand;
	end

	-- dire_beast;
	if talents[BM.DireBeast] and cooldown[BM.DireBeast].ready then
		return BM.DireBeast;
	end

	-- cobra_shot,if=(focus-cost+focus.regen*(cooldown.kill_command.remains-1)>action.kill_command.cost|cooldown.kill_command.remains>1+gcd)|(buff.bestial_wrath.up|buff.nesingwarys_trapping_apparatus.up)&!runeforge.qapla_eredun_war_order|target.time_to_die<3;
	if
		(
			focus - 35 + focusRegen * (cooldown[BM.KillCommand].remains - 1) > 30 --cooldown[BM.KillCommand].cost
				or
			cooldown[BM.KillCommand].remains > 1 + gcd
		)
		--	or -- CAN'T CHECK THIS FOR NOW
		--(
		--	buff[BM.BestialWrath].up
		--		or
		--	buff[BM.NesingwarysTrappingApparatus].up
		--)
		--	and
		--not runeforge[BM.QaplaEredunWarOrder]
			or
		timeToDie < 3
	then
		return BM.CobraShot;
	end

	-- TODO: hmm
	-- barbed_shot,if=buff.wild_spirits.up;
	--if buff[BM.WildSpirits].up then
	--	return BM.BarbedShot;
	--end
end