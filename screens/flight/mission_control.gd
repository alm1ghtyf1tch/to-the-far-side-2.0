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
var _view: CinematicFlightView
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
var _pace_note: Label
var _pace_track: ColorRect
var _pace_fill: ColorRect
var _veil: Control


var _ui: MissionDashboard
var _navigation: FlightView
var _pending_games := {}
var _follow_log := true
var _log_dragging := false


func _build_presentation() -> void:
	_ui = MissionDashboard.new()
	_ui.plan = PLAN
	_ui.result = _result
	_ui.phase_info = PHASE_INFO
	_frame.add_child(_ui)
	_view = CinematicFlightView.new()
	_ui.view_slot.add_child(_view)
	_ui.view_slot.move_child(_view, 0)
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view.setup(Vehicle.design, Campaign.site, bool(Vehicle.stats.get("high_orbit", false)))
	_caption = _ui.caption
	_day_label = _ui.day
	_rows = _ui.rows
	_row_titles = _ui.row_titles
	_row_marks = _ui.row_marks
	_info_label = _ui.info_label
	_info_default = "Point at a step of the plan to read what happens in it."
	_values = _ui.values
	_gauges = _ui.gauges
	_goal_marks = _ui.goal_marks
	_goal_labels = _ui.goal_labels
	_banner = _ui.banner
	_banner_label = _ui.banner_label
	_log_box = _ui.log_box
	_log_scroll = _ui.log_scroll
	_log_scroll.gui_input.connect(_log_input)
	_log_scroll.get_v_scroll_bar().gui_input.connect(_log_input)
	_gate_box = _ui.gate_box
	_gate_title = _ui.gate_title
	_gate_text = _ui.gate_text
	_gate_yes = _ui.gate_yes
	_gate_no = _ui.gate_no
	_next_button = _ui.next_button
	_skip_button = _ui.skip_button
	_report_button = _ui.report_button
	_pause_button = _ui.pause_button
	_pace_box = _ui.pace_box
	_pace_note = _ui.pace_note
	_pace_track = _ui.pace_track
	_pace_fill = _ui.pace_fill
	_veil = _ui.veil
	_gate_yes.pressed.connect(choose.bind(true))
	_gate_no.pressed.connect(choose.bind(false))
	_pause_button.pressed.connect(toggle_pause)
	_next_button.pressed.connect(next_line)
	_skip_button.pressed.connect(skip_to_end)
	_report_button.pressed.connect(open_report)
	for button: Button in [_pause_button, _next_button, _skip_button]:
		button.focus_mode = Control.FOCUS_NONE
	for entry: Array in PLAN:
		_mark_row(str(entry[0]), "pending")
	_navigation = FlightView.new()
	_navigation.size = Vector2(1020, 600)
	_ui.navigation_slot.add_child(_navigation)
	_navigation.setup(Vehicle.design, Campaign.site, bool(Vehicle.stats.get("high_orbit", false)))
	_navigation.set_process(false)
	_ui.navigation_slot.resized.connect(_place_navigation)
	_ui.navigation_requested.connect(refresh_navigation)
	_place_navigation()


func _place_navigation() -> void:
	var ratio := minf(_ui.navigation_slot.size.x / 1020.0, _ui.navigation_slot.size.y / 600.0)
	_navigation.scale = Vector2.ONE * maxf(ratio, 0.01)
	_navigation.position = (_ui.navigation_slot.size - Vector2(1020, 600) * ratio) * 0.5


func refresh_navigation() -> void:
	_navigation.view = _view.view
	_navigation.mode = _view.mode
	_navigation.jump(_view.progress)
	_navigation.burning = _view.burning
	_navigation.walkers = _view.walkers
	if _view.staged < _navigation.staged:
		_navigation.reset_stack()
	if _view.staged > _navigation.staged:
		_navigation.drop_stage(_view.staged, false)


func _place_landing(game: Control) -> void:
	if not is_instance_valid(game):
		return
	var ratio := minf(_ui.landing_host.size.x / 1020.0, _ui.landing_host.size.y / 600.0)
	game.scale = Vector2.ONE * ratio
	game.position = (_ui.landing_host.size - Vector2(1020, 600) * ratio) * 0.5


