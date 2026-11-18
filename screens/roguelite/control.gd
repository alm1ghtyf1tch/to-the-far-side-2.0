extends "res://screens/flight/mission_control.gd"
## Reuses original flight playback/piloting; commands consume actual capabilities.

var _command_sheet := {}
var _commands_open := false
var _command_phase := ""
var _dashboard_panel: Control
var _dashboard_tab: Button
var _run_identity := ""
var _mission_number := 0


func _build_presentation() -> void:
	_result = _contract_view_result(Flight.result)
	super._build_presentation()
	var header_summary := _ui.get_child(1).get_child(0).get_child(0).get_child(1) as Label
	header_summary.text = "%s → %s\nMISSION %d / LAUNCH PREP DAY %d" % [Vehicle.launch_site().get("short", ""), Campaign.site.get("name", ""), RogueRun.state["mission"], Flight.result.get("launch_day", 0)]
	# Run-only full-bleed composition. Original Story Mission Control is untouched.
	_view.reparent(_frame, false)
	_frame.move_child(_view, 0)
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	(_ui.get_child(0) as Control).hide()
	RogueWidgets.edge_shade(_ui, true)
	RogueWidgets.edge_shade(_ui, false)
	var observation := _ui.view_slot.get_parent().get_parent() as PanelContainer
	observation.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_dashboard_panel = _ui._monitoring.get_parent().get_parent() as Control
	_dashboard_tab = RogueWidgets.button("Dashboard −", func() -> void:
		_dashboard_panel.visible = not _dashboard_panel.visible
		_dashboard_tab.text = "Dashboard −" if _dashboard_panel.visible else "Dashboard +")
	_dashboard_tab.anchor_left = 1
	_dashboard_tab.anchor_right = 1
	_dashboard_tab.offset_left = -310
	_dashboard_tab.offset_right = -90
	_dashboard_tab.offset_top = 114
	_dashboard_tab.offset_bottom = 156
	_frame.add_child(_dashboard_tab)


func _ready() -> void:
	_run_identity = str(RogueRun.state.get("run_id", ""))
	_mission_number = int(RogueRun.state["mission"])
	RogueBridge.project(RogueRun.state)
	_frame.reparent(self, false)
	_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_node("Aspect").hide()
	super._ready()
	_skip_button.text = "Save / agency"
	_report_button.text = "Agency debrief ›"
	_restore_playback.call_deferred()


func _restore_playback() -> void:
	var saved: Dictionary = RogueRun.state.get("playback", {})
	_overrides = saved.get("overrides", {}).duplicate(true)
	_phase_index = clampi(int(saved.get("phase", 0)), 0, _phases.size())
	_manual_ascent = bool(saved.get("manual_ascent", false))
	_ascent_flown = bool(saved.get("ascent_flown", false))
	_landing_flown = bool(saved.get("landing_flown", false))
	_landing_chosen = _landing_flown
	_launched = bool(saved.get("launched", false))
	if _phase_index == 0:
		return
	_gate = ""
	_gate_box.hide()
	_line_index = -1
	for index in _phase_index:
		var phase: Dictionary = _phases[index]
		for line: Dictionary in phase["lines"]:
			_add_line(phase, line)
		_mark_row(str(phase["id"]), "done")
	_step()


func _step() -> void:
	if _commands_open:
		return
	if not _finished and _gate.is_empty() and _game == null and _line_index < 0 and _phase_index < _phases.size():
		var id := str(_phases[_phase_index]["id"])
		RogueRun.state["flight_phase"] = id
		_checkpoint()
		if id in ["coast", "surface"] and not RogueRun.state["command_done"].has("window_" + id):
			_open_commands(id)
			return
	super._step()


