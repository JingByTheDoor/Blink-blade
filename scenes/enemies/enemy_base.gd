extends CharacterBody3D
class_name EnemyBase
## Base class for all enemies

signal died()
signal hit_taken(damage: int)

@export var max_health: int = 50
@export var move_speed: float = 3.0
@export var attack_damage: int = 20
@export var attack_range: float = 2.0
@export var detection_range: float = 12.0
@export var attack_cooldown: float = 2.2
@export var attack_windup_time: float = 0.3
@export var attack_telegraph_color: Color = Color(1.0, 0.6, 0.2, 1.0)
@export var attack_indicator_height: float = 0.08
@export var attack_indicator_opacity: float = 0.6
@export var attack_arc_angle_degrees: float = 140.0
@export var attack_arc_inner_radius: float = 0.0
@export var attack_indicator_flash_color: Color = Color(1.0, 0.2, 0.2, 1.0)
@export var attack_indicator_flash_time: float = 0.08
@export var attack_swing_opacity: float = 0.85
@export var attack_swing_duration: float = 0.18
@export var attack_windup_tilt_degrees: float = -8.0
@export var attack_swing_tilt_degrees: float = 12.0
@export var attack_tilt_time: float = 0.12
@export var attack_wave_thickness: float = 0.35
@export var attack_wave_opacity: float = 0.4
@export var attack_wave_height: float = 0.05
@export var attack_wave_start_scale: float = 0.05
@export var attack_wave_emission_multiplier: float = 0.6

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
	
	_play_attack_tilt(attack_windup_tilt_degrees, attack_tilt_time)
	var indicator = await _telegraph_attack()
	if is_dead or not is_instance_valid(self):
		return
	
	_play_attack_tilt(attack_swing_tilt_degrees, attack_tilt_time)
	_spawn_attack_swing_arc()
	var hit = _apply_attack_damage()
	if indicator and is_instance_valid(indicator):
		if hit:
			await _flash_attack_indicator(indicator)
		indicator.queue_free()
	
	# Attack animation duration
	if get_tree():
		await get_tree().create_timer(0.5).timeout
	is_attacking = false


func _telegraph_attack() -> MeshInstance3D:
	var indicator = _spawn_attack_indicator()
	var wave = _spawn_attack_wave()
	var mat: StandardMaterial3D = null
	var original_color := Color.WHITE
	if mesh:
		var candidate = mesh.get_active_material(0)
		if candidate is StandardMaterial3D:
			mat = candidate
			original_color = mat.albedo_color
			mat.albedo_color = attack_telegraph_color
	
	if attack_windup_time > 0 and get_tree():
		await get_tree().create_timer(attack_windup_time).timeout
	
	if mat and is_instance_valid(self):
		mat.albedo_color = original_color
	if wave and is_instance_valid(wave):
		wave.queue_free()
	
	return indicator


func _spawn_attack_indicator() -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "AttackIndicator"
	mesh_instance.mesh = _create_attack_arc_mesh()
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(attack_telegraph_color.r, attack_telegraph_color.g, attack_telegraph_color.b, attack_indicator_opacity)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = attack_telegraph_color
	mat.emission_energy_multiplier = 1.2
	mesh_instance.material_override = mat
	add_child(mesh_instance)
	
	if attack_windup_time > 0 and is_inside_tree():
		mesh_instance.scale = Vector3(0.8, 1.0, 0.8)
		var tween = create_tween()
		tween.tween_property(mesh_instance, "scale", Vector3(1, 1, 1), attack_windup_time)
	
	mesh_instance.position = Vector3(0, attack_indicator_height, 0)
	return mesh_instance


func _create_attack_arc_mesh() -> ArrayMesh:
	var outer_radius = max(attack_range, 0.1)
	var inner_radius = clamp(attack_arc_inner_radius, 0.0, outer_radius)
	var arc_degrees = clamp(attack_arc_angle_degrees, 5.0, 359.0)
	var arc_radians = deg_to_rad(arc_degrees)
	var half_arc = arc_radians * 0.5
	var segments = max(8, int(arc_degrees / 5.0))
	
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var angle = lerp(-half_arc, half_arc, t)
		var sin_a = sin(angle)
		var cos_a = cos(angle)
		var outer = Vector3(sin_a * outer_radius, 0.0, -cos_a * outer_radius)
		var inner = Vector3(sin_a * inner_radius, 0.0, -cos_a * inner_radius)
		vertices.append(outer)
		vertices.append(inner)
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
	
	for i in range(segments):
		var base = i * 2
		indices.append(base)
		indices.append(base + 1)
		indices.append(base + 2)
		indices.append(base + 1)
		indices.append(base + 3)
		indices.append(base + 2)
	
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _create_attack_arc_mesh_custom(outer_radius: float, inner_radius: float) -> ArrayMesh:
	var outer = max(outer_radius, 0.1)
	var inner = clamp(inner_radius, 0.0, outer)
	var arc_degrees = clamp(attack_arc_angle_degrees, 5.0, 359.0)
	var arc_radians = deg_to_rad(arc_degrees)
	var half_arc = arc_radians * 0.5
	var segments = max(8, int(arc_degrees / 5.0))
	
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var angle = lerp(-half_arc, half_arc, t)
		var sin_a = sin(angle)
		var cos_a = cos(angle)
		var outer_point = Vector3(sin_a * outer, 0.0, -cos_a * outer)
		var inner_point = Vector3(sin_a * inner, 0.0, -cos_a * inner)
		vertices.append(outer_point)
		vertices.append(inner_point)
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
	
	for i in range(segments):
		var base = i * 2
		indices.append(base)
		indices.append(base + 1)
		indices.append(base + 2)
		indices.append(base + 1)
		indices.append(base + 3)
		indices.append(base + 2)
	
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _apply_attack_damage() -> bool:
	if not target or not is_instance_valid(target):
		return false
	if not _is_target_in_attack_arc(target):
		return false
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
	return true


