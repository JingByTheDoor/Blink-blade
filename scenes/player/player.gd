extends CharacterBody3D
class_name Player
## Main player controller - handles movement, combat, and abilities

signal attack_hit(target: Node3D)
signal blink_performed(target: Node3D)
signal dash_performed()
signal died()

# Node references
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var mesh: MeshInstance3D = $Mesh
@onready var hitbox: Hitbox = $Hitbox
@onready var blink_target_indicator: Node3D = $BlinkTargetIndicator
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine: StateMachine = $StateMachine

# Movement settings
const GRAVITY: float = 30.0
const MOVE_SPEED: float = 8.0
const JUMP_VELOCITY: float = 10.0
const MOUSE_SENSITIVITY: float = 0.002
const AIR_CONTROL: float = 0.3

# Camera settings
const CAMERA_MIN_ANGLE: float = -80.0
const CAMERA_MAX_ANGLE: float = 70.0

# Combat settings
const COMBO_WINDOW: float = 0.5
const ATTACK_DURATION: float = 0.3
const ATTACK_COOLDOWN: float = 0.1

# State tracking
var current_attack: int = 0
var combo_timer: float = 0.0
var attack_cooldown_timer: float = 0.0
var blink_cooldown_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var is_attacking: bool = false
var is_blinking: bool = false
var is_dashing: bool = false
var can_combo: bool = false
var last_hit_enemy: Node3D = null
var blink_target: Node3D = null
var combo_decay_timer: float = 0.0

# Dash state
var dash_direction: Vector3 = Vector3.ZERO
var dash_timer: float = 0.0
const DASH_DURATION: float = 0.2


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hitbox.hit_detected.connect(_on_hitbox_hit)
	
	# Initialize from GameState
	_sync_from_game_state()
	GameState.player_health_changed.connect(_on_health_changed)


func _sync_from_game_state() -> void:
	# Sync cooldowns and stats from GameState
	pass


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_handle_camera_rotation(event)
	
	if event.is_action_pressed("pause"):
		_toggle_pause()


func _handle_camera_rotation(event: InputEventMouseMotion) -> void:
	rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
	camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(CAMERA_MIN_ANGLE), deg_to_rad(CAMERA_MAX_ANGLE))


func _toggle_pause() -> void:
	get_tree().paused = !get_tree().paused
	if get_tree().paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_update_blink_target()
	
	if is_dashing:
		_process_dash(delta)
	elif is_blinking:
		pass  # Blink is instant
	else:
		_process_movement(delta)
		_process_combat_input()
	
	move_and_slide()


func _update_timers(delta: float) -> void:
	if blink_cooldown_timer > 0:
		blink_cooldown_timer -= delta
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			current_attack = 0
			can_combo = false
	
	# Combo decay
	if GameState.current_combo > 0:
		combo_decay_timer -= delta
		if combo_decay_timer <= 0:
			GameState.reset_combo(false)


