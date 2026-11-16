class_name LandingGame
extends Control

signal finished(outcome: Dictionary)

const FONT := preload("res://assets/fonts/IBMPlexSans-Regular.woff2")
const FONT_BOLD := preload("res://assets/fonts/IBMPlexSans-SemiBold.woff2")
const FONT_MONO := preload("res://assets/fonts/IBMPlexMono-Regular.woff2")
const ART := "res://assets/textures/flight/"
const CATALOG := "res://assets/textures/catalog/"
const NAVY := Color("061f4a")
const RED := Color("dd361c")
const RED_DARK := Color("c62d1f")
const SILVER := Color("aeb0b5")
const WHITE := Color("ffffff")
const GRAVITY := 1.62
const THRUST := 3.5
const SIDE := 1.8
const SOFT := 2.5
const HARD := 4.5
const WORLD := 250.0
const GROUND := 474.0
const UP := 2.5

var _setup := {}
var _site := "site_a11"
var _lander := "lander_standard"
var _height := 150.0
var _fall := -9.0
var _x := 0.0
var _slide := 0.0
var _fuel := 19.0
var _clear: Array = []
var _rocks: Array = []
var _over := false
var _started := false
var _outcome := {}
var _time := 0.0
var _alarm_left := 0.0
var _alarm_done := false
var _engine := false
var _push := 0.0
var _hold_engine := false
var _hold_side := 0.0
var _textures := {}


func start(setup: Dictionary, site_id: String) -> void:
	_setup = setup
	_site = "site_%s" % site_id
	var lander := str(setup.get("lander", "lander_standard"))
	_lander = lander if lander in ["lander_standard", "lander_extended", "lander_light", "lander_hls"] else "lander_standard"
	var training := int(setup.get("training", 1))
	_fuel = float({"lander_standard": 19.0, "lander_extended": 18.0, "lander_light": 17.0, "lander_hls": 22.0}.get(_lander, 19.0)) + 2.5 * training
	var rng := RandomNumberGenerator.new()
	rng.seed = int(setup.get("seed", 1))
	var widths: Array = {1: [62.0, 56.0, 60.0], 2: [42.0, 38.0, 44.0], 3: [30.0, 26.0, 28.0]}.get(int(setup.get("risk", 1)), [42.0, 38.0, 44.0])
	var centres: Array = [-82.0 + rng.randf_range(-8.0, 8.0), rng.randf_range(-10.0, 10.0), 82.0 + rng.randf_range(-8.0, 8.0)]
	_clear.clear()
	for index in 3:
		_clear.append(Vector2(float(centres[index]) - float(widths[index]) * 0.5, float(centres[index]) + float(widths[index]) * 0.5))
	var miss := (1.0 - clampf(float(setup.get("accuracy", 1.0)), 0.0, 1.0)) * 70.0
	_x = clampf(float(centres[1]) + (1.0 if rng.randf() < 0.5 else -1.0) * miss, -WORLD * 0.42, WORLD * 0.42)
	_rocks.clear()
	var at := -WORLD * 0.5
	while at < WORLD * 0.5:
		if not _is_clear(at, 0.0):
			_rocks.append([at + rng.randf_range(-1.5, 1.5), rng.randf_range(1.6, 4.2), rng.randf_range(0.0, 1.0)])
		at += rng.randf_range(4.0, 7.5)
	_started = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_add_hold("◄", Rect2(724.0, 536.0, 62.0, 50.0), func(down: bool) -> void: _hold_side = -1.0 if down else 0.0)
	_add_hold("ENGINE", Rect2(794.0, 536.0, 134.0, 50.0), func(down: bool) -> void: _hold_engine = down)
	_add_hold("►", Rect2(936.0, 536.0, 62.0, 50.0), func(down: bool) -> void: _hold_side = 1.0 if down else 0.0)


func _add_hold(text: String, rect: Rect2, change: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", FONT_BOLD)
	button.add_theme_font_size_override("font_size", 19)
	var normal := StyleBoxFlat.new()
	normal.bg_color = RED
	normal.set_corner_radius_all(3)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = RED_DARK
	for state: String in ["normal", "focus", "hover"]:
		button.add_theme_stylebox_override(state, normal)
	button.add_theme_stylebox_override("pressed", pressed)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, WHITE)
	button.button_down.connect(change.bind(true))
	button.button_up.connect(change.bind(false))
	add_child(button)


func steer(engine: bool, push: float) -> void:
	_hold_engine = engine
	_hold_side = push


func _is_clear(x: float, half: float) -> bool:
	for zone: Vector2 in _clear:
		if x - half >= zone.x and x + half <= zone.y:
			return true
	return false


