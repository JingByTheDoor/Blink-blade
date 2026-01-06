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
	# The hitbox itself handles damage dealing
	# This hurtbox is just for collision detection
	# The actual damage is handled by the Hitbox's _process_hit method
	# which calls take_damage on the owner/parent node
	pass
