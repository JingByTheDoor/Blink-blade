extends Node3D
## Base room controller - manages enemy spawning and room completion

signal all_enemies_defeated()

@export var room_number: int = 1
@export var spawn_data: Array[EnemySpawnData] = []
@export var next_room_path: String = ""

var active_enemies: Array[Node] = []
var current_wave: int = 0
var all_waves_spawned: bool = false
var room_cleared: bool = false

@onready var spawn_points: Node3D = $SpawnPoints
@onready var door: Node3D = $Door
@onready var player_spawn: Marker3D = $PlayerSpawn


func _ready() -> void:
	# Close door initially
	if door:
		door.visible = true
	
	# Spawn player
	_spawn_player()
	
	# Generate spawn data if not set
	if spawn_data.is_empty():
		_generate_spawn_data()
	
	# Start spawning enemies
	_spawn_wave(0)


func _spawn_player() -> void:
	var player_scene = load("res://scenes/player/player.tscn")
	if player_scene and player_spawn:
		var player = player_scene.instantiate()
		add_child(player)
		player.global_position = player_spawn.global_position
		player.add_to_group("player")


func _spawn_wave(wave_num: int) -> void:
	current_wave = wave_num
	var has_spawned = false
	
	for data in spawn_data:
		if data.wave_group == wave_num:
			has_spawned = true
			_spawn_enemy_delayed(data)
	
	if not has_spawned:
		all_waves_spawned = true


func _spawn_enemy_delayed(data: EnemySpawnData) -> void:
	if data.spawn_delay > 0:
		await get_tree().create_timer(data.spawn_delay).timeout
	
	if data.enemy_scene:
		var enemy = data.enemy_scene.instantiate()
		add_child(enemy)
		enemy.global_position = data.spawn_position
		enemy.died.connect(_on_enemy_died.bind(enemy))
		active_enemies.append(enemy)


func _process(_delta: float) -> void:
	if room_cleared:
		return
	
	# Check if all enemies in current wave are defeated
	if active_enemies.size() == 0 and not all_waves_spawned:
		_spawn_wave(current_wave + 1)
	
	# Check if all waves spawned and all enemies defeated
	if active_enemies.size() == 0 and all_waves_spawned and not room_cleared:
		_on_room_cleared()


func _on_enemy_died(enemy: Node) -> void:
	if enemy in active_enemies:
		active_enemies.erase(enemy)


func _on_room_cleared() -> void:
	room_cleared = true
	all_enemies_defeated.emit()
	
	# Open door
	if door:
		var tween = create_tween()
		tween.tween_property(door, "position:y", door.position.y + 5, 1.0)
	
	# Notify game state
	GameState.on_room_cleared()


func _generate_spawn_data() -> void:
	var grunt_scene = preload("res://scenes/enemies/grunt.tscn")
	var heavy_scene = preload("res://scenes/enemies/heavy.tscn")
	
	var spawn_point_nodes = spawn_points.get_children()
	if spawn_point_nodes.is_empty():
		return
	
	# Room 1-3: Grunts only (3, 4, 5 enemies)
	if room_number <= 3:
		var enemy_count = 2 + room_number
		for i in range(enemy_count):
			var data = EnemySpawnData.new()
			data.enemy_scene = grunt_scene
			data.spawn_position = spawn_point_nodes[i % spawn_point_nodes.size()].global_position
			data.wave_group = 0
			spawn_data.append(data)
	
	# Room 4-6: Mix of Grunts and Heavies
	elif room_number <= 6:
		var grunt_count = 3 + (room_number - 4)
		var heavy_count = room_number - 3
		
		for i in range(grunt_count):
			var data = EnemySpawnData.new()
			data.enemy_scene = grunt_scene
			data.spawn_position = spawn_point_nodes[i % spawn_point_nodes.size()].global_position
			data.wave_group = 0
			spawn_data.append(data)
		
		for i in range(heavy_count):
			var data = EnemySpawnData.new()
			data.enemy_scene = heavy_scene
			data.spawn_position = spawn_point_nodes[(i + grunt_count) % spawn_point_nodes.size()].global_position
			data.wave_group = 0
			spawn_data.append(data)
	
	# Room 7-9: More Heavies, multi-wave spawns
	elif room_number <= 9:
		# Wave 1
		for i in range(2):
			var data = EnemySpawnData.new()
			data.enemy_scene = grunt_scene
			data.spawn_position = spawn_point_nodes[i % spawn_point_nodes.size()].global_position
			data.wave_group = 0
			spawn_data.append(data)
		
		for i in range(2):
			var data = EnemySpawnData.new()
			data.enemy_scene = heavy_scene
			data.spawn_position = spawn_point_nodes[(i + 2) % spawn_point_nodes.size()].global_position
			data.wave_group = 0
			spawn_data.append(data)
		
		# Wave 2
		for i in range(room_number - 6):
			var data = EnemySpawnData.new()
			data.enemy_scene = heavy_scene
			data.spawn_position = spawn_point_nodes[i % spawn_point_nodes.size()].global_position
			data.wave_group = 1
			data.spawn_delay = 1.0
			spawn_data.append(data)
	
	# Room 10: Boss room with many enemies
	elif room_number == 10:
		# Wave 1: Mixed
		for i in range(3):
			var data = EnemySpawnData.new()
			data.enemy_scene = grunt_scene
			data.spawn_position = spawn_point_nodes[i % spawn_point_nodes.size()].global_position
			data.wave_group = 0
			spawn_data.append(data)
		
		for i in range(2):
			var data = EnemySpawnData.new()
			data.enemy_scene = heavy_scene
			data.spawn_position = spawn_point_nodes[(i + 3) % spawn_point_nodes.size()].global_position
			data.wave_group = 0
			spawn_data.append(data)
		
		# Wave 2: More reinforcements
		for i in range(2):
			var data = EnemySpawnData.new()
			data.enemy_scene = grunt_scene
			data.spawn_position = spawn_point_nodes[i % spawn_point_nodes.size()].global_position
			data.wave_group = 1
			data.spawn_delay = 1.0
			spawn_data.append(data)
		
		for i in range(2):
			var data = EnemySpawnData.new()
			data.enemy_scene = heavy_scene
			data.spawn_position = spawn_point_nodes[(i + 2) % spawn_point_nodes.size()].global_position
			data.wave_group = 1
			data.spawn_delay = 1.5
			spawn_data.append(data)
