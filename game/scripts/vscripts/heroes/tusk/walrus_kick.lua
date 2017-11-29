LinkLuaModifier("modifier_tusk_walrus_kick_flying","heroes/tusk/walrus_kick.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tusk_walrus_kick_slow","heroes/tusk/walrus_kick.lua",LUA_MODIFIER_MOTION_NONE)
-- This modifier does not yet use a motion controller! It should start using some system to prevent conflicts
---@class modifier_tusk_walrus_kick_flying : CDOTA_Modifier_Lua
modifier_tusk_walrus_kick_flying = class({})

---@override
function modifier_tusk_walrus_kick_flying:CheckState()
  return {
    [MODIFIER_STATE_STUNNED] = IsServer(), -- Not showing the status bar
  }
end

---@override
function modifier_tusk_walrus_kick_flying:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }
end

---@override
function modifier_tusk_walrus_kick_flying:GetOverrideAnimation()
  return ACT_DOTA_FLAIL
end

---@override
function modifier_tusk_walrus_kick_flying:OnCreated(keys)
  if IsServer() then
    self.push_length = self:GetAbility():GetSpecialValueFor("push_length")
    self.air_time_duration = self:GetAbility():GetSpecialValueFor("air_time")

    self.push_speed = self.push_length/self.air_time_duration
    local max_height = 360
    -- The height that needs to be gained when the unit moves 1 unit.
    self.z_vel = (max_height/self.air_time_duration) *4
    self.direction = Vector(keys.dir_x*self.push_speed,keys.dir_y*self.push_speed,self.z_vel)

    self:StartIntervalThink(FrameTime())
  end
end

---@override
function modifier_tusk_walrus_kick_flying:OnIntervalThink()
  local unit = self:GetParent()
  -- Decrease the z velocity
  self.direction.z = self.direction.z - (self.z_vel *2  *FrameTime())
  unit:SetAbsOrigin(unit:GetAbsOrigin() + self.direction *  FrameTime())
end

---@override
function modifier_tusk_walrus_kick_flying:OnDestroy()
  if IsServer() then
    -- Make sure the unit ends on the ground
    -- Don't think this is needed though, the engine sets unit to ground level on movement
    FindClearSpaceForUnit(self:GetParent(),self:GetParent():GetAbsOrigin(),true)
  end
end


---@class modifier_tusk_walrus_kick_slow : CDOTA_Modifier_Lua
modifier_tusk_walrus_kick_slow = class({})

---@override
function modifier_tusk_walrus_kick_slow:OnCreated()
  self.slow = self:GetAbility():GetSpecialValueFor("move_slow")
end

---@override
function modifier_tusk_walrus_kick_slow:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
  }
end

---@override
function modifier_tusk_walrus_kick_slow:GetModifierMoveSpeedBonus_Percentage()
  return self.slow
end

-- Particle effect
---@override
function modifier_tusk_walrus_kick_slow:GetStatusEffectName()
  return "particles/units/heroes/hero_tusk/tusk_walruspunch_status.vpcf"
end

---@class tusk_walrus_kick_lua : CDOTA_Ability_Lua
tusk_walrus_kick_lua = class({})

---@override
function tusk_walrus_kick_lua:OnInventoryContentsChanged()
  self:SetHidden(not self:GetCaster():HasScepter())
  -- Find the scepter and make it undroppable
  for i=DOTA_ITEM_SLOT_1,DOTA_ITEM_SLOT_6 do
    local item =  self:GetCaster():GetItemInSlot(i)
    if item then
      item:SetDroppable(false)
      item:SetSellable(false)
      item:SetCanBeUsedOutOfInventory(false ) -- Would this prevent it from going in backpack?
    end
  end

  self:SetLevel(1)
end
---@override
function tusk_walrus_kick_lua:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()
  local direction = caster:GetForwardVector()
  local air_time_duration = self:GetSpecialValueFor("air_time")
  local duration = self:GetSpecialValueFor("slow_duration")
  local damage = self:GetSpecialValueFor("damage")
  local damage_type = self:GetAbilityDamageType()

  local damage_table = {
    ability = self,
    attacker = caster,
    victim = target,
    damage = damage,
    damage_type = damage_type,
  }

  ApplyDamage(damage_table)

  target:AddNewModifier(caster,self,"modifier_tusk_walrus_kick_flying",{duration = air_time_duration,dir_x = direction.x,dir_y=direction.y})
  target:AddNewModifier(caster,self,"modifier_tusk_walrus_kick_slow",{duration = duration})

  -- Text particles
  local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_tusk/tusk_walruskick_txt_ult.vpcf", PATTACH_ABSORIGIN, caster)
  ParticleManager:SetParticleControl(particle, 2, caster:GetAbsOrigin()+Vector(0,0,175))
  ParticleManager:ReleaseParticleIndex(particle)
  caster:EmitSound("Hero_Tusk.WalrusKick.Target")
end