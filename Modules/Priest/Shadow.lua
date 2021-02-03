local _, addonTable = ...;

if not RotationHelper then
	return
end

local Priest = addonTable.Priest;

local RotationHelper = RotationHelper;
local UnitPower = UnitPower;

local Necrolord = Enum.CovenantType.Necrolord;
local Venthyr = Enum.CovenantType.Venthyr;
local NightFae = Enum.CovenantType.NightFae;
local Kyrian = Enum.CovenantType.Kyrian;

local SH = {
	Shadowform         = 232698,
	VampiricTouch      = 34914,
	ShadowWordPain     = 589,
	DevouringPlague    = 335467,
	Voidform           = 194249,
	VoidEruption       = 228260,
	HungeringVoid      = 345218,
	AscendedBlast      = 325283,
	AscendedNova       = 325020,
	SearingNightmare   = 341385,
	PowerInfusion      = 10060,
	Silence            = 15487,
	BoonOfTheAscended  = 325013,
	VoidBolt           = 205448,
	Mindgames          = 323673,
	UnholyNova         = 324724,
	MindBlast          = 8092,
	Fiend              = 34433,
	FaeGuardians       = 327661,
	WrathfulFaerie     = 342132,
	MindSear           = 48045,
	Damnation          = 341374,
	ShadowWordDeath    = 32379,
	SurrenderToMadness = 193223,
	VoidTorrent        = 263165,
	TwistOfFate        = 109142,
	Mindbender         = 200174,
	ShadowCrash        = 205385,
	DarkThought        = 341207,
	MindFlay           = 15407,
	Misery             = 238558,
	UnfurlingDarkness  = 341273,
	PsychicLink        = 199484,
	Shadowfiend        = 34433,
	DissonantEchoes    = 123,
	DissonantEchoesAura = 343144,

	-- bonus id
	ShadowflamePrismBonusId = 6982,
	PainbreakerPsalmBonusId = 6981,
};

setmetatable(SH, Priest.spellMeta);

function Priest:createShadowEffectsTable()
   local effects = {};

   -- TODO: spec - spriest

   -- effects[SH.BarbedShot] = function(fd)
   --    fd = RotationHelper:startCooldown(fd, SH.BarbedShot);
   --    fd = RotationHelper:reduceCooldown(fd, SH.BestialWrath, 12);
   --    fd = RotationHelper:addTargetDebuff(fd, SH.BarbedShotAura);
   --    fd.pet = RotationHelper:addAura(fd.pet, SH.Frenzy);
   --    return fd;
   -- end

   -- effects[SH.Multishot] = function(fd)
   --    fd.focus = fd.focus - 40;
   --    return fd;
   -- end

   -- effects[SH.ResonatingArrow] = RotationHelper:normalCooldownEffect(SH.ResonatingArrow);

   return effects;
end

local SHEffect = Priest:createShadowEffectsTable();

function Priest:ShadowAfterSpell(fd)
   return fd;
end

function Priest:ShadowPrep(fd)
	fd.insanity = UnitPower('player', Enum.PowerType.Insanity);
	fd.insanityMax = UnitPowerMax('player', Enum.PowerType.Insanity);
   fd.targets = RotationHelper:SmartAoe();

	fd.fiendActive = false;
	if fd.talents[SH.Mindbender] then
		fd.fiendActive = fd.cooldown[SH.Mindbender].remains > 45;
	else
		fd.fiendActive = fd.cooldown[SH.Shadowfiend].remains > 165;
	end

	-- variable,name=dots_up,op=set,value=dot.shadow_word_pain.ticking&dot.vampiric_touch.ticking;
	fd.dotsUp = fd.debuff[SH.ShadowWordPain].up and fd.debuff[SH.VampiricTouch].up;

	-- variable,name=all_dots_up,op=set,value=dot.shadow_word_pain.ticking&dot.vampiric_touch.ticking&dot.devouring_plague.ticking;
	fd.allDotsUp = fd.debuff[SH.ShadowWordPain].up and fd.debuff[SH.VampiricTouch].up and fd.debuff[SH.DevouringPlague].up;

	-- variable,name=searing_nightmare_cutoff,op=set,value=spell_targets.mind_sear>2+buff.voidform.up;
	fd.searingNightmareCutoff = fd.targets > 2 + (fd.buff[SH.Voidform].up and 1 or 0);
	fd.mindSearCutoff = 2;

	-- variable,name=pool_for_cds,op=set,value=cooldown.void_eruption.up&(!raid_event.adds.up|raid_event.adds.duration<=10|raid_event.adds.remains>=10+5*(talent.hungering_void.enabled|covenant.kyrian))&((raid_event.adds.in>20|spell_targets.void_eruption>=5)|talent.hungering_void.enabled|covenant.kyrian);
	fd.poolForCds = fd.cooldown[SH.VoidEruption].up;

   if (fd.currentSpell and SHEffect[fd.currentSpell]) then
      local updateFrameData = SHEffect[fd.currentSpell];
      fd = updateFrameData(fd);
   end

   return fd;
