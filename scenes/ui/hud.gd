extends CanvasLayer
## In-game HUD showing player stats and game info

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthBar/HealthLabel
@onready var combo_label: Label = $MarginContainer/VBoxContainer/ComboLabel
@onready var room_label: Label = $MarginContainer/VBoxContainer/RoomLabel
@onready var blink_cooldown: ProgressBar = $MarginContainer/VBoxContainer/HBoxContainer/BlinkCooldown
@onready var dash_cooldown: ProgressBar = $MarginContainer/VBoxContainer/HBoxContainer/DashCooldown


func _ready() -> void:
	# Connect to game state signals
	GameState.player_health_changed.connect(_on_health_changed)
	GameState.combo_changed.connect(_on_combo_changed)
	GameState.combo_reset.connect(_on_combo_reset)
	
	# Initialize values
	_update_health()
	_update_combo()
	_update_room()


func _process(_delta: float) -> void:
	_update_room()


func _update_health() -> void:
	if health_bar:
		health_bar.max_value = GameState.max_health
		health_bar.value = GameState.current_health
	
	if health_label:
		health_label.text = "%d / %d" % [GameState.current_health, GameState.max_health]


func _update_combo() -> void:
	if combo_label:
		if GameState.current_combo > 0:
			combo_label.text = "COMBO: %d" % GameState.current_combo
			combo_label.modulate = Color.YELLOW
		else:
			combo_label.text = "COMBO: 0"
			combo_label.modulate = Color.WHITE


func _update_room() -> void:
	if room_label:
		room_label.text = "Room %d / 10" % GameState.get_current_room_number()


func _on_health_changed(new_health: int, max_health_value: int) -> void:
	_update_health()


func _on_combo_changed(new_combo: int) -> void:
	_update_combo()


func _on_combo_reset() -> void:
	_update_combo()
	# Flash red to indicate combo loss
	if combo_label:
		combo_label.modulate = Color.RED
		await get_tree().create_timer(0.3).timeout
		combo_label.modulate = Color.WHITE
