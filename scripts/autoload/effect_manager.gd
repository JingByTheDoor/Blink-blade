extends Node
## Manages spawning visual effects throughout the game

const BLINK_EFFECT = preload("res://scenes/effects/blink_effect.tscn")
const DASH_EFFECT = preload("res://scenes/effects/dash_effect.tscn")
const HIT_EFFECT = preload("res://scenes/effects/hit_effect.tscn")
const SLASH_EFFECT = preload("res://scenes/effects/slash_effect.tscn")


func spawn_blink_effect(position: Vector3) -> void:
	var effect = BLINK_EFFECT.instantiate()
	_add_effect_to_scene(effect, position)


func spawn_dash_effect(position: Vector3, direction: Vector3) -> void:
	var effect = DASH_EFFECT.instantiate()
	_add_effect_to_scene(effect, position)
	if direction.length() > 0.1:
		effect.look_at(position + direction, Vector3.UP)


func spawn_hit_effect(position: Vector3) -> void:
	var effect = HIT_EFFECT.instantiate()
	_add_effect_to_scene(effect, position)


func spawn_slash_effect(position: Vector3, direction: Vector3) -> void:
	var effect = SLASH_EFFECT.instantiate()
	_add_effect_to_scene(effect, position)
	if direction.length() > 0.1:
		effect.look_at(position + direction, Vector3.UP)


func _add_effect_to_scene(effect: Node3D, position: Vector3) -> void:
	var scene_root = get_tree().current_scene
	if scene_root:
		scene_root.add_child(effect)
		effect.global_position = position
