extends "res://tests/presentation_smoke.gd"
## Full Mission Control integration. Fault fixtures and pilot helpers are test-only.

var mission: Control
var _camera_pose: Transform3D


func _run() -> void:
	create_timer(150).timeout.connect(func() -> void:
		push_error("Phase 4 integration timed out")
		quit(1))
	_shell = load("res://systems/rendering/presentation_shell.tscn").instantiate()
	root.add_child(_shell)
	current_scene = _shell
	await _frames(5)
	GameSettings.apply_display(Vector2i(1920, 1080), GameSettings.BORDERLESS)
	GameSettings.set_visuals(GameSettings.VISUAL_DEFAULTS)
	GameSettings.set_visuals({"dynamic_movement": false})
	_model_checks()
	await _automatic_scenarios()
	await _manual_staging()
	await _mistimed_staging()
	await _manual_landing(true)
	await _manual_landing(false)
	await _display_and_skip()
	if _failures.is_empty():
		print("PASS: Phase 4 full mission, fixed camera, configuration, failures, original staging/landing, pause, decisions, CRT input, modes, skip and report")
		quit()
	else:
		push_error("FAIL: %d Phase 4 checks" % _failures.size())
		quit(1)


func _state() -> Array:
	return [Campaign.stage, Campaign.days, Campaign.budget_left, Campaign.calc_round, Campaign._check_sum, Vehicle.design.duplicate(true), Vehicle.stats.duplicate(true), Operations.choices.duplicate(true), Flight.build.duplicate(true), Flight.result.duplicate(true)]


func _model_checks() -> void:
	var models := SpacecraftModels.new()
	for entry: Array in [["stage1", "s1_five", 5], ["stage1", "s1_four", 4], ["stage1", "s1_thirty", 30], ["stage2", "s2_core", 4], ["stage3", "s3_twin", 2]]:
		var model := models.module(entry[0], Vehicle.chosen({entry[0]: entry[1]}, entry[0]))
		root.add_child(model)
		model.hide()
		var anchors := model.find_children("Exhaust*", "Node3D", true, false)
		var positions := {}
		for anchor: Node3D in anchors:
			positions[anchor.global_position.snapped(Vector3.ONE * 0.0001)] = true
		_check(anchors.size() == entry[2] and positions.size() == entry[2], "Selected engine cluster has distinct physical nozzles: " + str(entry[1]))
		model.free()


func _prepare(latent: Dictionary = {}) -> void:
	Flight.quick_start(10)
	Flight.build["latent"] = latent.duplicate()
	Flight.fly()


func _mount() -> void:
	_shell.open_screen(SceneRouter.MISSION_CONTROL)
	await _frames(6)
	mission = _shell.active_screen
	mission._timer.stop()
	_camera_pose = mission._view.space.camera.transform
	_check(mission._gate == "start", "Original start gate opens")
	_check(mission._view.space.spacecraft.parts["stage1"].get_meta("part_id") == Vehicle.design["stage1"], "Launch model uses selected first stage")
	_check(mission._view.space.spacecraft.lander.get_meta("part_id") == Vehicle.design["lander"], "Lander model uses selected part")


func _advance() -> void:
	if mission._gate != "":
		mission.choose(false)
	else:
		mission.next_line()
	mission._timer.stop()
	await _frames(2)
	_check(mission._view.space.camera.transform == _camera_pose, "Mission camera remains completely fixed")


func _until_gate(kind: String) -> void:
	for attempt in 150:
		if mission._gate == kind:
			return
		if mission._finished:
			break
		await _advance()
	_check(false, "Reached expected decision gate: " + kind)


func _drain() -> void:
	for attempt in 180:
		if mission._finished:
			return
		await _advance()
	_check(false, "Mission presentation reaches completion")