func _is_target_in_attack_arc(target_node: Node3D) -> bool:
	var to_target = target_node.global_position - global_position
	to_target.y = 0
	var distance = to_target.length()
	if distance > attack_range:
		return false
	if attack_arc_angle_degrees >= 360.0 or distance <= 0.001:
		return true
	
	var forward = -global_transform.basis.z
	forward.y = 0
	if forward.length() <= 0.001:
		return true
	forward = forward.normalized()
	var dir = to_target / max(distance, 0.001)
	var angle = rad_to_deg(acos(clamp(forward.dot(dir), -1.0, 1.0)))
	return angle <= attack_arc_angle_degrees * 0.5


func _flash_attack_indicator(indicator: MeshInstance3D) -> void:
	if not indicator or not is_instance_valid(indicator):
		return
	var mat = indicator.material_override as StandardMaterial3D
	if not mat:
		return
	
	mat.albedo_color = Color(attack_indicator_flash_color.r, attack_indicator_flash_color.g, attack_indicator_flash_color.b, attack_indicator_opacity)
	mat.emission = attack_indicator_flash_color
	if get_tree():
		await get_tree().create_timer(attack_indicator_flash_time).timeout


func _spawn_attack_wave() -> MeshInstance3D:
	if attack_windup_time <= 0:
		return null
	if attack_range <= 0.05:
		return null
	
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "AttackWave"
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	var thickness = clamp(attack_wave_thickness, 0.02, attack_range)
	var inner_ratio = max(1.0 - (thickness / max(attack_range, 0.1)), 0.0)
	mesh_instance.mesh = _create_attack_arc_mesh_custom(1.0, inner_ratio)
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(attack_indicator_flash_color.r, attack_indicator_flash_color.g, attack_indicator_flash_color.b, attack_wave_opacity)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = attack_indicator_flash_color
	mat.emission_energy_multiplier = attack_wave_emission_multiplier
	mesh_instance.material_override = mat
	add_child(mesh_instance)
	
	mesh_instance.position = Vector3(0, attack_wave_height, 0)
	mesh_instance.scale = Vector3(attack_wave_start_scale, 1.0, attack_wave_start_scale)
	
	if is_inside_tree():
		var tween = create_tween()
		tween.tween_property(mesh_instance, "scale", Vector3(attack_range, 1.0, attack_range), max(attack_windup_time, 0.01))
	
	return mesh_instance


func _spawn_attack_swing_arc() -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "AttackSwing"
	mesh_instance.mesh = _create_attack_arc_mesh()
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.position = Vector3(0, attack_indicator_height, 0)
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(attack_indicator_flash_color.r, attack_indicator_flash_color.g, attack_indicator_flash_color.b, attack_swing_opacity)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = attack_indicator_flash_color
	mat.emission_energy_multiplier = 1.6
	mesh_instance.material_override = mat
	add_child(mesh_instance)
	
	if attack_swing_duration > 0 and is_inside_tree():
		var tween = create_tween()
		tween.tween_property(mesh_instance, "scale", Vector3(1.05, 1.0, 1.05), attack_swing_duration)
		tween.tween_callback(mesh_instance.queue_free)
	else:
		mesh_instance.queue_free()


func _play_attack_tilt(angle_degrees: float, duration: float) -> void:
	if not mesh or abs(angle_degrees) <= 0.001 or duration <= 0:
		return
	
	var start_rot = mesh.rotation
	var tilt = start_rot.x + deg_to_rad(angle_degrees)
	var tween = create_tween()
	tween.tween_property(mesh, "rotation:x", tilt, duration * 0.5)
	tween.tween_property(mesh, "rotation:x", start_rot.x, duration * 0.5)


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
