extends Control

const FONT := preload("res://assets/fonts/IBMPlexSans-Regular.woff2")
const FONT_BOLD := preload("res://assets/fonts/IBMPlexSans-SemiBold.woff2")
const FONT_TITLE := preload("res://assets/fonts/Saira-Display.ttf")
const THUMBS := "res://assets/textures/vehicle/thumb_%s.png"
const SITE_ART := "res://assets/textures/vehicle/%s.png"
const MAP_RATIO := 1328.0 / 864.0
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

@onready var _frame: Control = %Frame
@onready var _stack: RocketStack = %Stack

var _choice := {}
var _slot_id := ""
var _slot_rows := {}
var _slot_titles := {}
var _slot_values := {}
var _slot_badges := {}
var _slot_numbers := {}
var _cards_box: HBoxContainer
var _slot_title: Label
var _slot_why: Label
var _progress: Label
var _budget_label: Label
var _status: Label
var _hand_over: Button
var _reserve_note: Label
var _values := {}
var _gauges := {}
var _read_more: ReadMore
var _locked := false
var _map: LaunchMap
var _site_card: Control
var _shown_site := ""


func _ready() -> void:
	if Campaign.stage < 6:
		Campaign.reset()
		Campaign.fund_calculations(float(Campaign.science()["requested_pct"]))
		Campaign.finish_calculations(30, 40)
		Campaign.set_science_plan(Campaign.sites()[5], [Campaign.instrument_options()[0], Campaign.instrument_options()[7]])
		Campaign.days = 300.0
		Campaign.stage = 6
	_choice = Vehicle.draft
	_read_more = ReadMore.new()
	add_child(_read_more)
	_build_top_bar()
	_build_slot_list()
	_build_catalog()
	_stack.slot_clicked.connect(select_slot)
	for item: Dictionary in Vehicle.slots():
		_stack.set_part(str(item["id"]), Vehicle.chosen(_choice, str(item["id"])), false)
	select_slot(_first_empty())
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _locked:
		get_viewport().set_input_as_handled()
		Campaign.clock_running = true
		SceneRouter.go_to(SceneRouter.HQ)


func select_slot(slot_id: String) -> void:
	if _locked or slot_id.is_empty():
		return
	_slot_id = slot_id
	_stack.selected = slot_id if RocketStack.ORDER.has(slot_id) else ""
	var slot := Vehicle.slot(slot_id)
	_slot_title.text = str(slot.get("title", ""))
	_slot_why.text = str(slot.get("why", ""))
	_fill_cards()
	_refresh()


func show_site(site_id: String) -> void:
	if _locked or _slot_id != "spaceport":
		return
	_shown_site = site_id
	if _map:
		_map.shown = site_id
	_fill_site_card()


func install(part_id: String) -> void:
	if _locked:
		return
	var was_empty := not _choice.has(_slot_id)
	if _choice.get(_slot_id) == part_id:
		_choice.erase(_slot_id)
	else:
		_choice[_slot_id] = part_id
	_stack.set_part(_slot_id, Vehicle.chosen(_choice, _slot_id))
	_fill_cards()
	_refresh()
	if was_empty and _choice.has(_slot_id):
		create_tween().tween_callback(_advance_from.bind(_slot_id)).set_delay(0.55)


func _advance_from(from: String) -> void:
	if _slot_id == from and not _locked and Vehicle.missing(_choice) > 0:
		select_slot(_first_empty())


func _first_empty() -> String:
	for item: Dictionary in Vehicle.slots():
		if not _choice.has(str(item["id"])):
			return str(item["id"])
	return _slot_id if not _slot_id.is_empty() else str(Vehicle.slots()[0]["id"])


