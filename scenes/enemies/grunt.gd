extends EnemyBase
class_name EnemyGrunt
## Fast, low-health enemy that rushes the player

func _ready() -> void:
	max_health = 30
	move_speed = 4.5
	attack_damage = 15
	attack_range = 1.5
	attack_cooldown = 1.6
	attack_windup_time = 0.25
	super._ready()