func _show_pace() -> void:
	var state := _pace_state
	_pause_button.disabled = state in ["gate", "over"]
	_pause_button.text = "Resume  [P]" if state == "paused" else "Pause  [P]"
	_pace_note.text = {"paused": "Flight paused", "gate": "Waiting for you", "game": "Manual controls", "over": "Flight complete"}.get(state, "Next log entry")
	_ui.show_mode(_gate != "", _game is StagingGame)
	_veil.visible = state == "paused"
	if _veil.visible:
		_veil.get_parent().move_child(_veil, -1)


func _add_line(phase: Dictionary, line: Dictionary) -> void:
	var kind := str(line["kind"])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var mark := ColorRect.new()
	mark.custom_minimum_size.x = 3.0
	mark.color = {"good": Color("83c8a5"), "bad": VisualTheme.AMBER}.get(kind, VisualTheme.CYAN)
	row.add_child(mark)
	var day := float(phase.get("day", 0.0))
	var stamp := _ui.label("LAUNCH" if day < 0.05 else "DAY %d" % (int(day) + 1), 12, VisualTheme.MUTED, VisualTheme.MONO)
	stamp.custom_minimum_size.x = 55
	row.add_child(stamp)
	var text := _ui.label(str(line["text"]), 17, VisualTheme.PAPER)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	_log_box.add_child(row)
	_ui.show_event(phase, line)
	if not _instant:
		UiMotion.reveal(row, 0.22)
	if _follow_log:
		_scroll_log.call_deferred()


func _scroll_log() -> void:
	await get_tree().process_frame
	if is_inside_tree() and _follow_log:
		_log_scroll.scroll_vertical = int(_log_scroll.get_v_scroll_bar().max_value)


func _log_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_log_dragging = event.pressed
	if event is InputEventMouseButton or event is InputEventKey:
		_follow_log = false
		_resume_log_follow.call_deferred()


func _resume_log_follow() -> void:
	await get_tree().process_frame
	if is_inside_tree() and not _log_dragging:
		var bar := _log_scroll.get_v_scroll_bar()
		_follow_log = bar.value >= bar.max_value - bar.page - 24.0


func _ready() -> void:
	if Campaign.stage < 10 or (Campaign.stage > 10 and Flight.result.is_empty()):
		Flight.quick_start(10)
	if Campaign.stage == 10:
		Flight.fly()
	Campaign.clock_running = false
	_result = Flight.result
	_phases = _result.get("phases", [])
	_build_presentation()
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_step)
	add_child(_timer)
	_open_gate.call_deferred("start")


func _process(_delta: float) -> void:
	if _ui.details.visible:
		refresh_navigation()
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
	if event.is_action_pressed("ui_cancel") and _ui.details.visible:
		_ui.details.hide()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
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
	if paused and _game is LandingGame:
		(_game as LandingGame).steer(false, 0.0)
	var mode: Node.ProcessMode = Node.PROCESS_MODE_DISABLED if paused else Node.PROCESS_MODE_INHERIT
	_timer.process_mode = mode
	_view.process_mode = mode
	if _game != null:
		_game.process_mode = mode
	if not paused and not _pending_games.is_empty():
		var pending := _pending_games.duplicate(true)
		_pending_games.clear()
		if pending.has("staging"):
			_on_staging_finished(pending["staging"])
		elif pending.has("landing"):
			_on_landing_finished(pending["landing"])


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
	_pending_games.clear()
	_ui.staging_host.hide()
	_ui.landing_host.hide()
	_view.show()
	_view.viewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_view.space.spacecraft.settle()
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
	_pace_state = ""
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
		var phase_day := float(_phases[_phase_index].get("day", 0.0))
		_day_label.text = "MISSION DAY %d" % (int(phase_day) + 1)
		_gate_title.text = "150 metres above the Moon"
		_gate_text.text = "The computer has flown the lander this far. You can fly the last part yourself and pick the spot, or let the computer finish the landing."
		_gate_yes.text = "I fly the landing"
		_gate_no.text = "Let the computer land"
	_gate_box.visible = true
	_ui.show_mode(true, false)
	UiMotion.reveal(_gate_box, 0.25)
	_gate_yes.grab_focus()


