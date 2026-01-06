extends Node
class_name GameManager
## Manages overall game flow within a room

signal all_enemies_defeated
signal wave_started(wave_number: int)

@export var spawn_points: Array[Node3D] = []
@export var enemy_spawns: Array[EnemySpawnData] = []

var active_enemies: Array[Node3D] = []
var current_wave: int = 0
var max_wave: int = 0
var room_started: bool = false


func _ready() -> void:
	# Calculate max wave number
	for spawn_data in enemy_spawns:
		if spawn_data.wave_group > max_wave:
			max_wave = spawn_data.wave_group
	
	# Find and register any pre-placed enemies in the scene
	await get_tree().process_frame
	_register_existing_enemies()


func _register_existing_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy not in active_enemies:
			active_enemies.append(enemy)
			if enemy.has_signal("died"):
				enemy.died.connect(_on_enemy_died.bind(enemy))


func start_room() -> void:
	if room_started:
		return
	room_started = true
	spawn_wave(0)


func spawn_wave(wave_number: int) -> void:
	current_wave = wave_number
	wave_started.emit(wave_number)
	
	for spawn_data in enemy_spawns:
		if spawn_data.wave_group == wave_number:
			if spawn_data.spawn_delay > 0 and get_tree():
				await get_tree().create_timer(spawn_data.spawn_delay).timeout
			spawn_enemy(spawn_data)


func spawn_enemy(spawn_data: EnemySpawnData) -> void:
	if spawn_data.enemy_scene == null:
		return
	
	var enemy = spawn_data.enemy_scene.instantiate()
	enemy.global_position = spawn_data.spawn_position
	add_child(enemy)
	active_enemies.append(enemy)
	
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died.bind(enemy))


func _on_enemy_died(enemy: Node3D) -> void:
	active_enemies.erase(enemy)
	GameState.enemy_killed()
	
	if active_enemies.is_empty():
		if current_wave < max_wave:
			spawn_wave(current_wave + 1)
		else:
			all_enemies_defeated.emit()
			GameState.on_room_cleared()


func get_enemies_in_range(position: Vector3, range_distance: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			var dist = position.distance_to(enemy.global_position)
			if dist <= range_distance:
				result.append(enemy)
	return result


func get_closest_enemy(position: Vector3, max_range: float = 100.0) -> Node3D:
	var closest: Node3D = null
	var closest_dist: float = max_range
	
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			var dist = position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy
	
	return closest
