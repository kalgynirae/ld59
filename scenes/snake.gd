extends Node2D

var gridlocs: Array[Vector2i] = []

var SnakePart = preload("res://scenes/snake_part.tscn")

func add_part(pos: Vector2i):
	gridlocs.append(pos)
	add_child(SnakePart.instantiate())
	
func move(direction: String):
	var head = gridlocs[0]
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
	gridlocs.insert(0, new)
	gridlocs.pop_back()
	
	var parts = get_children()
	assert(parts.size() == gridlocs.size())
	# parts[0] is the head
	parts[0].move_to(gridlocs[0])
	if parts.size() > 1:
		# middle parts:
		for i in range(1, gridlocs.size() - 1):
			parts[i].move_to(gridlocs[i])
			# TODO: orientation!
		# parts[-1] is the tail
		parts[-1].move_to(gridlocs[-1])

func _ready() -> void:
	add_part(Vector2i(12, 12))
	add_part(Vector2i(12, 13))
	add_part(Vector2i(12, 14))
	add_part(Vector2i(12, 15))
