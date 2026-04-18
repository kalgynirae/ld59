extends Node2D

@export var powered: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if self.powered:
		self.power_on()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func power_on():
	$off.visible = false
	$on.visible = true
