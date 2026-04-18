extends Node
class_name GridLoc

static func offset(dir: String) -> Vector2i:
	match dir:
		"left":
			return Vector2i(-1, 0)
		"right":
			return Vector2i(1, 0)
		"up":
			return Vector2i(0, -1)
		"down":
			return Vector2i(0, 1)
		_:
			assert(false, "Invalid direction")
			return Vector2i(0, 0)

static func move(loc: Vector2i, dir: String) -> Vector2i:
	return loc + offset(dir)
