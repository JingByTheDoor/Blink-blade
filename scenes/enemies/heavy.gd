extends EnemyBase
class_name EnemyHeavy
## Slow, tanky enemy with powerful attacks

func _ready() -> void:
	max_health = 100
	move_speed = 2.5
	attack_damage = 35
	attack_range = 2.5
	attack_cooldown = 2.0
	super._ready()


func _perform_attack() -> void:
	is_attacking = true
	attack_timer = attack_cooldown
	
	# Wind-up before attack (telegraphing)
	if not get_tree():
		return
	await get_tree().create_timer(0.5).timeout
	
	if is_dead or not is_instance_valid(self):
		return
	
	# Heavy slam attack
	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		if distance <= attack_range:
			if target.has_method("take_damage"):
				target.take_damage(attack_damage)
				AudioManager.play_sfx("hit_player")
	
	if get_tree():
		await get_tree().create_timer(0.5).timeout
	is_attacking = false
