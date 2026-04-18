extends Node2D

enum PartShown {
	HEAD,
	BODY_1,
	BODY_2,
	TAIL
}

enum PowerLevel {
	NORMAL,
	SLIGHTLY_CHARGED,
	CHARGED,
	VERY_CHARGED,
	SUPERCHARGED
}

@export var current_part: PartShown = PartShown.HEAD
@export var power_level: PowerLevel = PowerLevel.NORMAL

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Snakeparts.region_enabled = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var part_offset = 0;
		
	match current_part:
		PartShown.HEAD:
			part_offset = 0
		PartShown.BODY_1:
			part_offset = 16
		PartShown.BODY_2:
			part_offset = 32
		PartShown.TAIL:
			part_offset = 48

	$Snakeparts.region_rect = Rect2(power_level * 16, part_offset, 16, 16)