func _process(delta: float) -> void:
	_time += delta
	if not _started or _over:
		queue_redraw()
		return
	var step := minf(delta, 0.05)
	_engine = (_hold_engine or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)) and _fuel > 0.0
	_push = _hold_side
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		_push = -1.0
	elif Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		_push = 1.0
	if _fuel <= 0.0:
		_push = 0.0
	_fuel = maxf(_fuel - (step if _engine else 0.0) - absf(_push) * step * 0.35, 0.0)
	_fall += ((THRUST if _engine else 0.0) - GRAVITY) * step
	_slide += _push * SIDE * step
	_height += _fall * step
	_x = clampf(_x + _slide * step, -WORLD * 0.47, WORLD * 0.47)
	_alarm_left = maxf(_alarm_left - step, 0.0)
	if not _alarm_done and _height < 95.0:
		_alarm_done = true
		_alarm_left = [2.6, 1.0, 0.0][clampi(int(_setup.get("computer", 1)), 0, 2)]
	if _height <= 0.0:
		_height = 0.0
		var speed := absf(_fall)
		var good_ground := _is_clear(_x, 4.0)
		var soft := speed <= SOFT and absf(_slide) <= 1.5 and good_ground
		_finish("landed" if soft else "hard", speed)
		return
	var net := THRUST - GRAVITY
	var cannot_stop := _fall < -sqrt(2.0 * net * _height + HARD * HARD)
	var rough := _height < 6.0 and _fall < 0.0 and not _is_clear(_x, 4.0)
	var dry := _fuel <= 0.0 and sqrt(_fall * _fall + 2.0 * GRAVITY * _height) > HARD
	if cannot_stop or rough or dry or _height > 260.0:
		_finish("abort", absf(_fall))
	queue_redraw()


func _finish(result: String, speed: float) -> void:
	_over = true
	_engine = false
	_outcome = {"result": result, "speed": speed, "fuel": _fuel}
	queue_redraw()
	await get_tree().create_timer(1.8).timeout
	finished.emit(_outcome)


func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	return _textures[path]


