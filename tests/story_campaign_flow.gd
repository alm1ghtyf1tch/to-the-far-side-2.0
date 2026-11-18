extends "res://tests/presentation_smoke.gd"
## Complete authored campaign via real screen handlers and existing skip options.


func _run() -> void:
	create_timer(100).timeout.connect(func() -> void: quit(1))
	_shell = load("res://systems/rendering/presentation_shell.tscn").instantiate()
	root.add_child(_shell)
	current_scene = _shell
	await _frames(5)
	Campaign.reset()
	_shell.open_screen(SceneRouter.MEETING)
	await _frames(3)
	_shell.active_screen._on_approve_pressed()
	await _route(SceneRouter.HQ)
	_check(Campaign.stage == 2, "Authored meeting approval")
	_shell.active_screen._on_floor_clicked(_shell.active_screen._engineering)
	await _route(SceneRouter.SCIENCE_BUDGET)
	_shell.active_screen._slider.value = float(Campaign.science()["requested_pct"])
	_shell.active_screen._on_confirm_pressed()
	await _route(SceneRouter.CALC_GAME)
	_shell.active_screen._on_skip_pressed()
	await _route(SceneRouter.SCIENCE_REPORT)
	_check(Campaign.stage == 3 and Campaign.runs_total > 0, "Original calculation skip computes a real report")
	_shell.active_screen._on_file_pressed()
	await _route(SceneRouter.HQ)
	await _board_review()
	_check(Campaign.stage == 4, "Concept review opens original science phase")
	_shell.active_screen._on_floor_clicked(_shell.active_screen._science)
	await _route(SceneRouter.SCIENCE_PLAN)
	_shell.active_screen.select_site(0)
	_shell.active_screen.toggle_instrument(0)
	_shell.active_screen.toggle_instrument(6)
	_shell.active_screen._on_confirm_pressed()
	_shell.active_screen._on_confirm_pressed()
	await _route(SceneRouter.HQ)
	_check(Campaign.stage == 5, "Original science plan commits")
	await _board_review()
	_check(Campaign.stage == 6, "Requirements review opens engineering")
	_shell.active_screen._on_floor_clicked(_shell.active_screen._engineering)
	await _route(SceneRouter.ENGINEERING)
	var assembly: Control = _shell.active_screen
	assembly._choice.merge({"stage1":"s1_solid","stage2":"s2_core","stage3":"s3_icps","lander":"lander_hls","service":"service_esm","capsule":"capsule_three","escape":"escape_tower","life":"life_canisters","suits":"suits_flex","power":"power_solar","comms":"comms_dish","spaceport":"port_ksc","ground":"ground_existing","tests":"tests_allup"}, true)
	assembly._hangar.rocket.set_choice(assembly._choice, "", false)
	assembly._refresh()
	assembly._on_hand_over_pressed()
	await _route(SceneRouter.HQ)
	_check(Campaign.stage == 7, "Original vehicle handover")
	await _board_review()
	_check(Campaign.stage == 8, "Design review opens operations")
	_shell.active_screen._on_floor_clicked(_shell.active_screen._engineering)
	await _route(SceneRouter.OPERATIONS)
	for item: Dictionary in Operations.items():
		_shell.active_screen.choose(str(item["id"]), 1)
	_shell.active_screen._on_confirm_pressed()
	await _route(SceneRouter.HQ)
	_check(Campaign.stage == 9 and not Flight.build.is_empty(), "Original preparations and build events")
	await _board_review()
	_check(Campaign.stage == 10, "Readiness review opens flight")
	_shell.active_screen._on_floor_clicked(_shell.active_screen._engineering)
	await _route(SceneRouter.MISSION_CONTROL)
	_shell.active_screen.skip_to_end()
	_check(Campaign.stage == 11 and not Flight.result.is_empty(), "Original flight resolves")
	_shell.active_screen.open_report()
	await _route(SceneRouter.MISSION_REPORT)
	_check(_shell.active_screen._report.text.contains(str(Flight.result["headline"])), "Original final report uses real outcome")
	_check(not RogueRun.active, "Story never enables the Rogue economy")
	if _failures.is_empty():
		print("PASS: complete original 11-stage Story flow through actual screen handlers, existing calculation/flight skip choices, all reviews, engineering, operations and final report")
		quit()
	else:
		quit(1)


func _board_review() -> void:
	_shell.active_screen._on_floor_clicked(_shell.active_screen._board)
	await _route(SceneRouter.BOARD_REVIEW)
	_shell.active_screen._on_ack_pressed()
	await _route(SceneRouter.HQ)


func _route(path: String) -> void:
	var deadline := Time.get_ticks_msec() + 6000
	while Time.get_ticks_msec() < deadline:
		if _shell.active_screen.scene_file_path == path and not root.get_node("SceneRouter").is_busy():
			await _frames(4)
			return
		await process_frame
	_check(false, "Story route: " + path)
