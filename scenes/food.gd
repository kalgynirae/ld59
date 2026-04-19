extends Node2D

func _ready() -> void:
	$Sprite.visible = true

func eat():
	$Sprite.visible = false