func choose(manual: bool) -> void:
	if _gate == "":
		return
	var kind := _gate
	_gate = ""
	_pace_state = ""
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
	_pace_state = ""
	_mark_row("ascent", "current")
	_caption.text = "ASCENT"
	_day_label.text = "LAUNCH DAY"
	_next_button.disabled = true
	_info_label.text = str(PHASE_INFO["ascent"])
	_view.present_phase(phase, false)
	var game := preload("res://screens/flight/cinematic_staging_game.gd").new()
	_ui.staging_host.show()
	_ui.staging_host.add_child(game)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_game = game
	game.start(_view, _result.get("stage_names", ["first stage", "second stage"]), Vehicle.stats.get("stage_dv", [0.0, 0.0, 0.0]), str(phase.get("fail", "")))
	game.finished.connect(_on_staging_finished)


func _on_staging_finished(errors: Array) -> void:
	if _game == null:
		return
	if _paused:
		_pending_games["staging"] = errors.duplicate()
		return
	_ui.staging_host.hide()
	_pace_state = ""
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
	_pace_state = ""
	_next_button.disabled = true
	_view.present_phase(phase, false)
	_view.hide()
	_view.viewport_3d.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var game := preload("res://screens/flight/cinematic_landing_game.gd").new()
	_ui.landing_host.show()
	_ui.landing_host.add_child(game)
	game.size = Vector2(1020, 600)
	_place_landing(game)
	_ui.landing_host.resized.connect(_place_landing.bind(game))
	_game = game
	game.start(phase.get("setup", {}), str(Campaign.site.get("id", "a11")))
	game.finished.connect(_on_landing_finished)


func _on_landing_finished(outcome: Dictionary) -> void:
	if _game == null:
		return
	if _paused:
		_pending_games["landing"] = outcome.duplicate(true)
		return
	_ui.landing_host.hide()
	_pace_state = ""
	_view.show()
	_view.viewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
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
	_view.present_phase(phase, _instant)
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
				_view.present_landing_result(_overrides.get("landing", {}))
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
	_view.present_line(phase, line, _line_index, _instant)


func _end_phase(phase: Dictionary) -> void:
	_view.presentation.complete_phase()
	var id := str(phase["id"])
	_mark_row(id, "problem" if str(phase["status"]) == "problem" else "done")
	if id == "countdown" and str(_result.get("outcome", "")) != "no_launch":
		_show_goal(2)
	if id == "landing":
		_show_goal(0)


func _finish() -> void:
	_finished = true
	_view.presentation.finish(_result)
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
	UiMotion.reveal(_banner, 0.0 if _instant else 0.5)
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
	if _phase_index < _phases.size() and _phases[_phase_index]["id"] == "surface":
		var deployed := []
		for row: Dictionary in _result.get("science_rows", []):
			for item: Dictionary in Flight.build.get("kept", []):
				if row.get("name") == item.get("name"):
					deployed.append(row)
		_view.space.spacecraft.surface_work(deployed)


func _show_goal(index: int) -> void:
	var goal: Dictionary = (_result.get("objectives", []) as Array)[index]
	var mark := _goal_marks[index]
	mark.text = "✓" if goal["met"] else "✕"
	mark.add_theme_color_override("font_color", WHITE)
	var style := StyleBoxFlat.new()
	style.bg_color = BRIGHT_BLUE if goal["met"] else RED
	mark.add_theme_stylebox_override("normal", style)
	_goal_labels[index].add_theme_color_override("font_color", WHITE)


func _show_current_info() -> void:
	var text := _info_default
	if not _finished and _phase_index < _phases.size() and (_line_index >= 0 or _game != null or _gate == "landing"):
		text = str(PHASE_INFO.get(str(_phases[_phase_index]["id"]), _info_default))
	_info_label.text = text


func _mark_row(id: String, state: String) -> void:
	_ui.mark_phase(id, state)
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


func _num(value: float) -> String:
	return ("%.1f" % value).trim_suffix(".0")
