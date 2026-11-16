class_name StagingGame
extends Control

signal finished(errors: Array)

const FONT := preload("res://assets/fonts/IBMPlexSans-Regular.woff2")
const FONT_BOLD := preload("res://assets/fonts/IBMPlexSans-SemiBold.woff2")
const FONT_MONO := preload("res://assets/fonts/IBMPlexMono-Regular.woff2")
const NAVY := Color("061f4a")
const RED := Color("dd361c")
const RED_DARK := Color("c62d1f")
const SILVER := Color("aeb0b5")
const WHITE := Color("ffffff")
const BURN := 6.5
const LATE_LIMIT := 1.5

var _view: FlightView
var _names: Array = ["first stage", "second stage"]
var _speeds: Array = [0.0, 0.0, 0.0]
var _fail := ""
var _stage := 0
var _clock := 0.0
var _errors: Array = []
var _over := false
var _note := ""
var _note_good := true
var _note_left := 0.0
var _button: Button


func start(view: FlightView, names: Array, speeds: Array, fail: String) -> void:
	_view = view
	_names = names
	_speeds = speeds
	_fail = fail
	_view.view = "ascent"
	_view.mode = ""
	_view.jump(0.0)
	_view.burning = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_button = Button.new()
	_button.text = "DROP THE STAGE"
	_button.position = Vector2(700.0, 96.0)
	_button.size = Vector2(296.0, 96.0)
	_button.focus_mode = Control.FOCUS_NONE
	_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_button.add_theme_font_override("font", FONT_BOLD)
	_button.add_theme_font_size_override("font_size", 26)
	var normal := StyleBoxFlat.new()
	normal.bg_color = RED
	normal.set_corner_radius_all(3)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = RED_DARK
	for state: String in ["normal", "focus"]:
		_button.add_theme_stylebox_override(state, normal)
	_button.add_theme_stylebox_override("hover", hover)
	_button.add_theme_stylebox_override("pressed", hover)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_button.add_theme_color_override(state, WHITE)
	_button.pressed.connect(press)
	add_child(_button)


func _input(event: InputEvent) -> void:
	if _over:
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		press()


func press() -> void:
	if _over or _stage >= 2 or _clock < BURN * 0.25:
		return
	_separate(_clock - BURN)


func _process(delta: float) -> void:
	if _over or _view == null:
		return
	_clock += delta
	_note_left = maxf(_note_left - delta, 0.0)
	var part := _clock / BURN
	_view.jump(minf(0.45 * _stage + 0.45 * minf(part, 1.0), 0.9))
	if (_fail == "stage1" and _stage == 0 and part >= 0.45) or (_fail == "stage2" and _stage == 1 and part >= 0.4):
		_view.burning = _fail == "stage1"
		_end()
		return
	if part >= 1.0:
		_view.burning = false
		if _clock >= BURN + LATE_LIMIT:
			_separate(LATE_LIMIT)
	queue_redraw()


func _separate(error: float) -> void:
	_errors.append(error)
	var gain := Flight.staging_gain(error)
	var when := "Right on time" if absf(error) <= 0.15 else ("%.1f s late" % error if error > 0.0 else "%.1f s early" % -error)
	_note = "%s  ·  %s%d m/s" % [when, "+" if gain >= 0.0 else "−", roundi(absf(gain) * 1000.0)]
	_note_good = gain >= 0.0
	_note_left = 2.0
	_view.drop_stage(_stage + 1)
	_view.burning = true
	_stage += 1
	_clock = 0.0
	if _stage >= 2:
		_over = true
		_button.disabled = true
		queue_redraw()
		await get_tree().create_timer(1.4).timeout
		_view.jump(1.0)
		finished.emit(_errors)


func _end() -> void:
	_over = true
	_button.disabled = true
	finished.emit(_errors)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), NAVY)
	draw_rect(Rect2(0.0, 0.0, size.x, 4.0), RED)
	var stage := mini(_stage, 1)
	var part := clampf(_clock / BURN, 0.0, 1.0) if not _over else 1.0
	var left := 24.0
	draw_string(FONT_BOLD, Vector2(left, 40.0), "YOU ARE DROPPING THE STAGES", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, WHITE)
	draw_rect(Rect2(left, 50.0, 56.0, 4.0), RED)
	draw_string(FONT_BOLD, Vector2(left, 96.0), "%s  ·  PROPELLANT LEFT" % str(_names[stage]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, WHITE)
	var bar := Rect2(left, 112.0, 620.0, 34.0)
	draw_rect(bar, Color(1, 1, 1, 0.16))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * (1.0 - part), bar.size.y)), WHITE)
	draw_rect(Rect2(bar.position.x - 3.0, bar.position.y - 8.0, 6.0, bar.size.y + 16.0), RED)
	draw_string(FONT_MONO, Vector2(left, 172.0), "EMPTY: DROP IT HERE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, SILVER)
	draw_string(FONT_MONO, Vector2(left + bar.size.x - 36.0, 172.0), "FULL", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, SILVER)
	var speed := 0.0
	for index in _stage:
		speed += float(_speeds[index])
	if not _over:
		speed += float(_speeds[stage]) * part
	draw_string(FONT_MONO, Vector2(left, 218.0), "SPEED BUILT UP SO FAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, SILVER)
	draw_string(FONT_MONO, Vector2(left, 254.0), "%.2f km/s" % speed, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, WHITE)
	draw_string(FONT_MONO, Vector2(left + 220.0, 240.0), "this stage adds %.2f km/s" % float(_speeds[stage]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, SILVER)
	draw_string(FONT_MONO, Vector2(left + 220.0, 258.0), "reaching orbit takes about 9.2 km/s", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, SILVER)
	draw_multiline_string(FONT, Vector2(left, 296.0), "Drop the stage the moment its tanks run dry: press SPACE or the red button. Too early throws propellant away. Too late carries an empty tank as dead weight. The flight computer would drop it a little early, to be safe.", HORIZONTAL_ALIGNMENT_LEFT, 960.0, 15, 2, SILVER)
	draw_string(FONT_MONO, Vector2(700.0, 84.0), "SPACE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, SILVER)
	if _note_left > 0.0:
		draw_string(FONT_BOLD, Vector2(700.0, 232.0), _note, HORIZONTAL_ALIGNMENT_LEFT, 300.0, 21, WHITE if _note_good else Color("f9e0de"))
