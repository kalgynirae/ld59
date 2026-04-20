extends Node2D

func _ready() -> void:
	$Sprite.visible = true

func eat():
	$Sprite.visible = false

func save_state():
	return $Sprite.visible
	
func restore_state(state):
	$Sprite.visible = state

func uneaten() -> bool:
	return $Sprite.visible
