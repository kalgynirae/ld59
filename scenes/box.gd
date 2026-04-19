extends Node2D

@export var active: bool = true

func breaks():
	active = false
	$Sprite.visible = false
