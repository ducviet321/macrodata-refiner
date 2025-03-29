extends Control

@onready var color_rect: ColorRect = $ColorRect


func _on_mouse_entered() -> void:
	print("_on_mouse_entered()")


func _on_mouse_exited() -> void:
	print("_on_mouse_exited()")
