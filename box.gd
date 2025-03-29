extends VBoxContainer

@onready var label_percentage: Label = $Control/LabelPercentage
@onready var label_id: Label = $Container/MarginContainer/LabelId

@export var box_index: int = 0

func _ready() -> void:
	label_id.text = "%02d" % (box_index + 1)
	


func _on_mouse_entered() -> void:
	print("_on_mouse_entered()")


func _on_mouse_exited() -> void:
	print("_on_mouse_exited()")
