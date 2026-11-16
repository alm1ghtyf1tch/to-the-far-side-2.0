extends Control

signal finished(hits: int, total: int)

const LANES: Array[String] = ["TRAJECTORY", "MASS", "FUEL", "LAUNCH WINDOW"]
const LANE_HINTS: Array[String] = ["Where will the ship be?", "How heavy is it?", "How much propellant?", "When can we go?"]
const KEY_NAMES: Array[String] = ["D", "F", "J", "K"]
const KEYS: Array[Key] = [KEY_D, KEY_F, KEY_J, KEY_K]
const ARROWS: Array[Key] = [KEY_LEFT, KEY_DOWN, KEY_UP, KEY_RIGHT]
const LANE_COLORS: Array[Color] = [Color("02bfe7"), Color("ffffff"), Color("e59892"), Color("105bd8")]

const DURATION := 36.0
const FALL_TIME := 1.8
const HIT_WINDOW := 0.18

const FONT := preload("res://assets/fonts/IBMPlexSans-Regular.woff2")
const FONT_BOLD := preload("res://assets/fonts/IBMPlexSans-SemiBold.woff2")
const FONT_TITLE := preload("res://assets/fonts/Saira-Display.ttf")
const FONT_MONO := preload("res://assets/fonts/IBMPlexMono-SemiBold.woff2")

enum { PENDING, HIT, MISSED }

var hits := 0
var misses := 0

var _notes: Array[Dictionary] = []
var _time := 0.0
var _running := false
var _done := false
var _flash: Array[float] = [0.0, 0.0, 0.0, 0.0]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_notes()


func is_running() -> bool:
	return _running


func is_done() -> bool:
	return _done


func total() -> int:
	return _notes.size()


func progress() -> float:
	return clampf(_time / DURATION, 0.0, 1.0)


func start() -> void:
	if _running or _done:
		return
	_running = true
	queue_redraw()


func skip(hit_rate: float) -> void:
	if _done:
		return
	hits = roundi(total() * hit_rate)
	_finish()


func _process(delta: float) -> void:
	for lane in _flash.size():
		_flash[lane] = maxf(_flash[lane] - delta * 4.0, 0.0)
	if _running:
		_time += delta
		for note in _notes:
			if note.state == PENDING and _time > note.time + HIT_WINDOW:
				note.state = MISSED
				misses += 1
		if _time >= DURATION + 0.6:
			_finish()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var lane := KEYS.find(key.physical_keycode)
	if lane == -1:
		lane = ARROWS.find(key.physical_keycode)
	if lane != -1 and _running:
		get_viewport().set_input_as_handled()
		_press_lane(lane)


func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT and _running:
		var field := _field()
		if field.has_point(mouse.position):
			_press_lane(clampi(int((mouse.position.x - field.position.x) / (field.size.x / LANES.size())), 0, LANES.size() - 1))


func _press_lane(lane: int) -> void:
	_flash[lane] = 0.35
	for note in _notes:
		if note.state == PENDING and note.lane == lane and absf(note.time - _time) <= HIT_WINDOW:
			note.state = HIT
			hits += 1
			_flash[lane] = 1.0
			return


func _finish() -> void:
	_running = false
	_done = true
	queue_redraw()
	finished.emit(hits, total())


func _build_notes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1969
	var time := 2.2
	var lane := -1
	while time < DURATION - 1.0:
		var next := rng.randi_range(0, LANES.size() - 1)
		if next == lane:
			next = (next + 1) % LANES.size()
		lane = next
		_notes.append({"time": time, "lane": lane, "state": PENDING})
		time += rng.randf_range(0.55, 1.1)


