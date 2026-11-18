extends "res://tests/presentation_smoke.gd"
## End-to-end Phase 3 checks through the approved CRT input mapping.

var _planner: Control
var _before: Array


func _run() -> void:
	create_timer(100.0).timeout.connect(func() -> void:
		push_error("Phase 3 integration timed out")
		quit(1))
	Campaign.reset()
	Campaign.stage = 4
	Campaign.days = 100.0
	Campaign.budget_left = 73.0
	Campaign.clock_running = false
	_before = _campaign_snapshot()
	_shell = load("res://systems/rendering/presentation_shell.tscn").instantiate()
	root.add_child(_shell)
	current_scene = _shell
	await _frames(5)
	GameSettings.apply_display(Vector2i(1920, 1080), GameSettings.BORDERLESS)
	GameSettings.set_visuals(GameSettings.VISUAL_DEFAULTS)
	GameSettings.set_visuals({"dynamic_movement": false})
	_shell.open_screen(SceneRouter.SCIENCE_PLAN)
	await create_timer(0.4).timeout
	_planner = _shell.active_screen
	_check(_planner._site_cards.size() == 6 and _planner._gear_cards.size() == 11, "All original choices exist")
	_check(_planner._ui.confirm.disabled, "A destination is required, including on the payload step")
	_coordinate_checks()
	await _capture("overview")
	await _sites_and_camera()
	await _payload_checks()
	await _display_checks()
	await _benchmark()
	_check(_campaign_snapshot() == _before, "All previews, selections, notes and step changes leave campaign untouched")
	await _confirmation_check()
	if _failures.is_empty():
		print("PASS: Phase 3 six sites, orbital camera, mapping, occlusion, 11 instruments, totals, notes, CRT input, display scaling and single confirmation")
		quit()
	else:
		push_error("FAIL: %d Phase 3 checks" % _failures.size())
		quit(1)


func _campaign_snapshot() -> Array:
	return [Campaign.stage, Campaign.days, Campaign.budget_left, Campaign.site.duplicate(), Campaign.instruments.duplicate(), Campaign.payload_mass, Campaign.payload_power, Campaign.payload_cost, Campaign.science_value, Campaign.clock_running]


func _coordinate_checks() -> void:
	_check(LunarCoordinates.direction(0, 0).is_equal_approx(Vector3.BACK), "Prime meridian faces +Z")
	_check(LunarCoordinates.direction(0, 90).is_equal_approx(Vector3.RIGHT), "East is +X")
	_check(LunarCoordinates.direction(90, 0).is_equal_approx(Vector3.UP), "North is +Y")
	_check(LunarCoordinates.uv(LunarCoordinates.direction(0, -90)).is_equal_approx(Vector2(0.25, 0.5)), "Western longitude maps to left half of NASA map")
	_check(LunarCoordinates.visible(Vector3.BACK, Vector3(0, 0, 8.5), 2.65), "Front marker visible")
	_check(not LunarCoordinates.visible(Vector3.FORWARD, Vector3(0, 0, 8.5), 2.65), "Farside label occluded by sphere")
	_check(not LunarCoordinates.visible(Vector3.RIGHT, Vector3(0, 0, 8.5), 2.65), "Limb label suppressed despite being in camera frustum")
	# Recognizable independent map landmarks: Tycho's bright rays and dark maria.
	var albedo := (load("res://assets/moon/lroc_color_2k.jpg") as Texture2D).get_image()
	var tycho := _map_pixel(albedo, -43.3, -11.2)
	var mare := _map_pixel(albedo, 28.0, 17.5)
	_check(tycho.get_luminance() > mare.get_luminance() + 0.12, "NASA map alignment: bright Tycho versus dark Serenitatis")


func _map_pixel(image: Image, lat: float, lon: float) -> Color:
	# Independent geographic indexing of the actual texture asset.
	return image.get_pixel(int((lon + 180.0) / 360.0 * image.get_width()), int((90.0 - lat) / 180.0 * image.get_height()))


