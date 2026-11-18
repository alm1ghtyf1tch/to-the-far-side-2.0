extends Control
## Draft and commit flow from the original assembly screen; presentation is isolated.

const THUMBS := "res://assets/textures/vehicle/thumb_%s.png"
const SITE_ART := "res://assets/textures/vehicle/%s.png"
const MAP_RATIO := 1328.0 / 864.0

var _shell: ImmersiveSceneShell
var _hangar: AssemblyHangar
var _ui: AssemblyOverlay
var _choice := {}
var _slot_id := ""
var _locked := false
var _read_more: ReadMore
var _values := {}
var _gauges := {}
var _reserve_note: Label
var _hand_over: Button
var _status: Label
var _map: LaunchMap
var _shown_site := ""
var _site_overlay: Control
var _site_info: VBoxContainer
var _hover_timer: Timer
var _pending_part := ""
var _pending_slot := ""
var _option_cards: Array[AssemblyOptionCard] = []
var _metric_tweens := {}


func _ready() -> void:
	if Campaign.stage < 6:
		Campaign.reset()
		Campaign.fund_calculations(float(Campaign.science()["requested_pct"]))
		Campaign.finish_calculations(30, 40)
		Campaign.set_science_plan(Campaign.sites()[5], [Campaign.instrument_options()[0], Campaign.instrument_options()[7]])
		Campaign.days = 300.0
		Campaign.stage = 6
	_choice = Vehicle.draft
	_build_presentation()
	select_slot(_first_empty())
	_refresh()


func _build_presentation() -> void:
	_shell = ImmersiveSceneShell.new()
	add_child(_shell)
	_hangar = _shell.set_world(preload("res://environments/assembly/assembly_hangar.tscn")) as AssemblyHangar
	var picking := preload("res://screens/engineering/assembly_picking.gd").new()
	picking.hangar = _hangar
	picking.shell = _shell
	_shell.overlays.add_child(picking)
	picking.section_clicked.connect(select_slot)
	_ui = AssemblyOverlay.new()
	_shell.overlays.add_child(_ui)
	_ui.slot_requested.connect(select_slot)
	_ui.notes_requested.connect(_show_details)
	_ui.install_requested.connect(install)
	_values = _ui.values
	_gauges = _ui.gauges
	_reserve_note = _ui.reserve_note
	_hand_over = _ui.hand_over
	_status = _ui.status
	_hand_over.pressed.connect(_on_hand_over_pressed)
	_read_more = preload("res://screens/science_plan/planner_read_more.gd").new()
	add_child(_read_more)
	_hover_timer = Timer.new()
	_hover_timer.one_shot = true
	_hover_timer.wait_time = 0.12
	add_child(_hover_timer)
	_hover_timer.timeout.connect(_show_preview)
	_hangar.rocket.set_choice(_choice, "", false)
	_hangar.set_site(Vehicle.chosen(_choice, "spaceport"))
	_build_site_overlay()


func _process(_delta: float) -> void:
	if _slot_id.is_empty():
		return
	var at := _hangar.camera.unproject_position(_hangar.rocket.centre_of(_slot_id))
	at = at / Vector2(_shell.viewport_3d.size) * size
	_ui.callout.position = Vector2(clampf(at.x + 74, 350, maxf(350, size.x - 910)), clampf(at.y - 25, 150, size.y - 200))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _locked:
		get_viewport().set_input_as_handled()
		if _read_more.is_open():
			_read_more.close()
		elif _ui.sheet.visible:
			_ui.sheet.hide()
		elif _site_overlay.visible:
			_site_overlay.hide()
		else:
			Campaign.clock_running = true
			SceneRouter.go_to(SceneRouter.HQ)


func select_slot(slot_id: String) -> void:
	if _locked or slot_id.is_empty():
		return
	_cancel_preview()
	_slot_id = slot_id
	var slot := Vehicle.slot(slot_id)
	_ui.title.text = str(slot.get("title", ""))
	_ui.why.text = str(slot.get("why", ""))
	_ui.why.tooltip_text = _ui.why.text
	_hangar.rocket.highlight(slot_id)
	_ui.tray.set_open(true)
	_fill_cards()
	_refresh()
	if slot_id == "spaceport":
		_site_overlay.show()
	else:
		_site_overlay.hide()