func _field() -> Rect2:
	var width := minf(size.x * 0.6, 900.0)
	return Rect2((size.x - width) * 0.5, 92.0, width, size.y - 92.0 - 96.0)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("212121"))
	var field := _field()
	var lane_width := field.size.x / LANES.size()
	var hit_y := field.end.y
	for lane in LANES.size():
		var x := field.position.x + lane * lane_width
		var color := LANE_COLORS[lane]
		draw_rect(Rect2(x, field.position.y, lane_width, field.size.y), Color(color, 0.05 + 0.12 * _flash[lane]))
		draw_line(Vector2(x, field.position.y), Vector2(x, hit_y + 60.0), Color(1, 1, 1, 0.08), 1.0)
		draw_string(FONT_BOLD, Vector2(x, 44.0), LANES[lane], HORIZONTAL_ALIGNMENT_CENTER, lane_width, 18, color)
		draw_string(FONT, Vector2(x, 70.0), LANE_HINTS[lane], HORIZONTAL_ALIGNMENT_CENTER, lane_width, 15, Color(1, 1, 1, 0.45))
		var cap := Rect2(x + lane_width * 0.5 - 26.0, hit_y + 18.0, 52.0, 44.0)
		draw_rect(cap, Color(color, 0.18 + 0.5 * _flash[lane]))
		draw_rect(cap, Color(color, 0.8), false, 2.0)
		draw_string(FONT_MONO, Vector2(cap.position.x, cap.position.y + 31.0), KEY_NAMES[lane], HORIZONTAL_ALIGNMENT_CENTER, cap.size.x, 24, Color.WHITE)
	draw_line(Vector2(field.end.x, field.position.y), Vector2(field.end.x, hit_y + 60.0), Color(1, 1, 1, 0.08), 1.0)
	draw_rect(Rect2(field.position.x, hit_y - 3.0, field.size.x, 6.0), Color(1, 1, 1, 0.85))
	if _running or _done:
		for note in _notes:
			var ahead: float = note.time - _time
			if ahead > FALL_TIME or note.state == HIT:
				continue
			var y := lerpf(field.position.y, hit_y, 1.0 - ahead / FALL_TIME)
			if y > size.y:
				continue
			var x: float = field.position.x + note.lane * lane_width
			var color: Color = LANE_COLORS[note.lane]
			if note.state == MISSED:
				color = Color(0.9, 0.3, 0.3, 0.45)
			draw_rect(Rect2(x + 16.0, y - 14.0, lane_width - 32.0, 28.0), color)
	var left := field.position.x - 300.0
	draw_string(FONT, Vector2(left, field.position.y + 30.0), "RUNS VERIFIED", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.5))
	draw_string(FONT_TITLE, Vector2(left, field.position.y + 84.0), "%d / %d" % [hits, total()], HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color.WHITE)
	draw_string(FONT, Vector2(left, field.position.y + 130.0), "MISSED", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.5))
	draw_string(FONT_TITLE, Vector2(left, field.position.y + 168.0), "%d" % misses, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("e59892"))
	var right := field.end.x + 60.0
	draw_string(FONT, Vector2(right, field.position.y + 30.0), "CALCULATIONS", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.5))
	draw_string(FONT_TITLE, Vector2(right, field.position.y + 84.0), "%d%%" % roundi(progress() * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color.WHITE)
	draw_rect(Rect2(right, field.position.y + 104.0, 220.0, 8.0), Color(1, 1, 1, 0.12))
	draw_rect(Rect2(right, field.position.y + 104.0, 220.0 * progress(), 8.0), Color("02bfe7"))
	if not _running and not _done:
		var box := Rect2(field.position.x + 40.0, field.position.y + 70.0, field.size.x - 80.0, 300.0)
		draw_rect(box, Color(0.04, 0.07, 0.12, 0.96))
		draw_rect(box, Color(0.44, 0.69, 1.0, 0.6), false, 2.0)
		var lines := [
			[FONT_TITLE, 30, Color.WHITE, "Check the numbers"],
			[FONT, 21, Color(0.8, 0.86, 0.94), "Each falling block is one calculation run by the Flight Dynamics team."],
			[FONT, 21, Color(0.8, 0.86, 0.94), "Confirm a run when it reaches the white line."],
			[FONT_BOLD, 21, Color("02bfe7"), "Keys D  F  J  K  —  or click the lane."],
		]
		var y := box.position.y + 62.0
		for line: Array in lines:
			draw_string(line[0], Vector2(box.position.x, y), line[3], HORIZONTAL_ALIGNMENT_CENTER, box.size.x, line[1], line[2])
			y += 46.0 if line[1] > 25 else 36.0
	elif _done:
		draw_string(FONT_TITLE, Vector2(field.position.x, field.position.y + field.size.y * 0.45), "Round complete", HORIZONTAL_ALIGNMENT_CENTER, field.size.x, 34, Color.WHITE)