end

function Priest:Shadow(fd)
   local spellId = Priest:chooseShadowSpellId(fd);
   local retVal = {
      id = spellId,
   };

   if (spellId and SHEffect[spellId]) then
      retVal.updateFrameData = SHEffect[spellId];
   end

   Priest:GlowShadowCds(fd);

   return retVal;
end

function Priest:GlowShadowCds(fd)
	local cooldown = fd.cooldown;
	local talents = fd.talents;
	local timeToDie = fd.timeToDie;
	local covenantId = fd.covenant.covenantId;
   local Fiend = talents[SH.Mindbender] and SH.Mindbender or SH.Shadowfiend;

	RotationHelper:GlowCooldown(SH.PowerInfusion, cooldown[SH.PowerInfusion].ready);
	RotationHelper:GlowCooldown(SH.VoidEruption, cooldown[SH.VoidEruption].ready);

	if not talents[SH.Mindbender] then
		RotationHelper:GlowCooldown(Fiend, cooldown[Fiend].ready);
	end

	if talents[SH.SurrenderToMadness] then
		RotationHelper:GlowCooldown(SH.SurrenderToMadness, cooldown[SH.SurrenderToMadness].ready and timeToDie < 25)
	end

	if covenantId == Kyrian then
		RotationHelper:GlowCooldown(SH.BoonOfTheAscended, cooldown[SH.BoonOfTheAscended].ready);
	elseif covenantId == Venthyr then
		RotationHelper:GlowCooldown(SH.Mindgames, cooldown[SH.Mindgames].ready);
	elseif covenantId == NightFae then
		RotationHelper:GlowCooldown(SH.FaeGuardians, cooldown[SH.FaeGuardians].ready);
	elseif covenantId == Necrolord then
		RotationHelper:GlowCooldown(SH.UnholyNova, cooldown[SH.UnholyNova].ready);
	end
end

function Priest:chooseShadowSpellId(fd)
	local talents = fd.talents;

	-- call_action_list,name=cwc;
	local result = Priest:ShadowCwc(fd);
	if result then
		return result;
	end

	-- run_action_list,name=main;
	return Priest:ShadowMain(fd);
end

function Priest:ShadowBoon(fd)
	local cooldown = fd.cooldown;
	local talents = fd.talents;
	local targets = fd.targets;

	-- ascended_blast,if=spell_targets.mind_sear<=3;
	if cooldown[SH.AscendedBlast].ready and (targets <= 3) then
		return SH.AscendedBlast;
	end

	-- ascended_nova,if=spell_targets.ascended_nova>1&spell_targets.mind_sear>1+talent.searing_nightmare.enabled;
	if targets > 1 and targets > 1 + talents[SH.SearingNightmare] then
		return SH.AscendedNova;
	end
end

function Priest:ShadowCwc(fd)
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets;
	local poolForCds = fd.poolForCds;
	local searingNightmareCutoff = fd.searingNightmareCutoff;
	local insanity = fd.insanity;
	local cooldown = fd.cooldown;
	local currentSpell = fd.currentSpell;

	-- searing_nightmare,use_while_casting=1,target_if=(variable.searing_nightmare_cutoff&!variable.pool_for_cds)|(dot.shadow_word_pain.refreshable&spell_targets.mind_sear>1);
	if talents[SH.SearingNightmare] and
		insanity >= 30 and
		(
			(searingNightmareCutoff and not poolForCds) or
			(debuff[SH.ShadowWordPain].refreshable and targets > 1)
		)
	then
		return SH.SearingNightmare;
	end

	-- searing_nightmare,use_while_casting=1,target_if=talent.searing_nightmare.enabled&dot.shadow_word_pain.refreshable&spell_targets.mind_sear>2;
	if talents[SH.SearingNightmare] and
		insanity >= 30 and
		debuff[SH.ShadowWordPain].refreshable and
		targets > 2
	then
		return SH.SearingNightmare;
	end

	-- mind_blast,only_cwc=1;
	if currentSpell ~= SH.MindBlast and
		cooldown[SH.MindBlast].ready
	then
		return SH.MindBlast;
	end
end

