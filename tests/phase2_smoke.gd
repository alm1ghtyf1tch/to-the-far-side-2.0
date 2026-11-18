extends "res://tests/presentation_smoke.gd"
## Phase 2 integration checks. Does not write the player's settings.


func _run() -> void:
	create_timer(90.0).timeout.connect(func() -> void:
		push_error("Phase 2 integration timed out")
		quit(1))
	_shell = load("res://systems/rendering/presentation_shell.tscn").instantiate()
	root.add_child(_shell)
	current_scene = _shell
	await _frames(6)
	GameSettings.set_visuals(GameSettings.VISUAL_DEFAULTS)
	await _parallax_checks()
	_settings_migration_checks()
	await _display_mode_checks()
	await _menu_checks()
	await _headquarters_checks()
	if _failures.is_empty():
		print("PASS: Phase 2 parallax, display modes, menu, 3D headquarters, all 11 stage gates and return flow")
		quit()
	else:
		push_error("FAIL: %d Phase 2 checks" % _failures.size())
		quit(1)


func _parallax_checks() -> void:
	# Every visible part of the original glass remains inside the overscanned image
	# at maximum movement, including maximum curvature. Rounded CRT corners stay put.
	var safe := true
	for curve: float in [0.0, 0.35, 1.0]:
		for offset: Vector2 in [Vector2(-0.018, -0.018), Vector2(0.018, -0.018), Vector2(-0.018, 0.018), Vector2(0.018, 0.018)]:
			for x in 21:
				for y in 21:
					var uv := Vector2(x, y) / 20.0
					if CRTGeometry.on_screen(CRTGeometry.glass_uv(uv, curve)):
						safe = safe and CRTGeometry.on_screen(CRTGeometry.source_uv(uv, curve, 0.95, offset))
	_check(safe, "Maximum movement never reveals unrendered image borders inside the CRT glass")
	var neutral := CRTGeometry.source_uv(Vector2(0.7, 0.5), 0.35, 0.95)
	var shifted := CRTGeometry.source_uv(Vector2(0.7, 0.5), 0.35, 0.95, Vector2(0.018, 0))
	_check(shifted.x < neutral.x, "Positive movement translates the visible image in the pointer direction")
	GameSettings.set_visuals({"movement_strength": 1.0, "dynamic_movement": true, "reduced_motion": false})
	_raw_motion(Vector2(0.95, 0.95))
	await create_timer(0.35).timeout
	_check(_shell._image_offset.x > 0 and _shell._image_offset.y > 0, "Image follows lower-right pointer")
	var previous: Vector2 = _shell._image_offset
	_raw_motion(Vector2(0.05, 0.05))
	await _frames(1)
	_check(_shell._image_offset.distance_to(Vector2(-0.0162, -0.0162)) > 0.0001, "Movement eases rather than snapping")
	await create_timer(0.6).timeout
	_check(_shell._image_offset.x < 0 and _shell._image_offset.y < 0, "Image follows upper-left pointer")
	_check(previous.length() <= Vector2.ONE.length() * CRTGeometry.MAX_MOVEMENT, "Smoothing stays inside safe overscan")
	var layer := CanvasLayer.new()
	layer.layer = 80
	_shell.content.add_child(layer)
	var button := TactileButton.new()
	button.text = "Parallax target"
	button.size = Vector2(220, 70)
	button.pressed.connect(func() -> void: _pressed += 1)
	layer.add_child(button)
	for pose: Vector2 in [Vector2(0.05, 0.05), Vector2(0.95, 0.05), Vector2(0.05, 0.95), Vector2(0.95, 0.95)]:
		_raw_motion(pose)
		await create_timer(0.28).timeout
		_shell.set_process(false)
		button.position = Vector2(0.14 if pose.x < 0.5 else 0.78, 0.15 if pose.y < 0.5 else 0.78) * Vector2(_shell.content.size_2d_override)
		var before := _pressed
		await _click(button.get_global_rect().get_center(), _shell._curvature)
		_check(_pressed == before + 1, "Pointer aligns with shifted corner %s" % pose)
		_shell.set_process(true)
	# Alternate adjacent controls while the image is still easing.
	button.position = Vector2(700, 580)
	button.size = Vector2(160, 70)
	var adjacent := TactileButton.new()
	adjacent.text = "Adjacent"
	adjacent.position = Vector2(870, 580)
	adjacent.size = Vector2(160, 70)
	adjacent.pressed.connect(func() -> void: _pressed += 1)
	layer.add_child(adjacent)
	var before := _pressed
	for index in 8:
		_raw_motion(Vector2.ZERO if index % 2 == 0 else Vector2.ONE)
		await _click((button if index % 2 == 0 else adjacent).get_global_rect().get_center(), _shell._curvature)
	_check(_pressed == before + 8, "Rapid adjacent clicks remain accurate during live movement")
	layer.queue_free()
	GameSettings.set_visuals({"reduced_motion": true})
	_raw_motion(Vector2.ONE)
	await _frames(4)
	_check(_shell._image_offset == Vector2.ZERO and _shell._visible_fraction == 1.0, "Reduced motion disables movement and overscan")
	_check(GameSettings.visuals()["dynamic_movement"], "Reduced motion preserves the user's movement preference")
	GameSettings.set_visuals({"reduced_motion": false, "dynamic_movement": false})
	_check(_shell._image_offset == Vector2.ZERO and _shell._visible_fraction == 1.0, "Movement off restores Phase 1 framing")
	GameSettings.set_visuals(GameSettings.VISUAL_DEFAULTS)


