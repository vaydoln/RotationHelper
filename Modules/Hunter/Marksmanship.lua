local _, addonTable = ...;

--- @type RotationHelper
if not RotationHelper then
	return
end
local RotationHelper = RotationHelper;
local Hunter = addonTable.Hunter;

local TableIndexOf = tIndexOf;
local min = min;

--local MM = {
--	--PreciseShots   = 260242,
--	SteadyFocus      = 193534,
--	LoneWolf         = 164273,
--	--TrickShots     = 257622,
--	LockAndLoad      = 194594,
--
--
--	HuntersMark      = 257284,
--	DoubleTap        = 260402,
--	Trueshot         = 288613,
--	AimedShot        = 19434,
--	RapidFire        = 257044,
--	CarefulAim       = 260228,
--	ExplosiveShot    = 212431,
--	Barrage          = 120360,
--	AMurderOfCrows   = 131894,
--	SerpentSting     = 271788,
--	ArcaneShot       = 185358,
--	MasterMarksman   = 269576,
--	Streamline       = 260367,
--	PreciseShots     = 260240,
--	PreciseShotsAura = 260242,
--	PiercingShot     = 198670,
--	SteadyShot       = 56641,
--	TrickShots       = 257622,
--	Multishot        = 257620,
--
--	--Azerite
--	InTheRhythm      = 272733,
--	FocusedFire      = 278531,
--	SurgingShots     = 287707,
--}

local MM = {
	TarTrap              = 187698,
	SoulforgeEmbers      = 336745,
	DoubleTap            = 260402,
	Volley               = 260243,
	AimedShot            = 19434,
	SteadyShot           = 56641,
	CounterShot          = 147362,
	CarefulAim           = 260228,
	SteadyFocus          = 193533,
	SteadyFocusAura      = 193534,
	KillShot             = 53351,
	ResonatingArrow      = 308491,
	RapidFire            = 257044,
	Flare                = 1543,
	ExplosiveShot        = 212431,
	WildSpirits          = 328231,
	FlayedShot           = 324149,
	DeathChakram         = 325028,
	PreciseShots         = 260242,
	ChimaeraShot         = 342049,
	AMurderOfCrows       = 131894,
	Trueshot             = 288613,
	SerpentSting         = 271788,
	TrickShots           = 257622,
	EagletalonsTrueFocus = 336849,
	Streamline           = 260367,
	ArcaneShot           = 185358,
	Barrage              = 120360,
	SurgingShots         = 336867,
	Multishot            = 257620,
	DeadEye              = 321460,
	CallingTheShots      = 260404,
};

local pandemicSpells = {
   [MM.SerpentSting] = MM.SerpentSting,
};

setmetatable(MM, Hunter.spellMeta);

