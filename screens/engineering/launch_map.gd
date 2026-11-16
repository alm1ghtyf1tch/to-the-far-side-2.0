class_name LaunchMap
extends Control

signal site_clicked(id: String)

const IMAGE_PATH := "res://assets/textures/vehicle/usa_map.png"
const FONT := preload("res://assets/fonts/IBMPlexSans-Regular.woff2")
const FONT_BOLD := preload("res://assets/fonts/IBMPlexSans-SemiBold.woff2")
const FONT_MONO := preload("res://assets/fonts/IBMPlexMono-Regular.woff2")
const NAVY := Color("061f4a")
const RED := Color("dd361c")
const WHITE := Color("ffffff")
const PICK_RADIUS := 26.0
const LABELS := [
	["PACIFIC", 0.012, 0.585, 13], ["OCEAN", 0.012, 0.625, 13], ["ATLANTIC", 0.862, 0.305, 13], ["OCEAN", 0.884, 0.345, 13],
	["GULF OF MEXICO", 0.565, 0.86, 13], ["CANADA", 0.47, 0.045, 14], ["MEXICO", 0.345, 0.79, 14], ["CUBA", 0.80, 0.905, 11],
	["ALASKA", 0.018, 0.745, 12], ["HAWAII", 0.266, 0.978, 11],
]
const PARALLELS := [[25, 0.739], [30, 0.582], [35, 0.422], [40, 0.261], [45, 0.099]]

var sites: Array = []:
	set(value):
		sites = value
		queue_redraw()
var chosen := "":
	set(value):
		chosen = value
		queue_redraw()
var shown := "":
	set(value):
		shown = value
		queue_redraw()

var _hovered := ""
var _texture: Texture2D = null
var _time := 0.0


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	clip_contents = true
	if ResourceLoader.exists(IMAGE_PATH):
		_texture = load(IMAGE_PATH)
	mouse_exited.connect(func() -> void:
		_hovered = ""
		queue_redraw())


func _process(delta: float) -> void:
	_time += delta
	if is_visible_in_tree():
		queue_redraw()


func point_of(site: Dictionary) -> Vector2:
	return Vector2(float(site.get("map_x", 0.5)), float(site.get("map_y", 0.5))) * size


func _site_at(point: Vector2) -> String:
	var best := ""
	var best_distance := PICK_RADIUS
	for site: Dictionary in sites:
		var distance := point.distance_to(point_of(site))
		if distance < best_distance:
			best = str(site["id"])
			best_distance = distance
	return best


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var hovered := _site_at((event as InputEventMouseMotion).position)
		if hovered != _hovered:
			_hovered = hovered
			queue_redraw()
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		var id := _site_at(mouse.position)
		if not id.is_empty():
			accept_event()
			site_clicked.emit(id)


func _draw() -> void:
	if _texture:
		draw_texture_rect(_texture, Rect2(Vector2.ZERO, size), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color("0b3d91"))
	for label: Array in LABELS:
		draw_string(FONT_BOLD, Vector2(float(label[1]), float(label[2])) * size, str(label[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(label[3]), Color(WHITE, 0.6))
	for parallel: Array in PARALLELS:
		draw_string(FONT, Vector2(size.x - 64.0, float(parallel[1]) * size.y - 4.0), "%d°N" % int(parallel[0]), HORIZONTAL_ALIGNMENT_RIGHT, 60.0, 11, Color(WHITE, 0.7))

	for site: Dictionary in sites:
		if str(site["id"]) != shown:
			continue
		var at := point_of(site)
		var inset := float(site.get("lat", 0.0)) > 50.0
		var reach := size.x * (0.062 if inset else 0.19)
		var north := float(site.get("map_north", 0.0))
		if float(site.get("az_from", -1.0)) >= 0.0:
			var from := deg_to_rad(float(site["az_from"]) + north)
			var to := deg_to_rad(float(site["az_to"]) + north)
			var fan := PackedVector2Array([at])
			for step in 25:
				var bearing := lerpf(from, to, step / 24.0)
				fan.append(at + Vector2(sin(bearing), -cos(bearing)) * reach)
			draw_colored_polygon(fan, Color(WHITE, 0.28))
			draw_polyline(fan, Color(WHITE, 0.95), 1.5, true)
			draw_line(fan[fan.size() - 1], at, Color(WHITE, 0.95), 1.5, true)
			var middle := (from + to) * 0.5
			var tip := at + Vector2(sin(middle), -cos(middle)) * reach * 0.82
			var back := at + Vector2(sin(middle), -cos(middle)) * reach * 0.3
			draw_line(back, tip, RED, 2.5, true)
			for side: float in [-0.5, 0.5]:
				draw_line(tip, tip - Vector2(sin(middle + side), -cos(middle + side)) * 12.0, RED, 2.5, true)
		else:
			var radius := reach * 0.72
			draw_circle(at, radius, Color(NAVY, 0.1))
			for dash in 36:
				draw_arc(at, radius, TAU * dash / 36.0, TAU * (dash + 0.55) / 36.0, 4, NAVY, 2.0, true)
			var note := "land on every side"
			var note_width := FONT_BOLD.get_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			var plate := Rect2(at + Vector2(-note_width * 0.5 - 7.0, -radius - 11.0), Vector2(note_width + 14.0, 22.0))
			draw_rect(plate, NAVY)
			draw_string(FONT_BOLD, plate.position + Vector2(7.0, 16.0), note, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, WHITE)

	for site: Dictionary in sites:
		var id := str(site["id"])
		var at := point_of(site)
		var active := id == shown or id == _hovered
		if id == shown:
			draw_arc(at, 15.0 + sin(_time * 3.0) * 2.0, 0.0, TAU, 40, RED, 2.0, true)
		draw_circle(at, 9.5 if active else 8.0, WHITE)
		draw_circle(at, 7.0 if active else 5.5, RED)
		var text := str(site.get("short", site.get("name", "")))
		var font_size := 14
		var mark := 16.0 if id == chosen else 0.0
		var width := FONT_BOLD.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var tag := Rect2(at + Vector2(13.0, -12.0), Vector2(width + 12.0 + mark, 24.0))
		if tag.end.x > size.x - 30.0:
			tag.position.x = at.x - 13.0 - tag.size.x
		draw_rect(tag, WHITE if id == chosen else Color(NAVY, 0.92))
		if id == chosen:
			var tick := tag.position + Vector2(6.0, 12.0)
			draw_polyline(PackedVector2Array([tick, tick + Vector2(4.0, 4.5), tick + Vector2(11.0, -5.0)]), RED, 2.5, true)
		draw_string(FONT_BOLD, tag.position + Vector2(6.0 + mark, 17.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, NAVY if id == chosen else WHITE)
