extends Resource
class_name EnemySpawnData
## Defines enemy spawn configuration for a room

@export var enemy_scene: PackedScene
@export var spawn_position: Vector3
@export var spawn_delay: float = 0.0  # Delay before spawning (for waves)
@export var wave_group: int = 0  # Which wave this enemy belongs to