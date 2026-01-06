extends Node
## Global game state manager - tracks run progress, player stats, and room flow

# Signals
signal combo_changed(new_value: int)
signal combo_reset()
signal combo_milestone_reached(milestone: int)
signal player_health_changed(new_health: int, max_health: int)
signal player_died()
signal room_cleared()
signal run_started()
signal run_ended(victory: bool)
signal upgrade_selection_started()
signal upgrade_selection_ended()

# Player Stats (base values)
const BASE_MAX_HEALTH: int = 100
const BASE_BLINK_COOLDOWN: float = 2.0
const BASE_BLINK_RANGE: float = 15.0
const BASE_DASH_COOLDOWN: float = 1.5
const BASE_DASH_DISTANCE: float = 5.0
const BASE_ATTACK_DAMAGE: int = 10
const BASE_COMBO_DECAY_TIME: float = 3.0

# Current run stats (modified by upgrades)
var max_health: int = BASE_MAX_HEALTH
var current_health: int = BASE_MAX_HEALTH
var blink_cooldown: float = BASE_BLINK_COOLDOWN
var blink_range: float = BASE_BLINK_RANGE
var dash_cooldown: float = BASE_DASH_COOLDOWN
var dash_distance: float = BASE_DASH_DISTANCE
var attack_damage: int = BASE_ATTACK_DAMAGE
var combo_decay_time: float = BASE_COMBO_DECAY_TIME
var finisher_damage_multiplier: float = 1.5
var healing_multiplier: float = 1.0

# Combo system
var current_combo: int = 0
var max_combo_this_run: int = 0
var combo_milestones: Array[int] = [10, 20, 30, 50, 75, 100]
var reached_milestones: Array[int] = []

# Run progress
var current_room_index: int = 0
var rooms_cleared: int = 0
var perfect_rooms: int = 0
var took_damage_this_room: bool = false
var total_enemies_killed: int = 0
var run_start_time: float = 0.0
var run_time: float = 0.0
var is_run_active: bool = false

# Room definitions
var room_sequence: Array[String] = [
	"res://scenes/rooms/room_01.tscn",
	"res://scenes/rooms/room_02.tscn",
	"res://scenes/rooms/room_03.tscn",
	"res://scenes/rooms/room_04.tscn",
	"res://scenes/rooms/room_05.tscn",
	"res://scenes/rooms/room_06.tscn",
	"res://scenes/rooms/room_07.tscn",
	"res://scenes/rooms/room_08.tscn",
	"res://scenes/rooms/room_09.tscn",
	"res://scenes/rooms/room_10.tscn",
]

var upgrade_after_rooms: Array[int] = [3, 6, 9]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if is_run_active:
		run_time += delta


func start_new_run() -> void:
	max_health = BASE_MAX_HEALTH
	current_health = BASE_MAX_HEALTH
	blink_cooldown = BASE_BLINK_COOLDOWN
	blink_range = BASE_BLINK_RANGE
	dash_cooldown = BASE_DASH_COOLDOWN
	dash_distance = BASE_DASH_DISTANCE
	attack_damage = BASE_ATTACK_DAMAGE
	combo_decay_time = BASE_COMBO_DECAY_TIME
	finisher_damage_multiplier = 1.5
	healing_multiplier = 1.0
	
	current_combo = 0
	max_combo_this_run = 0
	reached_milestones.clear()
	
	current_room_index = 0
	rooms_cleared = 0
	perfect_rooms = 0
	took_damage_this_room = false
	total_enemies_killed = 0
	run_start_time = Time.get_ticks_msec() / 1000.0
	run_time = 0.0
	is_run_active = true
	
	UpgradeManager.reset_upgrades()
	run_started.emit()
	load_current_room()


func add_combo(amount: int = 1) -> void:
	current_combo += amount
	if current_combo > max_combo_this_run:
		max_combo_this_run = current_combo
	combo_changed.emit(current_combo)
	
	for milestone in combo_milestones:
		if current_combo >= milestone and milestone not in reached_milestones:
			reached_milestones.append(milestone)
			combo_milestone_reached.emit(milestone)


func reset_combo(from_damage: bool = false) -> void:
	if current_combo > 0:
		current_combo = 0
		combo_changed.emit(current_combo)
		if from_damage:
			combo_reset.emit()
	reached_milestones.clear()


func take_damage(amount: int) -> void:
	current_health -= amount
	current_health = max(0, current_health)
	took_damage_this_room = true
	reset_combo(true)
	player_health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		player_died.emit()
		end_run(false)


func heal(amount: int) -> void:
	var heal_amount = int(amount * healing_multiplier)
	current_health = min(current_health + heal_amount, max_health)
	player_health_changed.emit(current_health, max_health)


func enemy_killed() -> void:
	total_enemies_killed += 1


func on_room_cleared() -> void:
	rooms_cleared += 1
	if not took_damage_this_room:
		perfect_rooms += 1
	room_cleared.emit()
	
	if rooms_cleared in upgrade_after_rooms:
		show_upgrade_selection()
	else:
		advance_to_next_room()


func show_upgrade_selection() -> void:
	upgrade_selection_started.emit()


func advance_to_next_room() -> void:
	current_room_index += 1
	took_damage_this_room = false
	
	if current_room_index >= room_sequence.size():
		end_run(true)
	else:
		load_current_room()


func load_current_room() -> void:
	var room_path = room_sequence[current_room_index]
	get_tree().change_scene_to_file(room_path)


func end_run(victory: bool) -> void:
	is_run_active = false
	run_ended.emit(victory)
	get_tree().change_scene_to_file("res://scenes/ui/results_screen.tscn")


func get_current_room_number() -> int:
	return current_room_index + 1


func calculate_score() -> Dictionary:
	var time_bonus = max(0, 1000 - int(run_time))
	var combo_bonus = max_combo_this_run * 100
	var perfect_bonus = perfect_rooms * 500
	var kill_score = total_enemies_killed * 50
	var total = time_bonus + combo_bonus + perfect_bonus + kill_score
	
	return {
		"total": total,
		"time_bonus": time_bonus,
		"combo_bonus": combo_bonus,
		"perfect_bonus": perfect_bonus,
		"kill_score": kill_score,
		"max_combo": max_combo_this_run,
		"perfect_rooms": perfect_rooms,
		"rooms_cleared": rooms_cleared,
		"run_time": run_time
	}


func get_grade(score: int) -> String:
	if score >= 10000:
		return "S"
	elif score >= 7500:
		return "A"
	elif score >= 5000:
		return "B"
	elif score >= 2500:
		return "C"
	else:
		return "D"
