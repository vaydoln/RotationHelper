local _, addonTable = ...;
--- @type RotationHelper
if not RotationHelper then
	return
end

local Warrior = addonTable.Warrior;
local RotationHelper = RotationHelper;
local UnitPower = UnitPower;
local PowerTypeRage = Enum.PowerType.Rage;

local Necrolord = Enum.CovenantType.Necrolord;
local Venthyr = Enum.CovenantType.Venthyr;
local NightFae = Enum.CovenantType.NightFae;
local Kyrian = Enum.CovenantType.Kyrian;

local AR = {
	AncientAftershock = 325886,
	ConquerorsBanner  = 324143,
	SpearOfBastion    = 307865,
	Charge            = 100,
	SweepingStrikes   = 260708,
	Bladestorm        = 227847,
	Ravager           = 152277,
	Massacre          = 281001,
	DeadlyCalm        = 262228,
	Rend              = 772,
	Skullsplitter     = 260643,
	Avatar            = 107574,
	ColossusSmash     = 167105,
	ColossusSmashAura = 208086,
	Cleave            = 845,
	DeepWoundsAura    = 262115,
	Warbreaker        = 262161,
	Condemn           = 330334,
	SuddenDeath       = 29725,
	SuddenDeathAura   = 52437,
	Overpower         = 7384,
	MortalStrike      = 12294,
	Dreadnaught       = 262150,
	Whirlwind         = 1680,
	FervorOfBattle    = 202316,
	Slam              = 1464,
	Execute           = 163201,
	ExecuteMassacre   = 281000
};

setmetatable(AR, Warrior.spellMeta);