function Hunter:createMarksmanshipEffectsTable()
   local effects = {};

   effects[MM.SteadyShot] = function(fd)
      fd.focus = min(fd.focusMax, fd.focus + 10);
      fd.steadyShots = fd.steadyShots + 1;

      if (fd.talents[MM.SteadyFocus] and fd.steadyShots >= 2) then
         fd = RotationHelper:addSelfBuff(fd, MM.SteadyFocusAura);
      end

      return fd;
   end

   effects[MM.SerpentSting] = function(fd)
      local cost = fd.runeforge[MM.EagletalonsTrueFocus] and 5 or 10;
      fd.focus = fd.focus - cost;
      fd = RotationHelper:addTargetDebuff(fd, MM.SerpentSting);
      return fd;
   end

   effects[MM.AMurderOfCrows] = function(fd)
      local cost = fd.runeforge[MM.EagletalonsTrueFocus] and 10 or 20;
      fd.focus = fd.focus - cost;
      fd = RotationHelper:startCooldown(fd, MM.SerpentSting);
      fd = RotationHelper:addTargetDebuff(fd, MM.SerpentSting);
      return fd;
   end

   effects[MM.Barrage] = function(fd)
      local cost = fd.runeforge[MM.EagletalonsTrueFocus] and 15 or 30;
      fd.focus = fd.focus - cost;
      fd = RotationHelper:startCooldown(fd, MM.Barrage);
      return fd;
   end

   effects[MM.AimedShot] = function(fd)
      local cost = fd.runeforge[MM.EagletalonsTrueFocus] and 18 or 35;
      fd.focus = fd.focus - cost;
      fd = RotationHelper:startCooldown(fd, MM.AimedShot);
      fd = RotationHelper:addSelfBuff(fd, MM.PreciseShots);
      return fd;
   end

   effects[MM.KillShot] = function(fd)
      local cost = fd.runeforge[MM.EagletalonsTrueFocus] and 5 or 10;
      fd.focus = fd.focus - cost;
      fd = RotationHelper:startCooldown(fd, MM.KillShot);
      return fd;
   end

   effects[MM.RapidFire] = function(fd)
      local shots = fd.buff[MM.DoubleTap] and 14 or 7;
      fd.focus = min(fd.focusMax, fd.focus + shots);
      fd = RotationHelper:startCooldown(fd, MM.RapidFire);
      return fd;
   end

   effects[MM.ExplosiveShot] = function(fd)
      local cost = fd.runeforge[MM.EagletalonsTrueFocus] and 10 or 20;
      fd.focus = fd.focus - cost;
      fd = RotationHelper:startCooldown(fd, MM.ExplosiveShot);
      return fd;
   end

   effects[MM.ChimaeraShot] = function(fd)
      local cost = fd.runeforge[MM.EagletalonsTrueFocus] and 10 or 20;
      fd.focus = fd.focus - cost;
      return fd;
   end

   effects[MM.ArcaneShot] = function(fd)
      local cost = fd.runeforge[MM.EagletalonsTrueFocus] and 10 or 20;
      fd.focus = fd.focus - cost;
      if (fd.talents[MM.CallingTheShots]) then
         fd = RotationHelper:reduceCooldown(fd, MM.Trueshot, 2.5);
      end
      if (fd.buff[MM.PreciseShots]) then
         fd = RotationHelper:removeSelfBuff(fd, MM.PreciseShots);
      end
      return fd;
   end

   effects[MM.Multishot] = function(fd)
      local cost = fd.runeforge[MM.EagletalonsTrueFocus] and 10 or 20;
      fd.focus = fd.focus - cost;
      if (fd.targets ~= nil and fd.targets >= 3) then
         fd = RotationHelper:addSelfBuff(fd, MM.TrickShots);
      end
      if (fd.talents[MM.CallingTheShots]) then
         fd = RotationHelper:reduceCooldown(fd, MM.Trueshot, 2.5);
      end
      if (fd.buff[MM.PreciseShots]) then
         fd = RotationHelper:removeSelfBuff(fd, MM.PreciseShots);
      end
      return fd;
   end

   effects[MM.Trueshot] = function(fd)
      fd = RotationHelper:addSelfBuff(fd, MM.Trueshot);
      fd = RotationHelper:startCooldown(fd, MM.Trueshot);
      return fd;
   end

   effects[MM.FlayedShot] = function(fd)
      fd.focus = fd.focus - 10;
      fd = RotationHelper:startCooldown(fd, MM.FlayedShot);
      return fd;
   end

   effects[MM.CounterShot] = RotationHelper:normalCooldownEffect(MM.CounterShot);
   effects[MM.TarTrap] = RotationHelper:normalCooldownEffect(MM.TarTrap);
   effects[MM.Volley] = RotationHelper:normalCooldownEffect(MM.Volley);
   effects[MM.Flare] = RotationHelper:normalCooldownEffect(MM.Flare);
   effects[MM.DeathChakram] = RotationHelper:normalCooldownEffect(MM.DeathChakram);
   effects[MM.WildSpirits] = RotationHelper:normalCooldownEffect(MM.WildSpirits);
   effects[MM.ResonatingArrow] = RotationHelper:normalCooldownEffect(MM.ResonatingArrow);

   return effects;
end

local MMEffect = Hunter:createMarksmanshipEffectsTable();

function Hunter:MarksmanshipPrep(fd)
	fd.focus, fd.focusMax, fd.focusRegen = Hunter:Focus(0, fd.timeShift);
	fd.targetHp = RotationHelper:TargetPercentHealth() * 100;
	fd.targets = RotationHelper:SmartAoe();

   fd.steadyShots = 0;
   if (fd.spellHistory[1] == MM.SteadyShot) then
      fd.steadyShots = 1;
      if (fd.spellHistory[2] == MM.SteadyShot) then
         fd.steadyShots = 2;
      end
   end

   if (fd.currentSpell and MMEffect[fd.currentSpell]) then
      local updateFrameData = MMEffect[fd.currentSpell];
      fd = updateFrameData(fd);
   end

   return fd;
