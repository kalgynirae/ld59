extends Node2D

const VIEWPORT_WIDTH: int = 320
const VIEWPORT_HEIGHT: int = 256

const TILE_WIDTH: int = 20
const TILE_HEIGHT: int = 16

var current_map: Maps = Maps.Start

enum Maps {
	Start,
	Desert,
	Rain,
	Switch,
	Box
}

func _process(delta: float) -> void:
	var snake_pos: Vector2i = $Map/Snake.gridlocs[0]

	if snake_pos.y >= -TILE_HEIGHT && snake_pos.y < 0:
		current_map = Maps.Switch
	elif snake_pos.y >= TILE_HEIGHT && snake_pos.y < TILE_HEIGHT * 2:
		current_map = Maps.Box
	elif snake_pos.x >= 0 && snake_pos.x < TILE_WIDTH:
		current_map = Maps.Start
	elif snake_pos.x >= -TILE_WIDTH && snake_pos.x < 0:
		current_map = Maps.Desert
	elif snake_pos.x >= TILE_WIDTH && snake_pos.x < TILE_WIDTH * 2:
		current_map = Maps.Rain

	match current_map:
		Maps.Start:
			$Camera.position = Vector2i(0, 0)
		Maps.Desert:
			$Camera.position = Vector2i(-VIEWPORT_WIDTH, 0)
		Maps.Rain:
			$Camera.position = Vector2i(VIEWPORT_WIDTH, 0)
		Maps.Switch:
			$Camera.position = Vector2i(0, -VIEWPORT_HEIGHT)
		Maps.Box:
			$Camera.position = Vector2i(0, VIEWPORT_HEIGHT)
