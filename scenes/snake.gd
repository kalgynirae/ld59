extends Node2D
class_name Snake

# How long the snake will display a "hurt" animation for
@export_range(0, 10, 0.25) var hurt_time: float = 0.5

var active_shape: Shape = Shape.None
var gridlocs: Array[Vector2i] = []
var parts: Array[SnakePart] = []

var SnakePartScene = preload("res://scenes/snake_part.tscn")

var Part = SnakePart.Part
var Turn = SnakePart.Turn

enum Shape {
	None,
	Square,
	Wave,
	Cloud,
	Tower,
}

func head_direction() -> String:
	return parts[0].direction

func save_state():
	return [active_shape, gridlocs.duplicate(), head_direction()]

func restore_state(state):
	parts[0].hide_dead()
	active_shape = state[0]
	gridlocs = state[1].duplicate()
	for i in range(gridlocs.size(), parts.size()):
		parts.pop_back().queue_free()
	sync_snake_parts(state[2], true)

func start_at(loc: Vector2i, dir: String):
	gridlocs.append(loc)
	var head = SnakePartScene.instantiate()
	parts.append(head)
	add_child(head)
	head.move_to(loc)
	head.set_direction(dir)
	head.set_part(Part.HEAD)

func add_part():
	assert(parts.size() > 0)
	var dir = parts[-1].direction
	var newloc = gridlocs[-1] - GridLoc.offset(dir)
	gridlocs.append(newloc)
	var new = SnakePartScene.instantiate()
	parts.append(new)
	add_child(new)
	new.move_to(newloc)
	new.set_direction(dir)
	new.set_part(Part.TAIL)
	if parts.size() > 2:
		parts[-2].set_part(Part.BODY_1)

func extend(direction: String):
	add_part()
	move(direction)

func move(direction: String):
	assert(parts.size() > 0)
	var newloc = gridlocs[0] + GridLoc.offset(direction)
	gridlocs.insert(0, newloc)
	gridlocs.pop_back()
	parts.insert(0, parts.pop_back())
	sync_snake_parts(direction, false)

func sync_snake_parts(head_direction: String, full: bool):
	assert(parts.size() > 2, "Snakes of size < 3 are not supported")
	# parts[0] is the new head
	parts[0].move_to(gridlocs[0])
	parts[0].set_part(Part.HEAD)
	parts[0].set_direction(head_direction)

	# parts[1] May need to change shape
	var indices = range(1, parts.size() - 1) if full else [1]
	for i in indices:
		var part = parts[i]
		var before = gridlocs[i - 1]
		var loc = gridlocs[i]
		var after = gridlocs[i + 1]
		part.move_to(loc)
		if before.x < loc.x:
			part.set_direction("left")
			if loc.x < after.x:
				# TODO: body alternation
				part.set_part(Part.BODY_1)
			elif loc.y < after.y:
				part.set_part(Part.CORNER, true)
			elif loc.y > after.y:
				part.set_part(Part.CORNER, false)
		elif before.x > loc.x:
			part.set_direction("right")
			if loc.x > after.x:
				# TODO: body alternation
				part.set_part(Part.BODY_1)
			elif loc.y < after.y:
				part.set_part(Part.CORNER, false)
			elif loc.y > after.y:
				part.set_part(Part.CORNER, true)
		elif before.y < loc.y:
			part.set_direction("up")
			if loc.y < after.y:
				# TODO: body alternation
				part.set_part(Part.BODY_1)
			elif loc.x < after.x:
				part.set_part(Part.CORNER, false)
			elif loc.x > after.x:
				part.set_part(Part.CORNER, true)
		elif before.y > loc.y:
			part.set_direction("down")
			if loc.y > after.y:
				# TODO: body alternation
				part.set_part(Part.BODY_1)
			elif loc.x < after.x:
				part.set_part(Part.CORNER, true)
			elif loc.x > after.x:
				part.set_part(Part.CORNER, false)

	var tailpart = parts[-1]
	var tail = gridlocs[-1]
	tailpart.move_to(tail)
	tailpart.set_part(Part.TAIL)
	var before = gridlocs[-2]
	if before.x < tail.x:
		tailpart.set_direction("left")
	elif before.x > tail.x:
		tailpart.set_direction("right")
	elif before.y < tail.y:
		tailpart.set_direction("up")
	else:
		tailpart.set_direction("down")

func set_power_level(level: SnakePart.PowerLevel):
	for part in parts:
		part.set_power_level(level)


# Modulates the color a bit and
func hurt():
	for part in parts:
		part.modulate_hurt()
		
	await get_tree().create_timer(hurt_time).timeout
	
	for part in parts:
		part.modulate_reset()

