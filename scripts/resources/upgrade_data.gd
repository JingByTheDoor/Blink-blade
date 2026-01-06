extends Resource
class_name UpgradeData
## Data container for an upgrade

@export var id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var category: String = ""  # blink, melee, survivability, mobility, combo
@export var effects: Dictionary = {}
@export var icon: Texture2D = null