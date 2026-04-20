extends Node2D

const Shape = Snake.Shape

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
var current_move_speed: int = 1
var current_screen_coords: Vector2i = Vector2i(0, 0)
var current_hp: int = 5
var saved_food_state: Dictionary[Node, bool] = {}
var saved_snake_state = null
var active_shape: Shape = Shape.None
var desert_harmful: bool = true

enum Mode {
	Init,
	Menu,
	Running,
	CameraMoving,
	Transmitting,
	Raining,
	BreakingBoxes,
	FlippingSwitches,
	ActivatingTower,
	Shape,
	Dead,
	Resurrecting,
}

func set_mode(mode: Mode) -> bool:
	print("set_mode(%s)" % Mode.keys()[mode])
	var allowed = true
	match [current_mode, mode]:
		[Mode.Init, Mode.Running]:
			$MoveTimer.start()
		[Mode.Running, Mode.CameraMoving]:
			pass
		[Mode.CameraMoving, Mode.Running]:
			pass
		[Mode.Running, Mode.Transmitting]:
			transmit()
		[Mode.Transmitting, Mode.Raining]:
			rain()
		[Mode.Raining, Mode.Running]:
			pass
		[Mode.Transmitting, Mode.BreakingBoxes]:
			break_boxes()
		[Mode.BreakingBoxes, Mode.Running]:
			pass
		[Mode.Transmitting, Mode.FlippingSwitches]:
			flip_switches()
		[Mode.FlippingSwitches, Mode.Running]:
			pass
		[Mode.Running, Mode.Dead]:
			$MoveTimer.stop()
			$Map/Snake.die()
			$Camera/Panel.display_death_message(DeathPanel.DeathType.EAT_SELF)
			$ResurrectTimer.start()
		[Mode.Dead, Mode.Resurrecting]:
			$Camera/Panel.hide_message()
		[Mode.Resurrecting, Mode.Running]:
			$MoveTimer.start()
		_:
			allowed = false
	if allowed:
		print("committing mode change %s -> %s" % [Mode.keys()[current_mode], Mode.keys()[mode]])
		current_mode = mode
	else:
		print("Mode transition blocked: %s -> %s" % [Mode.keys()[current_mode], Mode.keys()[mode]])
	return allowed

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

func _process(_delta: float) -> void:
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
			save_state()
	if Input.is_action_just_pressed("die"):
		set_mode(Mode.Dead)
	if Input.is_action_just_pressed("speed_up"):
		change_move_speed(1)
	if Input.is_action_just_pressed("speed_down"):
		change_move_speed(-1)

func _ready() -> void:
	$Map/Snake.init(Vector2i(9, 8), "down", 11)
	current_direction = "down"
	change_move_speed(0)
	save_state()
	set_mode(Mode.Running)

func save_state() -> void:
	saved_food_state = {}
	for food in $Map/food.get_children():
		saved_food_state[food] = food.save_state()
	saved_snake_state = [$Map/Snake.save_state(), current_direction]

func restore_state() -> void:
	for food in $Map/food.get_children():
		food.restore_state(saved_food_state[food])

	$Map/Snake.restore_state(saved_snake_state[0])
	$Map/Snake.set_power_level(count_power_sources())
	current_direction = saved_snake_state[1]

func on_resurrect_timer_timeout() -> void:
	set_mode(Mode.Resurrecting)
	print("Restoring snake")
	restore_state()
	await get_tree().create_timer(1.0).timeout
	set_mode(Mode.Running)

func on_move_timer_timeout() -> void:
	match current_mode:
		Mode.CameraMoving:
			set_mode(Mode.Running)
		Mode.Running:
			if current_direction != "" and current_move_speed > 0:
				move_snake(current_direction)
				if change_screen():
					save_state()

func on_hurt_timer_timeout() -> void:
	if desert_harmful and detect_desert():
		$Map/Snake.hurt()
		current_hp -= 1
		if current_hp == 0:
			set_mode(Mode.Dead)
	else:
		current_hp = 5

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

func detect_boxes() -> bool:
	var loc = $Map/Snake.gridlocs[0]
	for box in $Map/desert_boxes.get_children():
		if box.unbroken() and loc == GridLoc.from_position(box.position):
			return true
	for box in $Map/flowerpatch_boxes.get_children():
		if box.unbroken() and loc == GridLoc.from_position(box.position):
			return true
	return false

func detect_switches() -> bool:
	var loc = $Map/Snake.gridlocs[0]
	for switch in $Map/UpperSwitches.get_children():
		if switch.is_raised() and loc == GridLoc.from_position(switch.position):
			return true
	return false

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

func eat_food(direction: String) -> bool:
	var head_loc = $Map/Snake.gridlocs[0] + GridLoc.offset(direction)
	for food in $Map/food.get_children():
		if food.uneaten() and GridLoc.from_position(food.position) == head_loc:
			food.eat()
			return true
	return false

func has_collided_with_bridge() -> bool:
	var loc: Vector2i = $Map/Snake.gridlocs[0]
	var bridge_loc = GridLoc.from_position($Map/river/Bridge.position)
	var cur_water_level = $Map/river/Bridge.bridge_level
	var safe_water_level: bool = cur_water_level == Bridge.BridgeLevel.BRAND_NEW or cur_water_level == Bridge.BridgeLevel.REPAIRED
	return not safe_water_level and loc.y == bridge_loc.y and loc.x == bridge_loc.x + 1

func move_snake(direction: String) -> void:
	if eat_food(direction):
		$Map/Snake.extend(direction)
	else:
		$Map/Snake.move(direction)
	if $Map/Snake.detect_self_collision() or detect_obstacles() or has_collided_with_bridge() or detect_boxes() or detect_switches():
		set_mode(Mode.Dead)
		return
	if $Map/Snake.detect_shape():
		active_shape = $Map/Snake.active_shape
		if active_shape != Shape.None:
			set_mode(Mode.Transmitting)
	$Map/Snake.set_power_level(count_power_sources())

func transmit() -> void:
	match active_shape:
		Shape.Cloud:
			await $Map/Snake.flash_n(2)
			set_mode(Mode.Raining)
		Shape.Wave:
			await $Map/Snake.flash_n(2)
			set_mode(Mode.FlippingSwitches)
		Shape.Square:
			await $Map/Snake.flash_n(2)
			set_mode(Mode.BreakingBoxes)
		_:
			print("shape not handled yet: %s" % Shape.keys()[active_shape])

func rain() -> void:
	%Rain.emitting = true
	%Rain.amount = 64
	await get_tree().create_timer(0.5).timeout
	%Rain.amount = 192
	match current_screen_coords:
		RIVER:
			$Map/river.fill()
			resurrect_plants($Map/river_plants.get_children())
			await get_tree().create_timer(4.0).timeout
		DESERT:
			desert_harmful = false
			%Heat.emitting = false
			await get_tree().create_timer(3.0).timeout
	%Rain.emitting = false
	set_mode(Mode.Running)

func flip_switches():
	match current_screen_coords:
		NORTH:
			for switch in $Map/UpperSwitches.get_children():
				switch.toggle()
	await get_tree().create_timer(1.0).timeout
	set_mode(Mode.Running)

func break_boxes():
	match current_screen_coords:
		DESERT:
			for box in $Map/desert_boxes.get_children():
				box.explode()
		SOUTH:
			for box in $Map/flowerpatch_boxes.get_children():
				box.explode()
	await get_tree().create_timer(1.0).timeout
	set_mode(Mode.Running)

func resurrect_plants(plants):
	plants.shuffle()
	for plant in plants:
		await get_tree().create_timer(0.02).timeout
		plant.growth_stage -= 1
