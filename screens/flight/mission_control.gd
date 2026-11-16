extends Control

const FONT := preload("res://assets/fonts/IBMPlexSans-Regular.woff2")
const FONT_BOLD := preload("res://assets/fonts/IBMPlexSans-SemiBold.woff2")
const FONT_TITLE := preload("res://assets/fonts/Saira-Display.ttf")
const FONT_MONO := preload("res://assets/fonts/IBMPlexMono-Regular.woff2")
const NAVY := Color("061f4a")
const BLUE := Color("0b3d91")
const BRIGHT_BLUE := Color("105bd8")
const RED := Color("dd361c")
const GOLD := Color("f2b632")
const RED_DARK := Color("c62d1f")
const INK := Color("212121")
const GRAY := Color("323a45")
const SILVER := Color("aeb0b5")
const PAPER := Color("e1f3f8")
const WHITE := Color("ffffff")
const PLAN := [
	["countdown", "Countdown"], ["ascent", "Ascent"], ["orbit", "Earth orbit"], ["tli", "Burn for the Moon"],
	["coast", "Coast to the Moon"], ["loi", "Lunar orbit"], ["landing", "Landing"], ["surface", "On the Moon"],
	["return", "Coast home"], ["entry", "Re-entry and splashdown"],
]
const INTRO_TIME := 2.2
const READ_TIME := 1.8
const READ_PER_LETTER := 0.045
const ASCENT_INTRO := 4.6
const GOLD_BRIGHT := Color("ffcf5c")
const PHASE_INFO := {
	"countdown": "The last hours on the pad. The tanks are filled with propellant colder than −180 °C and hundreds of readings are checked. Any one of them can stop the clock.",
	"ascent": "About ten minutes from the pad to orbit. The rocket has to reach 7.8 km/s sideways, 185 km up. Each empty stage is dropped so the next one does not have to carry it.",
	"orbit": "A parking orbit 185 km above the Earth, one lap every 88 minutes. The crew checks the ship before committing to the Moon.",
	"tli": "One burn of the upper stage raises the speed from 7.8 to about 10.9 km/s. After it the ship coasts: no engine for almost three days.",
	"coast": "384,400 km in under three days. Earth's pull slows the ship from 10.9 km/s to about 1 km/s, then the Moon's pull takes over.",
	"loi": "Behind the Moon, out of radio contact, the engine slows the ship by about 0.9 km/s. Without this burn the ship would swing round the Moon and fall back to Earth.",
	"landing": "From orbit to the surface in about twelve minutes. The last 150 metres are flown looking out of the window for clear ground.",
	"surface": "Moonwalks, instruments and samples. Everything the mission came for happens here.",
	"return": "One more burn behind the Moon, about 1 km/s, and a coast of two and a half days. Earth's pull speeds the ship up all the way home.",
	"entry": "The capsule meets the air at 11 km/s, close to 40,000 km/h. Its heat shield takes about 2,700 °C. Then parachutes, and the sea.",
}

@onready var _frame: Control = %Frame

var _result := {}
var _phases: Array = []
var _phase_index := 0
var _line_index := -1
var _instant := false
var _finished := false
var _timer: Timer
var _scene_tween: Tween
var _view: FlightView
var _rows := {}
var _row_titles := {}
var _row_marks := {}
var _caption: Label
var _day_label: Label
var _log_box: VBoxContainer
var _log_scroll: ScrollContainer
var _values := {}
var _gauges := {}
var _goal_marks: Array[Label] = []
var _goal_labels: Array[Label] = []
var _banner: PanelContainer
var _banner_label: Label
var _next_button: Button
var _skip_button: Button
var _report_button: Button
var _info_label: Label
var _info_default := ""
var _overrides := {}
var _gate := ""
var _gate_box: PanelContainer
var _gate_title: Label
var _gate_text: Label
var _gate_yes: Button
var _gate_no: Button
var _game: Control = null
var _launched := false
var _manual_ascent := false
var _ascent_flown := false
var _landing_chosen := false
var _landing_flown := false
var _paused := false
var _pace_state := ""
var _pace_box: VBoxContainer
var _pause_button: Button
var _pause_icon: PaceIcon
var _pause_key: Label
var _pace_note: Label
var _pace_track: ColorRect
var _pace_fill: ColorRect
var _veil: Control


func _ready() -> void:
	if Campaign.stage < 10 or (Campaign.stage > 10 and Flight.result.is_empty()):
		Flight.quick_start(10)
	if Campaign.stage == 10:
		Flight.fly()
	Campaign.clock_running = false
	_result = Flight.result
	_phases = _result.get("phases", [])
	var back := ColorRect.new()
	back.color = INK
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(back)
	_build_top_bar()
	_build_plan()
	_build_view()
	_build_log()
	_build_status()
	_build_veil()
	_build_gate()
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_step)
	add_child(_timer)
	_open_gate.call_deferred("start")