end

function Hunter:Marksmanship(fd)
   local spellId = Hunter:chooseMarksmanshipSpellId(fd);
   local retVal = {
      id = spellId,
   };

   if (spellId and MMEffect[spellId]) then
      retVal.updateFrameData = MMEffect[spellId];
   end

   if (spellId) then
      retVal.pandemicId = pandemicSpells[spellId];
   end

   return retVal;
end

function Hunter:chooseMarksmanshipSpellId(fd)
	local cooldown = fd.cooldown;
	local currentSpell = fd.currentSpell;
	local canAimed = cooldown[MM.AimedShot].charges >= 2 or (cooldown[MM.AimedShot].ready and currentSpell ~= MM.AimedShot);
   fd.canAimed = canAimed;

   -- call_action_list,name=cds;
   if (fd.recurseIndex == 1) then
      Hunter:MarksmanshipCds(fd);
   end

	-- call_action_list,name=st,if=active_enemies<3;
	if fd.targets < 3 then
		return Hunter:MarksmanshipSt(fd);
	else
		-- call_action_list,name=trickshots,if=active_enemies>2;
		return Hunter:MarksmanshipTrickshots(fd);
	end
end

function Hunter:MarksmanshipCds(fd)
	local cooldown = fd.cooldown;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local gcd = fd.gcd;
	local timeToDie = fd.timeToDie;
	local targetHp = fd.targetHp;
	local covenantId = fd.covenant.covenantId;

	-- trueshot,if=buff.precise_shots.down|buff.resonating_arrow.up|buff.wild_spirits.up|buff.volley.up&active_enemies>1;
	--if cooldown[MM.Trueshot].ready and (not buff[MM.PreciseShots].up or buff[MM.ResonatingArrow].up or buff[MM.WildSpirits].up or buff[MM.Volley].up and targets > 1) then
	--	return MM.Trueshot;
	--end
	RotationHelper:GlowCooldown(
		MM.Trueshot,
		cooldown[MM.Trueshot].ready and (
			not cooldown[MM.RapidFire].up and timeToDie > cooldown[MM.Trueshot].duration + cooldown[MM.Trueshot].duration or
			(targetHp < 20 or not talents[MM.CarefulAim]) or
			timeToDie < 15
		)
	);

	-- double_tap,if=cooldown.rapid_fire.remains<gcd.max|target.time_to_die<20;
	RotationHelper:GlowCooldown(
		MM.DoubleTap,
		talents[MM.DoubleTap] and cooldown[MM.DoubleTap].ready and (cooldown[MM.RapidFire].remains < gcd or timeToDie < 20)
	);

	if covenantId == Enum.CovenantType.Kyrian then
		RotationHelper:GlowCooldown(MM.ResonatingArrow, cooldown[MM.ResonatingArrow].ready);
	elseif covenantId == Enum.CovenantType.NightFae then
		RotationHelper:GlowCooldown(MM.WildSpirits, cooldown[MM.WildSpirits].ready);
	elseif covenantId == Enum.CovenantType.Necrolord then
		RotationHelper:GlowCooldown(MM.DeathChakram, cooldown[MM.DeathChakram].ready);
	elseif covenantId == Enum.CovenantType.Venthyr then
		RotationHelper:GlowCooldown(MM.FlayedShot, cooldown[MM.FlayedShot].ready);
	end
end

