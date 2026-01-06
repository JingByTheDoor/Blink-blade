extends GPUParticles3D
## Hit effect - visual feedback for successful attacks

func _ready() -> void:
	emitting = true
	one_shot = true
	
	# Auto-cleanup after effect finishes
	await get_tree().create_timer(1.0).timeout
	queue_free()
