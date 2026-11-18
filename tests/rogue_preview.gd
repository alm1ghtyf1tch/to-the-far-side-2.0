extends SceneTree
## Isolated in-memory scenario; never overwrite the player's saved Rogue agency.

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if OS.get_cmdline_user_args().has("--capture"):
		create_timer(60).timeout.connect(func() -> void: quit(1))
	RogueRun.save_path = "res://.godot/rogue-preview.json"
	RogueRun.start("Horizon Research Agency", "science", "horizon-11", 1)
	RogueRun.select_contract(0)
	var event: Dictionary = RogueRun.state["pending_event"]
	RogueRun.choose_event(event["choices"].size() - 1)
	RogueRun.confirm_science(str(RogueRun.state["site"]), RogueResearch.required_ids(RogueRun.state))
	var baseline := RogueCatalog.baseline(RogueRun.state["contract"])
	for slot: String in baseline:
		if int(RogueRun.state["inventory"].get(baseline[slot], 0)) == 0:
			RogueRun.purchase(slot, baseline[slot])
		if RogueRun.state["vehicle"].get(slot) != baseline[slot]:
			RogueRun.install(slot, baseline[slot])
	var shell: Control = load("res://systems/rendering/presentation_shell.tscn").instantiate()
	root.add_child(shell)
	current_scene = shell
	await process_frame
	GameSettings.apply_display(Vector2i(1920, 1080), GameSettings.BORDERLESS)
	GameSettings.set_visuals({"dynamic_movement": false})
	shell.open_screen(SceneRouter.ROGUE_HQ)
	await create_timer(0.6).timeout
	if not OS.get_cmdline_user_args().has("--capture"):
		return
	await _capture("agency")
	shell.active_screen._management()
	await create_timer(0.4).timeout
	await _capture("management")
	shell.active_screen._desk["layer"].queue_free()
	shell.active_screen._research()
	await create_timer(0.4).timeout
	await _capture("research")
	shell.open_screen(SceneRouter.ROGUE_SCIENCE)
	await create_timer(0.7).timeout
	await _capture("moon")
	shell.open_screen(SceneRouter.ROGUE_ASSEMBLY)
	await create_timer(0.6).timeout
	await _capture("assembly")
	RogueRun.launch()
	shell.open_screen(SceneRouter.ROGUE_CONTROL)
	await create_timer(0.6).timeout
	await _capture("control")
	quit()


func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/rogue-%s.png" % label)
