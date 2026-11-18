extends "res://tests/presentation_smoke.gd"
## Windows/headless aspect-ratio checks, explicitly not macOS hardware testing.


func _run() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(1))
	_shell = load("res://systems/rendering/presentation_shell.tscn").instantiate()
	root.add_child(_shell)
	current_scene = _shell
	await _frames(5)
	GameSettings.set_visuals({"dynamic_movement": false})
	for dimensions: Vector2i in [Vector2i(1280, 800), Vector2i(1600, 1000), Vector2i(2408, 1506)]:
		GameSettings.apply_display(dimensions, GameSettings.WINDOWED)
		if DisplayServer.get_name() == "headless":
			root.size = dimensions
		await create_timer(0.3).timeout
		Flight.quick_start(10)
		Vehicle.draft = Vehicle.design.duplicate()
		Campaign.stage = 6
		Campaign.budget_left = 80
		_shell.open_screen(SceneRouter.ENGINEERING)
		await _frames(8)
		var assembly: Control = _shell.active_screen
		_check(assembly.get_global_rect().encloses(assembly._hand_over.get_global_rect()), "16:10 assembly action fits")
		await _click(assembly._ui.metrics.tab.get_global_rect().get_center(), _shell._curvature)
		_check(not assembly._ui.metrics.opened, "16:10 CRT input aligns")
		if dimensions.x == 1280:
			await _capture("assembly-16x10")
		_shell.open_screen(SceneRouter.SCIENCE_PLAN)
		await _frames(8)
		var planner: Control = _shell.active_screen
		_check(planner.get_global_rect().encloses(planner._ui.confirm.get_global_rect()), "16:10 science confirmation fits")
		_shell.open_screen(SceneRouter.HQ)
		await _frames(8)
		var hq: Control = _shell.active_screen
		_check(hq._diorama.camera.position.length() > 0, "16:10 HQ renders its existing world")
		Flight.quick_start(11)
		_shell.open_screen(SceneRouter.MISSION_CONTROL)
		await _frames(8)
		var mission: Control = _shell.active_screen
		mission._timer.stop()
		_check(mission.get_global_rect().encloses(mission._gate_yes.get_global_rect()), "16:10 mission choice fits")
		print("Aspect check requested %s; actual desktop window %s" % [dimensions, DisplayServer.window_get_size()])
	if _failures.is_empty():
		print("PASS: approximate Mac display aspect, assembly/science/HQ/flight layouts and CRT input; macOS hardware not tested")
		quit()
	else:
		quit(1)


func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/macos-%s.png" % label)
