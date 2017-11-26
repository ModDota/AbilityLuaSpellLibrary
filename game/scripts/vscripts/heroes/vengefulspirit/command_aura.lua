--[[
ModDota AbilityLuaSpellLibrary implementation for Vengenge Aura

Mechanics correct as at 7.07c (excluding talents)
See github for contributor list
--]]

LinkLuaModifier("modifier_vengefulspirit_command_aura_effect_lua", "heroes/vengefulspirit/command_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vengefulspirit_command_aura_lua", "heroes/vengefulspirit/command_aura", LUA_MODIFIER_MOTION_NONE)

--[[
==============================
===== Command Aura Effect ====
==============================
--]]
---@class modifier_vengefulspirit_command_aura_effect_lua : CDOTA_Modifier_Lua
---@field bonus_damage_pct number
modifier_vengefulspirit_command_aura_effect_lua = class({})

---@override
function modifier_vengefulspirit_command_aura_effect_lua:IsDebuff()
    if self:GetCaster():GetTeamNumber() ~= self:GetParent():GetTeamNumber() then
        return true
    end

    return false
end

---@override
function modifier_vengefulspirit_command_aura_effect_lua:OnCreated()
    self.bonus_damage_pct = self:GetAbility():GetSpecialValueFor("bonus_damage_pct")
end

---@override
function modifier_vengefulspirit_command_aura_effect_lua:OnRefresh()
    self.bonus_damage_pct = self:GetAbility():GetSpecialValueFor("bonus_damage_pct")
end

---@override
function modifier_vengefulspirit_command_aura_effect_lua:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
    }
    return funcs
end

---@override
function modifier_vengefulspirit_command_aura_effect_lua:GetModifierBaseDamageOutgoing_Percentage()
    if self:GetCaster():PassivesDisabled() then
        return 0
    end

    if self:GetCaster():GetTeamNumber() ~= self:GetParent():GetTeamNumber() then
        return -self.bonus_damage_pct
    end

    return self.bonus_damage_pct
end

--[[
============================
===== Command Aura Aura ====
============================
--]]
---@class modifier_vengefulspirit_command_aura_lua : CDOTA_Modifier_Lua
---@field aura_radius number
modifier_vengefulspirit_command_aura_lua = class({})

---@override
function modifier_vengefulspirit_command_aura_lua:IsHidden()
    return true
end

---@override
function modifier_vengefulspirit_command_aura_lua:IsAura()
    return true
end

---@override
function modifier_vengefulspirit_command_aura_lua:GetModifierAura()
    return "modifier_vengefulspirit_command_aura_effect_lua"
end

---@override
function modifier_vengefulspirit_command_aura_lua:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

---@override
function modifier_vengefulspirit_command_aura_lua:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP
end

---@override
function modifier_vengefulspirit_command_aura_lua:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

---@override
function modifier_vengefulspirit_command_aura_lua:GetAuraRadius()
    return self.aura_radius
end

---@override
function modifier_vengefulspirit_command_aura_lua:OnCreated()
    self.aura_radius = self:GetAbility():GetSpecialValueFor("aura_radius")
    if IsServer() and self:GetParent() ~= self:GetCaster() then
        self:StartIntervalThink(0.5)
    end
end

---@override
function modifier_vengefulspirit_command_aura_lua:OnRefresh()
    self.aura_radius = self:GetAbility():GetSpecialValueFor("aura_radius")
end

---@override
function modifier_vengefulspirit_command_aura_lua:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH
    }
    return funcs
end

--TODO: This should be type annotated externally
---@class OnDeathParams
---@field attacker CDOTA_BaseNPC
---@field unit CDOTA_BaseNPC

---@param params OnDeathParams
---@override
function modifier_vengefulspirit_command_aura_lua:OnDeath(params)
    if IsServer() then
        if self:GetCaster() == nil then
            return
        end

        if self:GetCaster():PassivesDisabled() then
            return
        end

        if self:GetCaster() ~= self:GetParent() then
            return
        end

        local hAttacker = params.attacker
        local hVictim = params.unit

        if hVictim ~= nil and hAttacker ~= nil and hVictim == self:GetCaster() and hAttacker:GetTeamNumber() ~= hVictim:GetTeamNumber() then
            ---@type CDOTA_BaseNPC
            local hAuraHolder
            if hAttacker:IsHero() then
                hAuraHolder = hAttacker
            elseif hAttacker:GetOwnerEntity() ~= nil then
                ---@type CDOTA_BaseNPC
                local hAuraHolderTmp = hAttacker:GetOwnerEntity()
                if hAuraHolder:IsHero() then
                    hAuraHolder = hAuraHolderTmp
                end
            end

            if hAuraHolder ~= nil then
                local modifierTable = {
                    duration = -1
                }
                --TODO: Figure out why IntelliJ is convinced AddNewModifier does not exist
                hAuraHolder:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_vengefulspirit_command_aura_lua", modifierTable)

                local nFXIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_vengeful/vengeful_negative_aura.vpcf", PATTACH_ABSORIGIN_FOLLOW, hAuraHolder)
                ParticleManager:SetParticleControlEnt(nFXIndex, 1, hVictim, PATTACH_ABSORIGIN_FOLLOW, nil, hVictim:GetOrigin(), false)
                ParticleManager:ReleaseParticleIndex(nFXIndex )
            end
        end
    end

    return
end

---@override
function modifier_vengefulspirit_command_aura_lua:OnIntervalThink()
    if self:GetCaster() ~= self:GetParent() and self:GetCaster():IsAlive() then
        self:Destroy()
    end
end

--[[
=============================
===== Command Aura Spell ====
=============================
--]]
---@class vengefulspirit_command_aura_lua : CDOTA_Ability_Lua
vengefulspirit_command_aura_lua = class({})

---@override
function vengefulspirit_command_aura_lua:GetIntrinsicModifierName()
    return "modifier_vengefulspirit_command_aura_lua"
end
