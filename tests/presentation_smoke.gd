extends SceneTree
## Runs headless or rendered. Screenshots are generated only by a real renderer.
## godot --path . --script tests/presentation_smoke.gd

var _shell: Control
var _pressed := 0
var _drag_ended := false
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(30.0).timeout.connect(func() -> void:
		push_error("Presentation smoke test timed out")
		quit(1))
	root.size = Vector2i(1280, 720)
	_shell = load("res://systems/rendering/presentation_shell.tscn").instantiate()
	root.add_child(_shell)
	current_scene = _shell
	await _frames(6)
	_check(_shell.active_screen.scene_file_path == SceneRouter.MAIN_MENU, "Initial menu route")
	await create_timer(0.8).timeout
	await _capture("menu")
	_shell.active_screen._open_settings()
	await create_timer(0.4).timeout
	await _capture("settings")
	# Back restores the preview without changing the stored preference.
	var saved := GameSettings.visuals()
	_shell.active_screen._display_settings._sliders["curvature"].value = 100.0
	_shell.active_screen._display_settings._motion.button_pressed = true
	_check(GameSettings.visuals()["curvature"] == 1.0, "Display controls preview the actual compositor settings")
	_check(_shell.active_screen.get_node("%SaveButton").visible, "A display change enables Save")
	_shell.active_screen._close_settings()
	_check(GameSettings.visuals() == saved, "Back restores the display preview")
	await _pointer_checks()
	await _flight_input_checks()
	await _motion_checks()
	await _route_checks()
	await _embedded_3d_checks()
	if _failures.is_empty():
		print("PASS: presentation composition, curved pointer input, keyboard, drag release, dialogs, UI motion and all routes")
		quit()
	else:
		push_error("FAIL: %d presentation checks" % _failures.size())
		quit(1)


func _pointer_checks() -> void:
	var original := GameSettings.visuals()
	var layer := CanvasLayer.new()
	layer.layer = 80
	_shell.content.add_child(layer)
	var button := TactileButton.new()
	button.text = "Pointer target"
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.position = Vector2(80, 70)
	button.size = Vector2(240, 90)
	button.pressed.connect(func() -> void: _pressed += 1)
	layer.add_child(button)
	await _frames(3)
	if OS.get_cmdline_user_args().has("--debug-input"):
		print("Input geometry: ", root.size, " / ", root.get_visible_rect(), " / screen ", _shell.screen.size,
			" / content ", _shell.content.size, " / logical ", _shell.content.size_2d_override)
		_shell.screen.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton: print("Screen input: ", event.position))
		button.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton: print("Button input: ", event.position))
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(1280, 800)]:
		root.size = dimensions
		# Native Windows resize/focus notifications arrive asynchronously.
		await create_timer(0.15).timeout
		await _frames(3)
		if OS.get_cmdline_user_args().has("--debug-input"):
			print("Resized geometry: ", dimensions, " / ", root.size, " / ", root.get_visible_rect(), " / screen ", _shell.screen.size, " / content ", _shell.content.size, " / logical ", _shell.content.size_2d_override)
		for curvature: float in [0.0, 0.35, 1.0]:
			GameSettings.set_visuals({"crt_enabled": true, "curvature": curvature})
			for corner: Vector2 in [Vector2(0.05, 0.06), Vector2(0.80, 0.06), Vector2(0.05, 0.80), Vector2(0.80, 0.80)]:
				button.position = corner * Vector2(_shell.content.size_2d_override)
				var before := _pressed
				await _click(button.get_global_rect().get_center(), curvature)
				_check(_pressed == before + 1, "Curved-screen click at %s / %s / %s" % [dimensions, curvature, corner])
				_check(_shell.screen.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND, "Curved hover preserves the target's cursor")
	GameSettings.set_visuals({"crt_enabled": false})
	var before := _pressed
	await _click(button.get_global_rect().get_center(), 0.0)
	_check(_pressed == before + 1, "CRT disabled click")
	button.grab_focus()
	var key := InputEventKey.new()
	key.keycode = KEY_ENTER
	key.pressed = true
	root.push_input(key, true)
	key = key.duplicate()
	key.pressed = false
	root.push_input(key, true)
	await _frames(2)
	_check(_pressed == before + 2, "Keyboard action reaches content exactly once")
	var slider := HSlider.new()
	slider.position = Vector2(80, 220)
	slider.size = Vector2(400, 50)
	slider.drag_ended.connect(func(_changed: bool) -> void: _drag_ended = true)
	layer.add_child(slider)
	await _frames(2)
	GameSettings.set_visuals({"crt_enabled": true, "curvature": 1.0})
	await _mouse(slider.get_global_rect().get_center(), 1.0, true)
	_check(slider.value > 0.0, "Slider receives mapped input")
	await _mouse(Vector2(-40, -40), 1.0, false)
	_check(_drag_ended, "Dragging releases outside the display")
	# A higher CanvasLayer dialog must intercept the same warped click.
	var dialog := CanvasLayer.new()
	dialog.layer = 90
	_shell.content.add_child(dialog)
	var cover := Button.new()
	cover.position = button.position
	cover.size = button.size
	dialog.add_child(cover)
	before = _pressed
	await _click(button.get_global_rect().get_center(), 1.0)
	_check(_pressed == before, "Dialog blocks underlying controls")
	dialog.queue_free()
	layer.queue_free()
	GameSettings.set_visuals(original)
	root.size = Vector2i(1280, 720)
	await _frames(3)