function Warrior:createArmsEffectsTable()
   local effects = {};

   effects[AR.Whirlwind] = function(fd)
      if (fd.buff[AR.DeadlyCalm].up) then
         fd = RotationHelper:removeSelfBuff(fd, AR.DeadlyCalm);
      else
         fd.rage = fd.rage - 30;
      end
      return fd;
   end

   effects[AR.Slam] = function(fd)
      if (fd.buff[AR.DeadlyCalm].up) then
         fd = RotationHelper:removeSelfBuff(fd, AR.DeadlyCalm);
      else
         fd.rage = fd.rage - 20;
      end
      return fd;
   end

   effects[AR.Rend] = function(fd)
      if (fd.talents[AR.DeadlyCalm] and fd.buff[AR.DeadlyCalm].up) then
         fd = RotationHelper:removeSelfBuff(fd, AR.DeadlyCalm);
      else
         fd.rage = fd.rage - 30;
      end
      fd = RotationHelper:addTargetDebuff(fd, AR.Rend);
      return fd;
   end

   effects[AR.Execute] = function(fd)
      if (fd.talents[AR.DeadlyCalm] and fd.buff[AR.DeadlyCalm].up) then
         fd = RotationHelper:removeSelfBuff(fd, AR.DeadlyCalm);
      else
         local cost = floor((min(fd.rage, 40) * 0.8) + 0.5);
         fd.rage = fd.rage - cost;
      end
      return fd;
   end

   effects[AR.Condemn] = effects[AR.Execute];
   effects[AR.ExecuteMassacre] = effects[AR.Execute];

   effects[AR.Charge] = function(fd)
      fd.rage = min(fd.rageMax, fd.rage + 20);
      fd = RotationHelper:startCooldown(fd, AR.Charge);
      return fd;
   end

   effects[AR.Avatar] = function(fd)
      fd.rage = min(fd.rageMax, fd.rage + 20);
      fd = RotationHelper:startCooldown(fd, AR.Avatar);
      return fd;
   end

   effects[AR.Skullsplitter] = function(fd)
      fd.rage = min(fd.rageMax, fd.rage + 20);
      fd = RotationHelper:startCooldown(fd, AR.Skullsplitter);
      return fd;
   end

   effects[AR.Cleave] = function(fd)
      if (fd.talents[AR.DeadlyCalm] and fd.buff[AR.DeadlyCalm].up) then
         fd = RotationHelper:removeSelfBuff(fd, AR.DeadlyCalm);
      else
         fd.rage = fd.rage - 20;
      end
      fd = RotationHelper:startCooldown(fd, AR.Cleave);
      fd = RotationHelper:removeSelfBuff(fd, AR.Overpower);
      fd = RotationHelper:addTargetDebuff(fd, AR.DeepWoundsAura);
      return fd;
   end

   effects[AR.MortalStrike] = function(fd)
      if (fd.talents[AR.DeadlyCalm] and fd.buff[AR.DeadlyCalm].up) then
         fd = RotationHelper:removeSelfBuff(fd, AR.DeadlyCalm);
      else
         fd.rage = fd.rage - 30;
      end
      fd = RotationHelper:startCooldown(fd, AR.MortalStrike);
      fd = RotationHelper:removeSelfBuff(fd, AR.Overpower);
      fd = RotationHelper:addTargetDebuff(fd, AR.MortalStrike);
      return fd;
   end

   effects[AR.DeadlyCalm] = function(fd)
      fd = RotationHelper:startCooldown(fd, AR.DeadlyCalm);
      fd = RotationHelper:addSelfBuff(fd, AR.DeadlyCalm);
      return fd;
   end

   effects[AR.Overpower] = function(fd)
      fd = RotationHelper:startCooldown(fd, AR.Overpower);
      fd = RotationHelper:addSelfBuff(fd, AR.Overpower);
      return fd;
   end

   effects[AR.Warbreaker] = function(fd)
      fd = RotationHelper:startCooldown(fd, AR.Warbreaker);
      fd = RotationHelper:addTargetDebuff(fd, AR.ColossusSmashAura);
      return fd;
   end

   effects[AR.ColossusSmash] = function(fd)
      fd = RotationHelper:startCooldown(fd, AR.ColossusSmash);
      fd = RotationHelper:addTargetDebuff(fd, AR.ColossusSmashAura);
      return fd;
   end

   effects[AR.Ravager] = function(fd)
      fd = RotationHelper:startCooldown(fd, AR.Ravager);
      fd = RotationHelper:addTargetDebuff(fd, AR.DeepWoundsAura);
      return fd;
   end

   effects[AR.SweepingStrikes] = function(fd)
      fd = RotationHelper:startCooldown(fd, AR.SweepingStrikes);
      fd = RotationHelper:addSelfBuff(fd, AR.SweepingStrikes);
      return fd;
   end

   effects[AR.Bladestorm] = RotationHelper:normalCooldownEffect(AR.Bladestorm);
   effects[AR.AncientAftershock] = RotationHelper:normalCooldownEffect(AR.AncientAftershock);
   effects[AR.ConquerorsBanner] = RotationHelper:normalCooldownEffect(AR.ConquerorsBanner);
   effects[AR.SpearOfBastion] = RotationHelper:normalCooldownEffect(AR.SpearOfBastion);

   return effects;
end

local AREffect = Warrior:createArmsEffectsTable();

function Warrior:ArmsAfterSpell(fd)
   return fd;
end

function Warrior:ArmsPrep(fd)
	fd.rage = UnitPower('player', PowerTypeRage);
	fd.rageMax = UnitPowerMax('player', PowerTypeRage);
	fd.targets = RotationHelper:SmartAoe();
	fd.targetHp = RotationHelper:TargetPercentHealth() * 100;
   fd.inExecutePhase = (fd.talents[AR.Massacre] and fd.targetHp < 35) or (fd.targetHp < 20) or (fd.targetHp > 80 and fd.covenant.covenantId == Venthyr);
	fd.Execute = fd.covenant.covenantId == Venthyr and AR.Condemn or (fd.talents[AR.Massacre] and AR.ExecuteMassacre or AR.Execute);

   if (fd.currentSpell and AREffect[fd.currentSpell]) then
      local updateFrameData = AREffect[fd.currentSpell];
      fd = updateFrameData(fd);
   end

   return fd;
end

function Warrior:Arms(fd)
   local spellId = Warrior:chooseArmsSpellId(fd);
   local retVal = {
      id = spellId,
   };

   if (spellId and AREffect[spellId]) then
      retVal.updateFrameData = AREffect[spellId];
   end

   return retVal;
