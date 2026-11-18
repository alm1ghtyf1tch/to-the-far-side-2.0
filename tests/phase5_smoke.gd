extends "res://tests/presentation_smoke.gd"
## Real compositor/native input, catalogue coverage and original commit semantics.

var assembly: Control
var _preset := {}


func _run() -> void:
	create_timer(150).timeout.connect(func() -> void:
		push_error("Phase 5 integration timed out")
		quit(1))
	Flight.quick_start(10)
	_preset = Vehicle.design.duplicate()
	Campaign.stage = 6
	Campaign.clock_running = false
	Campaign.budget_left = 80.0
	Vehicle.draft = {}
	_shell = load("res://systems/rendering/presentation_shell.tscn").instantiate()
	root.add_child(_shell)
	current_scene = _shell
	await _frames(5)
	GameSettings.apply_display(Vector2i(1920, 1080), GameSettings.BORDERLESS)
	GameSettings.set_visuals(GameSettings.VISUAL_DEFAULTS)
	GameSettings.set_visuals({"dynamic_movement": false})
	await _mount()
	await _empty_build()
	await _catalogue()
	await _cards_and_picking()
	await _launch_sites()
	await _warnings_and_metrics()
	await _display_checks()
	await _benchmark()
	await _draft_return()
	await _handover()
	if _failures.is_empty():
		print("PASS: Phase 5 14 sections/52 options, previews, install/remove, picking, original metrics/warnings, five sites, sheets, CRT, native modes, draft return and one-time handover")
		quit()
	else:
		push_error("FAIL: %d Phase 5 checks" % _failures.size())
		quit(1)


func _mount() -> void:
	_shell.open_screen(SceneRouter.ENGINEERING)
	await _frames(6)
	assembly = _shell.active_screen
	# A native window can open beneath the desktop cursor and legitimately start
	# a hover preview. Establish a neutral pointer before testing actual hardware.
	await _hover(Vector2(550, 140))
	assembly._cancel_preview()
	_check(assembly._shell.image.get_global_rect() == assembly.get_global_rect(), "World is full-bleed")
	_check(assembly._shell.viewport_3d.own_world_3d, "Assembly world is isolated")


func _state() -> Array:
	return [Campaign.stage, Campaign.days, Campaign.budget_left, Vehicle.design.duplicate(true), Vehicle.stats.duplicate(true), Vehicle.reliability, Operations.choices.duplicate(true), Flight.build.duplicate(true), Flight.result.duplicate(true)]


func _empty_build() -> void:
	_check(assembly._ui.section_buttons.size() == 14, "All original sections")
	_check(assembly._hand_over.disabled, "Empty design cannot hand over")
	_check(assembly._hangar.rocket.parts.is_empty(), "Empty draft never invents installed hardware")
	_check(assembly._hangar.rocket._ghosts.size() == 7, "Empty axial bays have construction guides")
	var before := _state()
	assembly._on_hand_over_pressed()
	_check(_state() == before, "Disabled commit cannot charge or advance")
	assembly.install("s1_five")
	_check(Vehicle.draft.get("stage1") == "s1_five", "Original draft reference persists installation")
	await create_timer(0.65).timeout
	_check(assembly._slot_id == "stage2", "Original auto-next after filling an empty section")
	assembly.select_slot("stage1")
	assembly.install("s1_five")
	await create_timer(0.25).timeout
	_check(not Vehicle.draft.has("stage1") and not assembly._hangar.rocket.parts.has("stage1"), "Removing leaves the real bay empty")
	_check(_state() == before, "Editing never changes committed design, budget, time or simulation")
	Vehicle.draft.merge(_preset, true)
	assembly._hangar.rocket.set_choice(Vehicle.draft, "", false)
	assembly.select_slot("stage1")


