LinkLuaModifier("modifier_meepo_geostrike_lua","heroes/meepo/geostrike.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_meepo_geostrike_debuff_lua","heroes/meepo/geostrike.lua",LUA_MODIFIER_MOTION_NONE)
meepo_geostrike_lua = class({})
function meepo_geostrike_lua.GetIntrinsicModifierName(self)
    return "modifier_meepo_geostrike_lua"
end
modifier_meepo_geostrike_lua = class({})
function modifier_meepo_geostrike_lua.IsHidden(self)
    return true
end
function modifier_meepo_geostrike_lua.IsPermanent(self)
    return true
end
function modifier_meepo_geostrike_lua.DeclareFunctions(self)
    return {MODIFIER_EVENT_ON_ATTACK_LANDED}
end
function modifier_meepo_geostrike_lua.OnAttackLanded(self,keys)
    if (keys.attacker==self.GetParent(self)) and not keys.attacker.PassivesDisabled(keys.attacker) then
        local ability = self.GetAbility(self)
        local duration = ability.GetSpecialValueFor(ability,"duration_tooltip")
        local target = keys.target
        local attacker = keys.attacker
        local modifier = target.FindModifierByNameAndCaster(target,"modifier_meepo_geostrike_debuff_lua",attacker)
        if modifier then
            modifier.SetDuration(modifier,duration,true)
        else
            target.AddNewModifier(target,attacker,self.GetAbility(self),"modifier_meepo_geostrike_debuff_lua",{["duration"]=duration})
        end
    end
end
modifier_meepo_geostrike_debuff_lua = class({})
function modifier_meepo_geostrike_debuff_lua.GetAttributes(self)
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
function modifier_meepo_geostrike_debuff_lua.DeclareFunctions(self)
    return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end
function modifier_meepo_geostrike_debuff_lua.GetModifierMoveSpeedBonus_Percentage(self)
    return self.slow
end
function modifier_meepo_geostrike_debuff_lua.OnCreated(self)
    if IsServer() then
        self.damage=self.GetAbility(self).GetAbilityDamage(self.GetAbility(self))
        self.slow=self.GetAbility(self).GetSpecialValueFor(self.GetAbility(self),"slow")
        self.StartIntervalThink(self,1)
        self.particle=ParticleManager.CreateParticle(ParticleManager,"particles/units/heroes/hero_meepo/meepo_geostrike.vpcf",PATTACH_ABSORIGIN_FOLLOW,self.GetCaster(self))
        ParticleManager.SetParticleControl(ParticleManager,self.particle,0,Vector(0,0,0))
        self.AddParticle(self,self.particle,true,false,1,false,false)
    end
end
function modifier_meepo_geostrike_debuff_lua.OnIntervalThink(self)
    local dTable = {["attacker"]=self.GetCaster(self),["victim"]=self.GetParent(self),["damage"]=self.damage,["damage_type"]=DAMAGE_TYPE_MAGICAL}
    ApplyDamage(dTable)
end
