LinkLuaModifier("modifier_meepo_earthbind_lua","heroes/meepo/earthbind.lua",LUA_MODIFIER_MOTION_NONE)
meepo_earthbind_lua = class({})
function meepo_earthbind_lua.GetCooldown(self)
    local caster = self.GetCaster(self)
    local cooldown = self.GetSpecialValueFor(self,"cooldown")
    if IsServer() then
        local talent = self.GetCaster(self).FindAbilityByName(self.GetCaster(self),"special_bonus_unique_meepo_3")
        if talent then
            cooldown=cooldown-talent.GetSpecialValueFor(talent,"value")
        end
    end
    return cooldown
end
function meepo_earthbind_lua.OnAbilityPhaseStart(self)
    self.GetCaster(self).EmitSound(self.GetCaster(self),"Hero_Meepo.Earthbind.Cast")
    return true
end
function meepo_earthbind_lua.OnAbilityPhaseInterrupted(self)
    self.GetCaster(self).StopSound(self.GetCaster(self),"Hero_Meepo.Earthbind.Cast")
end
function meepo_earthbind_lua.OnSpellStart(self)
    local caster = self.GetCaster(self)
    local point = self.GetCursorPosition(self)
    local projectileSpeed = self.GetSpecialValueFor(self,"speed")
    local direction = point-caster.GetAbsOrigin(caster)
    direction=direction.Normalized(direction)
    direction[2]=0
    direction=(direction*projectileSpeed)
    local range = point-caster.GetAbsOrigin(caster)
    range=range.Length2D(range)
    local radius = self.GetSpecialValueFor(self,"radius")
    self.particle=ParticleManager.CreateParticle(ParticleManager,"particles/units/heroes/hero_meepo/meepo_earthbind_projectile_fx.vpcf",PATTACH_ABSORIGIN_FOLLOW,caster)
    ParticleManager.SetParticleControl(ParticleManager,self.particle,0,caster.GetAbsOrigin(caster))
    ParticleManager.SetParticleControl(ParticleManager,self.particle,1,point)
    ParticleManager.SetParticleControl(ParticleManager,self.particle,2,Vector(projectileSpeed,0,0))
    ParticleManager.SetParticleControl(ParticleManager,self.particle,3,point)
    local projectileTable = {["Ability"]=self,["EffectName"]="",["vSpawnOrigin"]=caster.GetAbsOrigin(caster),["fDistance"]=range,["fStartRadius"]=radius,["fEndRadius"]=radius,["Source"]=caster,["bHasFrontalCone"]=false,["bReplaceExisting"]=false,["iUnitTargetTeam"]=DOTA_UNIT_TARGET_TEAM_NONE,["iUnitTargetFlags"]=DOTA_UNIT_TARGET_FLAG_NONE,["iUnitTargetType"]=DOTA_UNIT_TARGET_NONE,["fExpireTime"]=(GameRules.GetGameTime(GameRules)+0.25)+(range/projectileSpeed),["bDeleteOnHit"]=false,["vVelocity"]=direction,["bProvidesVision"]=true,["iVisionRadius"]=radius,["iVisionTeamNumber"]=caster.GetTeamNumber(caster)}
    ProjectileManager.CreateLinearProjectile(ProjectileManager,projectileTable)
end
function meepo_earthbind_lua.OnProjectileHit(self,target,location)
    local caster = self.GetCaster(self)
    local duration = self.GetSpecialValueFor(self,"duration")
    local radius = self.GetSpecialValueFor(self,"radius")
    local units = FindUnitsInRadius(caster.GetTeamNumber(caster),location,nil,radius,DOTA_UNIT_TARGET_TEAM_ENEMY,DOTA_UNIT_TARGET_BASIC+DOTA_UNIT_TARGET_HERO,DOTA_UNIT_TARGET_FLAG_NONE,0,false)
    for _, unit in pairs(units) do
        unit.AddNewModifier(unit,caster,self,"modifier_meepo_earthbind_lua",{["duration"]=duration})
        unit.EmitSound(unit,"Hero_Meepo.Earthbind.Target")
    end
    ParticleManager.DestroyParticle(ParticleManager,self.particle,false)
    ParticleManager.ReleaseParticleIndex(ParticleManager,self.particle)
    return true
end
modifier_meepo_earthbind_lua = class({})
function modifier_meepo_earthbind_lua.GetPriority(self)
    return MODIFIER_PRIORITY_HIGH
end
function modifier_meepo_earthbind_lua.CheckState(self)
    local funcs = {[MODIFIER_STATE_INVISIBLE]=false,[MODIFIER_STATE_ROOTED]=true}
    return funcs
end
function modifier_meepo_earthbind_lua.GetEffectName(self)
    return "particles/units/heroes/hero_meepo/meepo_earthbind.vpcf"
end
