extends Control
## Main menu screen

@onready var debug_toggle: CheckBox = $VBoxContainer/DebugToggle

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	AudioManager.play_music("menu")
	if debug_toggle:
		debug_toggle.button_pressed = GameState.debug_infinite_health


func _on_start_pressed() -> void:
	AudioManager.play_sfx("menu_select")
	GameState.start_new_run()


func _on_options_pressed() -> void:
	AudioManager.play_sfx("menu_select")
	# TODO: Show options menu


func _on_quit_pressed() -> void:
	AudioManager.play_sfx("menu_select")
	get_tree().quit()


func _on_debug_toggled(pressed: bool) -> void:
	GameState.debug_infinite_health = pressed