func _open_commands(phase: String) -> void:
	_timer.stop()
	_commands_open = true
	_command_phase = phase
	_command_sheet = RogueWidgets.sheet(self, "FLIGHT DIRECTOR / " + phase.to_upper())
	_command_sheet["close"].text = "Continue planned coast" if phase == "coast" else "Finish focused science allocation / continue"
	_command_sheet["close"].pressed.connect(_end_commands)
	var box: VBoxContainer = _command_sheet["body"]
	box.add_child(RogueWidgets.label("Scientific work periods remaining: %d\nRequired contract research: %s" % [RogueRun.state["work_left"], RogueWidgets.research_names([RogueRun.state["contract"]["objective"]])], 23, VisualTheme.CYAN))
	if phase == "coast":
		box.add_child(RogueWidgets.label("Routine operations and contingencies", 28, VisualTheme.AMBER))
		for command: Array in [["survey", "Camera calibration / orbital observations / 1 work period / +1 knowledge on safe return"], ["radio_backup", "Switch to the installed standby radio"], ["life_reserve", "Use the carried reserve life-support cartridge"]]:
			var reason := RogueRun.command_reason(str(command[0]))
			var button := RogueWidgets.button(str(command[1]), _command.bind(str(command[0])), reason.is_empty())
			button.tooltip_text = reason
			box.add_child(button)
			if not reason.is_empty():
				box.add_child(RogueWidgets.label(reason, 17, VisualTheme.MUTED))
	else:
		box.add_child(RogueWidgets.label("Focused research sessions use the instruments deployed by the original mission simulation. Prioritize the contract; remaining work may not cover the whole portfolio.", 21))
		for id: String in RogueRun.state["portfolio"]:
			var objective := RogueCatalog.find("objectives", id)
			var reason := RogueResearch.experiment_reason(RogueRun.state, id)
			var button := RogueWidgets.button("%s / %d work / +%d knowledge" % [objective["name"], objective["work"], objective["knowledge"]], _experiment.bind(id), reason.is_empty())
			button.tooltip_text = reason
			box.add_child(button)
			box.add_child(RogueWidgets.label(str(objective["description"]) + ("\n" + reason if not reason.is_empty() else ""), 18, VisualTheme.MUTED))
	if not RogueRun.last_error.is_empty():
		box.add_child(RogueWidgets.label(RogueRun.last_error, 18, VisualTheme.AMBER))


func _command(id: String) -> void:
	RogueRun.command(id)
	_result = _contract_view_result(Flight.result)
	_phases = _result["phases"]
	_refresh_commands()


func _experiment(id: String) -> void:
	RogueRun.experiment(id)
	_result = _contract_view_result(Flight.result)
	_refresh_commands()


func _refresh_commands() -> void:
	_command_sheet["layer"].queue_free()
	_open_commands(_command_phase)


func _end_commands() -> void:
	RogueRun.state["command_done"]["window_" + _command_phase] = true
	_commands_open = false
	_checkpoint()
	_step()


func _open_gate(kind: String) -> void:
	if _dashboard_panel:
		_dashboard_panel.show()
		_dashboard_tab.text = "Dashboard −"
	super._open_gate(kind)


func _checkpoint() -> void:
	if not RogueRun.active or str(RogueRun.state.get("run_id", "")) != _run_identity or int(RogueRun.state["mission"]) != _mission_number:
		return
	RogueRun.state["playback"] = {"phase": _phase_index, "overrides": _overrides.duplicate(true),
		"manual_ascent": _manual_ascent, "ascent_flown": _ascent_flown,
		"landing_flown": _landing_flown, "launched": _launched}
	RogueRun.state["context"] = RogueBridge.capture()
	RogueRun.save()


func _refly() -> void:
	super._refly()
	_result = _contract_view_result(Flight.result)
	_phases = _result["phases"]
	_checkpoint()


func skip_to_end() -> void:
	# This run-only control is Save/agency. Story retains its original Skip action.
	_save_return()


func _save_return() -> void:
	if _game != null:
		_info_label.text = "Finish the piloting segment before leaving. An interrupted app resumes from the same seeded phase boundary."
		return
	_timer.stop()
	_checkpoint()
	SceneRouter.go_to(SceneRouter.ROGUE_HQ)


func open_report() -> void:
	if RogueRun.resolve_flight():
		_report_button.disabled = true
		SceneRouter.go_to(SceneRouter.ROGUE_HQ)


func _finish() -> void:
	_result = _contract_view_result(Flight.result)
	super._finish()
	_values["budget"].text = "%.1f cr after flight" % float(Flight.result["budget_left"])
	_checkpoint()


func _unhandled_input(event: InputEvent) -> void:
	if _commands_open:
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_command_sheet["layer"].queue_free()
			_end_commands()
		return
	if event.is_action_pressed("ui_cancel") and not _ui.details.visible:
		get_viewport().set_input_as_handled()
		_save_return()
	else:
		super._unhandled_input(event)


func _exit_tree() -> void:
	if RogueRun.active and RogueRun.state.get("phase") == "flight":
		_checkpoint()


func _contract_view_result(original: Dictionary) -> Dictionary:
	# Presentation copy only: retain the original outcome and replay dictionary.
	var view := original.duplicate(true)
	if view.get("objectives", []).size() >= 5:
		view["objectives"][2] = {"text": "Launch by preparation day %d" % int(RogueRun.state["contract"]["deadline"]), "met": int(original.get("launch_day", 99999)) <= int(RogueRun.state["contract"]["deadline"])}
		var research_done: bool = (RogueRun.state["science_done"] as Array).has(str(RogueRun.state["contract"]["objective"]))
		view["objectives"][4] = {"text": "Complete contracted focused research", "met": research_done}
		if original.get("outcome") == "landed" and not research_done:
			view["headline"] = "Landing complete / contracted research incomplete"
	return view
