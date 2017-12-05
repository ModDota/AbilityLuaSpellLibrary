LinkLuaModifier("modifier_sniper_take_aim","heroes/sniper/take_aim.lua",LUA_MODIFIER_MOTION_NONE)

---@class sniper_take_aim_lua : CDOTA_Ability_Lua
sniper_take_aim_lua = class({})
---@override
function sniper_take_aim_lua:GetIntrinsicModifierName()
    return "modifier_sniper_take_aim_lua"
end

---@class modifier_sniper_take_aim_lua : CDOTA_Modifier_Lua
modifier_sniper_take_aim_lua = class({})
---@override
function modifier_sniper_take_aim_lua:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
    }
end
---@override
function modifier_sniper_take_aim_lua:GetModifierAttackRangeBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_range")
end