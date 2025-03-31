class_name Number extends Node2D

@onready var label_id: Label = $Node2D/LabelId
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var container: Node2D = $Node2D

const SELECT_TRANSITION_DURATION = .4
const FOCUS_SCALE := 1.5
const FOCUS_DURATION := 0.3
const FLY_DURATION := 2.0

var score_type: Gameplay.SCORES 
var tween: Tween
var number: int = -1:
	get:
		return number
	set(value):
		if label_id: 
			label_id.text = str(value)
			
		number = value

var focus_tween: Tween
var is_active: bool = false
var grid_x: int = -1
var grid_y: int = -1
var is_used: bool = false

func _ready() -> void:
	pass
	#await get_tree().process_frame
	#animation_player.play(&"show")
	#fly_to_target(Vector2.ZERO)
	
func fade_in() -> void:
	animation_player.speed_scale = 1.0
	animation_player.play(&"RESET")
	await get_tree().create_timer(randf_range(1.0, 5.0)).timeout # Random delay before showing
	animation_player.play(&"show")
	await get_tree().create_timer(2.0).timeout
	animation_player.speed_scale = randf_range(0.1, 1.0)
	animation_player.play(&"move0")
	#print("fade_in()", grid_x, " ", grid_y)
	
func toggle_select() -> bool:
	if tween and tween.is_running():
		tween.kill()
		
	if is_used: return false
		
	tween = create_tween()
	tween.set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label_id, "position", Vector2(-25, -25), SELECT_TRANSITION_DURATION)
	is_active = !is_active
	
	if is_active:
		animation_player.pause()
		tween.tween_property(label_id, "scale", Vector2(1.5, 1.5), SELECT_TRANSITION_DURATION)
		tween.tween_property(self, "modulate", Gameplay.SCORE_TO_COLOR[score_type], SELECT_TRANSITION_DURATION)
	else:
		tween.tween_property(self, "modulate", Color.WHITE, SELECT_TRANSITION_DURATION)
		tween.tween_property(label_id, "scale", Vector2(1.0, 1.0), SELECT_TRANSITION_DURATION)
		tween.tween_callback(animation_player.stop)
		tween.tween_callback(animation_player.play.bind(&"move0"))

	#print("toggle_select(", is_active, ")")
	return is_active
	
func toggle_focus(is_active: bool = true) -> void:
	if focus_tween and focus_tween.is_running():
		focus_tween.kill()
		
	if self.is_active: return
		
	focus_tween = create_tween()
	focus_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	if is_active:
		focus_tween.tween_property(container, "scale", Vector2.ONE * FOCUS_SCALE, FOCUS_DURATION)
	else:
		focus_tween.tween_property(container, "scale", Vector2.ONE, FOCUS_DURATION)
		

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			if visible and animation_player:
				label_id.scale = Vector2.ONE
				label_id.modulate.a = 1.0
				animation_player.play(&"move0")

func fly_to_target(box: Box) -> void:
	# Mark as used so it won't be selectable again
	is_used = true
	var viewport = get_viewport()
	var camera_2d = viewport.get_camera_2d()
	
	# Visual clone for the animation
	var clone: Control = label_id.duplicate()
	clone.scale = scale * container.scale * label_id.scale * camera_2d.zoom
	clone.modulate = modulate
	# clone.global_position = box.get_viewport().get_canvas_transform().affine_inverse() * label_id.get_viewport().get_canvas_transform() * label_id.global_position
	# container.add_child(clone)

	# TODO THIS CONVERSION FROM SUB-VIEWPORT TO UI CANVAS LAYER IS WRONG!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	var label_canvas_pos = label_id.get_global_transform_with_canvas().origin
	var box_container_transform = box.control.get_global_transform_with_canvas()
	var clone_pos_in_box = box_container_transform.affine_inverse() * label_canvas_pos
	clone.position = clone_pos_in_box + Vector2(0, 250.0)
	box.control.add_child(clone)
	
	# var world_pos = label_id.global_position
	# var screen_pos = camera_2d.get_viewport_transform() * world_pos
	# var local_pos = box.fly_score_container.get_global_transform().affine_inverse() * screen_pos
	# # Set the clone's position
	# clone.position = local_pos + Vector2(0, 250.0)
	
	# Hide the original number
	# visible = false

	# Create animation tween
	var tween = create_tween()
	tween.set_parallel().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.2) # Temporary solution because the clone position is wrong T_T
	tween.tween_property(clone, "global_position", box.control.global_position, FLY_DURATION)
	tween.tween_property(clone, "modulate", Color.TRANSPARENT, FLY_DURATION)
	# tween.parallel().tween_interval(FLY_DURATION * 0.8)
	# tween.parallel().tween_property(clone, "modulate", Color.TRANSPARENT, 0.2)
	
	# Clean up after animation
	tween.chain().tween_callback(func():
		clone.queue_free()
	)

func reset_state() -> void:
	# Reset all animation and visual states
	if tween and tween.is_running():
		tween.kill()
	
	if focus_tween and focus_tween.is_running():
		focus_tween.kill()
		
	visible = true
	modulate = Color.WHITE
	is_used = false
	is_active = false
	animation_player.stop()
