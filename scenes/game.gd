extends Node2D

const SCREEN_TILE_WIDTH = 20
const SCREEN_TILE_HEIGHT = 16
const VIEWPORT_PIXELS: Vector2i = Vector2(320, 256)

var current_mode: Mode = Mode.Init
var current_direction: String = ""
var current_move_speed: int = 2
var current_screen_coords: Vector2i = Vector2i(0, 0)

enum Mode {
	Init,
	Menu,
	Running,
	CameraMoving,
	Shape,
	Dead,
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
		[Mode.Running, Mode.Dead]:
			allowed = true
			$MoveTimer.stop()
			$Map/Snake.die()
	if allowed:
		current_mode = mode
	else:
		print("Mode transition blocked: %s -> %s" % [current_mode, mode])
	return allowed

enum Maps {
	Start,
	Desert,
	Rain,
	Switch,
	Box,
}

func update_camera() -> void:
	var snake_loc: Vector2i = $Map/Snake.gridlocs[0]
	# Note: Integer division rounds toward 0, so we can't use it here
	var snake_screen_coords = Vector2i(
		floor(float(snake_loc.x) / SCREEN_TILE_WIDTH),
		floor(float(snake_loc.y) / SCREEN_TILE_HEIGHT),
	)
	if snake_screen_coords != current_screen_coords:
		current_screen_coords = snake_screen_coords
		move_camera(current_screen_coords * VIEWPORT_PIXELS)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("move_right"):
		if $Map/Snake.head_direction() != "left":
			current_direction = "right"
	if Input.is_action_just_pressed("move_left"):
		if $Map/Snake.head_direction() != "right":
			current_direction = "left"
	if Input.is_action_just_pressed("move_down"):
		if $Map/Snake.head_direction() != "up":
			current_direction = "down"
	if Input.is_action_just_pressed("move_up"):
		if $Map/Snake.head_direction() != "down":
			current_direction = "up"
	if Input.is_action_just_pressed("extend"):
		$Map/Snake.extend($Map/Snake.head_direction())
		update_camera()
	if Input.is_action_just_pressed("retract"):
		$Map/Snake.retract()
	if Input.is_action_just_pressed("die"):
		set_mode(Mode.Dead)
	if Input.is_action_just_pressed("speed_up"):
		change_move_speed(1)
	if Input.is_action_just_pressed("speed_down"):
		change_move_speed(-1)

func move_camera(position: Vector2) -> void:
	if $Camera.position != position:
		$Camera.position = position
		set_mode(Mode.CameraMoving)

func _ready() -> void:
	$Map/Snake.init(Vector2i(8,4), "right", 6)
	current_direction = "right"
	change_move_speed(0)
	set_mode(Mode.Running)

func on_move_timer_timeout() -> void:
	if current_mode == Mode.CameraMoving:
		set_mode(Mode.Running)
	elif current_direction != "" and current_move_speed > 0:
		move_snake(current_direction)
		update_camera()

func on_hurt_timer_timeout() -> void:
	# TODO: fix the desert
	if false:
		$Map/Snake.hurt()

func change_move_speed(change: int) -> void:
	if change > 0 and current_move_speed < 3 or change < 0 and current_move_speed > 0:
		current_move_speed = current_move_speed + change
	match current_move_speed:
		0:
			pass # handled in on_move_timer_timeout
		1:
			$MoveTimer.wait_time = 0.36
		2:
			$MoveTimer.wait_time = 0.25
		3:
			$MoveTimer.wait_time = 0.15

# These values are defined as a custom data layer on the individual tiles of the tilemap
#
# e.g. The sprite for the power source has a manually set value of "2"
enum Objects {
	PLANT = 1,
	POWER_SOURCE = 2,
	OBSTACLE = 3,
}

func get_tilemap_data(pos: Vector2i):
	var ground_data = $Map/Ground.get_cell_tile_data(pos)
	if ground_data:
		return ground_data.get_custom_data("interact")

func is_touching(obj: Objects) -> bool:
	var head_pos = $Map/Snake.gridlocs[0]
	return get_tilemap_data(head_pos) == obj

func num_touching(obj: Objects) -> int:
	var count: int = 0
	for pos in $Map/Snake.gridlocs:
		if get_tilemap_data(pos) == obj:
			count += 1
	return count

func handle_touching_food():
	var snake_head: Vector2i = $Map/Snake.gridlocs[0]
	for food_node in $Map/food_nodes.get_children():
		# Convert from snake space into world space
		if Vector2i(food_node.position) / 16 == snake_head:
			food_node.eat()

func move_snake(direction: String) -> void:
	$Map/Snake.move(direction)
	if $Map/Snake.detect_self_collision() or is_touching(Objects.OBSTACLE):
		set_mode(Mode.Dead)
		return

	if $Map/Snake.detect_shape():
		match $Map/Snake.active_shape:
			Snake.Shape.Wave:
				flip_switches()
			Snake.Shape.Square:
				for box in $Map/desert_boxes.get_children():
					box.visible = false
			Snake.Shape.Cloud:
				$Map/river.fill()

	var touching_sources = num_touching(Objects.POWER_SOURCE)
	$Map/Snake.set_power_level(touching_sources)
	
	handle_touching_food()

func flip_switches():
	for switch in find_children("switch*"):
		switch.toggle()
