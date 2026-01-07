extends EnemyBase
class_name EnemyRanger
## Ranged enemy that shoots projectiles at the player from a distance

const PROJECTILE_SCENE = preload("res://scenes/enemies/projectile.tscn")

@export var preferred_distance: float = 8.0  # Try to stay at this range
@export var min_distance: float = 5.0  # Back up if player gets closer
@export var projectile_speed: float = 6.075  # 35% faster than grunt speed (4.5 * 1.35)

var shoot_windup_timer: float = 0.0
var is_winding_up: bool = false
var aim_indicator: MeshInstance3D = null


func _ready() -> void:
	max_health = 40
	move_speed = 3.0
	attack_damage = 15
	attack_range = 12.0  # Can shoot from far away
	detection_range = 15.0
	attack_cooldown = 2.0
	attack_windup_time = 0.5
	super._ready()


func _update_ai(delta: float) -> void:
	if not target or not is_instance_valid(target):
		return
	
	var distance_to_target = global_position.distance_to(target.global_position)
	
	# Handle shooting
	if distance_to_target <= attack_range and attack_timer <= 0 and not is_attacking:
		_start_attack()
	elif not is_attacking:
		# Movement - try to maintain preferred distance
		if distance_to_target < min_distance:
			# Too close, back away
			_move_away_from_target(delta)
		elif distance_to_target > preferred_distance:
			# Too far, move closer
			_move_toward_target(delta)
		else:
			# Good distance, strafe or hold position
			_strafe(delta)
	
	# Always face the target
	_face_target()


func _move_away_from_target(delta: float) -> void:
	var direction = (global_position - target.global_position).normalized()
	direction.y = 0
	
	knockback_velocity.x += direction.x * move_speed
	knockback_velocity.z += direction.z * move_speed
	knockback_velocity = knockback_velocity.limit_length(move_speed)


func _strafe(delta: float) -> void:
	# Slight side-to-side movement
	var to_target = (target.global_position - global_position).normalized()
	var strafe_dir = to_target.cross(Vector3.UP).normalized()
	
	# Alternate strafe direction based on time
	if fmod(Time.get_ticks_msec() / 1000.0, 2.0) < 1.0:
		strafe_dir = -strafe_dir
	
	knockback_velocity.x += strafe_dir.x * move_speed * 0.5
	knockback_velocity.z += strafe_dir.z * move_speed * 0.5
	knockback_velocity = knockback_velocity.limit_length(move_speed * 0.5)


func _face_target() -> void:
	if target and is_instance_valid(target):
		var look_pos = target.global_position
		look_pos.y = global_position.y
		look_at(look_pos, Vector3.UP)


func _start_attack() -> void:
	is_attacking = true
	attack_timer = attack_cooldown
	
	# Show aim indicator
	_spawn_aim_indicator()
	
	# Wind up
	if attack_windup_time > 0 and get_tree():
		await get_tree().create_timer(attack_windup_time).timeout
	
	if is_dead or not is_instance_valid(self):
		return
	
	# Shoot projectile
	_shoot_projectile()
	
	# Clean up aim indicator
	if aim_indicator and is_instance_valid(aim_indicator):
		aim_indicator.queue_free()
		aim_indicator = null
	
	is_attacking = false


func _spawn_aim_indicator() -> void:
	aim_indicator = MeshInstance3D.new()
	aim_indicator.name = "AimIndicator"
	
	# Create a line pointing at the player
	var line_mesh = CylinderMesh.new()
	line_mesh.top_radius = 0.02
	line_mesh.bottom_radius = 0.02
	line_mesh.height = attack_range
	aim_indicator.mesh = line_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.3, 0.1, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.3, 0.1)
	mat.emission_energy_multiplier = 1.5
	aim_indicator.material_override = mat
	aim_indicator.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	add_child(aim_indicator)
	
	# Position and rotate to point at target
	aim_indicator.position = Vector3(0, 1.0, 0)
	aim_indicator.rotation.x = deg_to_rad(90)
	aim_indicator.position.z = -attack_range / 2.0


func _shoot_projectile() -> void:
	if not target or not is_instance_valid(target):
		return
	
	var projectile = PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(projectile)
	
	# Spawn at enemy position, slightly in front
	var spawn_pos = global_position + Vector3.UP * 1.0 + (-global_transform.basis.z * 0.5)
	projectile.global_position = spawn_pos
	
	# Aim at player's center mass
	var target_pos = target.global_position + Vector3.UP * 1.0
	var direction = (target_pos - spawn_pos).normalized()
	
	projectile.initialize(direction, attack_damage, projectile_speed)
	
	AudioManager.play_sfx("enemy_shoot")


func _perform_attack() -> void:
	# Override to prevent melee attack behavior
	pass
