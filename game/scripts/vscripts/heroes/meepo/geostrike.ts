LinkLuaModifier("modifier_meepo_geostrike_lua","heroes/meepo/geostrike.lua",LuaModifierType.LUA_MODIFIER_MOTION_NONE);
LinkLuaModifier("modifier_meepo_geostrike_debuff_lua","heroes/meepo/geostrike.lua",LuaModifierType.LUA_MODIFIER_MOTION_NONE);

class meepo_geostrike_lua extends CDOTA_Ability_Lua {
  GetIntrinsicModifierName() { return "modifier_meepo_geostrike_lua" }

}



class modifier_meepo_geostrike_lua extends CDOTA_Modifier_Lua   {
  IsHidden() {return true}
  IsPermanent() {return true}


  DeclareFunctions() {

    return [
      modifierfunction.MODIFIER_EVENT_ON_ATTACK_LANDED,
    ]
  }

  

  OnAttackLanded(keys) {

    if (keys.attacker == this.GetParent() && !keys.attacker.PassivesDisabled()) {
      let ability = this.GetAbility()
      let duration = ability.GetSpecialValueFor("duration_tooltip")
      let target = <CDOTA_BaseNPC> keys.target
      let attacker = <CDOTA_BaseNPC> keys.attacker
      let modifier = target.FindModifierByNameAndCaster("modifier_meepo_geostrike_debuff_lua",attacker)
      if (modifier) {
        modifier.SetDuration(duration,true)
      } else {
        target.AddNewModifier(attacker,this.GetAbility(),"modifier_meepo_geostrike_debuff_lua",{duration:duration})
      }
    }
  }
}

class modifier_meepo_geostrike_debuff_lua extends CDOTA_Modifier_Lua {
  damage : number
  slow : number
  particle:ParticleID

  GetAttributes() {
    return DOTAModifierAttribute_t.MODIFIER_ATTRIBUTE_MULTIPLE
    
  }

  DeclareFunctions() {
    return [
      modifierfunction.MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    ]
  }


  GetModifierMoveSpeedBonus_Percentage() {
    return this.slow
  }
  OnCreated() {
    if (IsServer()) {
      this.damage = this.GetAbility().GetAbilityDamage()
      this.slow = this.GetAbility().GetSpecialValueFor("slow")
      this.StartIntervalThink(1)
    }
  }

  OnIntervalThink() {
    let dTable: DamageTable = {attacker:this.GetCaster(),victim:this.GetParent(),damage:this.damage,damage_type:DAMAGE_TYPES.DAMAGE_TYPE_MAGICAL};
    ApplyDamage(dTable);
  }

  GetEffectName() {
    return "particles/units/heroes/hero_meepo/meepo_geostrike.vpcf"
  }
  GetEffectAttachType() {
    return ParticleAttachment_t.PATTACH_ABSORIGIN_FOLLOW
  }
}
 
