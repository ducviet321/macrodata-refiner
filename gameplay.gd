extends CanvasLayer

@onready var input_name: LineEdit = %InputName
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	input_name.text = ""
	input_name.grab_focus()


func _on_input_name_text_submitted(new_text: String) -> void:
	if len(new_text) < 3:
		print("New too short")
		return
