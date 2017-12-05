LinkLuaModifier("modifier_sniper_headshot_passive","heroes/sniper/headshot.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sniper_headshot_enemies","heroes/sniper/headshot.lua",LUA_MODIFIER_MOTION_NONE)

---@class sniper_headshot_lua : CDOTA_Ability_Lua
sniper_headshot_lua = class({})
---@override
function sniper_headshot_lua:GetIntrinsicModifierName()
    return "modifier_sniper_headshot_passive"
end

---@class modifier_sniper_headshot_passive : CDOTA_Modifier_Lua
modifier_sniper_headshot_passive = class({})
---@override
function modifier_sniper_headshot_passive:DeclareFunctions()
    return {
        --MODIFIER_EVENT_ON_ATTACK_START,
        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL,
    }
end
---@override
function modifier_sniper_headshot_passive:GetModifierProcAttack_BonusDamage_Physical(keys) -- This only triggers serversside on attack.
    if IsServer() then
        local target = keys.target
        local caster = self:GetCaster()
        local ability = self:GetAbility()
        if caster:PassivesDisabled() then return 0 end
        if target:IsBuilding() or target:IsOther() then return 0 end
        if RollPercentage(ability:GetSpecialValueFor("proc_chance")) then
            target:AddNewModifier(caster,self:GetAbility(),"modifier_sniper_headshot_enemies",{ duration = ability:GetSpecialValueFor("slow_duration")})
            local talent = caster:FindAbilityByName("special_bonus_unique_sniper_3_lua")
            if talent and talent:GetLevel() > 0 then
                local knockback_dist = talent:GetSpecialValueFor("value")
                local knockback =	{
                    should_stun = 0,
                    knockback_duration = 0.1, -- Wiki says knockback speed is 350, 35/350 = 0.1
                    duration = 0.1,
                    knockback_distance = knockback_dist,
                    knockback_height = 0,
                    center_x = caster:GetAbsOrigin().x,
                    center_y = caster:GetAbsOrigin().y,
                    center_z = caster:GetAbsOrigin().z,
                }
                -- If using motion controllers, this has the lowest priority
                target:AddNewModifier(caster,self:GetAbility(),"modifier_knockback",knockback)
            end
        else
            return 0
        end
    end
end

---@class modifier_sniper_headshot_enemies : CDOTA_Modifier_Lua
modifier_sniper_headshot_enemies = class({})

---@override
function modifier_sniper_headshot_enemies:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    }
end
---@override
function modifier_sniper_headshot_enemies:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end

---@override
function modifier_sniper_headshot_enemies:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("slow")
end

---@override
function modifier_sniper_headshot_enemies:GetEffectName()
    return "particles/units/heroes/hero_sniper/sniper_headshot_slow.vpcf"
end

---@override
function modifier_sniper_headshot_enemies:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end