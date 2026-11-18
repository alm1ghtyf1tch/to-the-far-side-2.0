class_name MissionDashboard
extends Control
## Native controls, shared tactile animation and terminal trim. No flight state writes.

var plan: Array = []
var result := {}
var phase_info := {}
signal navigation_requested
var view_slot: Control
var landing_host: Control
var staging_host: Control
var caption: Label
var day: Label
var latest: Label
var alert_title: Label
var alert: PanelContainer
var gate_box: PanelContainer
var gate_title: Label
var gate_text: Label
var gate_yes: Button
var gate_no: Button
var next_button: Button
var skip_button: Button
var report_button: Button
var pause_button: Button
var pace_note: Label
var pace_track: ColorRect
var pace_fill: ColorRect
var pace_box: VBoxContainer
var banner: PanelContainer
var banner_label: Label
var veil: Control
var info_label: Label
var values := {}
var gauges := {}
var rows := {}
var row_titles := {}
var row_marks := {}
var goal_marks: Array[Label] = []
var goal_labels: Array[Label] = []
var log_box: VBoxContainer
var log_scroll: ScrollContainer
var details: Control
var navigation_slot: Control
var _monitoring: VBoxContainer
var _feed: VBoxContainer
var _steps := {}
var _details_body: Label
var _details_button: Button


