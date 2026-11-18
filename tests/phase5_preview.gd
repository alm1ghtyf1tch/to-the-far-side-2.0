extends SceneTree
## Isolated preview of a real, selected draft. Saved preferences are never written.

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	Flight.quick_start(10)
	Vehicle.draft = Vehicle.design.duplicate()
	if "--empty" in OS.get_cmdline_user_args():
		Vehicle.draft.clear()
	Campaign.stage = 6
	Campaign.budget_left = 80.0
	Campaign.clock_running = false
	var shell: Control = load("res://systems/rendering/presentation_shell.tscn").instantiate()
	root.add_child(shell)
	current_scene = shell
	await process_frame
	GameSettings.apply_display(Vector2i(1920, 1080), GameSettings.BORDERLESS)
	shell.open_screen(SceneRouter.ENGINEERING)
	await create_timer(1.0).timeout
	if not "--capture" in OS.get_cmdline_user_args():
		return
	var assembly: Control = shell.active_screen
	# Park synthetic input away from cards so desktop cursor location cannot choose
	# a provisional model in the review capture.
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(960, 140)
	motion.global_position = motion.position
	root.push_input(motion, true)
	assembly._cancel_preview()
	await create_timer(0.35).timeout
	await _capture("assembly")
	assembly._ui.toggle_focus()
	await create_timer(0.4).timeout
	await _capture("focus")
	assembly._ui.toggle_focus()
	assembly.select_slot("lander")
	await create_timer(0.5).timeout
	await _capture("lander")
	assembly._ui.show_sheet(Vehicle.chosen({"lander": "lander_hls"}, "lander"))
	await create_timer(0.3).timeout
	await _capture("technical-sheet")
	assembly._ui.sheet.hide()
	assembly.select_slot("spaceport")
	assembly.show_site("port_ksc")
	await create_timer(0.4).timeout
	await _capture("launch-site")
	quit()


func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/phase5-%s.png" % label)
