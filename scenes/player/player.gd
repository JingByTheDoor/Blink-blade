extends CharacterBody3D
## Player controller with movement, combat, blink, and dash abilities

const SPEED: float = 8.0
const JUMP_VELOCITY: float = 4.5
const GRAVITY: float = 20.0
const MOUSE_SENSITIVITY: float = 0.003
const CAMERA_MIN_ANGLE: float = -60.0
const CAMERA_MAX_ANGLE: float = 60.0

# Attack combo
var attack_combo_index: int = 0
var attack_timer: float = 0.0
const ATTACK_COMBO_WINDOW: float = 0.5
const ATTACK_DURATIONS: Array[float] = [0.3, 0.3, 0.5]

# Blink ability
var blink_cooldown_timer: float = 0.0
var can_blink: bool = true

# Dash ability
var dash_cooldown_timer: float = 0.0
var can_dash: bool = true
var is_dashing: bool = false
var dash_timer: float = 0.0
const DASH_DURATION: float = 0.2
var dash_direction: Vector3 = Vector3.ZERO

# Combo decay
var combo_decay_timer: float = 0.0

# Camera
var camera_rotation_x: float = 0.0

# References
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var mesh: MeshInstance3D = $Mesh
@onready var hitbox: Hitbox = $Hitbox
@onready var state_machine: StateMachine = $StateMachine


func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Set up collision layers
	collision_layer = 2  # Player layer
	collision_mask = 1 | 4  # World + Enemy
	
	# Set up hitbox
	hitbox.collision_layer = 8  # PlayerHitbox layer
	hitbox.collision_mask = 4  # Enemy layer
	hitbox.deactivate()
	hitbox.hit_detected.connect(_on_hitbox_hit_detected)
	
	# Connect to game state signals
	GameState.player_died.connect(_on_player_died)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Horizontal rotation (yaw)
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		
		# Vertical rotation (pitch)
		camera_rotation_x -= event.relative.y * MOUSE_SENSITIVITY
		camera_rotation_x = clamp(camera_rotation_x, deg_to_rad(CAMERA_MIN_ANGLE), deg_to_rad(CAMERA_MAX_ANGLE))
		camera_pivot.rotation.x = camera_rotation_x


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	
	if not is_dashing:
		_handle_movement(delta)
		_handle_input()
	else:
		_handle_dash(delta)
	
	move_and_slide()


func _update_timers(delta: float) -> void:
	# Attack combo timer
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			attack_combo_index = 0
	
	# Blink cooldown
	if blink_cooldown_timer > 0:
		blink_cooldown_timer -= delta
		if blink_cooldown_timer <= 0:
			can_blink = true
	
	# Dash cooldown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0:
			can_dash = true
	
	# Combo decay timer
	if GameState.current_combo > 0:
		combo_decay_timer += delta
		if combo_decay_timer >= GameState.combo_decay_time:
			GameState.reset_combo(false)
			combo_decay_timer = 0.0


func _handle_movement(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Get input direction
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Calculate movement direction relative to camera
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)


func _handle_input() -> void:
	# Light attack
	if Input.is_action_just_pressed("light_attack"):
		_perform_light_attack()
	
	# Blink
	if Input.is_action_just_pressed("blink") and can_blink:
		_perform_blink()
	
	# Dash
	if Input.is_action_just_pressed("dash") and can_dash:
		_perform_dash()
	
	# Pause
	if Input.is_action_just_pressed("pause"):
		_toggle_pause()


func _perform_light_attack() -> void:
	# Reset combo if window expired
	if attack_timer <= 0:
		attack_combo_index = 0
	
	# Determine damage
	var damage: int = GameState.attack_damage
	if attack_combo_index == 2:  # Third hit
		damage = int(damage * GameState.finisher_damage_multiplier)
	
	# Activate hitbox
	hitbox.activate(damage)
	
	# Brief window for hitbox to be active
	await get_tree().create_timer(0.1).timeout
	hitbox.deactivate()
	
	# Advance combo
	attack_combo_index = (attack_combo_index + 1) % 3
	attack_timer = ATTACK_COMBO_WINDOW
	
	# Visual feedback (simple rotation for now)
	var tween = create_tween()
	tween.tween_property(mesh, "rotation:y", mesh.rotation.y + PI / 2, 0.15)


func _perform_blink() -> void:
	# Find nearest enemy
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_enemy: Node3D = null
	var nearest_distance: float = GameState.blink_range
	
	for enemy in enemies:
		if enemy is Node3D:
			var distance = global_position.distance_to(enemy.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_enemy = enemy
	
	if nearest_enemy:
		# Teleport to offset position near enemy
		var offset_dir = (global_position - nearest_enemy.global_position).normalized()
		var target_pos = nearest_enemy.global_position + offset_dir * 2.0
		global_position = target_pos
		
		# Extend combo timer if upgrade exists
		if UpgradeManager.has_upgrade("combo_keeper"):
			var extension = UpgradeManager.get_upgrade_effect("combo_keeper", "blink_extends_combo", 0.0)
			combo_decay_timer = max(0, combo_decay_timer - extension)
		
		# Visual effect
		_spawn_blink_effect()
	
	# Set cooldown
	can_blink = false
	blink_cooldown_timer = GameState.blink_cooldown


func _perform_dash() -> void:
	# Get dash direction
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	if input_dir.length() > 0:
		dash_direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	else:
		# Dash backward if no input
		dash_direction = -transform.basis.z
	
	is_dashing = true
	dash_timer = DASH_DURATION
	can_dash = false
	dash_cooldown_timer = GameState.dash_cooldown


func _handle_dash(delta: float) -> void:
	dash_timer -= delta
	
	if dash_timer > 0:
		# Move in dash direction
		velocity = dash_direction * GameState.dash_distance / DASH_DURATION
		velocity.y = 0  # Keep grounded during dash
	else:
		is_dashing = false


func _spawn_blink_effect() -> void:
	# Load and spawn blink effect
	var effect_scene = load("res://scenes/effects/blink_effect.tscn")
	if effect_scene:
		var effect = effect_scene.instantiate()
		get_parent().add_child(effect)
		effect.global_position = global_position


func take_damage(amount: int, knockback: Vector3 = Vector3.ZERO) -> void:
	GameState.take_damage(amount)
	
	# Apply knockback
	velocity += knockback
	
	# Reset combo decay timer
	combo_decay_timer = 0.0


func _on_player_died() -> void:
	# Disable input
	set_physics_process(false)
	set_process_input(false)


func _toggle_pause() -> void:
	var pause_menu_scene = load("res://scenes/ui/pause_menu.tscn")
	if pause_menu_scene:
		var pause_menu = pause_menu_scene.instantiate()
		get_tree().root.add_child(pause_menu)
		get_tree().paused = true


# Connect hitbox to combo system
func _on_hitbox_hit_detected(target: Node3D) -> void:
	GameState.add_combo(1)
	combo_decay_timer = 0.0  # Reset decay timer on hit
	
	# Spawn hit effect
	_spawn_hit_effect(target.global_position)


func _spawn_hit_effect(pos: Vector3) -> void:
	var effect_scene = load("res://scenes/effects/hit_effect.tscn")
	if effect_scene:
		var effect = effect_scene.instantiate()
		get_parent().add_child(effect)
		effect.global_position = pos
