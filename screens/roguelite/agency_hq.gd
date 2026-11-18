extends "res://screens/hq/hq.gd"
## Reuses the existing headquarters, room polygons and tactile controls.

var _actions: VBoxContainer
var _desk := {}


func _ready() -> void:
	super._ready()
	_actions = VBoxContainer.new()
	_actions.add_theme_constant_override("separation", 8)
	_panel_content.add_child(_actions)
	refresh()


func _process(_delta: float) -> void:
	pass # Agency time advances through explicit actions, never real-time HQ ticks.


func _show_stage() -> void:
	if not RogueRun.active:
		return
	_stage_label.text = "ROGUE ROCKET / MISSION %d%s" % [RogueRun.state["mission"], " / ENDLESS" if RogueRun.state["endless"] else ""]
	_title_label.text = str(RogueRun.state["agency"])
	_body_label.text = str(RogueRun.state.get("contract", {}).get("description", "Choose the agency's next mission contract."))
	_deadline_value.text = "DAY %d" % int(RogueRun.state["contract"]["deadline"]) if not RogueRun.state.get("contract", {}).is_empty() else "CHOOSE CONTRACT"
	var colours := [VisualTheme.AMBER, VisualTheme.CYAN, VisualTheme.PAPER, Color("eb8876")]
	_title_label.add_theme_color_override("font_color", colours[int(RogueRun.state["emblem"])])
	_budget_top_label.text = "%.1f cr" % float(RogueRun.state["money"])
	_info_box.hide()
	_roadmap.hide()
	_hint_label.text = ""
	_task_label.text = "Board: agency / Engineering: vehicle / Science: research"
	_goal = _board
	for floor: FloorHotspot in [_board, _engineering, _science]:
		floor.is_goal = true
	_diorama.set_goal(2)
	_diorama.set_programme(6, Campaign.site, RogueRun.state.get("vehicle", {}))
	_update_date()


func _update_date() -> void:
	if RogueRun.active:
		var preparation := int(RogueRun.state.get("mission_day", 0)) if RogueRun.state["phase"] in ["planning", "flight", "contract"] else 0
		_date_label.text = "AGENCY DAY %d" % (int(RogueRun.state.get("agency_days", 0)) + preparation)
		_day_label.text = "Seed: " + str(RogueRun.state["seed"])


func refresh() -> void:
	_show_stage()
	for child in _actions.get_children():
		_actions.remove_child(child)
		child.queue_free()
	_actions.add_child(RogueWidgets.label("Reputation %d / Knowledge %d / Test slots %d" % [RogueRun.state["reputation"], RogueRun.state["knowledge"], RogueRun.state["tests"]], 17, VisualTheme.CYAN))
	if RogueRun.state["phase"] == "contract":
		_actions.add_child(RogueWidgets.button("Choose mission contract", _contracts))
	elif RogueRun.state["phase"] == "planning":
		_actions.add_child(RogueWidgets.button("Agency / procurement / workbench", _management))
		_actions.add_child(RogueWidgets.button("Research portfolio", _research))
		_actions.add_child(RogueWidgets.button("Moon / science payload", func() -> void: SceneRouter.go_to(SceneRouter.ROGUE_SCIENCE)))
		_actions.add_child(RogueWidgets.button("Engineering / component draft", func() -> void: SceneRouter.go_to(SceneRouter.ROGUE_ASSEMBLY)))
		var problems := RogueRun.readiness()
		var launch := RogueWidgets.button("Authorize launch / Mission Control", _launch, problems.is_empty())
		launch.tooltip_text = "\n".join(PackedStringArray(problems)) if not problems.is_empty() else "Consume selected physical hardware and fund integration/operations exactly once."
		_actions.add_child(launch)
		var status := RogueWidgets.label(RogueRun.last_error if not RogueRun.last_error.is_empty() else (problems[0] if not problems.is_empty() else "Launch is ready."), 16, VisualTheme.AMBER)
		status.max_lines_visible = 3
		_actions.add_child(status)
		if RogueRun.can_close_unfunded():
			_actions.add_child(RogueWidgets.button("Close unfunded programme", func() -> void:
				RogueRun.close_unfunded()
				refresh()))
	elif RogueRun.state["phase"] == "flight":
		_actions.add_child(RogueWidgets.button("Resume Mission Control", func() -> void: SceneRouter.go_to(SceneRouter.ROGUE_CONTROL)))
	else:
		_actions.add_child(RogueWidgets.button("Agency results / mission history", _results))
		if RogueRun.state["phase"] == "debrief":
			_actions.add_child(RogueWidgets.button("Next mission contract", func() -> void:
				RogueRun.next_mission()
				refresh()))
		elif RogueRun.state["phase"] == "complete":
			_actions.add_child(RogueWidgets.button("Continue this agency / Endless mode", func() -> void:
				RogueRun.next_mission(true)
				refresh()))
			_actions.add_child(RogueWidgets.button("Finish the standard run", func() -> void:
				RogueRun.state["phase"] = "finished"
				RogueRun.save()
				refresh()))
	_actions.add_child(RogueWidgets.button("Save and return to main menu", _go_home))


