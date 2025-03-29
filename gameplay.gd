class_name Gameplay extends CanvasLayer

@onready var input_name: LineEdit = %InputName
@onready var label_name: Label = %LabelName
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var box_container: HBoxContainer = $UI/Gameplay/UI/Bottom/BoxContainer

enum SCORES {
	WO,
	FC,
	DR,
	MA
}

var isGameStarted: bool = false
var boxes: Array[Box] = []

func _ready() -> void:
	input_name.text = ""
	input_name.grab_focus()
	
	for child in box_container.get_children():
		if child is Box:
			boxes.append(child)
	
func start(is_restart: bool = true):
	""" Rules:
	- Find all matched color numbers and fill it in each folder
		
	- 5 Folders x 4 Attributes: 
		WO = Green
		FC = Yellow
		DR = White
		MA = Blue
	"""
	if is_restart:
		for box: Box in boxes:
			box.reset()
	
	isGameStarted = true
	
func _on_input_name_text_submitted(new_text: String) -> void:
	if isGameStarted: return
	
	if len(new_text) < 3:
		print("New too short")
		return
		
	label_name.text = new_text
	start()
