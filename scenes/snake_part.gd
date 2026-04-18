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

func set_part(part: Part) -> void:
	$Sprite.region_rect = Rect2(power_level * 16, part * 16, 16, 16)

func set_direction(dir: String) -> void:
	direction = dir
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
