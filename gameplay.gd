class_name Gameplay extends CanvasLayer

@onready var input_name: LineEdit = %InputName
@onready var label_name: Label = %LabelName
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var box_container: HBoxContainer = $UI/Gameplay/UI/Bottom/BoxContainer
@onready var number_container: Node2D = %NumberContainer
@onready var camera_2d: Camera2D = %Camera2D
@onready var sub_viewport: SubViewport = $UI/Gameplay/Control/SubViewportContainer/SubViewport
@onready var mouse_container: Node2D = $UI/Gameplay/Control/SubViewportContainer/SubViewport/MouseContainer
@onready var label_left: Label = $UI/Gameplay/UI/Bottom/LabelLeft
@onready var label_middle: Label = $UI/Gameplay/UI/Bottom/LabelMiddle
@onready var label_complete_percentage: Label = %LabelCompletePercentage
@onready var label_end_score: Label = $"UI/100/100 Container/LabelEndScore"
@onready var label_85f_0_ff: Label = $"UI/Root/Label 85f0ff"


"""​The Four Tempers introduced by Lumon Industries' founder, Kier Eagan:

WO (Woe) – Represents sadness, despair, grief, or sorrow. Numbers in this category may evoke a sense of loss or suffering.
FC (Frolic) – Associated with joy, excitement, and playfulness. Numbers categorized here feel lighthearted and euphoric.
DR (Dread) – Symbolizes fear, anxiety, and an impending sense of doom. These numbers may provoke unease or paranoia.
MA (Malice) – Stands for anger, hostility, and aggression. Numbers in this category feel menacing or violent.
"""

const NUMBER = preload("res://number.tscn")
#const NUMBER_ROW_COUNT: int = 5
#const NUMBER_COLLUMN_COUNT: int = 5
const NUMBER_ROW_COUNT: int = 30
const NUMBER_COLLUMN_COUNT: int = 52
const NUMBER_SPACING := 120.0
const MIN_ZOOM: float = 0.4
const MAX_ZOOM: float = 1.0

const CAMERA_MOVE_SPEED: float = 500.0
const ZOOM_DURATION: float = 0.2
const ZOOM_SPEED: float = 5.0
const GRID_SPACING := 120.0
const VISIBILITY_MARGIN_H := 100.0    # Horizontal margin
const VISIBILITY_MARGIN_TOP := 100.0  # Top margin (larger for UI elements)
const VISIBILITY_MARGIN_BOTTOM := 400.0  # Bottom margin
const SCORE_TO_COLOR: Dictionary[SCORES, Color] = {
	SCORES.WO: "#ccffde",
	SCORES.FC: "#eaefa2",
	SCORES.DR: "#f0f8ff",
	SCORES.MA: "#8accff",
}

const ending_quotes = [
	"%s, efficiency acknowledged\nQuota fulfilled in %02d:%02d\nPeak refinement: %d",
	"%s, your efforts have been recorded\nQuota achieved in %02d:%02d\nHighest refinement: %d",
	"%s, a suitable performance\nQuota met within %02d:%02d\nHighest refinement: %d",
	"%s, refinement success\nTime spent: %02d:%02d\nHighest refinement: %d",
	"%s, an acceptable outcome\nQuota reached in %02d:%02d\nHighest refinement: %d",
	"%s, the numbers align\nQuota achieved within %02d:%02d\nHighest refinement: %d",
	"%s, productivity noted\nQuota reached in %02d:%02d\nHighest refinement: %d",
	"%s, your work is appreciated\nQuota secured in %02d:%02d\nHighest refinement: %d",
	"%s, order maintained\nQuota reached in %02d:%02d\nHighest refinement: %d",
	"%s, precision observed\nQuota secured within %02d:%02d\nHighest refinement: %d"
]

enum SCORES {
	WO,
	FC,
	DR,
	MA
}

static var instance: Gameplay
static var player_name: String = "vit"

var is_game_started: bool = false
var boxes: Array[Box] = []
var number_grid: Array[Array] = []
var is_dragging: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO
var current_zoom_tween: Tween
var target_zoom: Vector2 = Vector2.ONE
var selected_number: Number = null
var is_mouse_pressed: bool = false
var selected_numbers: Array[Number] = []
var current_score: int = 0
var is_selecting: bool = false
var is_unselecting_mode: bool = false
var score_tween: Tween
var total_completion: float = 0.0

# Add these variables to store calculation results
var current_dominant_type: SCORES
var current_dominant_sum: int
var current_other_sum: int
var current_dominant_count: int

