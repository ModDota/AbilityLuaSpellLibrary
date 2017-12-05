-- IMPORTANT!
-- Add the "base_ability_charges" from npc_abilities_custom.txt to your npc_abilities_custom.txt file for this to work!
-- Also store the util/base_ability_charges.lua somewhere, and adjust the require path below.
-- The modifier you link should be named "modifier_" YOUR_ABILITY_NAME "_charges", in this case modifier_sniper_shrapnel_lua_charges
require('heroes/util/base_ability_charges')

LinkLuaModifier("modifier_sniper_shrapnel_lua_charges","heroes/sniper/shrapnel.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sniper_shrapnel_lua_aura","heroes/sniper/shrapnel.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sniper_shrapnel_lua_aura_modifier","heroes/sniper/shrapnel.lua",LUA_MODIFIER_MOTION_NONE)

-- Using the baseclass of the charges modifier instead of creating a new one
---@class sniper_shrapnel_lua : base_ability_charges
sniper_shrapnel_lua = class(base_ability_charges)
---@override
function sniper_shrapnel_lua:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

---@override
function sniper_shrapnel_lua:OnSpellStart()
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    local duration = self:GetSpecialValueFor("duration")
    local radius = self:GetSpecialValueFor("radius")
    local talent = caster:FindAbilityByName("special_bonus_unique_sniper_2")
    if talent and talent:GetLevel() ~= 0 then
        self:GetIntrinsicModifierHandle().max_charges = self:GetSpecialValueFor("max_charges") + talent:GetSpecialValueFor("value")
    end

    self:CreateVisibilityNode(point,radius,duration)

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_sniper/sniper_shrapnel_launch.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(particle, 1, point+Vector(0,0,1000))
    ParticleManager:ReleaseParticleIndex(particle)

    caster:EmitSound("Hero_Sniper.ShrapnelShoot")

    self:SetContextThink("shrapnel_delay",function()
        CreateModifierThinker(caster,self,"modifier_sniper_shrapnel_lua_aura",{duration = duration},point,caster:GetTeamNumber(),false)

        caster:EmitSound("Hero_Sniper.ShrapnelShatter" )
    end, self:GetSpecialValueFor("damage_delay"))
end

---@class modifier_sniper_shrapnel_lua_charges : modifier_base_ability_charges
modifier_sniper_shrapnel_lua_charges = class(modifier_base_ability_charges)

---@class modifier_sniper_shrapnel_lua_aura : CDOTA_Modifier_Lua
modifier_sniper_shrapnel_lua_aura = class({})
---@override
function modifier_sniper_shrapnel_lua_aura:OnCreated()
    if IsServer() then
        -- Ability specials
        self.radius = self:GetAbility():GetSpecialValueFor("radius")

        -- Add shrapnel particl effect
        self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_sniper/sniper_shrapnel.vpcf", PATTACH_WORLDORIGIN, nil)
        ParticleManager:SetParticleControl(self.particle, 0, self:GetParent():GetAbsOrigin())
        ParticleManager:SetParticleControl(self.particle, 1, Vector(self.radius, self.radius, 0))
        ParticleManager:SetParticleControl(self.particle, 2, self:GetParent():GetAbsOrigin())
        self:AddParticle(self.particle, false, false, -1, false, false)
    end
end
---@override
function modifier_sniper_shrapnel_lua_aura:IsAura() return true end
---@override
function modifier_sniper_shrapnel_lua_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end
---@override
function modifier_sniper_shrapnel_lua_aura:GetAuraRadius()
    return self.radius
end
---@override
function modifier_sniper_shrapnel_lua_aura:GetModifierAura()
    return "modifier_sniper_shrapnel_lua_aura_modifier"
end
---@override
function modifier_sniper_shrapnel_lua_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end
function modifier_sniper_shrapnel_lua_aura:GetAuraDuration()
    return self:GetAbility():GetSpecialValueFor("slow_duration")
end
---@class modifier_sniper_shrapnel_lua_aura_modifier : CDOTA_Modifier_Lua
modifier_sniper_shrapnel_lua_aura_modifier = class({})
---@override
function modifier_sniper_shrapnel_lua_aura_modifier:OnCreated()
    if IsServer then
        self.damage = self:GetAbility():GetSpecialValueFor("shrapnel_damage")
        local talent = caster:FindAbilityByName("special_bonus_unique_sniper_1")
        if talent and talent:GetLevel() ~= 0 then
            self.damage = self.damage + talent:GetSpecialValueFor("value")
        end
        self:StartIntervalThink(1)
        self:OnIntervalThink()
    end
end

function modifier_sniper_shrapnel_lua_aura_modifier:OnIntervalThink()
    local damageTable = {
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = self.damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
    }
end
---@override
function modifier_sniper_shrapnel_lua_aura_modifier:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end

---@override
function modifier_sniper_shrapnel_lua_aura_modifier:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow_movement_speed")
end