func _catalogue() -> void:
	var before := _state()
	var draft := Vehicle.draft.duplicate()
	var count := 0
	for slot: Dictionary in Vehicle.slots():
		var id := str(slot["id"])
		assembly.select_slot(id)
		await _frames(2)
		if id != "spaceport":
			_check(assembly._option_cards.size() == slot["parts"].size(), "All cards: " + id)
		for part: Dictionary in slot["parts"]:
			count += 1
			assembly._hangar.rocket.preview(id, str(part["id"]))
			var visual: AssemblyRocket = assembly._hangar.rocket
			_check(visual.rendered.get(id) == part["id"], "Provisional variant: " + str(part["id"]))
			if visual.parts.has(id):
				_check(visual.parts[id].get_meta("part_id") == part["id"], "Model identity: " + str(part["id"]))
			_check(Vehicle.draft == draft and _state() == before, "Preview is read-only: " + str(part["id"]))
			assembly._ui.show_sheet(part)
			_check(assembly._ui._sheet_specs.get_child_count() == part.get("specs", []).size(), "All source specs retained: " + str(part["id"]))
			assembly._ui.sheet.hide()
			visual.clear_preview()
			_check(visual.rendered == draft, "Preview restores actual draft")
	_check(count == 52, "All 52 original options")
	assembly.select_slot("stage1")
	var visual: AssemblyRocket = assembly._hangar.rocket
	for part: Dictionary in Vehicle.slot("stage1")["parts"]:
		assembly.install(str(part["id"]))
		visual.preview("stage1", "s1_four")
		visual.clear_preview()
	assembly.install("s1_five")
	await create_timer(0.5).timeout
	_check(visual.parts["stage1"].get_meta("part_id") == Vehicle.draft["stage1"], "Rapid comparison settles on the actual part")
	for slot: String in visual.parts:
		_check(visual.parts[slot].visible and visual.parts[slot].scale.length() > 0.1, "Final modules settle visibly: " + slot)
	var visible_count := 0
	for object: Node3D in visual._cache.values():
		if object.visible:
			visible_count += 1
	_check(visible_count == visual.parts.size(), "No duplicated or stale variants remain visible")


func _cards_and_picking() -> void:
	assembly.select_slot("stage1")
	await create_timer(0.3).timeout
	var card: AssemblyOptionCard = assembly._option_cards[0]
	await _hover(card.get_global_rect().get_center())
	await create_timer(0.2).timeout
	_check(assembly._hangar.rocket.preview_id == card.part["id"], "Native hover previews after dwell")
	await _hover(Vector2(550, 160))
	_check(assembly._hangar.rocket.preview_id.is_empty(), "Native exit restores actual hardware")
	# Root click on an already installed card must preserve the original behavior.
	var saved := Vehicle.draft.duplicate()
	await _click(card.get_global_rect().position + Vector2(40, 20), _shell._curvature)
	_check(Vehicle.draft == saved, "Installed card root does not remove hardware")
	var sheet := _find_button(card, "Sheet ›")
	await _click(sheet.get_global_rect().get_center(), _shell._curvature)
	_check(assembly._ui.sheet.visible, "Nested technical-sheet action opens without installing")
	_check(Vehicle.draft == saved, "Sheet action never propagates to parent install")
	_check(assembly._ui._sheet_specs.get_child_count() == card.part["specs"].size(), "Complete original technical specifications")
	var read := _find_button(assembly._ui.sheet, "Read the science & history  ›")
	await _click(read.get_global_rect().get_center(), _shell._curvature)
	await create_timer(0.3).timeout
	_check(assembly._read_more.is_open(), "Original illustrated educational notes remain available")
	assembly._read_more.close()
	assembly._ui.sheet.hide()
	await create_timer(0.3).timeout
	var remove := _find_button(card, "Remove")
	await _click(remove.get_global_rect().get_center(), _shell._curvature)
	_check(not Vehicle.draft.has("stage1"), "Nested Remove fires exactly once")
	await _frames(3)
	var install := _find_button(assembly._option_cards[0], "Install")
	await _click(install.get_global_rect().get_center(), _shell._curvature)
	_check(Vehicle.draft.get("stage1") == "s1_five", "Nested Install fires exactly once")
	await create_timer(0.5).timeout
	var pixel: Vector2 = assembly._hangar.camera.unproject_position(assembly._hangar.rocket.centre_of("stage2"))
	var logical: Vector2 = pixel / Vector2(assembly._shell.viewport_3d.size) * assembly.size
	await _click(logical, _shell._curvature)
	_check(assembly._slot_id == "stage2", "Clicking physical second stage selects its engineering section")