func _refresh() -> void:
	var result := Vehicle.evaluate(_choice)
	var slots := Vehicle.slots()
	for item: Dictionary in slots:
		var slot_id := str(item["id"])
		var part := Vehicle.chosen(_choice, slot_id)
		var active := slot_id == _slot_id
		var filled := not part.is_empty()
		var value: Label = _slot_values[slot_id]
		value.text = _short_name(part) if filled else "Empty"
		value.add_theme_color_override("font_color", GRAY if active else (WHITE if filled else SILVER))
		(_slot_titles[slot_id] as Label).add_theme_color_override("font_color", INK if active else WHITE)
		(_slot_rows[slot_id] as PanelContainer).add_theme_stylebox_override("panel", _row_style(active))
		var badge := StyleBoxFlat.new()
		badge.bg_color = BLUE if active else (WHITE if filled else Color(0, 0, 0, 0))
		badge.border_color = SILVER
		badge.set_border_width_all(0 if active or filled else 1)
		badge.set_corner_radius_all(2)
		(_slot_badges[slot_id] as PanelContainer).add_theme_stylebox_override("panel", badge)
		(_slot_numbers[slot_id] as Label).add_theme_color_override("font_color", WHITE if active else (NAVY if filled else SILVER))
	var left := Vehicle.missing(_choice)
	_progress.text = "%d of %d sections filled" % [slots.size() - left, slots.size()]
	_budget_label.text = "Budget left   %s%%" % _num(float(result["budget_after"]))

	var rocket_built: bool = result["rocket_built"]
	_set_gauge("rocket", float(result["rocket_dv"]) if rocket_built else 0.0, float(result["rocket_need"]),
			"%.2f km/s  ·  needs %.2f" % [result["rocket_dv"], result["rocket_need"]] if rocket_built else "—  ·  needs %.2f km/s" % result["rocket_need"])
	var ship_built: bool = result["ship_built"]
	_set_gauge("ship", float(result["ship_dv"]), float(result["ship_need"]),
			"%.2f km/s  ·  needs %.2f" % [result["ship_dv"], result["ship_need"]] if ship_built else "—  ·  needs %.2f km/s" % result["ship_need"])
	_set_gauge("cargo", float(result["cargo_capacity"]), float(result["cargo_need"]),
			"carries %d kg  ·  needs %d" % [roundi(result["cargo_capacity"]), roundi(result["cargo_need"])] if result["lander_built"] else "—  ·  needs %d kg" % roundi(result["cargo_need"]))
	_set_gauge("power", float(result["power_have"]), float(result["power_need"]),
			"gives %s kW  ·  needs %s" % [_num(result["power_have"]), _num2(result["power_need"])] if result["power_built"] else "—  ·  needs %s kW" % _num2(result["power_need"]))
	var liftoff := float(result["liftoff_mass"])
	_set_value("liftoff", "—" if not _choice.has("stage1") else ("%s t" % _thousands(roundi(liftoff)) + ("  ·  thrust-to-weight %.2f" % result["thrust_to_weight"] if float(result["thrust_to_weight"]) > 0.0 else "")))
	var propellant := float(result["propellant"])
	_set_value("propellant", "—" if propellant <= 0.0 else "%s t  ·  about USD %s million" % [_thousands(roundi(propellant)), _num(snappedf(float(result["propellant_usd"]) / 1000000.0, 0.5))])
	var crew := int(result["crew"])
	_set_value("crew", "—" if crew == 0 else "%d aboard, %d land  ·  %s days" % [crew, result["surface_crew"], _num(result["mission_days"])])
	_set_value("supplies", "—" if not result["life_built"] or crew == 0 else "%s t for %d person-days" % [_num2(result["supplies"]), roundi(result["crew_days"])])
	_set_value("suits", "—" if not result["suits_built"] else ("up to %s hours a day" % _num(result["eva_hours"]) if float(result["eva_hours"]) > 0.0 else "none: cabin suits only"))
	_set_value("cost", "%s%% of budget  ·  %s%% left" % [_num(result["cost"]), _num(result["budget_after"])])
	_set_value("people", "—" if _choice.is_empty() else "%s%% for %s days of work" % [_num(result["workforce_cost"]), _thousands(int(result["program_days"]))])
	var spare := int(result["spare_days"])
	_set_value("ready", "—" if _choice.is_empty() else "%s  ·  %s" % [Campaign.date_text(int(result["ready_day"])), "%d days early" % spare if spare >= 0 else "%d days late" % -spare])
	_reserve_note.text = "Every “needs” for speed includes a ±%s%% reserve for the uncertainty left by Flight Dynamics.%s The budget left after the vehicle pays for operations and surprises. Deadline: %s." % [
			_num(Campaign.margin), " A lander sent ahead lets the ship stop in a high lunar orbit, which needs less speed." if result["high_orbit"] else "", Campaign.deadline_text()]

	_hand_over.disabled = left > 0 or float(result["budget_after"]) < 0.0 or _locked
	if left > 0:
		_status.text = "Fill every section to hand the design over: %d left" % left
	elif float(result["budget_after"]) < 0.0:
		_status.text = "This vehicle costs %s%% more than the budget that is left" % _num(-float(result["budget_after"]))
	else:
		_status.text = "The design is complete. You can still change any part."


