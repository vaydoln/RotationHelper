local _, addonTable = ...;

--- @type RotationHelper
if not RotationHelper then
	return
end

local Druid = addonTable.Druid;
local RotationHelper = RotationHelper;
local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;
local GetTime = GetTime;
local Energy = Enum.PowerType.Energy;
local ComboPoints = Enum.PowerType.ComboPoints;

local Necrolord = Enum.CovenantType.Necrolord;
local Venthyr = Enum.CovenantType.Venthyr;
local NightFae = Enum.CovenantType.NightFae;
local Kyrian = Enum.CovenantType.Kyrian;

local FR = {
	Bloodtalons       = 319439,
	BloodtalonsAura   = 145152,
	CatForm           = 768,
	Prowl             = 5215,
	Starsurge         = 197626,
	Sunfire           = 197630,
	TigersFury        = 5217,
	Rake              = 1822,
	RakeAura          = 155722,
	Rip               = 1079,
	Clearcasting      = 135700,
	BalanceAffinity   = 197488,
	ConvokeTheSpirits = 323764,
	MoonkinForm       = 197625,
	FerociousBite     = 22568,
	FeralFrenzy       = 274837,
	Moonfire          = 155625,
	BrutalSlash       = 202028,
	Shred             = 5221,
	Swipe             = 106785,
	LunarInspiration  = 155580,
	HeartOfTheWild    = 319454,
	Thrash            = 106830,
	Berserk           = 106951,
	Incarnation       = 102543,
	Predator          = 202021,
	KindredSpirits    = 326434,
	AdaptiveSwarm     = 325727,
	AdaptiveSwarmAura = 325733,
	SavageRoar        = 52610,
	PrimalWrath       = 285381,
	Sabertooth        = 202031,
	RavenousFrenzy    = 323546,
	SunfireAura       = 164815,
	MoonfireAura      = 164812,

	SuddenAmbush      = 340698,

	-- leggo buffs
	ApexPredatorsCraving = 339140,
};

local pandemicSpells = {
   [FR.Sunfire] = FR.SunfireAura,
   [FR.Moonfire] = FR.MoonfireAura,
   [FR.Rake] = FR.RakeAura,
   [FR.Rip] = FR.Rip,
   [FR.Thrash] = FR.Thrash,
};

setmetatable(FR, Druid.spellMeta);

local filler = 0;

-- timestamp when ability was used last time
local BtBuffSource = {
   [FR.Rake] = 0,
	[FR.Shred] = 0,
	[FR.Swipe] = 0,
	[FR.Thrash] = 0,
	[FR.Moonfire] = 0,
	[FR.BrutalSlash] = 0,
}

local BtBuffCopy = {};