func _automatic_scenarios() -> void:
	for scenario: Dictionary in [{"name": "success", "latent": {}, "outcome": "landed"}, {"name": "first-stage-failure", "latent": {"stage1": true}, "outcome": "launch_abort"}, {"name": "second-stage-failure", "latent": {"stage2": true}, "outcome": "launch_abort"}, {"name": "restart-failure", "latent": {"stage3": true}, "outcome": "earth_orbit"}, {"name": "lunar-engine-failure", "latent": {"service": true}, "outcome": "flyby"}, {"name": "power-and-comms", "latent": {"power": true, "comms": true}, "outcome": "landed"}]:
		_prepare(scenario["latent"])
		_check(Flight.result["outcome"] == scenario["outcome"], "Original scenario fixture: %s" % scenario["name"])
		var before := _state()
		await _mount()
		if scenario["name"] == "success":
			await _click(mission._gate_yes.get_global_rect().get_center(), _shell._curvature)
			_check(mission._gate == "", "Native start choice reaches coordinator once")
			mission._timer.stop()
		await _drain()
		_check(_state() == before, "Playback does not rerun/change simulation: %s" % scenario["name"])
		var count := 0
		for phase: Dictionary in Flight.result["phases"]:
			count += (phase["lines"] as Array).size()
		_check(mission._log_box.get_child_count() == count, "Actual event log appears exactly once")
		_check(mission._view.presentation.event_count == count, "Actual visual cues processed exactly once")
		var craft: SpacecraftVisual = mission._view.space.spacecraft
		_check(craft.engine_target == 0 and craft.engine_amount == 0, "Final engine state is settled")
		_check(craft.recovered, "Surviving crew ends in recovery configuration")
		if scenario["name"] == "success":
			_check(Flight.result["phases"].size() == 10, "All ten original phases remain")
			await _capture("success")
		elif scenario["name"] == "first-stage-failure":
			_check(not craft.separated.has("stage1"), "First-stage failure never shows successful separation")
			await _capture("abort-recovery")
		mission.next_line()
		_check(mission._log_box.get_child_count() == count, "Completed flight ignores repeated advance")
	# Actual complete but underpowered catalogue configuration, rather than forced result data.
	Flight.quick_start(7)
	Vehicle.design["stage1"] = "s1_four"
	Vehicle.stats = Vehicle.evaluate(Vehicle.design)
	Campaign.pass_review()
	var choices := {}
	for item: Dictionary in Operations.items():
		choices[str(item["id"])] = 0
	Operations.confirm(choices)
	Campaign.pass_review()
	Flight.fly()
	_check(Flight.result["outcome"] == "no_launch", "Original no-launch configuration")
	var before := _state()
	await _mount()
	await _drain()
	_check(_state() == before and not mission._view.space.spacecraft.recovered, "No-launch stays on stage and never fabricates recovery")
	_check(mission._view.space.spacecraft.configuration == "launch", "No-launch retains intact launch vehicle")
	await _capture("no-launch")
	# No escape hardware: the same real first-stage fault must not become a rescue.
	Flight.quick_start(10)
	Vehicle.design["escape"] = "escape_none"
	Vehicle.stats = Vehicle.evaluate(Vehicle.design)
	Flight.build["latent"] = {"stage1": true}
	Flight.fly()
	_check(Flight.result["outcome"] == "crew_lost", "Original no-escape failure fixture")
	before = _state()
	await _mount()
	await _drain()
	_check(not mission._view.space.spacecraft.recovered and _state() == before, "Crew loss never shows a successful recovery or changes consequences")
	await _capture("crew-lost")


func _manual_staging() -> void:
	_prepare()
	await _mount()
	mission.choose(true)
	mission._timer.stop()
	await _until_gate("launch")
	await _click(mission._gate_yes.get_global_rect().get_center(), _shell._curvature)
	mission._timer.stop()
	for attempt in 12:
		if mission._game != null:
			break
		await _advance()
	_check(mission._game is StagingGame, "Original manual staging starts in dashboard")
	var game: StagingGame = mission._game
	game._clock = StagingGame.BURN
	_key(KEY_SPACE, true)
	_key(KEY_SPACE, false)
	_check(game._errors.size() == 1 and mission._view.staged == 1, "Space drops exactly one stage using inherited timing")
	await _frames(2)
	_check(mission._view.space.spacecraft.separated.has("stage1"), "Real manual staging drives physical separation")
	game._clock = StagingGame.BURN
	await _click(game._button.get_global_rect().get_center(), _shell._curvature)
	_check(game._errors.size() == 2, "Native staging button handles second stage once")
	mission.set_paused(true)
	var pose: Transform3D = mission._view.space.spacecraft.parts["stage2"].transform
	await create_timer(1.6).timeout
	_check(mission._game != null and not mission._ascent_flown, "Finished staging waits for resume before applying result")
	_check(mission._view.space.spacecraft.parts["stage2"].transform == pose, "Separation animation freezes while paused")
	await _capture("staging-paused")
	mission.set_paused(false)
	mission._timer.stop()
	_check(mission._game == null and mission._ascent_flown, "Resume applies staging result once")
	_check(mission._overrides.get("staging", []).size() == 2, "Original two timing errors reach Flight.fly")
	var after := _state()
	Flight.fly(mission._overrides)
	_check(_state() == after, "Manual staging replay preserves original deterministic result")
	await _drain()