func _screen_x(x: float) -> float:
	return size.x * 0.5 + x * size.x / WORLD


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
	var picture := _texture(CATALOG + _site + ".png")
	if picture:
		var scale_up := size.y / picture.get_height()
		var width := picture.get_width() * scale_up
		draw_texture_rect(picture, Rect2((size.x - width) * 0.5, 0.0, width, size.y), false)
	var training := int(_setup.get("training", 1))
	for rock: Array in _rocks:
		var at := Vector2(_screen_x(float(rock[0])), GROUND + 6.0 + float(rock[2]) * 26.0)
		var r := float(rock[1]) * 3.4
		draw_colored_polygon(PackedVector2Array([at + Vector2(-r, 0.0), at + Vector2(-r * 0.6, -r * 1.1), at + Vector2(r * 0.3, -r * 1.3), at + Vector2(r, -r * 0.4), at + Vector2(r * 0.9, 0.0)]), Color("7d7b76"))
		draw_colored_polygon(PackedVector2Array([at + Vector2(r * 0.3, -r * 1.3), at + Vector2(r, -r * 0.4), at + Vector2(r * 0.9, 0.0), at + Vector2(r * 0.2, 0.0)]), Color("4a4946"))
		draw_set_transform(at + Vector2(r * 1.4, 1.0), 0.0, Vector2(1.0, 0.25))
		draw_circle(Vector2.ZERO, r * 1.2, Color(0, 0, 0, 0.5))
		draw_set_transform(Vector2.ZERO)
	if training >= 1:
		for zone: Vector2 in _clear:
			var a := _screen_x(zone.x)
			var b := _screen_x(zone.y)
			draw_line(Vector2(a, GROUND + 46.0), Vector2(b, GROUND + 46.0), WHITE, 2.0)
			draw_line(Vector2(a, GROUND + 34.0), Vector2(a, GROUND + 46.0), WHITE, 2.0)
			draw_line(Vector2(b, GROUND + 34.0), Vector2(b, GROUND + 46.0), WHITE, 2.0)
			draw_string(FONT_MONO, Vector2(a, GROUND + 41.0), "CLEAR GROUND", HORIZONTAL_ALIGNMENT_CENTER, b - a, 12, WHITE)
	var lander := _texture(ART + _lander + ".png")
	var feet := Vector2(_screen_x(_x), GROUND + 14.0 - _height * UP)
	var box := Vector2(84.0, 76.0)
	if lander:
		box = lander.get_size() * (0.2 if _lander != "lander_hls" else 0.24)
	var near := clampf(1.0 - _height / 90.0, 0.0, 1.0)
	draw_set_transform(Vector2(feet.x + box.x * 0.3, GROUND + 16.0), 0.0, Vector2(1.0, 0.18))
	draw_circle(Vector2.ZERO, box.x * 0.6, Color(0, 0, 0, 0.55 * near))
	draw_set_transform(Vector2.ZERO)
	if training >= 1 and not _over:
		draw_dashed_line(feet, Vector2(feet.x, GROUND + 14.0), Color(1, 1, 1, 0.45), 1.0, 6.0)
	if _engine:
		var flicker := 0.8 + 0.2 * sin(_time * 33.0)
		var nozzle := feet + Vector2(0.0, -box.y * 0.14)
		draw_colored_polygon(PackedVector2Array([nozzle + Vector2(-5.0, 0.0), nozzle + Vector2(5.0, 0.0), nozzle + Vector2(11.0, 34.0 * flicker), nozzle + Vector2(-11.0, 34.0 * flicker)]), Color(1.0, 0.97, 0.9, 0.7))
		if _height < 25.0:
			for index in 6:
				var side := -1.0 if index % 2 == 0 else 1.0
				draw_circle(Vector2(feet.x + side * (24.0 + index * 16.0 + fposmod(_time * 50.0, 16.0)), GROUND + 8.0), 10.0 + index * 2.0, Color(0.8, 0.79, 0.76, 0.25))
	if _push != 0.0:
		var side_at := feet + Vector2(-_push * box.x * 0.5, -box.y * 0.55)
		draw_colored_polygon(PackedVector2Array([side_at, side_at + Vector2(-_push * 22.0, -4.0), side_at + Vector2(-_push * 22.0, 4.0)]), Color(1, 1, 1, 0.7))
	if lander:
		draw_texture_rect(lander, Rect2(feet.x - box.x * 0.5, feet.y - box.y, box.x, box.y), false)

	var panel := Rect2(16.0, 60.0, 250.0, 236.0 if training >= 2 else 196.0)
	draw_rect(panel, Color(NAVY, 0.92))
	draw_rect(Rect2(panel.position, Vector2(5.0, panel.size.y)), RED)
	var blank := _alarm_left > 0.0
	var left := panel.position.x + 20.0
	_draw_number(Vector2(left, panel.position.y + 24.0), "ALTITUDE", "---" if blank else "%d m" % roundi(_height))
	var down := maxf(-_fall, 0.0)
	_draw_number(Vector2(left, panel.position.y + 80.0), "DESCENT RATE  ·  LAND BELOW 2.5", "---" if blank else "%.1f m/s" % down)
	draw_string(FONT_MONO, Vector2(left, panel.position.y + 136.0), "FUEL  ·  %d s" % roundi(_fuel) if not blank else "FUEL", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, SILVER)
	var bar := Rect2(left, panel.position.y + 146.0, 210.0, 14.0)
	draw_rect(bar, Color(1, 1, 1, 0.16))
	if not blank:
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(_fuel / 28.0, 0.0, 1.0), bar.size.y)), WHITE)
	draw_string(FONT_MONO, Vector2(left, panel.position.y + 182.0), "SIDEWAYS  %s" % ("---" if blank else "%.1f m/s" % absf(_slide)), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, SILVER)
	if training >= 2:
		var needed := maxf((down * down - 4.0) / (2.0 * (THRUST - GRAVITY)), 0.0)
		draw_string(FONT_MONO, Vector2(left, panel.position.y + 208.0), "HEIGHT NEEDED TO STOP", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, SILVER)
		draw_string(FONT_MONO, Vector2(left, panel.position.y + 228.0), "---" if blank else "%d m" % roundi(needed), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, WHITE)
	if blank:
		draw_rect(Rect2(panel.position.x, panel.end.y + 6.0, panel.size.x, 34.0), RED)
		draw_string(FONT_BOLD, Vector2(left, panel.end.y + 29.0), "COMPUTER ALARM", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, WHITE)

	draw_rect(Rect2(0.0, 526.0, size.x, 74.0), Color(NAVY, 0.92))
	draw_rect(Rect2(0.0, 526.0, size.x, 4.0), RED)
	draw_multiline_string(FONT, Vector2(24.0, 554.0), "Hold SPACE to fire the engine, A and D to slide sideways (or use the buttons). Touch down on clear ground slower than 2.5 m/s before the fuel runs out. If the descent goes wrong, the computer aborts and the crew returns to orbit.", HORIZONTAL_ALIGNMENT_LEFT, 680.0, 14, 3, SILVER)

	if _over:
		var title: String = {"landed": "TOUCHDOWN", "hard": "HARD LANDING", "abort": "ABORT"}.get(str(_outcome.get("result", "")), "")
		var detail := "%.1f m/s  ·  %d s of fuel left" % [float(_outcome.get("speed", 0.0)), roundi(float(_outcome.get("fuel", 0.0)))]
		if _outcome.get("result") == "abort":
			detail = "The ascent engine is taking the crew back to orbit."
		var card := Rect2(size.x * 0.5 - 250.0, 190.0, 500.0, 104.0)
		draw_rect(card, WHITE)
		draw_rect(Rect2(card.position, Vector2(10.0, card.size.y)), RED)
		draw_string(FONT_BOLD, card.position + Vector2(30.0, 46.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, NAVY)
		draw_string(FONT, card.position + Vector2(30.0, 80.0), detail, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("323a45"))


func _draw_number(at: Vector2, caption: String, value: String) -> void:
	draw_string(FONT_MONO, at, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, SILVER)
	draw_string(FONT_MONO, at + Vector2(0.0, 30.0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, WHITE)
