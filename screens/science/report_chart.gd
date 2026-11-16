class_name ReportChart
extends Control

const FONT := preload("res://assets/fonts/IBMPlexSans-Regular.woff2")
const FONT_BOLD := preload("res://assets/fonts/IBMPlexSans-SemiBold.woff2")
const INK := Color("212121")
const MUTED := Color("323a45")
const BLUE := Color("0b3d91")
const LIGHT_BLUE := Color("00a6d2")
const GRID := Color("aeb0b5", 0.45)
const GREEN := Color("046b99")
const RED := Color("dd361c")

const TARGET_KM := 110.0
const CORRIDOR := Vector2(80.0, 140.0)
const FLIGHTS := 1000
const KM_PER_PERCENT := 8.0

var kind := "trajectory"
var margin_pct := 1.0


static func simulate(margin: float) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20330720
	var samples := PackedFloat32Array()
	var inside := 0
	var impact := 0
	for i in FLIGHTS:
		var altitude := rng.randfn(TARGET_KM, margin * KM_PER_PERCENT)
		samples.append(altitude)
		if altitude >= CORRIDOR.x and altitude <= CORRIDOR.y:
			inside += 1
		elif altitude <= 0.0:
			impact += 1
	return {"samples": samples, "inside": inside, "impact": impact}


func _draw() -> void:
	match kind:
		"trajectory":
			_draw_trajectory()
		"dv":
			_draw_dv()
		"rocket":
			_draw_rocket()
		"dispersion":
			_draw_dispersion()


func _text(pos: Vector2, text: String, size_px := 16, color := INK, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, bold := false) -> void:
	draw_string(FONT_BOLD if bold else FONT, pos, text, align, width, size_px, color)


func _draw_trajectory() -> void:
	var w := size.x
	var h := size.y
	var earth := Vector2(w * 0.13, h * 0.5)
	var moon := Vector2(w * 0.85, h * 0.5)
	var earth_r := 46.0
	var moon_r := 20.0
	var gap := 16.0
	var span := moon.x - earth.x
	var fan := 12
	for i in fan:
		var shift := (float(i) / (fan - 1) - 0.5) * 2.0 * margin_pct * 5.0
		_bezier(earth + Vector2(8.0, earth_r + 8.0), earth + Vector2(span * 0.35, h * 0.40),
				moon + Vector2(-span * 0.30, -h * 0.44 + shift), moon + Vector2(0.0, -moon_r - gap + shift), Color(LIGHT_BLUE, 0.35), 1.5)
	_bezier(earth + Vector2(8.0, earth_r + 8.0), earth + Vector2(span * 0.35, h * 0.40),
			moon + Vector2(-span * 0.30, -h * 0.44), moon + Vector2(0.0, -moon_r - gap), BLUE, 3.0)
	draw_arc(moon, moon_r + gap, -PI * 0.5, PI * 0.5, 32, BLUE, 3.0, true)
	_bezier(moon + Vector2(0.0, moon_r + gap), moon + Vector2(-span * 0.30, h * 0.44),
			earth + Vector2(span * 0.35, -h * 0.40), earth + Vector2(8.0, -earth_r - 8.0), BLUE, 3.0, true)
	draw_circle(earth, earth_r, Color("105bd8"))
	draw_circle(moon, moon_r, Color("aeb0b5"))
	_text(earth + Vector2(-60.0, earth_r + 34.0), "Earth", 17, INK, HORIZONTAL_ALIGNMENT_CENTER, 120.0, true)
	_text(moon + Vector2(-60.0, moon_r + 62.0), "Moon", 17, INK, HORIZONTAL_ALIGNMENT_CENTER, 120.0, true)
	_step(earth + Vector2(54.0, earth_r + 30.0), "1", "Engine burn sends the ship toward the Moon")
	_step(moon + Vector2(moon_r + gap + 14.0, -8.0), "2", "", true)
	_text(Vector2(w * 0.60, 26.0), "2  The Moon's gravity bends the path around the far side", 16, INK, HORIZONTAL_ALIGNMENT_LEFT, -1, false)
	_step(earth + Vector2(54.0, -earth_r - 36.0), "3", "With the engine off, the ship falls back to Earth")
	_text(Vector2(0.0, h - 8.0), "Not to scale. Thin lines: possible paths inside our ±%s%% uncertainty, before correction burns." % _num(margin_pct), 15, MUTED)