func _launch_sites() -> void:
	assembly.select_slot("spaceport")
	# Switch between complete designs; erasing the port directly would leave old
	# delayed auto-next callbacks racing this artificial test-only missing slot.
	assembly.install("port_wallops")
	await _frames(4)
	for part: Dictionary in Vehicle.slot("spaceport")["parts"]:
		var draft := Vehicle.draft.duplicate()
		var before := _state()
		var point: Vector2 = assembly._map.get_global_rect().position + assembly._map.point_of(part)
		await _click(point, _shell._curvature)
		_check(assembly._shown_site == part["id"], "Native map dot: " + str(part["id"]))
		_check(Vehicle.draft == draft and _state() == before, "Site survey does not commit a site")
		var action := _find_button(assembly._site_info, "Launch from here")
		(assembly._site_info.get_parent() as ScrollContainer).ensure_control_visible(action)
		await _frames(3)
		_check((assembly._site_info.get_parent() as Control).get_global_rect().encloses(action.get_global_rect()), "Site action is scrolled into view")
		await _click(action.get_global_rect().get_center(), _shell._curvature)
		_check(Vehicle.draft.get("spaceport") == part["id"], "Original launch-site install: " + str(part["id"]))
		_check(assembly._map.chosen == part["id"], "Map distinguishes installed site")
		# Avoid original delayed auto-next during this explicit site-by-site fixture.
		assembly.select_slot("stage1")
		assembly.select_slot("spaceport")
	assembly.select_slot("stage1")


func _warnings_and_metrics() -> void:
	assembly._choice.merge(_preset, true)
	assembly._choice["stage1"] = "s1_four"
	assembly._choice["power"] = "power_batteries"
	assembly._choice["suits"] = "suits_cabin"
	assembly._choice["spaceport"] = "port_whitesands"
	assembly._hangar.rocket.set_choice(assembly._choice)
	assembly._refresh()
	await create_timer(0.35).timeout
	var result := Vehicle.evaluate(Vehicle.draft)
	var shortfalls := Vehicle.shortfalls(result)
	_check(shortfalls.has("suits") and shortfalls.has("range"), "Real catalogue creates warning-producing design")
	_check(assembly._ui.warnings.text.contains("No EVA capability") and assembly._ui.warnings.text.contains("Overland launch range"), "Advisories expose actual shortfalls")
	_check(not assembly._hand_over.disabled, "Original rules permit complete affordable designs with advisories")
	for row: Array in [["rocket", "rocket_dv", "rocket_need"], ["ship", "ship_dv", "ship_need"], ["cargo", "cargo_capacity", "cargo_need"], ["power", "power_have", "power_need"]]:
		var gauge: GaugeBar = assembly._gauges[row[0]]
		_check(is_equal_approx(gauge.have, result[row[1]]) and is_equal_approx(gauge.need, result[row[2]]), "Authoritative animated gauge: " + str(row[0]))
		_check(assembly._values[row[0]].text == assembly._values[row[0]].get_meta("engineering_text"), "Animated number settles exactly")
	_check(assembly._values["liftoff"].text.contains("%.2f" % result["thrust_to_weight"]), "Original TWR precision")
	_check(assembly._values["ready"].text.contains(Campaign.date_text(int(result["ready_day"]))), "Original readiness date")
	var budget := Campaign.budget_left
	Campaign.budget_left = 0
	assembly._refresh()
	_check(assembly._hand_over.disabled, "Unaffordable full design cannot hand over")
	var before := _state()
	assembly._on_hand_over_pressed()
	_check(_state() == before, "Unaffordable handover does not commit")
	Campaign.budget_left = budget
	assembly._refresh()
	await _capture("warnings")


