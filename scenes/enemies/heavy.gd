extends EnemyBase
## Slow, high-health enemy with telegraphed attacks

func _ready() -> void:
	max_health = 60
	move_speed = 2.5
	attack_damage = 20
	attack_range = 2.5
	detection_range = 20.0
	attack_cooldown = 2.5
	
	super._ready()


func perform_attack() -> void:
	if not can_attack or not player:
		return
	
	# Telegraph attack with a delay
	_telegraph_attack()
	
	await get_tree().create_timer(0.5).timeout
	
	super.perform_attack()


func _telegraph_attack() -> void:
	# Simple telegraph - scale up briefly
	if mesh:
		var tween = create_tween()
		tween.tween_property(mesh, "scale", Vector3(1.2, 1.2, 1.2), 0.25)
		tween.tween_property(mesh, "scale", Vector3.ONE, 0.25)
