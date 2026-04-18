extends Node2D

enum Objects {
	PLANT = 1
}

func is_touching(obj: Objects) -> bool:
	var head_pos = $Snake.gridlocs[0]
	
	var data = $Ground/Decorations.get_cell_tile_data(head_pos)
	
	if data != null:
		return data.get_custom_data("interact") == obj
	
	return false

func move_snake(direction: String) -> void:
	$Snake.move(direction)
