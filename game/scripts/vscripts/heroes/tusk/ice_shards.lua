---@class tusk_ice_shards_lua : CDOTA_Ability_Lua
tusk_ice_shards_lua = class({})

--- This does not display the reduced cooldown on the client, if you really want this use modifier with stacks to sync this.
---@override
function tusk_ice_shards_lua:GetCooldown(iLevel)
  if IsServer()then
    local talent = self:GetCaster():FindAbilityByName("special_bonus_unique_tusk_5_lua")
    local reduction
    if talent then
      reduction = talent:GetSpecialValueFor("value")
    end
    return self.BaseClass.GetCooldown(self, iLevel) - reduction
  end
  return self.BaseClass.GetCooldown(self, iLevel)
end

---@override
function tusk_ice_shards_lua:OnSpellStart()
  local caster = self:GetCaster()
  local point = self:GetCursorPosition()
  local length = (point-caster:GetAbsOrigin()):Length2D() - self:GetSpecialValueFor("shard_distance")
  local direction = (point-caster:GetAbsOrigin()):Normalized()
  direction.z = 0
  -- Store this to decide in which way the arc goes
  self.direction = direction
  -- Create a dummy to block creep spawns
  self.dummy = CreateUnitByName("npc_dota_units_base",caster:GetAbsOrigin(),false,nil,nil,caster:GetTeamNumber())
  self.dummy:AddNewModifier(caster,self,"modifier_tusk_ice_shards_dummy",{})
  local projectile_table = {
    Ability = self,
    EffectName = "particles/units/heroes/hero_tusk/tusk_ice_shards_projectile.vpcf",
    vSpawnOrigin = caster:GetAbsOrigin(),
    fDistance = length,
    fStartRadius = self:GetSpecialValueFor("shard_width"),
    fEndRadius = self:GetSpecialValueFor("shard_width"),
    Source = caster,
    bHasFrontalCone = false,
    bReplaceExisting = false,
    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
    iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    fExpireTime = GameRules:GetGameTime() + 3,
    bDeleteOnHit = false,
    vVelocity = direction * self:GetSpecialValueFor("shard_speed"),
    bProvidesVision = true,
    iVisionRadius = self:GetSpecialValueFor("shard_width"),
    iVisionTeamNumber = caster:GetTeamNumber()
  }
  ProjectileManager:CreateLinearProjectile(projectile_table)

  caster:EmitSound("Hero_Tusk.IceShards.Projectile")
end
---@override
function tusk_ice_shards_lua:OnProjectileThink(vLocation)
  self.dummy:SetAbsOrigin(vLocation)
end
---@override
function tusk_ice_shards_lua:OnProjectileHit(hTarget, vLocation)
  if hTarget then
    local damage_table = {
      victim = hTarget,
      attacker = self:GetCaster(),
      ability = self,
      damage = self:GetSpecialValueFor("shard_damage"),
      damage_type = self:GetAbilityDamageType(),
    }
    ApplyDamage(damage_table  )
  else
    self:GetCaster():StopSound("Hero_Tusk.IceShards.Projectile")
    self:GetCaster():EmitSound("Hero_Tusk.IceShards")
    UTIL_Remove(self.dummy)
    local shard_distance = self:GetSpecialValueFor("shard_distance")
    local shard_angle_step = self:GetSpecialValueFor("shard_angle_step")
    self.shards = {}
    self.blockers = {}
    -- 7 shards, from -120 to 120
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_tusk/tusk_ice_shards.vpcf",PATTACH_WORLDORIGIN,self:GetCaster())
    ParticleManager:SetParticleControl(particle,0,Vector(self:GetSpecialValueFor("shard_duration"),0,0))
    for i=0,6 do
      local angle = -120 + i * shard_angle_step
      local direction = RotatePosition(Vector(0,0,0), QAngle(0,angle,0), self.direction)
      local position = GetGroundPosition(vLocation + direction * shard_distance,nil)
      self.blockers[i] = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin = position})
      -- Using a particle for this is easier and looks better
      --[[self.shards[i] = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/particle/ice_shards.vmdl", DefaultAnim=animation, targetname=DoUniqueString("prop_dynamic")})
      self.shards[i]:SetAbsOrigin(position)
      self.shards[i]:SetForwardVector(vLocation-position)
      self.shards[i]:SetModelScale(15)]]
      ParticleManager:SetParticleControl(particle,i+1,position)
    end

    self:SetContextThink("think_duration",function() self:RemoveShards() end,self:GetSpecialValueFor("shard_duration"))
  end
end

function tusk_ice_shards_lua:RemoveShards()
  for i=0,6 do
    UTIL_Remove(self.blockers[i])
  end
  self.blockers = nil
end


LinkLuaModifier("modifier_tusk_ice_shards_dummy","heroes/tusk/ice_shards.lua",LUA_MODIFIER_MOTION_NONE)
---@class modifier_tusk_ice_shards_dummy : CDOTA_Modifier_Lua
modifier_tusk_ice_shards_dummy = class({})
---@override
function modifier_tusk_ice_shards_dummy:IsPermanent() return true end
---@return table
function modifier_tusk_ice_shards_dummy:CheckState()
  return {
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
  }
end