-- Author: Shush
-- Date: 25/11/2017

-------------------------------
--  Anti Mage's Spell Shield --
-------------------------------

lua_antimage_spell_shield = class({})
LinkLuaModifier("modifier_lua_antimage_spell_shield", "antimage/antimage_spell_shield", LUA_MODIFIER_MOTION_NONE)

function lua_antimage_spell_shield:GetIntrinsicModifierName()
    return "modifier_lua_antimage_spell_shield"
end

function lua_antimage_spell_shield:GetAbilityTextureName()
   return "antimage_spell_shield"
end

modifier_lua_antimage_spell_shield = class({})

function modifier_lua_antimage_spell_shield:OnCreated()
    -- Ability properties
    self.caster = self:GetCaster()
    self.ability = self:GetAbility()

    -- Ability specials
    self.spell_shield_resistance = self.ability:GetSpecialValueFor("spell_shield_resistance")
    self.scepter_cooldown = self.ability:GetSpecialValueFor("scepter_cooldown")
end

function modifier_lua_antimage_spell_shield:OnRefresh()
    self:OnCreated()
end

function modifier_lua_antimage_spell_shield:DeclareFunctions()
    local decFuncs = {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS}

    return decFuncs
end

function modifier_lua_antimage_spell_shield:GetModifierMagicalResistanceBonus()
    return self.spell_shield_resistance
end