func install(part_id: String) -> void:
	if _locked:
		return
	_cancel_preview()
	var was_empty := not _choice.has(_slot_id)
	if _choice.get(_slot_id) == part_id:
		_choice.erase(_slot_id)
	else:
		_choice[_slot_id] = part_id
	_hangar.rocket.set_choice(_choice, _slot_id)
	_hangar.set_site(Vehicle.chosen(_choice, "spaceport"))
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
	for slot: Dictionary in Vehicle.slots():
		var id := str(slot["id"])
		var part := Vehicle.chosen(_choice, id)
		var button: Button = _ui.section_buttons[id]
		var ordinal := Vehicle.slots().find(slot) + 1
		button.text = "%02d  %s%s" % [ordinal, slot["title"], "  +" if not part.is_empty() else ""]
		button.tooltip_text = str(part.get("name", "Unassigned"))
		button.add_theme_color_override("font_color", VisualTheme.AMBER if id == _slot_id else (VisualTheme.PAPER if not part.is_empty() else VisualTheme.MUTED))
		(button as TactileButton)._sync_face()
	var left := Vehicle.missing(_choice)
	_ui.progress.text = "%d of %d sections filled" % [Vehicle.slots().size() - left, Vehicle.slots().size()]
	_ui.budget.text = "BUDGET AFTER DESIGN  %s%%" % _num(float(result["budget_after"]))
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

	AnimatedValue.show_value(_values["reliability"], float(result["reliability"]) * 100.0, "%", 1)
	var labels := {"liftoff": "Low thrust-to-weight", "rocket": "Rocket Δv shortfall", "ship": "Spacecraft Δv shortfall", "cargo": "Payload exceeds capacity", "power": "Power shortfall", "suits": "No EVA capability", "late": "Build misses deadline", "range": "Overland launch range"}
	var messages: Array[String] = []
	for key: String in Vehicle.shortfalls(result):
		messages.append(str(labels.get(key, key)))
	_ui.warnings.text = "ENGINEERING ADVISORIES\n" + "\n".join(PackedStringArray(messages)) if not messages.is_empty() else "Engineering checks clear"
	var part := Vehicle.chosen(_choice, _slot_id)
	_ui.callout.text = str(Vehicle.slot(_slot_id).get("title", "")).to_upper() + "\n" + str(part.get("name", "AWAITING HARDWARE"))
	_ui.callout.size = Vector2(280, 0)
	_ui.callout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _set_value(key: String, text: String) -> void:
	(_values[key] as Label).text = text


func _set_gauge(key: String, have: float, need: float, text: String) -> void:
	var label: Label = _values[key]
	var gauge: GaugeBar = _gauges[key]
	if _metric_tweens.has(key):
		(_metric_tweens[key] as Tween).kill()
	var start := Vector2(gauge.have, gauge.need)
	var target := Vector2(have, need)
	label.set_meta("engineering_target", target)
	label.set_meta("engineering_text", text)
	if GameSettings.reduced_motion() or start.is_equal_approx(target) or text.begins_with("—") or start.y == 0:
		gauge.have = have
		gauge.need = need
		label.text = text
		return
	var animation := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_metric_tweens[key] = animation
	animation.tween_method(func(weight: float) -> void:
		var shown := start.lerp(target, weight)
		gauge.have = shown.x
		gauge.need = shown.y
		match key:
			"rocket", "ship": label.text = "%.2f km/s  ·  needs %.2f" % [shown.x, shown.y]
			"cargo": label.text = "carries %d kg  ·  needs %d" % [roundi(shown.x), roundi(shown.y)]
			"power": label.text = "gives %s kW  ·  needs %s" % [_num(shown.x), _num2(shown.y)]
	, 0.0, 1.0, 0.24)
	animation.tween_callback(func() -> void: label.text = text)


func _show_details(part: Dictionary) -> void:
	var topic: Dictionary = (part.get("read_more", {}) as Dictionary).duplicate()
	if topic.is_empty():
		return
	topic["title"] = str(part.get("name", ""))
	topic["image"] = SITE_ART % part["picture"] if part.has("picture") else THUMBS % part.get("id", "")
	topic["image_note"] = str(Vehicle.rules().get("image_note", ""))
	_read_more.offer(topic)
	_read_more.open()


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


func _on_hand_over_pressed() -> void:
	if _locked or _hand_over.disabled:
		return
	_locked = true
	_hand_over.disabled = true
	_hand_over.text = "Handed over"
	_read_more.clear()
	Vehicle.hand_over(_choice)
	Campaign.clock_running = true
	_status.text = "Design frozen  /  %s" % Campaign.date_text()
	await get_tree().create_timer(0.7).timeout
	SceneRouter.go_to(SceneRouter.HQ, 0.6)


func _fill_cards() -> void:
	for child in _ui.cards.get_children():
		_ui.cards.remove_child(child)
		child.queue_free()
	_option_cards.clear()
	if _slot_id == "spaceport":
		for part: Dictionary in Vehicle.slot("spaceport").get("parts", []):
			var button := _ui.button(str(part["name"]) + "  ↗", 72)
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.pressed.connect(show_site.bind(str(part["id"])))
			_ui.cards.add_child(button)
		_map.chosen = str(_choice.get("spaceport", ""))
		if _shown_site.is_empty():
			_shown_site = _map.chosen
		_fill_site_info()
		return
	for part: Dictionary in Vehicle.slot(_slot_id).get("parts", []):
		var card := AssemblyOptionCard.new()
		card.part = part
		card.installed = _choice.get(_slot_id) == part["id"]
		card.install_requested.connect(install.bind(str(part["id"])))
		card.pressed.connect(_on_card_pressed.bind(str(part["id"])))
		card.details_requested.connect(_ui.show_sheet.bind(part))
		card.mouse_entered.connect(_queue_preview.bind(str(part["id"])))
		card.focus_entered.connect(_queue_preview.bind(str(part["id"])))
		card.mouse_exited.connect(_cancel_preview)
		card.focus_exited.connect(_cancel_preview)
		_ui.cards.add_child(card)
		_option_cards.append(card)


