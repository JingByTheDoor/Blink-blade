extends EnemyBase
## Fast, low-health enemy that rushes the player

func _ready() -> void:
	max_health = 20
	move_speed = 6.0
	attack_damage = 8
	attack_range = 1.8
	detection_range = 25.0
	attack_cooldown = 1.0
	
	super._ready()