function Druid:createFeralEffectsTable()
   local effects = {};

   -- TODO: spec - feral druid

   effects[FR.Moonfire] = function(fd)
      if (fd.talents[FR.LunarInspiration]) then
         fd = Druid:feralSpendEnergy(fd, 30);
         fd = Druid:feralGainComboPoints(fd, 1);
      end
      fd = RotationHelper:addTargetDebuff(fd, FR.MoonfireAura);
      return fd;
   end

   effects[FR.Sunfire] = function(fd)
      fd = RotationHelper:addTargetDebuff(fd, FR.SunfireAura);
      return fd;
   end

   effects[FR.AdaptiveSwarm] = function(fd)
      fd = RotationHelper:startCooldown(fd, FR.AdaptiveSwarm);
      fd = RotationHelper:addTargetDebuff(fd, FR.AdaptiveSwarmAura);
      return fd;
   end

   effects[FR.TigersFury] = function(fd)
      fd = Druid:feralGainEnergy(fd, 50);
      fd = RotationHelper:startCooldown(fd, FR.TigersFury);
      fd = RotationHelper:addSelfBuff(fd, FR.TigersFury);
      return fd;
   end

   effects[FR.Rake] = function(fd)
      fd = Druid:feralSpendEnergy(fd, 35);
      fd = Druid:feralGainComboPoints(fd, 1);
      fd = RotationHelper:addTargetDebuff(fd, FR.RakeAura);
      return fd;
   end

   effects[FR.Thrash] = function(fd)
      fd = Druid:feralSpendEnergy(fd, 40);
      fd = Druid:feralGainComboPoints(fd, 1);
      fd = RotationHelper:addTargetDebuff(fd, FR.Thrash);
      return fd;
   end

   effects[FR.Shred] = function(fd)
      fd = Druid:feralSpendEnergy(fd, 40);
      fd = Druid:feralGainComboPoints(fd, 1);
      return fd;
   end

   effects[FR.FeralFrenzy] = function(fd)
      fd = Druid:feralSpendEnergy(fd, 25);
      fd = Druid:feralGainComboPoints(fd, 5);
      fd = RotationHelper:startCooldown(fd, FR.FeralFrenzy);
      return fd;
   end

   effects[FR.BrutalSlash] = function(fd)
      fd = Druid:feralSpendEnergy(fd, 25);
      fd = Druid:feralGainComboPoints(fd, 1);
      fd = RotationHelper:startCooldown(fd, FR.BrutalSlash);
      return fd;
   end

   effects[FR.Swipe] = function(fd)
      fd = Druid:feralSpendEnergy(fd, 35);
      fd = Druid:feralGainComboPoints(fd, 1);
      return fd;
   end

   effects[FR.HeartOfTheWild] = function(fd)
      fd = RotationHelper:startCooldown(fd, FR.HeartOfTheWild);
      fd = RotationHelper:addSelfBuff(fd, FR.HeartOfTheWild);
      return fd;
   end

   effects[FR.Berserk] = function(fd)
      fd = RotationHelper:startCooldown(fd, FR.Berserk);
      fd = RotationHelper:addSelfBuff(fd, FR.Berserk);
      return fd;
   end

   effects[FR.Incarnation] = function(fd)
      fd = RotationHelper:startCooldown(fd, FR.Incarnation);
      fd = RotationHelper:addSelfBuff(fd, FR.Incarnation);
      return fd;
   end

   effects[FR.Rip] = function(fd)
      fd = Druid:feralFinisher(fd);
      fd = Druid:feralSpendEnergy(fd, 20);
      fd = RotationHelper:addTargetDebuff(fd, FR.Rip);
      fd = RotationHelper:removeSelfBuff(fd, FR.Bloodtalons);
      return fd;
   end

   effects[FR.FerociousBite] = function(fd)
      fd = Druid:feralFinisher(fd);
      fd = Druid:feralSpendEnergy(fd, 25);
      fd = RotationHelper:removeSelfBuff(fd, FR.Bloodtalons);

      if (fd.talents[FR.Sabertooth]) then
         local rip = fd.debuff[FR.Rip];
         if (rip.up) then
            rip.remains = rip.remains + 1;
         end
      end
      return fd;
   end

   effects[FR.SavageRoar] = function(fd)
      fd = Druid:feralFinisher(fd);
      fd = Druid:feralSpendEnergy(fd, 25);
      fd = RotationHelper:addSelfBuff(fd, FR.SavageRoar);
      return fd;
   end

   effects[FR.PrimalWrath] = function(fd)
      fd = Druid:feralFinisher(fd);
      fd = Druid:feralSpendEnergy(fd, 20);
      fd = RotationHelper:addTargetDebuff(fd, FR.Rip);
      return fd;
   end

   effects[FR.ConvokeTheSpirits] = RotationHelper:normalCooldownEffect(FR.ConvokeTheSpirits);
   effects[FR.Starsurge] = RotationHelper:normalCooldownEffect(FR.Starsurge);
   effects[FR.KindredSpirits] = RotationHelper:normalCooldownEffect(FR.KindredSpirits);
   effects[FR.RavenousFrenzy] = RotationHelper:normalCooldownEffect(FR.RavenousFrenzy);

   return effects;
end

local DSEffect = Druid:createFeralEffectsTable();

function Druid:feralFinisher(fd)
   local cpCost = min(fd.comboPoints, 5);
   fd = Druid:feralSpendComboPoints(fd, cpCost);
   return fd;
end

function Druid:feralSpendComboPoints(fd, count)
   if (count == 5 and fd.buff[FR.Berserk].up) then
      count = 4;
   end

   fd.comboPoints = fd.comboPoints - count;
   return fd;
end

function Druid:feralGainComboPoints(fd, count)
   fd.comboPoints = min(fd.comboPointsMax, fd.comboPoints + count);
   return fd;
end

function Druid:feralSpendEnergy(fd, count)
   if (fd.buff[FR.Incarnation].up) then
      count = count * 0.8;
   end
   fd.energy = fd.energy - count;
   return fd;
end

function Druid:feralGainEnergy(fd, count)
   fd.energy = min(fd.energyMax, fd.energy + count);
   return fd;
end

