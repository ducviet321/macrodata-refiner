"""
https://github.com/godotengine/godot-proposals/discussions/11471#discussioncomment-11762037
"""

@tool
extends Container

@export var content_scale := 1.0:
	set(v):
		content_scale = v
		queue_sort()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			for child:Control in get_children():
				child.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT,Control.PRESET_MODE_MINSIZE)
				child.size /= content_scale 
				child.scale = Vector2(content_scale,content_scale)
