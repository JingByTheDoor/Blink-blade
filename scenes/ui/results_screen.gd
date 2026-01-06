extends Control
## Results screen - shows final score and grade

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var score_label: Label = $Panel/VBoxContainer/ScoreLabel
@onready var grade_label: Label = $Panel/VBoxContainer/GradeLabel
@onready var stats_label: Label = $Panel/VBoxContainer/StatsLabel
@onready var return_button: Button = $Panel/VBoxContainer/ReturnButton


func _ready() -> void:
	# Pause the game
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Calculate and display results
	var score_data = GameState.calculate_score()
	var total_score = score_data["total"]
	var grade = GameState.get_grade(total_score)
	
	# Update labels
	if title_label:
		if GameState.rooms_cleared >= 10:
			title_label.text = "VICTORY!"
			title_label.modulate = Color.GOLD
		else:
			title_label.text = "GAME OVER"
			title_label.modulate = Color.RED
	
	if score_label:
		score_label.text = "Total Score: %d" % total_score
	
	if grade_label:
		grade_label.text = "Grade: %s" % grade
		match grade:
			"S": grade_label.modulate = Color.GOLD
			"A": grade_label.modulate = Color.GREEN
			"B": grade_label.modulate = Color.CYAN
			"C": grade_label.modulate = Color.YELLOW
			_: grade_label.modulate = Color.GRAY
	
	if stats_label:
		stats_label.text = """
		Rooms Cleared: %d / 10
		Perfect Rooms: %d
		Max Combo: %d
		Enemies Killed: %d
		Time: %.1f seconds
		
		Score Breakdown:
		- Kills: %d
		- Combo Bonus: %d
		- Perfect Bonus: %d
		- Time Bonus: %d
		""" % [
			score_data["rooms_cleared"],
			score_data["perfect_rooms"],
			score_data["max_combo"],
			GameState.total_enemies_killed,
			score_data["run_time"],
			score_data["kill_score"],
			score_data["combo_bonus"],
			score_data["perfect_bonus"],
			score_data["time_bonus"]
		]
	
	if return_button:
		return_button.pressed.connect(_on_return_pressed)


func _on_return_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
