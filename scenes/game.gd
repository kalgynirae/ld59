extends Node2D

const VIEWPORT_WIDTH: int = 192
const VIEWPORT_HEIGHT: int = 144

var current_map: Maps = Maps.Start

enum Maps {
	Start,
	Dessert
}

func _process(delta: float) -> void:
	var snake_pos: Vector2i = $Map/Snake.gridlocs[0]
	
	print(snake_pos)
	if snake_pos.x > 0 && snake_pos.x < VIEWPORT_WIDTH:
		current_map = Maps.Start
	if snake_pos.x > -VIEWPORT_WIDTH && snake_pos.x < 0:
		current_map = Maps.Dessert
	
	match current_map:
		Maps.Start:
			$Camera.offset = Vector2i(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
		Maps.Dessert:
			$Camera.offset = Vector2i(-VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