func _ready() -> void:
	theme = VisualTheme.shared()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var back := ColorRect.new()
	back.color = Color("111b27")
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 76)
	for side: String in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 56)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	brand.add_child(label("FLIGHT DIRECTOR  /  LUNAR PROGRAMME  /  OBSERVATION LINK", 14, VisualTheme.CYAN, VisualTheme.MONO))
	brand.add_child(label("Mission Control", 40, VisualTheme.PAPER, VisualTheme.DISPLAY))
	var port := str(Vehicle.launch_site().get("short", "—"))
	var target := str(Campaign.site.get("name", "—"))
	var summary := label("%s  →  %s\n%s" % [port, target, Campaign.date_text(int(result.get("launch_day", Campaign.days)))], 17, VisualTheme.MUTED)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(summary)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(columns)
	var observation := panel(Color("070e19"))
	observation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	observation.size_flags_stretch_ratio = 2.12
	columns.add_child(observation)
	var scene_box := VBoxContainer.new()
	scene_box.add_theme_constant_override("separation", 10)
	observation.add_child(scene_box)
	var rail := HBoxContainer.new()
	rail.add_theme_constant_override("separation", 6)
	scene_box.add_child(rail)
	for index in plan.size():
		var step := button("%02d" % (index + 1), 0, 34)
		step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		step.add_theme_font_size_override("font_size", 14)
		step.tooltip_text = str(plan[index][1])
		step.pressed.connect(func() -> void:
			open_details()
			info_label.text = str(plan[index][1]) + "\n\n" + str(phase_info.get(str(plan[index][0]), "")))
		rail.add_child(step)
		_steps[str(plan[index][0])] = step
	view_slot = Control.new()
	view_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene_box.add_child(view_slot)
	landing_host = Control.new()
	landing_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	landing_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	landing_host.hide()
	view_slot.add_child(landing_host)
	scene_box.add_child(label("FLIGHT DIRECTOR OPTICS  /  MISSION OBSERVATION", 12, Color("7d939e"), VisualTheme.MONO))
	var right := panel(Color("1a2733"))
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size.x = 510
	columns.add_child(right)
	var dash := VBoxContainer.new()
	dash.add_theme_constant_override("separation", 9)
	right.add_child(dash)
	day = label("LAUNCH DAY", 13, VisualTheme.CYAN, VisualTheme.MONO)
	dash.add_child(day)
	caption = label("Standing by", 28, VisualTheme.PAPER, VisualTheme.DISPLAY)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dash.add_child(caption)
	alert = panel(Color("102332"))
	dash.add_child(alert)
	var alert_box := VBoxContainer.new()
	alert.add_child(alert_box)
	alert_title = label("OBSERVATION LINK READY", 13, VisualTheme.CYAN, VisualTheme.MONO)
	alert_box.add_child(alert_title)
	latest = label("Awaiting the flight director.", 19, VisualTheme.PAPER)
	latest.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alert_box.add_child(latest)
	gate_box = panel(Color("293746"))
	gate_box.hide()
	dash.add_child(gate_box)
	var gate := VBoxContainer.new()
	gate.add_theme_constant_override("separation", 10)
	gate_box.add_child(gate)
	gate_title = label("", 24, VisualTheme.AMBER, VisualTheme.DISPLAY)
	gate_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gate.add_child(gate_title)
	gate_text = label("", 17, VisualTheme.PAPER)
	gate_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gate.add_child(gate_text)
	gate_yes = button("", 0, 60)
	gate_no = button("", 0, 60)
	for action: Button in [gate_yes, gate_no]:
		action.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		gate.add_child(action)
	staging_host = Control.new()
	staging_host.custom_minimum_size.y = 382
	staging_host.hide()
	dash.add_child(staging_host)
	_monitoring = VBoxContainer.new()
	dash.add_child(_monitoring)
	for entry: Array in [["rocket", "ROCKET Δv", "Checked at the burn for the Moon"], ["ship", "SPACECRAFT Δv", "Checked at lunar orbit"]]:
		_monitoring.add_child(label(entry[1], 12, VisualTheme.MUTED, VisualTheme.MONO))
		var value := label(entry[2], 17, VisualTheme.PAPER, VisualTheme.MONO)
		value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_monitoring.add_child(value)
		values[entry[0]] = value
		var gauge := GaugeBar.new()
		gauge.custom_minimum_size.y = 16
		_monitoring.add_child(gauge)
		gauges[entry[0]] = gauge
	_feed = VBoxContainer.new()
	_feed.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dash.add_child(_feed)
	_feed.add_child(label("MISSION EVENT HISTORY", 13, VisualTheme.MUTED, VisualTheme.MONO))
	log_scroll = ScrollContainer.new()
	log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_feed.add_child(log_scroll)
	log_box = VBoxContainer.new()
	log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_box.add_theme_constant_override("separation", 12)
	log_scroll.add_child(log_box)
	_details_button = button("Flight plan & engineering  ↗", 0, 38)
	_details_button.pressed.connect(open_details)
	dash.add_child(_details_button)
	banner = panel(Color("2c3b43"))
	banner.hide()
	dash.add_child(banner)
	banner_label = label("", 24, VisualTheme.AMBER, VisualTheme.DISPLAY)
	banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner.add_child(banner_label)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 14)
	box.add_child(footer)
	for entry: Array in [["science", "SCIENCE RETURNED", "0 of %d planned points" % int(result.get("science_planned", 0))], ["budget", "BUDGET", "Counted after flight"]]:
		var metric := VBoxContainer.new()
		metric.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		footer.add_child(metric)
		metric.add_child(label(entry[1], 12, VisualTheme.MUTED, VisualTheme.MONO))
		var value := label(entry[2], 17, VisualTheme.PAPER, VisualTheme.MONO)
		metric.add_child(value)
		values[entry[0]] = value
	var pace := VBoxContainer.new()
	pace_box = pace
	pace.custom_minimum_size.x = 160
	footer.add_child(pace)
	pace_note = label("Next log entry", 13, VisualTheme.MUTED)
	pace.add_child(pace_note)
	pace_track = ColorRect.new()
	pace_track.color = Color("304456")
	pace_track.custom_minimum_size.y = 5
	pace.add_child(pace_track)
	pace_fill = ColorRect.new()
	pace_fill.color = VisualTheme.AMBER
	pace_track.add_child(pace_fill)
	pause_button = button("Pause  [P]", 170, 48)
	next_button = button("Next entry  ›", 155, 48)
	skip_button = button("Skip to end", 155, 48)
	report_button = button("Mission report  ›", 215, 48)
	report_button.disabled = true
	for action: Button in [pause_button, next_button, skip_button, report_button]:
		footer.add_child(action)
	_build_details()
	veil = ColorRect.new()
	(veil as ColorRect).color = Color(0.02, 0.04, 0.07, 0.65)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view_slot.add_child(veil)
	var pause_caption := label("FLIGHT PAUSED\nP / Resume to continue", 32, VisualTheme.PAPER, VisualTheme.DISPLAY)
	pause_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pause_caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.add_child(pause_caption)
	veil.hide()


func show_mode(gate_active: bool, game_active: bool) -> void:
	_monitoring.visible = not gate_active and not game_active
	_feed.visible = not gate_active and not game_active