func _contracts() -> void:
	_desk = RogueWidgets.sheet(self, "CONTRACT BOARD")
	var box: VBoxContainer = _desk["body"]
	for index in RogueRun.state["contract_offers"].size():
		var contract: Dictionary = RogueRun.state["contract_offers"][index]
		box.add_child(RogueWidgets.label(str(contract["title"]), 26, VisualTheme.AMBER))
		box.add_child(RogueWidgets.label("%s\nDeadline: day %d / base completion reward %.0f cr\nReference architecture: %s" % [contract["description"], contract["deadline"], contract["reward"], "Conventional lander / three-stage launcher" if contract["architecture"] == "classic" else "Separate lander delivery / high lunar orbit"], 19))
		box.add_child(RogueWidgets.button("Accept this contract", func() -> void:
			if RogueRun.select_contract(index):
				_desk["layer"].queue_free()
				refresh()))


func _on_floor_clicked(hotspot: FloorHotspot) -> void:
	if RogueRun.state["phase"] == "contract":
		_contracts()
	elif RogueRun.state["phase"] == "planning":
		if hotspot == _science:
			_research()
		elif hotspot == _engineering:
			SceneRouter.go_to(SceneRouter.ROGUE_ASSEMBLY)
		else:
			_management()
	elif RogueRun.state["phase"] == "flight":
		SceneRouter.go_to(SceneRouter.ROGUE_CONTROL)
	else:
		_results()


func _new_desk(title: String) -> VBoxContainer:
	if _desk.get("layer") and is_instance_valid(_desk["layer"]):
		_desk["layer"].queue_free()
	_desk = RogueWidgets.sheet(self, title)
	return _desk["body"]


func _action(call: Callable, page: Callable) -> void:
	call.call()
	refresh()
	page.call()


