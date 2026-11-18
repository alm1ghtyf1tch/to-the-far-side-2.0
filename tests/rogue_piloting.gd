extends "res://tests/phase4_smoke.gd"
## The same reference-physics tests, now inside the isolated fullscreen run mode.


func _run() -> void:
	create_timer(150).timeout.connect(func() -> void: quit(1))
	RogueRun.save_path = "res://.godot/rogue-piloting-test.json"
	_shell = load("res://systems/rendering/presentation_shell.tscn").instantiate()
	root.add_child(_shell)
	current_scene = _shell
	await _frames(5)
	GameSettings.apply_display(Vector2i(1600, 1000), GameSettings.WINDOWED)
	GameSettings.set_visuals({"dynamic_movement": false})
	await _manual_staging()
	await _manual_landing(true)
	await _manual_landing(false)
	_shell.open_screen(SceneRouter.MAIN_MENU)
	RogueRun.suspend()
	if _failures.is_empty():
		print("PASS: run-mode native staging and landing, original reference physics/results, pause and input release, fixed camera, replay and 16:10 fullscreen world")
		quit()
	else:
		quit(1)


func _prepare(latent: Dictionary = {}) -> void:
	RogueRun.start("Piloting", "science", "horizon-11")
	var index := 0
	for candidate in RogueRun.state["contract_offers"].size():
		if RogueRun.state["contract_offers"][candidate]["id"] == "mare":
			index = candidate
	RogueRun.select_contract(index)
	var event: Dictionary = RogueRun.state["pending_event"]
	RogueRun.choose_event(event["choices"].size() - 1)
	RogueRun.confirm_science(str(RogueRun.state["site"]), RogueResearch.required_ids(RogueRun.state))
	var baseline := RogueCatalog.baseline(RogueRun.state["contract"])
	for slot: String in baseline:
		if int(RogueRun.state["inventory"].get(baseline[slot], 0)) == 0:
			RogueRun.purchase(slot, baseline[slot])
		if RogueRun.state["vehicle"].get(slot) != baseline[slot]:
			RogueRun.install(slot, baseline[slot])
	_check(RogueRun.launch(), "Piloting fixture passes actual run readiness")
	Flight.build["latent"] = latent.duplicate()
	Flight.fly()
	RogueRun.state["context"] = RogueBridge.capture()


func _mount() -> void:
	_shell.open_screen(SceneRouter.ROGUE_CONTROL)
	await _frames(6)
	mission = _shell.active_screen
	mission._timer.stop()
	_camera_pose = mission._view.space.camera.transform
	_check(mission._gate == "start", "Run piloting begins at original start gate")
	_check(mission._view.get_global_rect() == mission.get_global_rect(), "16:10 run world fills root")


func _advance() -> void:
	if mission._commands_open:
		mission._command_sheet["layer"].queue_free()
		mission._end_commands()
	elif mission._gate != "":
		mission.choose(false)
	else:
		mission.next_line()
	mission._timer.stop()
	await _frames(2)
	_check(mission._view.space.camera.transform == _camera_pose, "Run piloting camera is fixed")