function Hunter:MarksmanshipSt(fd)
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local gcd = fd.gcd;
	local timeShift = fd.timeShift;
	local targets = fd.targets;
	local targetHp = fd.targetHp;
	local spellHistory = fd.spellHistory;
	local timeToDie = fd.timeToDie;
	local focus = fd.focus;
	local castRegen = fd.focusRegen;
	local focusMax = fd.focusMax;

	local caExecute = targetHp < 20 or targetHp > 70;
	local canAimed = fd.canAimed;

	local AimedShotCost = 35;
	local ChimaeraShotCost = 20;
	local ArcaneShotCost = 20;

	local PreciseShotsUp = buff[MM.PreciseShots].up or currentSpell == MM.AimedShot;
	local TrickShotsUp = buff[MM.TrickShots].up and not (currentSpell == MM.RapidFire or currentSpell == MM.AimedShot);

	-- steady_shot,if=talent.steady_focus&(prev_gcd.1.steady_shot&buff.steady_focus.remains<5|buff.steady_focus.down);
   if talents[MM.SteadyFocus] 
   and buff[MM.SteadyFocusAura].remains < 6
   and (fd.steadyShots == 0 or fd.steadyShots == 1)
   then
   	return MM.SteadyShot;
	end

	-- kill_shot;
	if cooldown[MM.KillShot].ready and targetHp < 20 and focus >= 10 then
		return MM.KillShot;
	end

	-- explosive_shot;
	if talents[MM.ExplosiveShot] and cooldown[MM.ExplosiveShot].ready and focus >= 20 then
		return MM.ExplosiveShot;
	end

	-- volley,if=buff.precise_shots.down|!talent.chimaera_shot|active_enemies<2;
	if talents[MM.Volley] and cooldown[MM.Volley].ready and
		(not PreciseShotsUp or not talents[MM.ChimaeraShot] or targets < 2)
	then
		return MM.Volley;
	end

	-- a_murder_of_crows;
	if talents[MM.AMurderOfCrows] and cooldown[MM.AMurderOfCrows].ready and focus >= 20 then
		return MM.AMurderOfCrows;
	end

	-- aimed_shot,target_if=min:(dot.serpent_sting.remains<?action.serpent_sting.in_flight_to_target*dot.serpent_sting.duration),if=buff.precise_shots.down|(buff.trueshot.up|full_recharge_time<gcd+cast_time)&(!talent.chimaera_shot|active_enemies<2)|buff.trick_shots.remains>execute_time&active_enemies>1;
	if focus >= 30 and canAimed and (
		not PreciseShotsUp
			or
		(buff[MM.Trueshot].up or cooldown[MM.AimedShot].fullRecharge < gcd + timeShift) and (not talents[MM.ChimaeraShot] or targets < 2)
			or
		TrickShotsUp and targets > 1
	) then
		return MM.AimedShot;
	end

	-- rapid_fire,if=focus+cast_regen<focus.max&(buff.trueshot.down|!runeforge.eagletalons_true_focus)&(buff.double_tap.down|talent.streamline);
	if cooldown[MM.RapidFire].ready and (
		focus + castRegen < focusMax and (
			not buff[MM.Trueshot].up --or
			--not runeforge[MM.EagletalonsTrueFocus]
		) and (
			not buff[MM.DoubleTap].up or talents[MM.Streamline]
		)
	) then
		return MM.RapidFire;
	end

	if talents[MM.ChimaeraShot] then
		-- chimaera_shot,if=buff.precise_shots.up|focus>cost+action.aimed_shot.cost;
		if (PreciseShotsUp or focus > ChimaeraShotCost + AimedShotCost) then
			return MM.ChimaeraShot;
		end
	else
		-- arcane_shot,if=buff.precise_shots.up|focus>cost+action.aimed_shot.cost;
		if focus >= 15 and (PreciseShotsUp or focus > ArcaneShotCost + AimedShotCost) then
			return MM.ArcaneShot;
		end
	end

	-- serpent_sting,target_if=min:remains,if=refreshable&target.time_to_die>duration;
	if talents[MM.SerpentSting] and focus >= 10 and
		debuff[MM.SerpentSting].remains > 0 and
		debuff[MM.SerpentSting].refreshable and
		timeToDie > cooldown[MM.SerpentSting].duration
	then
		return MM.SerpentSting;
	end

	-- barrage,if=active_enemies>1;
	if talents[MM.Barrage] and cooldown[MM.Barrage].ready and focus >= 30 and targets > 1 then
		return MM.Barrage;
	end

	-- rapid_fire,if=focus+cast_regen<focus.max&(buff.double_tap.down|talent.streamline);
	if cooldown[MM.RapidFire].ready and
		focus + castRegen < focusMax and
		(not buff[MM.DoubleTap].up or talents[MM.Streamline])
	then
		return MM.RapidFire;
	end

	-- steady_shot;
	return MM.SteadyShot;
end

