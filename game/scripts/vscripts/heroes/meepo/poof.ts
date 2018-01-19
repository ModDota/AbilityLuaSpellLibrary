require("heroes/meepo/divided_we_stand")

class meepo_poof_lua extends CDOTA_Ability_Lua {
  particle:ParticleID

  CastFilterResultTarget(target:CDOTA_BaseNPC) {
    if (target.GetName() == this.GetCaster().GetName() && target.GetPlayerOwnerID() == this.GetCaster().GetPlayerOwnerID()) {
      return UnitFilterResult.UF_SUCCESS;
    } else {
      return UnitFilterResult.UF_FAIL_CUSTOM;
    }
  }
  
  GetCustomCastErrorTarget(target:CDOTA_BaseNPC) {
    // Localize this
    return "#error_meepo_poof";
    
  }

  GetCooldown(iLevel) {
    let caster:CDOTA_BaseNPC = this.GetCaster();
    let cooldown = this.GetSpecialValueFor("cooldown");
    if (IsServer()) {
      let talent:CDOTABaseAbility = this.GetCaster().FindAbilityByName("special_bonus_unique_meepo");
      if (talent) {
        cooldown -= talent.GetSpecialValueFor("value");
      }
    }
    return cooldown;
  }

  OnAbilityPhaseStart() {
    this.particle = ParticleManager.CreateParticle("particles/units/heroes/hero_meepo/meepo_poof_start.vpcf", ParticleAttachment_t.PATTACH_ABSORIGIN_FOLLOW, this.GetCaster());
    this.GetCaster().EmitSound("Hero_Meepo.Poof.Channel");
    return true;
  }

  OnAbilityPhaseInterrupted() {
    ParticleManager.DestroyParticle(this.particle, false);
    this.GetCaster().StopSound("Hero_Meepo.Poof.Channel");
  }

  OnSpellStart() {
    let caster = this.GetCaster();
    let caster_origin = caster.GetAbsOrigin();
    let target = this.GetCursorTarget();

    // if the ground was clicked, find the nearest meepo
    if (!target) {
      let PID = caster.GetPlayerOwnerID();
      let mainMeepo = PlayerResource.GetSelectedHeroEntity(PID);
      
      //let closest
      //let dist = Number.MAX_VALUE
      let dist = 999999;
      
      for (let meepo of GetAllMeepos(mainMeepo)) {
        let range = meepo.GetAbsOrigin() - this.GetCursorPosition();
        range = range.Length2D()
        if (range < dist) {
          dist = range;
          target = meepo;
        }
      }
    }
      
    let target_origin = target.GetAbsOrigin();

    let damage = this.GetSpecialValueFor("poof_damage");
    let talent:CDOTABaseAbility = this.GetCaster().FindAbilityByName("special_bonus_unique_meepo2");
    if (talent) {
      damage += talent.GetSpecialValueFor("value");
    }
    let radius:number = this.GetSpecialValueFor("radius");

    // Poof at old location
    let units = FindUnitsInRadius(caster.GetTeamNumber(),caster_origin,null,radius,DOTA_UNIT_TARGET_TEAM.DOTA_UNIT_TARGET_TEAM_ENEMY,DOTA_UNIT_TARGET_TYPE.DOTA_UNIT_TARGET_BASIC+DOTA_UNIT_TARGET_TYPE.DOTA_UNIT_TARGET_HERO,DOTA_UNIT_TARGET_FLAGS.DOTA_UNIT_TARGET_FLAG_NONE,0,false)
    for (let unit of units) {
      let dTable: DamageTable = {attacker:caster,victim:unit,damage:damage,damage_type:DAMAGE_TYPES.DAMAGE_TYPE_MAGICAL};
      ApplyDamage(dTable);
      unit.EmitSound("Hero_Meepo.Poof.Damage");
    }

    let particleOldPoint = ParticleManager.CreateParticle("particles/units/heroes/hero_meepo/meepo_poof_end.vpcf",ParticleAttachment_t.PATTACH_ABSORIGIN,caster);
    ParticleManager.SetParticleControl(particleOldPoint, 0, caster_origin);

    
    FindClearSpaceForUnit(caster,target_origin,true);
    caster.AddNewModifier(caster, this, "modifier_phased", {duration:0.1});

    // Poof at new location
    units = FindUnitsInRadius(caster.GetTeamNumber(),target_origin,null,radius,DOTA_UNIT_TARGET_TEAM.DOTA_UNIT_TARGET_TEAM_ENEMY,DOTA_UNIT_TARGET_TYPE.DOTA_UNIT_TARGET_BASIC+DOTA_UNIT_TARGET_TYPE.DOTA_UNIT_TARGET_HERO,DOTA_UNIT_TARGET_FLAGS.DOTA_UNIT_TARGET_FLAG_NONE,0,false)
    for (var unit of units) {
      let dTable: DamageTable = {attacker:caster,victim:unit,damage:damage,damage_type:DAMAGE_TYPES.DAMAGE_TYPE_MAGICAL};
      ApplyDamage(dTable);
      unit.EmitSound("Hero_Meepo.Poof.Damage");
    }

    let particleNewPoint = ParticleManager.CreateParticle("particles/units/heroes/hero_meepo/meepo_poof_end.vpcf",ParticleAttachment_t.PATTACH_ABSORIGIN,caster);
    ParticleManager.SetParticleControl(particleNewPoint, 0, target_origin);


    //let soundString = "Hero_Meepo.Poof.End0"+(RandomInt(0,5)).toString();
    let soundString = "Hero_Meepo.Poof.End00";
    caster.EmitSound(soundString);

    caster.StartGesture(GameActivity_t.ACT_DOTA_POOF_END)
    
  }
}
