-- Author: Shush
-- Date: 29/11/2017

-------------------------------
--   Anti Mage's Mana Void   --
-------------------------------
lua_antimage_mana_void = class({})
LinkLuaModifier("modifier_lua_mana_void_stunned", "antimage/antimage_mana_void", LUA_MODIFIER_MOTION_NONE)

function lua_antimage_mana_void:GetAbilityTextureName()
    return "antimage_mana_void"
end

function lua_antimage_mana_void:OnAbilityPhaseStart()
    if IsServer() then
        self:GetCaster():EmitSound("Hero_Antimage.ManaVoidCast")
        return true
    end
end

function lua_antimage_mana_void:GetAOERadius()
    return self:GetSpecialValueFor("mana_void_aoe_radius")
end

function lua_antimage_mana_void:IsHiddenWhenStolen()
    return false
end

function lua_antimage_mana_void:OnSpellStart()
  if IsServer() then
        -- Ability properties
        local caster = self:GetCaster()
        local ability = self        
        local target = self:GetCursorTarget()
        local modifier_ministun = "modifier_lua_mana_void_stunned"
        
        -- Ability specials        
        local mana_void_damage_per_mana = ability:GetSpecialValueFor("mana_void_damage_per_mana")
        local mana_void_ministun = ability:GetSpecialValueFor("mana_void_ministun")
        local mana_void_aoe_radius = ability:GetSpecialValueFor("mana_void_aoe_radius")
        
        -- If the target possesses a ready Linken's Sphere, do nothing
        if target:GetTeam() ~= caster:GetTeam() then
            if target:TriggerSpellAbsorb(ability) then
                return nil
            end
        end    

        -- Calculate missing mana and damage based on it
        local damage = 0

        -- Damage is not calculated on targets that have no mana pool
        if target:GetMaxMana() > 0 then
            local missing_mana = target:GetMaxMana() - target:GetMana()
            damage = missing_mana * mana_void_damage_per_mana
        end

        -- Ministun the main target
        target:AddNewModifier(caster, ability, modifier_ministun, {duration = mana_void_ministun})

        -- Find all nearby enemies
        local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
                                          target:GetAbsOrigin(),
                                          nil,
                                          mana_void_aoe_radius,
                                          DOTA_UNIT_TARGET_TEAM_ENEMY,
                                          DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                                          DOTA_UNIT_TARGET_FLAG_NONE,
                                          FIND_ANY_ORDER,
                                          false)

        -- Damage all enemies in the area for the total damage tally
        for _,enemy in pairs(enemies) do
            if not enemy:IsMagicImmune() then

                -- Deal damage
                local damageTable = {victim = enemy,
                                     damage = damage,
                                     damage_type = DAMAGE_TYPE_MAGICAL,
                                     attacker = caster,
                                     ability = ability
                                    }

                ApplyDamage(damageTable)
                SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, damage, nil)
            end             
        end        
        
        -- Mana Void effects
        local void_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_antimage/antimage_manavoid.vpcf", PATTACH_POINT_FOLLOW, target)
        ParticleManager:SetParticleControlEnt(void_pfx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetOrigin(), true)
        ParticleManager:SetParticleControl(void_pfx, 1, Vector(mana_void_aoe_radius,0,0))
        ParticleManager:ReleaseParticleIndex(void_pfx)
        target:EmitSound("Hero_Antimage.ManaVoid")    
    end 
end


-- Stun modifier
modifier_lua_mana_void_stunned = class({})

function modifier_lua_mana_void_stunned:CheckState()
    local state = {[MODIFIER_STATE_STUNNED] = true}
    return state  
end

function modifier_lua_mana_void_stunned:IsPurgable() return false end
function modifier_lua_mana_void_stunned:IsPurgeException() return true end
function modifier_lua_mana_void_stunned:IsStunDebuff() return true end
function modifier_lua_mana_void_stunned:IsHidden() return false end
function modifier_lua_mana_void_stunned:GetEffectName() return "particles/generic_gameplay/generic_stunned.vpcf" end
function modifier_lua_mana_void_stunned:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end
function modifier_lua_mana_void_stunned:DeclareFunctions()
    local decFuncs = {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}

    return decFuncs
end

function modifier_lua_mana_void_stunned:GetOverrideAnimation()
    return ACT_DOTA_DISABLED
end