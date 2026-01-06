extends Control
## Main menu - title screen with start and quit options

@onready var start_button: Button = $Panel/VBoxContainer/StartButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)


func _on_start_pressed() -> void:
	GameState.start_new_run()


func _on_quit_pressed() -> void:
	get_tree().quit()
