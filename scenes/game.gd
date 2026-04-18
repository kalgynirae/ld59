extends Node2D

const VIEWPORT_WIDTH: int = 192
const VIEWPORT_HEIGHT: int = 144

const TILE_WIDTH: int = 24
const TILE_HEIGHT: int = 18

var current_map: Maps = Maps.Start

enum Maps {
	Start,
	Dessert,
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
		current_map = Maps.Dessert
	elif snake_pos.x >= TILE_WIDTH && snake_pos.x < TILE_WIDTH * 2:
		current_map = Maps.Rain

	match current_map:
		Maps.Start:
			$Camera.offset = Vector2i(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
		Maps.Dessert:
			$Camera.offset = Vector2i(-VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
		Maps.Rain:
			$Camera.offset = Vector2i(VIEWPORT_WIDTH * 3, VIEWPORT_HEIGHT)
		Maps.Switch:
			$Camera.offset = Vector2i(VIEWPORT_WIDTH, -VIEWPORT_HEIGHT)
		Maps.Box:
			$Camera.offset = Vector2i(VIEWPORT_WIDTH, VIEWPORT_HEIGHT * 3)
