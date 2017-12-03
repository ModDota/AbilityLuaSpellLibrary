-- Author: Shush
-- Date: 2/12/2017

-- This adds a utility function for Skywrath Mage's scepter effects.
-- Used by invoking the SkywrathSpellsTargetFinder function from it.
require("heroes/skywrath_mage/skywrath_mage_target_finder")

------------------------------------
--   Skywrath Mage's Arcane Seal  --
------------------------------------
lua_skywrath_mage_ancient_seal = class({})
LinkLuaModifier("modifier_lua_arcane_seal_debuff", "heroes/skywrath_mage/skywrath_mage_arcane_seal", LUA_MODIFIER_MOTION_NONE)

function lua_skywrath_mage_ancient_seal:GetAbilityTextureName()
   return "skywrath_mage_ancient_seal"
end

function lua_skywrath_mage_ancient_seal:OnSpellStart()
    -- Ability properties
    local caster = self:GetCaster()
    local ability = self
    local target = self:GetCursorTarget()
    local sound_cast = "Hero_SkywrathMage.AncientSeal.Target"    
    local modifier_seal = "modifier_lua_arcane_seal_debuff"
    local scepter = caster:HasScepter()

    -- Ability specials 
    local seal_duration = ability:GetSpecialValueFor("seal_duration") 
    local scepter_radius = ability:GetSpecialValueFor("scepter_radius")

    -- Play sound
    EmitSoundOn(sound_cast, target)

    -- Scepter: apply seal on a random enemy. Prioritizes enemies/illusions.
    if scepter then
        local scepter_target = SkywrathSpellsTargetFinder(caster, target, scepter_radius)
        if scepter_target then
            scepter_target:AddNewModifier(caster, ability, modifier_seal, {duration = seal_duration})
        end    
    end

    -- If target has Linken's Sphere off cooldown, do nothing
    if target:GetTeam() ~= caster:GetTeam() then
        if target:TriggerSpellAbsorb(ability) then
            return nil
        end
    end

    -- Apply seal on target
    target:AddNewModifier(caster, ability, modifier_seal, {duration = seal_duration})    
end



-- Modifier: Ancient Seal debuff (magic resistance penalty and silence)
modifier_lua_arcane_seal_debuff = class({})

function modifier_lua_arcane_seal_debuff:IsHidden() return false end
function modifier_lua_arcane_seal_debuff:IsPurgable() return true end
function modifier_lua_arcane_seal_debuff:IsDebuff() return true end

function modifier_lua_arcane_seal_debuff:OnCreated()
    -- Ability properties
    self.caster = self:GetCaster()
    self.ability = self:GetAbility()    
    self.parent = self:GetParent()
    self.particle_seal = "particles/units/heroes/hero_skywrath_mage/skywrath_mage_ancient_seal_debuff.vpcf"

    -- Ability specials
    self.resist_debuff = self.ability:GetSpecialValueFor("resist_debuff")

    -- Apply seal particle
    self.particle_seal_fx = ParticleManager:CreateParticle(self.particle_seal, PATTACH_OVERHEAD_FOLLOW, self.parent)
    ParticleManager:SetParticleControlEnt(self.particle_seal_fx, 1, self.parent, PATTACH_ABSORIGIN_FOLLOW, "attach_origin", self.parent:GetAbsOrigin(), true)
    self:AddParticle(self.particle_seal_fx, false, false, -1 , false, true)
end

function modifier_lua_arcane_seal_debuff:OnRefresh()
    -- Update values
    self.resist_debuff = self.ability:GetSpecialValueFor("resist_debuff")
end

function modifier_lua_arcane_seal_debuff:DeclareFunctions()
    local decFuncs = {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS}

    return decFuncs
end

function modifier_lua_arcane_seal_debuff:GetModifierMagicalResistanceBonus()
    return self.resist_debuff
end

function modifier_lua_arcane_seal_debuff:CheckState() 
    local state = {[MODIFIER_STATE_SILENCED] = true}
    return state
end