func _motion_checks() -> void:
	var card := TactileCard.new()
	card.text = "Selection test"
	_shell.content.add_child(card)
	await _frames(2)
	var rect := card.get_global_rect()
	for index in 12:
		card.mouse_entered.emit()
		card.button_down.emit()
		card.button_up.emit()
		card.mouse_exited.emit()
	GameSettings.set_visuals({"reduced_motion": true})
	_check(card._face.scale == Vector2.ONE, "Reduced motion settles interrupted spring")
	_check(card.get_global_rect() == rect, "Spring keeps native hit rectangle stable")
	card.disabled = true
	card.mouse_entered.emit()
	await _frames(2)
	_check(card._face.scale == Vector2.ONE, "Disabled card stays still")
	card.queue_free()
	GameSettings.set_visuals({"reduced_motion": false})


func _flight_input_checks() -> void:
	Flight.quick_start(10)
	var layer := CanvasLayer.new()
	layer.layer = 80
	_shell.content.add_child(layer)
	var view := FlightView.new()
	view.position = Vector2(100, 100)
	view.size = Vector2(1020, 600)
	layer.add_child(view)
	view.setup(Vehicle.design, Campaign.site, bool(Vehicle.stats.get("high_orbit", false)))
	var staging := StagingGame.new()
	layer.add_child(staging)
	staging.start(view, ["first stage", "second stage"], Vehicle.stats["stage_dv"], "")
	staging._clock = 6.5
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	root.push_input(key, true)
	_check(staging._stage == 1 and staging._errors.size() == 1, "Manual staging receives its existing Space input")
	_check(view.staged == 1, "Manual staging still drives the original FlightView")
	key = key.duplicate()
	key.pressed = false
	root.push_input(key, true)
	staging.queue_free()
	var landing := LandingGame.new()
	landing.position = Vector2(100, 100)
	landing.size = Vector2(1020, 600)
	layer.add_child(landing)
	landing.start({"seed": 1, "training": 1, "risk": 1, "accuracy": 1.0, "computer": 1}, "a11")
	await _frames(2)
	var engine := landing.position + Vector2(861, 561)
	await _mouse(engine, _shell._curvature, true)
	await _frames(2)
	_check(landing._hold_engine and landing._engine, "Manual landing engine hold reaches unchanged mechanics")
	await _mouse(Vector2(-40, -40), _shell._curvature, false)
	_check(not landing._hold_engine, "Manual landing hold releases outside the screen")
	layer.queue_free()
	await _frames(2)


