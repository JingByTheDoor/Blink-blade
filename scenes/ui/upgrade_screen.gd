extends Control
## Upgrade selection screen - choose 1 of 3 random upgrades

var upgrade_options: Array[UpgradeData] = []

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var hbox_container: HBoxContainer = $Panel/VBoxContainer/HBoxContainer
@onready var upgrade_button_1: Button = $Panel/VBoxContainer/HBoxContainer/UpgradeButton1
@onready var upgrade_button_2: Button = $Panel/VBoxContainer/HBoxContainer/UpgradeButton2
@onready var upgrade_button_3: Button = $Panel/VBoxContainer/HBoxContainer/UpgradeButton3


func _ready() -> void:
	# Pause the game
	get_tree().paused = true
	
	# Get random upgrades
	upgrade_options = UpgradeManager.get_random_upgrades(3)
	
	# Set up buttons
	_setup_upgrade_button(upgrade_button_1, 0)
	_setup_upgrade_button(upgrade_button_2, 1)
	_setup_upgrade_button(upgrade_button_3, 2)


func _setup_upgrade_button(button: Button, index: int) -> void:
	if index < upgrade_options.size():
		var upgrade = upgrade_options[index]
		button.text = "%s\n%s" % [upgrade.title, upgrade.description]
		button.pressed.connect(_on_upgrade_selected.bind(upgrade))
	else:
		button.visible = false


func _on_upgrade_selected(upgrade: UpgradeData) -> void:
	# Apply the upgrade
	UpgradeManager.apply_upgrade(upgrade)
	
	# Emit signal and advance
	GameState.upgrade_selection_ended.emit()
	GameState.advance_to_next_room()
	
	# Unpause and close
	get_tree().paused = false
	queue_free()