func _settings_migration_checks() -> void:
	var config := ConfigFile.new()
	GameSettings.set_visuals({"movement_strength": 0.91, "dynamic_movement": false})
	GameSettings._write_config(config)
	var file := "res://.godot/phase2-settings-test.cfg"
	_check(config.save(file) == OK, "Movement settings serialize")
	var restored := ConfigFile.new()
	_check(restored.load(file) == OK, "Movement settings reload")
	GameSettings.set_visuals(GameSettings.VISUAL_DEFAULTS)
	GameSettings._read_config(restored)
	_check(GameSettings.visuals()["movement_strength"] == 0.91 and not GameSettings.visuals()["dynamic_movement"], "Movement settings round-trip")
	var legacy := ConfigFile.new()
	legacy.set_value("video", "resolution", Vector2i.ZERO)
	GameSettings._read_config(legacy)
	_check(GameSettings.display_mode == GameSettings.BORDERLESS, "Legacy fullscreen migrates to borderless")
	_check(GameSettings.resolution.x > 0 and GameSettings.resolution.y > 0, "Legacy fullscreen retains a usable window size")
	legacy.set_value("video", "resolution", Vector2i(1600, 900))
	GameSettings._read_config(legacy)
	_check(GameSettings.display_mode == GameSettings.WINDOWED, "Legacy windowed resolution stays windowed")
	GameSettings.set_visuals(GameSettings.VISUAL_DEFAULTS)


func _display_mode_checks() -> void:
	if DisplayServer.get_name() == "headless":
		print("Native display mode checks skipped in headless mode")
		return
	for cycle in 2:
		for mode: String in GameSettings.display_modes():
			GameSettings.apply_display(Vector2i(1280, 720), mode)
			await create_timer(0.3).timeout
			await _frames(4)
			var actual := DisplayServer.window_get_mode()
			var expected := {GameSettings.WINDOWED: DisplayServer.WINDOW_MODE_WINDOWED, GameSettings.BORDERLESS: DisplayServer.WINDOW_MODE_FULLSCREEN, GameSettings.EXCLUSIVE: DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN}
			_check(actual == expected[mode], "Native display mode %s / cycle %d" % [mode, cycle])
			if mode == GameSettings.WINDOWED:
				_check(not DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS), "Window decorations restored")
				_check(not DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED), "Window is resizable")
			else:
				_check(root.size == DisplayServer.screen_get_size(DisplayServer.window_get_current_screen()), "Fullscreen uses actual desktop resolution")
	GameSettings.apply_display(Vector2i(1600, 900), GameSettings.WINDOWED)
	await create_timer(0.2).timeout
	root.size = Vector2i(1920, 1080)
	await _frames(5)


func _menu_checks() -> void:
	await create_timer(0.8).timeout
	await _capture("menu-1080")
	var menu: Control = _shell.active_screen
	await _click(menu.get_node("%SettingsButton").get_global_rect().get_center(), _shell._curvature)
	await create_timer(0.35).timeout
	_check(menu._settings_box.visible and menu._display_settings.visible, "Menu Settings opens both settings panels")
	var mode_select: OptionButton = menu.get_node("%ModeSelect")
	await _click(mode_select.get_global_rect().get_center(), _shell._curvature)
	await _frames(3)
	_check(mode_select.get_popup().visible and mode_select.get_popup().is_embedded(), "Mode popup is embedded inside the CRT composition")
	_key(KEY_DOWN)
	_key(KEY_DOWN)
	_key(KEY_ENTER)
	await _frames(3)
	_check(menu._mode != GameSettings.WINDOWED, "Mode popup accepts forwarded keyboard input")
	await _capture("settings-1080")
	menu._close_settings()
	_check(not menu._settings_box.visible and menu._column.visible, "Back restores main navigation")
	await _click(menu.get_node("%PlayButton").get_global_rect().get_center(), _shell._curvature)
	await _wait_for_route(SceneRouter.PROGRAMMES)
	_shell.active_screen.story()
	await _wait_for_route(SceneRouter.HQ)
	_check(Campaign.stage == 1 and Campaign.budget_left == 100.0, "Play preserves the existing campaign reset")