func _on_card_pressed(part_id: String) -> void:
	if _choice.get(_slot_id) != part_id:
		install(part_id)
	else:
		for card in _option_cards:
			card.set_pressed_no_signal(card.installed)
			card._sync_face()


func _queue_preview(part_id: String) -> void:
	if _locked:
		return
	_pending_part = part_id
	_pending_slot = _slot_id
	_hover_timer.start()


func _show_preview() -> void:
	if _locked or _pending_slot != _slot_id or _pending_part.is_empty():
		return
	_hangar.rocket.preview(_slot_id, _pending_part)
	var part := Vehicle.chosen({_slot_id: _pending_part}, _slot_id)
	var installed := Vehicle.chosen(_choice, _slot_id)
	_ui.callout.text = "PREVIEW  /  " + str(part.get("name", "")) + "\n" + ("Replaces " + str(installed["name"]) if not installed.is_empty() else "Empty bay") + "\nClick Install to fit"
	_ui.callout.size = Vector2(280, 0)
	_ui.callout.add_theme_color_override("font_color", VisualTheme.CYAN)


func _cancel_preview() -> void:
	if _hover_timer:
		_hover_timer.stop()
	_pending_part = ""
	_pending_slot = ""
	_hangar.rocket.clear_preview()
	if not _slot_id.is_empty():
		var part := Vehicle.chosen(_choice, _slot_id)
		_ui.callout.text = str(Vehicle.slot(_slot_id).get("title", "")).to_upper() + "\n" + str(part.get("name", "AWAITING HARDWARE"))
		_ui.callout.size = Vector2(280, 0)
		_ui.callout.add_theme_color_override("font_color", VisualTheme.AMBER)


func _build_site_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 44
	add_child(layer)
	_site_overlay = Control.new()
	_site_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_site_overlay)
	var dark := ColorRect.new()
	dark.color = Color(0.015, 0.035, 0.065, 0.8)
	dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_site_overlay.add_child(dark)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + edge, 110)
	for edge: String in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 100)
	_site_overlay.add_child(margin)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", VisualTheme.surface(Color("122738"), VisualTheme.CYAN, 24))
	margin.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var close := _ui.button("LAUNCH SITE SURVEY   /   Close ×", 42)
	close.pressed.connect(_site_overlay.hide)
	box.add_child(close)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(columns)
	var map_holder := Control.new()
	map_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_holder.size_flags_stretch_ratio = 1.7
	columns.add_child(map_holder)
	_map = LaunchMap.new()
	_map.sites = Vehicle.slot("spaceport").get("parts", [])
	_map.site_clicked.connect(show_site)
	map_holder.add_child(_map)
	map_holder.resized.connect(func() -> void:
		var width := minf(map_holder.size.x, map_holder.size.y * MAP_RATIO)
		_map.size = Vector2(width, width / MAP_RATIO)
		_map.position.y = (map_holder.size.y - _map.size.y) * 0.5)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(scroll)
	_site_info = VBoxContainer.new()
	_site_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_site_info.add_theme_constant_override("separation", 10)
	scroll.add_child(_site_info)
	_fill_site_info()
	_site_overlay.hide()


func show_site(site_id: String) -> void:
	if _locked or _slot_id != "spaceport":
		return
	_shown_site = site_id
	_map.shown = site_id
	_site_overlay.show()
	_fill_site_info()


func _fill_site_info() -> void:
	for child in _site_info.get_children():
		_site_info.remove_child(child)
		child.queue_free()
	var part := Vehicle.chosen({"spaceport": _shown_site}, "spaceport")
	_map.shown = _shown_site
	var title := _ui.label(str(part.get("name", "Five places NASA launches from")), 30, VisualTheme.PAPER, VisualTheme.DISPLAY)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_site_info.add_child(title)
	var explanation := str(part.get("what", "Each red dot is a real launch site in the United States. Pick one to see what it offers. The white fan on the map shows the directions in which rockets may be launched from it. Orbit tilt is the angle between an orbit and the equator. NASA also launches small rockets from Kwajalein Atoll in the Pacific, far outside this map."))
	var text := _ui.label(explanation, 19, VisualTheme.MUTED)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_site_info.add_child(text)
	if not part.is_empty():
		for spec: Array in part.get("specs", []):
			var value := _ui.label("%s    %s" % [spec[0], spec[1]], 17, VisualTheme.PAPER)
			value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_site_info.add_child(value)
		var read := _ui.button("Read the science & history  ›", 42)
		read.pressed.connect(_show_details.bind(part))
		_site_info.add_child(read)
		var action := _ui.button("Remove" if _choice.get("spaceport") == part["id"] else "Launch from here", 50)
		action.pressed.connect(install.bind(str(part["id"])))
		_site_info.add_child(action)
	for site: Dictionary in Vehicle.slot("spaceport").get("parts", []):
		var select := _ui.button(str(site["name"]), 38)
		select.pressed.connect(show_site.bind(str(site["id"])))
		_site_info.add_child(select)