func _process_movement(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Get input direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Apply movement
	var speed_mult = 1.0 if is_on_floor() else AIR_CONTROL
	if direction:
		velocity.x = direction.x * MOVE_SPEED * speed_mult
		velocity.z = direction.z * MOVE_SPEED * speed_mult
	else:
		velocity.x = move_toward(velocity.x, 0, MOVE_SPEED * 0.5)
		velocity.z = move_toward(velocity.z, 0, MOVE_SPEED * 0.5)


func _process_combat_input() -> void:
	# Light attack (3-hit combo)
	if Input.is_action_just_pressed("light_attack") and not is_attacking:
		if attack_cooldown_timer <= 0:
			_perform_attack()
	
	# Blink
	if Input.is_action_just_pressed("blink") and blink_cooldown_timer <= 0 and blink_target != null:
		_perform_blink()
	
	# Dash
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
		_perform_dash()


func _perform_attack() -> void:
	is_attacking = true
	current_attack += 1
	if current_attack > 3:
		current_attack = 1
	
	var damage = GameState.attack_damage
	if current_attack == 3:
		damage = int(damage * GameState.finisher_damage_multiplier)
	
	hitbox.activate(damage)
	AudioManager.play_sfx("attack_" + str(current_attack))
	
	# Play attack animation
	var anim_name = "attack_" + str(current_attack)
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	
	# Reset combo window
	combo_timer = COMBO_WINDOW
	can_combo = true
	
	# Attack duration
	await get_tree().create_timer(ATTACK_DURATION).timeout
	hitbox.deactivate()
	is_attacking = false
	attack_cooldown_timer = ATTACK_COOLDOWN
	
	# If this was the finisher, add a longer cooldown
	if current_attack == 3:
		attack_cooldown_timer *= 2


func _perform_blink() -> void:
	if blink_target == null:
		return
	
	is_blinking = true
	blink_cooldown_timer = GameState.blink_cooldown
	
	# Calculate position behind target
	var target_pos = blink_target.global_position
	var dir_to_target = (target_pos - global_position).normalized()
	var blink_position = target_pos - dir_to_target * 2.0
	blink_position.y = target_pos.y
	
	# Track if we switched targets (for combo bonus)
	var switched_target = last_hit_enemy != null and last_hit_enemy != blink_target
	
	# Teleport
	global_position = blink_position
	look_at(target_pos, Vector3.UP)
	
	AudioManager.play_sfx("blink")
	blink_performed.emit(blink_target)
	
	# Extend combo timer if we have the upgrade
	var combo_extend = UpgradeManager.get_upgrade_effect("combo_keeper", "blink_extends_combo", 0.0)
	if combo_extend > 0:
		combo_decay_timer += combo_extend
	
	# Target switch bonus
	if switched_target and UpgradeManager.has_upgrade("combo_gain"):
		GameState.add_combo(1)
	
	is_blinking = false


func _perform_dash() -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if input_dir.length() < 0.1:
		dash_direction = -transform.basis.z
	else:
		dash_direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	is_dashing = true
	dash_timer = DASH_DURATION
	dash_cooldown_timer = GameState.dash_cooldown
	
	AudioManager.play_sfx("dash")
	dash_performed.emit()


func _process_dash(delta: float) -> void:
	dash_timer -= delta
	var dash_speed = GameState.dash_distance / DASH_DURATION
	velocity = dash_direction * dash_speed
	velocity.y = 0
	
	if dash_timer <= 0:
		is_dashing = false
		velocity = Vector3.ZERO


func _update_blink_target() -> void:
	# Find closest enemy in range
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_method("get_closest_enemy"):
		blink_target = game_manager.get_closest_enemy(global_position, GameState.blink_range)
	else:
		blink_target = _find_closest_enemy_fallback()
	
	# Update target indicator
	if blink_target_indicator:
		if blink_target != null and blink_cooldown_timer <= 0:
			blink_target_indicator.visible = true
			blink_target_indicator.global_position = blink_target.global_position + Vector3.UP * 2
		else:
			blink_target_indicator.visible = false


func _find_closest_enemy_fallback() -> Node3D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node3D = null
	var closest_dist: float = GameState.blink_range
	
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = enemy
	
	return closest


func _on_hitbox_hit(target: Node3D) -> void:
	if target.is_in_group("enemies") and target.has_method("take_damage"):
		var damage = GameState.attack_damage
		if current_attack == 3:
			damage = int(damage * GameState.finisher_damage_multiplier)
		
		target.take_damage(damage)
		last_hit_enemy = target
		
		# Add combo
		GameState.add_combo(1)
		combo_decay_timer = GameState.combo_decay_time
		
		AudioManager.play_sfx("hit_enemy")
		attack_hit.emit(target)


func take_damage(amount: int) -> void:
	GameState.take_damage(amount)
	AudioManager.play_sfx("hit_player")
	
	# Visual feedback
	_flash_damage()


func _flash_damage() -> void:
	if mesh and mesh.get_surface_override_material(0):
		var mat = mesh.get_surface_override_material(0) as StandardMaterial3D
		if mat:
			var original_color = mat.albedo_color
			mat.albedo_color = Color.RED
			await get_tree().create_timer(0.1).timeout
			mat.albedo_color = original_color


func _on_health_changed(new_health: int, max_health: int) -> void:
	if new_health <= 0:
		_die()


func _die() -> void:
	died.emit()
	# Death handling is done by GameState
