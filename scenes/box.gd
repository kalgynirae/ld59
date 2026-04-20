extends Node2D

@export var desert: bool = false
var broken: bool = false

func _ready() -> void:
	if desert:
		$Regular.visible = false
		$Desert.visible = true
		$Explosion.region_rect.position.y = 48

func explode() -> void:
	broken = true
	if desert:
		$Desert.visible = false
	else:
		$Regular.visible = false
	$Explosion.visible = true
	for i in 4:
		await get_tree().create_timer(0.1).timeout
		$Explosion.region_rect.position.x = min(192, $Explosion.region_rect.position.x + 48)

func unbroken() -> bool:
	return not broken
