extends Node3D
## Blink effect - visual feedback for blink teleport

@onready var particles: GPUParticles3D = $GPUParticles3D


func _ready() -> void:
	if particles:
		particles.emitting = true
		particles.one_shot = true
	
	# Auto-cleanup after effect finishes
	await get_tree().create_timer(2.0).timeout
	queue_free()
