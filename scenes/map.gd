extends Node2D

# These values are defined as a custom data layer on the individual tiles of the tilemap
#
# e.g. The sprite for the power source has a manually set value of "2"
enum Objects {
	PLANT = 1,
	POWER_SOURCE = 2
}

func get_decoration_from_tilemap(pos: Vector2i):
	var data = $Ground/Decorations.get_cell_tile_data(pos)
	
	if data == null:
		return null
	
	return data.get_custom_data("interact")

func is_touching(obj: Objects) -> bool:
	var head_pos = $Snake.gridlocs[0]
	
	var data = get_decoration_from_tilemap(head_pos)
	
	if data != null:
		return data == obj
	
	return false

func num_touching(obj: Objects) -> int:
	var count: int = 0
	
	for pos in $Snake.gridlocs:
		var data = get_decoration_from_tilemap(pos)
		if data != null && data == obj:
			count += 1
		
	return count

func handle_touching_food():
	var snake_head: Vector2i = $Snake.gridlocs[0]
	
	for food_node in $food_nodes.get_children():
		# Convert from snake space into world space
		if Vector2i(food_node.position) / 16 == snake_head:
			food_node.eat()

func move_snake(direction: String) -> void:
	$Snake.move(direction)
	# TODO: detect if the snake ran into something
	if $Snake.detect_shape():
		match $Snake.active_shape:
			Snake.Shape.Wave:
				flip_switches()
			Snake.Shape.Square:
				$desert_boxes.break_all()

	var touching_sources = num_touching(Objects.POWER_SOURCE)
	$Snake.set_power_level(touching_sources)
	
	handle_touching_food()

func flip_switches():
	for switch in find_children("switch*"):
		switch.toggle()
