extends Control
## Projected labels use the same camera as the mesh and explicit sphere occlusion.

var scene: LunarScene3D
var _styles: Array[StyleBoxFlat] = []
var _names: Array[String] = []
const OFFSETS := [Vector2(38, 48), Vector2(-135, 36), Vector2(-145, -20), Vector2(-130, -45), Vector2(30, 62), Vector2(34, -42)]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for color: Color in [Color("889b9d"), VisualTheme.CYAN, VisualTheme.AMBER]:
		_styles.append(VisualTheme.surface(Color("101a24"), Color(color, 0.6), 0))
	for site: Dictionary in Campaign.sites():
		_names.append(str(site["mission"]).to_upper())


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if scene == null or scene.camera == null:
		return
	var camera := scene.camera
	for index in scene.markers.size():
		var marker := scene.markers[index]
		var normal := marker.position.normalized()
		if not LunarCoordinates.visible(normal, camera.position, LunarScene3D.RADIUS) or camera.is_position_behind(marker.position):
			continue
		var point := camera.unproject_position(marker.position) * size / Vector2(camera.get_viewport().size)
		var highlighted := index == scene.selected or index == scene.previewed
		var color := VisualTheme.AMBER if index == scene.selected else (VisualTheme.CYAN if index == scene.previewed else Color("889b9d"))
		var end: Vector2 = point + OFFSETS[index] * (1.0 if highlighted else 0.8)
		var text := _names[index]
		var width := VisualTheme.MONO.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 16
		var rect := Rect2(end + Vector2(-8, -16), Vector2(width, 23))
		draw_line(point, end, Color(color, 0.65), 1, true)
		draw_style_box(_styles[2 if index == scene.selected else (1 if index == scene.previewed else 0)], rect)
		draw_string(VisualTheme.MONO, end, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)
		if highlighted:
			draw_arc(point, 9, 0, TAU, 32, color, 1.5, true)
