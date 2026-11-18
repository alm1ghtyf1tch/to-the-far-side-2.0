extends SceneTree
## Isolated stage-10 preview; -- --capture produces actual CRT screenshots and exits.

var _shell: Control


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	Flight.quick_start(10)
	_shell = load("res://systems/rendering/presentation_shell.tscn").instantiate()
	root.add_child(_shell)
	current_scene = _shell
	await process_frame
	GameSettings.apply_display(Vector2i(1920, 1080), GameSettings.BORDERLESS)
	_shell.open_screen(SceneRouter.MISSION_CONTROL)
	await create_timer(0.8).timeout
	if not "--capture" in OS.get_cmdline_user_args():
		return
	var mission: Control = _shell.active_screen
	await _capture("ready")
	mission.choose(true)
	mission._timer.stop()
	var previous := ""
	var separated := false
	var chutes := false
	for step in 140:
		if mission._finished:
			break
		if mission._gate != "":
			mission.choose(false)
		mission.next_line()
		mission._timer.stop()
		if mission._phase_index >= mission._phases.size():
			continue
		var id := str(mission._phases[mission._phase_index]["id"])
		if id != previous and mission._line_index >= 0:
			previous = id
			await create_timer(0.8).timeout
			await _capture(id)
		if not separated and id == "ascent" and mission._view.staged == 1:
			separated = true
			await create_timer(0.5).timeout
			await _capture("separation")
		if not chutes and mission._view.space.spacecraft._chutes.visible:
			chutes = true
			await create_timer(0.8).timeout
			await _capture("parachutes")
	await create_timer(0.8).timeout
	await _capture("complete")
	quit()


func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/phase4-%s.png" % label)
