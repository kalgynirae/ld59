extends Node2D

var parts: Array[Vector2i] = []

var SnakePart = preload("res://scenes/snake_part.tscn")

func move(direction: String):
	var head = parts[0]
	var new
	match direction:
		"left":
			new = Vector2i(head.x - 1, head.y)
		"right":
			new = Vector2i(head.x + 1, head.y)
		"up":
			new = Vector2i(head.x, head.y - 1)
		"down":
			new = Vector2i(head.x, head.y + 1)
	parts.insert(0, new)
	parts.pop_back()

func _ready() -> void:
	parts.append(Vector2i(12, 12))
	parts.append(Vector2i(12, 13))
	
	for i in range(len(parts)):
		add_child(SnakePart.instantiate())

func _process() -> void:
	if 
