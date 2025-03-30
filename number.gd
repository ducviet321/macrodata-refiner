class_name Number extends Node2D

@onready var label_id: Label = $Node2D/LabelId
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var container: Node2D = $Node2D

const SELECT_TRANSITION_DURATION = .4
const FOCUS_SCALE := 1.5
const FOCUS_DURATION := 0.3

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

func _ready() -> void:
	# fade_in() # TODO Remove
	pass
	
func fade_in() -> void:
	animation_player.play(&"RESET")
	await get_tree().create_timer(randf_range(1.0, 5.0)).timeout # Random delay before showing
	animation_player.play(&"show")
	await get_tree().create_timer(2.0).timeout
	animation_player.speed_scale = randf_range(0.1, 1.0)
	animation_player.play(&"move0")
	
func toggle_select() -> bool:
	if tween and tween.is_running():
		tween.kill()
		
	tween = create_tween()
	tween.set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label_id, "position", Vector2(-25, -25), SELECT_TRANSITION_DURATION)
	is_active = !is_active
	
	if is_active:
		animation_player.pause()
		tween.tween_property(label_id, "scale", Vector2(1.5, 1.5), SELECT_TRANSITION_DURATION)
		tween.tween_property(self, "modulate", Gameplay.SCORE_TO_COLOR[score_type], SELECT_TRANSITION_DURATION)
	else:
		tween.tween_property(label_id, "modulate", Color.WHITE, SELECT_TRANSITION_DURATION)
		tween.tween_property(label_id, "scale", Vector2(1.0, 1.0), SELECT_TRANSITION_DURATION)
		tween.tween_callback(animation_player.stop)
		tween.tween_callback(animation_player.play.bind(&"move0"))

	print("toggle_select(", is_active, ")")
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

func fly_to_target(target_position: Vector2) -> void:
	# Create a visual clone for the animation
	var clone = Node2D.new()
	var label_clone = Label.new()
	
	# Setup clone appearance
	label_clone.text = str(number)
	label_clone.add_theme_font_size_override("font_size", 32)
	label_clone.modulate = modulate
	clone.global_position = global_position
	clone.add_child(label_clone)
	
	# Add clone to scene
	get_tree().root.add_child(clone)
	
	# Hide the original number
	visible = false
	
	# Create animation tween
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(clone, "global_position", target_position, 0.5)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(clone, "scale", Vector2.ZERO, 0.5)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	
	# Clean up after animation
	tween.chain().tween_callback(func():
		clone.queue_free()
	)
