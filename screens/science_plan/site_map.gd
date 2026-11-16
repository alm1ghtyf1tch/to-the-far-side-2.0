class_name SiteMap
extends Control

signal site_clicked(index: int)
signal caption_changed(text: String)

const IMAGE_PATH := "res://assets/textures/moon_sites_map.png"
const FONT := preload("res://assets/fonts/IBMPlexSans-Regular.woff2")
const FONT_BOLD := preload("res://assets/fonts/IBMPlexSans-SemiBold.woff2")
const MARIA := [
	["Oceanus\nProcellarum", 18.4, -55.0, 17.0],
	["Mare Imbrium", 33.0, -16.0, 18.0],
	["Mare\nSerenitatis", 28.0, 17.5, 11.0],
	["Mare\nTranquillitatis", 8.5, 31.4, 13.0],
	["Mare\nCrisium", 17.0, 59.1, 8.5],
	["Mare\nFecunditatis", -7.8, 51.3, 12.0],
	["Mare\nNectaris", -15.2, 35.5, 5.6],
	["Mare Nubium", -21.3, -16.6, 11.0],
	["Mare\nHumorum", -24.4, -38.6, 6.9],
	["Mare Insularum", 7.8, -30.6, 8.0],
	["Mare Cognitum", -10.5, -22.3, 5.5],
	["Mare Vaporum", 13.3, 3.6, 4.0],
	["Mare Frigoris", 56.0, 1.4, 5.0],
]
const TEXTURE_CENTER := Vector2(352.8, 349.6) / 700.0
const TEXTURE_RADIUS := 306.0 / 700.0
const TEXTURE_LABELS := [
	["Mare Frigoris", 332.0, 84.0],
	["Mare\nImbrium", 256.0, 223.0],
	["Mare\nSerenitatis", 432.0, 232.0],
	["Mare\nVaporum", 381.0, 292.0],
	["Mare\nTranquillitatis", 503.0, 298.0],
	["Mare\nCrisium", 604.0, 257.0],
	["Mare\nFecunditatis", 592.0, 365.0],
	["Mare\nNectaris", 535.0, 423.0],
	["Oceanus\nProcellarum", 117.0, 352.0],
	["Mare\nCognitum", 194.0, 399.0],
	["Mare\nHumorum", 189.0, 475.0],
]
const RED := Color("dd361c")
const PICK_RADIUS := 22.0

@export var disc_center := Vector2(0.5, 0.5)
@export var disc_radius := 0.46

var sites: Array = []:
	set(value):
		sites = value
		queue_redraw()
var selected := -1:
	set(value):
		selected = value
		_emit_caption()
		queue_redraw()

var _hovered := -1
var _texture: Texture2D = null


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if ResourceLoader.exists(IMAGE_PATH):
		_texture = load(IMAGE_PATH)
		disc_center = TEXTURE_CENTER
		disc_radius = TEXTURE_RADIUS
	mouse_exited.connect(func() -> void:
		_hovered = -1
		_emit_caption()
		queue_redraw())


func project(lat_deg: float, lon_deg: float) -> Vector2:
	var lat := deg_to_rad(lat_deg)
	var lon := deg_to_rad(lon_deg)
	var side := minf(size.x, size.y)
	return size * disc_center + Vector2(cos(lat) * sin(lon), -sin(lat)) * side * disc_radius


func _site_at(point: Vector2) -> int:
	var best := -1
	var best_distance := PICK_RADIUS
	for index in sites.size():
		var distance := point.distance_to(project(float(sites[index].get("lat", 0.0)), float(sites[index].get("lon", 0.0))))
		if distance < best_distance:
			best = index
			best_distance = distance
	return best


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var hovered := _site_at((event as InputEventMouseMotion).position)
		if hovered != _hovered:
			_hovered = hovered
			_emit_caption()
			queue_redraw()
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		var index := _site_at(mouse.position)
		if index >= 0:
			accept_event()
			site_clicked.emit(index)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("212121"))
	if _texture:
		_draw_texture_map()
	else:
		_draw_scheme()
	for index in sites.size():
		var site: Dictionary = sites[index]
		var point := project(float(site.get("lat", 0.0)), float(site.get("lon", 0.0)))
		var active := index == selected
		var radius := 11.0 if active else (9.0 if index == _hovered else 7.0)
		if active:
			draw_arc(point, 19.0, 0.0, TAU, 40, Color.WHITE, 2.5, true)
		draw_circle(point, radius + 2.5, Color.WHITE)
		draw_circle(point, radius, RED)
		var number := str(site.get("mission", "")).replace("Apollo ", "")
		var offset := Vector2(14.0, -22.0)
		for other: Dictionary in sites:
			var gap := project(float(other.get("lat", 0.0)), float(other.get("lon", 0.0))) - point
			if gap.x > 1.0 and gap.x < 50.0 and absf(gap.y) < 26.0:
				offset.x = -26.0 - FONT_BOLD.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		_tag(point + offset, number, 17, Color.WHITE, Color(0.05, 0.08, 0.13, 0.85))


