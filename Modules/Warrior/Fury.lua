local _, addonTable = ...;

--- @type RotationHelper
if not RotationHelper then return end

local Warrior = addonTable.Warrior;
local RotationHelper = RotationHelper;
local UnitPower = UnitPower;
local PowerTypeRage = Enum.PowerType.Rage;

local Necrolord = Enum.CovenantType.Necrolord;
local Venthyr = Enum.CovenantType.Venthyr;
local NightFae = Enum.CovenantType.NightFae;
local Kyrian = Enum.CovenantType.Kyrian;

local FR = {
	AncientAftershock = 325886,
	ConquerorsBanner  = 324143,
	SpearOfBastion    = 307865,
	Charge            = 100,
	HeroicLeap        = 6544,
	Rampage           = 184367,
	Recklessness      = 1719,
	RecklessAbandon   = 202751,
	AngerManagement   = 152278,
	Massacre          = 206315,
	MeatCleaver       = 280392,
	MeatCleaverAura   = 85739,
	Whirlwind         = 190411,
	RagingBlow        = 85288,
	Siegebreaker      = 280772,
	Enrage            = 184361,
	Frenzy            = 335077,
	Condemn           = 330325,
	Execute           = 5308,
	ExecuteMassacre   = 280735,
	Bladestorm        = 46924,
	Bloodthirst       = 23881,
	ViciousContempt   = 337302,
	Cruelty           = 335070,
	DragonRoar        = 118000,
	Onslaught         = 315720,
   SuddenDeathAura   = 280776,
   Seethe            = 335091,

	-- leggo
	WillOfTheBerserkerBonusId = 6966,
	WillOfTheBerserker = 335597
};

setmetatable(FR, Warrior.spellMeta);

function Warrior:createFuryEffectsTable()
   local effects = {};

   effects[FR.Bloodthirst] = function(fd)
      local increase = fd.talents[FR.Seethe] and 10 or 8;
      fd.rage = min(fd.rageMax, fd.rage + increase);
      fd = RotationHelper:startCooldown(fd, FR.Bloodthirst);
      fd = RotationHelper:removeSelfBuff(fd, FR.MeatCleaverAura);
      return fd;
   end

   effects[FR.RagingBlow] = function(fd)
      fd.rage = min(fd.rageMax, fd.rage + 12);
      fd = RotationHelper:startCooldown(fd, FR.RagingBlow);
      fd = RotationHelper:removeSelfBuff(fd, FR.MeatCleaverAura);
      return fd;
   end

   effects[FR.Whirlwind] = function(fd)
      fd.rage = min(fd.rageMax, fd.rage + 3 + (1 * fd.targets));
      if (fd.talents[FR.MeatCleaver]) then
         fd = RotationHelper:addSelfBuff(fd, FR.MeatCleaverAura, 4);
      else
         fd = RotationHelper:addSelfBuff(fd, FR.MeatCleaverAura, 2);
      end
      return fd;
   end

   effects[FR.Rampage] = function(fd)
      fd.rage = fd.rage - 80;
      fd = RotationHelper:addSelfBuff(fd, FR.Enrage);
      fd = RotationHelper:removeSelfBuff(fd, FR.MeatCleaverAura);
      return fd;
   end

   effects[FR.Execute] = function(fd)
      fd.rage = min(fd.rageMax, fd.rage + 20);
      fd = RotationHelper:startCooldown(fd, fd.Execute);
      fd = RotationHelper:removeSelfBuff(fd, FR.MeatCleaverAura);
      return fd;
   end

   effects[FR.Condemn] = effects[FR.Execute];
   effects[FR.ExecuteMassacre] = effects[FR.Execute];

   effects[FR.Charge] = function(fd)
      fd.rage = min(fd.rageMax, fd.rage + 20);
      fd = RotationHelper:startCooldown(fd, FR.Charge);
      return fd;
   end

   effects[FR.Recklessness] = function(fd)
      fd = RotationHelper:startCooldown(fd, FR.Recklessness);
      if (fd.talents[FR.RecklessAbandon]) then
         fd.rage = min(fd.rageMax, fd.rage + 50);
      end
      return fd;
   end

   effects[FR.Onslaught] = function(fd)
      fd.rage = min(fd.rageMax, fd.rage + 15);
      fd = RotationHelper:startCooldown(fd, FR.Onslaught);
      fd = RotationHelper:removeSelfBuff(fd, FR.MeatCleaverAura);
      return fd;
   end

   effects[FR.DragonRoar] = function(fd)
      fd.rage = min(fd.rageMax, fd.rage + 10);
      fd = RotationHelper:startCooldown(fd, FR.DragonRoar);
      return fd;
   end

   effects[FR.Bladestorm] = function(fd)
      fd.rage = min(fd.rageMax, fd.rage + 25);
      fd = RotationHelper:startCooldown(fd, FR.Bladestorm);
      return fd;
   end

   effects[FR.Siegebreaker] = function(fd)
      fd.rage = min(fd.rageMax, fd.rage + 10);
      fd = RotationHelper:startCooldown(fd, FR.Siegebreaker);
      fd = RotationHelper:removeSelfBuff(fd, FR.MeatCleaverAura);
      return fd;
   end

   effects[FR.HeroicLeap] = RotationHelper:normalCooldownEffect(FR.HeroicLeap);
   effects[FR.AncientAftershock] = RotationHelper:normalCooldownEffect(FR.AncientAftershock);
   effects[FR.ConquerorsBanner] = RotationHelper:normalCooldownEffect(FR.ConquerorsBanner);
   effects[FR.SpearOfBastion] = RotationHelper:normalCooldownEffect(FR.SpearOfBastion);

   return effects;
