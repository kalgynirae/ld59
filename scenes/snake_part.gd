extends Node2D
class_name SnakePart

enum Part {
	HEAD,
	BODY_1,
	BODY_2,
	TAIL,
	CORNER
}

enum PowerLevel {
	NORMAL,
	SLIGHTLY_CHARGED,
	CHARGED,
	VERY_CHARGED,
	SUPERCHARGED
}

var current_part: Part = Part.HEAD
var power_level: PowerLevel = PowerLevel.NORMAL
var direction: String = "up"

# Helper method to separate out the logic that chooses what sprite to show
func set_current_sprite(part: Part, level: PowerLevel):
	$Sprite.region_rect = Rect2(level * 16, part * 16, 16, 16)

func set_power_level(level: PowerLevel):
	set_current_sprite(current_part, level)

# Resets the color shift on the sprite part
func modulate_reset():
	$Sprite.modulate = Color(1, 1, 1)

# Modulates the color shift on the snake to mimic a "hurt" color
func modulate_hurt():
	$Sprite.modulate = Color(1, 0, 0)

func set_part(part: Part, flip: bool = false) -> void:
	set_current_sprite(part, power_level)
	if part == Part.CORNER or current_part == Part.CORNER:
		# Fix rotation
		set_direction(direction, part == Part.CORNER, flip)
	current_part = part

func set_direction(dir: String, corner: bool = false, flip: bool = false) -> void:
	direction = dir
	$Sprite.flip_h = flip
	if corner:
		match dir:
			"left":
				$Sprite.rotation_degrees = 90
			"right":
				$Sprite.rotation_degrees = -90
			"up":
				$Sprite.rotation_degrees = 180
			"down":
				$Sprite.rotation_degrees = 0
	else:
		match dir:
			"left":
				$Sprite.rotation_degrees = -90
			"right":
				$Sprite.rotation_degrees = 90
			"up":
				$Sprite.rotation_degrees = 0
			"down":
				$Sprite.rotation_degrees = 180

func move_to(loc: Vector2i) -> void:
	position = loc * 16

func show_dead() -> void:
	$Dead.visible = true

func hide_dead() -> void:
	$Dead.visible = false

enum Turn {
	None,
	Right,
	Left,
}

func turn() -> Turn:
	if current_part == Part.CORNER:
		if $Sprite.flip_h:
			return Turn.Right
		else:
			return Turn.Left
	return Turn.None
