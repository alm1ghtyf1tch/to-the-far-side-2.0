extends "res://tests/phase4_smoke.gd"
## Native mode/agency/science/procurement/flight path using approved scene classes.


func _run() -> void:
	create_timer(180).timeout.connect(func() -> void:
		push_error("Rogue UI integration timed out")
		quit(1))
	RogueRun.save_path = "res://.godot/rogue-ui-test.json"
	_shell = load("res://systems/rendering/presentation_shell.tscn").instantiate()
	root.add_child(_shell)
	current_scene = _shell
	await _frames(5)
	GameSettings.apply_display(Vector2i(1920, 1080), GameSettings.BORDERLESS)
	GameSettings.set_visuals({"dynamic_movement": false, "curvature": 0.35})
	_shell.open_screen(SceneRouter.PROGRAMMES)
	await _frames(6)
	var modes: Control = _shell.active_screen
	await _press(modes, "Story Campaign / original authored lunar mission")
	await _route(SceneRouter.HQ)
	_check(Campaign.stage == 1, "Story selection keeps original new-campaign entry")
	_shell.open_screen(SceneRouter.PROGRAMMES)
	await _frames(6)
	modes = _shell.active_screen
	await _press(modes, "Rogue Rocket / create a space agency")
	await _frames(3)
	var inputs: Array[Node] = modes._body.find_children("*", "LineEdit", true, false)
	inputs[0].text = "Native Test Agency"
	inputs[1].text = "horizon-11"
	await _press(modes, "Start new run / replace saved Rogue run")
	await _route(SceneRouter.ROGUE_HQ)
	var hq: Control = _shell.active_screen
	await _press(hq, "Choose mission contract")
	await _frames(4)
	await _press(hq._desk["root"], "Accept this contract")
	await _frames(5)
	_check(RogueRun.state["phase"] == "planning", "Native agency and contract creation")
	await _press(hq, "Agency / procurement / workbench")
	await _frames(4)
	var event: Dictionary = RogueRun.state["pending_event"]
	await _press(hq._desk["root"], str(event["choices"][-1]["name"]))
	await _frames(4)
	_check(RogueRun.state["pending_event"].is_empty(), "Native event resolution")
	await _press(hq._desk["root"], "AGENCY / PROCUREMENT / OPERATIONS  /  Close")
	await _frames(3)
	await _press(hq, "Moon / science payload")
	await _route(SceneRouter.ROGUE_SCIENCE)
	var planner: Control = _shell.active_screen
	await _click(planner._ui.confirm.get_global_rect().get_center(), _shell._curvature)
	await _frames(4)
	for id: String in RogueResearch.required_ids(RogueRun.state):
		for index in Campaign.instrument_options().size():
			if Campaign.instrument_options()[index]["id"] == id:
				await _control(planner._gear_cards[index])
	await _control(planner._ui.confirm)
	await _route(SceneRouter.ROGUE_HQ)
	_check(RogueRun.state["science_confirmed"], "Native Moon and payload confirmation")
	hq = _shell.active_screen
	await _press(hq, "Engineering / component draft")
	await _route(SceneRouter.ROGUE_ASSEMBLY)
	var assembly: Control = _shell.active_screen
	var baseline := RogueCatalog.baseline(RogueRun.state["contract"])
	assembly.select_slot("stage1")
	await create_timer(0.3).timeout
	var found := false
	for card: AssemblyOptionCard in assembly._option_cards:
		if card.part["id"] == baseline["stage1"]:
			await _control(card)
			found = true
			break
	_check(found and RogueRun.state["vehicle"].get("stage1") == baseline["stage1"], "Native draft card purchases and installs once")
	# Fill the rest with the same real public transactions to keep this UI test short.
	for slot: String in baseline:
		if int(RogueRun.state["inventory"].get(baseline[slot], 0)) == 0:
			_check(RogueRun.purchase(slot, baseline[slot]), "Real component procurement: " + slot)
		if RogueRun.state["vehicle"].get(slot) != baseline[slot]:
			_check(RogueRun.install(slot, baseline[slot]), "Real component installation: " + slot)
	assembly._choice = RogueRun.state["vehicle"]
	assembly._hangar.rocket.set_choice(assembly._choice, "", false)
	assembly._refresh()
	var saved_state: Dictionary = RogueRun.state.duplicate(true)
	for settings: Dictionary in [{"crt_enabled": false}, {"crt_enabled": true, "curvature": 1.0, "dynamic_movement": true, "movement_strength": 1.0}, {"reduced_motion": true}]:
		GameSettings.set_visuals(settings)
		await create_timer(0.3).timeout
		await _control(assembly._ui.metrics.tab)
		_check(not assembly._ui.metrics.opened, "Run overlay input at CRT/movement preference")
		await _control(assembly._ui.metrics.tab)
		_check(assembly._ui.metrics.opened, "Run overlay reopens at CRT/movement preference")
		_check(RogueRun.state == saved_state, "Display/animation preferences do not consume offers, resources or gameplay randomness")
	GameSettings.set_visuals({"crt_enabled": true, "curvature": 0.35, "dynamic_movement": false, "reduced_motion": false})
	await _capture("run-assembly")
	await _control(assembly._hand_over)
	await _route(SceneRouter.ROGUE_HQ)
	hq = _shell.active_screen
	await _press(hq, "Authorize launch / Mission Control")
	await _route(SceneRouter.ROGUE_CONTROL)
	mission = _shell.active_screen
	mission._timer.stop()
	_camera_pose = mission._view.space.camera.transform
	_check(mission._view.get_global_rect() == mission.get_global_rect(), "Run observation scene is full-bleed")
	await _control(mission._dashboard_tab)
	_check(not mission._dashboard_panel.visible, "Floating dashboard retracts")
	await _control(mission._dashboard_tab)
	_check(mission._dashboard_panel.visible, "Floating dashboard reopens")
	await _control(mission._gate_yes)
	mission._timer.stop()
	await _rogue_until("coast")
	_check(mission._commands_open and mission._command_phase == "coast", "Outbound command window appears")
	await _control(mission._command_sheet["close"])
	mission._timer.stop()
	# Save/re-enter at the same boundary; original result and offers cannot reroll.
	var outcome: Dictionary = Flight.result.duplicate(true)
	mission._save_return()
	await _route(SceneRouter.ROGUE_HQ)
	await _press(_shell.active_screen, "Resume Mission Control")
	await _route(SceneRouter.ROGUE_CONTROL)
	mission = _shell.active_screen
	mission._timer.stop()
	_check(Flight.result == outcome, "In-session flight return does not reroll outcome")
	await _rogue_until("surface")
	if mission._commands_open:
		var objective := str(RogueRun.state["contract"]["objective"])
		var research := RogueCatalog.find("objectives", objective)
		await _press(mission._command_sheet["root"], "%s / %d work / +%d knowledge" % [research["name"], research["work"], research["knowledge"]])
		await _frames(3)
		_check((RogueRun.state["science_done"] as Array).has(objective), "Native science work allocation")
		await _control(mission._command_sheet["close"])
		mission._timer.stop()
	await _rogue_drain()
	_check(mission._finished, "Actual mission presentation terminates")
	await _capture("run-flight")
	await _control(mission._report_button)
	await _route(SceneRouter.ROGUE_HQ)
	_check(RogueRun.state["history"].size() == 1, "One actual agency mission evaluation")
	await _press(_shell.active_screen, "Agency results / mission history")
	await _capture("run-results")
	# Return to Story and ensure the separate session survived.
	RogueRun.suspend()
	_check(Campaign.stage == 1 and Campaign.budget_left == 100, "Rogue departure restores Story session")
	if _failures.is_empty():
		print("PASS: native programme/agency/contract, event, Moon, paid draft, fullscreen flight, dashboard collapse, phase resume, commands, focused science and agency report")
		quit()
	else:
		quit(1)


