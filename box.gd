class_name Box extends VBoxContainer

@onready var label_percentage: Label = $Control/LabelPercentage
@onready var label_id: Label = $Container/MarginContainer/LabelId
@onready var box_score_container: VBoxContainer = $"Container/Opening/Score Container/Tempers/BoxScoreContainer"
@onready var box_progress: ProgressBar = $Control/BoxProgress

var box_scores: Dictionary[Gameplay.SCORES, BoxScore] = {}
var tween_progress: Tween

var total_percentage: float:
	get: 
		if not box_scores: return 0.0
		
		# Total result from all box scores
		var result = 0.0
		for box_score: BoxScore in box_scores.values():
			result += box_score.current_score
			
		result /= box_scores.size()
		return result
	

func _ready() -> void:
	label_id.text = "%02d" % (get_index() + 1)
	
	for child in box_score_container.get_children():
		if child is BoxScore:
			box_scores[child.score_type] = child
			
func reset(should_animate: bool = true):
	if should_animate:
		if tween_progress and tween_progress.is_running():
			tween_progress.stop()
			
		tween_progress = create_tween()
		tween_progress.tween_property(box_progress, "value", 0.0, 1.0)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	else:
		box_progress.value = 0.0
	
	for box_score: BoxScore in box_scores.values():
		box_score.reset(false)

			
func add_score(score_type: Gameplay.SCORES, value: float) -> float:
	if not box_scores.has(score_type):
		printerr("Box.add_score() Box", get_index(), "doesn't have score type:", score_type)
		return 0.0
		
	print("Box.add_score(", Gameplay.SCORES.keys()[score_type], ", ", value, ")")
		
	var addable_score: float = box_scores[score_type].add_score(value)
	
	if is_zero_approx(addable_score): return addable_score
		
	if tween_progress and tween_progress.is_running():
		tween_progress.stop()
		
	tween_progress = create_tween()
	tween_progress.tween_property(box_progress, "value", total_percentage, 1.0)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		
	return addable_score

func _on_mouse_entered() -> void:
	print("_on_mouse_entered()")

func _on_mouse_exited() -> void:
	print("_on_mouse_exited()")

func _on_box_progress_value_changed(value: float) -> void:
	label_percentage.text = "%d%%" % (box_progress.value / box_progress.max_value * 100.0)

func _on_button_pressed() -> void:
	add_score(randi() % 4, randf() * 100)
