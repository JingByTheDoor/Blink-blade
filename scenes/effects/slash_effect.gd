extends Node3D
class_name SlashEffect
## Visual effect for melee stab attacks

@onready var mesh: MeshInstance3D = $MeshInstance3D

const STAB_LENGTH: float = 2.0  # How far the stab extends
const STAB_DURATION: float = 0.1
const STAB_FADE_TIME: float = 0.1


func _ready() -> void:
	_create_stab_effect()
	
	# Self destruct
	if get_tree():
		await get_tree().create_timer(STAB_DURATION + STAB_FADE_TIME + 0.1).timeout
	if is_instance_valid(self):
		queue_free()


func _create_stab_effect() -> void:
	# Remove the default mesh if it exists
	if mesh:
		mesh.queue_free()
	
	# Create a long stab trail mesh
	var stab_mesh = _generate_stab_mesh()
	var stab_instance = MeshInstance3D.new()
	stab_instance.mesh = stab_mesh
	stab_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# Create glowing blue material
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.2, 0.5, 1.0, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.6, 1.0)
	mat.emission_energy_multiplier = 2.5
	stab_instance.material_override = mat
	
	add_child(stab_instance)
	
	# Animate the stab - thrust forward quickly
	stab_instance.scale = Vector3(0.2, 0.2, 0.3)
	stab_instance.position.z = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Scale up to full size (thrust out)
	tween.tween_property(stab_instance, "scale", Vector3(1.0, 1.0, 1.0), STAB_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Move forward slightly
	tween.tween_property(stab_instance, "position:z", -STAB_LENGTH * 0.3, STAB_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Fade out after thrust
	tween.tween_property(mat, "albedo_color:a", 0.0, STAB_FADE_TIME).set_delay(STAB_DURATION * 0.5)


func _generate_stab_mesh() -> ArrayMesh:
	# Create a long pointed stab shape
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var verts = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Stab parameters
	var stab_length: float = STAB_LENGTH
	var base_width: float = 0.15
	var base_height: float = 0.08
	var segments: int = 12
	
	# Create a long tapered blade shape extending forward
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var dist = t * stab_length
		
		# Taper to a sharp point
		var taper = 1.0 - t
		taper = taper * taper  # Quadratic taper for sharper point
		var width = base_width * taper
		var height = base_height * taper
		
		# Top vertex
		verts.append(Vector3(0, height, -dist))
		normals.append(Vector3(0, 1, 0))
		
		# Bottom vertex  
		verts.append(Vector3(0, -height, -dist))
		normals.append(Vector3(0, -1, 0))
		
		# Left vertex
		verts.append(Vector3(-width, 0, -dist))
		normals.append(Vector3(-1, 0, 0))
		
		# Right vertex
		verts.append(Vector3(width, 0, -dist))
		normals.append(Vector3(1, 0, 0))
	
	# Create triangles connecting each segment
	for i in range(segments):
		var base = i * 4
		var next = (i + 1) * 4
		
		# Top-left face
		indices.append(base + 0)  # top
		indices.append(base + 2)  # left
		indices.append(next + 0)  # next top
		
		indices.append(base + 2)  # left
		indices.append(next + 2)  # next left
		indices.append(next + 0)  # next top
		
		# Top-right face
		indices.append(base + 0)  # top
		indices.append(next + 0)  # next top
		indices.append(base + 3)  # right
		
		indices.append(base + 3)  # right
		indices.append(next + 0)  # next top
		indices.append(next + 3)  # next right
		
		# Bottom-left face
		indices.append(base + 1)  # bottom
		indices.append(next + 1)  # next bottom
		indices.append(base + 2)  # left
		
		indices.append(base + 2)  # left
		indices.append(next + 1)  # next bottom
		indices.append(next + 2)  # next left
		
		# Bottom-right face
		indices.append(base + 1)  # bottom
		indices.append(base + 3)  # right
		indices.append(next + 1)  # next bottom
		
		indices.append(base + 3)  # right
		indices.append(next + 3)  # next right
		indices.append(next + 1)  # next bottom
	
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	var arr_mesh = ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	return arr_mesh