func _process(_delta: float) -> void:
	var state := "auto"
	if _finished:
		state = "over"
	elif _paused:
		state = "paused"
	elif _gate != "":
		state = "gate"
	elif _game != null:
		state = "game"
	if state != _pace_state:
		_pace_state = state
		_show_pace()
	var part := 0.0
	if state in ["auto", "paused"] and not _timer.is_stopped() and _timer.wait_time > 0.0:
		part = clampf(1.0 - _timer.time_left / _timer.wait_time, 0.0, 1.0)
	_pace_fill.size = Vector2(_pace_track.size.x * part, _pace_track.size.y)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_timer.stop()
		SceneRouter.go_to(SceneRouter.HQ)
	elif _is_pause_key(event):
		get_viewport().set_input_as_handled()
		toggle_pause()
	elif event.is_action_pressed("ui_accept") and not _finished:
		get_viewport().set_input_as_handled()
		next_line()


func _is_pause_key(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return false
	return key.keycode == KEY_P or (key.keycode == KEY_SPACE and _game == null)


func toggle_pause() -> void:
	if _finished or _instant or _gate != "":
		return
	set_paused(not _paused)


func set_paused(paused: bool) -> void:
	if paused == _paused:
		return
	_paused = paused
	var mode: Node.ProcessMode = Node.PROCESS_MODE_DISABLED if paused else Node.PROCESS_MODE_INHERIT
	_timer.process_mode = mode
	_view.process_mode = mode
	if _game != null:
		_game.process_mode = mode


func next_line() -> void:
	if _finished or _instant or _gate != "" or _game != null:
		return
	set_paused(false)
	_timer.stop()
	_step()


func skip_to_end() -> void:
	if _finished:
		return
	set_paused(false)
	_instant = true
	_timer.stop()
	if _scene_tween:
		_scene_tween.kill()
	if _game != null:
		_game.queue_free()
		_game = null
	_gate = ""
	_gate_box.visible = false
	_launched = true
	_landing_chosen = true
	while not _finished:
		_step()


func open_report() -> void:
	_report_button.disabled = true
	SceneRouter.go_to(SceneRouter.MISSION_REPORT, 0.6)


func _step() -> void:
	if _finished or _gate != "" or _game != null:
		return
	if _phase_index >= _phases.size():
		_finish()
		return
	var phase: Dictionary = _phases[_phase_index]
	var lines: Array = phase["lines"]
	var id := str(phase["id"])
	if _line_index < 0:
		if not _instant and id == "landing" and phase.get("manual", false) and not _landing_chosen:
			_mark_row(id, "current")
			_caption.text = "LANDING"
			_view.view = "surface"
			_view.mode = "descent"
			_view.jump(0.0)
			_open_gate("landing")
			return
		if not _instant and id == "ascent" and _manual_ascent and not _ascent_flown:
			_start_staging(phase)
			return
		_begin_phase(phase)
		_line_index = 0
		_wait(_intro_time(phase))
		return
	if _line_index < lines.size():
		if id == "countdown" and _line_index == int(phase.get("gate", -1)) and not _launched:
			if _instant:
				_launched = true
			else:
				_open_gate("launch")
				return
		var line: Dictionary = lines[_line_index]
		_add_line(phase, line)
		_on_line(phase, line, _line_index == lines.size() - 1)
		_line_index += 1
		_wait(READ_TIME + str(line["text"]).length() * READ_PER_LETTER)
		return
	_end_phase(phase)
	_phase_index += 1
	_line_index = -1
	_wait(0.6)


func _intro_time(phase: Dictionary) -> float:
	return ASCENT_INTRO if phase["id"] == "ascent" and not _ascent_flown else INTRO_TIME


func _refly() -> void:
	Flight.fly(_overrides)
	_result = Flight.result
	_phases = _result.get("phases", [])


func _open_gate(kind: String) -> void:
	_gate = kind
	_next_button.disabled = true
	_gate_no.visible = kind != "start"
	if kind == "start":
		_gate_title.text = "Mission Control is ready"
		_gate_text.text = "The flight plays on its own, one log entry at a time. Whenever you want more time to read, press P or the Pause button on the right. Nothing is lost while the flight is paused."
		_gate_yes.text = "Start the countdown"
	elif kind == "launch":
		_gate_title.text = "Ready to launch"
		_gate_text.text = "The count has reached zero. On the way up each empty stage has to be dropped. You can do that yourself, or leave it to the flight computer."
		_gate_yes.text = "Launch, I drop the stages"
		_gate_no.text = "Launch on autopilot"
	else:
		_info_label.text = str(PHASE_INFO["landing"])
		_gate_title.text = "150 metres above the Moon"
		_gate_text.text = "The computer has flown the lander this far. You can fly the last part yourself and pick the spot, or let the computer finish the landing."
		_gate_yes.text = "I fly the landing"
		_gate_no.text = "Let the computer land"
	_gate_box.visible = true
	_gate_box.modulate.a = 0.0
	create_tween().tween_property(_gate_box, "modulate:a", 1.0, 0.25)
	_gate_yes.grab_focus()


func choose(manual: bool) -> void:
	if _gate == "":
		return
	var kind := _gate
	_gate = ""
	_gate_box.visible = false
	_next_button.disabled = false
	if kind == "start":
		_wait(0.6)
	elif kind == "launch":
		_launched = true
		_manual_ascent = manual and str(_result.get("outcome", "")) != "no_launch"
		_step()
	elif manual:
		_landing_chosen = true
		_start_landing(_phases[_phase_index])
	else:
		_landing_chosen = true
		_step()


func _start_staging(phase: Dictionary) -> void:
	_mark_row("ascent", "current")
	_caption.text = "ASCENT"
	_day_label.text = "LAUNCH DAY"
	_next_button.disabled = true
	_info_label.text = str(PHASE_INFO["ascent"])
	var game := StagingGame.new()
	game.position = Vector2(378.0, 706.0)
	game.size = Vector2(1020.0, 350.0)
	_frame.add_child(game)
	_game = game
	game.start(_view, _result.get("stage_names", ["first stage", "second stage"]), Vehicle.stats.get("stage_dv", [0.0, 0.0, 0.0]), str(phase.get("fail", "")))
	game.finished.connect(_on_staging_finished)


func _on_staging_finished(errors: Array) -> void:
	if _game == null:
		return
	_game.queue_free()
	_game = null
	_next_button.disabled = false
	_ascent_flown = true
	if not errors.is_empty():
		_overrides["staging"] = errors
		_refly()
	_line_index = 0
	_wait(0.6)


func _start_landing(phase: Dictionary) -> void:
	_next_button.disabled = true
	var game := LandingGame.new()
	game.position = _view.position
	game.size = _view.size
	_frame.add_child(game)
	_game = game
	game.start(phase.get("setup", {}), str(Campaign.site.get("id", "a11")))
	game.finished.connect(_on_landing_finished)


func _on_landing_finished(outcome: Dictionary) -> void:
	if _game == null:
		return
	_game.queue_free()
	_game = null
	_next_button.disabled = false
	_landing_flown = true
	_overrides["landing"] = outcome
	_refly()
	_step()


func _wait(seconds: float) -> void:
	if not _instant:
		_timer.start(seconds)


func _phase_time(phase: Dictionary) -> float:
	var total := _intro_time(phase)
	for line: Dictionary in phase["lines"]:
		total += READ_TIME + str(line["text"]).length() * READ_PER_LETTER
	return total


func _begin_phase(phase: Dictionary) -> void:
	var id := str(phase["id"])
	_mark_row(id, "current")
	_caption.text = str(phase["title"]).to_upper()
	_info_label.text = str(PHASE_INFO.get(id, _info_default))
	var day := float(phase.get("day", 0.0))
	_day_label.text = "LAUNCH DAY" if day < 0.05 else "MISSION DAY %d" % (int(day) + 1)
	if phase.has("gauge"):
		var gauge: Dictionary = phase["gauge"]
		var key := "rocket" if id == "tli" else "ship"
		(_values[key] as Label).text = "%.2f km/s  ·  needs %.2f" % [gauge["have"], gauge["need"]]
		(_gauges[key] as GaugeBar).have = float(gauge["have"])
		(_gauges[key] as GaugeBar).need = float(gauge["need"])
	_set_scene(phase)


func _set_scene(phase: Dictionary) -> void:
	if _scene_tween:
		_scene_tween.kill()
	var id := str(phase["id"])
	var outcome := str(_result.get("outcome", ""))
	var problem := str(phase["status"]) == "problem"
	var time := _phase_time(phase)
	_view.burning = false
	match id:
		"countdown":
			_view.view = "pad"
			_view.mode = ""
			_view.reset_stack()
			_view.jump(0.0)
		"ascent":
			if _ascent_flown:
				return
			var fail := str(phase.get("fail", ""))
			_view.view = "ascent"
			_view.mode = ""
			_view.burning = true
			if _instant:
				if fail == "stage1":
					_view.mode = "fail"
					_view.settle_wreck()
					_view.jump(0.3)
				else:
					_view.drop_stage(1 if fail == "stage2" else 2, false)
					_view.burning = false
					_view.jump(1.0)
			else:
				_view.play(0.0, 0.3 if fail == "stage1" else 0.45, ASCENT_INTRO)
		"orbit":
			_view.view = "map"
			_view.mode = "earth_orbit"
			_play(0.0, 1.0, time, 1.0)
		"tli":
			_view.view = "map"
			if outcome == "earth_orbit":
				_view.mode = "earth_orbit"
				_play(0.0, 1.0, time, 1.0)
			else:
				_view.mode = "outbound"
				_play(0.0, 0.05, time, 0.05)
		"coast":
			_view.view = "map"
			_view.mode = "outbound"
			_play(0.05, 0.94, time, 0.94)
		"loi":
			_view.view = "map"
			_view.mode = "outbound"
			var after := "flyby" if outcome == "flyby" else "moon_orbit"
			var until := 0.06 if outcome == "flyby" else 1.0
			var approach := minf(time * 0.45, 6.0)
			if _instant:
				_view.mode = after
				_view.jump(until)
			else:
				_view.play(0.94, 1.0, approach)
				_scene_tween = _view.create_tween()
				_scene_tween.tween_interval(approach)
				_scene_tween.tween_callback(func() -> void:
					_view.mode = after
					_view.play(0.0, until, maxf(time - approach, 1.0)))
		"landing":
			if int(Vehicle.stats.get("surface_crew", 0)) <= 0:
				_view.view = "map"
				_view.mode = "moon_orbit"
				_play(0.0, 1.0, time, 1.0)
			elif _landing_flown:
				_view.view = "surface"
				_view.walkers = 0
				_view.mode = "landed" if outcome == "landed" else "abort"
				_view.jump(1.0)
			else:
				_view.view = "surface"
				_view.walkers = 0
				_view.mode = "abort" if outcome != "landed" else "descent"
				_play(0.0, 1.0, time * 0.8, 1.0)
		"surface":
			_view.view = "surface"
			_view.mode = "landed"
			_view.walkers = mini(int(_result.get("surface_crew", 0)), 2) if float(Vehicle.stats.get("eva_hours", 0.0)) > 0.0 else 0
			_view.jump(1.0)
		"return":
			_view.view = "map"
			if outcome == "flyby":
				_view.mode = "flyby"
				_play(0.06, 0.995, time, 0.995)
			else:
				_view.mode = "return"
				_play(0.0, 0.995, time, 0.995)
		"entry":
			_view.view = "sea"
			_view.mode = ""
			_play(0.0, 1.0, time * 0.85, 1.0)


func _play(from: float, to: float, seconds: float, end: float) -> void:
	if _instant:
		_view.jump(end)
	else:
		_view.play(from, to, seconds)


func _on_line(phase: Dictionary, line: Dictionary, last: bool) -> void:
	var id := str(phase["id"])
	var hint := str(line.get("view", ""))
	if hint == "sea":
		_view.view = "sea"
		_view.mode = ""
		_play(0.0, 1.0, 6.0, 1.0)
	elif hint == "drop1" and not _instant:
		_view.drop_stage(1)
		_view.play(_view.progress, 0.9, 5.0)
	elif hint == "drop2" and not _instant:
		_view.drop_stage(2)
		_view.play(_view.progress, 1.0, 3.2)
	elif id == "ascent" and str(line["kind"]) == "bad" and str(phase.get("fail", "")) == "stage1":
		_view.mode = "fail"
		if _instant:
			_view.settle_wreck()
	elif id == "ascent" and str(line["kind"]) == "bad":
		_view.burning = false
	elif id == "countdown" and last and str(_result.get("outcome", "")) == "no_launch" and not _instant:
		_view.burning = true
		_scene_tween = _view.create_tween()
		_scene_tween.tween_interval(2.4)
		_scene_tween.tween_callback(func() -> void: _view.burning = false)
	if id == "surface" and last:
		_show_science()


func _end_phase(phase: Dictionary) -> void:
	var id := str(phase["id"])
	_mark_row(id, "problem" if str(phase["status"]) == "problem" else "done")
	if id == "countdown" and str(_result.get("outcome", "")) != "no_launch":
		_show_goal(2)
	if id == "landing":
		_show_goal(0)


func _finish() -> void:
	_finished = true
	for entry: Array in PLAN:
		if not _phase_flown(str(entry[0])):
			_mark_row(str(entry[0]), "skipped")
	for index in _goal_marks.size():
		_show_goal(index)
	_show_science()
	(_values["budget"] as Label).text = "%s%% of the mission budget" % _num(float(_result.get("budget_left", 0.0)))
	_caption.text = {"no_launch": "LAUNCH CANCELLED", "launch_abort": "FLIGHT ENDED", "crew_lost": "FLIGHT ENDED"}.get(str(_result.get("outcome", "")), "FLIGHT COMPLETE")
	_banner_label.text = str(_result.get("headline", ""))
	_banner.visible = true
	_banner.modulate.a = 0.0
	create_tween().tween_property(_banner, "modulate:a", 1.0, 0.0 if _instant else 0.5)
	_skip_button.visible = false
	_next_button.visible = false
	_pace_box.visible = false
	_veil.visible = false
	_report_button.disabled = false
	_report_button.grab_focus()


func _phase_flown(id: String) -> bool:
	for phase: Dictionary in _phases:
		if phase["id"] == id:
			return true
	return false


func _show_science() -> void:
	(_values["science"] as Label).text = "%d of %d planned points" % [int(_result.get("science_returned", 0)), int(_result.get("science_planned", 0))]


func _show_goal(index: int) -> void:
	var goal: Dictionary = (_result.get("objectives", []) as Array)[index]
	var mark := _goal_marks[index]
	mark.text = "✓" if goal["met"] else "✕"
	mark.add_theme_color_override("font_color", WHITE)
	var style := StyleBoxFlat.new()
	style.bg_color = BRIGHT_BLUE if goal["met"] else RED
	mark.add_theme_stylebox_override("normal", style)
	_goal_labels[index].add_theme_color_override("font_color", WHITE)


func _add_line(phase: Dictionary, line: Dictionary) -> void:
	var kind := str(line["kind"])
	for child in _log_box.get_children():
		((child as HBoxContainer).get_child(2) as Label).add_theme_color_override("font_color", SILVER)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var mark := ColorRect.new()
	mark.custom_minimum_size = Vector2(6.0, 0.0)
	mark.color = {"good": WHITE, "bad": RED, "info": GRAY}.get(kind, GRAY)
	row.add_child(mark)
	var day := float(phase.get("day", 0.0))
	var stamp := _label("LAUNCH" if day < 0.05 else "DAY %d" % (int(day) + 1), FONT_MONO, 15, SILVER)
	stamp.custom_minimum_size = Vector2(72.0, 0.0)
	row.add_child(stamp)
	var text := _label(str(line["text"]), FONT, 19, WHITE, true)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	_log_box.add_child(row)
	if not _instant:
		row.modulate.a = 0.0
		create_tween().tween_property(row, "modulate:a", 1.0, 0.3)


func _scroll_log() -> void:
	_log_scroll.scroll_vertical = int(_log_scroll.get_v_scroll_bar().max_value)


func _build_top_bar() -> void:
	var bar := PanelContainer.new()
	bar.position = Vector2.ZERO
	bar.size = Vector2(1920.0, 66.0)
	var style := StyleBoxFlat.new()
	style.bg_color = WHITE
	style.border_color = GOLD
	style.border_width_bottom = 4
	style.content_margin_left = 20.0
	style.content_margin_right = 24.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 12.0
	bar.add_theme_stylebox_override("panel", style)
	_frame.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	bar.add_child(row)
	var stage := PanelContainer.new()
	stage.custom_minimum_size = Vector2(46.0, 40.0)
	var stage_style := StyleBoxFlat.new()
	stage_style.bg_color = GOLD
	stage.add_theme_stylebox_override("panel", stage_style)
	var number := _label("10", FONT_TITLE, 20, NAVY)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stage.add_child(number)
	row.add_child(stage)
	var title := _label("Mission Control", FONT_TITLE, 26, NAVY)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(title)
	var launch_day := int(_result.get("launch_day", int(Campaign.days)))
	var note := _label("Launch: %s, %s   ·   Landing site: %s" % [Vehicle.launch_site().get("short", "—"), Campaign.date_text(launch_day).capitalize(), Campaign.site.get("name", "—")], FONT, 17, GRAY)
	note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(note)
	var hint := _label("The flight plays on its own. Press P or the Pause button to stop and read.", FONT_BOLD, 17, NAVY)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(hint)


func _build_plan() -> void:
	var panel := _panel(Rect2(24.0, 90.0, 330.0, 966.0), 18.0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	box.add_child(_label("FLIGHT PLAN", FONT_BOLD, 17, WHITE))
	box.add_child(_rule(GOLD, 56.0, 4.0))
	box.add_child(_spacer(6.0))
	for index in PLAN.size():
		var id := str(PLAN[index][0])
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(0.0, 50.0)
		box.add_child(row)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 12)
		row.add_child(line)
		var mark := _label("%d" % (index + 1), FONT_MONO, 16, SILVER)
		mark.custom_minimum_size = Vector2(28.0, 28.0)
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(mark)
		var title := _label(str(PLAN[index][1]), FONT_BOLD, 18, SILVER)
		title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(title)
		_rows[id] = row
		_row_titles[id] = title
		_row_marks[id] = mark
		_mark_row(id, "pending")
		row.mouse_entered.connect(func() -> void: _info_label.text = str(PHASE_INFO.get(id, "")))
		row.mouse_exited.connect(_show_current_info)
	box.add_child(_spacer(10.0))
	var stats := Vehicle.stats
	var facts := _label("Crew of %d  ·  %d to the surface\nLift-off mass %s t\nPlanned flight: %s days" % [
		int(stats.get("crew", 0)), int(stats.get("surface_crew", 0)), _thousands(roundi(float(stats.get("liftoff_mass", 0.0)))), _num(float(stats.get("mission_days", 0.0)))], FONT, 16, WHITE, true)
	box.add_child(_note_box(facts, Color(BRIGHT_BLUE, 0.35), RED))
	box.add_child(_spacer(8.0))
	box.add_child(_label("WHAT HAPPENS IN THIS STEP", FONT_BOLD, 14, SILVER))
	_info_default = "Point at a step of the plan to read what happens in it."
	_info_label = _label(_info_default, FONT, 15, WHITE, true)
	_info_label.custom_minimum_size = Vector2(0.0, 132.0)
	_info_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	box.add_child(_info_label)
	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(filler)
	box.add_child(_label("A dash marks a step that was not flown: flight rules cut a mission short before they put the crew at risk.", FONT, 14, SILVER, true))


func _show_current_info() -> void:
	var text := _info_default
	if not _finished and _phase_index < _phases.size() and (_line_index >= 0 or _game != null or _gate == "landing"):
		text = str(PHASE_INFO.get(str(_phases[_phase_index]["id"]), _info_default))
	_info_label.text = text


func _mark_row(id: String, state: String) -> void:
	var row: PanelContainer = _rows[id]
	var title: Label = _row_titles[id]
	var mark: Label = _row_marks[id]
	var style := StyleBoxFlat.new()
	style.bg_color = WHITE if state == "current" else Color(0, 0, 0, 0)
	style.border_color = GOLD if state == "current" else Color(WHITE, 0.12)
	style.border_width_left = 6 if state == "current" else 0
	style.border_width_bottom = 0 if state == "current" else 1
	style.content_margin_left = 8.0 if state == "current" else 14.0
	style.content_margin_right = 10.0
	row.add_theme_stylebox_override("panel", style)
	var mark_style := StyleBoxFlat.new()
	mark_style.bg_color = Color(0, 0, 0, 0)
	var index := 0
	for entry: Array in PLAN:
		index += 1
		if entry[0] == id:
			break
	mark.text = "%d" % index
	match state:
		"pending":
			title.add_theme_color_override("font_color", SILVER)
			mark.add_theme_color_override("font_color", SILVER)
		"current":
			title.add_theme_color_override("font_color", NAVY)
			mark.add_theme_color_override("font_color", NAVY)
		"done":
			title.add_theme_color_override("font_color", WHITE)
			mark.text = "✓"
			mark.add_theme_color_override("font_color", WHITE)
			mark_style.bg_color = BRIGHT_BLUE
		"problem":
			title.add_theme_color_override("font_color", WHITE)
			mark.text = "!"
			mark.add_theme_color_override("font_color", WHITE)
			mark_style.bg_color = RED
		"skipped":
			title.add_theme_color_override("font_color", Color(SILVER, 0.5))
			mark.text = "—"
			mark.add_theme_color_override("font_color", Color(SILVER, 0.5))
	mark.add_theme_stylebox_override("normal", mark_style)


func _build_view() -> void:
	_view = FlightView.new()
	_view.position = Vector2(378.0, 90.0)
	_view.size = Vector2(1020.0, 600.0)
	_frame.add_child(_view)
	_view.setup(Vehicle.design, Campaign.site, bool(Vehicle.stats.get("high_orbit", false)))
	var plate := PanelContainer.new()
	plate.position = Vector2(378.0, 90.0)
	var style := StyleBoxFlat.new()
	style.bg_color = NAVY
	style.border_color = GOLD
	style.border_width_left = 6
	style.content_margin_left = 16.0
	style.content_margin_right = 18.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 9.0
	plate.add_theme_stylebox_override("panel", style)
	_frame.add_child(plate)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	plate.add_child(row)
	_caption = _label("READY", FONT_BOLD, 22, WHITE)
	row.add_child(_caption)
	_day_label = _label("LAUNCH DAY", FONT_MONO, 17, SILVER)
	_day_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_day_label)
	_banner = PanelContainer.new()
	_banner.position = Vector2(378.0, 602.0)
	_banner.size = Vector2(1020.0, 88.0)
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = WHITE
	banner_style.border_color = GOLD
	banner_style.border_width_left = 10
	banner_style.content_margin_left = 24.0
	banner_style.content_margin_right = 24.0
	_banner.add_theme_stylebox_override("panel", banner_style)
	_banner.visible = false
	_frame.add_child(_banner)
	_banner_label = _label("", FONT_BOLD, 34, NAVY)
	_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_label)