func _set_value(key: String, text: String) -> void:
	(_values[key] as Label).text = text


func _set_gauge(key: String, have: float, need: float, text: String) -> void:
	(_values[key] as Label).text = text
	var gauge: GaugeBar = _gauges[key]
	gauge.have = have
	gauge.need = need


func _on_hand_over_pressed() -> void:
	_locked = true
	_hand_over.disabled = true
	_hand_over.text = "Handed over"
	_read_more.clear()
	Vehicle.hand_over(_choice)
	Campaign.clock_running = true
	_status.text = "Design frozen  ·  %s" % Campaign.date_text()
	await get_tree().create_timer(0.7).timeout
	SceneRouter.go_to(SceneRouter.HQ, 0.6)


func _show_details(part: Dictionary) -> void:
	var topic: Dictionary = (part.get("read_more", {}) as Dictionary).duplicate()
	if topic.is_empty():
		return
	topic["title"] = str(part.get("name", ""))
	topic["image"] = SITE_ART % part["picture"] if part.has("picture") else THUMBS % part.get("id", "")
	topic["image_note"] = str(Vehicle.rules().get("image_note", ""))
	_read_more.offer(topic)
	_read_more.open()


func _build_top_bar() -> void:
	var bar := PanelContainer.new()
	bar.position = Vector2.ZERO
	bar.size = Vector2(1920.0, 66.0)
	var style := StyleBoxFlat.new()
	style.bg_color = WHITE
	style.border_color = GOLD
	style.border_width_bottom = 4
	style.content_margin_left = 20.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 12.0
	bar.add_theme_stylebox_override("panel", style)
	_frame.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	bar.add_child(row)
	var stage := PanelContainer.new()
	stage.custom_minimum_size = Vector2(40.0, 40.0)
	var stage_style := StyleBoxFlat.new()
	stage_style.bg_color = GOLD
	stage.add_theme_stylebox_override("panel", stage_style)
	var stage_number := _label("6", FONT_TITLE, 22, NAVY)
	stage_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stage.add_child(stage_number)
	row.add_child(stage)
	var title := _label("Vehicle Assembly", FONT_TITLE, 26, NAVY)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(title)
	var note := _label("Design the vehicle   ·   %s" % Campaign.date_text(), FONT, 17, GRAY)
	note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(note)
	_budget_label = _label("", FONT_BOLD, 17, NAVY)
	_budget_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_budget_label)


