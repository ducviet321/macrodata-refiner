class_name BoxScore extends HBoxContainer

@onready var progress_bar: ProgressBar = $Control/ProgressBar
@export var score_type: Gameplay.SCORES
@onready var label: Label = $"MarginContainer/Label 85f0ff2"

var tween_progress: Tween
var current_score: float = 0.0
		
func _ready() -> void:
	label.text = Gameplay.SCORES.keys()[score_type]
	modulate = Gameplay.SCORE_TO_COLOR[score_type]
	
func reset(should_animate: bool = true):
	if should_animate:
		add_score(-current_score)
	else:
		current_score = 0.0
		progress_bar.value = 0.0
	
func add_score(value: float) -> float:
	var addable_score: float = value
	
	if progress_bar.value + addable_score > progress_bar.max_value:
		addable_score = progress_bar.max_value - current_score
		
	current_score  = max(current_score + addable_score, 0.0)
	
	if tween_progress and tween_progress.is_running():
		tween_progress.stop()
		
	tween_progress = create_tween()
	tween_progress.tween_property(progress_bar, "value", current_score, 1.0)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		
	return addable_score
