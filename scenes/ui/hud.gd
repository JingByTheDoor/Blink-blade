extends CanvasLayer
class_name HUD
## In-game heads-up display

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthBar/Label
@onready var combo_label: Label = $ComboContainer/ComboLabel
@onready var combo_counter: Label = $ComboContainer/ComboCounter
@onready var room_label: Label = $TopContainer/RoomLabel
@onready var blink_cooldown: ProgressBar = $AbilityContainer/BlinkCooldown
@onready var dash_cooldown: ProgressBar = $AbilityContainer/DashCooldown
@onready var blink_label: Label = $AbilityContainer/BlinkCooldown/Label
@onready var dash_label: Label = $AbilityContainer/DashCooldown/Label

var combo_tween: Tween = null
var player: Node3D = null


func _ready() -> void:
	GameState.combo_changed.connect(_on_combo_changed)
	GameState.combo_reset.connect(_on_combo_reset)
	GameState.combo_milestone_reached.connect(_on_milestone_reached)
	GameState.player_health_changed.connect(_on_health_changed)
	
	_update_room_display()
	_update_health_display(GameState.current_health, GameState.max_health)
	_update_combo_display(0)
	
	# Find player after a frame
	await get_tree().process_frame
	_find_player()


func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]


func _process(_delta: float) -> void:
	_update_cooldowns()


func _update_cooldowns() -> void:
	if not player or not is_instance_valid(player):
		_find_player()
		return
	
	# Update blink cooldown display
	if blink_cooldown:
		var blink_max = GameState.blink_cooldown
		var blink_current = player.blink_cooldown_timer if player.has_method("_ready") else 0.0
		blink_cooldown.max_value = blink_max
		blink_cooldown.value = blink_max - blink_current
		
		# Update label
		if blink_label:
			if blink_current > 0:
				blink_label.text = "%.1f" % blink_current
			else:
				blink_label.text = "RMB"
	
	# Update dash cooldown display
	if dash_cooldown:
		var dash_max = GameState.dash_cooldown
		var dash_current = player.dash_cooldown_timer if player.has_method("_ready") else 0.0
		dash_cooldown.max_value = dash_max
		dash_cooldown.value = dash_max - dash_current
		
		# Update label
		if dash_label:
			if dash_current > 0:
				dash_label.text = "%.1f" % dash_current
			else:
				dash_label.text = "SHIFT"


func _on_combo_changed(new_value: int) -> void:
	_update_combo_display(new_value)


func _on_combo_reset() -> void:
	_flash_combo_break()


func _on_milestone_reached(milestone: int) -> void:
	_flash_milestone(milestone)
	AudioManager.play_sfx("combo_milestone")


func _on_health_changed(new_health: int, max_health: int) -> void:
	_update_health_display(new_health, max_health)


func _update_health_display(current: int, maximum: int) -> void:
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current
	if health_label:
		health_label.text = "%d / %d" % [current, maximum]


func _update_combo_display(combo: int) -> void:
	if combo_counter:
		combo_counter.text = str(combo)
	
	if combo_label:
		combo_label.visible = combo > 0
	if combo_counter:
		combo_counter.visible = combo > 0
	
	# Pulse effect
	if combo > 0 and combo_counter:
		if combo_tween:
			combo_tween.kill()
		combo_tween = create_tween()
		combo_counter.scale = Vector2(1.3, 1.3)
		combo_tween.tween_property(combo_counter, "scale", Vector2(1, 1), 0.15)


func _update_room_display() -> void:
	if room_label:
		room_label.text = "Room %d / %d" % [GameState.get_current_room_number(), GameState.room_sequence.size()]


func _flash_combo_break() -> void:
	if combo_counter and get_tree():
		combo_counter.add_theme_color_override("font_color", Color.RED)
		await get_tree().create_timer(0.3).timeout
		if is_instance_valid(combo_counter):
			combo_counter.remove_theme_color_override("font_color")


func _flash_milestone(milestone: int) -> void:
	if combo_counter and get_tree():
		combo_counter.add_theme_color_override("font_color", Color.GOLD)
		await get_tree().create_timer(0.5).timeout
		if is_instance_valid(combo_counter):
			combo_counter.remove_theme_color_override("font_color")
