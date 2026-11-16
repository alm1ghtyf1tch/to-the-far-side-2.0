class_name RocketStack
extends Control

signal slot_clicked(slot_id: String)

const TEXTURES := "res://assets/textures/vehicle/"
const ORDER: Array[String] = ["stage1", "stage2", "stage3", "lander", "service", "capsule", "escape"]
const GHOST := {
	"stage1": Vector2(150, 300), "stage2": Vector2(150, 170), "stage3": Vector2(100, 120), "lander": Vector2(100, 110),
	"service": Vector2(64, 66), "capsule": Vector2(64, 54), "escape": Vector2(24, 60),
}
const MARK := Color("dd361c")
const GHOST_COLOR := Color("ffffff")
const FONT_BOLD := preload("res://assets/fonts/IBMPlexSans-SemiBold.woff2")

@export var stack_scale := 0.84
@export var axis_x := 210.0
@export var base_y := 928.0

var selected := "":
	set(value):
		selected = value
		queue_redraw()

var dropped := {}:
	set(value):
		dropped = value
		queue_redraw()
var show_empty := true

var _parts := {}
var _drop := {}
var _rects := {}
var _hover := ""
var _cache := {}
var _time := 0.0
var _side_mounted := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_exited.connect(func() -> void:
		_hover = ""
		queue_redraw())


func _process(delta: float) -> void:
	_time += delta
	if not selected.is_empty() and _part(selected).is_empty():
		queue_redraw()


func set_part(slot_id: String, part: Dictionary, animate := true) -> void:
	_parts[slot_id] = part
	if animate and not part.is_empty():
		_drop[slot_id] = -70.0
		var tween := create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.tween_method(func(value: float) -> void:
			_drop[slot_id] = value
			queue_redraw(), -70.0, 0.0, 0.45)
	queue_redraw()


func slot_rect(slot_id: String) -> Rect2:
	_layout()
	return _rects.get(slot_id, Rect2())


func slot_texture(slot_id: String) -> Texture2D:
	return _texture(_part(slot_id))


func has_side_boosters() -> bool:
	_layout()
	return _side_mounted


func _part(slot_id: String) -> Dictionary:
	var value: Variant = _parts.get(slot_id)
	return value if value is Dictionary else {}


func _texture(part: Dictionary) -> Texture2D:
	var sprite := str(part.get("sprite", ""))
	if sprite.is_empty():
		return null
	if not _cache.has(sprite):
		var path := "%s%s.png" % [TEXTURES, sprite]
		_cache[sprite] = load(path) if ResourceLoader.exists(path) else null
	return _cache[sprite]


func _layout() -> void:
	_rects.clear()
	var y := base_y
	var first := _part("stage1")
	_side_mounted = str(first.get("mount", "")) == "side" and _texture(first) != null
	for slot_id in ORDER:
		var part := _part(slot_id)
		var texture := _texture(part)
		if slot_id == "stage1" and _side_mounted:
			continue
		if slot_id == "escape" and str(part.get("abort", "")) == "integrated":
			var capsule: Rect2 = _rects.get("capsule", Rect2())
			var pods := texture.get_size() * 0.5 * stack_scale if texture else Vector2.ZERO
			_rects[slot_id] = Rect2(axis_x - pods.x * 0.5, capsule.end.y - pods.y + 2.0, pods.x, pods.y)
			continue
		if part.is_empty() or texture == null:
			var ghost: Vector2 = GHOST[slot_id] * stack_scale
			if not part.is_empty():
				ghost.y = 0.0
			_rects[slot_id] = Rect2(axis_x - ghost.x * 0.5, y - ghost.y, ghost.x, ghost.y)
			y -= ghost.y
		else:
			var size := texture.get_size() * 0.5 * stack_scale
			var tuck := float(part.get("tuck", 0.0)) * stack_scale
			if slot_id == "stage2" and _side_mounted:
				tuck = 0.0
			_rects[slot_id] = Rect2(axis_x - size.x * 0.5, y + tuck - size.y, size.x, size.y)
			y += tuck - size.y
		if slot_id == "stage2" and _side_mounted:
			var boosters := _texture(first).get_size() * 0.5 * stack_scale
			_rects["stage1"] = Rect2(axis_x - boosters.x * 0.5, base_y - boosters.y, boosters.x, boosters.y)


