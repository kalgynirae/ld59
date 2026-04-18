extends Node2D

var gridlocs: Array[Vector2i] = []
var parts: Array[SnakePart] = []

var SnakePartScene = preload("res://scenes/snake_part.tscn")

var Part = SnakePart.Part

func start_at(loc: Vector2i, dir: String):
	gridlocs.append(loc)
	var head = SnakePartScene.instantiate()
	parts.append(head)
	add_child(head)
	head.set_direction(dir)
	head.set_part(Part.HEAD)

func add_part():
	assert(parts.size() > 0)
	var old_tail = parts[-1]
	var newloc = GridLoc.move(gridlocs[-1], parts[-1].direction)
	gridlocs.append(newloc)
	var new = SnakePartScene.instantiate()
	parts.append(new)
	add_child(new)
	new.move_to(newloc)
	new.set_direction(parts[-1].direction)
	new.set_part(Part.TAIL)

	if parts.size() > 2:
		if parts[-3].current_part == Part.BODY_1:
			parts[-2].set_part(Part.BODY_2)
		else:
			parts[-2].set_part(Part.BODY_1)

func move(direction: String):
	assert(parts.size() > 0)
	var newloc = GridLoc.move(gridlocs[0], direction)
	gridlocs.insert(0, newloc)
	gridlocs.pop_back()
	parts.insert(0, parts.pop_back())

	# parts[0] is the new head
	parts[0].move_to(gridlocs[0])
	parts[0].set_part(Part.HEAD)
	parts[0].set_direction(direction)

	# parts[1] May need to change shape
	if parts.size() > 2:
		var part = parts[1]
		var head = gridlocs[0]
		var loc = gridlocs[1]
		var after = gridlocs[2]
		if head.x < loc.x:
			part.set_direction("left")
			if loc.x < after.x:
				# TODO: body alternation
				part.set_part(Part.BODY_1)
			elif loc.y < after.y:
				# TODO: corner left to down
				part.set_part(Part.CORNER)
			elif loc.y > after.y:
				# TODO: corner left to up
				part.set_part(Part.CORNER)
		elif head.x > loc.x:
			part.set_direction("right")
			if loc.x > after.x:
				# TODO: body alternation
				part.set_part(Part.BODY_1)
			elif loc.y < after.y:
				# TODO: corner right to down
				part.set_part(Part.CORNER)
			elif loc.y > after.y:
				# TODO: corner right to up
				part.set_part(Part.CORNER)
		elif head.y < loc.y:
			part.set_direction("up")
			if loc.y < after.y:
				# TODO: body alternation
				part.set_part(Part.BODY_1)
			elif loc.x < after.x:
				# TODO: corner up to left
				part.set_part(Part.CORNER)
			elif loc.x > after.x:
				# TODO: corner up to right
				part.set_part(Part.CORNER)
		elif head.y > loc.y:
			part.set_direction("down")
			if loc.y > after.y:
				# TODO: body alternation
				part.set_part(Part.BODY_1)
			elif loc.x < after.x:
				# TODO: corner down to left
				part.set_part(Part.CORNER)
			elif loc.x > after.x:
				# TODO: corner down to right
				part.set_part(Part.CORNER)


	# parts[-1] is now the tail
	if parts.size() > 1:
		parts[-1].set_part(Part.TAIL)

func _ready() -> void:
	start_at(Vector2i(4, 8), "right")
	for i in 5:
		add_part()
