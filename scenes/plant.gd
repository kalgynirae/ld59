extends Node2D
class_name Plant

enum GrowthStage {
	HEALTHY,
	WILTED,
	DEAD,
}

@export var growth_stage: GrowthStage = GrowthStage.DEAD

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sprite.region_enabled = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Sprite.region_rect = Rect2(16 * growth_stage, 0, 16, 16)