end

local FREffect = Warrior:createFuryEffectsTable();

function Warrior:FuryAfterSpell(fd)
   return fd;
end

function Warrior:FuryPrep(fd)
	fd.rage = UnitPower('player', PowerTypeRage);
	fd.rageMax = UnitPowerMax('player', PowerTypeRage);
	fd.targets = RotationHelper:SmartAoe();
   fd.Execute = (fd.covenant.covenantId == Venthyr) and FR.Condemn 
      or (fd.talents[FR.Massacre] and FR.ExecuteMassacre or FR.Execute);

   if (fd.currentSpell and FREffect[fd.currentSpell]) then
      local updateFrameData = FREffect[fd.currentSpell];
      fd = updateFrameData(fd);
   end

	-- recklessness;
	RotationHelper:GlowCooldown(FR.Recklessness, fd.cooldown[FR.Recklessness].ready);

	if fd.talents[FR.Bladestorm] then
		RotationHelper:GlowCooldown(FR.Bladestorm, fd.cooldown[FR.Bladestorm].ready);
	end

	if fd.covenant.covenantId == NightFae then
		RotationHelper:GlowCooldown(FR.AncientAftershock, fd.cooldown[FR.AncientAftershock].ready);
	elseif fd.covenant.covenantId == Necrolord then
		RotationHelper:GlowCooldown(FR.ConquerorsBanner, fd.cooldown[FR.ConquerorsBanner].ready);
	elseif fd.covenant.covenantId == Kyrian then
		RotationHelper:GlowCooldown(FR.SpearOfBastion, fd.cooldown[FR.SpearOfBastion].ready);
	end

   return fd;
end

function Warrior:Fury(fd)
   local spellId = Warrior:chooseFurySpellId(fd);
   local retVal = {
      id = spellId,
   };

   if (spellId and FREffect[spellId]) then
      retVal.updateFrameData = FREffect[spellId];
   end

   return retVal;
end

function Warrior:chooseFurySpellId(fd)
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local targets = fd.targets;
	local rage = fd.rage;

	-- rampage,if=cooldown.recklessness.remains<3&talent.reckless_abandon.enabled;
	if rage >= 80 and cooldown[FR.Recklessness].remains < 3 and talents[FR.RecklessAbandon] then
		return FR.Rampage;
	end

	-- recklessness,if=gcd.remains=0&((buff.bloodlust.up|talent.anger_management.enabled|raid_event.adds.in>10)|target.time_to_die>100|(talent.massacre.enabled&target.health.pct<35)|target.health.pct<20|target.time_to_die<15&raid_event.adds.in>10)&(spell_targets.whirlwind=1|buff.meat_cleaver.up);
	--if cooldown[FR.Recklessness].ready and
	--	(gcdRemains == 0 and ((buff[FR.Bloodlust].up or talents[FR.AngerManagement] or 10) or timeToDie > 100 or (talents[FR.Massacre] and targetHp < 35) or targetHp < 20 or timeToDie < 15 and 10) and (targets == 1 or buff[FR.MeatCleaver].up)) then
	--	return FR.Recklessness;
	--end

	-- whirlwind,if=spell_targets.whirlwind>1&!buff.meat_cleaver.up|raid_event.adds.in<gcd&!buff.meat_cleaver.up;
	if targets > 1 and not buff[FR.MeatCleaverAura].up then
		return FR.Whirlwind;
	end

	-- run_action_list,name=single_target;
	return Warrior:FurySingleTarget(fd);
