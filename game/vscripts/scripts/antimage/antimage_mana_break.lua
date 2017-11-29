-- Author: Shush
-- Date: 25/11/2017

-------------------------------
--   Anti Mage's Mana Break  --
-------------------------------

lua_antimage_mana_break = class({})
LinkLuaModifier("modifier_lua_antimage_mana_break", "antimage/antimage_mana_break", LUA_MODIFIER_MOTION_NONE)

function lua_antimage_mana_break:GetIntrinsicModifierName()
    return "modifier_lua_antimage_mana_break"
end

function lua_antimage_mana_break:GetAbilityTextureName()
   return "antimage_mana_break"
end


modifier_lua_antimage_mana_break = class({})

function modifier_lua_antimage_mana_break:IsHidden() return true end
function modifier_lua_antimage_mana_break:IsPurgable() return false end
function modifier_lua_antimage_mana_break:IsDebuff() return false end
function modifier_lua_antimage_mana_break:RemoveOnDeath() return false end

function modifier_lua_antimage_mana_break:OnCreated()
    -- Ability properties
    self.caster = self:GetCaster()
    self.ability = self:GetAbility()
    self.hit_sound = "Hero_Antimage.ManaBreak"
    self.particle_manaburn = "particles/generic_gameplay/generic_manaburn.vpcf"

    -- Ability specials
    self.damage_per_burn = self.ability:GetSpecialValueFor("damage_per_burn")
    self.mana_per_hit = self.ability:GetSpecialValueFor("mana_per_hit")
end

function modifier_lua_antimage_mana_break:OnRefresh()
    self:OnCreated()
end

function modifier_lua_antimage_mana_break:DeclareFunctions()
    local decFuncs = {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE_PROC}

    return decFuncs
end

function modifier_lua_antimage_mana_break:GetModifierPreAttack_BonusDamage_Proc(keys)
    local target = keys.target
    local attacker = keys.attacker

    -- If the attacker wasn't the caster, do nothing
    if not attacker == self.caster then
        return nil
    end

    --  If the attacker has Break, do nothing
    if attacker:PassivesDisabled() then
        return nil
    end

    -- If the target doesn't have a mana pool, do nothing
    if target:GetMaxMana() == 0 then
        return nil
    end

    -- If the target is a building or a ward, do nothing
    if target:IsBuilding() or target:IsOther() then
        return nil
    end

    -- If we got here, this means Anti Mage has landed a successful attack that mana burns!
    -- Play sound
    EmitSoundOn(self.hit_sound, target)

    -- Play particle effects
    local manaburn_pfx = ParticleManager:CreateParticle(self.particle_manaburn, PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControl(manaburn_pfx, 0, target:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex(manaburn_pfx)

    -- Calculate mana before the burn
    local target_mana = target:GetMana()
    local mana_burn = self.mana_per_hit

    -- If the target has less mana than the mana that will be burned, set the mana to be burned accordingly
    -- This is done to apply correct damage based on actual mana burned
    if self.mana_per_hit > target_mana then
        mana_burn = target_mana
    end

    -- Calculate burn damage
    local damage = mana_burn * self.damage_per_burn

    -- Reduce target mana
    target:ReduceMana(mana_burn)    
end






