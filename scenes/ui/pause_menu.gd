extends CanvasLayer
class_name PauseMenu
## In-game pause menu

@onready var panel: Panel = $Panel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide_menu()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()


func toggle_pause() -> void:
	if get_tree().paused:
		resume()
	else:
		pause()


func pause() -> void:
	get_tree().paused = true
	panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func resume() -> void:
	get_tree().paused = false
	panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func hide_menu() -> void:
	panel.visible = false


func _on_resume_pressed() -> void:
	AudioManager.play_sfx("menu_select")
	resume()


func _on_options_pressed() -> void:
	AudioManager.play_sfx("menu_select")
	# TODO: Show options


func _on_quit_run_pressed() -> void:
	AudioManager.play_sfx("menu_select")
	get_tree().paused = false
	GameState.end_run(false)
