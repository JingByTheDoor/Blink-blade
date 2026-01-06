extends Node3D
class_name DashEffect
## Visual effect for dash ability

@onready var trail: MeshInstance3D = $Trail


func _ready() -> void:
	# Fade out trail
	if trail and trail.get_active_material(0):
		var mat = trail.get_active_material(0) as StandardMaterial3D
		if mat:
			var tween = create_tween()
			tween.tween_property(mat, "albedo_color:a", 0.0, 0.3)
	
	# Self destruct
	await get_tree().create_timer(0.5).timeout
	queue_free()
