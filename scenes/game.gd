extends Node2D

const VIEWPORT_WIDTH: int = 320
const VIEWPORT_HEIGHT: int = 256

const TILE_WIDTH: int = 20
const TILE_HEIGHT: int = 16

var current_map: Maps = Maps.Start
var current_mode: Mode = Mode.Init
var current_direction: String = ""

enum Mode {
	Init,
	Menu,
	Running,
	CameraMoving,
}

func set_mode(mode: Mode) -> bool:
	var allowed = false
	match [current_mode, mode]:
		[Mode.Init, Mode.Running]:
			allowed = true
			$MoveTimer.start()
		[Mode.Running, Mode.CameraMoving]:
			allowed = true
		[Mode.CameraMoving, Mode.Running]:
			allowed = true
	if allowed:
		current_mode = mode
	return allowed

enum Maps {
	Start,
	Desert,
	Rain,
	Switch,
	Box,
}

func update_camera() -> void:
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
			move_camera(Vector2(0, 0))
		Maps.Desert:
			move_camera(Vector2(-VIEWPORT_WIDTH, 0))
		Maps.Rain:
			move_camera(Vector2(VIEWPORT_WIDTH, 0))
		Maps.Switch:
			move_camera(Vector2(0, -VIEWPORT_HEIGHT))
		Maps.Box:
			move_camera(Vector2(0, VIEWPORT_HEIGHT))

func _process(delta: float) -> void:
	update_camera()
	if Input.is_action_just_pressed("move_right"):
		current_direction = "right"
	if Input.is_action_just_pressed("move_left"):
		current_direction = "left"
	if Input.is_action_just_pressed("move_down"):
		current_direction = "down"
	if Input.is_action_just_pressed("move_up"):
		current_direction = "up"
	if Input.is_action_just_pressed("extend"):
		$Map/Snake.extend($Snake.head_direction())
	if Input.is_action_just_pressed("retract"):
		$Map/Snake.retract()
	if Input.is_action_just_pressed("die"):
		$Map/Snake.die()

func move_camera(position: Vector2) -> void:
	if $Camera.position != position:
		$Camera.position = position
		set_mode(Mode.CameraMoving)

func _ready() -> void:
	$Map/Snake.init(Vector2i(8,4), "right", 6)
	current_direction = "right"
	set_mode(Mode.Running)

func on_move_timer_timeout() -> void:
	if current_mode == Mode.CameraMoving:
		set_mode(Mode.Running)
	elif current_direction != "":
		$Map.move_snake(current_direction)
