extends PanelContainer
## Light physical trim over the shared theme; no input or simulation behavior.

func _ready() -> void:
	resized.connect(queue_redraw)
	mouse_filter = Control.MOUSE_FILTER_PASS


func _draw() -> void:
	var bounds := Rect2(Vector2(3, 3), size - Vector2(6, 6))
	draw_line(bounds.position, Vector2(bounds.end.x, bounds.position.y), Color("64707a"), 1)
	draw_line(Vector2(bounds.position.x, bounds.end.y), bounds.end, Color("080d14"), 2)
	for corner: Vector2 in [Vector2(8, 8), Vector2(size.x - 8, 8), Vector2(8, size.y - 8), size - Vector2(8, 8)]:
		draw_circle(corner, 2.8, Color("080d14"))
		draw_line(corner - Vector2(1.4, 0), corner + Vector2(1.4, 0), Color("687580"), 1)
