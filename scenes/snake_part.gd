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

func set_part(part: Part, flip: bool = false) -> void:
	$Sprite.region_rect = Rect2(power_level * 16, part * 16, 16, 16)
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
