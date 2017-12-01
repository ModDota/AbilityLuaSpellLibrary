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

function lua_antimage_spell_shield:GetCooldown(level)
    if self:GetCaster():HasScepter() then
        return self:GetSpecialValueFor("scepter_cooldown")
    end

    return 0
end


-- Spell shield modifier
modifier_lua_antimage_spell_shield = class({})

function modifier_lua_antimage_spell_shield:IsHidden() return true end
function modifier_lua_antimage_spell_shield:IsDebuff() return false end

function modifier_lua_antimage_spell_shield:OnCreated()
    -- Ability properties
    self.caster = self:GetCaster()
    self.ability = self:GetAbility()

    -- Ability specials
    self.spell_shield_resistance = self.ability:GetSpecialValueFor("spell_shield_resistance")    

    -- Initialize table of old spells
    self.caster.tOldSpells = {}
    
    if IsServer() then
        -- Think, in order to check for scepter. Once a scepter is found, the modifier's interval starts
        self:StartIntervalThink(20)
    end
end

function modifier_lua_antimage_spell_shield:OnRefresh()
    -- Refresh specials
    self.spell_shield_resistance = self.ability:GetSpecialValueFor("spell_shield_resistance")    
end

-- Biggest thanks to Yunten and AtroCty
function modifier_lua_antimage_spell_shield:OnIntervalThink()
    if IsServer() then
        -- Continually checks if the caster has a scepter. If it does, thinking becomes much faster.        
        if self.caster:HasScepter() then

            -- Deleting old abilities
            for i=#self.caster.tOldSpells,1,-1 do
                local hSpell = self.caster.tOldSpells[i]
                if hSpell:NumModifiersUsingAbility() == 0 and not hSpell:IsChanneling() then
                    hSpell:RemoveSelf()
                    table.remove(self.caster.tOldSpells,i)
                end
            end

            self:StartIntervalThink(0.2)
        else
            self:StartIntervalThink(20)
        end        
    end
end

function modifier_lua_antimage_spell_shield:DeclareFunctions() 
    local decFuncs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_ABSORB_SPELL,
        MODIFIER_PROPERTY_REFLECT_SPELL
    }
    return decFuncs 
end

function modifier_lua_antimage_spell_shield:GetModifierMagicalResistanceBonus()
    if not self.caster:PassivesDisabled() then
        return self.spell_shield_resistance
    end
end

function modifier_lua_antimage_spell_shield:GetAbsorbSpell( params )
    if IsServer() then    
        if self.caster:HasScepter() and self.caster:IsRealHero() and self.ability:IsCooldownReady() then
            if not self.caster:PassivesDisabled() then  
                -- Apply Spell Absorption
                local reflect_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_antimage/antimage_spellshield.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self.caster)
                ParticleManager:SetParticleControlEnt(reflect_pfx, 0, self.caster, PATTACH_POINT_FOLLOW, "attach_hitloc", self.caster:GetOrigin(), true)
                ParticleManager:ReleaseParticleIndex(reflect_pfx)
                return true
            end
        end
        return false  
    end
end

function modifier_lua_antimage_spell_shield:GetReflectSpell( params )
    if IsServer() then    
        if self.caster:HasScepter() and self.caster:IsRealHero() and self.ability:IsCooldownReady() then
            if not self.caster:PassivesDisabled() then        

                -- Set ability on cooldown
                self.ability:UseResources(false, false, true)

                -- If some spells shouldn't be reflected, enter it into this spell-list
                local exception_spell = 
                {   
                    ["rubick_spell_steal"] = true,
                }
            
                local reflected_spell_name = params.ability:GetAbilityName()
                local target = params.ability:GetCaster()  

                -- Does not reflect allies' projectiles for any reason
                if target:GetTeamNumber() == self.caster:GetTeamNumber() then
                    return nil
                end
          
                -- Do not reflect spells if the target has Lotus Orb on, otherwise the game will die hard.
                if target:HasModifier("modifier_item_lotus_orb_active") then
                    return nil
                end  
            
                if ( not exception_spell[reflected_spell_name] ) and (not target:HasModifier("modifier_lua_antimage_spell_shield")) then

                    -- If this is a reflected ability, do nothing
                    if params.ability.spell_shield_reflect then
                        return nil
                    end    
              
                    local reflect_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_antimage/antimage_spellshield_reflect.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self.caster)
                    ParticleManager:SetParticleControlEnt(reflect_pfx, 0, self.caster, PATTACH_POINT_FOLLOW, "attach_hitloc", self.caster:GetAbsOrigin(), true)
                    ParticleManager:ReleaseParticleIndex(reflect_pfx)
            
                    local old_spell = false
                    for _,hSpell in pairs(self.caster.tOldSpells) do
                        if hSpell ~= nil and hSpell:GetAbilityName() == reflected_spell_name then
                            old_spell = true
                            break
                        end
                    end

                    if old_spell then
                        ability = self.caster:FindAbilityByName(reflected_spell_name)
                    else
                        ability = self.caster:AddAbility(reflected_spell_name)
                        ability:SetStolen(true)
                        ability:SetHidden(true)

                        -- Tag ability as a reflection ability
                        ability.spell_shield_reflect = true
                    
                        -- Modifier counter, and add it into the old-spell list
                        ability:SetRefCountsModifiers(true)
                        table.insert(self.caster.tOldSpells, ability)
                    end   
                  
                    ability:SetLevel(params.ability:GetLevel())
                    -- Set target & fire spell
                    self.caster:SetCursorCastTarget(target)
                    ability:OnSpellStart()
                    target:EmitSound("Hero_Antimage.SpellShield.Reflect")
                end

                return false
            end
        end
    end
end

  