func _build_slot_list() -> void:
	var panel := _panel(Rect2(20.0, 86.0, 296.0, 974.0), 0.0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	panel.add_child(box)
	var head := MarginContainer.new()
	head.add_theme_constant_override("margin_left", 16)
	head.add_theme_constant_override("margin_right", 16)
	head.add_theme_constant_override("margin_top", 12)
	head.add_theme_constant_override("margin_bottom", 2)
	box.add_child(head)
	var head_box := VBoxContainer.new()
	head_box.add_theme_constant_override("separation", 6)
	head.add_child(head_box)
	head_box.add_child(_label("SECTIONS", FONT_BOLD, 16, WHITE))
	head_box.add_child(_rule(GOLD, 44.0, 4.0))
	head_box.add_child(_label("Pick a section, then a part for it.", FONT, 14, SILVER))
	var group := ""
	var number := 0
	for item: Dictionary in Vehicle.slots():
		var slot_id := str(item["id"])
		number += 1
		if str(item.get("group", "")) != group:
			group = str(item.get("group", ""))
			var caption := _label("   " + group.to_upper(), FONT_BOLD, 13, SILVER)
			caption.custom_minimum_size = Vector2(0.0, 25.0)
			caption.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			box.add_child(caption)
		var row := PanelContainer.new()
		row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		row.gui_input.connect(_on_row_input.bind(slot_id))
		var line := HBoxContainer.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_theme_constant_override("separation", 12)
		row.add_child(line)
		var badge := PanelContainer.new()
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.custom_minimum_size = Vector2(28.0, 28.0)
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var index_label := _label("%d" % number, FONT_BOLD, 15, SILVER)
		index_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		index_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_child(index_label)
		line.add_child(badge)
		var text := VBoxContainer.new()
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_constant_override("separation", -3)
		line.add_child(text)
		var title := _label(str(item["title"]), FONT_BOLD, 17, WHITE)
		text.add_child(title)
		var value := _label("Empty", FONT, 14, SILVER)
		value.clip_text = true
		value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		text.add_child(value)
		box.add_child(row)
		_slot_rows[slot_id] = row
		_slot_titles[slot_id] = title
		_slot_values[slot_id] = value
		_slot_badges[slot_id] = badge
		_slot_numbers[slot_id] = index_label
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(gap)
	var foot := MarginContainer.new()
	foot.add_theme_constant_override("margin_left", 16)
	foot.add_theme_constant_override("margin_right", 16)
	foot.add_theme_constant_override("margin_bottom", 10)
	box.add_child(foot)
	var foot_box := VBoxContainer.new()
	foot_box.add_theme_constant_override("separation", 2)
	foot.add_child(foot_box)
	_progress = _label("", FONT_BOLD, 15, WHITE)
	foot_box.add_child(_progress)
	foot_box.add_child(_label("Esc  ·  back to HQ, the design is kept", FONT, 13, SILVER))


func _build_catalog() -> void:
	var panel := _panel(Rect2(772.0, 86.0, 1128.0, 974.0), 20.0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	_slot_title = _label("", FONT_TITLE, 26, WHITE)
	box.add_child(_slot_title)
	box.add_child(_rule(GOLD, 56.0, 4.0))
	_slot_why = _label("", FONT, 18, NAVY, true)
	_slot_why.custom_minimum_size = Vector2(0.0, 50.0)
	_slot_why.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(_note_box(_slot_why, PAPER, BRIGHT_BLUE))
	_cards_box = HBoxContainer.new()
	_cards_box.add_theme_constant_override("separation", 12)
	_cards_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_cards_box)

	var divider := ColorRect.new()
	divider.color = Color(WHITE, 0.22)
	divider.custom_minimum_size = Vector2(0.0, 1.0)
	box.add_child(divider)
	var check_head := HBoxContainer.new()
	check_head.add_theme_constant_override("separation", 10)
	box.add_child(check_head)
	var bullet := ColorRect.new()
	bullet.color = GOLD
	bullet.custom_minimum_size = Vector2(10.0, 10.0)
	bullet.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	check_head.add_child(bullet)
	check_head.add_child(_label("VEHICLE CHECK", FONT_BOLD, 15, WHITE))
	check_head.add_child(_label("updates with every part", FONT, 14, SILVER))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 34)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)
	var rows := [
		["rocket", "Rocket speed, pad to the Moon (Δv)", true],
		["ship", "Spacecraft engine, there and back (Δv)", true],
		["cargo", "Lander cargo to the surface", true],
		["power", "Electric power", true],
		["liftoff", "Mass at lift-off", false],
		["propellant", "Propellant on board", false],
		["crew", "Crew and mission length", false],
		["supplies", "Air, water and food", false],
		["suits", "Time outside on the Moon", false],
		["cost", "Cost of this vehicle", false],
		["people", "Of which people and facilities", false],
		["ready", "Ready to launch", false],
	]
	for row: Array in rows:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", 0)
		grid.add_child(cell)
		cell.add_child(_label(str(row[1]), FONT, 14, SILVER))
		var value := _label("—", FONT_BOLD, 18, WHITE)
		value.clip_text = true
		cell.add_child(value)
		_values[row[0]] = value
		if row[2]:
			var gauge := GaugeBar.new()
			cell.add_child(gauge)
			_gauges[row[0]] = gauge
	_reserve_note = _label("", FONT, 15, WHITE, true)
	box.add_child(_note_box(_reserve_note, Color(BRIGHT_BLUE, 0.35), RED))

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 16)
	box.add_child(footer)
	_status = _label("", FONT_BOLD, 16, WHITE)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_status)
	_hand_over = Button.new()
	_hand_over.text = "Hand over to the Board  ›"
	_hand_over.custom_minimum_size = Vector2(330.0, 50.0)
	_hand_over.focus_mode = Control.FOCUS_NONE
	_hand_over.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_hand_over.add_theme_font_override("font", FONT_BOLD)
	_hand_over.add_theme_font_size_override("font_size", 19)
	_style_button(_hand_over, true)
	_hand_over.pressed.connect(_on_hand_over_pressed)
	footer.add_child(_hand_over)


