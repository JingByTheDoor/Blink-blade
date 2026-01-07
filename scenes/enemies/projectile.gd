extends Area3D
class_name Projectile
## Enemy projectile that travels toward the player

signal hit_player(damage: int)

@export var speed: float = 6.075  # 35% faster than grunt (4.5 * 1.35)
@export var damage: int = 15
@export var lifetime: float = 5.0

var direction: Vector3 = Vector3.FORWARD
var time_alive: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	# Move in direction
	global_position += direction * speed * delta
	
	# Lifetime check
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()


func initialize(dir: Vector3, proj_damage: int = 15, proj_speed: float = 6.075) -> void:
	direction = dir.normalized()
	damage = proj_damage
	speed = proj_speed
	
	# Face the direction of travel
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		hit_player.emit(damage)
		_spawn_hit_effect()
		queue_free()
	elif body.collision_layer & 1:  # World layer
		_spawn_hit_effect()
		queue_free()


func _on_area_entered(area: Area3D) -> void:
	var parent = area.get_parent()
	if parent and parent.is_in_group("player"):
		if parent.has_method("take_damage"):
			parent.take_damage(damage)
		hit_player.emit(damage)
		_spawn_hit_effect()
		queue_free()


func _spawn_hit_effect() -> void:
	EffectManager.spawn_hit_effect(global_position)
