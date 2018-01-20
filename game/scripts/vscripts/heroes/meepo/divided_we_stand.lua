LinkLuaModifier("modifier_meepo_divided_we_stand_lua","heroes/meepo/divided_we_stand.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_meepo_divided_we_stand_death_lua","heroes/meepo/divided_we_stand.lua",LUA_MODIFIER_MOTION_NONE)
meepo_divided_we_stand_lua = class({})
function meepo_divided_we_stand_lua.constructor(self)
    self.isScepterUpgraded = false
end
function meepo_divided_we_stand_lua.OnUpgrade(self)
    local caster = self.GetCaster(self)
    local PID = caster.GetPlayerOwnerID(caster)
    local mainMeepo = PlayerResource.GetSelectedHeroEntity(PlayerResource,PID)
    local list = mainMeepo.meepoList or {}
    if caster~=mainMeepo then
        return nil
    end
    if not mainMeepo.meepoList then
        table.insert(list, mainMeepo)
        mainMeepo.meepoList=list
        mainMeepo.AddNewModifier(mainMeepo,mainMeepo,self,"modifier_meepo_divided_we_stand_lua",{})
    end
    local newMeepo = CreateUnitByName(caster.GetUnitName(caster),mainMeepo.GetAbsOrigin(mainMeepo),true,mainMeepo,mainMeepo.GetPlayerOwner(mainMeepo),mainMeepo.GetTeamNumber(mainMeepo))
    newMeepo.SetControllableByPlayer(newMeepo,PID,false)
    newMeepo.SetOwner(newMeepo,caster.GetOwner(caster))
    newMeepo.AddNewModifier(newMeepo,mainMeepo,self,"modifier_phased",{["duration"]=0.1})
    local ability = newMeepo.FindAbilityByName(newMeepo,self.GetAbilityName(self))
    newMeepo.AddNewModifier(newMeepo,mainMeepo,self,"modifier_meepo_divided_we_stand_lua",{})
    list=mainMeepo.meepoList
    table.insert(list, newMeepo)
    mainMeepo.meepoList=list
end
function meepo_divided_we_stand_lua.OnInventoryContentsChanged(self)
    if not self.isScepterUpgraded and self.GetCaster(self).HasScepter(self.GetCaster(self)) then
        for i=0,5,1 do
            local item = self.GetCaster(self).GetItemInSlot(self.GetCaster(self),i)
            if item and (item.GetAbilityName(item)=="item_ultimate_scepter") then
                item.SetDroppable(item,false)
                item.SetSellable(item,false)
                item.SetCanBeUsedOutOfInventory(item,false)
                self.isScepterUpgraded=true
            end
        end
        self.OnUpgrade(self)
    end
end
modifier_meepo_divided_we_stand_lua = class({})
function modifier_meepo_divided_we_stand_lua.IsHidden(self)
    return true
end
function modifier_meepo_divided_we_stand_lua.IsPermanent(self)
    return true
end
function modifier_meepo_divided_we_stand_lua.DeclareFunctions(self)
    return {MODIFIER_EVENT_ON_ORDER,MODIFIER_EVENT_ON_DEATH,MODIFIER_EVENT_ON_RESPAWN,MODIFIER_EVENT_ON_TAKEDAMAGE}
end
function modifier_meepo_divided_we_stand_lua.OnCreated(self)
    if IsServer() then
        self.StartIntervalThink(self,FrameTime())
    end