function Druid:FeralAfterSpell(fd)
   fd = Druid:feralGainEnergy(fd, fd.energyRegen * fd.timeShiftLast);
   if (fd.currentSpell) then
      BtBuffCopy[fd.currentSpell] = GetTime() + fd.timeShift;
   end
   return fd;
end

function Druid:FeralPrep(fd)
	fd.energy = UnitPower('player', Enum.PowerType.Energy);
   fd.energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	fd.energyRegen = GetPowerRegen();
   fd.comboPoints = UnitPower('player', Enum.PowerType.ComboPoints);
   fd.comboPointsMax = UnitPowerMax('player', Enum.PowerType.ComboPoints);
   BtBuffCopy = RotationHelper:ShallowCopy(BtBuffSource);
   return fd;
end

function Druid:Feral(fd)
   local spellId = Druid:chooseFeralSpellId(fd);
   local retVal = {
      id = spellId,
   };

   if (spellId and DSEffect[spellId]) then
      retVal.updateFrameData = DSEffect[spellId];
   end

   if (spellId) then
      retVal.pandemicId = pandemicSpells[spellId];
   end

   return retVal;
end

function Druid:chooseFeralSpellId(fd)
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local currentSpell = fd.currentSpell;
	local spellHistory = fd.spellHistory;
	local talents = fd.talents;
	local targets = RotationHelper:SmartAoe();
	local covenantId = fd.covenant.covenantId;
	local energy = fd.energy;
	local energyMax = fd.energyMax;
	local energyDeficit = energyMax - energy;

	fd.targets = targets;
	fd.energy = energy;
	fd.energyMax = energyMax;
	fd.energyDeficit = energyDeficit;

	local comboPoints = fd.comboPoints;

	local Incarnation = talents[FR.Incarnation] and FR.Incarnation or FR.Berserk;
	fd.Incarnation = Incarnation;

	-- berserk,if=combo_points>=3;
	-- incarnation,if=combo_points>=3;
	RotationHelper:GlowCooldown(Incarnation, cooldown[Incarnation].ready and comboPoints >= 3);

	if talents[FR.HeartOfTheWild] then
		RotationHelper:GlowCooldown(FR.HeartOfTheWild, cooldown[FR.HeartOfTheWild].ready);
	end

	if covenantId == Venthyr then
		RotationHelper:GlowCooldown(FR.RavenousFrenzy, cooldown[FR.RavenousFrenzy].ready);
	elseif covenantId == NightFae then
		RotationHelper:GlowCooldown(FR.ConvokeTheSpirits, cooldown[FR.ConvokeTheSpirits].ready);
	elseif covenantId == Kyrian then
		RotationHelper:GlowCooldown(FR.KindredSpirits, cooldown[FR.KindredSpirits].ready);
	end

	if buff[FR.MoonkinForm].up then
		-- starsurge,if=buff.heart_of_the_wild.up;
		if talents[FR.BalanceAffinity] and cooldown[FR.Starsurge].ready and buff[FR.HeartOfTheWild].up then
			return FR.Starsurge;
		end

		-- sunfire,if=!prev_gcd.1.sunfire;
		if spellHistory[1] ~= FR.Sunfire then
			return FR.Sunfire;
		end

		-- tigers_fury,if=buff.cat_form.down;
		if cooldown[FR.TigersFury].ready and not buff[FR.CatForm].up then
			return FR.TigersFury;
		end

		-- cat_form,if=buff.cat_form.down;
		if not buff[FR.CatForm].up then
			return FR.CatForm;
		end
	end

	-- prowl;
	--if cooldown[FR.Prowl].ready then
	--	return FR.Prowl;
	--end

	-- heart_of_the_wild,if=energy<40&dot.rake.remains>4.5&(dot.rip.remains>4.5|combo_points<5)&cooldown.tigers_fury.remains>=4.5&buff.clearcasting.stack<1&!buff.apex_predators_craving.up&!cooldown.convoke_the_spirits.up&variable.owlweave=1;

	--if energy < 40 and debuff[FR.Rake].remains > 4.5 and (debuff[FR.Rip].remains > 4.5 or comboPoints < 5) and cooldown[FR.TigersFury].remains >= 4.5 and buff[FR.Clearcasting].count < 1 and not buff[FR.ApexPredatorsCraving].up and not cooldown[FR.ConvokeTheSpirits].up and owlweave == 1 then
	--	return FR.HeartOfTheWild;
	--end

	-- moonkin_form,if=energy<40&dot.rake.remains>4.5&(dot.rip.remains>4.5|combo_points<5)&cooldown.tigers_fury.remains>=4.5&buff.clearcasting.stack<1&!buff.apex_predators_craving.up&!cooldown.convoke_the_spirits.up&variable.owlweave=1;
	--if energy < 40 and debuff[FR.Rake].remains > 4.5 and (debuff[FR.Rip].remains > 4.5 or comboPoints < 5) and cooldown[FR.TigersFury].remains >= 4.5 and buff[FR.Clearcasting].count < 1 and not buff[FR.ApexPredatorsCraving].up and not cooldown[FR.ConvokeTheSpirits].up and owlweave == 1 then
	--	return FR.MoonkinForm;
	--end

	-- run_action_list,name=stealth,if=buff.shadowmeld.up|buff.prowl.up;
	if buff[FR.Prowl].up then -- buff[FR.Shadowmeld].up or
		return Druid:FeralStealth(fd);
	end

	-- call_action_list,name=cooldown;
	local result = Druid:FeralCooldown(fd);
	if result then
		return result;
	end

	-- run_action_list,name=finisher,if=combo_points>=(5-variable.4cp_bite);
	if comboPoints >= 5 then -- fourCpBite = 0
		return Druid:FeralFinisher(fd);
	end

	-- call_action_list,name=stealth,if=buff.bs_inc.up|buff.sudden_ambush.up;
	if buff[Incarnation].up or buff[FR.SuddenAmbush].up then
		result = Druid:FeralStealth(fd);
		if result then
			return result;
		end
	end

	-- run_action_list,name=bloodtalons,if=talent.bloodtalons.enabled&buff.bloodtalons.down;
	if talents[FR.Bloodtalons] and not buff[FR.BloodtalonsAura].up then
		return Druid:FeralBloodtalons(fd);
	end

	-- ferocious_bite,target_if=max:target.time_to_die,if=buff.apex_predators_craving.up&(!talent.bloodtalons.enabled|buff.bloodtalons.up);
	if energy >= 25 and
		comboPoints >= 1 and
		buff[FR.ApexPredatorsCraving].up and
		(not talents[FR.Bloodtalons] or buff[FR.BloodtalonsAura].up)
	then
		return FR.FerociousBite;
	end

	-- feral_frenzy,if=combo_points<3;
	if talents[FR.FeralFrenzy] and
		cooldown[FR.FeralFrenzy].ready and
		energy >= 25 and
		comboPoints < 3
	then
		return FR.FeralFrenzy;
	end

	-- rake,target_if=(refreshable|persistent_multiplier>dot.rake.pmultiplier)&druid.rake.ticks_gained_on_refresh>spell_targets.swipe_cat*2-2;
	if energy >= 35 and debuff[FR.RakeAura].refreshable then
		return FR.Rake;
	end

	-- moonfire_cat,target_if=refreshable&druid.moonfire.ticks_gained_on_refresh>spell_targets.swipe_cat*2-2;
	if talents[FR.LunarInspiration] and debuff[FR.Moonfire].refreshable then
		return FR.Moonfire;
	end

	-- brutal_slash,if=(raid_event.adds.in>(1+max_charges-charges_fractional)*recharge_time)&(spell_targets.brutal_slash*action.brutal_slash.damage%action.brutal_slash.cost)>(action.shred.damage%action.shred.cost);
	if talents[FR.BrutalSlash] and cooldown[FR.BrutalSlash].ready and energy >= 25 -- and (
		--((1 + cooldown[FR.BrutalSlash].maxCharges - cooldown[FR.BrutalSlash].charges) * cooldown[FR.BrutalSlash].partialRecharge) and
		--(targets * cooldown[FR.BrutalSlash].damage / cooldown[FR.BrutalSlash].cost) > (cooldown[FR.Shred].damage / cooldown[FR.Shred].cost))
	then
		return FR.BrutalSlash;
	end

	-- swipe_cat,if=spell_targets.swipe_cat>1+buff.bs_inc.up*2;
	if not talents[FR.BrutalSlash] and targets > 1 + (buff[Incarnation].up and 2 or 0) then
		return FR.Swipe;
	end

	-- shred,if=buff.clearcasting.up;
	if buff[FR.Clearcasting].up then
		return FR.Shred;
	end

	-- rake,target_if=buff.bs_inc.up&druid.rake.ticks_gained_on_refresh>2;
	if energy >= 35 and buff[Incarnation].up then
		return FR.Rake;
	end

	-- call_action_list,name=filler;
	return Druid:FeralFiller(fd);
