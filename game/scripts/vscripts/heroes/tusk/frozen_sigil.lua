LinkLuaModifier("modifier_tusk_sigil_slow_aura","heroes/tusk/frozen_sigil.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tusk_sigil_slow_aura_modifier","heroes/tusk/frozen_sigil.lua",LUA_MODIFIER_MOTION_NONE)

---@class tusk_frozen_sigil_lua : CDOTA_Ability_Lua
tusk_frozen_sigil_lua = class({})
---@override
function tusk_frozen_sigil_lua:OnSpellStart()
    local caster = self:GetCaster()
    local sigil_duration = self:GetSpecialValueFor("sigil_duration")
    -- Unit can be found in npc_dota_units.txt file
    local unit = CreateUnitByName("npc_dota_tusk_frozen_sigil"..self:GetLevel(),caster:GetAbsOrigin(),false,caster,caster:GetPlayerOwner(),caster:GetTeamNumber())
    unit:SetControllableByPlayer(caster:GetPlayerOwnerID(),false)
    --Transfer this ability to the sigil, so there can't be nil references when this is stolen
    local ability = unit:AddAbility(self:GetAbilityName())
    ability:SetLevel(self:GetLevel())
    ability:SetHidden(true)
    -- Default modifier, can't be recreated.
    unit:AddNewModifier(caster,ability,"modifier_kill",{duration = sigil_duration})
    unit:AddNewModifier(caster,ability,"modifier_tusk_sigil_slow_aura",{duration = sigil_duration})
end

---@class modifier_tusk_sigil_slow_aura : CDOTA_Modifier_Lua
modifier_tusk_sigil_slow_aura = class({})
---@override
function modifier_tusk_sigil_slow_aura:OnCreated()
    self.radius = self:GetAbility():GetSpecialValueFor("sigil_radius")
    if IsServer() then
        self:GetParent():EmitSound("Hero_Tusk.FrozenSigil")
        local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_tusk/tusk_frozen_sigil.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    end
end
-- This also makes it permanent
---@override
function modifier_tusk_sigil_slow_aura:IsAura() return true end
---@override
function modifier_tusk_sigil_slow_aura:IsDebuff() return false end
---@override
function modifier_tusk_sigil_slow_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end
---@override
function modifier_tusk_sigil_slow_aura:GetAuraRadius()
    return self.radius
end
---@override
function modifier_tusk_sigil_slow_aura:GetModifierAura()
    return "modifier_tusk_sigil_slow_aura_modifier"
end
---@override
function modifier_tusk_sigil_slow_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end
---@override
function modifier_tusk_sigil_slow_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK
    }
end
---@override
function modifier_tusk_sigil_slow_aura:CheckState()
    return {
        [MODIFIER_STATE_MAGIC_IMMUNE] = true
    }
end
-- This does show a damage block icon, but I think it's better than setting health
---@override
function modifier_tusk_sigil_slow_aura:GetModifierTotal_ConstantBlock(keys)
    local damage = keys.damage
    local attacker = keys.attacker
    -- Block all damage from abilities
    if keys.inflictor then return keys.damage end
    if attacker:IsRealHero() then
        -- Sigil takes 4 damage from heroes
        return keys.damage - 4
    else
        -- Sigil takes 1 damage from heroes
        return keys.damage - 1
    end
end

---@override
function modifier_tusk_sigil_slow_aura:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

---@class modifier_tusk_sigil_slow_aura_modifier : CDOTA_Modifier_Lua
modifier_tusk_sigil_slow_aura_modifier = class({})

---@override
function modifier_tusk_sigil_slow_aura_modifier:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    }
end
---@override
function modifier_tusk_sigil_slow_aura_modifier:GetModifierAttackSpeedBonus_Constant()
    return -1 * self:GetAbility():GetSpecialValueFor("attack_slow")
end

---@override
function modifier_tusk_sigil_slow_aura_modifier:GetModifierMoveSpeedBonus_Percentage()
    return -1 * self:GetAbility():GetSpecialValueFor("move_slow")
end

---@override
function modifier_tusk_sigil_slow_aura_modifier :GetStatusEffectName()
    return "particles/units/heroes/hero_tusk/tusk_frozen_sigil_status.vpcf"
end