func _marks(slot_id: String) -> Array[Rect2]:
	var rect: Rect2 = _rects[slot_id]
	if slot_id != "stage1" or not _side_mounted:
		return [rect]
	var column := (rect.size.x - GHOST["stage2"].x * stack_scale) * 0.5
	return [Rect2(rect.position, Vector2(column, rect.size.y)), Rect2(rect.end.x - column, rect.position.y, column, rect.size.y)]


func _draw() -> void:
	_layout()
	for index in range(ORDER.size() - 1, -1, -1):
		var slot_id := ORDER[index]
		var part := _part(slot_id)
		var rect: Rect2 = _rects[slot_id]
		var texture := _texture(part)
		if dropped.has(slot_id):
			continue
		if part.is_empty():
			if show_empty:
				_draw_ghost(rect, slot_id == selected)
		elif texture:
			draw_texture_rect(texture, Rect2(rect.position + Vector2(0.0, float(_drop.get(slot_id, 0.0))), rect.size), false)
	_draw_overlay("power", 0.5, true)
	_draw_overlay("comms", 0.0, false)
	for slot_id: String in [_hover, selected]:
		if slot_id.is_empty() or not _rects.has(slot_id):
			continue
		if (_rects[slot_id] as Rect2).size.y < 12.0:
			continue
		for mark in _marks(slot_id):
			_draw_brackets(mark.grow(6.0), MARK if slot_id == selected else Color(GHOST_COLOR, 0.85), 4.0 if slot_id == selected else 2.0)
		if slot_id == selected:
			var rect: Rect2 = (_rects[slot_id] as Rect2).grow(6.0)
			var tip := Vector2(rect.end.x + 8.0, rect.get_center().y)
			draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(13.0, -9.0), tip + Vector2(13.0, 9.0)]), MARK)


func _draw_overlay(slot_id: String, anchor: float, centered: bool) -> void:
	var texture := _texture(_part(slot_id))
	if texture == null:
		return
	var service: Rect2 = _rects["service"]
	var body := service.size.y
	if not _part("service").is_empty():
		body -= float(_part("service").get("tuck", 0.0)) * stack_scale
	var size := texture.get_size() * 0.5 * stack_scale
	var top := service.position.y + body * anchor - (size.y * 0.5 if centered else 0.0)
	draw_texture_rect(texture, Rect2(axis_x - size.x * 0.5, top + float(_drop.get(slot_id, 0.0)), size.x, size.y), false)


func _draw_brackets(rect: Rect2, color: Color, width: float) -> void:
	var arm := minf(18.0, minf(rect.size.x, rect.size.y) * 0.35)
	for corner: Vector2 in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
		var at := rect.position + rect.size * corner
		var dx := arm if corner.x == 0.0 else -arm
		var dy := arm if corner.y == 0.0 else -arm
		draw_line(at, at + Vector2(dx, 0.0), color, width)
		draw_line(at, at + Vector2(0.0, dy), color, width)


func _draw_ghost(rect: Rect2, active: bool) -> void:
	var pulse := 0.6 + 0.35 * sin(_time * 4.0) if active else 0.4
	var color := Color(GHOST_COLOR, pulse)
	draw_rect(rect, Color(GHOST_COLOR, 0.08 if active else 0.04), true)
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for index in 4:
		draw_dashed_line(corners[index], corners[(index + 1) % 4], color, 2.0, 8.0)
	var center := rect.get_center()
	var arm := minf(minf(rect.size.x, rect.size.y) * 0.22, 14.0)
	draw_line(center - Vector2(arm, 0.0), center + Vector2(arm, 0.0), color, 3.0)
	draw_line(center - Vector2(0.0, arm), center + Vector2(0.0, arm), color, 3.0)


func _slot_at(point: Vector2) -> String:
	for index in range(ORDER.size() - 1, -1, -1):
		var slot_id := ORDER[index]
		if not _rects.has(slot_id):
			continue
		for mark in _marks(slot_id):
			if mark.grow(4.0).has_point(point):
				return slot_id
	return ""


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var found := _slot_at((event as InputEventMouseMotion).position)
		if found != _hover:
			_hover = found
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not found.is_empty() else Control.CURSOR_ARROW
			queue_redraw()
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		var found := _slot_at(mouse.position)
		if not found.is_empty():
			slot_clicked.emit(found)
