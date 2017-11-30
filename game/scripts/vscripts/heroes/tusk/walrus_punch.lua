-- modifier_tusk_walrus_punch is taken by the game
LinkLuaModifier("modifier_tusk_walrus_punch_lua","heroes/tusk/walrus_punch.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tusk_walrus_punch_crit","heroes/tusk/walrus_punch.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tusk_walrus_punch_slow","heroes/tusk/walrus_punch.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tusk_walrus_punch_flying","heroes/tusk/walrus_punch.lua",LUA_MODIFIER_MOTION_NONE)

---@class tusk_walrus_punch_lua : CDOTA_Ability_Lua
tusk_walrus_punch_lua = class({})

---@override
function tusk_walrus_punch_lua:GetIntrinsicModifierName()
    return "modifier_tusk_walrus_punch_lua"
end

---@param hTarget CDOTA_BaseNPC
function tusk_walrus_punch_lua:CastWalrusPunch(hTarget)
    local caster = self:GetCaster()
    local target = hTarget

    local air_time_duration = self:GetSpecialValueFor("air_time")
    local duration = self:GetSpecialValueFor("slow_duration")

    caster:AddNewModifier(caster,self,"modifier_tusk_walrus_punch_crit",{})
    -- Could also be in OnAttackLanded
    target:AddNewModifier(caster,self,"modifier_tusk_walrus_punch_flying",{duration = air_time_duration})
    target:AddNewModifier(caster,self,"modifier_tusk_walrus_punch_slow",{duration = duration})

    -- Text particles
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_tusk/tusk_walruspunch_txt_ult.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControl(particle, 2, caster:GetAbsOrigin()+Vector(0,0,175))
    ParticleManager:ReleaseParticleIndex(particle)

    caster:EmitSound("Hero_Tusk.WalrusPunch.Cast")
end

---@class modifier_tusk_walrus_punch_lua : CDOTA_Modifier_Lua
modifier_tusk_walrus_punch_lua = class({})

---@override
function modifier_tusk_walrus_punch_lua:IsHidden() return false end
---@override
function modifier_tusk_walrus_punch_lua:IsPermanent() return true end

---@override
function modifier_tusk_walrus_punch_lua:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_START,
    }
end

---@param hTarget CDOTA_BaseNPC
---@return boolean
function modifier_tusk_walrus_punch_lua:IsValidToTrigger(hTarget)
    -- Rejection based on target
    if hTarget:GetTeamNumber() ==  self:GetCaster():GetTeamNumber() then return false end
    if hTarget:IsBuilding() or hTarget:IsOther() then return false end
    -- Talent cast doesn't require resources
    local talent = self:GetCaster():FindAbilityByName("special_bonus_unique_tusk_3_lua")
    if talent then
        local walrus_punch_chance = talent:GetSpecialValueFor("value")
        if RollPercentage(walrus_punch_chance) then
            return true
        end
    end
    
    if not self:GetAbility():IsCooldownReady() or not self:GetAbility():GetAutoCastState() then return false end
    if self:GetCaster():GetMana() < self:GetAbility():GetManaCost(-1) then return false end
    self:GetAbility():UseResources(true,false,true)
    return true
end

function modifier_tusk_walrus_punch_lua:OnAttackStart(keys)
    local target = keys.target
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    
    if keys.attacker ~= self:GetCaster() then return end
    if not self:IsValidToTrigger(target) then return end
    -- I prefer to use the ability for this
    ability:CastWalrusPunch(target)
end

---@class modifier_tusk_walrus_punch_crit : CDOTA_Modifier_Lua
modifier_tusk_walrus_punch_crit = class({})

---@override
function modifier_tusk_walrus_punch_crit:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
end

---@override
function modifier_tusk_walrus_punch_crit:OnCreated()
    if IsServer() then
        local ability = self:GetAbility()
        self.crit_multiplier = ability:GetSpecialValueFor("crit_multiplier")
        local talent = self:GetCaster():FindAbilityByName("special_bonus_unique_tusk_3_lua")
        if talent then
            self.crit_multiplier = self.crit_multiplier + talent:GetSpecialValueFor("value")
        end
    end
end


---@override
function modifier_tusk_walrus_punch_crit:GetModifierPreAttack_CriticalStrike(keys)
    if IsServer() then -- Property won't be displayed on client anyway
        return self.crit_multiplier
    end
end

---@override
function modifier_tusk_walrus_punch_crit:OnAttackLanded()
    self:GetCaster():EmitSound("Hero_Tusk.WalrusPunch.Target")
    self:Destroy()
end
---@class modifier_tusk_walrus_punch_flying : CDOTA_Modifier_Lua
modifier_tusk_walrus_punch_flying = class({})

---@override
function modifier_tusk_walrus_punch_flying:CheckState()
    return {
        [MODIFIER_STATE_STUNNED] = IsServer(), -- Not showing the status bar
    }
end

---@override
function modifier_tusk_walrus_punch_flying:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
    }
end

---@override
function modifier_tusk_walrus_punch_flying:GetOverrideAnimation()
    return ACT_DOTA_FLAIL
end

---@override
function modifier_tusk_walrus_punch_flying:OnCreated(keys)
    if IsServer() then
        self.air_time_duration = self:GetAbility():GetSpecialValueFor("air_time")
        local max_height = 650
        -- The height that needs to be gained when the unit moves 1 unit.
        self.z_vel = max_height * 4
        self.direction = Vector(0,0,self.z_vel)
        
        self:StartIntervalThink(FrameTime())
    end
end

---@override
function modifier_tusk_walrus_punch_flying:OnIntervalThink()
    local unit = self:GetParent()
    -- Decrease the z velocity
    self.direction.z = self.direction.z - (self.z_vel *2  *FrameTime())
    unit:SetAbsOrigin(unit:GetAbsOrigin() + self.direction *  FrameTime())
end

---@override
function modifier_tusk_walrus_punch_flying:OnDestroy()
    if IsServer() then
        -- Make sure the unit ends on the ground
        -- Don't think this is needed though, the engine sets unit to ground level on movement
        FindClearSpaceForUnit(self:GetParent(),self:GetParent():GetAbsOrigin(),true)
    end
end


---@class modifier_tusk_walrus_punch_slow : CDOTA_Modifier_Lua
modifier_tusk_walrus_punch_slow = class({})

---@override
function modifier_tusk_walrus_punch_slow:OnCreated()
    self.slow = self:GetAbility():GetSpecialValueFor("move_slow")
end

---@override
function modifier_tusk_walrus_punch_slow:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end

---@override
function modifier_tusk_walrus_punch_slow:GetModifierMoveSpeedBonus_Percentage()
    return self.slow
end

---@override
function modifier_tusk_walrus_punch_slow:GetStatusEffectName()
    return "particles/units/heroes/hero_tusk/tusk_walruspunch_status.vpcf"
end

