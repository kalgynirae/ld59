extends Node
class_name GridLoc

const TILE_PIXELS: int = 16

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

static func from_position(position: Vector2) -> Vector2i:
	return Vector2i(
		floor(position.x / TILE_PIXELS),
		floor(position.y / TILE_PIXELS),
	)
