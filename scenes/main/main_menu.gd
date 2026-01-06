extends Control
## Main menu screen

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	AudioManager.play_music("menu")


func _on_start_pressed() -> void:
	AudioManager.play_sfx("menu_select")
	GameState.start_new_run()


func _on_options_pressed() -> void:
	AudioManager.play_sfx("menu_select")
	# TODO: Show options menu


func _on_quit_pressed() -> void:
	AudioManager.play_sfx("menu_select")
	get_tree().quit()