end

function Druid:FeralBloodtalons(fd)
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets;
	local energy = fd.energy;
	local cooldown = fd.cooldown;

	-- rake,target_if=(!ticking|(refreshable&persistent_multiplier>dot.rake.pmultiplier))&buff.bt_rake.down&druid.rake.ticks_gained_on_refresh>=2;
	if energy >= 35 and (
		not debuff[FR.RakeAura].up or
		(
			debuff[FR.RakeAura].refreshable and
			Druid:BtBuffDown(fd, FR.Rake)
		)
	) then
		return FR.Rake;
	end

	-- lunar_inspiration,target_if=refreshable&buff.bt_moonfire.down;
	if talents[FR.LunarInspiration] and debuff[FR.Moonfire].refreshable and Druid:BtBuffDown(fd, FR.Moonfire) then
		return FR.Moonfire;
	end

	-- thrash_cat,target_if=refreshable&buff.bt_thrash.down&druid.thrash_cat.ticks_gained_on_refresh>8;
	if debuff[FR.Thrash].refreshable and buff[FR.Thrash].down and Druid:BtBuffDown(fd, FR.Thrash) then
		return FR.Thrash;
	end

	-- brutal_slash,if=buff.bt_brutal_slash.down;
	if talents[FR.BrutalSlash] and
		cooldown[FR.BrutalSlash].ready and
		--energy >= 25 and
		Druid:BtBuffDown(fd, FR.BrutalSlash)
	then
		return FR.BrutalSlash;
	end

	-- swipe_cat,if=buff.bt_swipe.down&spell_targets.swipe_cat>1;
	if not talents[FR.BrutalSlash] and
		--energy >= 35 and
		targets > 1 and
		Druid:BtBuffDown(fd, FR.Swipe)
	then
		return FR.Swipe;
	end

	-- shred,if=buff.bt_shred.down;
	if Druid:BtBuffDown(fd, FR.Shred) then -- energy >= 40 and
		return FR.Shred;
	end

	-- swipe_cat,if=buff.bt_swipe.down;
	if not talents[FR.BrutalSlash] and Druid:BtBuffDown(fd, FR.Swipe) then
		return FR.Swipe;
	end

	-- thrash_cat,if=buff.bt_thrash.down;
	if Druid:BtBuffDown(fd, FR.Thrash) then
		return FR.Thrash;
	end