func _sites_and_camera() -> void:
	var lunar: LunarScene3D = _planner._ui.lunar
	var fixed_transform := lunar.moon.transform
	await _hover(Vector2(930, 100))
	await _frames(2)
	var previous_preview: int = _planner._preview_index
	# Passing quickly over a card must not start a stale camera movement.
	_planner._queue_preview(0)
	await create_timer(0.04).timeout
	_planner._cancel_preview(0)
	await create_timer(0.16).timeout
	_check(_planner._preview_index == previous_preview, "Hover debounce cancels a passing pointer")
	for index in 6:
		await _hover(_planner._site_cards[index].get_global_rect().get_center())
		await create_timer(0.2).timeout
		_check(_planner._preview_index == index, "Hover previews Apollo site %d through CRT" % index)
		_check(_planner._site_index == -1, "Hover does not commit destination")
		for sample in 8:
			await create_timer(0.1).timeout
			_check(absf(lunar.camera.position.length() - OrbitCameraController.DISTANCE) < 0.001, "Camera stays outside Moon on constant-radius arc")
		var normal := LunarCoordinates.from_site(Campaign.sites()[index])
		_check(lunar.camera.orbital_direction.dot(normal) > 0.9999, "Camera settles on exact authoritative site %d" % index)
		var projected := lunar.camera.unproject_position(lunar.markers[index].position)
		_check(projected.distance_to(Vector2(lunar.camera.get_viewport().size) * 0.5) < 2.0, "Destination is centred in lunar viewport")
		_check(lunar.moon.transform == fixed_transform, "Moon does not rotate during camera travel")
		if index in [0, 3, 5]:
			await _capture("apollo-%d" % int(str(Campaign.sites()[index]["mission"]).get_slice(" ", 1)))
	await _click(_planner._site_cards[0].get_global_rect().get_center(), _shell._curvature)
	await _hover(_planner._site_cards[5].get_global_rect().get_center())
	await create_timer(0.22).timeout
	_check(_planner._site_index == 0 and lunar.selected == 0 and lunar.previewed == 5, "Committed amber destination persists during a cyan preview")
	# Retarget while still moving. The new arc starts exactly at the current pose.
	var pose := lunar.camera.position
	_planner._preview_site(1)
	_check(lunar.camera.position.is_equal_approx(pose), "Retargeting has no position jump")
	_planner._preview_site(4)
	_planner._preview_site(3)
	await create_timer(1.0).timeout
	_check(lunar.camera.target_direction.dot(LunarCoordinates.from_site(Campaign.sites()[3])) > 0.99999, "Rapid retarget keeps only the latest destination")
	# Field notes retain all original educational text and source.
	await _click(_planner._ui.details.get_global_rect().get_center(), _shell._curvature)
	await create_timer(0.35).timeout
	_check(_planner._read_more.is_open(), "Site field notes open through CRT")
	_check(_planner._read_more._topic["source"] == Campaign.sites()[3]["read_more"]["source"], "Original site source is preserved")
	_planner._read_more.close()
	await create_timer(0.35).timeout
	_planner._toggle_map()
	_check(_planner._map_window.visible and _planner._map.sites.size() == 6, "Original reference map retained")
	_planner._map.site_clicked.emit(2)
	_check(_planner._site_index == 2, "Reference map still selects the same destination")
	_planner._toggle_map()


func _payload_checks() -> void:
	await _click(_planner._ui.confirm.get_global_rect().get_center(), _shell._curvature)
	await create_timer(0.35).timeout
	_check(_planner._step == 1 and _planner._ui.lunar_viewport.is_inside_tree(), "Equipment step retains live Moon")
	# Native input on a card, then manifest removal, including a nested notes button.
	await _click(_planner._gear_cards[0].get_global_rect().get_center(), _shell._curvature)
	_check(_planner._picked[0], "Native instrument card adds payload")
	await _frames(3)
	await _click((_planner._ui.tray.get_child(0) as Control).get_global_rect().get_center(), _shell._curvature)
	_check(not _planner._picked[0], "Manifest chip removes payload")
	for index in 11:
		_planner.toggle_instrument(index)
	await create_timer(0.35).timeout
	var totals := Campaign.plan_totals(Campaign.sites()[2], Campaign.instrument_options())
	_check(_planner._chosen().size() == 11, "All eleven instruments can be installed")
	_check(float(_planner._ui.values["mass"].get_meta("target_value")) == float(totals["mass"]), "Payload mass uses Campaign totals")
	_check(float(_planner._ui.values["power"].get_meta("target_value")) == float(totals["power"]), "Payload power uses Campaign totals")
	_check(is_equal_approx(float(_planner._ui.values["cost"].get_meta("target_value")), float(totals["cost"])), "Cost uses Campaign totals")
	_check(int(_planner._ui.values["science"].text) == int(totals["science"]), "Animated science settles to exact total")
	_planner._ui.gear_scroll.scroll_vertical = 10000
	await _frames(5)
	var last: Control = _planner._gear_cards[10]
	_check(_planner._ui.gear_scroll.get_global_rect().intersects(last.get_global_rect()), "Last instrument is reachable by scrolling")
	var notes: Button = _find_button(last, "Field notes  ›")
	await _click(notes.get_global_rect().get_center(), _shell._curvature)
	await create_timer(0.35).timeout
	_check(_planner._read_more.is_open() and _planner._picked[10], "Nested instrument notes open without changing selection")
	_check(_planner._read_more._topic["source"] == Campaign.instrument_options()[10]["read_more"]["source"], "Original instrument educational source retained")
	await _capture("field-notes")
	_planner._read_more.close()
	await create_timer(0.35).timeout
	_planner.show_step(0)
	_planner.show_step(1)
	_check(_planner._chosen().size() == 11 and _planner._site_index == 2, "Moving between steps preserves local choices")
	await create_timer(0.4).timeout
	await _capture("payload-all")
	# No new affordability constraint or mandatory equipment restriction.
	for index in 11:
		_planner.toggle_instrument(index)
	_check(not _planner._ui.confirm.disabled, "Original zero-instrument plan remains allowed")
	_planner.toggle_instrument(0)
	_planner.toggle_instrument(7)


