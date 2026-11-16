extends Control

const SALARY_COLOR := Color("aeb0b5")
const CALC_COLOR := Color("0b3d91")
const LEFT_COLOR := Color("9bdaf1")
const FONT := preload("res://assets/fonts/IBMPlexSans-SemiBold.woff2")

var salaries := 3.0
var calc := 0.0


func set_parts(new_salaries: float, new_calc: float) -> void:
	salaries = new_salaries
	calc = new_calc
	queue_redraw()


func _draw() -> void:
	var x := 0.0
	var parts := [
		[salaries, SALARY_COLOR, Color.WHITE, ""],
		[calc, CALC_COLOR, Color.WHITE, "Calculations"],
		[100.0 - salaries - calc, LEFT_COLOR, Color("061f4a"), "Rocket, spacecraft and crew"],
	]
	for part: Array in parts:
		var width := size.x * float(part[0]) / 100.0
		if width <= 0.0:
			continue
		draw_rect(Rect2(x, 0.0, width, size.y), part[1])
		var label := "%s %d%%" % [part[3], roundi(float(part[0]))]
		label = label.strip_edges()
		var text_width := FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		if text_width + 20.0 <= width:
			draw_string(FONT, Vector2(x + 12.0, size.y * 0.5 + 7.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, part[2])
		x += width
	draw_rect(Rect2(Vector2.ZERO, size), Color("aeb0b5"), false, 1.0)