func _headquarters_checks() -> void:
	var hq: Control = _shell.active_screen
	await create_timer(0.5).timeout
	_check(hq._diorama.rooms.size() == 3, "Headquarters has three real 3D departments")
	_check(hq._world_viewport.own_world_3d, "Headquarters owns an isolated 3D world")
	await _capture("hq-1080")
	for floor: FloorHotspot in [hq._board, hq._engineering, hq._science]:
		var eye: Transform3D = hq._diorama.camera.transform
		await _hover_floor(hq, floor)
		_check(hq._diorama._hovered == floor.floor_number - 1, "Department hover: %s" % floor.department)
		_check(hq._diorama.camera.transform == eye, "Hover never moves the headquarters camera")
		_check(hq._department_label.text.contains(floor.department.to_upper()), "Department label follows hover")
	await _capture("hq-science-hover")
	var budget := Campaign.budget_left
	await _click(_floor_point(hq._engineering), _shell._curvature)
	_check(_shell.active_screen == hq and not root.get_node("SceneRouter").is_busy(), "Locked Engineering cannot bypass stage 1")
	_check(not hq._hint_label.text.is_empty() and Campaign.budget_left == budget, "Locked department preserves hint and budget behavior")
	var eye: Vector3 = hq._diorama.camera.position
	await _click(_floor_point(hq._board), _shell._curvature)
	await create_timer(0.2).timeout
	_check(root.get_node("SceneRouter").is_busy() and _shell.active_screen == hq, "Room transition uses the existing router fade")
	_check(hq._diorama.camera.position.distance_to(eye) > 0.01, "Valid selection begins an authored camera transition")
	_check(Campaign.stage == 1, "Camera animation does not advance campaign stage")
	await _capture("board-entry")
	await _wait_for_route(SceneRouter.MEETING)
	_shell.active_screen._on_approve_pressed()
	await _wait_for_route(SceneRouter.HQ)
	_check(Campaign.stage == 2, "Existing meeting returns to HQ at stage 2")
	hq = _shell.active_screen
	await _click(_floor_point(hq._engineering), _shell._curvature)
	await _wait_for_route(SceneRouter.SCIENCE_BUDGET)
	_check(not Campaign.clock_running, "Department entry preserves campaign clock stopping")
	# Read-only stage gating checks use the existing complete mission fixture.
	Flight.quick_start(10)
	var floors := [3, 2, 3, 1, 3, 2, 3, 2, 3, 2, 3]
	var routes := [SceneRouter.MEETING, SceneRouter.SCIENCE_BUDGET, SceneRouter.BOARD_REVIEW, SceneRouter.SCIENCE_PLAN,
		SceneRouter.BOARD_REVIEW, SceneRouter.ENGINEERING, SceneRouter.BOARD_REVIEW, SceneRouter.OPERATIONS,
		SceneRouter.BOARD_REVIEW, SceneRouter.MISSION_CONTROL, SceneRouter.MISSION_REPORT]
	for stage in range(1, 12):
		Campaign.stage = stage
		Campaign.clock_running = false
		await root.get_node("SceneRouter").go_to(SceneRouter.HQ, 0.01)
		await _frames(3)
		hq = _shell.active_screen
		_check(hq._goal.floor_number == floors[stage - 1] and hq._goal_scene == routes[stage - 1], "Original stage %d department and route" % stage)
		var before := [Campaign.days, Campaign.budget_left, Campaign.board_confidence, Campaign.stage]
		for floor: FloorHotspot in [hq._board, hq._engineering, hq._science]:
			if floor != hq._goal:
				hq._on_floor_clicked(floor)
		_check(before == [Campaign.days, Campaign.budget_left, Campaign.board_confidence, Campaign.stage] and not root.get_node("SceneRouter").is_busy(), "Stage %d locked floors do not mutate gameplay" % stage)
		if stage == 4:
			await _click(_floor_point(hq._science), _shell._curvature)
			await _wait_for_route(SceneRouter.SCIENCE_PLAN)
			_check(Campaign.stage == 4, "Science department entry does not commit a science plan")
	Campaign.reset()
	await root.get_node("SceneRouter").go_to(SceneRouter.HQ, 0.01)
	GameSettings.set_visuals({"reduced_motion": true})
	await _frames(3)
	hq = _shell.active_screen
	var rotation: Vector3 = hq._diorama._globe.rotation
	await _frames(8)
	_check(hq._diorama._globe.rotation == rotation, "Reduced motion freezes headquarters ambient models")
	GameSettings.set_visuals(GameSettings.VISUAL_DEFAULTS)


func _floor_point(floor: FloorHotspot) -> Vector2:
	var center := Vector2.ZERO
	for point: Vector2 in floor._shape:
		center += point
	center /= maxf(1.0, float(floor._shape.size()))
	return floor.get_global_transform_with_canvas() * center


func _hover_floor(_hq: Control, floor: FloorHotspot) -> void:
	var source := _floor_point(floor) / Vector2(_shell.content.size_2d_override)
	_raw_motion(_display_uv(source, _shell._curvature))
	await create_timer(0.12).timeout


func _raw_motion(uv: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = uv * root.get_visible_rect().size
	event.global_position = event.position
	root.push_input(event, true)


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)


func _wait_for_route(path: String) -> void:
	while _shell.active_screen.scene_file_path != path or root.get_node("SceneRouter").is_busy():
		await process_frame
	await _frames(4)


func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/phase2-%s.png" % label)