function Hunter:MarksmanshipTrickshots(fd)
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local focus = fd.focus;
	local targets = fd.targets;
	local timeShift = fd.timeShift;
	local gcd = fd.gcd;
	local canAimed = fd.canAimed;
	local targetHp = fd.targetHp;
	local spellHistory = fd.spellHistory;

	local PreciseShotsUp = buff[MM.PreciseShots].up or currentSpell == MM.AimedShot;
	local TrickShotsUp = buff[MM.TrickShots].up and not (currentSpell == MM.RapidFire or currentSpell == MM.AimedShot);

	local MultishotCost = 20;
	local AimedShotCost = 35;
	local ChimaeraShotCost = 20;

	-- steady_shot,if=talent.steady_focus&in_flight&buff.steady_focus.remains<5;
   if talents[MM.SteadyFocus] 
   and buff[MM.SteadyFocusAura].remains < 5 
   and (fd.steadyShots == 0 or fd.steadyShots == 1)
   then
   	return MM.SteadyShot;
	end

	-- explosive_shot;
	if talents[MM.ExplosiveShot] and cooldown[MM.ExplosiveShot].ready and focus >= 20 then
		return MM.ExplosiveShot;
	end

	-- volley;
	if talents[MM.Volley] and cooldown[MM.Volley].ready then
		return MM.Volley;
	end

	-- barrage;
	if talents[MM.Barrage] and cooldown[MM.Barrage].ready and focus >= 30 then
		return MM.Barrage;
	end

	-- rapid_fire,if=buff.trick_shots.remains>=execute_time&runeforge.surging_shots&buff.double_tap.down;
	-- TODO: NOT POSSIBLE FOR NOW
	--if cooldown[MM.RapidFire].ready and (
	--	buff[MM.TrickShots].remains >= timeShift and
	--	runeforge[MM.SurgingShots] and
	--	not buff[MM.DoubleTap].up
	--) then
	--	return MM.RapidFire;
	--end

	-- aimed_shot,target_if=min:(dot.serpent_sting.remains<?action.serpent_sting.in_flight_to_target*dot.serpent_sting.duration),if=buff.trick_shots.remains>=execute_time&(buff.precise_shots.down|full_recharge_time<cast_time+gcd|buff.trueshot.up);
	if focus >= 30 and canAimed and (
		TrickShotsUp and
		(not PreciseShotsUp or cooldown[MM.AimedShot].fullRecharge < timeShift + gcd or buff[MM.Trueshot].up)
	) then
		return MM.AimedShot;
	end

	-- rapid_fire,if=buff.trick_shots.remains>=execute_time;
	if cooldown[MM.RapidFire].ready and TrickShotsUp then
		return MM.RapidFire;
	end

	-- multishot,if=buff.trick_shots.down|buff.precise_shots.up&focus>cost+action.aimed_shot.cost&(!talent.chimaera_shot|active_enemies>3);
	if focus >= 15 and (
		not TrickShotsUp or
		PreciseShotsUp and focus > MultishotCost + AimedShotCost and (not talents[MM.ChimaeraShot] or targets > 3)
	) then
		return MM.Multishot;
	end

	-- chimaera_shot,if=buff.precise_shots.up&focus>cost+action.aimed_shot.cost&active_enemies<4;
	if talents[MM.ChimaeraShot] and PreciseShotsUp and
		focus > ChimaeraShotCost + AimedShotCost and targets < 4
	then
		return MM.ChimaeraShot;
	end

	-- kill_shot,if=buff.dead_eye.down;
	if cooldown[MM.KillShot].ready and targetHp < 20 and focus >= 10 and not buff[MM.DeadEye].up then
		return MM.KillShot;
	end

	-- a_murder_of_crows;
	if talents[MM.AMurderOfCrows] and cooldown[MM.AMurderOfCrows].ready and focus >= 20 then
		return MM.AMurderOfCrows;
	end

	-- serpent_sting,target_if=min:dot.serpent_sting.remains,if=refreshable;
	if talents[MM.SerpentSting] and focus >= 10 and debuff[MM.SerpentSting].refreshable then
		return MM.SerpentSting;
	end

	-- multishot,if=focus>cost+action.aimed_shot.cost;
	if focus > MultishotCost + AimedShotCost then
		return MM.Multishot;
	end

	-- steady_shot;
	return MM.SteadyShot;
end