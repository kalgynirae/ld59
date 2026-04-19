extends Node2D

@export var color2: bool = false

func _ready() -> void:
	if color2:
		$Sprite.region_rect.position.y = 16
		lower()

func is_raised() -> bool:
	return $Sprite.region_rect.position.x == 0

func lower() -> void:
	$Sprite.region_rect.position.x = 16

func raise() -> void:
	$Sprite.region_rect.position.x = 0

func toggle() -> void:
	if is_raised():
		lower()
	else:
		raise()
