extends Node2D
class_name RiverTile

@export var river_pos: RiverPos = RiverPos.CENTER

enum WaterLevel {
	EMPTY,
	SLIGHTLY_FILLED,
	MOSTLY_FILLED,
	FULL
}

enum RiverPos {
	LEFT,
	CENTER,
	RIGHT
}

# Sets all the attributes associated with a river tile
func set_water_level(level: WaterLevel) -> void:
	$Sprite.region_rect = Rect2(river_pos * 16, level * 16, 16, 16)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sprite.region_enabled = true
	$Sprite.region_rect = Rect2(river_pos * 16, 0, 16, 16)
