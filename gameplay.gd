class_name Gameplay extends CanvasLayer

@onready var input_name: LineEdit = %InputName
@onready var label_name: Label = %LabelName
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var box_container: HBoxContainer = $UI/Gameplay/UI/Bottom/BoxContainer
@onready var number_container: Node2D = %NumberContainer
@onready var camera_2d: Camera2D = %Camera2D
@onready var sub_viewport: SubViewport = $UI/Gameplay/Control/SubViewportContainer/SubViewport

"""​The Four Tempers introduced by Lumon Industries' founder, Kier Eagan:

WO (Woe) – Represents sadness, despair, grief, or sorrow. Numbers in this category may evoke a sense of loss or suffering.
FC (Frolic) – Associated with joy, excitement, and playfulness. Numbers categorized here feel lighthearted and euphoric.
DR (Dread) – Symbolizes fear, anxiety, and an impending sense of doom. These numbers may provoke unease or paranoia.
MA (Malice) – Stands for anger, hostility, and aggression. Numbers in this category feel menacing or violent.
"""

const NUMBER = preload("res://number.tscn")
# const NUMBER_ROW_COUNT: int = 33
# const NUMBER_COLLUMN_COUNT: int = 80
const NUMBER_ROW_COUNT: int = 20
const NUMBER_COLLUMN_COUNT: int = 48
const MIN_ZOOM: float = 0.4
const MAX_ZOOM: float = 1.0

const CAMERA_MOVE_SPEED: float = 500.0
const ZOOM_DURATION: float = 0.2
const ZOOM_SPEED: float = 5.0
const GRID_SPACING := 120.0
const VISIBILITY_MARGIN_H := 100.0    # Horizontal margin
const VISIBILITY_MARGIN_TOP := 100.0  # Top margin (larger for UI elements)
const VISIBILITY_MARGIN_BOTTOM := 400.0  # Bottom margin
enum SCORES {
	WO,
	FC,
	DR,
	MA
}

var is_game_started: bool = false
var boxes: Array[Box] = []
var number_grid: Array[Array] = []
var is_dragging: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO

var current_zoom_tween: Tween
var target_zoom: Vector2 = Vector2.ONE

func _ready() -> void:
	input_name.text = ""
	input_name.grab_focus()
	
	for child in box_container.get_children():
		if child is Box:
			boxes.append(child)
			
	# TODO REMOVE ME
	spawnNumbers()
	start()

	print("get_viewport().get_visible_rect().size", get_viewport().get_visible_rect().size)
	
func _process(delta: float) -> void:
	if is_game_started:
		if is_dragging:
			handle_drag()
			
		if not (is_equal_approx(camera_2d.zoom.x, target_zoom.x) and is_equal_approx(camera_2d.zoom.y, target_zoom.y)):
			camera_2d.zoom = camera_2d.zoom.lerp(target_zoom, ZOOM_SPEED * delta)
			
		hide_outside_numbers()
		
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
		for number: Node2D in row:
			if camera_rect.has_point(number.position):
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
	if is_restart:
		for box: Box in boxes:
			box.reset()
	
	is_game_started = true
	
func spawnNumbers(should_clear: bool = true):
	const spacing := 120.0
	
	for row in range(NUMBER_COLLUMN_COUNT):
		var number_row: Array = []
		for column in range(NUMBER_ROW_COUNT):
			var number: Node2D = NUMBER.instantiate()
			number.global_position = Vector2(
				row * spacing, 
				column * spacing
				)
			number_container.add_child(number)
			number_row.append(number)
		
		number_grid.append(number_row)
	
	var viewport_size = get_viewport().get_visible_rect().size
	camera_2d.offset = viewport_size / 2
	camera_2d.limit_left = number_grid[0][0].position.x
	camera_2d.limit_right = number_grid[-1][-1].position.x
	camera_2d.limit_top = number_grid[0][0].position.y - 300.0
	camera_2d.limit_bottom = number_grid[-1][-1].position.y - 300.0
			
func find_cells_in_circle(x: float, y: float, radius: float) -> Array:
	var result = []
	var center = Vector2(x, y)
	
	for i in range(number_grid.size()):
		for j in range(number_grid[i].size()):
			# Get the world position of the current cell
			var cell: Node2D = number_grid[i][j]
			var distance = center.distance_to(cell.global_position)
			
			# If the distance is less than or equal to the radius, add to result
			if distance <= radius:
				result.append(cell)
	
	return result
	
func _on_input_name_text_submitted(new_text: String) -> void:
	if is_game_started: return
	
	if len(new_text) < 3:
		print("New too short")
		return
		
	label_name.text = new_text
	start()
	
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed(&"mouse_right"):
		is_dragging = true
		last_mouse_position = get_viewport().get_mouse_position()
	elif Input.is_action_just_released(&"mouse_right"):
		is_dragging = false
		
	if event is InputEventMouseMotion:
		var grid_pos = get_grid_position(event.position)
		print("Grid position:", grid_pos)
		
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed(&"scroll_up"):
		target_zoom = (target_zoom + Vector2(0.1, 0.1)).clamp(Vector2.ONE * MIN_ZOOM, Vector2.ONE * MAX_ZOOM)
	elif Input.is_action_just_pressed(&"scroll_down"):
		target_zoom = (target_zoom - Vector2(0.1, 0.1)).clamp(Vector2.ONE * MIN_ZOOM, Vector2.ONE * MAX_ZOOM)
	
func get_grid_position(mouse_pos: Vector2) -> Vector2i:
	var viewport_mouse = get_viewport().get_mouse_position()
	var world_pos = (viewport_mouse - camera_2d.offset) / camera_2d.zoom + camera_2d.position
	var grid_pos = Vector2i(
		floor(world_pos.x / GRID_SPACING),
		floor(world_pos.y / GRID_SPACING)
	)
	return grid_pos

	
