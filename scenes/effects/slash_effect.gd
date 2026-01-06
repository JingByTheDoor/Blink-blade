extends Node3D
class_name SlashEffect
## Visual effect for melee slash attacks

@onready var mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	# Animate slash
	if mesh:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(mesh, "scale", Vector3(1.5, 1.5, 1.5), 0.15)
		
		var mat = mesh.get_active_material(0) as StandardMaterial3D
		if mat:
			tween.tween_property(mat, "albedo_color:a", 0.0, 0.2)
	
	# Self destruct
	if get_tree():
		await get_tree().create_timer(0.3).timeout
	if is_instance_valid(self):
		queue_free()
