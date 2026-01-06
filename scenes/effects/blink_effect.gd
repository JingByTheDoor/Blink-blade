extends Node3D
class_name BlinkEffect
## Visual effect for blink ability

@onready var particles: GPUParticles3D = $GPUParticles3D
@onready var light: OmniLight3D = $OmniLight3D


func _ready() -> void:
	if particles:
		particles.emitting = true
	
	# Fade out light
	if light:
		var tween = create_tween()
		tween.tween_property(light, "light_energy", 0.0, 0.3)
	
	# Self destruct
	await get_tree().create_timer(1.0).timeout
	queue_free()


func play_at(position: Vector3) -> void:
	global_position = position
	if particles:
		particles.emitting = true