func _fill_cards() -> void:
	for child in _cards_box.get_children():
		_cards_box.remove_child(child)
		child.queue_free()
	_map = null
	_site_card = null
	if _slot_id == "spaceport":
		_fill_sites()
		return
	var parts: Array = Vehicle.slot(_slot_id).get("parts", [])
	for part: Dictionary in parts:
		_cards_box.add_child(_make_card(part, _choice.get(_slot_id) == part.get("id"), parts.size() > 3))


func _make_card(part: Dictionary, installed: bool, compact := false) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.gui_input.connect(_on_card_input.bind(str(part.get("id", ""))))
	var edge := 4.0 if installed else 0.0
	var style := StyleBoxFlat.new()
	style.bg_color = WHITE
	style.border_color = BRIGHT_BLUE
	style.set_border_width_all(int(edge))
	style.set_corner_radius_all(3)
	style.set_content_margin_all(edge)
	card.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_theme_constant_override("separation", 0)
	card.add_child(box)

	var photo := Control.new()
	photo.custom_minimum_size = Vector2(0.0, (112.0 if compact else 134.0) - edge)
	photo.clip_contents = true
	photo.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_child(photo)
	var backdrop := ColorRect.new()
	backdrop.color = PAPER
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	photo.add_child(backdrop)
	var path := THUMBS % part.get("id", "")
	if ResourceLoader.exists(path):
		var image := TextureRect.new()
		image.texture = load(path)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		photo.add_child(image)
	if installed:
		photo.add_child(_chip("INSTALLED", BRIGHT_BLUE, WHITE))

	var body := MarginContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_PASS
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var side := 11.0 if compact else 14.0
	body.add_theme_constant_override("margin_left", int(side - edge))
	body.add_theme_constant_override("margin_right", int(side - edge))
	body.add_theme_constant_override("margin_top", 8)
	body.add_theme_constant_override("margin_bottom", int(11.0 - edge))
	box.add_child(body)
	var text_box := VBoxContainer.new()
	text_box.mouse_filter = Control.MOUSE_FILTER_PASS
	text_box.add_theme_constant_override("separation", 5)
	body.add_child(text_box)
	var small := 13 if compact else 14
	var title := _label(str(part.get("name", "")), FONT_BOLD, 17 if compact else 19, INK, true)
	title.max_lines_visible = 2
	text_box.add_child(title)
	var text := _label(str(part.get("what", "")), FONT, small, GRAY, true)
	text.custom_minimum_size = Vector2(0.0, 40.0)
	text.max_lines_visible = 4
	text_box.add_child(text)

	var specs := GridContainer.new()
	specs.columns = 2
	specs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	specs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	specs.add_theme_constant_override("h_separation", 12)
	specs.add_theme_constant_override("v_separation", 1)
	text_box.add_child(specs)
	for spec: Array in part.get("specs", []):
		specs.add_child(_label(str(spec[0]), FONT, small, GRAY))
		var value := _label(str(spec[1]), FONT_BOLD, small, INK)
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		specs.add_child(value)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	text_box.add_child(row)
	var details := Button.new()
	details.text = "Details  ›"
	details.focus_mode = Control.FOCUS_NONE
	details.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	details.add_theme_font_override("font", FONT_BOLD)
	details.add_theme_font_size_override("font_size", 15)
	for state: String in ["font_color", "font_pressed_color", "font_focus_color"]:
		details.add_theme_color_override(state, BLUE)
	details.add_theme_color_override("font_hover_color", BRIGHT_BLUE)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		details.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	details.pressed.connect(_show_details.bind(part))
	row.add_child(details)
	var gap := Control.new()
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(gap)
	var action := Button.new()
	action.text = "Remove" if installed else "Install"
	action.custom_minimum_size = Vector2(104.0 if compact else 124.0, 34.0)
	action.focus_mode = Control.FOCUS_NONE
	action.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	action.add_theme_font_override("font", FONT_BOLD)
	action.add_theme_font_size_override("font_size", 16)
	if installed:
		_style_outline_button(action)
	else:
		_style_button(action, false)
	action.pressed.connect(install.bind(str(part.get("id", ""))))
	row.add_child(action)
	return card