var start_time: int = 0
var highest_hit_score: float = 0.0

func _ready() -> void:
	instance = self
	input_name.text = ""
	input_name.grab_focus()
	
	for child in box_container.get_children():
		if child is Box:
			boxes.append(child)
			child.on_box_progress_changed.connect(_on_box_progress_changed)
			
	#start() # TODO REMOVE ME
	#game_over()
	
func _process(delta: float) -> void:
	if is_game_started:
		if is_dragging:
			handle_drag()
			
		if not (is_equal_approx(camera_2d.zoom.x, target_zoom.x) and is_equal_approx(camera_2d.zoom.y, target_zoom.y)):
			camera_2d.zoom = camera_2d.zoom.lerp(target_zoom, ZOOM_SPEED * delta)
			
		hide_outside_numbers()
		
		# Update mouse_area_2d position with direct world position calculation
		var viewport_mouse = sub_viewport.get_mouse_position()
		var world_position = camera_2d.get_screen_center_position() + (viewport_mouse - sub_viewport.get_visible_rect().size/2) / camera_2d.zoom
		mouse_container.global_position = world_position
		
func submit_score(box: Box):
	if selected_numbers.is_empty():
		return
		
	var final_score:float = (current_dominant_sum - current_other_sum) * current_dominant_count / 10.0
	
	# Track highest score
	highest_hit_score = max(highest_hit_score, final_score)
	
	# Add score to box
	box.add_score(current_dominant_type, final_score)
	
	# Animate numbers flying to the box
	for number in selected_numbers:
		number.fly_to_target(box.global_position)
	
	selected_numbers.clear()

	# Animate label increase score
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_method(func(value: float):
		label_middle.text = ("+" if value >= 0 else "") +  "%d" % value
	, 0, final_score, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)

func handle_drag():
	var current_mouse_pos = get_viewport().get_mouse_position()
	var mouse_delta = (last_mouse_position - current_mouse_pos) 
	
	if is_zero_approx(mouse_delta.x) and is_zero_approx(mouse_delta.y): return
	
	camera_2d.position += mouse_delta / camera_2d.zoom
	
	# Account for viewport size and zoom when clamping
	var half_viewport = get_viewport().get_visible_rect().size / (2 * camera_2d.zoom)
	camera_2d.position.x = clamp(
		camera_2d.position.x, 
		camera_2d.limit_left + half_viewport.x,
		camera_2d.limit_right - half_viewport.x
	)
	camera_2d.position.y = clamp(
		camera_2d.position.y,
		camera_2d.limit_top + half_viewport.y,
		camera_2d.limit_bottom - half_viewport.y
	)
	last_mouse_position = current_mouse_pos
	
	
func hide_outside_numbers():
	# Update number visibility with separate margins
	var viewport_rect = sub_viewport.get_visible_rect()
	var margin_h = VISIBILITY_MARGIN_H / camera_2d.zoom.x
	var margin_top = VISIBILITY_MARGIN_TOP / camera_2d.zoom.y
	var margin_bottom = VISIBILITY_MARGIN_BOTTOM / camera_2d.zoom.y
	
	var camera_rect = Rect2(
		camera_2d.position - Vector2(
			viewport_rect.size.x / (2 * camera_2d.zoom.x) + margin_h,
			viewport_rect.size.y / (2 * camera_2d.zoom.y) + margin_top
		),
		viewport_rect.size / camera_2d.zoom + Vector2(
			margin_h * 2, 
			margin_top + margin_bottom
		)
	)
	
	for row in number_grid:
		for number: Number in row:
			if number.is_used: 
				continue
			elif camera_rect.has_point(number.position):
				number.process_mode = Node.PROCESS_MODE_INHERIT
				number.visible = true
			else:
				number.process_mode = Node.PROCESS_MODE_DISABLED
				number.visible = false
	
func start(is_restart: bool = true):
	""" Rules:
	- Find all matched color numbers and fill it in each folder
		
	- 5 Folders x 4 Attributes: 
		WO = Green
		FC = Yellow
		DR = White
		MA = Blue
	"""
	spawn_numbers()

	if is_restart:
		for box: Box in boxes:
			box.reset()

	selected_numbers = []
	highest_hit_score = 0.0
	start_time = Time.get_ticks_msec()
	update_score_label()
	is_game_started = true