func _step(pos: Vector2, number: String, text: String, dot_only := false) -> void:
	draw_circle(pos, 12.0, BLUE)
	draw_string(FONT_BOLD, pos + Vector2(-12.0, 6.0), number, HORIZONTAL_ALIGNMENT_CENTER, 24.0, 16, Color.WHITE)
	if not dot_only:
		_text(pos + Vector2(20.0, 6.0), text, 16)


func _bezier(a: Vector2, c1: Vector2, c2: Vector2, b: Vector2, color: Color, width: float, dashed := false) -> void:
	var points := PackedVector2Array()
	for i in 49:
		points.append(a.bezier_interpolate(c1, c2, b, i / 48.0))
	if dashed:
		for i in range(0, points.size() - 1, 2):
			draw_line(points[i], points[i + 1], color, width, true)
	else:
		draw_polyline(points, color, width, true)


func _draw_dv() -> void:
	var rows := [
		["Launch to Earth orbit", 9.4],
		["Burn toward the Moon", 3.1],
		["Brake into lunar orbit", 0.9],
		["Descend to the surface", 2.1],
		["Lift off from the Moon", 1.9],
		["Burn toward Earth", 1.0],
	]
	var label_w := 250.0
	var plot := Rect2(label_w, 8.0, size.x - label_w - 90.0, size.y - 52.0)
	var max_value := 10.0
	for tick in 6:
		var x := plot.position.x + plot.size.x * tick * 2.0 / max_value
		draw_line(Vector2(x, plot.position.y), Vector2(x, plot.end.y), GRID, 1.0)
		_text(Vector2(x - 30.0, plot.end.y + 22.0), "%d" % (tick * 2), 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER, 60.0)
	_text(Vector2(plot.end.x + 12.0, plot.end.y + 22.0), "km/s", 15, MUTED)
	var row_h := plot.size.y / rows.size()
	for i in rows.size():
		var y := plot.position.y + i * row_h
		var value: float = rows[i][1]
		_text(Vector2(0.0, y + row_h * 0.5 + 6.0), rows[i][0], 17)
		var bar := Rect2(plot.position.x, y + row_h * 0.2, plot.size.x * value / max_value, row_h * 0.6)
		draw_rect(bar, BLUE if i > 0 else LIGHT_BLUE)
		_text(Vector2(bar.end.x + 10.0, y + row_h * 0.5 + 6.0), "%.1f" % value, 17, INK, HORIZONTAL_ALIGNMENT_LEFT, -1, true)


func _draw_rocket() -> void:
	var plot := Rect2(70.0, 14.0, size.x - 110.0, size.y - 74.0)
	var max_dv := 14.0
	var max_share := 0.96
	for tick in 8:
		var y := plot.end.y - plot.size.y * tick * 2.0 / max_dv
		draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), GRID, 1.0)
		_text(Vector2(0.0, y + 5.0), "%d" % (tick * 2), 15, MUTED, HORIZONTAL_ALIGNMENT_RIGHT, plot.position.x - 10.0)
	for tick in 6:
		var share := tick * 0.2
		if share > max_share:
			break
		var x := plot.position.x + plot.size.x * share / max_share
		draw_line(Vector2(x, plot.position.y), Vector2(x, plot.end.y), GRID, 1.0)
		_text(Vector2(x - 30.0, plot.end.y + 22.0), "%d%%" % roundi(share * 100.0), 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER, 60.0)
	_text(Vector2(plot.position.x, plot.end.y + 50.0), "Share of the rocket's starting mass that is propellant", 16, MUTED, HORIZONTAL_ALIGNMENT_CENTER, plot.size.x)
	_text(Vector2(plot.position.x + 10.0, plot.position.y + 18.0), "Speed gained, km/s", 16, MUTED)
	for engine: Array in [[4.1, BLUE, "Hydrogen engine", -12.0], [3.0, LIGHT_BLUE, "Kerosene engine", 44.0]]:
		var exhaust: float = engine[0]
		var points := PackedVector2Array()
		for i in 97:
			var share := max_share * i / 96.0
			var dv := minf(exhaust * log(1.0 / (1.0 - share)), max_dv)
			points.append(Vector2(plot.position.x + plot.size.x * share / max_share, plot.end.y - plot.size.y * dv / max_dv))
		draw_polyline(points, engine[1], 3.0, true)
		var label_share := 0.80
		var label_dv := exhaust * log(1.0 / (1.0 - label_share))
		_text(Vector2(plot.position.x + plot.size.x * label_share / max_share - 190.0, plot.end.y - plot.size.y * label_dv / max_dv + float(engine[3])), engine[2], 16, engine[1], HORIZONTAL_ALIGNMENT_RIGHT, 180.0, true)
	var need := 9.4
	var share_needed := 1.0 - exp(-need / 4.1)
	var px := plot.position.x + plot.size.x * share_needed / max_share
	var py := plot.end.y - plot.size.y * need / max_dv
	_dashed(Vector2(plot.position.x, py), Vector2(px, py), RED)
	_dashed(Vector2(px, py), Vector2(px, plot.end.y), RED)
	draw_circle(Vector2(px, py), 6.0, RED)
	_text(Vector2(plot.position.x + 12.0, py - 10.0), "Reaching Earth orbit takes 9.4 km/s: about %d%% of the rocket must be propellant" % roundi(share_needed * 100.0), 16, RED, HORIZONTAL_ALIGNMENT_LEFT, -1, true)


