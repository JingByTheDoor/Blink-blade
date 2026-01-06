extends Node
class_name StateMachine
## Generic state machine for player and enemy AI

signal state_changed(from_state: String, to_state: String)

@export var initial_state: String = ""

var current_state: String = ""
var states: Dictionary = {}
var state_node: Node = null


func _ready() -> void:
	await owner.ready
	state_node = get_parent()
	
	if initial_state != "":
		change_state(initial_state)


func _process(delta: float) -> void:
	if current_state != "" and state_node:
		var method_name = "_state_" + current_state + "_process"
		if state_node.has_method(method_name):
			state_node.call(method_name, delta)


func _physics_process(delta: float) -> void:
	if current_state != "" and state_node:
		var method_name = "_state_" + current_state + "_physics"
		if state_node.has_method(method_name):
			state_node.call(method_name, delta)


func change_state(new_state: String) -> void:
	if new_state == current_state:
		return
	
	var old_state = current_state
	
	if current_state != "" and state_node:
		var exit_method = "_state_" + current_state + "_exit"
		if state_node.has_method(exit_method):
			state_node.call(exit_method)
	
	current_state = new_state
	
	if state_node:
		var enter_method = "_state_" + new_state + "_enter"
		if state_node.has_method(enter_method):
			state_node.call(enter_method)
	
	state_changed.emit(old_state, new_state)


func is_state(state_name: String) -> bool:
	return current_state == state_name