func spawn_numbers():
	if number_grid: # Restart Game, new set of numbers
		for row_idx in range(number_grid.size()):
			for col_idx in range(number_grid[row_idx].size()):
				var number: Number = number_grid[row_idx][col_idx]
				number.score_type = randi_range(0, SCORES.size() - 1)
				if player_name == "vit": # Cheat mode, show colors
					number.modulate = SCORE_TO_COLOR[number.score_type]
				number.reset_state() # Reset the number's state
	else: # Spawn new nodes
		for row in range(NUMBER_COLLUMN_COUNT):
			var number_row: Array = []
			for column in range(NUMBER_ROW_COUNT):
				var number: Number = NUMBER.instantiate()
				number.score_type = randi_range(0, SCORES.size() - 1)
				number.grid_x = row
				number.grid_y = column
		
				if player_name == "vit": # Cheat mode, show colors
					number.modulate = SCORE_TO_COLOR[number.score_type]
					
				number.global_position = Vector2(
					row * NUMBER_SPACING, 
					column * NUMBER_SPACING
					)
				number_container.add_child(number)
				number_row.append(number)
			
			number_grid.append(number_row)


	# Count same score type numbers in 8 directions around each number
	for row_idx in range(number_grid.size()):
		for col_idx in range(number_grid[row_idx].size()):
			var current_number: Number = number_grid[row_idx][col_idx]
			var count = 0
			
			# Check all 8 directions around the current number
			for dr in [-1, 0, 1]:
				for dc in [-1, 0, 1]:
					if dr == 0 and dc == 0:
						continue  # Skip the current number itself
					
					var r = row_idx + dr
					var c = col_idx + dc
					
					# Check if the neighbor is within bounds
					if r >= 0 and r < number_grid.size() and c >= 0 and c < number_grid[row_idx].size():
						var neighbor = number_grid[r][c]
						if neighbor.score_type == current_number.score_type:
							count += 1
			
			current_number.number = count
			current_number.fade_in()
	
	var viewport_size = get_viewport().get_visible_rect().size
	camera_2d.offset = viewport_size / 2
	camera_2d.limit_left = number_grid[0][0].position.x
	camera_2d.limit_right = number_grid[-1][-1].position.x
	camera_2d.limit_top = number_grid[0][0].position.y - 300.0
	camera_2d.limit_bottom = number_grid[-1][-1].position.y - 300.0
			
func _on_input_name_text_submitted(new_text: String) -> void:
	if len(new_text) < 3:
		print("New too short")
		return
		
	label_name.text = new_text
	player_name = new_text
	label_85f_0_ff.visible = false
	animation_player.seek(12.0) # End intro
	animation_player.play(&"show_game")
	start()
	
func toggle_number_selection(number: Number) -> void:
	var is_selected = number.toggle_select()
	if is_selected:
		selected_numbers.append(number)
	else:
		selected_numbers.erase(number)
	
	update_score_label()

func update_score_label():
	if selected_numbers.is_empty():
		label_middle.text = "0x0"
		current_dominant_type = SCORES.WO
		current_dominant_sum = 0
		current_other_sum = 0
		current_dominant_count = 0
		return
		
	# Count numbers by score type
	var counts = {
		SCORES.WO: 0,
		SCORES.FC: 0,
		SCORES.DR: 0,
		SCORES.MA: 0
	}
	
	var sum_by_type = {
		SCORES.WO: 0,
		SCORES.FC: 0,
		SCORES.DR: 0,
		SCORES.MA: 0
	}
	
	# Calculate counts and sums for each type
	for number in selected_numbers:
		counts[number.score_type] += 1
		sum_by_type[number.score_type] += number.number
	
	# Find dominant type (highest count)
	current_dominant_type = SCORES.WO
	var max_count = 0
	
	for type in counts.keys():
		if counts[type] > max_count:
			max_count = counts[type]
			current_dominant_type = type
	
	current_dominant_sum = sum_by_type[current_dominant_type]
	current_other_sum = 0
	
	for type in sum_by_type.keys():
		if type != current_dominant_type:
			current_other_sum += sum_by_type[type]
			
	current_dominant_count = counts[current_dominant_type]
	
	if current_other_sum == 0:
		if current_dominant_count == 0:
			label_middle.text = "%d" % current_dominant_sum
		else:
			label_middle.text = "%d×%d" % [current_dominant_sum, current_dominant_count]
	else:
		if current_dominant_count <= 1:
			label_middle.text = "(%d - %d)" % [current_dominant_sum, current_other_sum]
		else:
			label_middle.text = "(%d - %d) × %d" % [current_dominant_sum, current_other_sum, current_dominant_count]