func _build_gate() -> void:
	_gate_box = PanelContainer.new()
	_gate_box.position = Vector2(378.0 + 130.0, 90.0 + 386.0)
	_gate_box.size = Vector2(760.0, 196.0)
	var style := StyleBoxFlat.new()
	style.bg_color = WHITE
	style.border_color = GOLD
	style.border_width_left = 10
	style.content_margin_left = 28.0
	style.content_margin_right = 24.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 18.0
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 14
	_gate_box.add_theme_stylebox_override("panel", style)
	_gate_box.visible = false
	_frame.add_child(_gate_box)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_gate_box.add_child(box)
	_gate_title = _label("", FONT_BOLD, 28, NAVY)
	box.add_child(_gate_title)
	_gate_text = _label("", FONT, 17, GRAY, true)
	_gate_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_gate_text)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	_gate_yes = Button.new()
	_style_action(_gate_yes)
	_gate_yes.pressed.connect(choose.bind(true))
	_gate_no = Button.new()
	_style_plain(_gate_no)
	_gate_no.pressed.connect(choose.bind(false))
	for button: Button in [_gate_yes, _gate_no]:
		button.custom_minimum_size = Vector2(0.0, 52.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_override("font", FONT_BOLD)
		button.add_theme_font_size_override("font_size", 20)
		row.add_child(button)


func _build_log() -> void:
	var panel := _panel(Rect2(378.0, 706.0, 1020.0, 350.0), 18.0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	box.add_child(_label("FLIGHT LOG", FONT_BOLD, 17, WHITE))
	box.add_child(_rule(GOLD, 56.0, 4.0))
	_log_scroll = ScrollContainer.new()
	_log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(_log_scroll)
	_log_box = VBoxContainer.new()
	_log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_box.add_theme_constant_override("separation", 10)
	_log_scroll.add_child(_log_box)
	_log_scroll.get_v_scroll_bar().changed.connect(_scroll_log)


func _build_status() -> void:
	var panel := _panel(Rect2(1422.0, 90.0, 474.0, 966.0), 20.0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	box.add_child(_label("MISSION STATUS", FONT_BOLD, 17, WHITE))
	box.add_child(_rule(GOLD, 56.0, 4.0))
	box.add_child(_spacer(4.0))
	_add_value(box, "rocket", "ROCKET SPEED", "Checked at the burn for the Moon", true)
	_add_value(box, "ship", "SPACECRAFT ENGINE", "Checked at lunar orbit", true)
	_add_value(box, "science", "SCIENCE RETURNED", "0 of %d planned points" % int(_result.get("science_planned", 0)), false)
	_add_value(box, "budget", "BUDGET LEFT", "Counted after the flight", false)
	box.add_child(_spacer(8.0))
	box.add_child(_label("MISSION OBJECTIVES", FONT_BOLD, 17, WHITE))
	box.add_child(_rule(GOLD, 56.0, 4.0))
	box.add_child(_spacer(4.0))
	for goal: Dictionary in _result.get("objectives", []):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		box.add_child(row)
		var mark := _label("", FONT_BOLD, 17, SILVER)
		mark.custom_minimum_size = Vector2(28.0, 28.0)
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var hollow := StyleBoxFlat.new()
		hollow.bg_color = Color(0, 0, 0, 0)
		hollow.border_color = Color(SILVER, 0.7)
		hollow.set_border_width_all(2)
		mark.add_theme_stylebox_override("normal", hollow)
		row.add_child(mark)
		var text := _label(str(goal["text"]), FONT, 18, SILVER, true)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		_goal_marks.append(mark)
		_goal_labels.append(text)
		box.add_child(_spacer(2.0))
	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(filler)
	_pace_box = VBoxContainer.new()
	_pace_box.add_theme_constant_override("separation", 6)
	box.add_child(_pace_box)
	_pace_box.add_child(_label("FLIGHT PLAYBACK", FONT_BOLD, 17, WHITE))
	_pace_box.add_child(_rule(GOLD, 56.0, 4.0))
	_pace_box.add_child(_spacer(2.0))
	_pause_button = Button.new()
	_pause_button.custom_minimum_size = Vector2(0.0, 64.0)
	_pause_button.focus_mode = Control.FOCUS_NONE
	_pause_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_pause_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_pause_button.add_theme_font_override("font", FONT_BOLD)
	_pause_button.add_theme_font_size_override("font_size", 23)
	_pause_button.pressed.connect(toggle_pause)
	_pace_box.add_child(_pause_button)
	_pause_icon = PaceIcon.new()
	_pause_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_icon.anchor_top = 0.5
	_pause_icon.anchor_bottom = 0.5
	_pause_icon.offset_left = 24.0
	_pause_icon.offset_right = 46.0
	_pause_icon.offset_top = -12.0
	_pause_icon.offset_bottom = 12.0
	_pause_button.add_child(_pause_icon)
	_pause_key = _label("P", FONT_MONO, 17, NAVY)
	_pause_key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_pause_key.anchor_left = 1.0
	_pause_key.anchor_right = 1.0
	_pause_key.anchor_top = 0.5
	_pause_key.anchor_bottom = 0.5
	_pause_key.offset_left = -58.0
	_pause_key.offset_right = -22.0
	_pause_key.offset_top = -16.0
	_pause_key.offset_bottom = 16.0
	_pause_button.add_child(_pause_key)
	var meter := HBoxContainer.new()
	meter.add_theme_constant_override("separation", 12)
	_pace_box.add_child(meter)
	_pace_note = _label("Next log entry", FONT, 15, SILVER)
	_pace_note.custom_minimum_size = Vector2(176.0, 0.0)
	meter.add_child(_pace_note)
	_pace_track = ColorRect.new()
	_pace_track.color = Color(WHITE, 0.16)
	_pace_track.custom_minimum_size = Vector2(0.0, 6.0)
	_pace_track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pace_track.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_pace_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter.add_child(_pace_track)
	_pace_fill = ColorRect.new()
	_pace_fill.color = GOLD
	_pace_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pace_track.add_child(_pace_fill)
	_pace_box.add_child(_spacer(2.0))
	var pace := HBoxContainer.new()
	pace.add_theme_constant_override("separation", 12)
	_pace_box.add_child(pace)
	_next_button = Button.new()
	_next_button.text = "Next entry  ›"
	_next_button.pressed.connect(next_line)
	_skip_button = Button.new()
	_skip_button.text = "Skip to the end"
	_skip_button.pressed.connect(skip_to_end)
	for button: Button in [_next_button, _skip_button]:
		button.custom_minimum_size = Vector2(0.0, 46.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_override("font", FONT_BOLD)
		button.add_theme_font_size_override("font_size", 18)
		_style_outline(button)
		pace.add_child(button)
	_report_button = Button.new()
	_report_button.text = "Mission report  ›"
	_report_button.custom_minimum_size = Vector2(0.0, 56.0)
	_report_button.disabled = true
	_report_button.add_theme_font_override("font", FONT_BOLD)
	_report_button.add_theme_font_size_override("font_size", 21)
	_style_action(_report_button)
	_report_button.pressed.connect(open_report)
	box.add_child(_report_button)


func _show_pace() -> void:
	var paused := _pace_state == "paused"
	var off := _pace_state in ["gate", "over"]
	_pause_button.disabled = off
	_pause_button.text = "Resume the flight" if paused else "Pause the flight"
	_pause_icon.playing = not paused
	var ink := Color(WHITE, 0.45) if off else NAVY
	_pause_icon.color = ink
	_pause_key.add_theme_color_override("font_color", ink)
	var cap := StyleBoxFlat.new()
	cap.bg_color = Color(0, 0, 0, 0)
	cap.border_color = ink
	cap.set_border_width_all(2)
	cap.set_corner_radius_all(4)
	_pause_key.add_theme_stylebox_override("normal", cap)
	var normal := StyleBoxFlat.new()
	normal.bg_color = WHITE if paused else GOLD
	normal.border_color = GOLD
	normal.set_border_width_all(4 if paused else 0)
	normal.set_corner_radius_all(3)
	normal.content_margin_left = 62.0
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = PAPER if paused else GOLD_BRIGHT
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0, 0, 0, 0)
	disabled.border_color = Color(WHITE, 0.3)
	disabled.set_border_width_all(2)
	for state: String in ["normal", "focus"]:
		_pause_button.add_theme_stylebox_override(state, normal)
	_pause_button.add_theme_stylebox_override("hover", hover)
	_pause_button.add_theme_stylebox_override("pressed", hover)
	_pause_button.add_theme_stylebox_override("disabled", disabled)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_pause_button.add_theme_color_override(state, NAVY)
	_pause_button.add_theme_color_override("font_disabled_color", Color(WHITE, 0.45))
	_pace_note.text = {"paused": "Paused", "gate": "Waiting for you", "game": "You have the controls"}.get(_pace_state, "Next log entry")
	_pace_note.add_theme_color_override("font_color", GOLD if paused else SILVER)
	_veil.visible = paused
	if paused:
		_frame.move_child(_veil, -1)


func _build_veil() -> void:
	_veil = Control.new()
	_veil.position = Vector2(378.0, 90.0)
	_veil.size = Vector2(1020.0, 600.0)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.visible = false
	_frame.add_child(_veil)
	var shade := ColorRect.new()
	shade.color = Color(INK, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.add_child(shade)
	var plate := PanelContainer.new()
	plate.position = Vector2(170.0, 226.0)
	plate.size = Vector2(680.0, 148.0)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = NAVY
	style.border_color = GOLD
	style.border_width_left = 10
	style.content_margin_left = 30.0
	style.content_margin_right = 24.0
	style.content_margin_top = 18.0
	style.content_margin_bottom = 20.0
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 14
	plate.add_theme_stylebox_override("panel", style)
	_veil.add_child(plate)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	plate.add_child(box)
	box.add_child(_label("FLIGHT PAUSED", FONT_TITLE, 40, WHITE))
	box.add_child(_label("Read as long as you need. Press P or Resume to go on.", FONT, 19, SILVER))


func _add_value(box: VBoxContainer, key: String, caption: String, text: String, with_gauge: bool) -> void:
	box.add_child(_label(caption, FONT_BOLD, 14, SILVER))
	var value := _label(text, FONT_MONO, 19, WHITE)
	box.add_child(value)
	_values[key] = value
	if with_gauge:
		var gauge := GaugeBar.new()
		box.add_child(gauge)
		_gauges[key] = gauge
	box.add_child(_spacer(6.0))


func _panel(rect: Rect2, margin: float) -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = NAVY
	style.set_corner_radius_all(4)
	style.set_content_margin_all(margin)
	var panel := PanelContainer.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", style)
	_frame.add_child(panel)
	return panel


func _note_box(label: Label, fill: Color, stripe: Color) -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = stripe
	style.border_width_left = 5
	style.set_corner_radius_all(3)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 9.0
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(label)
	return panel


func _style_action(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = RED
	normal.set_corner_radius_all(3)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = RED_DARK
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0, 0, 0, 0)
	disabled.border_color = Color(WHITE, 0.3)
	disabled.set_border_width_all(2)
	for state: String in ["normal", "focus"]:
		button.add_theme_stylebox_override(state, normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", disabled)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, WHITE)
	button.add_theme_color_override("font_disabled_color", Color(WHITE, 0.45))


func _style_plain(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = WHITE
	normal.border_color = INK
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(3)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = PAPER
	for state: String in ["normal", "focus"]:
		button.add_theme_stylebox_override(state, normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, INK)


func _style_outline(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.border_color = WHITE
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(3)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(WHITE, 0.14)
	for state: String in ["normal", "focus"]:
		button.add_theme_stylebox_override(state, normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, WHITE)


func _rule(color: Color, width: float, height: float) -> Control:
	var rule := ColorRect.new()
	rule.color = color
	rule.custom_minimum_size = Vector2(width, height)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule


func _spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, height)
	return spacer


func _label(text: String, font: Font, font_size: int, color: Color, wrap := false) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _thousands(value: int) -> String:
	var text := str(value)
	var out := ""
	while text.length() > 3:
		out = "," + text.substr(text.length() - 3) + out
		text = text.substr(0, text.length() - 3)
	return text + out


func _num(value: float) -> String:
	return ("%.1f" % value).trim_suffix(".0")


class PaceIcon extends Control:
	var playing := true:
		set(value):
			playing = value
			queue_redraw()
	var color := Color.WHITE:
		set(value):
			color = value
			queue_redraw()

	func _draw() -> void:
		if playing:
			var bar := size.x * 0.32
			draw_rect(Rect2(size.x * 0.08, 0.0, bar, size.y), color)
			draw_rect(Rect2(size.x * 0.6, 0.0, bar, size.y), color)
		else:
			draw_colored_polygon(PackedVector2Array([Vector2(size.x * 0.1, 0.0), Vector2(size.x, size.y * 0.5), Vector2(size.x * 0.1, size.y)]), color)
