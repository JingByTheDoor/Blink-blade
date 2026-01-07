extends Node3D
class_name CombatRoom
## Base class for all combat rooms

signal room_started()
signal room_completed()

@export var room_name: String = "Combat Room"
@export var auto_start: bool = true

@onready var player_spawn: Marker3D = $PlayerSpawn
@onready var game_manager: GameManager = $GameManager
@onready var exit_door: Node3D = $ExitDoor

var player_instance: Node3D = null
var room_active: bool = false
var hud_instance: CanvasLayer = null
var pause_menu_instance: CanvasLayer = null
var upgrade_screen_instance: Control = null

const PLAYER_SCENE = preload("res://scenes/player/player.tscn")
const HUD_SCENE = preload("res://scenes/ui/hud.tscn")
const PAUSE_MENU_SCENE = preload("res://scenes/ui/pause_menu.tscn")
const UPGRADE_SCREEN_SCENE = preload("res://scenes/ui/upgrade_screen.tscn")
const OBSTACLES_BY_ROOM := {
	"Training Grounds": [
		{"size": Vector3(4, 2, 4), "position": Vector3(0, 0, 0)},
		{"size": Vector3(6, 2, 2), "position": Vector3(-6, 0, 4)}
	],
	"Gauntlet": [
		{"size": Vector3(8, 2, 2), "position": Vector3(-6, 0, 2)},
		{"size": Vector3(8, 2, 2), "position": Vector3(6, 0, 2)}
	],
	"Heavy Introduction": [
		{"size": Vector3(5, 3, 5), "position": Vector3(0, 0, 0)},
		{"size": Vector3(3, 2, 7), "position": Vector3(6, 0, 3)}
	],
	"Crossfire": [
		{"size": Vector3(3, 2.5, 3), "position": Vector3(-6, 0, 0)},
		{"size": Vector3(3, 2.5, 3), "position": Vector3(6, 0, 0)},
		{"size": Vector3(3, 2.5, 3), "position": Vector3(0, 0, 6)},
		{"size": Vector3(3, 2.5, 3), "position": Vector3(0, 0, -6)}
	],
	"Swarm": [
		{"size": Vector3(6, 2, 2), "position": Vector3(0, 0, 2)},
		{"size": Vector3(3, 2, 3), "position": Vector3(-6, 0, 0)},
		{"size": Vector3(3, 2, 3), "position": Vector3(6, 0, 0)}
	],
	"Heavy Assault": [
		{"size": Vector3(6, 3, 6), "position": Vector3(0, 0, 0)},
		{"size": Vector3(10, 2, 2), "position": Vector3(0, 0, 6)}
	],
	"Arena": [
		{"size": Vector3(8, 2.5, 8), "position": Vector3(0, 0, 0)},
		{"size": Vector3(4, 2, 4), "position": Vector3(-10, 0, 6)},
		{"size": Vector3(4, 2, 4), "position": Vector3(10, 0, 6)}
	],
	"Encirclement": [
		{"size": Vector3(3, 2.5, 8), "position": Vector3(-6, 0, 0)},
		{"size": Vector3(3, 2.5, 8), "position": Vector3(6, 0, 0)},
		{"size": Vector3(8, 2, 3), "position": Vector3(0, 0, 6)}
	],
	"The Gauntlet": [
		{"size": Vector3(12, 2.5, 2), "position": Vector3(0, 0, 4)},
		{"size": Vector3(12, 2.5, 2), "position": Vector3(0, 0, -4)},
		{"size": Vector3(3, 2, 3), "position": Vector3(-10, 0, 0)}
	],
	"Final Stand": [
		{"size": Vector3(10, 3, 10), "position": Vector3(0, 0, 0)},
		{"size": Vector3(6, 3, 6), "position": Vector3(-12, 0, 8)},
		{"size": Vector3(6, 3, 6), "position": Vector3(12, 0, 8)}
	]
}


func _ready() -> void:
	if game_manager:
		game_manager.all_enemies_defeated.connect(_on_all_enemies_defeated)
	
	_spawn_player()
	_setup_ui()
	_spawn_obstacles()
	
	if auto_start:
		start_room()


func _spawn_player() -> void:
	player_instance = PLAYER_SCENE.instantiate()
	add_child(player_instance)
	
	if player_spawn:
		player_instance.global_position = player_spawn.global_position
	else:
		player_instance.global_position = Vector3(0, 1, 0)


func _setup_ui() -> void:
	# Add HUD
	hud_instance = HUD_SCENE.instantiate()
	add_child(hud_instance)
	
	# Add Pause Menu
	pause_menu_instance = PAUSE_MENU_SCENE.instantiate()
	add_child(pause_menu_instance)
	
	# Add Upgrade Screen
	upgrade_screen_instance = UPGRADE_SCREEN_SCENE.instantiate()
	add_child(upgrade_screen_instance)


func _spawn_obstacles() -> void:
	var environment_root = get_node_or_null("Environment")
	if not environment_root:
		return
	
	var obstacles = OBSTACLES_BY_ROOM.get(room_name, [])
	for i in range(obstacles.size()):
		var obstacle = obstacles[i]
		var size: Vector3 = obstacle["size"]
		var position: Vector3 = obstacle["position"]
		position.y = size.y * 0.5
		
		var body := StaticBody3D.new()
		body.name = "Obstacle_%d" % (i + 1)
		body.collision_layer = 1
		body.position = position
		environment_root.add_child(body)
		
		var shape := BoxShape3D.new()
		shape.size = size
		var collider := CollisionShape3D.new()
		collider.shape = shape
		body.add_child(collider)
		
		var mesh := BoxMesh.new()
		mesh.size = size
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = mesh
		body.add_child(mesh_instance)


func start_room() -> void:
	if room_active:
		return
	
	room_active = true
	room_started.emit()
	AudioManager.play_music("combat")
	
	if game_manager:
		game_manager.start_room()


func _on_all_enemies_defeated() -> void:
	room_completed.emit()
	_open_exit()


func _open_exit() -> void:
	if exit_door:
		AudioManager.play_sfx("door_open")
		# Animate door opening
		var tween = create_tween()
		tween.tween_property(exit_door, "position:y", exit_door.position.y + 3, 0.5)
