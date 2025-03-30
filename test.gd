extends Control

@onready var color_rect: ColorRect = $ColorRect


func _on_mouse_entered() -> void:
	print("_on_mouse_entered()")


func _on_mouse_exited() -> void:
	print("_on_mouse_exited()")


func _on_area_2d_area_entered(area: Area2D) -> void:
	print("_on_area_2d_area_entered()")
	pass # Replace with function body.


func _on_area_2d_area_exited(area: Area2D) -> void:
	print("_on_area_2d_area_exited()")
	pass # Replace with function body.
