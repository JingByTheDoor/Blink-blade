extends Node3D
class_name HitEffect
## Visual effect for hit impacts

@onready var particles: GPUParticles3D = $GPUParticles3D
@onready var light: OmniLight3D = $OmniLight3D


func _ready() -> void:
	if particles:
		particles.emitting = true
	
	# Flash and fade light
	if light:
		var tween = create_tween()
		tween.tween_property(light, "light_energy", 0.0, 0.2)
	
	# Self destruct
	await get_tree().create_timer(0.5).timeout
	queue_free()
