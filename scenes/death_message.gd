extends Panel
class_name DeathPanel

enum DeathType {
	EAT_SELF,
	FENCE,
	ROCK,
	CACTUS
}

func message_for(death_type: DeathType) -> String:
	match death_type:
		_:
			match randi_range(0, 1):
				0:
					return "Snake has perished"
				1:
					return "Snake has left this mortal coil"
				_:
					return "Snake has fallen out of world"

func display_death_message(death_type: DeathType) -> void:
	visible = true
	$Label.text = message_for(death_type)

func hide_message() -> void:
	visible = false

func _ready() -> void:
	visible = false