func _management() -> void:
	var box := _new_desk("AGENCY / PROCUREMENT / OPERATIONS")
	var s: Dictionary = RogueRun.state
	box.add_child(RogueWidgets.label("%.1f cr / prep day %d / deadline %d / %d free actions (%d total)" % [s["money"], s["mission_day"], s["contract"]["deadline"], RogueRun.available_actions(), s["actions"]], 22, VisualTheme.CYAN))
	if not RogueRun.last_error.is_empty():
		box.add_child(RogueWidgets.label(RogueRun.last_error, 19, VisualTheme.AMBER))
	var event: Dictionary = s["pending_event"]
	if not event.is_empty():
		box.add_child(RogueWidgets.label(str(event["title"]), 26, VisualTheme.AMBER))
		box.add_child(RogueWidgets.label(str(event["description"]) + " One action is reserved for this event.", 19))
		for index in event["choices"].size():
			var choice: Dictionary = event["choices"][index]
			var reason := RogueRun.event_reason(choice)
			var button := RogueWidgets.button(str(choice["name"]), func() -> void: _action(RogueRun.choose_event.bind(index), _management), reason.is_empty())
			button.tooltip_text = reason
			box.add_child(button)
	box.add_child(RogueWidgets.label("Abstract manufacturing stock / an order buys 8 units for 6 cr, one action and 15 days", 20, VisualTheme.MUTED))
	for material: String in s["materials"]:
		box.add_child(RogueWidgets.button("%s: %d / order +8" % [material.capitalize(), s["materials"][material]], func() -> void: _action(RogueRun.buy_material.bind(material), _management), RogueRun.available_actions() > 0 and float(s["money"]) >= 6))
		box.add_child(RogueWidgets.button("%s / bulk +16 / 12 cr / one action" % material.capitalize(), func() -> void: _action(RogueRun.buy_material.bind(material, 16), _management), RogueRun.available_actions() > 0 and float(s["money"]) >= 12))
	box.add_child(RogueWidgets.button("Research review / +3 knowledge / 3 cr / 1 action / 20 days", func() -> void: _action(RogueRun.research_action, _management), RogueRun.available_actions() > 0 and float(s["money"]) >= 3))
	box.add_child(RogueWidgets.button("Book laboratory batch / +2 test slots / 3 cr / 1 action / 20 days", func() -> void: _action(RogueRun.book_tests, _management), RogueRun.available_actions() > 0 and float(s["money"]) >= 3))
	box.add_child(RogueWidgets.button("Negotiate +1 science work period / 4 cr / 1 action / 20 days", func() -> void: _action(RogueRun.extend_science, _management), RogueRun.available_actions() > 0 and float(s["money"]) >= 4 and int(s["work_left"]) < 5))
	box.add_child(RogueWidgets.label("Engineering workbench / configuration effects use the original model", 24, VisualTheme.AMBER))
	for entry: Array in [["radio_backup", "Standby radio: duplicate radio mass, +30 W, +1.5 cr; one fault recovery"], ["life_reserve", "Reserve cartridge: +300 kg, +1 cr; one life-support recovery"]]:
		box.add_child(RogueWidgets.button(("ON / " if s["mods"][entry[0]] else "OFF / ") + str(entry[1]), func() -> void: _action(RogueRun.toggle_mod.bind(str(entry[0])), _management)))
	var targets := OptionButton.new()
	var slots := ["stage1", "stage2", "stage3", "service", "capsule", "lander"]
	for slot: String in slots:
		targets.add_item(str(Vehicle.slot(slot)["title"]))
	targets.custom_minimum_size.y = 42
	box.add_child(targets)
	box.add_child(RogueWidgets.button("Qualify selected design / 2.5 cr / 1 test / 1 action / 30 days", func() -> void: _action(RogueRun.qualify.bind(str(slots[targets.selected])), _management), RogueRun.available_actions() > 0 and int(s["tests"]) > 0 and float(s["money"]) >= 2.5))
	box.add_child(RogueWidgets.label("Flight preparations / charged once at launch", 24, VisualTheme.AMBER))
	var cost_label := RogueWidgets.label("Operations quote: %.1f cr" % Operations.cost(s["operations"]), 20)
	box.add_child(cost_label)
	for item: Dictionary in Operations.items():
		box.add_child(RogueWidgets.label(str(item["title"]), 18, VisualTheme.MUTED))
		var option := OptionButton.new()
		option.custom_minimum_size.y = 42
		for level: Dictionary in item["levels"]:
			option.add_item("%s / %.1f cr" % [level["name"], level["cost_pct"]])
		option.select(int(s["operations"][item["id"]]))
		option.item_selected.connect(func(level: int) -> void:
			RogueRun.set_operation(str(item["id"]), level)
			cost_label.text = "Operations quote: %.1f cr" % Operations.cost(s["operations"]))
		box.add_child(option)
	box.add_child(RogueWidgets.button("Bridge support / +15 cr now / repay 20 cr / -5 reputation", func() -> void: _action(RogueRun.bridge_grant, _management), not s["loan_taken"] and float(s["money"]) < 20 and int(s["reputation"]) >= 15))
	for slot: Dictionary in Vehicle.slots():
		for part: Dictionary in slot["parts"]:
			if int(s["inventory"].get(part["id"], 0)) > 0 and s["vehicle"].get(slot["id"]) != part["id"]:
				box.add_child(RogueWidgets.button("Sell unused %s / %.1f cr" % [part["name"], float(RogueCatalog.part(str(slot["id"]), str(part["id"])).get("cost_pct", 0)) * 0.55], func() -> void: _action(RogueRun.sell.bind(str(slot["id"]), str(part["id"])), _management)))