end

function Druid:FeralCooldown(fd)
	local cooldown = fd.cooldown;
	local debuff = fd.debuff;
	local energyDeficit = fd.energyDeficit;
	local covenantId = fd.covenant.covenantId;

	-- tigers_fury,if=energy.deficit>55|buff.bs_inc.up|(talent.predator.enabled&variable.shortest_ttd<3);
	if cooldown[FR.TigersFury].ready and energyDeficit >= 55 then
		return FR.TigersFury;
	end

	-- ravenous_frenzy,if=buff.bs_inc.up|fight_remains<21;
	--if buff[Incarnation].up then
	--	return FR.RavenousFrenzy;
	--end

	-- convoke_the_spirits,if=(dot.rip.remains>4&combo_points<3&dot.rake.ticking)|fight_remains<5;
	--if cooldown[FR.ConvokeTheSpirits].ready and
	--	currentSpell ~= FR.ConvokeTheSpirits and ((debuff[FR.Rip].remains > 4 and comboPoints < 3 and debuff[FR.Rake].up) or fightRemains < 5) then
	--	return FR.ConvokeTheSpirits;
	--end

	-- kindred_spirits,if=buff.tigers_fury.up|(conduit.deep_allegiance.enabled);
	--if currentSpell ~= FR.KindredSpirits and (buff[FR.TigersFury].up or (conduit[FR.DeepAllegiance])) then
	--	return FR.KindredSpirits;
	--end

	-- adaptive_swarm,target_if=max:time_to_die*(combo_points=5&!dot.adaptive_swarm_damage.ticking);
	if covenantId == Necrolord and
		cooldown[FR.AdaptiveSwarm].ready and
		not debuff[FR.AdaptiveSwarmAura].up
	then
		return FR.AdaptiveSwarm;
	end
end

