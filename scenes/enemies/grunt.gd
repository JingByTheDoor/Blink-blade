extends EnemyBase
class_name EnemyGrunt
## Fast, low-health enemy that rushes the player

func _ready() -> void:
	max_health = 30
	move_speed = 6.0
	attack_damage = 15
	attack_range = 1.5
	attack_cooldown = 1.0
	super._ready()
