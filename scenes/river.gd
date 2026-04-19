extends Node2D

func set_water_level(level: RiverTile.WaterLevel) -> void:
	for child in get_children():
		child.set_water_level(level)
