class_name GaugeBar
extends Control

var have := 0.0:
	set(value):
		have = value
		queue_redraw()
var need := 0.0:
	set(value):
		need = value
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(0.0, 14.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var bar := Rect2(0.0, 4.0, size.x, 6.0)
	draw_rect(bar, Color(1, 1, 1, 0.18), true)
	var top := maxf(maxf(have, need) * 1.18, 0.0001)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(have / top, 0.0, 1.0), bar.size.y)), Color("ffffff"), true)
	if need > 0.0:
		var x := bar.size.x * need / top
		draw_rect(Rect2(x - 1.5, 0.0, 3.0, size.y), Color("dd361c"), true)
