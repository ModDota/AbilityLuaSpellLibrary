LinkLuaModifier("modifier_sniper_assassinate_caster_lua","heroes/sniper/assassinate.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sniper_assassinate_target_lua","heroes/sniper/assassinate.lua",LUA_MODIFIER_MOTION_NONE)

-- The spell is almost completely different with and without Aghanims Scepter.
---@class sniper_assassinate_lua : CDOTA_Ability_Lua
sniper_assassinate_lua = class({})
---@override
function sniper_assassinate_lua:GetBehavior()
    if self:GetCaster():HasScepter() then
        return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE
    else -- Normal (non-scepter)
        return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
    end
end
---@override
function sniper_assassinate_lua:GetAbilityDamageType()
    if self:GetCaster():HasScepter() then
        return DAMAGE_TYPE_PHYSICAL
    else -- Normal (non-scepter)
        return DAMAGE_TYPE_MAGICAL
    end
end
---@override
function sniper_assassinate_lua:GetAOERadius()
    if self:GetCaster():HasScepter() then
        return self:GetSpecialValueFor("scepter_radius")
    else -- Normal (non-scepter)
        return 0
    end
end

---@override
function sniper_assassinate_lua:GetCastPoint()
    local time = self.BaseClass.GetCastPoint(self)
    local talent = self:GetCaster():FindAbilityByName("special_bonus_unique_sniper_4")
    if talent  then
        time = time - talent:GetSpecialValueFor("value")
    end
    return time
end

---@override
function sniper_assassinate_lua:OnAbilityPhaseStart(keys)
    local caster = self:GetCaster()
    caster:EmitSound("Ability.AssassinateLoad")
    -- Store the target(s) in self.storedTarget, apply a modifier that reveals them
    self.storedTarget = {}
    if caster:HasScepter() then
        local point = self:GetCursorPosition()
        self.storedTarget = FindUnitsInRadius(caster:GetTeamNumber(),point,caster,self:GetSpecialValueFor("scepter_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NO_INVIS, FIND_CLOSEST, false)
        for k,v in pairs(self.storedTarget) do
            v:AddNewModifier(caster,self,"modifier_sniper_assassinate_target_lua",{})
        end
    else -- Normal (non-scepter)
        self.storedTarget[1] = self:GetCursorTarget()
        self.storedTarget[1]:AddNewModifier(caster,self,"modifier_sniper_assassinate_target_lua",{}) -- Make this

    end
    return true
end
---@override
function sniper_assassinate_lua:OnAbilityPhaseInterrupted()
    -- Remove the crosshairs from the target(s), and remove the modifier from the caster
    if self.storedTarget then
        for k,v in pairs(self.storedTarget) do
            v:RemoveModifierByName("modifier_sniper_assassinate_target_lua")
        end
    end
    self.storedTarget = nil
    self:GetCaster():RemoveModifierByNameAndCaster("modifier_sniper_assassinate_caster_lua",self:GetCaster())
end
---@override
function sniper_assassinate_lua:OnSpellStart(keys)
    self:GetCaster():EmitSound("Ability.Assassinate")

    if not self.storedTarget then -- Should never happen, but to prevent errors we return here
        return
    end
    -- Because we stored the targets in a table, it is easy to fire a projectile at all of them
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


    -- Linkens dodge
    if not self:GetCaster():HasScepter() then
        if target:TriggerSpellAbsorb(self) then
            return true
        end
    end

    target:EmitSound("Hero_Sniper.AssassinateDamage")

    if caster:HasScepter() then
        -- Quickly create and remove the crit modifier
        caster:AddNewModifier(caster,self,"modifier_sniper_assassinate_caster_lua",{})
        caster:PerformAttack(target,true,true,true,true,false, false, true)
        caster:RemoveModifierByName("modifier_sniper_assassinate_caster_lua")
    else -- Normal (non-scepter)
        local damageTable = {
            victim = target,
            attacker = caster,
            damage = self:GetAbilityDamage(),
            damage_type = self:GetAbilityDamageType(),
        }
        ApplyDamage(damageTable)
    end
    -- Remove the crosshair+vision
    target:RemoveModifierByName("modifier_sniper_assassinate_target_lua")

    self.storedTarget[target] = nil
    for k,v in pairs(self.storedTarget) do
        if v == target then
            self.storedTarget[k] = nil
        end
    end
    return true
end
-- Marks the target(s) and provides vision for them
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
-- This modifier provides the crit
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