func die() -> void:
	parts[0].show_dead()

func detect_self_collision() -> bool:
	var locs = {}
	for loc in gridlocs:
		locs[loc] = null
	return locs.size() < gridlocs.size()

func init(startloc: Vector2i, direction: String, length: int = 6) -> void:
	start_at(startloc, direction)
	for i in length - 1:
		add_part()

func detect_shape(debug: bool = false) -> bool:
	var segments = [["s", 1]];
	for i in range(1, parts.size()):
		match parts[i].turn():
			Turn.None:
				if segments[-1][0] == "s":
					segments[-1][1] = segments[-1][1] + 1
				else:
					segments.append(["s", 1])
			Turn.Right:
				segments.append(["r", 1])
			Turn.Left:
				segments.append(["l", 1])

	var detected_shape
	if segments_match(segments, SQUARE, debug):
		detected_shape = Shape.Square
	elif segments_match(segments, CLOUD, debug):
		detected_shape = Shape.Cloud
	elif segments_match(segments, WAVE, debug):
		detected_shape = Shape.Wave
	else:
		detected_shape = Shape.None

	if detected_shape != active_shape:
		active_shape = detected_shape
		print("active_shape: %s" % Shape.keys()[active_shape])
		return true
	return false

var SQUARE = reverse_and_mirror([
	[["s", 1], ["r", 1], ["s", 1], ["r", 1], ["s", 1], ["r", 1], ["s", 2]],
	[["s", 1], ["r", 1], ["s", 2], ["r", 1], ["s", 2], ["r", 1], ["s", 3]],
	[["s", 2], ["r", 1], ["s", 2], ["r", 1], ["s", 2], ["r", 1], ["s", 2]],
	[["s", 2], ["r", 1], ["s", 3], ["r", 1], ["s", 3], ["r", 1], ["s", 4]],
	[["s", 3], ["r", 1], ["s", 3], ["r", 1], ["s", 3], ["r", 1], ["s", 3]],
	[["s", 1], ["r", 1], ["s", 3], ["r", 1], ["s", 3], ["r", 1], ["s", 3], ["r", 1], ["s", 1]],
])

var CLOUD = reverse_and_mirror([
	[["r", 1], ["l", 1], ["r", 1], ["s", 1], ["r", 1], ["l", 1], ["r", 1], ["l", 1], ["r", 1], ["r", 1], ["s", 5]],
])

var WAVE = reverse_and_mirror([
	[["s", 1], ["l", 1], ["s", 1], ["r", 1], ["s", 1], ["r", 1], ["s", 3], ["l", 1], ["s", 1], ["l", 1], ["s", 1], ["r", 1]],
])

func segments_match(segments: Array, patterns: Array, debug: bool) -> bool:
	var min_segment_count = patterns[0].size()
	if segments.size() < min_segment_count:
		return false

	if debug: print("segments=%s" % [segments])

	if debug: print("Trying to match any of %s patterns" % patterns.size())
	var matched = false
	for p in patterns.size():
		var pattern = patterns[p]
		if debug: print("  pattern %s: %s" % [p, pattern])
		if pattern.size() > segments.size():
			if debug: print("    oh wait, too small")
			continue
		for offset in (segments.size() - pattern.size()) + 1:
			if debug: print("    offset %s" % offset)
			var pattern_matched = true
			for i in pattern.size():
				var seg = segments[offset + i]
				var pat = pattern[i]
				if (i == 0 or i == (pattern.size() - 1)) and seg[0] == "s" and pat[0] == "s":
					# Straight at the beginning or end of a pattern only fails against shorter segments
					if seg[1] < pat[1]:
						if debug: print("      fail at %s: segment=%s too short (pattern=%s)" % [i, seg, pat])
						pattern_matched = false
						break
				elif seg != pat:
					if debug: print("      fail at %s: segment=%s != pattern=%s" % [i, seg, pat])
					pattern_matched = false
					break
			if pattern_matched:
				matched = true
				break
		if matched:
			break
	return matched

static func reverse_and_mirror(patterns: Array) -> Array:
	var out = []
	for pattern in patterns:
		var mirrored = pattern.duplicate(true)
		for item in mirrored:
			if item[0] == "l":
				item[0] = "r"
			elif item[0] == "r":
				item[0] = "l"

		var reversed = pattern.duplicate()
		reversed.reverse()
		var mirrored_reversed = mirrored.duplicate()
		mirrored_reversed.reverse()

		out.append(pattern)
		out.append(mirrored)
		out.append(reversed)
		out.append(mirrored_reversed)
	return out
