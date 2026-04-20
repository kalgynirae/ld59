extends Node2D

@export var powered: bool = false
@export var towered: bool = false

func _ready() -> void:
	if powered:
		power_on()
	if towered:
		$Sprite.region_rect.position.y = 16

func power_on():
	powered = true
	$Sprite.region_rect.position.x = 16
	$Particles.emitting = true
