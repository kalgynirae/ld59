extends Node2D
class_name Bridge

@export var bridge_level = BridgeLevel.BROKEN

enum BridgeLevel {
	BRAND_NEW,
	BROKEN,
	DAMP,
	RISING,
	REPAIRED
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sprite.region_enabled = true
	set_water_level(bridge_level)

func set_water_level(level: BridgeLevel) -> void:
	$Sprite.region_rect = Rect2(0, level * 48, 80, 48)
