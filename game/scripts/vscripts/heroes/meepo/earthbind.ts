LinkLuaModifier("modifier_meepo_earthbind_lua","heroes/meepo/earthbind.lua",LuaModifierType.LUA_MODIFIER_MOTION_NONE)

class meepo_earthbind_lua extends CDOTA_Ability_Lua {
    particle:ParticleID

    GetCooldown() {
        let caster:CDOTA_BaseNPC = this.GetCaster()
        let cooldown = this.GetSpecialValueFor("cooldown")
        if (IsServer()) {
            let talent:CDOTABaseAbility = this.GetCaster().FindAbilityByName("special_bonus_unique_meepo_3")
            if (talent) {
                cooldown -= talent.GetSpecialValueFor("value")
            }
        }
        return cooldown
    }

    OnAbilityPhaseStart() {
        this.GetCaster().EmitSound("Hero_Meepo.Earthbind.Cast")
        return true
    }

    OnAbilityPhaseInterrupted() {
        this.GetCaster().StopSound("Hero_Meepo.Earthbind.Cast")
    }

    OnSpellStart() {
        let caster = this.GetCaster()
        let point = this.GetCursorPosition()
        let projectileSpeed = this.GetSpecialValueFor("speed")
        let direction = point-caster.GetAbsOrigin()
        direction = direction.Normalized()
        direction[2] = 0
        direction = direction * projectileSpeed
        let range = point - caster.GetAbsOrigin()
        range = range.Length2D()
        let radius = this.GetSpecialValueFor("radius")
        this.particle = ParticleManager.CreateParticle("particles/units/heroes/hero_meepo/meepo_earthbind_projectile_fx.vpcf", ParticleAttachment_t.PATTACH_ABSORIGIN_FOLLOW, caster)
        ParticleManager.SetParticleControl(this.particle, 0, caster.GetAbsOrigin())
        ParticleManager.SetParticleControl(this.particle, 1, point)
        ParticleManager.SetParticleControl(this.particle, 2, Vector(projectileSpeed, 0, 0))
        ParticleManager.SetParticleControl(this.particle, 3, point)

        let projectileTable:LinearProjectileTable = {
            Ability: this,
            EffectName: "",
            vSpawnOrigin: caster.GetAbsOrigin(),
            fDistance: range,
            fStartRadius: radius,
            fEndRadius: radius,
            Source: caster,
            bHasFrontalCone: false,
            bReplaceExisting: false,
            iUnitTargetTeam: DOTA_UNIT_TARGET_TEAM.DOTA_UNIT_TARGET_TEAM_NONE,
            iUnitTargetFlags: DOTA_UNIT_TARGET_FLAGS.DOTA_UNIT_TARGET_FLAG_NONE,
            iUnitTargetType: DOTA_UNIT_TARGET_TYPE.DOTA_UNIT_TARGET_NONE,
            fExpireTime: GameRules.GetGameTime()+0.25+range/projectileSpeed  ,
            bDeleteOnHit: false,
            vVelocity: direction,
            bProvidesVision: true,
            iVisionRadius: radius,
            iVisionTeamNumber: caster.GetTeamNumber(),
        }
        ProjectileManager.CreateLinearProjectile(projectileTable)
    }

    OnProjectileHit(target:CDOTA_BaseNPC,location:Vec) {
        let caster = this.GetCaster()
        let duration = this.GetSpecialValueFor("duration")
        let radius = this.GetSpecialValueFor("radius")
        let units = FindUnitsInRadius(
            caster.GetTeamNumber(),
            location,
            null,
            radius,
            DOTA_UNIT_TARGET_TEAM.DOTA_UNIT_TARGET_TEAM_ENEMY,
            DOTA_UNIT_TARGET_TYPE.DOTA_UNIT_TARGET_BASIC+DOTA_UNIT_TARGET_TYPE.DOTA_UNIT_TARGET_HERO,
            DOTA_UNIT_TARGET_FLAGS.DOTA_UNIT_TARGET_FLAG_NONE,
            0,
            false
        )
        for (let unit of units) {
            unit.AddNewModifier(caster,this,"modifier_meepo_earthbind_lua",{duration:duration})
            unit.EmitSound("Hero_Meepo.Earthbind.Target")
        }
        ParticleManager.DestroyParticle(this.particle,false)
        ParticleManager.ReleaseParticleIndex(this.particle)
        return true
    }
}

class modifier_meepo_earthbind_lua extends CDOTA_Modifier_Lua {
    // Override invis
    GetPriority() {
        return modifierpriority.MODIFIER_PRIORITY_HIGH
    }

    CheckState() {
        let funcs = {
            [modifierstate.MODIFIER_STATE_INVISIBLE]: false,
            [modifierstate.MODIFIER_STATE_ROOTED]: true,
        }
        return funcs
    }

    GetEffectName() {
        return "particles/units/heroes/hero_meepo/meepo_earthbind.vpcf"
    }
}