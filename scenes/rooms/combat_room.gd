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

const PLAYER_SCENE = preload("res://scenes/player/player.tscn")


func _ready() -> void:
	if game_manager:
		game_manager.all_enemies_defeated.connect(_on_all_enemies_defeated)
	
	_spawn_player()
	
	if auto_start:
		start_room()


func _spawn_player() -> void:
	player_instance = PLAYER_SCENE.instantiate()
	add_child(player_instance)
	
	if player_spawn:
		player_instance.global_position = player_spawn.global_position
	else:
		player_instance.global_position = Vector3(0, 1, 0)


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
