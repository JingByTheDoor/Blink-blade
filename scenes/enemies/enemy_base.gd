extends CharacterBody3D
class_name EnemyBase
## Base class for all enemies

signal died()
signal damaged(amount: int)

@export var max_health: int = 30
@export var move_speed: float = 3.0
@export var attack_damage: int = 10
@export var attack_range: float = 2.0
@export var detection_range: float = 20.0
@export var attack_cooldown: float = 1.5

var current_health: int = 0
var player: CharacterBody3D = null
var is_dead: bool = false
var can_attack: bool = true
var attack_timer: float = 0.0
var is_staggered: bool = false
var stagger_timer: float = 0.0
const STAGGER_DURATION: float = 0.3

@onready var state_machine: StateMachine = $StateMachine
@onready var mesh: MeshInstance3D = $Mesh
@onready var hurtbox: Hurtbox = $Hurtbox


func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	
	# Set up collision layers
	collision_layer = 4  # Enemy layer
	collision_mask = 1 | 2  # World + Player
	
	# Set up hurtbox
	hurtbox.owner_node = self
	hurtbox.collision_layer = 4  # Enemy layer
	hurtbox.collision_mask = 8  # PlayerHitbox layer
	
	# Find player
	await get_tree().process_frame
	_find_player()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Update timers
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true
	
	if is_staggered:
		stagger_timer -= delta
		if stagger_timer <= 0:
			is_staggered = false
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	
	move_and_slide()


func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]


func take_damage(amount: int, knockback: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
	
	current_health -= amount
	damaged.emit(amount)
	
	# Apply knockback
	velocity += knockback
	
	# Stagger
	is_staggered = true
	stagger_timer = STAGGER_DURATION
	
	# Flash effect
	_flash_damage()
	
	if current_health <= 0:
		_die()


func _flash_damage() -> void:
	# Simple flash effect
	if mesh:
		var material = mesh.get_active_material(0)
		if material:
			material = material.duplicate()
			mesh.set_surface_override_material(0, material)
			
			var tween = create_tween()
			tween.tween_property(material, "albedo_color", Color.RED, 0.1)
			tween.tween_property(material, "albedo_color", Color.WHITE, 0.1)


func _die() -> void:
	is_dead = true
	died.emit()
	GameState.enemy_killed()
	
	# Simple death animation
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.3)
	tween.tween_callback(queue_free)


func get_distance_to_player() -> float:
	if player:
		return global_position.distance_to(player.global_position)
	return INF


func get_direction_to_player() -> Vector3:
	if player:
		return (player.global_position - global_position).normalized()
	return Vector3.ZERO


func is_player_in_range(range: float) -> bool:
	return get_distance_to_player() <= range


func move_toward_player(delta: float, speed: float) -> void:
	if is_staggered or not player:
		return
	
	var direction = get_direction_to_player()
	direction.y = 0
	direction = direction.normalized()
	
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	# Face player
	if direction.length() > 0:
		look_at(player.global_position, Vector3.UP)


func perform_attack() -> void:
	if not can_attack or not player:
		return
	
	can_attack = false
	attack_timer = attack_cooldown
	
	# Check if player is in range
	if is_player_in_range(attack_range):
		# Deal damage to player
		if player.has_method("take_damage"):
			var direction = get_direction_to_player()
			var knockback = direction * 3.0
			player.take_damage(attack_damage, knockback)


# State machine methods - to be overridden by subclasses
func _state_idle_enter() -> void:
	pass


func _state_idle_physics(delta: float) -> void:
	if is_player_in_range(detection_range):
		state_machine.change_state("chase")


func _state_chase_enter() -> void:
	pass


func _state_chase_physics(delta: float) -> void:
	if is_player_in_range(attack_range):
		state_machine.change_state("attack")
	else:
		move_toward_player(delta, move_speed)


func _state_attack_enter() -> void:
	perform_attack()


func _state_attack_physics(delta: float) -> void:
	if can_attack:
		if is_player_in_range(attack_range):
			state_machine.change_state("attack")
		else:
			state_machine.change_state("chase")
