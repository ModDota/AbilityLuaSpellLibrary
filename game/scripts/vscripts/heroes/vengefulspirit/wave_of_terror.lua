LinkLuaModifier("modifier_vengefulspirit_wave_of_terror_lua", "heroes/vengefulspirit/wave_of_terror", LUA_MODIFIER_MOTION_NONE)

--[[
================================
===== Wave of Terror Effect ====
================================
--]]
---@class modifier_vengefulspirit_wave_of_terror_lua : CDOTA_Modifier_Lua
---@field armor_reduction number
modifier_vengefulspirit_wave_of_terror_lua = class({})

---@override
function modifier_vengefulspirit_wave_of_terror_lua:IsDebuff()
    return true
end

---@override
function modifier_vengefulspirit_wave_of_terror_lua:GetEffectName()
    return "particles/units/heroes/hero_vengeful/vengeful_wave_of_terror_recipient.vpcf"
end

---@override
function modifier_vengefulspirit_wave_of_terror_lua:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

---@override
function modifier_vengefulspirit_wave_of_terror_lua:OnCreated()
    self.armor_reduction = self:GetAbility():GetSpecialValueFor("armor_reduction")
end

---@override
function modifier_vengefulspirit_wave_of_terror_lua:OnRefresh()
    self.armor_reduction = self:GetAbility():GetSpecialValueFor("armor_reduction")
end

---@override
function modifier_vengefulspirit_wave_of_terror_lua:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }
    return funcs
end

---@override
function modifier_vengefulspirit_wave_of_terror_lua:GetModifierPhysicalArmorBonus()
    return self.armor_reduction
end


--[[
===============================
===== Wave of Terror Spell ====
===============================
--]]
---@class vengeful_wave_of_terror : CDOTA_Ability_Lua
---@field wave_speed number
---@field wave_width number
---@field vision_aoe number
---@field vision_duration number
---@field tooltip_duration number
---@field wave_damage number
---@field flVisionTimer number
---@field flLastThinkTime number
---@field nProjID ProjectileID
vengefulspirit_wave_of_terror_lua = class({})

---@override
function vengefulspirit_wave_of_terror_lua:OnSpellStart()
    local vDirection = self:GetCursorPosition() - self:GetCaster():GetOrigin()
    vDirection = vDirection:Normalized()

    self.wave_speed = self:GetSpecialValueFor("wave_speed")
    self.wave_width = self:GetSpecialValueFor("wave_width")
    self.vision_aoe = self:GetSpecialValueFor("vision_aoe")
    self.vision_duration = self:GetSpecialValueFor("vision_duration")
    self.tooltip_duration = self:GetSpecialValueFor("tooltip_duration")
    self.wave_damage = self:GetSpecialValueFor("wave_damage")

    local info = {
        EffectName = "particles/units/heroes/hero_vengeful/vengeful_wave_of_terror.vpcf",
        Ability = self,
        vSpawnOrigin = self:GetCaster():GetOrigin(), 
        fStartRadius = self.wave_width,
        fEndRadius = self.wave_width,
        vVelocity = vDirection * self.wave_speed,
        fDistance = self:GetCastRange(self:GetCaster():GetOrigin(), self:GetCaster()),
        Source = self:GetCaster(),
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        bProvidesVision = true,
        iVisionTeamNumber = self:GetCaster():GetTeamNumber(),
        iVisionRadius = self.vision_aoe
    }

    self.flVisionTimer = self.wave_width / self.wave_speed
    self.flLastThinkTime = GameRules:GetGameTime()
    self.nProjID = ProjectileManager:CreateLinearProjectile(info)
    EmitSoundOn("Hero_VengefulSpirit.WaveOfTerror" , self:GetCaster())
end

---@override
function vengefulspirit_wave_of_terror_lua:OnProjectileThink(vLocation)
    self.flVisionTimer = self.flVisionTimer - (GameRules:GetGameTime() - self.flLastThinkTime)

    if self.flVisionTimer <= 0.0 then
        local vVelocity = ProjectileManager:GetLinearProjectileVelocity(self.nProjID)
        AddFOWViewer(self:GetCaster():GetTeamNumber(), vLocation + vVelocity * ( self.wave_width / self.wave_speed ), self.vision_aoe, self.vision_duration, false)
        self.flVisionTimer = self.wave_width / self.wave_speed
    end
end

---@override
function vengefulspirit_wave_of_terror_lua:OnProjectileHit(hTarget, vLocation)
    if hTarget ~= nil then
        local damage = {
            victim = hTarget,
            attacker = self:GetCaster(),
            damage = self.wave_damage,
            damage_type = DAMAGE_TYPE_PURE,
            ability = self
        }

        ApplyDamage(damage) --TODO: Type annotate ApplyDamage to take table not handle

        --TODO: Figure out why IntelliJ is convinced AddNewModifier does not exist
        hTarget:AddNewModifier(self:GetCaster(), self, "modifier_vengefulspirit_wave_of_terror_lua", { duration = self.tooltip_duration })
    end

    return false
end