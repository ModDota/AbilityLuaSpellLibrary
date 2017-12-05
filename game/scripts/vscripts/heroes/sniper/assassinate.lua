LinkLuaModifier("modifier_sniper_assassinate_caster_lua","heroes/sniper/assassinate.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sniper_assassinate_target_lua","heroes/sniper/assassinate.lua",LUA_MODIFIER_MOTION_NONE)

---@class sniper_assassinate_lua : CDOTA_Ability_Lua
sniper_assassinate_lua = class({})
---@override
function sniper_assassinate_lua:GetBehavior()
    if not self:GetCaster():HasScepter() then
        return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
    else
        return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE
    end
end
---@override
function sniper_assassinate_lua:GetAbilityDamageType()
    if not self:GetCaster():HasScepter() then
        return DAMAGE_TYPE_MAGICAL
    else
        return DAMAGE_TYPE_PHYSICAL
    end
end
---@override
function sniper_assassinate_lua:GetAOERadius()
    if not self:GetCaster():HasScepter() then
        return 0
    else
        return self:GetSpecialValueFor("scepter_radius")
    end
end

---@override
function sniper_assassinate_lua:ProcsMagicStick()
    return true
end
---@override
function sniper_assassinate_lua:GetCastPoint()
    local time = self.BaseClass.GetCastPoint()
    local talent = self:GetCaster():FindAbilityByName("special_bonus_unique_sniper_4")
    if talent  then
        time = time - talent:GetSpecialValueFor("value")
    end
    return time
end
---@override
function sniper_assassinate_lua:GetBackswingTime()
    local time = 1.37
    if talent then
        time = time + talent:GetSpecialValueFor("value")
    end
    return time
end

---@override
function sniper_assassinate_lua:OnAbilityPhaseStart(keys)
    local caster = self:GetCaster()
    caster:EmitSound("Ability.AssassinateLoad")
    self.storedTarget = {}
    caster:AddNewModifier(caster,self,"modifier_sniper_assassinate_caster_lua",{})
    if not caster:HasScepter() then
        self.storedTarget[1] = self:GetCursorTarget()
        self.storedTarget[1]:AddNewModifier(caster,self,"modifier_sniper_assassinate_target_lua",{}) -- Make this
    else
        local point = self:GetCursorPosition()
        self.storedTarget = FindUnitsInRadius(caster:GetTeamNumber(),point,caster,self:GetSpecialValueFor("scepter_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NO_INVIS, FIND_CLOSEST, false)
        for k,v in pairs(self.storedTarget) do
            v:AddNewModifier(caster,self,"modifier_sniper_assassinate_target_lua",{})
        end
    end
    return true
end
---@override
function sniper_assassinate_lua:OnAbilityPhaseInterrupted()
    if self.storedTarget then
        for k,v in pairs(self.storedTarget) do
            v:RemoveModifierByName("modifier_sniper_assassinate_target_lua")
        end
    end
    self.storedTarget = nil
    self:GetCaster():RemoveModifierByName("modifier_sniper_assassinate_caster_lua")
end
---@override
function sniper_assassinate_lua:OnSpellStart(keys)
    self:GetCaster():EmitSound("Ability.Assassinate")

    if not self.storedTarget then
        return
    end
    for k,v in pairs(self.storedTarget) do
        local projTable = {
            EffectName = "particles/units/heroes/hero_sniper/sniper_assassinate.vpcf",
            Ability = self,
            Target = v,
            Source = self:GetCaster(),
            bDodgeable = true,
            bProvidesVision = true,
            vSpawnOrigin = self:GetCaster():GetAbsOrigin(),
            iMoveSpeed = self:GetSpecialValueFor("projectile_speed"), --
            iVisionRadius = 100,--
            iVisionTeamNumber = self:GetCaster():GetTeamNumber(),
            iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
        }
        ProjectileManager:CreateTrackingProjectile(projTable)
    end
end
---@override
function sniper_assassinate_lua:OnProjectileHit(hTarget,vLocation)
    local caster = self:GetCaster()

    local target = hTarget

    if not target then
        return true
    end

    if not self:GetCaster():HasScepter() then
        if target:TriggerSpellAbsorb(self) then
            return true
        end
    end

    target:EmitSound("Hero_Sniper.AssassinateDamage")
    if not caster:HasScepter() then
        --print(self:GetSpecialValueFor("damage"))
        local damageTable = {
            victim = target,
            attacker = caster,
            damage = self:GetAbilityDamage(),
            damage_type = self:GetAbilityDamageType(),
        }
        ApplyDamage(damageTable)
    else
        caster:PerformAttack(target,true,true,true,true,false, false, true)
    end
    target:RemoveModifierByName("modifier_sniper_assassinate_target_lua")

    self.storedTarget[target] = nil
    for k,v in pairs(self.storedTarget) do
        if v == target then
            self.storedTarget[k] = nil
        end
    end
    if #self.storedTarget == 0 then
        caster:RemoveModifierByName("modifier_sniper_assassinate_caster_lua")
    end
    return true
end

---@class modifier_sniper_assassinate_target_lua : CDOTA_Modifier_Lua
modifier_sniper_assassinate_target_lua = class({})
---@override
function modifier_sniper_assassinate_target_lua:IsHidden()
    return true
end
---@override
function modifier_sniper_assassinate_target_lua:IsPurgable()
    return false
end
---@override
function modifier_sniper_assassinate_target_lua:IsDebuff()
    return true
end
---@override
function modifier_sniper_assassinate_target_lua:GetEffectName()
    return "particles/units/heroes/hero_sniper/sniper_crosshair.vpcf"
end
---@override
function modifier_sniper_assassinate_target_lua:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end
---@override
function modifier_sniper_assassinate_target_lua:CheckStates()
    local state = {
        [MODIFIER_STATE_INVISIBLE] = false,
    }
    return state
end
---@override
function modifier_sniper_assassinate_target_lua:DeclareFunctions()
  local funcs = { 
    MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
  }
end
---@override
function modifier_sniper_assassinate_target_lua:GetModifierProvidesFOWVision()
  return 1
end
---@override
function modifier_sniper_assassinate_target_lua:OnCreated()
    if IsServer() then
        self:StartIntervalThink(FrameTime())
    end
end

---@class modifier_sniper_assassinate_caster_lua : CDOTA_Modifier_Lua
modifier_sniper_assassinate_caster_lua = class({})
---@override
function modifier_sniper_assassinate_caster_lua:IsHidden()
    return true
end
---@override
function modifier_sniper_assassinate_caster_lua:IsPurgable()
    return false
end
---@override
function modifier_sniper_assassinate_caster_lua:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
    }
    return funcs
end
---@override
function modifier_sniper_assassinate_caster_lua:GetModifierPreAttack_CriticalStrike()
    if IsServer() then
        return self:GetAbility():GetSpecialValueFor("scepter_crit_bonus")
    end
end