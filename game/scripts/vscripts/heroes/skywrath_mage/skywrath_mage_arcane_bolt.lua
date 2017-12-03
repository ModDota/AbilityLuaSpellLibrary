-- Author: Shush
-- Date: 2/12/2017

-- This adds a utility function for Skywrath Mage's scepter effects.
-- Used by invoking the SkywrathSpellsTargetFinder function from it.
require("heroes/skywrath_mage/skywrath_mage_target_finder")

------------------------------------
--   Skywrath Mage's Arcane Bolt  --
------------------------------------
lua_skywrath_mage_arcane_bolt = class({})

function lua_skywrath_mage_arcane_bolt:GetAbilityTextureName()
   return "skywrath_mage_arcane_bolt"
end

function lua_skywrath_mage_arcane_bolt:OnSpellStart()
    -- Ability properties
    local caster = self:GetCaster()
    local ability = self
    local target = self:GetCursorTarget()    
    local scepter = caster:HasScepter()
    local sound_cast = "Hero_SkywrathMage.ArcaneBolt.Cast"

    -- Ability specials    
    local scepter_radius = ability:GetSpecialValueFor("scepter_radius")      

    -- Emit sound
    EmitSoundOn(sound_cast, caster)
    
    -- Fire primary bolt
    self:FireArcaneBolt(target)

    -- Scepter: fires a secondary bolt at a random target. Prioritizes heroes/illusions of them.
    if scepter then        
        local scepter_target = SkywrathSpellsTargetFinder(caster, target, scepter_radius)
        if scepter_target then
            self:FireArcaneBolt(scepter_target)
        end         
    end
end

function lua_skywrath_mage_arcane_bolt:FireArcaneBolt(target)
    -- Ability properties
    local caster = self:GetCaster()
    local ability = self
    local particle_projectile = "particles/units/heroes/hero_skywrath_mage/skywrath_mage_arcane_bolt.vpcf"

    -- Ability specials
    local bolt_speed = ability:GetSpecialValueFor("bolt_speed")
    local bolt_vision = ability:GetSpecialValueFor("bolt_vision")

    -- Get caster's intelligence, if it is a hero (units are dumb)
    local intelligence = 0
    if caster:IsHero() then
        intelligence = caster:GetIntellect()
    end

    -- Fire projectile at target
    local arcane_bolt_projectile
    arcane_bolt_projectile = {Target = target,
                              Source = caster,
                              Ability = ability,
                              EffectName = particle_projectile,
                              iMoveSpeed = bolt_speed,
                              bDodgeable = false, 
                              bVisibleToEnemies = true,
                              bReplaceExisting = false,
                              bProvidesVision = true,
                              iVisionRadius = bolt_vision,
                              iVisionTeamNumber = caster:GetTeamNumber(),
                              ExtraData = {int = intelligence}
                              }

    ProjectileManager:CreateTrackingProjectile(arcane_bolt_projectile)
end

function lua_skywrath_mage_arcane_bolt:OnProjectileHit_ExtraData(target, location, extra_data)
    -- Ability properties
    local caster = self:GetCaster()
    local ability = self
    local sound_impact = "Hero_SkywrathMage.ArcaneBolt.Impact"    

    -- Ability specials
    local bolt_damage = ability:GetSpecialValueFor("bolt_damage")
    local int_multiplier = ability:GetSpecialValueFor("int_multiplier")
    local vision_duration  = ability:GetSpecialValueFor("vision_duration")
    local bolt_vision = ability:GetSpecialValueFor("bolt_vision")

    -- Extra data
    local caster_int = extra_data.int

    -- If there was no target, do nothing
    if not target then
        return nil
    end

    -- If the target became magic immune, do nothing
    if target:IsMagicImmune() then
        return nil
    end

    -- If target has Linken's Sphere off cooldown, do nothing
    if target:GetTeam() ~= caster:GetTeam() then
        if target:TriggerSpellAbsorb(ability) then
            return nil
        end
    end

    -- Play sound
    EmitSoundOn(sound_impact, target)

    -- Add flying vision in the impact area
    AddFOWViewer(caster:GetTeamNumber(),
                 location,
                 bolt_vision,
                 vision_duration,
                 false)

    -- Calculate damage
    local damage = bolt_damage + caster_int * int_multiplier

    -- Deal damage to target
    local damageTable = {victim = target,
                         attacker = caster, 
                         damage = damage,
                         damage_type = DAMAGE_TYPE_MAGICAL,
                         ability = ability
                         }
        
    ApplyDamage(damageTable)
end