func _dashed(from: Vector2, to: Vector2, color: Color) -> void:
	var length := from.distance_to(to)
	var direction := (to - from) / maxf(length, 1.0)
	var at := 0.0
	while at < length:
		draw_line(from + direction * at, from + direction * minf(at + 8.0, length), color, 2.0)
		at += 14.0


func _draw_dispersion() -> void:
	var result := simulate(margin_pct)
	var samples: PackedFloat32Array = result["samples"]
	var plot := Rect2(20.0, 44.0, size.x - 40.0, size.y - 118.0)
	var from_km := -120.0
	var to_km := 340.0
	var bin_km := 10.0
	var bins := PackedInt32Array()
	bins.resize(int((to_km - from_km) / bin_km))
	for altitude in samples:
		if altitude >= from_km and altitude < to_km:
			bins[int((altitude - from_km) / bin_km)] += 1
	var top := 1
	for count in bins:
		top = maxi(top, count)
	var km_to_x := func(km: float) -> float: return plot.position.x + plot.size.x * (km - from_km) / (to_km - from_km)
	draw_rect(Rect2(plot.position.x, plot.position.y, km_to_x.call(0.0) - plot.position.x, plot.size.y), Color(RED, 0.10))
	draw_rect(Rect2(km_to_x.call(CORRIDOR.x), plot.position.y, km_to_x.call(CORRIDOR.y) - km_to_x.call(CORRIDOR.x), plot.size.y), Color(GREEN, 0.16))
	_text(Vector2(plot.position.x + 8.0, plot.position.y + 22.0), "Hits the Moon", 15, RED, HORIZONTAL_ALIGNMENT_LEFT, -1, true)
	_text(Vector2(km_to_x.call(CORRIDOR.x) - 60.0, plot.position.y - 10.0), "Safe corridor", 15, GREEN, HORIZONTAL_ALIGNMENT_CENTER, km_to_x.call(CORRIDOR.y) - km_to_x.call(CORRIDOR.x) + 120.0, true)
	_text(Vector2(plot.end.x - 260.0, plot.position.y + 22.0), "Too high to enter orbit", 15, MUTED, HORIZONTAL_ALIGNMENT_RIGHT, 250.0, true)
	var bar_w := plot.size.x / bins.size()
	for i in bins.size():
		if bins[i] == 0:
			continue
		var bar_h := plot.size.y * 0.92 * bins[i] / top
		draw_rect(Rect2(plot.position.x + i * bar_w + 1.0, plot.end.y - bar_h, bar_w - 2.0, bar_h), BLUE)
	draw_line(Vector2(plot.position.x, plot.end.y), Vector2(plot.end.x, plot.end.y), INK, 2.0)
	for km in [-100, 0, 100, 200, 300]:
		var x: float = km_to_x.call(float(km))
		draw_line(Vector2(x, plot.end.y), Vector2(x, plot.end.y + 6.0), INK, 2.0)
		_text(Vector2(x - 40.0, plot.end.y + 26.0), "%d" % km, 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER, 80.0)
	_text(Vector2(plot.position.x, plot.end.y + 54.0), "Height above the Moon at closest approach, km  (target: %d km)" % roundi(TARGET_KM), 16, MUTED, HORIZONTAL_ALIGNMENT_CENTER, plot.size.x)


func _num(value: float) -> String:
	return ("%.1f" % value).trim_suffix(".0")
