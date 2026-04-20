extends Node2D

@export var fill_level_interval_seconds: float = 2.0

func fill() -> void:
	for fill_level in range(RiverTile.WaterLevel.FULL + 1):
		set_water_level(fill_level)
		$Bridge.set_water_level(fill_level + 1)
		await get_tree().create_timer(fill_level_interval_seconds).timeout
	
	await get_tree().create_timer(fill_level_interval_seconds).timeout
	$Bridge.set_water_level(Bridge.BridgeLevel.BRAND_NEW)

func set_water_level(level: RiverTile.WaterLevel) -> void:
	for child in get_children():
		if child.name != "Bridge":
			child.set_water_level(level)
