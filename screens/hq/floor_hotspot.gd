@tool
class_name FloorHotspot
extends Control

signal clicked(hotspot: FloorHotspot)

@export var floor_number := 1
@export var department := "Science"
@export var image_size := Vector2(1671, 941)
@export var corners := PackedVector2Array():
	set(value):
		corners = value
		_update_shape()
@export var plate_offset := Vector2(12, 10):
	set(value):
		plate_offset = value
		_update_shape()

const ACCENT := Color("6fb0ff")

var is_goal := false:
	set(value):
		is_goal = value
		queue_redraw()
var is_selected := false:
	set(value):
		is_selected = value
		queue_redraw()

var _hovered := false
var _time := 0.0
var _shape := PackedVector2Array()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_ALL
	mouse_exited.connect(_set_hovered.bind(false))
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	resized.connect(_update_shape)
	_update_shape()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if is_goal and not is_selected:
		_time += delta
		queue_redraw()


func _has_point(point: Vector2) -> bool:
	return _shape.size() >= 3 and Geometry2D.is_point_in_polygon(point, _shape)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_set_hovered(true)
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		clicked.emit(self)
	elif event.is_action_pressed("ui_accept"):
		accept_event()
		clicked.emit(self)


func _draw() -> void:
	if _shape.size() < 3:
		return
	var fill := 0.0
	var border := 0.0
	if Engine.is_editor_hint():
		border = 0.8
	elif is_selected:
		fill = 0.10
		border = 1.0
	elif _hovered or has_focus():
		fill = 0.14
		border = 0.9
	if is_goal and not is_selected:
		var pulse := 0.5 + 0.5 * sin(_time * 3.2)
		border = maxf(border, 0.35 + 0.65 * pulse)
	if fill > 0.0:
		draw_colored_polygon(_shape, Color(ACCENT, fill))
	if border > 0.0:
		var outline := _shape.duplicate()
		outline.append(_shape[0])
		draw_polyline(outline, Color(ACCENT, border), 4.0, true)


func _update_shape() -> void:
	if not is_inside_tree():
		return
	var scale := size / image_size
	_shape.clear()
	for corner in corners:
		_shape.append(corner * scale)
	var plate := get_node_or_null("Plate") as Control
	if plate and not _shape.is_empty():
		plate.position = _shape[0] + plate_offset * scale
	queue_redraw()


func _set_hovered(value: bool) -> void:
	if _hovered == value:
		return
	_hovered = value
	queue_redraw()