func _display_checks() -> void:
	for configuration: Dictionary in [{"crt_enabled": false}, {"crt_enabled": true, "curvature": 1.0, "dynamic_movement": true, "movement_strength": 1.0}, {"reduced_motion": true}]:
		GameSettings.set_visuals(configuration)
		await create_timer(0.3).timeout
		for panel: RetractablePanel in [assembly._ui.sections, assembly._ui.metrics, assembly._ui.tray]:
			await _click(panel.tab.get_global_rect().get_center(), _shell._curvature)
			await create_timer(0.27).timeout
			_check(not panel.opened and not panel.surface.visible, "Native collapse with CRT/motion settings")
			await _click(panel.tab.get_global_rect().get_center(), _shell._curvature)
			await create_timer(0.27).timeout
			_check(panel.opened and panel.surface.visible, "Tab reopens panel with CRT/motion settings")
		_check(assembly._shell.image.get_global_rect() == assembly.get_global_rect(), "Panel changes never shrink the scene")
		if GameSettings.reduced_motion():
			assembly.select_slot("stage1")
			assembly.install("s1_thirty")
			var model: Node3D = assembly._hangar.rocket.parts["stage1"]
			_check(model.position == model.get_meta("rest_position"), "Reduced motion installs without a displaced intermediate pose")
	GameSettings.set_visuals({"reduced_motion": false, "dynamic_movement": false, "curvature": 0.35})
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]:
		GameSettings.apply_display(dimensions, GameSettings.WINDOWED)
		if DisplayServer.get_name() == "headless":
			root.size = dimensions
		await create_timer(0.35).timeout
		_check(assembly.get_global_rect().encloses(assembly._hand_over.get_global_rect()), "Handover fits " + str(dimensions))
		_check(assembly.get_global_rect().encloses(assembly._ui.tray.get_global_rect()), "Tray fits " + str(dimensions))
		print("Phase 5 display: requested %s, actual %s" % [dimensions, DisplayServer.window_get_size()])
		await _click(assembly._ui.metrics.tab.get_global_rect().get_center(), _shell._curvature)
		_check(not assembly._ui.metrics.opened, "Native input after resize")
		assembly._ui.metrics.set_open(true, true)
		await _capture("window-%d" % dimensions.x)
	for mode: String in [GameSettings.BORDERLESS, GameSettings.EXCLUSIVE]:
		GameSettings.apply_display(Vector2i(1920, 1080), mode)
		await create_timer(0.35).timeout
		if DisplayServer.get_name() != "headless":
			_check(DisplayServer.window_get_mode() == (DisplayServer.WINDOW_MODE_FULLSCREEN if mode == GameSettings.BORDERLESS else DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN), "Actual native mode: " + mode)
		await _click(assembly._ui.metrics.tab.get_global_rect().get_center(), _shell._curvature)
		_check(not assembly._ui.metrics.opened, "Input in " + mode)
		assembly._ui.metrics.set_open(true, true)
	GameSettings.apply_display(Vector2i(1920, 1080), GameSettings.BORDERLESS)
	assembly._ui.toggle_focus()
	await create_timer(0.3).timeout
	_check(not assembly._ui.sections.opened and not assembly._ui.tray.opened, "Focus retracts edge controls")
	await _capture("focus")
	assembly._ui.toggle_focus()


func _draft_return() -> void:
	var draft := Vehicle.draft.duplicate()
	var before := _state()
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	assembly._unhandled_input(cancel)
	await create_timer(1.1).timeout
	_check(_shell.active_screen.scene_file_path == SceneRouter.HQ and Vehicle.draft == draft, "Esc returns to HQ and retains draft")
	# HQ clock runs by the original rule; freeze it before checking re-entry.
	Campaign.clock_running = false
	await _mount()
	_check(assembly._choice == draft and Vehicle.design == before[3], "Re-entry restores draft without committing")


func _handover() -> void:
	Campaign.budget_left = 80.0
	assembly._refresh()
	var expected := Vehicle.evaluate(Vehicle.draft)
	var budget := Campaign.budget_left
	var days := Campaign.days
	var draft := Vehicle.draft.duplicate()
	await _click(assembly._hand_over.get_global_rect().get_center(), _shell._curvature)
	assembly._on_hand_over_pressed()
	_check(Campaign.stage == 7 and Vehicle.design == draft and Vehicle.stats == expected, "Original handover freezes exact authoritative design/stats")
	_check(is_equal_approx(Campaign.budget_left, budget - float(expected["cost"])), "Budget charged exactly once")
	_check(Campaign.days == days and Campaign.clock_running, "Original commit does not invent build-time charge")
	await create_timer(1.5).timeout
	_check(_shell.active_screen.scene_file_path == SceneRouter.HQ, "Handover returns to HQ")


func _benchmark() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await _frames(20)
	var times: Array[float] = []
	var previous := Time.get_ticks_usec()
	for index in 120:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append(float(now - previous) / 1000.0)
		previous = now
	times.sort()
	print("Phase 5 rendered frame intervals: median %.2f ms, p95 %.2f ms (120 frames, local hardware only)" % [times[60], times[114]])


func _find_button(node: Node, text: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == text:
			return child
		var result := _find_button(child, text)
		if result:
			return result
	return null


func _hover(point: Vector2) -> void:
	var source := point / Vector2(_shell.content.size_2d_override)
	var uv := _display_uv(source, _shell._curvature)
	var motion := InputEventMouseMotion.new()
	motion.position = uv * root.get_visible_rect().size
	motion.global_position = motion.position
	root.push_input(motion, true)
	await _frames(1)


func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/phase5-test-%s.png" % label)