func _fill_sites() -> void:
	var chosen := str(_choice.get("spaceport", ""))
	if _shown_site.is_empty():
		_shown_site = chosen
	var holder := Control.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.size_flags_stretch_ratio = 1.27
	holder.clip_contents = true
	_cards_box.add_child(holder)
	_map = LaunchMap.new()
	_map.sites = Vehicle.slot("spaceport").get("parts", [])
	_map.chosen = chosen
	_map.shown = _shown_site
	_map.site_clicked.connect(show_site)
	holder.add_child(_map)
	holder.resized.connect(_fit_map.bind(holder))
	_fit_map(holder)
	_fill_site_card()


func _fit_map(holder: Control) -> void:
	if holder.get_child_count() == 0:
		return
	var width := minf(holder.size.x, holder.size.y * MAP_RATIO)
	var map := holder.get_child(0) as Control
	map.position = Vector2.ZERO
	map.size = Vector2(width, width / MAP_RATIO).floor()


func _fill_site_card() -> void:
	if _site_card:
		_cards_box.remove_child(_site_card)
		_site_card.queue_free()
	var part := Vehicle.chosen({"spaceport": _shown_site}, "spaceport")
	_site_card = _make_site_intro() if part.is_empty() else _make_site_card(part, _choice.get("spaceport") == part.get("id"))
	_site_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_box.add_child(_site_card)