end
function modifier_meepo_divided_we_stand_lua.OnIntervalThink(self)
    local meepo = self.GetParent(self)
    local mainMeepo = self.GetCaster(self)
    local ability = self.GetAbility(self)
    if mainMeepo~=meepo then
        local boots = {"item_travel_boots2","item_travel_boots","item_guardian_greaves","item_power_treads","item_arcane_boots","item_phase_boots","item_tranquil_boots","item_boots"}
        local item = ""
        for _, name in pairs(boots) do
            if item=="" then
                for j=0,5,1 do
                    local it = mainMeepo.GetItemInSlot(mainMeepo,j)
                    if it and (name==it.GetAbilityName(it)) then
                        item=name
                    end
                end
            else
                break
            end
        end
        if item~="" then
            if meepo["item"] then
                if meepo["item"]~=item then
                    UTIL_Remove(meepo["itemHandle"])
                    local itemHandle = meepo.AddItemByName(meepo,item)
                    itemHandle.SetDroppable(itemHandle,false)
                    itemHandle.SetSellable(itemHandle,false)
                    itemHandle.SetCanBeUsedOutOfInventory(itemHandle,false)
                    meepo["itemHandle"]=itemHandle
                    meepo["item"]=item
                end
            else
                meepo["itemHandle"]=meepo.AddItemByName(meepo,item)
                meepo["item"]=item
            end
        end
        for j=0,5,1 do
            local itemToCheck = meepo.GetItemInSlot(meepo,j)
            if itemToCheck then
                local name = itemToCheck.GetAbilityName(itemToCheck)
                if name~=item then
                    UTIL_Remove(itemToCheck)
                end
            end
        end
        meepo.SetBaseStrength(meepo,mainMeepo.GetStrength(mainMeepo))
        meepo.SetBaseAgility(meepo,mainMeepo.GetAgility(mainMeepo))
        meepo.SetBaseIntellect(meepo,mainMeepo.GetIntellect(mainMeepo))
        meepo.CalculateStatBonus(meepo)
        while meepo.GetLevel(meepo)<mainMeepo.GetLevel(mainMeepo) do
            meepo.AddExperience(meepo,10,1,false,false)
        end
    else
        LevelAbilitiesForAllMeepos(meepo)
    end
end
function modifier_meepo_divided_we_stand_lua.OnTakeDamage(self,keys)
    local mainMeepo = self.GetCaster(self)
    local parent = self.GetParent(self)
    if keys.unit==parent then
        if parent.GetHealth(parent)<0 then
            if parent~=self.GetCaster(self) then
                local oldLocation = mainMeepo.GetAbsOrigin(mainMeepo)
                mainMeepo.SetAbsOrigin(mainMeepo,parent.GetAbsOrigin(parent))
                mainMeepo.Kill(mainMeepo,keys.inflictor,keys.attacker)
                mainMeepo.SetAbsOrigin(mainMeepo,oldLocation)
                parent.SetHealth(parent,parent.GetMaxHealth(parent))
            end
            for _, meepo in pairs(GetAllMeepos(mainMeepo)) do
                if meepo~=mainMeepo then
                    meepo.AddNewModifier(meepo,mainMeepo,self.GetAbility(self),"modifier_meepo_divided_we_stand_death_lua",{})
                end
            end
        end
    end
end
function modifier_meepo_divided_we_stand_lua.OnRespawn(self,keys)
    local parent = self.GetParent(self)
    local mainMeepo = self.GetCaster(self)
    if (keys.unit==parent) and (parent==PlayerResource.GetSelectedHeroEntity(PlayerResource,self.GetParent(self).GetPlayerOwnerID(self.GetParent(self)))) then
        for _, meepo in pairs(GetAllMeepos(mainMeepo)) do
            if meepo~=mainMeepo then
                meepo.RemoveModifierByName(meepo,"modifier_meepo_divided_we_stand_death_lua")
                meepo.RemoveNoDraw(meepo)
                FindClearSpaceForUnit(meepo,self.GetParent(self).GetAbsOrigin(self.GetParent(self)),true)
                meepo.AddNewModifier(meepo,meepo,self.GetAbility(self),"modifier_phased",{["duration"]=0.1})
            end
        end
    end
end
modifier_meepo_divided_we_stand_death_lua = class({})
function modifier_meepo_divided_we_stand_death_lua.IsPermanent(self)
    return false
end
function modifier_meepo_divided_we_stand_death_lua.IsHidden(self)
    return true
end
function modifier_meepo_divided_we_stand_death_lua.OnCreated(self)
    if IsServer() then
        self.GetParent(self).StartGesture(self.GetParent(self),ACT_DOTA_DIE)
        self.StartIntervalThink(self,1.5)
    end
end
function modifier_meepo_divided_we_stand_death_lua.OnIntervalThink(self)
    local parent = self.GetParent(self)
    parent.RemoveGesture(parent,ACT_DOTA_DIE)
    parent.AddNoDraw(parent)
    if parent.GetTeamNumber(parent)==DOTA_TEAM_GOODGUYS then
        parent.SetAbsOrigin(parent,Vector(-10000,-10000,0))
    else
        parent.SetAbsOrigin(parent,Vector(10000,10000,0))
    end
    self.StartIntervalThink(self,-1)