func _manual_landing(favorable: bool) -> void:
	_prepare()
	await _mount()
	mission.choose(true)
	mission._timer.stop()
	await _until_gate("landing")
	await _click(mission._gate_yes.get_global_rect().get_center(), _shell._curvature)
	_check(mission._game is LandingGame, "Original manual landing starts")
	var game: LandingGame = mission._game
	if favorable:
		var engine_button: Button = _find_engine_button(game)
		await _mouse(engine_button.get_global_rect().get_center(), _shell._curvature, true)
		await _frames(2)
		_check(game._hold_engine and game._engine, "Tactile engine hold reaches unchanged landing controls")
		mission.set_paused(true)
		_check(not game._hold_engine, "Pause releases virtual thrust and prevents a stuck pointer hold")
		await _mouse(Vector2(-30, -30), _shell._curvature, false)
		mission.set_paused(false)
	game.process_mode = Node.PROCESS_MODE_DISABLED
	# A reference instance of the untouched original receives the exact same inputs.
	var original := LandingGame.new()
	original.process_mode = Node.PROCESS_MODE_DISABLED
	original.size = Vector2(1020, 600)
	root.add_child(original)
	original.hide()
	original.start(game._setup, str(Campaign.site["id"]))
	_check(original._clear == game._clear and original._rocks == game._rocks, "Seeded landing zones/rocks are unchanged")
	# The native click already allowed one display frame of descent before freezing.
	# Align the reference to that live starting state, then compare identical inputs.
	for field: String in ["_height", "_fall", "_x", "_slide", "_fuel", "_time", "_alarm_left", "_alarm_done", "_engine", "_push", "_hold_engine", "_hold_side"]:
		original.set(field, game.get(field))
	var fields: Array[String] = ["_height", "_fall", "_x", "_slide", "_fuel", "_alarm_left"]
	var captured := false
	for frame in 3600:
		if game._over:
			break
		var engine := false
		var push := 0.0
		if favorable:
			var target_fall := -maxf(0.6, sqrt(2.0 * (LandingGame.THRUST - LandingGame.GRAVITY) * maxf(game._height - 1.0, 0.0)) * 0.65)
			engine = game._fall < target_fall
			var target: float = (game._clear[1].x + game._clear[1].y) * 0.5
			var error: float = target - game._x - game._slide * 2.0
			push = signf(error) if absf(error) > 0.3 else 0.0
		game.steer(engine, push)
		original.steer(engine, push)
		game._process(1.0 / 60.0)
		original._process(1.0 / 60.0)
		if frame % 30 == 0:
			for field: String in fields:
				_check(is_equal_approx(float(game.get(field)), float(original.get(field))), "3D presentation preserves original landing state: " + field)
		if not captured and frame > 100:
			captured = true
			await _frames(3)
			await _capture("manual-landing" if favorable else "landing-abort")
	_check(game._over and original._over, "Both landing implementations terminate")
	_check(game._outcome == original._outcome, "Landing result/fuel/speed exactly match untouched original")
	_check(game._outcome.get("result") == ("landed" if favorable else "abort"), "Favorable/unfavorable manual landing outcome")
	var outcome: Dictionary = game._outcome.duplicate()
	original.queue_free()
	if favorable:
		mission.set_paused(true)
		await create_timer(2.0).timeout
		_check(not mission._landing_flown and mission._game != null, "Landing completion also waits during pause")
		mission.set_paused(false)
	else:
		await create_timer(2.0).timeout
	mission._timer.stop()
	_check(mission._landing_flown and mission._game == null, "Landing result returns to coordinator exactly once")
	_check(mission._overrides.get("landing", {}) == outcome, "Unchanged manual result reaches Flight.fly")
	var after := _state()
	Flight.fly(mission._overrides)
	_check(_state() == after, "Manual landing consequences match original deterministic replay")
	await _drain()