func _site_sheet(installed: bool) -> PanelContainer:
	var edge := 4.0 if installed else 0.0
	var style := StyleBoxFlat.new()
	style.bg_color = WHITE
	style.border_color = BRIGHT_BLUE
	style.set_border_width_all(int(edge))
	style.set_corner_radius_all(3)
	style.content_margin_left = 14.0 - edge
	style.content_margin_right = 14.0 - edge
	style.content_margin_top = 12.0 - edge
	style.content_margin_bottom = 11.0 - edge
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", style)
	return card


func _make_site_intro() -> PanelContainer:
	var card := _site_sheet(false)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	box.add_child(_label("Five places NASA launches from", FONT_BOLD, 19, INK))
	box.add_child(_label("Each red dot is a real launch site in the United States. Pick one to see what it offers. The white fan on the map shows the directions in which rockets may be launched from it. Orbit tilt is the angle between an orbit and the equator.", FONT, 14, GRAY, true))
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 0)
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(list)
	for part: Dictionary in Vehicle.slot("spaceport").get("parts", []):
		var row := Button.new()
		row.focus_mode = Control.FOCUS_NONE
		row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		row.custom_minimum_size = Vector2(0.0, 40.0)
		var normal := StyleBoxFlat.new()
		normal.bg_color = WHITE
		normal.border_color = Color(SILVER, 0.6)
		normal.border_width_bottom = 1
		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = PAPER
		for state: String in ["normal", "focus", "disabled"]:
			row.add_theme_stylebox_override(state, normal)
		for state: String in ["hover", "pressed", "hover_pressed"]:
			row.add_theme_stylebox_override(state, hover)
		row.pressed.connect(show_site.bind(str(part["id"])))
		var line := HBoxContainer.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_theme_constant_override("separation", 10)
		line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		line.offset_left = 4.0
		line.offset_right = -4.0
		row.add_child(line)
		var dot := Panel.new()
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.custom_minimum_size = Vector2(12.0, 12.0)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var dot_style := StyleBoxFlat.new()
		dot_style.bg_color = RED
		dot_style.set_corner_radius_all(6)
		dot.add_theme_stylebox_override("panel", dot_style)
		line.add_child(dot)
		var name_label := _label(str(part.get("name", "")), FONT_BOLD, 15, INK)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.clip_text = true
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		line.add_child(name_label)
		line.add_child(_label(str(part.get("state", "")), FONT, 14, GRAY))
		list.add_child(row)
	box.add_child(_label("NASA also launches small rockets from Kwajalein Atoll in the Pacific, far outside this map.", FONT, 13, GRAY, true))
	return card


func _make_site_card(part: Dictionary, installed: bool) -> PanelContainer:
	var card := _site_sheet(installed)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	box.add_child(head)
	var photo := Control.new()
	photo.custom_minimum_size = Vector2(196.0, 90.0)
	photo.clip_contents = true
	head.add_child(photo)
	var path := SITE_ART % part.get("picture", "")
	if ResourceLoader.exists(path):
		var image := TextureRect.new()
		image.texture = load(path)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		photo.add_child(image)
	if installed:
		photo.add_child(_chip("CHOSEN", BRIGHT_BLUE, WHITE))
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	names.add_theme_constant_override("separation", 0)
	head.add_child(names)
	var title := _label(str(part.get("name", "")), FONT_BOLD, 19, INK, true)
	title.max_lines_visible = 2
	names.add_child(title)
	names.add_child(_label("%s  ·  %s° N" % [part.get("state", ""), _num(float(part.get("lat", 0.0)))], FONT, 15, GRAY))

	var text := _label(str(part.get("what", "")), FONT, 14, GRAY, true)
	text.max_lines_visible = 4
	box.add_child(text)

	var specs := GridContainer.new()
	specs.columns = 2
	specs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	specs.add_theme_constant_override("h_separation", 12)
	specs.add_theme_constant_override("v_separation", 0)
	box.add_child(specs)
	for spec: Array in part.get("specs", []):
		specs.add_child(_label(str(spec[0]), FONT, 14, GRAY))
		var value := _label(str(spec[1]), FONT_BOLD, 14, INK)
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.clip_text = true
		value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		specs.add_child(value)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var details := Button.new()
	details.text = "Read more  ›"
	details.focus_mode = Control.FOCUS_NONE
	details.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	details.add_theme_font_override("font", FONT_BOLD)
	details.add_theme_font_size_override("font_size", 15)
	for state: String in ["font_color", "font_pressed_color", "font_focus_color"]:
		details.add_theme_color_override(state, BLUE)
	details.add_theme_color_override("font_hover_color", BRIGHT_BLUE)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		details.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	details.pressed.connect(_show_details.bind(part))
	row.add_child(details)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(gap)
	var action := Button.new()
	action.text = "Remove" if installed else "Launch from here"
	action.custom_minimum_size = Vector2(124.0 if installed else 184.0, 34.0)
	action.focus_mode = Control.FOCUS_NONE
	action.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	action.add_theme_font_override("font", FONT_BOLD)
	action.add_theme_font_size_override("font_size", 16)
	if installed:
		_style_outline_button(action)
	else:
		_style_button(action, false)
	action.pressed.connect(install.bind(str(part.get("id", ""))))
	row.add_child(action)
	return card