end
function modifier_meepo_divided_we_stand_death_lua.CheckState(self)
    return {[MODIFIER_STATE_STUNNED]=true,[MODIFIER_STATE_UNSELECTABLE]=true,[MODIFIER_STATE_INVULNERABLE]=true,[MODIFIER_STATE_UNTARGETABLE]=true,[MODIFIER_STATE_OUT_OF_GAME]=true,[MODIFIER_STATE_NO_HEALTH_BAR]=true,[MODIFIER_STATE_NOT_ON_MINIMAP]=true}
end
function LevelAbilitiesForAllMeepos(caster)
    local PID = caster.GetPlayerOwnerID(caster)
    local mainMeepo = PlayerResource.GetSelectedHeroEntity(PlayerResource,PID)
    if caster==mainMeepo then
        for a=0,caster.GetAbilityCount(caster)-1,1 do
            local ability = caster.GetAbilityByIndex(caster,a)
            if ability then
                for _, meepo in pairs(GetAllMeepos(mainMeepo)) do
                    local cloneAbility = meepo.FindAbilityByName(meepo,ability.GetAbilityName(ability))
                    if ability.GetLevel(ability)>cloneAbility.GetLevel(cloneAbility) then
                        cloneAbility.SetLevel(cloneAbility,ability.GetLevel(ability))
                        meepo.SetAbilityPoints(meepo,meepo.GetAbilityPoints(meepo)-1)
                    end
                    if ability.GetLevel(ability)<cloneAbility.GetLevel(cloneAbility) then
                        ability.SetLevel(ability,cloneAbility.GetLevel(cloneAbility))
                        mainMeepo.SetAbilityPoints(mainMeepo,mainMeepo.GetAbilityPoints(mainMeepo)-1)
                    end
                end
            end
        end
    end
end
function GetAllMeepos(caster)
    if caster.meepoList then
        return caster.meepoList
    else
        return {caster}
    end
end
function MeepoExperience(filterTable)
    local PID = filterTable.player_id_const
    local reason = filterTable.reason_const
    local experience = filterTable.experience
    local hero = PlayerResource.GetSelectedHeroEntity(PlayerResource,PID)
    if (hero and hero.HasAbility(hero,"meepo_divided_we_stand_lua")) and (reason~=DOTA_ModifyXP_Unspecified) then
        filterTable.experience=0
        hero.AddExperience(hero,experience,DOTA_ModifyXP_Unspecified,true,false)
    end
    return filterTable
end
function MeepoOrderFilter(filterTable)
    local entindex_ability = filterTable.entindex_ability
    local sequence_number_const = filterTable.sequence_number_const
    local queue = filterTable.sequence_number_const
    local units = filterTable.units
    local entindex_target = filterTable.entindex_target
    local position = Vector(filterTable.position_y,filterTable.position_y,filterTable.position_z)
    local order_type = filterTable.order_type
    local issuer_player_id_const = filterTable.issuer_player_id_const
    local ability = EntIndexToHScript(entindex_ability)
    local target = EntIndexToHScript(entindex_target)
    for _, entindex_unit in pairs(units) do
        local unit = EntIndexToHScript(entindex_unit)
        if unit.HasModifier(unit,"modifier_meepo_divided_we_stand_lua") and (unit~=PlayerResource.GetSelectedHeroEntity(PlayerResource,unit.GetPlayerOwnerID(unit))) then
            if order_type==DOTA_UNIT_ORDER_PICKUP_ITEM then
                return false
            end
        end
        if ((target and target.HasModifier) and target.HasModifier(target,"modifier_meepo_divided_we_stand_lua")) and (target~=PlayerResource.GetSelectedHeroEntity(PlayerResource,target.GetPlayerOwnerID(target))) then
            if order_type==DOTA_UNIT_ORDER_GIVE_ITEM then
                return false
            end
        end
    end
    return true
end
if IsServer() then
    GameRules.GetGameModeEntity(GameRules).SetExecuteOrderFilter(GameRules.GetGameModeEntity(GameRules),function(f,filterTable)
        if MeepoOrderFilter then
            if not MeepoOrderFilter(filterTable) then
                return false
            end
        end
        return true
    end ,GameRules.GetGameModeEntity(GameRules))
    GameRules.GetGameModeEntity(GameRules).SetModifyExperienceFilter(GameRules.GetGameModeEntity(GameRules),function(f,filterTable)
        if MeepoExperience then
            filterTable=MeepoExperience(filterTable)
        end
        return true
    end ,GameRules.GetGameModeEntity(GameRules))
end