function Druid:FeralFiller(fd)
	local debuff = fd.debuff;
	local talents = fd.talents;
	local energy = fd.energy;

	if energy < 50 then
		return nil;
	end

	-- rake,target_if=variable.filler=1&dot.rake.pmultiplier<=persistent_multiplier;
	if filler == 1 then
		return FR.Rake;
	end

	-- rake,if=variable.filler=2;
	if filler == 2 then
		return FR.Rake;
	end

	-- lunar_inspiration,if=variable.filler=3;
	if talents[FR.LunarInspiration] and filler == 3 then
		return FR.Moonfire;
	end

	-- swipe,if=variable.filler=4;
	if not talents[FR.BrutalSlash] and filler == 4 then
		return FR.Swipe;
	end

	-- shred;
	return FR.Shred;
end

function Druid:FeralFinisher(fd)
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets;
	local timeToDie = fd.timeToDie;
	local comboPoints = fd.comboPoints;
	local energy = fd.energy;

	-- savage_roar,if=buff.savage_roar.down|buff.savage_roar.remains<(combo_points*6+1)*0.3;
	if talents[FR.SavageRoar] and
		energy >= 25 and
		comboPoints >= 1 and
		(not buff[FR.SavageRoar].up or buff[FR.SavageRoar].remains < (comboPoints * 6 + 1) * 0.3)
	then
		return FR.SavageRoar;
	end

	-- variable,name=best_rip,value=0,if=talent.primal_wrath.enabled;
	--if talents[FR.PrimalWrath] then
	--	local bestRip = WTFFFFFF;
	--end
	--
	-- cycling_variable,name=best_rip,op=max,value=druid.rip.ticks_gained_on_refresh,if=talent.primal_wrath.enabled;
	--if talents[FR.PrimalWrath] then
	--	return best_rip;
	--end

	-- primal_wrath,if=druid.primal_wrath.ticks_gained_on_refresh>(variable.rip_ticks>?variable.best_rip)|spell_targets.primal_wrath>(3+1*talent.sabertooth.enabled);
	if talents[FR.PrimalWrath] and
		energy >= 20 and
		comboPoints >= 1 and
		targets > (3 + 1 * (talents[FR.Sabertooth] and 1 or 0))
	then
		return FR.PrimalWrath;
	end

	-- rip,target_if=refreshable&druid.rip.ticks_gained_on_refresh>variable.rip_ticks&((buff.tigers_fury.up|cooldown.tigers_fury.remains>5)&(buff.bloodtalons.up|!talent.bloodtalons.enabled)&dot.rip.pmultiplier<=persistent_multiplier|!talent.sabertooth.enabled);
	if energy >= 20 and
		comboPoints >= 1 and
		debuff[FR.Rip].refreshable
	then
		return FR.Rip;
	end

	-- ferocious_bite,max_energy=1,target_if=max:time_to_die;
	if energy >= 25 and comboPoints >= 1 then
		return FR.FerociousBite;
	end
end

function Druid:FeralStealth(fd)
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets;
	local energy = fd.energy;
	local comboPoints = fd.comboPoints;

	-- run_action_list,name=bloodtalons,if=talent.bloodtalons.enabled&buff.bloodtalons.down;
	if talents[FR.Bloodtalons] and not buff[FR.BloodtalonsAura].up then
		return Druid:FeralBloodtalons();
	end

	-- rake,target_if=(dot.rake.pmultiplier<1.5|refreshable)&druid.rake.ticks_gained_on_refresh>2;
	if energy >= 35 and debuff[FR.RakeAura].refreshable then
		return FR.Rake;
	end

	-- brutal_slash,if=spell_targets.brutal_slash>2;
	if talents[FR.BrutalSlash] and energy >= 25 and targets > 2 then
		return FR.BrutalSlash;
	end

	-- shred,if=combo_points<4;
	if energy >= 40 and comboPoints < 4 then
		return FR.Shred;
	end
end

local BtAbilities = {
	[FR.Rake] = true,
	[FR.Shred] = true,
	[FR.Swipe] = true,
	[FR.Thrash] = true,
	[FR.Moonfire] = true,
	[FR.BrutalSlash] = true
};

function Druid:UNIT_SPELLCAST_SUCCEEDED(event, unitId, castGUID, spellId)
	if unitId ~= 'player' or not BtAbilities[spellId] then
		return;
	end

	BtBuffSource[spellId] = GetTime();
end

function Druid:BtBuffDown(fd, spellId)
	local talents = fd.talents;

	-- if you don't have BT talent, any filler is ok
	if not talents[FR.Bloodtalons] then
		return true;
	end

	local t = GetTime()
	local lastTimestamp = BtBuffCopy[spellId];

	return t - lastTimestamp > 4;
end