end

function Warrior:chooseArmsSpellId(fd)
	local cooldown = fd.cooldown;
	local talents = fd.talents;
	local targets = fd.targets;
	local covenantId = fd.covenant.covenantId;
	local inExecutePhase = fd.inExecutePhase;

	if talents[AR.Avatar] then
		RotationHelper:GlowCooldown(
			AR.Avatar,
			cooldown[AR.Avatar].ready and cooldown[AR.ColossusSmash].remains < 8
		);
	end

	if covenantId == NightFae then
		RotationHelper:GlowCooldown(AR.AncientAftershock, cooldown[AR.AncientAftershock].ready);
	elseif covenantId == Necrolord then
		RotationHelper:GlowCooldown(AR.ConquerorsBanner, cooldown[AR.ConquerorsBanner].ready);
	elseif covenantId == Kyrian then
		RotationHelper:GlowCooldown(AR.SpearOfBastion, cooldown[AR.SpearOfBastion].ready);
	end

	-- sweeping_strikes,if=spell_targets.whirlwind>1&(cooldown.bladestorm.remains>15|talent.ravager.enabled);
	if cooldown[AR.SweepingStrikes].ready and
		targets > 1 and
		(cooldown[AR.Bladestorm].remains > 15 or talents[AR.Ravager])
	then
		return AR.SweepingStrikes;
	end

	-- run_action_list,name=hac,if=raid_event.adds.exists;
	if targets > 1 then
		return Warrior:ArmsHac(fd);
	end

	-- run_action_list,name=execute,if=(talent.massacre.enabled&target.health.pct<35)|target.health.pct<20|(target.health.pct>80&covenant.venthyr);
	if inExecutePhase then
		return Warrior:ArmsExecute(fd);
	end

	-- run_action_list,name=single_target;
	return Warrior:ArmsSingleTarget(fd);
end

function Warrior:ArmsExecute(fd)
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets;
	local rage = fd.rage;
	local Execute = fd.Execute;
	local canExecute = fd.cooldown[fd.Execute].ready and fd.rage >= 20 and fd.inExecutePhase or fd.buff[AR.SuddenDeathAura].up;

	-- deadly_calm;
	if talents[AR.DeadlyCalm] and cooldown[AR.DeadlyCalm].ready then
		return AR.DeadlyCalm;
	end

	-- rend,if=remains<=duration*0.3;
	if talents[AR.Rend] and rage >= 30 and debuff[AR.Rend].refreshable then
		return AR.Rend;
	end

	-- skullsplitter,if=rage<60&(!talent.deadly_calm.enabled|buff.deadly_calm.down);
	if talents[AR.Skullsplitter] and
		cooldown[AR.Skullsplitter].ready and
		rage < 60 and
		(not talents[AR.DeadlyCalm] or not buff[AR.DeadlyCalm].up)
	then
		return AR.Skullsplitter;
	end

	-- avatar,if=cooldown.colossus_smash.remains<8&gcd.remains=0;
	--if talents[AR.Avatar] and cooldown[AR.Avatar].ready and cooldown[AR.ColossusSmash].remains < 8 then
	--	return AR.Avatar;
	--end

	-- ravager,if=buff.avatar.remains<18&!dot.ravager.remains;
	if talents[AR.Ravager] and
		cooldown[AR.Ravager].ready and
		buff[AR.Avatar].remains < 18
		--and
		--not debuff[AR.Ravager].up
	then
		return AR.Ravager;
	end

	-- cleave,if=spell_targets.whirlwind>1&dot.deep_wounds.remains<gcd;
	if talents[AR.Cleave] and
		cooldown[AR.Cleave].ready and
		rage >= 20 and
		targets > 1 and
		debuff[AR.DeepWoundsAura].remains < 2
	then
		return AR.Cleave;
	end

	-- warbreaker;
	if talents[AR.Warbreaker] then
		if cooldown[AR.Warbreaker].ready then
			return AR.Warbreaker;
		end
	else
		-- colossus_smash;
		if cooldown[AR.ColossusSmash].ready then
			return AR.ColossusSmash;
		end
	end

	-- condemn,if=debuff.colossus_smash.up|buff.sudden_death.react|rage>65;
	if canExecute and (debuff[AR.ColossusSmashAura].up or rage > 65) then
		return Execute;
	end

	-- overpower,if=charges=2;
	if cooldown[AR.Overpower].ready and cooldown[AR.Overpower].charges >= 2 then
		return AR.Overpower;
	end

	-- bladestorm,if=buff.deadly_calm.down&rage<50;
	if not talents[AR.Ravager] and cooldown[AR.Bladestorm].ready and not buff[AR.DeadlyCalm].up and rage < 50 then
		return AR.Bladestorm;
	end

	-- mortal_strike,if=dot.deep_wounds.remains<=gcd;
	if cooldown[AR.MortalStrike].ready and
		rage >= 30 and
		debuff[AR.DeepWoundsAura].remains <= 2
	then
		return AR.MortalStrike;
	end

	-- skullsplitter,if=rage<40;
	if talents[AR.Skullsplitter] and cooldown[AR.Skullsplitter].ready and rage < 40 then
		return AR.Skullsplitter;
	end

	-- overpower;
	if cooldown[AR.Overpower].ready then
		return AR.Overpower;
	end

	-- condemn;
	if canExecute then
		return Execute;
	end
