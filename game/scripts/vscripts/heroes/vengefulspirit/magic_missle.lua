LinkLuaModifier("modifier_vengefulspirit_magic_missile_lua", "heroes/vengefulspirit/magic_missle", LUA_MODIFIER_MOTION_NONE)

--[[
==============================
===== Magic Missle Effect ====
==============================
--]]
---@class modifier_vengefulspirit_magic_missile_lua : CDOTA_Modifier_Lua
modifier_vengefulspirit_magic_missile_lua = class({})

---@override
function modifier_vengefulspirit_magic_missile_lua:IsDebuff()
    return true
end

---@override
function modifier_vengefulspirit_magic_missile_lua:IsStunDebuff()
    return true
end

---@override
function modifier_vengefulspirit_magic_missile_lua:GetEffectName()
    return "particles/generic_gameplay/generic_stunned.vpcf"
end

---@override
function modifier_vengefulspirit_magic_missile_lua:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

---@override
function modifier_vengefulspirit_magic_missile_lua:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
    }

    return funcs
end

---@override
function modifier_vengefulspirit_magic_missile_lua:GetOverrideAnimation()
    return ACT_DOTA_DISABLED
end

---@override
function modifier_vengefulspirit_magic_missile_lua:CheckState()
    local state = {
        [MODIFIER_STATE_STUNNED] = true,
    }

    return state
end

--[[
=============================
===== Magic Missle Spell ====
=============================
--]]
---@class vengefulspirit_magic_missile_lua : CDOTA_Ability_Lua
vengefulspirit_magic_missile_lua = class({})


---@override
function vengefulspirit_magic_missile_lua:OnSpellStart()
    local info = {
        EffectName = "particles/units/heroes/hero_vengeful/vengeful_magic_missle.vpcf",
        Ability = self,
        iMoveSpeed = self:GetSpecialValueFor("magic_missile_speed"),
        Source = self:GetCaster(),
        Target = self:GetCursorTarget(),
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2
    }

    ProjectileManager:CreateTrackingProjectile(info)
    EmitSoundOn("Hero_VengefulSpirit.MagicMissile", self:GetCaster())
end

---@override
function vengefulspirit_magic_missile_lua:OnProjectileHit(hTarget, vLocation)
    if hTarget ~= nil and (not hTarget:IsInvulnerable()) and (not hTarget:TriggerSpellAbsorb(self)) and (not hTarget:IsMagicImmune()) then
        EmitSoundOn("Hero_VengefulSpirit.MagicMissileImpact", hTarget)
        local magic_missile_stun = self:GetSpecialValueFor("magic_missile_stun")
        local magic_missile_damage = self:GetSpecialValueFor("magic_missile_damage")

        local damage = {
            victim = hTarget,
            attacker = self:GetCaster(),
            damage = magic_missile_damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self
        }

        ApplyDamage(damage) --TODO: Type annotate ApplyDamage to take table not handle
        --TODO: Figure out why IntelliJ is convinced AddNewModifier does not exist
        hTarget:AddNewModifier(self:GetCaster(), self, "modifier_vengefulspirit_magic_missile_lua", { duration = magic_missile_stun })
    end

    return true
end