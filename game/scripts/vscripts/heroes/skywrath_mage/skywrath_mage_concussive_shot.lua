-- Author: Shush
-- Date: 2/12/2017

require("heroes/skywrath_mage/skywrath_mage_target_finder")

----------------------------------------
--   Skywrath Mage's Concussive Shot  --
----------------------------------------
lua_skywrath_mage_concussive_shot = class({})
LinkLuaModifier("modifier_lua_concussive_shot_slow", "heroes/skywrath_mage/skywrath_mage_concussive_shot", LUA_MODIFIER_MOTION_NONE)

function lua_skywrath_mage_concussive_shot:GetAbilityTextureName()
   return "skywrath_mage_concussive_shot"
end

function lua_skywrath_mage_concussive_shot:OnSpellStart()
    -- Ability properties
    local caster = self:GetCaster()
    local ability = self
    local sound_cast = "Hero_SkywrathMage.ConcussiveShot.Cast"    
    local particle_fail = "particles/units/heroes/hero_skywrath_mage/skywrath_mage_concussive_shot_failure.vpcf"    
    local scepter = caster:HasScepter()

    -- Ability specials
    local launch_radius = ability:GetSpecialValueFor("launch_radius")
    local scepter_radius = ability:GetSpecialValueFor("scepter_radius")

    -- Play cast sound
    EmitSoundOn(sound_cast, caster)

    -- Find the closest valid enemy to shot the projectile on
    local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
                                      caster:GetAbsOrigin(),
                                      nil,
                                      launch_radius,
                                      DOTA_UNIT_TARGET_TEAM_ENEMY,
                                      DOTA_UNIT_TARGET_HERO,
                                      DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS,
                                      FIND_CLOSEST,
                                      false)

    -- If no enemies was found, add fizzle effect and exit
    if #enemies == 0 then
        local particle_fail_fx = ParticleManager:CreateParticle(particle_fail, PATTACH_ABSORIGIN, caster)
        ParticleManager:SetParticleControl(particle_fail_fx, 0, caster:GetAbsOrigin())
        ParticleManager:SetParticleControl(particle_fail_fx, 1, caster:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(particle_fail_fx)

        return nil
    end

    -- Fire projectile
    self:FireConcussiveShot(enemies[1])

    -- Scepter: fire another Concussive Shot at a random enemy. Prioritizes enemies/illusions.
    if scepter then
        local scepter_target = SkywrathSpellsTargetFinder(caster, enemies[1], scepter_radius)
        if scepter_target then
            self:FireConcussiveShot(scepter_target)
        end         
    end
end


function lua_skywrath_mage_concussive_shot:FireConcussiveShot(target)    
    -- Ability properties
    local caster = self:GetCaster()
    local ability = self
    local particle_projectile = "particles/units/heroes/hero_skywrath_mage/skywrath_mage_concussive_shot.vpcf"

    -- Ability specials    
    local speed = ability:GetSpecialValueFor("speed")
    local shot_vision = ability:GetSpecialValueFor("shot_vision")    

    -- Define and launch projectile
    local concussive_projectile
    concussive_projectile = {Target = target,
                              Source = caster,
                              Ability = ability,
                              EffectName = particle_projectile,
                              iMoveSpeed = speed,
                              bDodgeable = true, 
                              bVisibleToEnemies = true,
                              bReplaceExisting = false,
                              bProvidesVision = true,
                              iVisionRadius = shot_vision,
                              iVisionTeamNumber = caster:GetTeamNumber()                            
                            }

    ProjectileManager:CreateTrackingProjectile(concussive_projectile)  
end


function lua_skywrath_mage_concussive_shot:OnProjectileHit(target, location)    
    -- If there was no target, do nothing
    if not target then
        return nil
    end

    -- Ability properties
    local caster = self:GetCaster()
    local ability = self
    local sound_impact = "Hero_SkywrathMage.ConcussiveShot.Target"    
    local modifier_slow = "modifier_lua_concussive_shot_slow"

    -- Ability specials
    local slow_radius = ability:GetSpecialValueFor("slow_radius")
    local damage = ability:GetSpecialValueFor("damage")
    local slow_duration = ability:GetSpecialValueFor("slow_duration")
    local shot_vision = ability:GetSpecialValueFor("shot_vision")
    local vision_duration = ability:GetSpecialValueFor("vision_duration")

    -- Add FOW Viewer
    AddFOWViewer(caster:GetTeamNumber(),
                 location,
                 shot_vision,
                 vision_duration,
                 false)    

    -- Play impact sound
    EmitSoundOn(sound_impact, caster)

    -- Find enemies around the impact area
    local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
                                      target:GetAbsOrigin(),
                                      nil,
                                      slow_radius,
                                      DOTA_UNIT_TARGET_TEAM_ENEMY,
                                      DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                                      DOTA_UNIT_TARGET_FLAG_NONE,
                                      FIND_ANY_ORDER,
                                      false)
    
    -- For each enemy, only apply if the enemy is not magic immune
    for _,enemy in pairs(enemies) do
        if not enemy:IsMagicImmune() then
            -- Deal damage
            local damageTable = {victim = enemy,
                                 attacker = caster, 
                                 damage = damage,
                                 damage_type = DAMAGE_TYPE_MAGICAL,
                                 ability = ability
                                 }
        
            ApplyDamage(damageTable)  

            -- Apply/Refresh slow debuff
            enemy:AddNewModifier(caster, ability, modifier_slow, {duration = slow_duration})
        end
    end  
end



-- Modifier: Concussive Shot slow
modifier_lua_concussive_shot_slow = class({})

function modifier_lua_concussive_shot_slow:IsHidden() return false end
function modifier_lua_concussive_shot_slow:IsPurgable() return true end
function modifier_lua_concussive_shot_slow:IsDebuff() return true end

function modifier_lua_concussive_shot_slow:OnCreated()
    -- Ability properties
    self.ability = self:GetAbility()

    -- Ability specials
    self.movement_speed_pct = self.ability:GetSpecialValueFor("movement_speed_pct")
end

function modifier_lua_concussive_shot_slow:OnRefresh()
    -- Update values
    self.movement_speed_pct = self.ability:GetSpecialValueFor("movement_speed_pct") 
end

function modifier_lua_concussive_shot_slow:DeclareFunctions()
    local decFuncs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}    

    return decFuncs
end    

function modifier_lua_concussive_shot_slow:GetModifierMoveSpeedBonus_Percentage()
    return self.movement_speed_pct * (-1)
end

function modifier_lua_concussive_shot_slow:GetEffectName()
    return "particles/units/heroes/hero_skywrath_mage/skywrath_mage_concussive_shot_slow_debuff.vpcf"
end

function modifier_lua_concussive_shot_slow:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end



    