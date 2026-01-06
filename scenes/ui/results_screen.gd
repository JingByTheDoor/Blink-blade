extends Control
class_name ResultsScreen
## End-of-run results display

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var grade_label: Label = $Panel/VBoxContainer/GradeLabel
@onready var stats_container: VBoxContainer = $Panel/VBoxContainer/StatsContainer
@onready var score_label: Label = $Panel/VBoxContainer/ScoreContainer/ScoreLabel


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	AudioManager.play_music("results")
	_display_results()


func _display_results() -> void:
	var score_data = GameState.calculate_score()
	var is_victory = GameState.rooms_cleared >= GameState.room_sequence.size()
	
	# Title
	if is_victory:
		title_label.text = "VICTORY!"
		title_label.add_theme_color_override("font_color", Color.GOLD)
	else:
		title_label.text = "RUN ENDED"
		title_label.add_theme_color_override("font_color", Color.RED)
	
	# Grade
	var grade = GameState.get_grade(score_data["total"])
	grade_label.text = grade
	grade_label.add_theme_color_override("font_color", _get_grade_color(grade))
	
	# Stats
	_add_stat("Rooms Cleared", "%d / %d" % [score_data["rooms_cleared"], GameState.room_sequence.size()])
	_add_stat("Max Combo", str(score_data["max_combo"]))
	_add_stat("Perfect Rooms", str(score_data["perfect_rooms"]))
	_add_stat("Run Time", _format_time(score_data["run_time"]))
	_add_stat("", "")
	_add_stat("Time Bonus", "+%d" % score_data["time_bonus"])
	_add_stat("Combo Bonus", "+%d" % score_data["combo_bonus"])
	_add_stat("Perfect Bonus", "+%d" % score_data["perfect_bonus"])
	_add_stat("Kill Score", "+%d" % score_data["kill_score"])
	
	# Total score
	score_label.text = str(score_data["total"])


func _add_stat(label_text: String, value_text: String) -> void:
	var hbox = HBoxContainer.new()
	stats_container.add_child(hbox)
	
	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)
	
	var value = Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(value)


func _format_time(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%d:%02d" % [mins, secs]


func _get_grade_color(grade: String) -> Color:
	match grade:
		"S":
			return Color.GOLD
		"A":
			return Color.GREEN
		"B":
			return Color.CYAN
		"C":
			return Color.YELLOW
		_:
			return Color.GRAY


func _on_retry_pressed() -> void:
	AudioManager.play_sfx("menu_select")
	GameState.start_new_run()


func _on_main_menu_pressed() -> void:
	AudioManager.play_sfx("menu_select")
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