end

function Warrior:ArmsHac(fd)
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local rage = fd.rage;
	local Execute = fd.Execute;
	local canExecute = fd.cooldown[fd.Execute].ready and fd.rage >= 20 and fd.inExecutePhase or fd.buff[AR.SuddenDeathAura].up;

	-- skullsplitter,if=rage<60&buff.deadly_calm.down;
	if talents[AR.Skullsplitter] and
		cooldown[AR.Skullsplitter].ready and
		rage < 60 and
		not buff[AR.DeadlyCalm].up
	then
		return AR.Skullsplitter;
	end

	-- avatar,if=cooldown.colossus_smash.remains<1;
	--if talents[AR.Avatar] and cooldown[AR.Avatar].ready and (cooldown[AR.ColossusSmash].remains < 1) then
	--	return AR.Avatar;
	--end

	-- cleave,if=dot.deep_wounds.remains<=gcd;
	if talents[AR.Cleave] and
		cooldown[AR.Cleave].ready and
		rage >= 20 and
		debuff[AR.DeepWoundsAura].remains <= 2
	then
		return AR.Cleave;
	end

	-- warbreaker;
	if talents[AR.Warbreaker] and cooldown[AR.Warbreaker].ready then
		return AR.Warbreaker;
	end

	if talents[AR.Ravager] then
		-- ravager;
		if cooldown[AR.Ravager].ready then
			return AR.Ravager;
		end
	else
		-- bladestorm;
		if cooldown[AR.Bladestorm].ready then
			return AR.Bladestorm;
		end
	end

	-- colossus_smash;
	if not talents[AR.Warbreaker] and cooldown[AR.ColossusSmash].ready then
		return AR.ColossusSmash;
	end

	-- rend,if=remains<=duration*0.3&buff.sweeping_strikes.up;
	if talents[AR.Rend] and
		rage >= 30 and
		debuff[AR.Rend].refreshable and
		buff[AR.SweepingStrikes].up
	then
		return AR.Rend;
	end

	-- cleave;
	if talents[AR.Cleave] and cooldown[AR.Cleave].ready and rage >= 20 then
		return AR.Cleave;
	end

	-- mortal_strike,if=buff.sweeping_strikes.up|dot.deep_wounds.remains<gcd&!talent.cleave.enabled;
	if cooldown[AR.MortalStrike].ready and
		rage >= 30 and
		(
			buff[AR.SweepingStrikes].up or
			debuff[AR.DeepWoundsAura].remains < 2 and not talents[AR.Cleave]
		)
	then
		return AR.MortalStrike;
	end

	-- overpower,if=talent.dreadnaught.enabled;
	if cooldown[AR.Overpower].ready and talents[AR.Dreadnaught] then
		return AR.Overpower;
	end

   if canExecute then
      return Execute;
   end

	-- overpower;
	if cooldown[AR.Overpower].ready then
		return AR.Overpower;
	end

	-- whirlwind;
	if rage >= 30 then
		return AR.Whirlwind;
	end
