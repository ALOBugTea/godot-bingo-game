extends Button


const sound_on_picture = preload("res://sound_on.png")
const sound_off_picture = preload("res://sound_off.png")

@onready var texture_button: TextureRect = $TextureButton

func _on_button_down() -> void:
	owner.is_sound = !owner.is_sound
	if owner.is_sound:
		texture_button.texture = sound_on_picture
	else:
		texture_button.texture = sound_off_picture
