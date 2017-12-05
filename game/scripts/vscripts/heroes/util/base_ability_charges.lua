LinkLuaModifier("modifier_base_ability_charges","heroes/sniper/assassinate.lua",LUA_MODIFIER_MOTION_NONE)

---@class base_ability_charges : CDOTA_Ability_Lua
base_ability_charges = class({})

---@overide
function base_ability_charges:GetIntrinsicModifierName()
    return "modifier_"..self:GetAbilityName().."_charges"
end
---@return CDOTA_Modifier_Lua
function base_ability_charges:GetIntrinsicModifierHandle()
    return self:GetCaster():FindModifierByName(self:GetIntrinsicModifierName())
end
---Override this when you have another name in your abilityspecial values
---@return number
function base_ability_charges:GetMaxChargeCount()
    return self:GetSpecialValueFor("max_charges")
end
---Override this when you have another name in your abilityspecial values
---@return number
function base_ability_charges:GetChargeRestoreTime()
    return self:GetSpecialValueFor("charge_restore_time")
end
---Override this if you don't want this to start at max
---@return nil
function base_ability_charges:GetStartStackCount()
    return nil
end
---@override
function base_ability_charges:GetCooldown()
    if IsServer() then
        return 0
    else
        return self:GetChargeRestoreTime()
    end
end

---@class modifier_base_ability_charges : CDOTA_Modifier_Lua
modifier_base_ability_charges = class({})

---@override
function modifier_base_ability_charges:IsDebuff()
    return false
end
---@override
function modifier_base_ability_charges:IsPermanent()
    return true
end
---@override
function modifier_base_ability_charges:OnCreated()
    if IsServer() then
        self.max_charges = self:GetAbility():GetMaxChargeCount()
        if self:GetAbility():GetStartStackCount() then
            self:SetStackCount(self:GetAbility():GetStartStackCount())
        else
            self:SetStackCount(self.max_charges)
        end
        self.charge_restore_time = self:GetAbility():GetChargeRestoreTime()
        self:StartIntervalThink(FrameTime())
    end
end
---@override
function modifier_base_ability_charges:OnRefresh()
    if IsServer() then
        self.max_charges = self:GetAbility():GetMaxChargeCount()
        self.charge_restore_time = self:GetAbility():GetChargeRestoreTime()
    end
end
---@override
function modifier_base_ability_charges:OnIntervalThink()
    if self:GetStackCount() == self.max_charges then
        self:SetDuration(self.charge_restore_time,true)
        return
    end
    if self:GetRemainingTime() <= 0 then
        self:SetStackCount(math.min(self.max_charges,self:GetStackCount()+1))
        self:SetDuration(self.charge_restore_time,true)
    end
end
function modifier_base_ability_charges:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
    }
end
---@override
function modifier_base_ability_charges:OnAbilityFullyCast(keys)
    if IsServer() then
        if keys.unit == self:GetCaster() and keys.ability == self:GetAbility() then
            self:DecrementStackCount()
            if self:GetStackCount() == 0 then
                self:GetAbility():StartCooldown(self.charge_restore_time)
            end
            if self:GetRemainingTime() < 0 then
                self:SetDuration(self.charge_restore_time,true)
            end
        end
    end
end