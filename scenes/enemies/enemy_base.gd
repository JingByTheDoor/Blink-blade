extends CharacterBody3D
class_name EnemyBase
## Base class for all enemies

signal died()
signal hit_taken(damage: int)

@export var max_health: int = 50
@export var move_speed: float = 4.0
@export var attack_damage: int = 20
@export var attack_range: float = 2.0
@export var detection_range: float = 12.0
@export var attack_cooldown: float = 1.5

@onready var mesh: MeshInstance3D = $Mesh
@onready var hitbox: Area3D = $Hitbox
@onready var health_bar: Node3D = $HealthBar

var current_health: int
var target: Node3D = null
var attack_timer: float = 0.0
var is_attacking: bool = false
var is_dead: bool = false
var knockback_velocity: Vector3 = Vector3.ZERO

const GRAVITY: float = 30.0
const KNOCKBACK_DECAY: float = 10.0


func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")
	_find_player()


func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if not target or not is_instance_valid(target):
		_find_player()
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0
	
	# Decay knockback
	knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, KNOCKBACK_DECAY * delta)
	
	# Update attack timer
	if attack_timer > 0:
		attack_timer -= delta
	
	# AI behavior
	if target and is_instance_valid(target):
		_update_ai(delta)
	
	# Apply movement
	velocity.x = knockback_velocity.x
	velocity.z = knockback_velocity.z
	move_and_slide()


func _update_ai(delta: float) -> void:
	var distance_to_target = global_position.distance_to(target.global_position)
	
	if distance_to_target <= attack_range and attack_timer <= 0:
		_perform_attack()
	elif distance_to_target <= detection_range and not is_attacking:
		_move_toward_target(delta)


func _move_toward_target(delta: float) -> void:
	var direction = (target.global_position - global_position).normalized()
	direction.y = 0
	
	knockback_velocity.x += direction.x * move_speed
	knockback_velocity.z += direction.z * move_speed
	knockback_velocity = knockback_velocity.limit_length(move_speed)
	
	# Face target
	if direction.length() > 0.1:
		look_at(global_position + direction, Vector3.UP)


func _perform_attack() -> void:
	is_attacking = true
	attack_timer = attack_cooldown
	
	# Simple attack - check if player is in range
	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		if distance <= attack_range:
			if target.has_method("take_damage"):
				target.take_damage(attack_damage)
	
	# Attack animation duration
	if get_tree():
		await get_tree().create_timer(0.5).timeout
	is_attacking = false


func take_damage(amount: int, knockback: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
	
	current_health -= amount
	hit_taken.emit(amount)
	
	# Apply knockback
	if knockback.length() > 0.1:
		knockback_velocity = knockback
	elif target:
		var knockback_dir = (global_position - target.global_position).normalized()
		knockback_velocity = knockback_dir * 5.0
	
	# Visual feedback
	_flash_hit()
	_update_health_bar()
	
	if current_health <= 0:
		_die()


func _flash_hit() -> void:
	if mesh and get_tree():
		var mat = mesh.get_active_material(0)
		if mat is StandardMaterial3D:
			var original_color = mat.albedo_color
			mat.albedo_color = Color.WHITE
			await get_tree().create_timer(0.1).timeout
			if is_instance_valid(self) and mat:
				mat.albedo_color = original_color


func _update_health_bar() -> void:
	if health_bar and health_bar.has_method("set_value"):
		health_bar.set_value(float(current_health) / float(max_health))


func _die() -> void:
	is_dead = true
	died.emit()
	AudioManager.play_sfx("enemy_death")
	
	# Death effect
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.3)
	tween.tween_callback(queue_free)
