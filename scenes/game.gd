extends Node2D

const Shape = Snake.Shape

const CHEATING = true

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
	Winging,
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
		[Mode.Transmitting, Mode.ActivatingTower]:
			activate_tower()
		[Mode.ActivatingTower, Mode.Running]:
			pass
		[Mode.Running, Mode.Dead]:
			$MoveTimer.stop()
			$Map/Snake.die()
			show_message("Snake has perished.")
			resurrect()
		[Mode.Dead, Mode.Resurrecting]:
			hide_message()
		[Mode.Resurrecting, Mode.Running]:
			$MoveTimer.start()
		[Mode.Transmitting, Mode.Winging]:
			wing_snake()
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
		
		if current_screen_coords == DESERT and desert_harmful:
			$Music.stream_paused = true
			$SoundWind.play()
		else:
			$SoundWind.stop()
			$Music.stream_paused = false
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
	if Input.is_action_just_pressed("die"):
		set_mode(Mode.Dead)
	if Input.is_action_just_pressed("speed_up"):
		change_move_speed(1)
	if Input.is_action_just_pressed("speed_down"):
		change_move_speed(-1)
	if CHEATING:
		if Input.is_action_just_pressed("extend"):
			$Map/Snake.extend($Map/Snake.head_direction())
			if change_screen():
				save_state()
		if Input.is_action_just_pressed("boxes"):
			break_boxes()
		if Input.is_action_just_pressed("rain"):
			rain()
		if Input.is_action_just_pressed("tower"):
			activate_tower()
		if Input.is_action_just_pressed("switches"):
			flip_switches()

func _ready() -> void:
	$Map/Snake.init(Vector2i(9, 8), "down", 11)
	current_direction = "down"
	change_move_speed(0)
	save_state()
	set_mode(Mode.Running)

func save_state() -> void:
	saved_snake_state = [$Map/Snake.gridlocs[0], $Map/Snake.head_direction()]

func restore_state() -> void:
	$Map/Snake.rebuild_snake(saved_snake_state[0], saved_snake_state[1])
	current_direction = saved_snake_state[1]

func resurrect() -> void:
	await get_tree().create_timer(2.0).timeout
	set_mode(Mode.Resurrecting)
	restore_state()
	await get_tree().create_timer(0.5).timeout
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
	for box in $Map/home_boxes.get_children():
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

func count_power_sources() -> SnakePart.PowerLevel:
	for ps in find_children("power_source*"):
		if not ps.powered:
			continue
		if $Map/Snake.gridlocs.has(GridLoc.from_position(ps.position)):
			if not $SoundBuzz.playing:
				$SoundBuzz.play()
			return SnakePart.PowerLevel.CHARGED
	$SoundBuzz.playing = false
	return SnakePart.PowerLevel.NORMAL

func eat_food(direction: String) -> bool:
	var head_loc = $Map/Snake.gridlocs[0] + GridLoc.offset(direction)
	for food in $Map/food.get_children():
		if food.uneaten() and GridLoc.from_position(food.position) == head_loc:
			food.eat()
			$SoundEat.playing = true
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
	$Map/Snake.set_power_level(count_power_sources())
	if $Map/Snake.detect_self_collision() or detect_obstacles() or has_collided_with_bridge() or detect_boxes() or detect_switches():
		set_mode(Mode.Dead)
		return
	if $Map/Snake.detect_shape():
		active_shape = $Map/Snake.active_shape
		if active_shape != Shape.None:
			set_mode(Mode.Transmitting)

func transmit() -> void:
	$SoundSignal.play()
	await $Map/Snake.transmit()
	match active_shape:
		Shape.Cloud:
			set_mode(Mode.Raining)
		Shape.Wave:
			set_mode(Mode.FlippingSwitches)
		Shape.Square:
			set_mode(Mode.BreakingBoxes)
		Shape.Tower:
			set_mode(Mode.ActivatingTower)
		Shape.Wings:
			set_mode(Mode.Winging)
		_:
			print("shape not handled yet: %s" % Shape.keys()[active_shape])

func rain() -> void:
	$SoundRain.playing = true
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
			$SoundWind.stop()
			desert_harmful = false
			%Heat.emitting = false
			await get_tree().create_timer(3.0).timeout
			$Music.stream_paused = false
	%Rain.emitting = false
	set_mode(Mode.Running)

func flip_switches():
	var any_flipped = false
	match current_screen_coords:
		NORTH:
			for switch in $Map/UpperSwitches.get_children():
				any_flipped = switch.toggle() or any_flipped
	if any_flipped:
		$SoundExplosion.play()
	await get_tree().create_timer(1.0).timeout
	set_mode(Mode.Running)

func break_boxes():
	var any_exploded = false
	match current_screen_coords:
		DESERT:
			for box in $Map/desert_boxes.get_children():
				any_exploded = box.explode() or any_exploded
		SOUTH:
			for box in $Map/flowerpatch_boxes.get_children():
				any_exploded = box.explode() or any_exploded
		HOME:
			for box in $Map/home_boxes.get_children():
				any_exploded = box.explode() or any_exploded
	if any_exploded:
		$SoundExplosion.play()
	await get_tree().create_timer(1.0).timeout
	set_mode(Mode.Running)

func resurrect_plants(plants):
	plants.shuffle()
	for plant in plants:
		await get_tree().create_timer(0.02).timeout
		plant.growth_stage -= 1

func activate_tower():
	$Map/TowerSparks.emitting = true
	await get_tree().create_timer(1.0).timeout
	$Map/WireSparks.emitting = true
	for p in $Map/power.get_children():
		if p.towered:
			p.power_on()
	await get_tree().create_timer(2.0).timeout
	set_mode(Mode.Running)

func show_message(msg: String) -> void:
	%Message.text = msg
	%MessageFrame.visible = true

func hide_message() -> void:
	%MessageFrame.visible = false

func wing_snake() -> void:
	$Map/Snake.grow_wings()
	await get_tree().create_timer(2.0).timeout
	for i in 12:
		await get_tree().create_timer(0.1).timeout
		$Map/Snake.position.y -= 1
	await get_tree().create_timer(0.8).timeout
	for i in 20:
		await get_tree().create_timer(0.08).timeout
		$Map/Snake.position.y -= 1.5
		$Map/Snake.position.x += 0.1
	for i in 60:
		await get_tree().create_timer(0.06).timeout
		$Map/Snake.position.y -= 2
		$Map/Snake.position.x += 0.5
	for i in 80:
		await get_tree().create_timer(0.04).timeout
		$Map/Snake.position.y -= 2.2
		$Map/Snake.position.x += 0.8
	for i in 100:
		await get_tree().create_timer(0.02).timeout
		%Curtain.color.a += 0.01

func _on_sound_wind_finished() -> void:
	$SoundWind.play(1.15)
