extends CanvasLayer

@onready var input_name: LineEdit = %InputName
@onready var label_name: Label = %LabelName
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var isGameStarted: bool = false

func _ready() -> void:
	input_name.text = ""
	input_name.grab_focus()
	
	
func start():
	""" Rules:
	- Find all matched color numbers and fill it in each folder
		
	- 5 Folders x 4 Attributes: 
		WO = Green
		FC = Yellow
		DR = White
		MA = Blue
	"""
	isGameStarted = true


func _on_input_name_text_submitted(new_text: String) -> void:
	if isGameStarted: return
	
	if len(new_text) < 3:
		print("New too short")
		return
		
	label_name.text = new_text
	start()
