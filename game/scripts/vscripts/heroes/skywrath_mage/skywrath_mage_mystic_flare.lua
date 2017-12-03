-- Author: Shush
-- Date: 2/12/2017

-- This adds a utility function for Skywrath Mage's scepter effects.
-- Used by invoking the SkywrathSpellsPositionFinder function from it. 
-- Note that this is a different function from the rest of the spells.
require("heroes/skywrath_mage/skywrath_mage_target_finder")

------------------------------------
--   Skywrath Mage's Mystic Flare --
------------------------------------
lua_skywrath_mage_mystic_flare = class({})
LinkLuaModifier("modifier_lua_mystic_flare", "heroes/skywrath_mage/skywrath_mage_mystic_flare", LUA_MODIFIER_MOTION_NONE)

function lua_skywrath_mage_mystic_flare:GetAbilityTextureName()
   return "skywrath_mage_mystic_flare"
end

function lua_skywrath_mage_mystic_flare:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function lua_skywrath_mage_mystic_flare:OnSpellStart()
    -- Ability properties
    local caster = self:GetCaster()
    local ability = self
    local target_point = self:GetCursorPosition()    
    local modifier_thinker = "modifier_lua_mystic_flare"
    local scepter = caster:HasScepter()

    -- Ability specials 
    local duration = ability:GetSpecialValueFor("duration")
    local radius = ability:GetSpecialValueFor("radius")
    local scepter_radius = ability:GetSpecialValueFor("scepter_radius")

    -- Apply a Mystic Flare on target location
    CreateModifierThinker(caster, ability, modifier_thinker, {duration = duration}, target_point, caster:GetTeamNumber(), false)

    -- Scepter: Fire a secondary Mystic Flare outside of the original flare area
    if scepter then        
        local scepter_target = SkywrathSpellsPositionFinder(caster, target_point, scepter_radius, radius)
        if scepter_target then
            CreateModifierThinker(caster, ability, modifier_thinker, {duration = duration}, scepter_target:GetAbsOrigin(), caster:GetTeamNumber(), false)
        end         
    end
end



-- Modifier: Thinker that is responsible for dealing damage around it
modifier_lua_mystic_flare = class({})

function modifier_lua_mystic_flare:OnCreated()
    -- Ability properties
    self.caster = self:GetCaster()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self.sound_target = "Hero_SkywrathMage.MysticFlare.Target"    
    self.core_particle = "particles/units/heroes/hero_skywrath_mage/skywrath_mage_mystic_flare_ambient.vpcf"
    self.parent_loc = self.parent:GetAbsOrigin()

    -- Ability specials
    self.radius = self.ability:GetSpecialValueFor("radius")
    self.damage = self.ability:GetSpecialValueFor("damage")
    self.damage_interval = self.ability:GetSpecialValueFor("damage_interval")
    self.duration = self.ability:GetSpecialValueFor("duration")

    -- Apply particle effect
    self.core_particle_fx = ParticleManager:CreateParticle(self.core_particle, PATTACH_WORLDORIGIN, nil)        
    ParticleManager:SetParticleControl(self.core_particle_fx, 0 , self.parent_loc)
    ParticleManager:SetParticleControl(self.core_particle_fx, 1, Vector(self.radius, self.duration, 0))
    ParticleManager:ReleaseParticleIndex(self.core_particle_fx)

    -- Start thinking
    self:StartIntervalThink(self.damage_interval)
end

function modifier_lua_mystic_flare:OnIntervalThink()
    if IsServer() then        
        -- Play hit sound
        EmitSoundOn(self.sound_target, self.parent)

        -- Find enemies in radius
        local enemies = FindUnitsInRadius(self.caster:GetTeamNumber(),
                                          self.parent_loc,
                                          nil,
                                          self.radius,
                                          DOTA_UNIT_TARGET_TEAM_ENEMY,
                                          DOTA_UNIT_TARGET_HERO,
                                          DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS,
                                          FIND_ANY_ORDER,
                                          false)

        -- Calculate damage for this instance for all enemies present
        local damage = 0 
        if #enemies > 0 then
            damage = (self.damage / #enemies / self.duration * self.damage_interval)
        end

        -- Deal damage to each hero        
        for _,enemy in pairs (enemies) do            
            local damageTable = {victim = enemy,
                                 attacker = self.caster, 
                                 damage = damage,
                                 damage_type = DAMAGE_TYPE_MAGICAL,
                                 ability = self.ability
                                 }
    
            ApplyDamage(damageTable)              
        end
    end
end






