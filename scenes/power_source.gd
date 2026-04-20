extends Node2D

@export var powered: bool = false

func _ready() -> void:
	if self.powered:
		self.power_on()

func power_on():
	$off.visible = false
	$on.visible = true