end

function Warrior:ArmsSingleTarget(fd)
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local gcd = fd.gcd;
	local Execute = fd.Execute;
	local targets = fd.targets;
	local rage = fd.rage;

	-- avatar,if=cooldown.colossus_smash.remains<8&gcd.remains=0;
	--if talents[AR.Avatar] and cooldown[AR.Avatar].ready and (cooldown[AR.ColossusSmash].remains < 8 and gcdRemains == 0) then
	--	return AR.Avatar;
	--end

	-- rend,if=remains<=duration*0.3;
	if talents[AR.Rend] and
		rage >= 30 and
		debuff[AR.Rend].refreshable
	then
		return AR.Rend;
	end

	-- cleave,if=spell_targets.whirlwind>1&dot.deep_wounds.remains<gcd;
	if talents[AR.Cleave] and
		cooldown[AR.Cleave].ready and
		rage >= 20 and
		targets > 1 and
		debuff[AR.DeepWoundsAura].remains < 2
	then
		return AR.Cleave;
	end

	-- warbreaker;
	if talents[AR.Warbreaker] then
		if cooldown[AR.Warbreaker].ready then
			return AR.Warbreaker;
		end
	else
		-- colossus_smash;
		if cooldown[AR.ColossusSmash].ready then
			return AR.ColossusSmash;
		end
	end

	-- ravager,if=buff.avatar.remains<18&!dot.ravager.remains;
	if talents[AR.Ravager] and cooldown[AR.Ravager].ready and buff[AR.Avatar].remains < 18 then
		return AR.Ravager;
	end

	-- overpower,if=charges=2;
	if cooldown[AR.Overpower].charges >= 2 then
		return AR.Overpower;
	end

	-- bladestorm,if=buff.deadly_calm.down&(debuff.colossus_smash.up&rage<30|rage<70);
	if not talents[AR.Ravager] and
		cooldown[AR.Bladestorm].ready and
		not buff[AR.DeadlyCalm].up and
		(debuff[AR.ColossusSmashAura].up and rage < 30 or rage < 70)
	then
		return AR.Bladestorm;
	end

	-- mortal_strike,if=buff.overpower.stack>=2&buff.deadly_calm.down|(dot.deep_wounds.remains<=gcd&cooldown.colossus_smash.remains>gcd);
	if cooldown[AR.MortalStrike].ready and
		rage >= 30 and
		(
			buff[AR.Overpower].count >= 2 and not buff[AR.DeadlyCalm].up or
			(debuff[AR.DeepWoundsAura].remains <= 2 and cooldown[AR.ColossusSmash].remains > gcd)
		)
	then
		return AR.MortalStrike;
	end

	-- deadly_calm;
	if talents[AR.DeadlyCalm] and cooldown[AR.DeadlyCalm].ready then
		return AR.DeadlyCalm;
	end

	-- skullsplitter,if=rage<60&buff.deadly_calm.down;
	if talents[AR.Skullsplitter] and
		cooldown[AR.Skullsplitter].ready and
		rage < 60 and
		not buff[AR.DeadlyCalm].up
	then
		return AR.Skullsplitter;
	end

	-- overpower;
	if cooldown[AR.Overpower].ready then
		return AR.Overpower;
	end


	if buff[AR.SuddenDeathAura].up then
		-- condemn,if=buff.sudden_death.react;
		-- execute,if=buff.sudden_death.react;
		return Execute;
	end

	-- mortal_strike;
	if cooldown[AR.MortalStrike].ready and rage >= 30 then
		return AR.MortalStrike;
	end

	-- whirlwind,if=talent.fervor_of_battle.enabled&rage>60;
	if rage >= 30 and talents[AR.FervorOfBattle] and rage > 60 then
		return AR.Whirlwind;
	end

	-- slam;
	if rage >= 20 then
		return AR.Slam;
	end
end