func _rogue_until(phase_id: String) -> void:
	for attempt in 220:
		if mission._commands_open and mission._command_phase == phase_id:
			return
		if mission._finished:
			return
		await _rogue_advance()
	_check(false, "Reached run phase " + phase_id)


func _rogue_drain() -> void:
	for attempt in 220:
		if mission._finished:
			return
		await _rogue_advance()
	_check(false, "Rogue mission ended")


func _rogue_advance() -> void:
	if mission._commands_open:
		await _control(mission._command_sheet["close"])
	elif mission._gate != "":
		mission.choose(false)
	else:
		mission.next_line()
	mission._timer.stop()
	await _frames(1)
	_check(mission._view.space.camera.transform == _camera_pose, "Run flight camera remains fixed")


func _press(node: Node, text: String) -> void:
	var button := _find_button(node, text)
	_check(button != null, "Button exists: " + text)
	if button:
		await _control(button)


func _find_button(node: Node, text: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == text:
			return child
		var found := _find_button(child, text)
		if found:
			return found
	return null


func _control(control: Control) -> void:
	var parent := control.get_parent()
	while parent:
		if parent is ScrollContainer:
			parent.ensure_control_visible(control)
			await _frames(3)
			break
		parent = parent.get_parent()
	await _click(control.get_global_rect().get_center(), _shell._curvature)
	await _frames(3)


func _route(path: String) -> void:
	var deadline := Time.get_ticks_msec() + 5000
	while Time.get_ticks_msec() < deadline:
		if _shell.active_screen.scene_file_path == path and not root.get_node("SceneRouter").is_busy():
			await _frames(5)
			return
		await process_frame
	_check(false, "Route reached: " + path)


func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/rogue-ui-%s.png" % label)
