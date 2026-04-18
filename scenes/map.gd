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

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("move_right"):
		$Snake.move("right")
	if Input.is_action_just_pressed("move_left"):
		$Snake.move("left")
	if Input.is_action_just_pressed("move_down"):
		$Snake.move("down")
	if Input.is_action_just_pressed("move_up"):
		$Snake.move("up")
	if Input.is_action_just_pressed("extend"):
		$Snake.extend($Snake.head_direction())
	if Input.is_action_just_pressed("retract"):
		$Snake.retract()
	if Input.is_action_just_pressed("die"):
		$Snake.die()
