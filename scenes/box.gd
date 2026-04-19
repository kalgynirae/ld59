extends Node2D

@export var desert: bool = false

func _ready() -> void:
	if desert:
		$Regular.visible = false
		$Desert.visible = true
