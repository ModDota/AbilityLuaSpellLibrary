-- Author: Shush
-- Date: 25/11/2017

-------------------------------
--   Anti Mage's Blink  --
-------------------------------

lua_antimage_blink = class({})

function lua_antimage_blink:GetAbilityTextureName()
   return "antimage_blink"
end

function lua_antimage_blink:OnSpellStart()
    -- Ability properties
    local caster = self:GetCaster()
    local ability = self
    local target_point = ability:GetCursorPosition()
    local blink_out_sound = "Hero_Antimage.Blink_out"
    local blink_in_sound = "Hero_Antimage.Blink_in"
    local particle_blink_start = "particles/units/heroes/hero_antimage/antimage_blink_start.vpcf"
    local particle_blink_end = "particles/units/heroes/hero_antimage/antimage_blink_end.vpcf"

    -- Ability specials
    local blink_range = ability:GetSpecialValueFor("blink_range")    

    -- Get blink distance
    local blink_distance = (target_point - caster:GetAbsOrigin()):Length2D()
    local direction = (target_point - caster:GetAbsOrigin()):Normalized()    

    -- Maximum blink distance
    if blink_distance > blink_range then
        blink_distance = blink_range
    end

    -- Blink particles on starting point
    local blink_pfx = ParticleManager:CreateParticle(particle_blink_start, PATTACH_ABSORIGIN, caster)
    ParticleManager:ReleaseParticleIndex(blink_pfx)        

    -- Blink sound on starting point
    EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), blink_out_sound, caster)

    Timers:CreateTimer(FrameTime(), function()

        -- Calculate location to move to
        local blink_point = caster:GetAbsOrigin() + direction * blink_distance

        -- Disjoint projectiles
        ProjectileManager:ProjectileDodge(caster)

        -- Move hero    
        FindClearSpaceForUnit(caster, blink_point, true)    
        
        -- Create Particle on end-point
        local blink_end_pfx = ParticleManager:CreateParticle(particle_blink_end, PATTACH_ABSORIGIN, caster)
        ParticleManager:ReleaseParticleIndex(blink_end_pfx)    

        -- Blink sound on end point
        EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), blink_out_sound, caster)    
    end)
end