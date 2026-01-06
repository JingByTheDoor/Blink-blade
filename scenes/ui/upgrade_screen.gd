extends Control
class_name UpgradeScreen
## Upgrade selection screen shown between rooms

signal upgrade_selected(upgrade: UpgradeData)

@onready var upgrade_container: HBoxContainer = $Panel/VBoxContainer/UpgradeContainer

var upgrade_buttons: Array[Button] = []
var available_upgrades: Array[UpgradeData] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	GameState.upgrade_selection_started.connect(_on_upgrade_selection_started)


func _on_upgrade_selection_started() -> void:
	show_upgrades()


func show_upgrades() -> void:
	get_tree().paused = true
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	available_upgrades = UpgradeManager.get_random_upgrades(3)
	_create_upgrade_buttons()


func _create_upgrade_buttons() -> void:
	# Clear existing
	for child in upgrade_container.get_children():
		child.queue_free()
	upgrade_buttons.clear()
	
	# Create new buttons
	for i in range(available_upgrades.size()):
		var upgrade = available_upgrades[i]
		var button = _create_upgrade_button(upgrade, i)
		upgrade_container.add_child(button)
		upgrade_buttons.append(button)


func _create_upgrade_button(upgrade: UpgradeData, index: int) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(250, 300)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = upgrade.title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	var category = Label.new()
	category.text = "[%s]" % upgrade.category.to_upper()
	category.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	category.add_theme_color_override("font_color", _get_category_color(upgrade.category))
	vbox.add_child(category)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	
	var desc = Label.new()
	desc.text = upgrade.description
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)
	
	var button = Button.new()
	button.text = "Select"
	button.pressed.connect(_on_upgrade_selected.bind(index))
	vbox.add_child(button)
	
	return panel


func _get_category_color(category: String) -> Color:
	match category:
		"blink":
			return Color.CYAN
		"melee":
			return Color.RED
		"survivability":
			return Color.GREEN
		"mobility":
			return Color.YELLOW
		"combo":
			return Color.ORANGE
		_:
			return Color.WHITE


func _on_upgrade_selected(index: int) -> void:
	if index >= 0 and index < available_upgrades.size():
		var upgrade = available_upgrades[index]
		UpgradeManager.apply_upgrade(upgrade)
		AudioManager.play_sfx("upgrade_select")
		upgrade_selected.emit(upgrade)
		
		visible = false
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		GameState.upgrade_selection_ended.emit()
		GameState.advance_to_next_room()