func _research() -> void:
	var box := _new_desk("SCIENCE / RESEARCH PORTFOLIO")
	box.add_child(RogueWidgets.label("Choose one or two focused objectives. Required instruments add real mass and power.\nWork periods: %d / outstanding grant commitments: %s" % [RogueRun.state["work_left"], RogueWidgets.research_names(RogueRun.state.get("grant_objectives", []))], 21, VisualTheme.CYAN))
	for id: String in RogueResearch.offers(RogueRun.state):
		var objective := RogueCatalog.find("objectives", id)
		var required: bool = id == RogueRun.state["contract"]["objective"]
		box.add_child(RogueWidgets.label(str(objective["name"]) + (" / REQUIRED" if required else ""), 24, VisualTheme.AMBER))
		box.add_child(RogueWidgets.label("%s\nGear: %s / %d work periods / +%d knowledge" % [objective["description"], RogueWidgets.instrument_names(objective["instruments"]), objective["work"], objective["knowledge"]], 19))
		box.add_child(RogueWidgets.button("Selected" if (RogueRun.state["portfolio"] as Array).has(id) else "Add to portfolio", func() -> void: _action(RogueRun.toggle_objective.bind(id), _research), not required))
	if not RogueRun.last_error.is_empty():
		box.add_child(RogueWidgets.label(RogueRun.last_error, 18, VisualTheme.AMBER))
	box.add_child(RogueWidgets.button("Open orbital Moon and instrument planner", func() -> void: SceneRouter.go_to(SceneRouter.ROGUE_SCIENCE)))


func _launch() -> void:
	if RogueRun.launch():
		SceneRouter.go_to(SceneRouter.ROGUE_CONTROL)
	else:
		refresh()


func _results() -> void:
	var box := _new_desk("AGENCY EVALUATION / SEED " + str(RogueRun.state["seed"]))
	box.add_child(RogueWidgets.label("%s / %s / %.1f cr / reputation %d / knowledge %d" % [RogueRun.state["agency"], str(RogueRun.state["phase"]).to_upper(), RogueRun.state["money"], RogueRun.state["reputation"], RogueRun.state["knowledge"]], 24, VisualTheme.CYAN))
	var summary := RogueRun.summary()
	box.add_child(RogueWidgets.label("Run grade %s / %d missions / %d contracts fulfilled / %d science points\n%d blueprints acquired / %d designs qualified" % [summary["grade"], summary["missions"], summary["contracts_fulfilled"], summary["cumulative_science"], RogueRun.state["blueprints"].size(), RogueRun.state["qualified"].size()], 21))
	for record: Dictionary in RogueRun.state["history"]:
		box.add_child(RogueWidgets.label("MISSION %d / %s / GRADE %s" % [record["mission"], record["contract"]["title"], record["grade"]], 26, VisualTheme.AMBER))
		box.add_child(RogueWidgets.label(str(record["result"]["headline"]), 22))
		var grades := PackedStringArray()
		for key: String in record["dimensions"]:
			grades.append("%s %.0f/100" % [key.capitalize(), record["dimensions"][key]])
		box.add_child(RogueWidgets.label("%s\nFocused research: %s / +%d knowledge / %.1f cr reward\nCommands: %s" % [" / ".join(grades), RogueWidgets.research_names(record["science_done"]), record["knowledge"], record["reward"], RogueWidgets.command_names(record["commands"])], 19))
		for event: Dictionary in RogueRun.state["events"]:
			if int(event["mission"]) == int(record["mission"]):
				box.add_child(RogueWidgets.label("Agency decision: %s / %s" % [RogueCatalog.find("events", str(event["event"])).get("title", "Development event"), event["choice"]["name"]], 18, VisualTheme.CYAN))
		for cause: Dictionary in record["result"].get("causes", []):
			box.add_child(RogueWidgets.label(str(cause.get("decision", "")) + " / " + str(cause.get("effect", "")), 17, VisualTheme.MUTED))


func _go_home() -> void:
	if RogueRun.suspend():
		SceneRouter.go_to(SceneRouter.MAIN_MENU)
	else:
		refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _desk.get("layer") and is_instance_valid(_desk["layer"]):
			_desk["layer"].queue_free()
		else:
			_go_home()
