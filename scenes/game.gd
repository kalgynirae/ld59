extends Node2D

const SCREEN_TILE_WIDTH = 20
const SCREEN_TILE_HEIGHT = 16
const VIEWPORT_PIXELS: Vector2i = Vector2(320, 256)

const HOME = Vector2i(0, 0)
const DESERT = Vector2i(-1, 0)
const TOWER = Vector2i(-2, 0)
const SOUTH = Vector2i(0, 1)
const RIVER = Vector2i(1, 0)
const NORTH = Vector2i(0, -1)

var current_mode: Mode = Mode.Init
var current_direction: String = ""
var current_move_speed: int = 2
var current_screen_coords: Vector2i = Vector2i(0, 0)
var saved_snake_state = null

enum Mode {
	Init,
	Menu,
	Running,
	CameraMoving,
	RiverFilling,
	Shape,
	Dead,
	Resurrecting,
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
		[Mode.RiverFilling, Mode.Running]:
			allowed = true
		[Mode.Running, Mode.RiverFilling]:
			allowed = true
		[Mode.Running, Mode.Dead]:
			allowed = true
			$MoveTimer.stop()
			$Map/Snake.die()
			$Camera/Panel.display_death_message(DeathPanel.DeathType.EAT_SELF)
			$ResurrectTimer.start()
		[Mode.Dead, Mode.Resurrecting]:
			$Camera/Panel.hide_message()
			allowed = true
		[Mode.Resurrecting, Mode.Running]:
			allowed = true
			$MoveTimer.start()
	if allowed:
		current_mode = mode
	else:
		print("Mode transition blocked: %s -> %s" % [Mode.keys()[current_mode], Mode.keys()[mode]])
	return allowed

enum Maps {
	Start,
	Desert,
	Rain,
	Switch,
	Box,
}

func change_screen() -> bool:
	var snake_loc: Vector2i = $Map/Snake.gridlocs[0]
	# Note: Integer division rounds toward 0, so we can't use it here
	var snake_screen_coords = Vector2i(
		floor(float(snake_loc.x) / SCREEN_TILE_WIDTH),
		floor(float(snake_loc.y) / SCREEN_TILE_HEIGHT),
	)
	if snake_screen_coords != current_screen_coords:
		current_screen_coords = snake_screen_coords
		var new_position = current_screen_coords * VIEWPORT_PIXELS
		$Camera.position = new_position
		set_mode(Mode.CameraMoving)
		return true
	return false

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
		if change_screen():
			save_snake()
	if Input.is_action_just_pressed("die"):
		set_mode(Mode.Dead)
	if Input.is_action_just_pressed("speed_up"):
		change_move_speed(1)
	if Input.is_action_just_pressed("speed_down"):
		change_move_speed(-1)

func _ready() -> void:
	$Map/Snake.init(Vector2i(9, 7), "down", 3)
	current_direction = "down"
	change_move_speed(0)
	set_mode(Mode.Running)

func save_snake() -> void:
	saved_snake_state = [$Map/Snake.save_state(), current_direction]

func restore_snake() -> void:
	if saved_snake_state:
		$Map/Snake.restore_state(saved_snake_state[0])
		$Map/Snake.set_power_level(count_power_sources())
		current_direction = saved_snake_state[1]
	else:
		print("Cannot restore snake because saved state is null :(")

func on_resurrect_timer_timeout() -> void:
	set_mode(Mode.Resurrecting)
	print("Restoring snake")
	restore_snake()
	await get_tree().create_timer(1.0).timeout
	set_mode(Mode.Running)

func on_move_timer_timeout() -> void:
	if current_mode == Mode.RiverFilling:
		return
	
	if current_mode == Mode.CameraMoving:
		set_mode(Mode.Running)
	elif current_direction != "" and current_move_speed > 0:
		move_snake(current_direction)
		if change_screen():
			save_snake()

func on_hurt_timer_timeout() -> void:
	if detect_desert():
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

func detect_obstacles() -> bool:
	var loc = $Map/Snake.gridlocs[0]
	var tile_data = $Map/Ground.get_cell_tile_data(loc)
	return tile_data and tile_data.get_custom_data("obstacle")

func detect_desert() -> bool:
	var loc = $Map/Snake.gridlocs[0]
	var tile_data = $Map/Ground.get_cell_tile_data(loc)
	return tile_data and tile_data.get_custom_data("desert")

func count_power_sources() -> int:
	var count = 0
	for ps in find_children("power_source*"):
		if not ps.powered:
			continue
		if $Map/Snake.gridlocs.has(GridLoc.from_position(ps.position)):
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
	if $Map/Snake.detect_self_collision() or detect_obstacles():
		set_mode(Mode.Dead)
		return

	if $Map/Snake.detect_shape():
		match $Map/Snake.active_shape:
			Snake.Shape.Wave:
				flip_switches()
			Snake.Shape.Square:
				break_boxes()
			Snake.Shape.Cloud:
				$Map/Snake.flash_n(2)
				set_mode(Mode.RiverFilling)
				await $Map/river.fill()
				set_mode(Mode.Running)

	$Map/Snake.set_power_level(count_power_sources())

	handle_touching_food()

func flip_switches():
	match current_screen_coords:
		NORTH:
			for switch in $Map/UpperSwitches.get_children():
				switch.toggle()

func break_boxes():
	match current_screen_coords:
		DESERT:
			for box in $Map/desert_boxes.get_children():
				box.break_()
		SOUTH:
			for box in $Map/flowerpatch_boxes.get_children():
				box.break_()
