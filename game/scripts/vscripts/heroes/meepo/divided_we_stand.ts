// For this to work you need to override the following lines in your lua file
// GameRules.GetGameModeEntity(GameRules).SetExecuteOrderFilter(GameRules.GetGameModeEntity(GameRules),function(f,filterTable)
// GameRules.GetGameModeEntity(GameRules).SetModifyExperienceFilter(GameRules.GetGameModeEntity(GameRules),function(f,filterTable)

// Known issue: Power treads not moving along, there is no way to get their state.
// Multiple boots may be included in the networth
LinkLuaModifier("modifier_meepo_divided_we_stand_lua","heroes/meepo/divided_we_stand.lua",LuaModifierType.LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_meepo_divided_we_stand_death_lua","heroes/meepo/divided_we_stand.lua",LuaModifierType.LUA_MODIFIER_MOTION_NONE)

class meepo_divided_we_stand_lua extends CDOTA_Ability_Lua {
	isScepterUpgraded: boolean = false

	
	OnUpgrade() {
		let caster = <CDOTA_BaseNPC_Hero>this.GetCaster()
		let PID = caster.GetPlayerOwnerID()
		let mainMeepo = PlayerResource.GetSelectedHeroEntity(PID)
		let list:CDOTA_BaseNPC_Hero[] = mainMeepo.meepoList  || []
		if (caster != mainMeepo) {
			return null
		}
		if (!mainMeepo.meepoList) {
			list.push(mainMeepo)
			mainMeepo.meepoList = list
			mainMeepo.AddNewModifier(mainMeepo,this,"modifier_meepo_divided_we_stand_lua",{})
		}

		let newMeepo = <CDOTA_BaseNPC_Hero>CreateUnitByName(
			caster.GetUnitName(),
			mainMeepo.GetAbsOrigin(),
			true,mainMeepo,
			mainMeepo.GetPlayerOwner(),
			mainMeepo.GetTeamNumber()
		)
		newMeepo.SetControllableByPlayer(PID,false)
		newMeepo.SetOwner(caster.GetOwner())
		newMeepo.AddNewModifier(mainMeepo,this,"modifier_phased",{duration:0.1})
		let ability = newMeepo.FindAbilityByName(this.GetAbilityName())
		newMeepo.AddNewModifier(mainMeepo,this,"modifier_meepo_divided_we_stand_lua",{})
		list = mainMeepo.meepoList
		list.push(newMeepo)
		mainMeepo.meepoList = list
	}

	OnInventoryContentsChanged() {
		// The scepter part
		if (!this.isScepterUpgraded && this.GetCaster().HasScepter()) {
			for (let i=0 ; i<=5 ; i++) {
				let item:CDOTA_Item = this.GetCaster().GetItemInSlot(i)
				if (item && item.GetAbilityName() == "item_ultimate_scepter") {
					item.SetDroppable(false)
					item.SetSellable(false)
					item.SetCanBeUsedOutOfInventory(false)
					this.isScepterUpgraded = true
				}
			}
			this.OnUpgrade()
		}
	}
}

// Modifier stuff

class modifier_meepo_divided_we_stand_lua extends CDOTA_Modifier_Lua {
	IsHidden() {return true}
	IsPermanent() {return true}
	boots_list:string[]

	DeclareFunctions() {
		return [
			modifierfunction.MODIFIER_EVENT_ON_ORDER,
			modifierfunction.MODIFIER_EVENT_ON_DEATH,
			modifierfunction.MODIFIER_EVENT_ON_RESPAWN,
			modifierfunction.MODIFIER_EVENT_ON_TAKEDAMAGE,
		]
	}


	// Stats sync with client on refresh and no other syncing needed.(?)
	OnCreated() {
		if (IsServer()) {
			this.StartIntervalThink(FrameTime())
		}
	}

	OnIntervalThink() {
		let meepo = <CDOTA_BaseNPC_Hero>this.GetParent()
		let mainMeepo = <CDOTA_BaseNPC_Hero>this.GetCaster()
		
		let ability: CDOTABaseAbility = this.GetAbility()
		// Loop through abilities to sync levels
		if (mainMeepo != meepo) {
			let boots:string[] = [
				"item_travel_boots2",
				"item_travel_boots",
				"item_guardian_greaves",
				"item_power_treads",
				"item_arcane_boots",
				"item_phase_boots",
				"item_tranquil_boots",
				"item_boots"
			]
			// Get the highest ranked boots
			let item = ""
			for (let name of boots) {
				if (item == "") {
					for (let j=0;j<=5;j++) {
						let it = mainMeepo.GetItemInSlot(j)
						if (it && name == it.GetAbilityName()) {
							item = name
						}
					}
				} else {
					break
				}
			}
			// Remove previous item if it exists and isn't the same
			// Add the best boots
			if (item != "") {
				if (meepo["item"]) { 
					if (meepo["item"] != item) {
						UTIL_Remove(meepo["itemHandle"])
						let itemHandle = meepo.AddItemByName(item)
						itemHandle.SetDroppable(false)
						itemHandle.SetSellable(false)
						itemHandle.SetCanBeUsedOutOfInventory(false)
						meepo["itemHandle"] = itemHandle
						meepo["item"] = item
					}
				} else {
					meepo["itemHandle"] = meepo.AddItemByName(item)
					meepo["item"] = item
				}
				
				// Remove all items from clones
			}  
			for (let j=0;j<=5;j++) {
				let itemToCheck:CDOTA_Item = meepo.GetItemInSlot(j)
				if (itemToCheck) {
					let name = itemToCheck.GetAbilityName()
					if (name != item) {
						UTIL_Remove(itemToCheck)
					}
				}
			}
			
			// Set base stats equal to main meepo stats
			meepo.SetBaseStrength(mainMeepo.GetStrength())
			meepo.SetBaseAgility(mainMeepo.GetAgility())
			meepo.SetBaseIntellect(mainMeepo.GetIntellect())
			meepo.CalculateStatBonus()
			
			while(meepo.GetLevel() < mainMeepo.GetLevel()) {
				meepo.AddExperience(10,1,false,false)
			}
		} else {
			LevelAbilitiesForAllMeepos(meepo)
		}
		
	}

	// Use this to only kill the main meepo and hide the others
	OnTakeDamage(keys:{inflictor:CDOTABaseAbility, unit:CDOTA_BaseNPC,target:CDOTA_BaseNPC}) {
		let mainMeepo = <CDOTA_BaseNPC_Hero>this.GetCaster()
		let parent = <CDOTA_BaseNPC_Hero>this.GetParent()
		if (keys.unit == parent) {
			if (parent.GetHealth() < 0) {
				if (parent != this.GetCaster()) {
					// Move the main hero to this location to grant exp etc, then move back in case of aegis/bloodstone
					let oldLocation = mainMeepo.GetAbsOrigin()
					mainMeepo.SetAbsOrigin(parent.GetAbsOrigin())
					mainMeepo.Kill(keys.inflictor,keys.attacker)
					mainMeepo.SetAbsOrigin(oldLocation)

					// Make sure the hero survives this
					parent.SetHealth(parent.GetMaxHealth())
				}
				for (let meepo of GetAllMeepos(mainMeepo)) {
					if (meepo != mainMeepo) {
						meepo.AddNewModifier(mainMeepo,this.GetAbility(),"modifier_meepo_divided_we_stand_death_lua",{})
					}
				}
			}
		}
	}

	OnRespawn(keys:{unit:CDOTA_BaseNPC_Hero}) {
		let parent = <CDOTA_BaseNPC_Hero> this.GetParent()
		let mainMeepo = <CDOTA_BaseNPC_Hero> this.GetCaster()
		if (keys.unit == parent && parent == PlayerResource.GetSelectedHeroEntity(this.GetParent().GetPlayerOwnerID())) {
			for (let meepo of GetAllMeepos(mainMeepo)) {
				if (meepo != mainMeepo) {  
					meepo.RemoveModifierByName("modifier_meepo_divided_we_stand_death_lua")
					meepo.RemoveNoDraw()
					FindClearSpaceForUnit(meepo,this.GetParent().GetAbsOrigin(),true)
					meepo.AddNewModifier(meepo, this.GetAbility(), "modifier_phased", {duration:0.1})
				}
			}
		}
	}
}
// Use this to fake deaths
class modifier_meepo_divided_we_stand_death_lua extends CDOTA_Modifier_Lua {
	IsPermanent() { return false}
	IsHidden() { return true }

	OnCreated() {
		if (IsServer()) {
			this.GetParent().StartGesture(GameActivity_t.ACT_DOTA_DIE)
			this.StartIntervalThink(1.5)
		}
	}

	OnIntervalThink() {
		let parent = this.GetParent()
		parent.RemoveGesture(GameActivity_t.ACT_DOTA_DIE)
		parent.AddNoDraw()
		if (parent.GetTeamNumber() == DOTATeam_t.DOTA_TEAM_GOODGUYS) {
			parent.SetAbsOrigin(Vector(-10000,-10000,0))
		} else {
			parent.SetAbsOrigin(Vector(10000,10000,0))
		}
		this.StartIntervalThink(-1) 
	}

	CheckState() {
		return {
			[modifierstate.MODIFIER_STATE_STUNNED]: true,
			[modifierstate.MODIFIER_STATE_UNSELECTABLE]:true,
			[modifierstate.MODIFIER_STATE_INVULNERABLE]:true,
			[modifierstate.MODIFIER_STATE_UNTARGETABLE]:true,
			[modifierstate.MODIFIER_STATE_OUT_OF_GAME]:true,
			[modifierstate.MODIFIER_STATE_NO_HEALTH_BAR]:true,
			[modifierstate.MODIFIER_STATE_NOT_ON_MINIMAP]:true,
		}
	}
}

// LevelAbilityForAllMeepos
// This can't be done in the onupgrade blocks because of talents
function LevelAbilitiesForAllMeepos(caster:CDOTA_BaseNPC_Hero): void {
	let PID = caster.GetPlayerOwnerID()
	let mainMeepo = PlayerResource.GetSelectedHeroEntity(PID)
	
	if (caster == mainMeepo) {
		for (let a=0;a <= caster.GetAbilityCount()-1;a++) {
			let ability: CDOTABaseAbility = caster.GetAbilityByIndex(a) 
			if (ability) {
				for (let meepo of GetAllMeepos(mainMeepo)) {
					let cloneAbility = meepo.FindAbilityByName(ability.GetAbilityName())
					if (ability.GetLevel() > cloneAbility.GetLevel()) {
						cloneAbility.SetLevel(ability.GetLevel())
						meepo.SetAbilityPoints(meepo.GetAbilityPoints()-1)
					} 
					if (ability.GetLevel() < cloneAbility.GetLevel()) {
						ability.SetLevel(cloneAbility.GetLevel())
						mainMeepo.SetAbilityPoints(mainMeepo.GetAbilityPoints()-1)
					}
				}
			}
		}
	}  
}

function GetAllMeepos(caster:CDOTA_BaseNPC_Hero):CDOTA_BaseNPC_Hero[] {
	if (caster.meepoList) { 
		return caster.meepoList
	} else {
		return [caster]
	}
}

function MeepoExperience(filterTable:table): table {
	let PID = <PlayerID> filterTable.player_id_const
	let reason = <EDOTA_ModifyXP_Reason> filterTable.reason_const 
	let experience = <number> filterTable.experience
	let hero = PlayerResource.GetSelectedHeroEntity(PID)
	if (hero && hero.HasAbility("meepo_divided_we_stand_lua") && reason != EDOTA_ModifyXP_Reason.DOTA_ModifyXP_Unspecified) {
		filterTable.experience = 0
		hero.AddExperience(experience,EDOTA_ModifyXP_Reason.DOTA_ModifyXP_Unspecified,true,false)
	}
	return filterTable
}

function MeepoOrderFilter(filterTable:table):boolean {
	let entindex_ability = <number>filterTable.entindex_ability
	let sequence_number_const = <number>filterTable.sequence_number_const   
	let queue = <0|1>filterTable.sequence_number_const
	let units = <number[]>filterTable.units
	let entindex_target = <number>filterTable.entindex_target   
	let position = Vector(filterTable.position_y,filterTable.position_y,filterTable.position_z)
	let order_type = <DotaUnitOrder_t>filterTable.order_type   
	let issuer_player_id_const = <PlayerID>filterTable.issuer_player_id_const
	let ability = EntIndexToHScript(entindex_ability)
	let target = EntIndexToHScript(entindex_target)


	for (let entindex_unit of units) {
		let unit = EntIndexToHScript(entindex_unit)
		// Cancel picking up items as clone
		if (unit.HasModifier("modifier_meepo_divided_we_stand_lua") && unit != PlayerResource.GetSelectedHeroEntity(unit.GetPlayerOwnerID())) {
			if (order_type == DotaUnitOrder_t.DOTA_UNIT_ORDER_PICKUP_ITEM) {
				return false
			}
		}
		// Prevent giving items to meepo
		if (target && target.HasModifier && target.HasModifier("modifier_meepo_divided_we_stand_lua") && target != PlayerResource.GetSelectedHeroEntity(target.GetPlayerOwnerID())) {
			if (order_type == DotaUnitOrder_t.DOTA_UNIT_ORDER_GIVE_ITEM) {
				return false
			}
		}
	}
	return true
}


if (IsServer()) {
	// If you are using an order filter yourself already, copy the meepo related line in there
	GameRules.GetGameModeEntity().SetExecuteOrderFilter(
		function(filterTable):boolean {
			//let meepo = require('heroes/meepo/divided_we_stand')
			if (MeepoOrderFilter) {
				if (!MeepoOrderFilter(filterTable)) {
					return false
				}
			}
			return true
		},
		GameRules.GetGameModeEntity()
	)

	// If you are using an experience filter yourself already, copy the meepo related line in there
	GameRules.GetGameModeEntity().SetModifyExperienceFilter(
		function(filterTable):boolean {
			//let meepo = require('heroes/meepo/divided_we_stand')
			if (MeepoExperience) {
				filterTable = MeepoExperience(filterTable)
			}
			return true
		},
		GameRules.GetGameModeEntity()
	)
}