func show_event(phase: Dictionary, line: Dictionary) -> void:
	var bad: bool = line["kind"] == "bad"
	var critical := str(line["text"]).contains("crew was lost") or str(line["text"]).contains("break up")
	alert_title.text = "!  FLIGHT ADVISORY" if bad else ("✓  FLIGHT UPDATE" if line["kind"] == "good" else "●  MISSION UPDATE")
	if critical:
		alert_title.text = "!!  CRITICAL FLIGHT EVENT"
	alert_title.add_theme_color_override("font_color", VisualTheme.DANGER if critical else (VisualTheme.AMBER if bad else VisualTheme.CYAN))
	latest.text = str(line["text"])
	UiMotion.reveal(alert, 0.22)


func mark_phase(id: String, state: String) -> void:
	var step: Button = _steps[id]
	var color: Color = {"current": VisualTheme.AMBER, "done": Color("83c8a5"), "problem": Color("ed9076"), "skipped": Color("4a5968")}.get(state, VisualTheme.MUTED)
	step.add_theme_color_override("font_color", color)
	if step is TactileButton:
		(step as TactileButton)._sync_face()


func open_details() -> void:
	details.show()
	navigation_requested.emit()


func _build_details() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 55
	add_child(layer)
	details = Control.new()
	details.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(details)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.04, 0.07, 0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	details.add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 94)
	details.add_child(margin)
	var surface := panel(Color("172535"))
	margin.add_child(surface)
	var box := VBoxContainer.new()
	surface.add_child(box)
	var close := button("FLIGHT PLAN & ENGINEERING     /     Close ×", 0, 45)
	close.pressed.connect(details.hide)
	box.add_child(close)
	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 24)
	box.add_child(split)
	var plan_box := VBoxContainer.new()
	plan_box.custom_minimum_size.x = 330
	split.add_child(plan_box)
	for entry: Array in plan:
		var row := PanelContainer.new()
		row.custom_minimum_size.y = 43
		plan_box.add_child(row)
		var line := HBoxContainer.new()
		row.add_child(line)
		var mark := label("", 17, VisualTheme.MUTED, VisualTheme.MONO)
		mark.custom_minimum_size.x = 30
		line.add_child(mark)
		var title := label(entry[1], 18, VisualTheme.PAPER)
		line.add_child(title)
		rows[str(entry[0])] = row
		row_titles[str(entry[0])] = title
		row_marks[str(entry[0])] = mark
		row.mouse_entered.connect(func() -> void:
			info_label.text = str(phase_info.get(str(entry[0]), "")))
	var facts := VBoxContainer.new()
	facts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(facts)
	navigation_slot = Control.new()
	navigation_slot.custom_minimum_size.y = 370
	facts.add_child(navigation_slot)
	info_label = label("Point at a flight phase to read its scientific context.", 20, VisualTheme.PAPER)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	facts.add_child(info_label)
	facts.add_child(label("Crew of %d  ·  %d to the surface  ·  Lift-off mass %.0f t\nPlanned flight: %.1f days" % [int(Vehicle.stats.get("crew", 0)), int(Vehicle.stats.get("surface_crew", 0)), float(Vehicle.stats.get("liftoff_mass", 0)), float(Vehicle.stats.get("mission_days", 0))], 18, VisualTheme.MUTED))
	for goal: Dictionary in result.get("objectives", []):
		var row := HBoxContainer.new()
		plan_box.add_child(row)
		var mark := label("□", 18, VisualTheme.MUTED)
		mark.custom_minimum_size.x = 28
		row.add_child(mark)
		var text := label(str(goal["text"]), 17, VisualTheme.MUTED)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		goal_marks.append(mark)
		goal_labels.append(text)
	details.hide()


func panel(color: Color) -> PanelContainer:
	var result_panel := preload("res://ui/components/terminal_panel.gd").new()
	result_panel.add_theme_stylebox_override("panel", VisualTheme.surface(color, Color("435666"), 15))
	return result_panel


func label(text: String, font_size: int, color: Color, font: Font = VisualTheme.BODY) -> Label:
	var result_label := Label.new()
	result_label.text = text
	result_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_label.add_theme_font_override("font", font)
	result_label.add_theme_font_size_override("font_size", font_size)
	result_label.add_theme_color_override("font_color", color)
	return result_label


func button(text: String, width: float, height: float) -> TactileButton:
	var result_button := TactileButton.new()
	result_button.text = text
	result_button.custom_minimum_size = Vector2(width, height)
	result_button.add_theme_font_size_override("font_size", 18)
	result_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return result_button
