extends Area3D
class_name Hitbox
## Generic hitbox for melee attacks

signal hit_detected(target: Node3D)

@export var damage: int = 10
@export var knockback_force: float = 5.0

var is_active: bool = false
var hit_targets: Array[Node3D] = []


func _ready() -> void:
	monitoring = false
	monitorable = false
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func activate(override_damage: int = -1) -> void:
	if override_damage >= 0:
		damage = override_damage
	hit_targets.clear()
	is_active = true
	monitoring = true
	monitorable = true


func deactivate() -> void:
	is_active = false
	monitoring = false
	monitorable = false
	hit_targets.clear()


func _on_body_entered(body: Node3D) -> void:
	if not is_active:
		return
	if body in hit_targets:
		return
	
	hit_targets.append(body)
	_process_hit(body)


func _on_area_entered(area: Area3D) -> void:
	if not is_active:
		return
	
	var parent = area.get_parent()
	if parent and parent is Node3D:
		if parent in hit_targets:
			return
		hit_targets.append(parent)
		_process_hit(parent)


func _process_hit(target: Node3D) -> void:
	var knockback_dir = (target.global_position - global_position).normalized()
	knockback_dir.y = 0.2
	var knockback = knockback_dir * knockback_force
	
	if target.has_method("take_damage"):
		target.take_damage(damage, knockback)
	
	hit_detected.emit(target)