end

function Warrior:FurySingleTarget(fd)
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local targets = fd.targets;
	local runeforge = fd.runeforge;
	local gcd = fd.gcd;
	local rage = fd.rage;
	local covenantId = fd.covenant.covenantId;
	local conduit = fd.covenant.soulbindConduits;

   local targetHp = RotationHelper:TargetPercentHealth() * 100;
   local lowPercentToExecute = talents[FR.Massacre] and 35 or 20;
   local highPercentToExecute = (covenantId == Venthyr) and 80 or 1000;

   local Execute = fd.Execute;
   local canExecute = cooldown[Execute].ready
      and (buff[FR.SuddenDeathAura].up or (targetHp <= lowPercentToExecute or highPercentToExecute < targetHp));

	-- raging_blow,if=runeforge.will_of_the_berserker.equipped&buff.will_of_the_berserker.remains<gcd;
	if cooldown[FR.RagingBlow].ready and
		runeforge[FR.WillOfTheBerserkerBonusId] and
		buff[FR.WillOfTheBerserker].remains < 2
	then
		return FR.RagingBlow;
	end

	-- siegebreaker,if=spell_targets.whirlwind>1|raid_event.adds.in>15;
	if talents[FR.Siegebreaker] and cooldown[FR.Siegebreaker].ready then
		return FR.Siegebreaker;
	end

	-- rampage,if=buff.recklessness.up|(buff.enrage.remains<gcd|rage>90)|buff.frenzy.remains<1.5;
	if rage >= 80 and
		(
			buff[FR.Recklessness].up or
			(buff[FR.Enrage].remains < 1.5 or rage > 90) or
			buff[FR.Frenzy].remains < 1.5
		)
	then
		return FR.Rampage;
	end

	-- condemn;
	-- execute;
	if canExecute then
		return Execute;
	end

	-- bladestorm,if=buff.enrage.up&(spell_targets.whirlwind>1|raid_event.adds.in>45);
	--if cooldown[FR.Bladestorm].ready and (buff[FR.Enrage].up and (targets > 1 or 45)) then
	--	return FR.Bladestorm;
	--end

   -- bloodthirst,if=buff.enrage.down|conduit.vicious_contempt.rank>5&target.health.pct<35&!talent.cruelty.enabled;
   local vcCount = conduit[FR.ViciousContempt] or 0;
	if cooldown[FR.Bloodthirst].ready and
		(
			not buff[FR.Enrage].up or vcCount > 5 and targetHp < 35 and not talents[FR.Cruelty]
		)
	then
		return FR.Bloodthirst;
	end

	-- dragon_roar,if=buff.enrage.up&(spell_targets.whirlwind>1|raid_event.adds.in>15);
	if talents[FR.DragonRoar] and cooldown[FR.DragonRoar].ready and buff[FR.Enrage].up then
		return FR.DragonRoar;
	end

	-- onslaught;
	if talents[FR.Onslaught] and cooldown[FR.Onslaught].ready then
		return FR.Onslaught;
	end

	-- raging_blow,if=charges=2;
	if cooldown[FR.RagingBlow].charges >= 2 then
		return FR.RagingBlow;
	end

	-- bloodthirst;
	if cooldown[FR.Bloodthirst].ready then
		return FR.Bloodthirst;
	end

	-- raging_blow;
	if cooldown[FR.RagingBlow].ready then
		return FR.RagingBlow;
	end

	-- whirlwind;
	return FR.Whirlwind;
end