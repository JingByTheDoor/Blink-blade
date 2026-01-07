extends EnemyBase
class_name EnemyHeavy
## Slow, tanky enemy with powerful attacks

func _ready() -> void:
	max_health = 100
	move_speed = 1.8
	attack_damage = 35
	attack_range = 2.5
	attack_cooldown = 2.8
	attack_windup_time = 0.6
	super._ready()


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
	if hit:
		AudioManager.play_sfx("hit_player")
	if indicator and is_instance_valid(indicator):
		if hit:
			await _flash_attack_indicator(indicator)
		indicator.queue_free()
	
	if get_tree():
		await get_tree().create_timer(0.5).timeout
	is_attacking = false