func _route_checks() -> void:
	var routes := [SceneRouter.MAIN_MENU, SceneRouter.HQ, SceneRouter.MEETING, SceneRouter.SCIENCE_BUDGET,
		SceneRouter.CALC_GAME, SceneRouter.SCIENCE_REPORT, SceneRouter.BOARD_REVIEW, SceneRouter.SCIENCE_PLAN,
		SceneRouter.ENGINEERING, SceneRouter.OPERATIONS, SceneRouter.MISSION_CONTROL, SceneRouter.MISSION_REPORT]
	for path: String in routes:
		if path == SceneRouter.HQ or path == SceneRouter.MEETING:
			Campaign.reset()
		elif path == SceneRouter.SCIENCE_BUDGET or path == SceneRouter.CALC_GAME:
			Campaign.stage = 2
			Campaign.fund_calculations(9.0)
		elif path == SceneRouter.BOARD_REVIEW:
			Campaign.stage = 3
		elif path == SceneRouter.SCIENCE_PLAN:
			Campaign.stage = 4
		elif path == SceneRouter.ENGINEERING:
			Flight.quick_start(7)
			Campaign.stage = 6
		elif path == SceneRouter.OPERATIONS:
			Flight.quick_start(8)
		elif path == SceneRouter.MISSION_CONTROL:
			Flight.quick_start(10)
		await root.get_node("SceneRouter").go_to(path, 0.01)
		await _frames(3)
		_check(_shell.active_screen.scene_file_path == path, "Route: %s" % path)
		_check(not root.get_node("SceneRouter").is_busy(), "Route releases input: %s" % path)
		if path == SceneRouter.HQ:
			await create_timer(0.95).timeout
			await _capture("hq")
		if path == SceneRouter.MISSION_CONTROL:
			_shell.active_screen.skip_to_end()
			_check(_shell.active_screen._finished, "Flight skip reaches its existing final state")
		print("Route OK: ", path)
	await root.get_node("SceneRouter").go_to(SceneRouter.MAIN_MENU, 0.01)
	await _frames(4)
	await create_timer(0.8).timeout
	GameSettings.set_visuals({"crt_enabled": false})
	await _capture("crt-off")
	GameSettings.set_visuals({"crt_enabled": true})


func _embedded_3d_checks() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var layer := CanvasLayer.new()
	layer.layer = 80
	_shell.content.add_child(layer)
	var view := SubViewport.new()
	view.size = Vector2i(256, 256)
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	layer.add_child(view)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 0, 4)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.0
	view.add_child(camera)
	camera.current = true
	var cube := MeshInstance3D.new()
	cube.mesh = BoxMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = VisualTheme.CYAN
	cube.material_override = material
	view.add_child(cube)
	var display := TextureRect.new()
	display.position = Vector2(1300, 180)
	display.size = Vector2(420, 420)
	display.texture = view.get_texture()
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(display)
	await _frames(8)
	await RenderingServer.frame_post_draw
	var source_pixel := view.get_texture().get_image().get_pixel(128, 128)
	_check(source_pixel.b > 0.5, "Embedded 3D viewport renders geometry")
	var source := display.get_global_rect().get_center() / Vector2(_shell.content.size_2d_override)
	var uv := _display_uv(source, float(GameSettings.visuals()["curvature"]))
	var output_image := root.get_texture().get_image()
	var at := Vector2i(uv * Vector2(output_image.get_size()))
	var pixel := output_image.get_pixelv(at)
	_check(pixel.b > 0.5 and pixel.g > 0.35, "3D viewport reaches the final CRT composition")
	await _capture("composition")
	layer.queue_free()
	await _frames(2)


func _click(logical_point: Vector2, curvature: float) -> void:
	await _mouse(logical_point, curvature, true)
	await _mouse(logical_point, curvature, false)


func _mouse(logical_point: Vector2, curvature: float, pressed: bool) -> void:
	var source := logical_point / Vector2(_shell.content.size_2d_override)
	var output_uv := _display_uv(source, curvature)
	var mouse := InputEventMouseButton.new()
	mouse.position = output_uv * root.get_visible_rect().size
	mouse.global_position = mouse.position
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = pressed
	mouse.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	var motion := InputEventMouseMotion.new()
	motion.position = mouse.position
	motion.global_position = mouse.position
	motion.button_mask = 0 if pressed else MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion, true)
	root.push_input(mouse, true)
	await _frames(1)


func _display_uv(source: Vector2, curvature: float) -> Vector2:
	# Independently invert the shader's sampling warp to find the visible target.
	source = (source - Vector2(0.5, 0.5)) / _shell._visible_fraction + Vector2(0.5, 0.5) + _shell._image_offset
	var q := source * 2.0 - Vector2.ONE
	var p := q
	var k := curvature * 0.08
	for iteration in 20:
		p = q / (Vector2.ONE + Vector2(p.y * p.y, p.x * p.x) * k)
	return p * 0.5 + Vector2(0.5, 0.5)


func _frames(count: int) -> void:
	for index in count:
		await process_frame


func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(not image.is_empty(), "Rendered capture: %s" % label)
	image.save_png("res://.godot/phase1-%s.png" % label)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error("FAIL: " + message)