func _short_name(part: Dictionary) -> String:
	if part.has("short") and part.has("state"):
		return "%s, %s" % [part["short"], part["state"]]
	return str(part.get("name", ""))


func _on_row_input(event: InputEvent, slot_id: String) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		select_slot(slot_id)


func _on_card_input(event: InputEvent, part_id: String) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT and _choice.get(_slot_id) != part_id:
		install(part_id)


func _panel(rect: Rect2, margin: float) -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = NAVY
	style.set_corner_radius_all(4)
	style.set_content_margin_all(margin)
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0.0, 4.0)
	var panel := PanelContainer.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", style)
	_frame.add_child(panel)
	return panel


func _row_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = WHITE if active else Color(0, 0, 0, 0)
	style.border_color = GOLD if active else Color(WHITE, 0.12)
	style.border_width_left = 6 if active else 0
	style.border_width_bottom = 0 if active else 1
	style.content_margin_left = 10.0 if active else 16.0
	style.content_margin_right = 12.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 6.0 if active else 5.0
	return style


func _style_button(button: Button, large: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = RED
	normal.set_corner_radius_all(3)
	normal.content_margin_left = 16.0
	normal.content_margin_right = 16.0
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = RED_DARK
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("99231b")
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0, 0, 0, 0)
	disabled.border_color = Color(WHITE, 0.3)
	disabled.set_border_width_all(2)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled if large else normal)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, WHITE)
	button.add_theme_color_override("font_disabled_color", Color(WHITE, 0.45))


func _style_outline_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = WHITE
	normal.border_color = INK
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(3)
	normal.content_margin_left = 16.0
	normal.content_margin_right = 16.0
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("f9e0de")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("hover", hover)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, INK)


func _chip(text: String, fill: Color, color: Color) -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 4.0
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", style)
	chip.add_child(_label(text, FONT_BOLD, 13, color))
	return chip


func _note_box(label: Label, fill: Color, stripe: Color) -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = stripe
	style.border_width_left = 5
	style.set_corner_radius_all(3)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 8.0
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(label)
	return panel


func _rule(color: Color, width: float, height: float) -> Control:
	var rule := ColorRect.new()
	rule.color = color
	rule.custom_minimum_size = Vector2(width, height)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule


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


func _num(value: float) -> String:
	return ("%.1f" % value).trim_suffix(".0")


func _num2(value: float) -> String:
	return ("%.2f" % value).trim_suffix("0").trim_suffix(".0")


func _thousands(value: int) -> String:
	var text := str(absi(value))
	var out := ""
	while text.length() > 3:
		out = "," + text.right(3) + out
		text = text.left(text.length() - 3)
	return ("-" if value < 0 else "") + text + out
