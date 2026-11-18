extends SceneTree
## Opens Phase 3 through the real compositor without changing saved settings.
## -- --capture saves review screenshots and exits; otherwise stays interactive.

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	Campaign.reset()
	Campaign.stage = 4
	Campaign.clock_running = false
	var shell: Control = load("res://systems/rendering/presentation_shell.tscn").instantiate()
	root.add_child(shell)
	current_scene = shell
	await process_frame
	GameSettings.apply_display(Vector2i(1920, 1080), GameSettings.BORDERLESS)
	shell.open_screen(SceneRouter.SCIENCE_PLAN)
	await create_timer(2.0).timeout
	if not "--capture" in OS.get_cmdline_user_args():
		return
	await _capture("overview")
	var planner: Control = shell.active_screen
	planner.select_site(5)
	await create_timer(1.0).timeout
	await _capture("site")
	planner.show_step(1)
	planner.toggle_instrument(0)
	planner.toggle_instrument(7)
	await create_timer(0.6).timeout
	await _capture("payload")
	quit()


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/phase3-%s.png" % label)