func is_adjacent(number1: Number, number2: Number) -> bool:
	# Use stored grid coordinates instead of calculating
	var dx = abs(number1.grid_x - number2.grid_x)
	var dy = abs(number1.grid_y - number2.grid_y)
	
	return dx <= 1 and dy <= 1 and not (dx == 0 and dy == 0)

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed(&"mouse_right"):
		is_dragging = true
		last_mouse_position = get_viewport().get_mouse_position()
	elif Input.is_action_just_released(&"mouse_right"):
		is_dragging = false
		
	if Input.is_action_just_pressed(&"mouse_left"):
		is_mouse_pressed = true
		is_selecting = true
		if selected_number and not selected_number.is_used:
			# Determine if we're in selecting or unselecting mode based on first number
			is_unselecting_mode = selected_number in selected_numbers
			
			# Check adjacency for initial selection too
			var can_select = false
			
			if is_unselecting_mode:
				# For unselecting, always allow if it's already selected
				can_select = selected_number in selected_numbers
			else:
				# For selecting, check if it's adjacent to any selected number
				if selected_numbers.is_empty():
					# First number can always be selected
					can_select = true
				else:
					# Check adjacency with any selected number
					for num in selected_numbers:
						if is_adjacent(selected_number, num):
							can_select = true
							break
			
			if can_select:
				toggle_number_selection(selected_number)
	elif Input.is_action_just_released(&"mouse_left"):
		is_mouse_pressed = false
		is_selecting = false
		is_unselecting_mode = false
		
	if event is InputEventMouseMotion and is_selecting and is_mouse_pressed:
		if selected_number:
			# Only allow selection if adjacent to at least one selected number
			var can_select = false
			
			if is_unselecting_mode:
				# For unselecting, always allow if it's already selected
				can_select = selected_number in selected_numbers
			else:
				# For selecting, check if it's adjacent to any selected number
				if selected_numbers.is_empty():
					# First number can always be selected
					can_select = true
				else:
					# Check adjacency with any selected number
					for num in selected_numbers:
						if is_adjacent(selected_number, num):
							can_select = true
							break
			
			if can_select:
				if is_unselecting_mode and selected_number in selected_numbers:
					toggle_number_selection(selected_number)
				elif not is_unselecting_mode and not selected_number in selected_numbers:
					toggle_number_selection(selected_number)

	if Input.is_action_just_pressed(&"scroll_up"):
		target_zoom = (target_zoom + Vector2(0.1, 0.1)).clamp(Vector2.ONE * MIN_ZOOM, Vector2.ONE * MAX_ZOOM)
	elif Input.is_action_just_pressed(&"scroll_down"):
		target_zoom = (target_zoom - Vector2(0.1, 0.1)).clamp(Vector2.ONE * MIN_ZOOM, Vector2.ONE * MAX_ZOOM)
	
func _on_mouse_area_2d_area_entered(area: Area2D) -> void:
	var node = area.get_parent()
	if node is Number:
		selected_number = node

func _on_mouse_area_2d_area_exited(area: Area2D) -> void:
	var node = area.get_parent()
	if node is Number and node == selected_number:
		selected_number = null

func _on_mouse_focus_area_2d_area_entered(area: Area2D) -> void:
	var node = area.get_parent()
	if node is Number:
		node.toggle_focus(true)

func _on_mouse_focus_area_2d_area_exited(area: Area2D) -> void:
	var node = area.get_parent()
	if node is Number:
		node.toggle_focus(false)

func _on_box_progress_changed(box: Box, percentage: float) -> void:
	# Calculate total completion percentage across all boxes
	total_completion = 0.0
	for b: Box in boxes:
		total_completion += b.box_progress.value / b.box_progress.max_value
	
	total_completion /= boxes.size()
	
	label_complete_percentage.text = "%d%% Complete" % (total_completion * 100.0)
	
	if total_completion >= 1.0:
		game_over()
		
func game_over():
	print("Game completed!")
	# Calculate time spent
	var elapsed_time = (Time.get_ticks_msec() - start_time) / 1000.0  # Convert to seconds
	var minutes = int(elapsed_time / 60)
	var seconds = int(elapsed_time) % 60
	
	# Choose a random ending quote
	var quote_index = randi() % ending_quotes.size()
	label_end_score.text = ending_quotes[quote_index] % [player_name, minutes, seconds, int(highest_hit_score)]
	
	animation_player.play(&"game_over")
	is_game_started = false

func _on_button_restart_pressed() -> void:
	animation_player.play_backwards(&"game_over")
	animation_player.seek(1.0)
	start()