func _mistimed_staging() -> void:
	_prepare()
	await _mount()
	mission.choose(true)
	mission._timer.stop()
	await _until_gate("launch")
	mission.choose(true)
	mission._timer.stop()
	for attempt in 12:
		if mission._game != null:
			break
		await _advance()
	var game: StagingGame = mission._game
	game._clock = StagingGame.BURN - 1.0
	game.press()
	game._clock = StagingGame.BURN + 1.0
	game.press()
	await create_timer(1.6).timeout
	mission._timer.stop()
	var errors: Array = mission._overrides.get("staging", [])
	_check(errors == [-1.0, 1.0], "Early/late staging errors retain their exact original values")
	_check(Flight.staging_gain(float(errors[0])) < 0 and Flight.staging_gain(float(errors[1])) < 0, "Mistimed staging keeps original speed penalties")
	var after := _state()
	Flight.fly(mission._overrides)
	_check(_state() == after, "Negative staging consequences match original deterministic replay")
	await _drain()


func _display_and_skip() -> void:
	_prepare()
	var before := _state()
	await _mount()
	for visuals: Dictionary in [{"crt_enabled": false}, {"crt_enabled": true, "curvature": 1.0, "dynamic_movement": true, "movement_strength": 1.0}, {"reduced_motion": true}]:
		GameSettings.set_visuals(visuals)
		await create_timer(0.3).timeout
		_check(mission._view.space.camera.transform == _camera_pose, "CRT movement and reduced motion never move observation camera")
		_check(_state() == before, "Visual settings cannot change outcomes")
		await _click(mission._ui._details_button.get_global_rect().get_center(), _shell._curvature)
		_check(mission._ui.details.visible, "Actual dashboard click aligns through CRT and screen drift")
		_key(KEY_ESCAPE, true)
		_key(KEY_ESCAPE, false)
		await _frames(2)
		_check(not mission._ui.details.visible, "Escape closes engineering details without leaving mission")
	GameSettings.set_visuals(GameSettings.VISUAL_DEFAULTS)
	for size_value: Vector2i in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]:
		GameSettings.apply_display(size_value, GameSettings.WINDOWED)
		if DisplayServer.get_name() == "headless":
			root.size = size_value
		await create_timer(0.2).timeout
		_check(mission.get_global_rect().encloses(mission._gate_yes.get_global_rect()), "Decision remains visible at %s" % size_value)
	GameSettings.apply_display(Vector2i(1920, 1080), GameSettings.BORDERLESS)
	await create_timer(0.25).timeout
	# Skip keeps the original contract: it chooses the precomputed automatic path.
	mission.skip_to_end()
	await _frames(3)
	_check(mission._finished and mission._game == null and mission._gate == "", "Skip resolves pending gates and ends in a valid state")
	_check(_state() == before, "Skip leaves scientific/campaign results unchanged")
	_check(mission._view.space.spacecraft.configuration == "recovery", "Skip settles directly to actual final configuration")
	await _capture("complete")
	await _benchmark()
	await _click(mission._report_button.get_global_rect().get_center(), _shell._curvature)
	await create_timer(1.4).timeout
	_check(_shell.active_screen.scene_file_path == SceneRouter.MISSION_REPORT, "Final report route preserved")
	_check(Flight.result == before[9], "Report uses the original simulation result")


func _key(code: Key, pressed: bool) -> void:
	var key := InputEventKey.new()
	key.keycode = code
	key.pressed = pressed
	root.push_input(key, true)


func _find_engine_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and child.text == "ENGINE":
			return child
	return null


func _benchmark() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var before := _state()
	# Exercise the full launch assembly and all active engines, not only the capsule.
	mission._view.space.spacecraft.reset_stack()
	mission._view.present_phase(mission._result["phases"][1])
	mission._view.burning = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await _frames(15)
	var times: Array[float] = []
	var previous := Time.get_ticks_usec()
	for index in 120:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append(float(now - previous) / 1000.0)
		previous = now
	times.sort()
	print("Phase 4 frame intervals: median %.2f ms / p95 %.2f ms (120 local uncapped frames)" % [times[60], times[114]])
	mission._view.burning = false
	mission._view.presentation.finish(mission._result)
	_check(_state() == before, "Replaying an animation never reruns the flight calculation")


func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/phase4-%s.png" % label)
