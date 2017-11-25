---@class vengefulspirit_command_aura_lua : CDOTA_Ability_Lua
vengefulspirit_command_aura_lua = class({})

---@class modifier_vengefulspirit_command_aura_lua : CDOTA_Modifier_Lua
modifier_vengefulspirit_command_aura_lua = class({})
LinkLuaModifier( "modifier_vengefulspirit_command_aura_lua", LUA_MODIFIER_MOTION_NONE )

---@class modifier_vengefulspirit_command_aura_effect_lua : CDOTA_Modifier_Lua
modifier_vengefulspirit_command_aura_effect_lua = class({})
LinkLuaModifier( "modifier_vengefulspirit_command_aura_effect_lua", LUA_MODIFIER_MOTION_NONE )

---@return string
function vengefulspirit_command_aura_lua:GetIntrinsicModifierName()
	return "modifier_vengefulspirit_command_aura_lua"
end

---@return boolean
function modifier_vengefulspirit_command_aura_lua:IsHidden()
    return true
end

---@return boolean
function modifier_vengefulspirit_command_aura_lua:IsAura()
    return true
end

---@return string
function modifier_vengefulspirit_command_aura_lua:GetModifierAura()
    return "modifier_vengefulspirit_command_aura_effect_lua"
end

---@return DOTA_UNIT_TARGET_TEAM
function modifier_vengefulspirit_command_aura_lua:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

---@return DOTA_UNIT_TARGET_TYPE
function modifier_vengefulspirit_command_aura_lua:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP
end

---@return DOTA_UNIT_TARGET_FLAGS
function modifier_vengefulspirit_command_aura_lua:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

---@return number
function modifier_vengefulspirit_command_aura_lua:GetAuraRadius()
    return self.aura_radius
end

function modifier_vengefulspirit_command_aura_lua:OnCreated( kv )
    self.aura_radius = self:GetAbility():GetSpecialValueFor( "aura_radius" )
    if IsServer() and self:GetParent() ~= self:GetCaster() then
        self:StartIntervalThink( 0.5 )
    end
end

function modifier_vengefulspirit_command_aura_lua:OnRefresh( kv )
    self.aura_radius = self:GetAbility():GetSpecialValueFor( "aura_radius" )
end

---@return table
function modifier_vengefulspirit_command_aura_lua:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH
    }
    return funcs
end

---@class OnDeathParams
---@field attacker CDOTA_BaseNPC
---@field unit CDOTA_BaseNPC

---@param params OnDeathParams
---@return number
function modifier_vengefulspirit_command_aura_lua:OnDeath( params )
    if IsServer() then
        if self:GetCaster() == nil then
            return 0
        end

        if self:GetCaster():PassivesDisabled() then
            return 0
        end

        if self:GetCaster() ~= self:GetParent() then
            return 0
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
                hAuraHolder:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_vengefulspirit_command_aura_lua", modifierTable )

                local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_vengeful/vengeful_negative_aura.vpcf", PATTACH_ABSORIGIN_FOLLOW, hAuraHolder )
                ParticleManager:SetParticleControlEnt( nFXIndex, 1, hVictim, PATTACH_ABSORIGIN_FOLLOW, nil, hVictim:GetOrigin(), false )
                ParticleManager:ReleaseParticleIndex( nFXIndex )
            end
        end
    end

    return 0
end

function modifier_vengefulspirit_command_aura_lua:OnIntervalThink()
    if self:GetCaster() ~= self:GetParent() and self:GetCaster():IsAlive() then
        self:Destroy()
    end
end

---@return boolean
function modifier_vengefulspirit_command_aura_effect_lua:IsDebuff()
    if self:GetCaster():GetTeamNumber() ~= self:GetParent():GetTeamNumber() then
        return true
    end

    return false
end

function modifier_vengefulspirit_command_aura_effect_lua:OnCreated( kv )
    self.bonus_damage_pct = self:GetAbility():GetSpecialValueFor( "bonus_damage_pct" )
end

function modifier_vengefulspirit_command_aura_effect_lua:OnRefresh( kv )
    self.bonus_damage_pct = self:GetAbility():GetSpecialValueFor( "bonus_damage_pct" )
end

---@return table
function modifier_vengefulspirit_command_aura_effect_lua:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
    }
    return funcs
end

---@return number
function modifier_vengefulspirit_command_aura_effect_lua:GetModifierBaseDamageOutgoing_Percentage( params )
    if self:GetCaster():PassivesDisabled() then
        return 0
    end

    if self:GetCaster():GetTeamNumber() ~= self:GetParent():GetTeamNumber() then
        return -self.bonus_damage_pct
    end

    return self.bonus_damage_pct
end
