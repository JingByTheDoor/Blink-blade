extends Control
## Pause menu - pause game and return to menu

@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton


func _ready() -> void:
	# Already paused by the player controller
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)


func _on_resume_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false
	queue_free()


func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
