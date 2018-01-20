require("heroes/meepo/divided_we_stand")
meepo_poof_lua = class({})
function meepo_poof_lua.CastFilterResultTarget(self,target)
    if (target.GetName(target)==self.GetCaster(self).GetName(self.GetCaster(self))) and (target.GetPlayerOwnerID(target)==self.GetCaster(self).GetPlayerOwnerID(self.GetCaster(self))) then
        return UF_SUCCESS
    else
        return UF_FAIL_CUSTOM
    end
end
function meepo_poof_lua.GetCustomCastErrorTarget(self,target)
    return "#error_meepo_poof"
end
function meepo_poof_lua.GetCooldown(self,iLevel)
    local caster = self.GetCaster(self)
    local cooldown = self.GetSpecialValueFor(self,"cooldown")
    if IsServer() then
        local talent = self.GetCaster(self).FindAbilityByName(self.GetCaster(self),"special_bonus_unique_meepo")
        if talent then
            cooldown=cooldown-talent.GetSpecialValueFor(talent,"value")
        end
    end
    return cooldown
end
function meepo_poof_lua.OnAbilityPhaseStart(self)
    self.particle=ParticleManager.CreateParticle(ParticleManager,"particles/units/heroes/hero_meepo/meepo_poof_start.vpcf",PATTACH_ABSORIGIN_FOLLOW,self.GetCaster(self))
    self.GetCaster(self).EmitSound(self.GetCaster(self),"Hero_Meepo.Poof.Channel")
    return true
end
function meepo_poof_lua.OnAbilityPhaseInterrupted(self)
    ParticleManager.DestroyParticle(ParticleManager,self.particle,false)
    self.GetCaster(self).StopSound(self.GetCaster(self),"Hero_Meepo.Poof.Channel")
end
function meepo_poof_lua.OnSpellStart(self)
    local caster = self.GetCaster(self)
    local caster_origin = caster.GetAbsOrigin(caster)
    local target = self.GetCursorTarget(self)
    if not target then
        local PID = caster.GetPlayerOwnerID(caster)
        local mainMeepo = PlayerResource.GetSelectedHeroEntity(PlayerResource,PID)
        local dist = 999999
        for _, meepo in pairs(GetAllMeepos(mainMeepo)) do
            local range = meepo.GetAbsOrigin(meepo)-self.GetCursorPosition(self)
            range=range.Length2D(range)
            if range<dist then
                dist=range
                target=meepo
            end
        end
    end
    local target_origin = target.GetAbsOrigin(target)
    local damage = self.GetSpecialValueFor(self,"poof_damage")
    local talent = self.GetCaster(self).FindAbilityByName(self.GetCaster(self),"special_bonus_unique_meepo2")
    if talent then
        damage=damage+talent.GetSpecialValueFor(talent,"value")
    end
    local radius = self.GetSpecialValueFor(self,"radius")
    local units = FindUnitsInRadius(caster.GetTeamNumber(caster),caster_origin,nil,radius,DOTA_UNIT_TARGET_TEAM_ENEMY,DOTA_UNIT_TARGET_BASIC+DOTA_UNIT_TARGET_HERO,DOTA_UNIT_TARGET_FLAG_NONE,0,false)
    for _, unit in pairs(units) do
        local dTable = {["attacker"]=caster,["victim"]=unit,["damage"]=damage,["damage_type"]=DAMAGE_TYPE_MAGICAL}
        ApplyDamage(dTable)
        unit.EmitSound(unit,"Hero_Meepo.Poof.Damage")
    end
    local particleOldPoint = ParticleManager.CreateParticle(ParticleManager,"particles/units/heroes/hero_meepo/meepo_poof_end.vpcf",PATTACH_ABSORIGIN,caster)
    ParticleManager.SetParticleControl(ParticleManager,particleOldPoint,0,caster_origin)
    FindClearSpaceForUnit(caster,target_origin,true)
    caster.AddNewModifier(caster,caster,self,"modifier_phased",{["duration"]=0.1})
    units=FindUnitsInRadius(caster.GetTeamNumber(caster),target_origin,nil,radius,DOTA_UNIT_TARGET_TEAM_ENEMY,DOTA_UNIT_TARGET_BASIC+DOTA_UNIT_TARGET_HERO,DOTA_UNIT_TARGET_FLAG_NONE,0,false)
    for _, unit in pairs(units) do
        local dTable = {["attacker"]=caster,["victim"]=unit,["damage"]=damage,["damage_type"]=DAMAGE_TYPE_MAGICAL}
        ApplyDamage(dTable)
        unit.EmitSound(unit,"Hero_Meepo.Poof.Damage")
    end
    local particleNewPoint = ParticleManager.CreateParticle(ParticleManager,"particles/units/heroes/hero_meepo/meepo_poof_end.vpcf",PATTACH_ABSORIGIN,caster)
    ParticleManager.SetParticleControl(ParticleManager,particleNewPoint,0,target_origin)
    local soundString = "Hero_Meepo.Poof.End00"
    caster.EmitSound(caster,soundString)
    caster.StartGesture(caster,ACT_DOTA_POOF_END)
end
