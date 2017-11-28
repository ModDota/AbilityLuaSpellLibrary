---@class tusk_snowball_lua : CDOTA_Ability_Lua
tusk_snowball_lua = class({})
---@override
function tusk_snowball_lua:OnUpgrade()
  self:GetCaster():FindAbilityByName(self:GetAssociatedPrimaryAbilities()):SetLevel(self:GetLevel())
end

---@override
function tusk_snowball_lua:GetAssociatedPrimaryAbilities()
 return "tusk_snowball_release_lua"
end

---@override
function tusk_snowball_lua:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()
  self.target = target
  local windup_time = self:GetSpecialValueFor("snowball_windup")
  local snowball_duration = self:GetSpecialValueFor("snowball_duration")
  local radius = self:GetSpecialValueFor("snowball_radius") /2

  caster:SwapAbilities("tusk_snowball_lua","tusk_snowball_release_lua",false,true)

  target:AddNewModifier(caster,self,"modifier_tusk_snowball_target_vision",{duration = windup_time + snowball_duration})
  caster:AddNewModifier(caster,self,"modifier_tusk_snowball_auto_launch_controller",{duration = windup_time})
  caster:AddNewModifier(caster,self,"modifier_tusk_snowball_host",{duration = windup_time+snowball_duration})

  caster:EmitSound("Hero_Tusk.Snowball.Cast")

  --Show some effect
  local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_tusk/tusk_snowball_form.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
  ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
  ParticleManager:SetParticleControl(particle, 4, caster:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(particle)

  -- Make a dummy to attach the snowball
  self.dummy = CreateUnitByName("npc_dota_units_base",caster:GetAbsOrigin(),false,nil,nil,caster:GetTeamNumber())
  self.dummy:AddNewModifier(caster,self,"modifier_tusk_snowball_dummy",{})
  -- Snowball model doesn't roll along!
  particle = ParticleManager:CreateParticle("particles/units/heroes/hero_tusk/tusk_snowball.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.dummy)
  ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
  ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true) --Target
  ParticleManager:SetParticleControl(particle, 2, Vector(0,0,0)) --Velocity
  ParticleManager:SetParticleControl(particle, 3, Vector(radius,radius,radius)) --Radius

  -- Store to change CP's later
  self.particle = particle
  self.unitsHit = {}
  self.unitInSnowball = {}
  self.unitInSnowball[caster] = true
 end

-- Launches the snowball to target
function tusk_snowball_lua:ReleaseSnowball()
  local caster = self:GetCaster()
  local target = self.target
  local snowball_speed = self:GetSpecialValueFor("snowball_speed")
  local talent = self:GetCaster():FindAbilityByName("special_bonus_unique_tusk_3_lua")
  if talent then
    snowball_speed = snowball_speed + talent:GetSpecialValueFor("value")
  end
  ParticleManager:SetParticleControl(self.particle, 2, Vector(snowball_speed,snowball_speed,snowball_speed  )) --Velocity

  caster:EmitSound("Hero_Tusk.Snowball.Loop")
  local projectile_table =
  {
    Target = target,
    Source = caster,
    Ability = self,
    EffectName = "particles/dev/empty_particle.vpcf",
    iMoveSpeed = snowball_speed,
    vSourceLoc= caster:GetAbsOrigin(),
    bDrawsOnMinimap = false,
    bDodgeable = false,
    bIsAttack = false,
    bVisibleToEnemies = true,
    flExpireTime = GameRules:GetGameTime() + 10,
    bProvidesVision = false,
  }
  ProjectileManager:CreateTrackingProjectile(projectile_table)
end

---@override
function tusk_snowball_lua:OnProjectileThink(vLocation)
  local caster = self:GetCaster()
  local stun_duration = self:GetSpecialValueFor("stun_duration")
  local damage = self:GetSpecialValueFor("snowball _damage")

  local talent = self:GetCaster():FindAbilityByName("special_bonus_unique_tusk_2_lua")
  if talent then
    damage = damage + talent:GetSpecialValueFor("value")
  end
  local damage_per_unit = self:GetSpecialValueFor("snowball_damage_bonus")

  -- Move units along
  for unit,_ in pairs(self.unitInSnowball) do
    unit:SetAbsOrigin(vLocation)
  end

  -- Damage enemy units
  local units = FindUnitsInRadius(caster:GetTeamNumber(),vLocation,nil,self.radius,DOTA_UNIT_TARGET_TEAM_ENEMY,DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC,DOTA_UNIT_TARGET_FLAG_NONE,FIND_ANY_ORDER,false)
  for _,unit in pairs(units) do
    if not self.unitsHit[unit] then
      local damage_table = {
        victim = unit,
        attacker = caster,
        ability = self,
        damage = damage + (#self.unitInSnowball-1 * damage_per_unit),
        damage_type = self:GetAbilityDamageType(),
      }
      ApplyDamage(damage_table)
      unit:AddNewModifier(caster,self,"modifier_stunned",{duration = stun_duration})

      caster:EmitSound("Hero_Tusk.Snowball.ProjectileHit")
    end
  end
end

---@override
function tusk_snowball_lua:OnProjectileHit(hTarget,vLocation)
  -- Resolve collisions
  ResolveNPCPositions(vLocation,50)
  -- Remove all the modifiers
  self:GetCaster():RemoveModifierByName("modifier_tusk_snowball_host")
  for unit,_ in pairs(self.unitInSnowball) do
    unit:RemoveModifierByName("modifier_tusk_snowball")
  end

  UTIL_Remove(self.dummy)

  -- Remove the particle
  ParticleManager:DestroyParticle(self.particle,false)
  ParticleManager:ReleaseParticleIndex(self.particle)
  self:GetCaster():StopSound("Hero_Tusk.Snowball.Loop")
  if hTarget then
    self:GetCaster():EmitSound("Hero_Tusk.Snowball.Stun")
  end
end


---@class tusk_snowball_release_lua : CDOTA_Ability_Lua
tusk_snowball_release_lua = class({})
---@override
function tusk_snowball_release_lua:GetAssociatedPrimaryAbilities()
  return "tusk_snowball_lua"
end
---@override
function tusk_snowball_release_lua:OnSpellStart()
  local caster = self:GetCaster()
  caster:RemoveModifierByName("modifier_tusk_snowball_auto_launch_controller")
  caster:FindAbilityByName("tusk_snowball_lua"):ReleaseSnowball()
end



LinkLuaModifier("modifier_tusk_snowball_dummy","heroes/tusk/snowball.lua",LUA_MODIFIER_MOTION_NONE)
---@class modifier_tusk_snowball_dummy : CDOTA_Modifier_Lua
modifier_tusk_snowball_dummy = class({})
---@override
function modifier_tusk_snowball_dummy:IsPermanent() return true end
---@return table
function modifier_tusk_snowball_dummy:CheckState()
  return {
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
  }
end
---@override
function modifier_tusk_snowball_dummy:OnCreated()
  if IsServer() then
    local ability = self:GetAbility()
    ability.radius = ability:GetSpecialValueFor("snowball_radius")
    self:StartIntervalThink(1)
  end
end

---@override
function modifier_tusk_snowball_dummy:OnIntervalThink()
  local ability = self:GetAbility()
  -- Update particles
  local snowball_grow_rate = ability:GetSpecialValueFor("snowball_grow_rate")
  ability.radius = ability.radius + snowball_grow_rate
  ParticleManager:SetParticleControl(ability.particle, 3, Vector(ability.radius,ability.radius,ability.radius)) --Radius
end



-- Modifier that autocasts this spell on destruction, so spells swap back etc
LinkLuaModifier("modifier_tusk_snowball_auto_launch_controller","heroes/tusk/snowball.lua",LUA_MODIFIER_MOTION_NONE)
---@class modifier_tusk_snowball_auto_launch_controller : CDOTA_Modifier_Lua
modifier_tusk_snowball_auto_launch_controller = class({})
---@override
function modifier_tusk_snowball_auto_launch_controller:OnDestroy()
  if IsServer() then
    self:GetCaster():SwapAbilities("tusk_snowball_lua","tusk_snowball_release_lua",true,false)
    self:GetCaster():FindAbilityByName("tusk_snowball_release_lua"):OnSpellStart()
  end
end


-- Provides the vision the target has to tusk's team
LinkLuaModifier("modifier_tusk_snowball_target_vision","heroes/tusk/snowball.lua",LUA_MODIFIER_MOTION_NONE)
---@class modifier_tusk_snowball_target_vision : CDOTA_Modifier_Lua
modifier_tusk_snowball_target_vision = class({})
---@return table
function modifier_tusk_snowball_target_vision:CheckState()
  return {
    [MODIFIER_STATE_PROVIDES_VISION] = true,
  }
end


-- The modifier that gives the properties for tuskar during the snowball time
LinkLuaModifier("modifier_tusk_snowball_host","heroes/tusk/snowball.lua",LUA_MODIFIER_MOTION_NONE)
---@class modifier_tusk_snowball_host : CDOTA_Modifier_Lua
modifier_tusk_snowball_host = class({})
---@override
function modifier_tusk_snowball_host:IsHidden() return true end
---@override
function modifier_tusk_snowball_host:IsPurgable() return false end
---@override
function modifier_tusk_snowball_host:IsPurgeException() return false end
---@override
function modifier_tusk_snowball_host:IsDebuff() return false end

---@override
function modifier_tusk_snowball_host:OnCreated()
  if IsServer() then -- Nothing needs to be done on the client
    -- Store all the values
    local ability = self:GetAbility()

    self.snowball_grow_rate = ability:GetSpecialValueFor("snowball_grow_rate")
    self.snowball_grab_radius = ability:GetSpecialValueFor("snowball_grab_radius")

    self.units_inside = 0

    --caster:AddNoDraw()

  end
end

---@override
function modifier_tusk_snowball_host:OnDestroy()
  if IsServer() then -- Nothing needs to be done on the client
    --self:GetCaster():RemoveNoDraw()
  end
end

---@return table
function modifier_tusk_snowball_host:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ORDER,
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    MODIFIER_PROPERTY_MODEL_CHANGE,
  }
end
-- Required to make the unit clickable
---@return string
function modifier_tusk_snowball_host:GetModifierModelChange()
  return "models/particle/snowball.vmdl"
end

---@return number
function modifier_tusk_snowball_host:GetModifierIncomingDamage_Percentage()
  return -1000
end
---@return table
function modifier_tusk_snowball_host:CheckState()
  return {
    [MODIFIER_STATE_MUTED] = IsServer(), -- Not showing the status bar
    [MODIFIER_STATE_DISARMED] = IsServer(), -- Not showing the status bar
    [MODIFIER_STATE_ROOTED] = IsServer(),
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    --[MODIFIER_STATE_INVULNERABLE] = true, -- These state make allied orders impossible
    --[MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_UNSELECTABLE] = false,
  }
end

---@return
---@param keys table
  function modifier_tusk_snowball_host:OnOrder(keys)
  local caster = self:GetCaster()
  -- Only act on normal or attack order, this also ensures that there is a target
  if keys.order_type ~= DOTA_UNIT_ORDER_MOVE_TO_TARGET and keys.order_type ~= DOTA_UNIT_ORDER_ATTACK_TARGET then
    return
  end

  if keys.unit == keys.target then return end

  -- Check if either the issuer or the target is the caster
  if keys.target ~= caster and keys.unit ~= caster then return end

  -- Only allied units can be caught
  if keys.target:GetTeamNumber() ~= caster:GetTeamNumber() then return end
  -- Filter out units, illusions do count
  if not keys.target:IsHero() then return end
  if keys.unit ~= caster and PlayerResource:IsDisableHelpSetForPlayerID(keys.target:GetPlayerOwnerID(),caster:GetPlayerOwnerID()) then return end

  -- Check if the unit is in range for the grab
  if (keys.target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() >= self.snowball_grab_radius then return end

  local unit = keys.target
  if unit == caster then
    unit = keys.unit
  end

  -- No more reasons to reject
  self:GetAbility().unitInSnowball[unit] = true

  unit:AddNewModifier(caster,self:GetAbility(),"modifier_tusk_snowball_guest",{duration = 3})
end



-- The modifier that handles everything for allies
LinkLuaModifier("modifier_tusk_snowball_guest","heroes/tusk/snowball.lua",LUA_MODIFIER_MOTION_NONE)
---@class modifier_tusk_snowball_guest : CDOTA_Modifier_Lua
modifier_tusk_snowball_guest = class({})
---@override
function modifier_tusk_snowball_guest:IsHidden() return true end
---@override
function modifier_tusk_snowball_guest:IsPurgable() return false end
---@override
function modifier_tusk_snowball_guest:IsPurgeException() return false end
---@override
function modifier_tusk_snowball_guest:IsDebuff() return false end

---@override
function modifier_tusk_snowball_guest:OnCreated()
  if IsServer() then -- Nothing needs to be done on the client
    --Show some effect
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_tusk/tusk_snowball_load.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(particle, 0, self:GetParent():GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(particle)

    self:GetParent():EmitSound("Hero_Tusk.Snowball.Ally")
    self:GetParent():AddNoDraw()
  end
end

---@override
function modifier_tusk_snowball_guest:OnDestroy()
  if IsServer() then -- Nothing needs to be done on the client
    self:GetParent():RemoveNoDraw()
  end
end

---@return table
function modifier_tusk_snowball_guest :CheckState()
  return {
    [MODIFIER_STATE_STUNNED] = IsServer(), -- Not showing the stunned bar
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
  }
end