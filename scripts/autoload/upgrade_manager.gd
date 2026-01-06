extends Node
## Manages available upgrades and applies their effects

signal upgrade_applied(upgrade: UpgradeData)

var all_upgrades: Array[UpgradeData] = []
var active_upgrades: Array[UpgradeData] = []


func _ready() -> void:
	_initialize_upgrades()


func _initialize_upgrades() -> void:
	all_upgrades.clear()
	
	# Blink upgrades
	all_upgrades.append(_create_upgrade("blink_cooldown_1", "Quick Blink", "Reduce blink cooldown by 20%", "blink", {"blink_cooldown_mult": 0.8}))
	all_upgrades.append(_create_upgrade("blink_cooldown_2", "Flash Step", "Reduce blink cooldown by 30%", "blink", {"blink_cooldown_mult": 0.7}))
	all_upgrades.append(_create_upgrade("blink_range", "Long Reach", "Increase blink range by 25%", "blink", {"blink_range_mult": 1.25}))
	all_upgrades.append(_create_upgrade("combo_keeper", "Combo Keeper", "Blink extends combo timer by 0.5 seconds", "blink", {"blink_extends_combo": 0.5}))
	
	# Melee upgrades
	all_upgrades.append(_create_upgrade("damage_1", "Sharp Edge", "Increase attack damage by 15%", "melee", {"attack_damage_mult": 1.15}))
	all_upgrades.append(_create_upgrade("damage_2", "Deadly Strikes", "Increase attack damage by 25%", "melee", {"attack_damage_mult": 1.25}))
	all_upgrades.append(_create_upgrade("finisher_bonus", "Finishing Blow", "Third hit deals 50% more damage", "melee", {"finisher_damage_mult": 1.5}))
	all_upgrades.append(_create_upgrade("attack_speed", "Swift Strikes", "Faster recovery after combo finisher", "melee", {"attack_recovery_mult": 0.75}))
	
	# Survivability upgrades
	all_upgrades.append(_create_upgrade("max_health_1", "Vitality", "Increase max health by 25", "survivability", {"max_health_add": 25}))
	all_upgrades.append(_create_upgrade("max_health_2", "Iron Constitution", "Increase max health by 50", "survivability", {"max_health_add": 50}))
	all_upgrades.append(_create_upgrade("healing_power", "Regeneration", "Healing orbs restore 50% more health", "survivability", {"healing_mult": 1.5}))
	
	# Mobility upgrades
	all_upgrades.append(_create_upgrade("dash_cooldown", "Agile", "Reduce dash cooldown by 25%", "mobility", {"dash_cooldown_mult": 0.75}))
	all_upgrades.append(_create_upgrade("dash_distance", "Long Dash", "Increase dash distance by 30%", "mobility", {"dash_distance_mult": 1.3}))
	
	# Combo upgrades
	all_upgrades.append(_create_upgrade("combo_decay", "Momentum", "Combo decays 25% slower", "combo", {"combo_decay_mult": 1.25}))
	all_upgrades.append(_create_upgrade("combo_gain", "Chain Master", "Gain +1 extra combo on target switches", "combo", {"target_switch_bonus": 1}))


func _create_upgrade(id: String, title: String, description: String, category: String, effects: Dictionary) -> UpgradeData:
	var upgrade = UpgradeData.new()
	upgrade.id = id
	upgrade.title = title
	upgrade.description = description
	upgrade.category = category
	upgrade.effects = effects
	return upgrade


func get_random_upgrades(count: int = 3) -> Array[UpgradeData]:
	var available: Array[UpgradeData] = []
	
	for upgrade in all_upgrades:
		var already_owned = false
		for active in active_upgrades:
			if active.id == upgrade.id:
				already_owned = true
				break
		if not already_owned:
			available.append(upgrade)
	
	available.shuffle()
	
	var result: Array[UpgradeData] = []
	for i in range(min(count, available.size())):
		result.append(available[i])
	
	return result


func apply_upgrade(upgrade: UpgradeData) -> void:
	active_upgrades.append(upgrade)
	var effects = upgrade.effects
	
	if effects.has("blink_cooldown_mult"):
		GameState.blink_cooldown *= effects["blink_cooldown_mult"]
	if effects.has("blink_range_mult"):
		GameState.blink_range *= effects["blink_range_mult"]
	if effects.has("attack_damage_mult"):
		GameState.attack_damage = int(GameState.attack_damage * effects["attack_damage_mult"])
	if effects.has("finisher_damage_mult"):
		GameState.finisher_damage_multiplier *= effects["finisher_damage_mult"]
	if effects.has("max_health_add"):
		var add_amount = effects["max_health_add"]
		GameState.max_health += add_amount
		GameState.current_health += add_amount
	if effects.has("healing_mult"):
		GameState.healing_multiplier *= effects["healing_mult"]
	if effects.has("dash_cooldown_mult"):
		GameState.dash_cooldown *= effects["dash_cooldown_mult"]
	if effects.has("dash_distance_mult"):
		GameState.dash_distance *= effects["dash_distance_mult"]
	if effects.has("combo_decay_mult"):
		GameState.combo_decay_time *= effects["combo_decay_mult"]
	
	upgrade_applied.emit(upgrade)


func has_upgrade(upgrade_id: String) -> bool:
	for upgrade in active_upgrades:
		if upgrade.id == upgrade_id:
			return true
	return false


func get_upgrade_effect(upgrade_id: String, effect_key: String, default_value: Variant) -> Variant:
	for upgrade in active_upgrades:
		if upgrade.id == upgrade_id and upgrade.effects.has(effect_key):
			return upgrade.effects[effect_key]
	return default_value


func reset_upgrades() -> void:
	active_upgrades.clear()
