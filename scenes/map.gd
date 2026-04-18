extends Node2D

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("move_right"):
		$Snake.move("right")
	if Input.is_action_just_pressed("move_left"):
		$Snake.move("left")
	if Input.is_action_just_pressed("move_down"):
		$Snake.move("down")
	if Input.is_action_just_pressed("move_up"):
		$Snake.move("up")
