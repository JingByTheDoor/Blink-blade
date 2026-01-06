extends Area3D
class_name Hurtbox
## Generic hurtbox component for receiving damage

signal damage_received(amount: int, knockback: Vector3)

@export var owner_node: Node3D = null


func _ready() -> void:
	monitoring = false
	monitorable = true
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area3D) -> void:
	# Check if this is a hitbox
	if area is Hitbox:
		var hitbox: Hitbox = area as Hitbox
		if hitbox.is_active and owner_node:
			# Let the hitbox handle the damage calculation
			# The owner should have a take_damage method
			pass
