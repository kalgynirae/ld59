extends Node2D
class_name Snake

var gridlocs: Array[Vector2i] = []
var parts: Array[SnakePart] = []

var SnakePartScene = preload("res://scenes/snake_part.tscn")

var Part = SnakePart.Part
var Turn = SnakePart.Turn

enum Shape {
	None,
	Square,
	Wave,
	Cloud,
}

func head_direction() -> String:
	return parts[0].direction

func start_at(loc: Vector2i, dir: String):
	gridlocs.append(loc)
	var head = SnakePartScene.instantiate()
	parts.append(head)
	add_child(head)
	head.move_to(loc)
	head.set_direction(dir)
	head.set_part(Part.HEAD)

func add_part():
	assert(parts.size() > 0)
	var dir = parts[-1].direction
	var newloc = gridlocs[-1] - GridLoc.offset(dir)
	gridlocs.append(newloc)
	var new = SnakePartScene.instantiate()
	parts.append(new)
	add_child(new)
	new.move_to(newloc)
	new.set_direction(dir)
	new.set_part(Part.TAIL)
	if parts.size() > 2:
		parts[-2].set_part(Part.BODY_1)

func extend(direction: String):
	add_part()
	move(direction)

func retract():
	if parts.size() > 4:
		gridlocs.pop_back()
		parts.pop_back().queue_free()
		update_tail()

func move(direction: String):
	assert(parts.size() > 0)
	var newloc = gridlocs[0] + GridLoc.offset(direction)
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
				part.set_part(Part.CORNER, true)
			elif loc.y > after.y:
				part.set_part(Part.CORNER, false)
		elif head.x > loc.x:
			part.set_direction("right")
			if loc.x > after.x:
				# TODO: body alternation
				part.set_part(Part.BODY_1)
			elif loc.y < after.y:
				part.set_part(Part.CORNER, false)
			elif loc.y > after.y:
				part.set_part(Part.CORNER, true)
		elif head.y < loc.y:
			part.set_direction("up")
			if loc.y < after.y:
				# TODO: body alternation
				part.set_part(Part.BODY_1)
			elif loc.x < after.x:
				part.set_part(Part.CORNER, false)
			elif loc.x > after.x:
				part.set_part(Part.CORNER, true)
		elif head.y > loc.y:
			part.set_direction("down")
			if loc.y > after.y:
				# TODO: body alternation
				part.set_part(Part.BODY_1)
			elif loc.x < after.x:
				part.set_part(Part.CORNER, true)
			elif loc.x > after.x:
				part.set_part(Part.CORNER, false)
	update_tail()
	
func update_tail() -> void:
	if parts.size() > 1:
		parts[-1].set_part(Part.TAIL)

func die() -> void:
	parts[0].show_dead()

func init(startloc: Vector2i, direction: String, length: int = 6) -> void:
	start_at(startloc, direction)
	for i in length - 1:
		add_part()

func detect_shape() -> Shape:
	var segments = [["s", 1]];
	for i in range(1, parts.size()):
		match parts[i].turn():
			Turn.None:
				if segments[-1][0] == "s":
					segments[-1][1] = segments[-1][1] + 1
				else:
					segments.append(["s", 1])
			Turn.Right:
				segments.append(["r", 1])
			Turn.Left:
				segments.append(["l", 1])
	print(segments)

	if segments_match(segments, SQUARE):
		return Shape.Square
	else:
		return Shape.None

const SQUARE = [
	[["s", 1], ["r", 1], ["s", 1], ["r", 1], ["s", 1], ["r", 1], ["s", 1]],
	[["s", 2], ["r", 1], ["s", 2], ["r", 1], ["s", 2], ["r", 1], ["s", 2]],
	[["s", 3], ["r", 1], ["s", 3], ["r", 1], ["s", 3], ["r", 1], ["s", 3]],
	[["s", 4], ["r", 1], ["s", 4], ["r", 1], ["s", 4], ["r", 1], ["s", 4]],
	[["s", 1], ["l", 1], ["s", 1], ["l", 1], ["s", 1], ["l", 1], ["s", 1]],
	[["s", 2], ["l", 1], ["s", 2], ["l", 1], ["s", 2], ["l", 1], ["s", 2]],
	[["s", 3], ["l", 1], ["s", 3], ["l", 1], ["s", 3], ["l", 1], ["s", 3]],
	[["s", 4], ["l", 1], ["s", 4], ["l", 1], ["s", 4], ["l", 1], ["s", 4]],
]

func segments_match(segments: Array, patterns: Array) -> bool:
	for pattern in patterns:
		if pattern.size() > segments.size():
			continue
		for offset in segments.size() - pattern.size():
			for i in pattern.size():
				pass  # TODO
	return false