func _find_button(node: Node, text: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == text:
			return child
		var result := _find_button(child, text)
		if result:
			return result
	return null


func _display_checks() -> void:
	for configuration: Dictionary in [{"crt_enabled": false}, {"crt_enabled": true, "curvature": 1.0, "movement_strength": 1.0, "dynamic_movement": true}, {"reduced_motion": true}]:
		GameSettings.set_visuals(configuration)
		await create_timer(0.35).timeout
		_planner.show_step(0)
		await create_timer(0.3).timeout
		await _click(_planner._site_cards[4].get_global_rect().get_center(), _shell._curvature)
		_check(_planner._site_index == 4, "Site selection aligns at CRT setting %s" % configuration)
		if GameSettings.reduced_motion():
			_check(_planner._ui.lunar.camera.orbital_direction.is_equal_approx(LunarCoordinates.from_site(Campaign.sites()[4])), "Reduced motion snaps orbital camera")
		_planner.show_step(1)
		await create_timer(0.3).timeout
	GameSettings.set_visuals({"reduced_motion": false, "curvature": 0.35, "dynamic_movement": false})
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]:
		GameSettings.apply_display(dimensions, GameSettings.WINDOWED)
		if DisplayServer.get_name() == "headless":
			root.size = dimensions
		await create_timer(0.3).timeout
		if DisplayServer.get_name() != "headless":
			_check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED, "Resolution check uses an actual native window")
			if dimensions.x <= 1600:
				_check(DisplayServer.window_get_size() == Vector2i((Vector2(dimensions) * DisplayServer.screen_get_scale()).round()), "Actual window dimensions match requested resolution")
			print("Phase 3 display check: requested %s, actual %s" % [dimensions, DisplayServer.window_get_size()])
		_check(_planner.get_global_rect().encloses(_planner._ui.confirm.get_global_rect()), "Confirmation fits %s" % dimensions)
		_check(_planner._ui.lunar.camera.position.length() > LunarScene3D.RADIUS, "Moon framing remains external")
		await _capture("payload-%d" % dimensions.x)
	GameSettings.apply_display(Vector2i(1920, 1080), GameSettings.BORDERLESS)
	await create_timer(0.3).timeout
	await _capture("payload")


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
	print("Phase 3 rendered frame intervals: median %.2f ms, p95 %.2f ms (120 frames, local hardware only)" % [times[60], times[114]])


func _confirmation_check() -> void:
	var totals := Campaign.plan_totals(Campaign.sites()[4], _planner._chosen())
	# Click final confirmation, then invoke again to verify the commit guard.
	await _click(_planner._ui.confirm.get_global_rect().get_center(), _shell._curvature)
	_planner._on_confirm_pressed()
	_check(Campaign.stage == 5 and Campaign.site == Campaign.sites()[4], "Final confirmation advances original stage and destination")
	_check(is_equal_approx(Campaign.budget_left, 73.0 - float(totals["cost"])), "Budget charged exactly once")
	_check(Campaign.days == 165.0, "Original 45 days plus 10 per instrument applied exactly once")
	_check(Campaign.clock_running and Campaign.instruments.size() == 2, "Original campaign clock and chosen payload committed")
	await create_timer(1.5).timeout
	_check(_shell.active_screen.scene_file_path == SceneRouter.HQ, "Original confirmation returns to headquarters")


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
	root.get_texture().get_image().save_png("res://.godot/phase3-%s.png" % label)