func _emit_caption() -> void:
	var shown := _hovered if _hovered >= 0 else selected
	if shown < 0 or shown >= sites.size():
		caption_changed.emit("")
		return
	var site: Dictionary = sites[shown]
	caption_changed.emit("%s  ·  %s  ·  %s" % [site.get("mission", ""), site.get("name", ""), site.get("english", "")])


func _draw_texture_map() -> void:
	var side := minf(size.x, size.y)
	draw_texture_rect(_texture, Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side)), false)
	var origin := (size - Vector2(side, side)) * 0.5
	for label: Array in TEXTURE_LABELS:
		var lines := str(label[0]).split("\n")
		var at := origin + Vector2(float(label[1]), float(label[2])) / 700.0 * side - Vector2(90.0, (lines.size() - 1) * 8.0 - 5.0)
		for line in lines:
			draw_string_outline(FONT_BOLD, at, line, HORIZONTAL_ALIGNMENT_CENTER, 180.0, 15, 4, Color(0.93, 0.95, 1.0, 0.7))
			draw_string(FONT_BOLD, at, line, HORIZONTAL_ALIGNMENT_CENTER, 180.0, 15, Color("061f4a"))
			at.y += 16.0
	var center := size * disc_center
	var radius := side * disc_radius
	var ink := Color("aeb0b5")
	for degrees in range(-80, 81, 10):
		if degrees == 0:
			continue
		var angle := deg_to_rad(float(degrees))
		for direction: float in [-1.0, 1.0]:
			var at := center + Vector2(cos(angle) * direction, -sin(angle)) * (radius + 20.0)
			draw_string(FONT, at + Vector2(-20.0, 5.0), "%d°" % absi(degrees), HORIZONTAL_ALIGNMENT_CENTER, 40.0, 13, ink)
	for mark: Array in [["N", Vector2(0, -1)], ["S", Vector2(0, 1)], ["W", Vector2(-1, 0)], ["E", Vector2(1, 0)]]:
		var at: Vector2 = center + (mark[1] as Vector2) * (radius + 20.0)
		draw_string(FONT_BOLD, at + Vector2(-20.0, 6.0), mark[0], HORIZONTAL_ALIGNMENT_CENTER, 40.0, 16, Color("ffffff"))


func _draw_scheme() -> void:
	var side := minf(size.x, size.y)
	var center := size * disc_center
	var radius := side * disc_radius
	draw_circle(center, radius, Color("aeb0b5"))
	for mare: Array in MARIA:
		var lat := deg_to_rad(float(mare[1]))
		var lon := deg_to_rad(float(mare[2]))
		var squeeze := maxf(cos(lon) * cos(lat), 0.25)
		var spot := radius * sin(deg_to_rad(float(mare[3])))
		draw_set_transform(project(float(mare[1]), float(mare[2])), 0.0, Vector2(squeeze, 1.0))
		draw_circle(Vector2.ZERO, spot, Color("323a45"))
		draw_set_transform(Vector2.ZERO)
	draw_arc(center, radius, 0.0, TAU, 96, Color("e1f3f8"), 2.0, true)
	for mare: Array in MARIA:
		var lines := str(mare[0]).split("\n")
		var at := project(float(mare[1]), float(mare[2])) - Vector2(80.0, (lines.size() - 1) * 7.0 - 4.0)
		for line in lines:
			draw_string(FONT, at, line, HORIZONTAL_ALIGNMENT_CENTER, 160.0, 13, Color("212121"))
			at.y += 14.0
	draw_string(FONT_BOLD, Vector2(0.0, 22.0), "N", HORIZONTAL_ALIGNMENT_CENTER, size.x, 15, Color("aeb0b5"))


func _tag(at: Vector2, text: String, font_size: int, color: Color, fill: Color) -> void:
	var text_size := FONT_BOLD.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	at.x = clampf(at.x, 4.0, size.x - text_size.x - 16.0)
	draw_rect(Rect2(at, text_size + Vector2(12.0, 4.0)), fill)
	draw_string(FONT_BOLD, at + Vector2(6.0, text_size.y - 3.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
