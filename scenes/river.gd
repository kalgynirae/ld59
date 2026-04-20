extends Node2D

func fill() -> void:
	for fill_level in range(RiverTile.WaterLevel.FULL + 1):
		set_water_level(fill_level)
		$Bridge.set_water_level(fill_level + 1)
		await get_tree().create_timer(1.0).timeout

func set_water_level(level: RiverTile.WaterLevel) -> void:
	for child in get_children():
		if child.name != "Bridge":
			child.set_water_level(level)