function Priest:ShadowMain(fd)
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local targets = fd.targets;
	local timeToDie = fd.timeToDie;
	local insanity = fd.insanity;
	local runeforge = fd.runeforge;
	local covenantId = fd.covenant.covenantId;
	local poolForCds = fd.poolForCds;
	local searingNightmareCutoff = fd.searingNightmareCutoff;
	local mindSearCutoff = fd.mindSearCutoff;
	local dotsUp = fd.dotsUp;
	local allDotsUp = fd.allDotsUp;
	local fiendActive = fd.fiendActive;
	local conduit = fd.covenant.soulbindConduits;
	local targetHp = RotationHelper:TargetPercentHealth() * 100;

	-- call_action_list,name=boon,if=buff.boon_of_the_ascended.up;
	if buff[SH.BoonOfTheAscended].up then
		local result = Priest:ShadowBoon(fd);
		if result then
			return result;
		end
	end

	-- void_eruption,if=variable.pool_for_cds&insanity>=40&(insanity<=85|talent.searing_nightmare.enabled&variable.searing_nightmare_cutoff)&!cooldown.fiend.up;
	--if cooldown[SH.VoidEruption].ready and
	--	poolForCds and
	--	insanity >= 40 and
	--	(insanity <= 85 or talents[SH.SearingNightmare] and searingNightmareCutoff) --and
	--	--not cooldown[SH.Fiend].up
	--then
	--	return SH.VoidEruption;
	--end

	-- shadow_word_pain,if=buff.fae_guardians.up&!debuff.wrathful_faerie.up;
	if covenantId == NightFae and buff[SH.FaeGuardians].up and not debuff[SH.WrathfulFaerie].up then
		return SH.ShadowWordPain;
	end

	-- mind_sear,target_if=talent.searing_nightmare.enabled&spell_targets.mind_sear>variable.mind_sear_cutoff&!dot.shadow_word_pain.ticking&!cooldown.fiend.up;
	if talents[SH.SearingNightmare] and
		targets > mindSearCutoff and
		not debuff[SH.ShadowWordPain].up
	then
		return SH.MindSear;
	end

	-- damnation,target_if=!variable.all_dots_up;
	if talents[SH.Damnation] and cooldown[SH.Damnation].ready and not allDotsUp then
		return SH.Damnation;
	end

	-- void_bolt,if=insanity<=85&talent.hungering_void.enabled&talent.searing_nightmare.enabled&spell_targets.mind_sear<=6|((talent.hungering_void.enabled&!talent.searing_nightmare.enabled)|spell_targets.mind_sear=1);
	if (buff[SH.Voidform].up and cooldown[SH.VoidBolt].ready or buff[SH.DissonantEchoesAura].up) and
		(
			insanity <= 85 and talents[SH.HungeringVoid] and talents[SH.SearingNightmare] and targets <= 6 or
			((talents[SH.HungeringVoid] and not talents[SH.SearingNightmare]) or targets <= 1)
		)
	then
		return SH.VoidBolt;
	end

	-- devouring_plague,target_if=(refreshable|insanity>75)&(!variable.pool_for_cds|insanity>=85)&(!talent.searing_nightmare.enabled|(talent.searing_nightmare.enabled&!variable.searing_nightmare_cutoff));
	if insanity >= 50 and (
		(debuff[SH.DevouringPlague].refreshable or insanity > 75) and
		(not poolForCds or insanity >= 85) and
		(not talents[SH.SearingNightmare] or (
			talents[SH.SearingNightmare] and not searingNightmareCutoff
		))
	) then
		return SH.DevouringPlague;
	end

	-- void_bolt,if=spell_targets.mind_sear<(4+conduit.dissonant_echoes.enabled)&insanity<=85&talent.searing_nightmare.enabled|!talent.searing_nightmare.enabled;
	if (buff[SH.Voidform].up and cooldown[SH.VoidBolt].ready or buff[SH.DissonantEchoesAura].up) and
		(
			targets < (4 + (conduit[SH.DissonantEchoes] and 1 or 0)) and insanity <= 85 and talents[SH.SearingNightmare] or
			not talents[SH.SearingNightmare]
		)
	then
		return SH.VoidBolt;
	end

	-- shadow_word_death,target_if=(target.health.pct<20&spell_targets.mind_sear<4)|(pet.fiend.active&runeforge.shadowflame_prism.equipped);
	if talents[SH.ShadowWordDeath] and (
		(targetHp < 20 and targets < 4) or
		(fiendActive and runeforge[SH.ShadowflamePrismBonusId])
	) then
		return SH.ShadowWordDeath;
	end

	-- surrender_to_madness,target_if=target.time_to_die<25&buff.voidform.down;
	--if talents[SH.SurrenderToMadness] and cooldown[SH.SurrenderToMadness].ready then
	--	return SH.SurrenderToMadness;
	--end

	-- void_torrent,target_if=variable.dots_up&target.time_to_die>3&buff.voidform.down&active_dot.vampiric_touch==spell_targets.vampiric_touch&spell_targets.mind_sear<(5+(6*talent.twist_of_fate.enabled));
	if talents[SH.VoidTorrent] and
		cooldown[SH.VoidTorrent].ready and
		not buff[SH.Voidform].up and
		targets < (5 + (talents[SH.TwistOfFate] and 6 or 0))
	then
		return SH.VoidTorrent;
	end

	-- mindbender,if=dot.vampiric_touch.ticking&(talent.searing_nightmare.enabled&spell_targets.mind_sear>variable.mind_sear_cutoff|dot.shadow_word_pain.ticking);
	if talents[SH.Mindbender] and
		cooldown[SH.Mindbender].ready and
		debuff[SH.VampiricTouch].up and
		(talents[SH.SearingNightmare] and targets > mindSearCutoff or debuff[SH.ShadowWordPain].up)
	then
		return SH.Mindbender;
	end

	-- shadow_word_death,if=runeforge.painbreaker_psalm.equipped&variable.dots_up&target.time_to_pct_20>(cooldown.shadow_word_death.duration+gcd);
	if talents[SH.ShadowWordDeath] and (
		runeforge[SH.PainbreakerPsalmBonusId] and
		dotsUp and
		targetHp < 20
	) then
		return SH.ShadowWordDeath;
	end

	-- shadow_crash,if=raid_event.adds.in>10;
	if talents[SH.ShadowCrash] and cooldown[SH.ShadowCrash].ready then
		return SH.ShadowCrash;
	end

	-- mind_sear,target_if=spell_targets.mind_sear>variable.mind_sear_cutoff&buff.dark_thought.up,chain=1,interrupt_immediate=1,interrupt_if=ticks>=2;
	if targets > mindSearCutoff and buff[SH.DarkThought].up	then
		return SH.MindSear;
	end

	-- mind_flay,if=buff.dark_thought.up&variable.dots_up,chain=1,interrupt_immediate=1,interrupt_if=ticks>=2&cooldown.void_bolt.up;
	if buff[SH.DarkThought].up and dotsUp then
		return SH.MindFlay;
	end

	-- mind_blast,if=variable.dots_up&raid_event.movement.in>cast_time+0.5&(spell_targets.mind_sear<4&!talent.misery.enabled|spell_targets.mind_sear<6&talent.misery.enabled);
	if currentSpell ~= SH.MindBlast and
		cooldown[SH.MindBlast].ready and
		dotsUp and
		(targets < 4 and not talents[SH.Misery] or targets < 6 and talents[SH.Misery])
	then
		return SH.MindBlast;
	end

	-- vampiric_touch,target_if=refreshable&target.time_to_die>6|(talent.misery.enabled&dot.shadow_word_pain.refreshable)|buff.unfurling_darkness.up;
	if currentSpell ~= SH.VampiricTouch and
		(
			debuff[SH.VampiricTouch].refreshable or
			(talents[SH.Misery] and debuff[SH.ShadowWordPain].refreshable) or
			buff[SH.UnfurlingDarkness].up
		)
	then
		return SH.VampiricTouch;
	end

	-- shadow_word_pain,if=refreshable&target.time_to_die>4&!talent.misery.enabled&talent.psychic_link.enabled&spell_targets.mind_sear>2;
	if debuff[SH.ShadowWordPain].refreshable and
		timeToDie > 4 and
		not talents[SH.Misery] and
		talents[SH.PsychicLink] and
		targets > 2
	then
		return SH.ShadowWordPain;
	end

	-- shadow_word_pain,target_if=refreshable&target.time_to_die>4&!talent.misery.enabled&!(talent.searing_nightmare.enabled&spell_targets.mind_sear>variable.mind_sear_cutoff)&(!talent.psychic_link.enabled|(talent.psychic_link.enabled&spell_targets.mind_sear<=2));
	if debuff[SH.ShadowWordPain].refreshable and
		timeToDie > 4 and
		not talents[SH.Misery] and
		not (talents[SH.SearingNightmare] and targets > mindSearCutoff) and
		(not talents[SH.PsychicLink] or (talents[SH.PsychicLink] and targets <= 2))
	then
		return SH.ShadowWordPain;

	end

	-- mind_sear,target_if=spell_targets.mind_sear>variable.mind_sear_cutoff,chain=1,interrupt_immediate=1,interrupt_if=ticks>=2;
	if targets > mindSearCutoff then
		return SH.MindSear;
	end

	-- mind_flay,chain=1,interrupt_immediate=1,interrupt_if=ticks>=2&cooldown.void_bolt.up;
	if currentSpell ~= SH.MindFlay then
		return SH.MindFlay;
	end

	-- shadow_word_death;
	if talents[SH.ShadowWordDeath] and targetHp < 20 then
		return SH.ShadowWordDeath;
	end

	-- shadow_word_pain;
	return SH.ShadowWordPain;
end