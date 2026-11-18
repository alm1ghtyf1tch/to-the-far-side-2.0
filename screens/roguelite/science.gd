extends "res://screens/science_plan/science_plan.gd"
## Original orbital Moon/gear planner with contract-scoped research requirements.


func _ready() -> void:
	RogueBridge.project(RogueRun.state)
	super._ready()
	for index in Campaign.sites().size():
		_site_cards[index].disabled = not (RogueRun.state["contract"]["sites"] as Array).has(Campaign.sites()[index]["id"])
		if Campaign.sites()[index]["id"] == RogueRun.state["site"]:
			_site_index = index
	for index in Campaign.instrument_options().size():
		_picked[index] = (RogueRun.state["instruments"] as Array).has(Campaign.instrument_options()[index]["id"])
	_refresh()


func _refresh() -> void:
	super._refresh()
	_ui.status.text = "Required gear: %s / funds %.1f cr" % [RogueWidgets.instrument_names(RogueResearch.required_ids(RogueRun.state)), RogueRun.state["money"]]
	var quote := 0.0
	var needed_stock := 0
	var selected := []
	for item: Dictionary in _chosen():
		selected.append(item["id"])
		if int(RogueRun.state["science_stock"].get(item["id"], 0)) == 0:
			quote += float(item["cost_pct"])
			needed_stock += 1
	AnimatedValue.show_value(_ui.values["left"], float(RogueRun.state["money"]) - quote, " cr", 1)
	AnimatedValue.show_value(_ui.values["cost"], quote, " cr", 1)
	if _step == 1:
		for id: String in RogueResearch.required_ids(RogueRun.state):
			if not selected.has(id):
				_ui.confirm.disabled = true
		if quote > float(RogueRun.state["money"]) or needed_stock > int(RogueRun.state["materials"]["electronics"]):
			_ui.confirm.disabled = true


func _gear_specs(item: Dictionary) -> String:
	return "%s kg / %s W / %.1f cr / 1 electronics stock" % [item["mass_kg"], item["power_w"], float(item["cost_pct"])]


func select_site(index: int) -> void:
	if not (RogueRun.state["contract"]["sites"] as Array).has(Campaign.sites()[index]["id"]):
		return
	super.select_site(index)


func _on_confirm_pressed() -> void:
	if _locked or _site_index < 0:
		return
	if _step == 0:
		show_step(1)
		return
	var ids := []
	for item: Dictionary in _chosen():
		ids.append(item["id"])
	if not RogueRun.confirm_science(str(Campaign.sites()[_site_index]["id"]), ids):
		_ui.status.text = RogueRun.last_error
		return
	_locked = true
	SceneRouter.go_to(SceneRouter.ROGUE_HQ)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _read_more.is_open():
			_read_more.close()
		else:
			SceneRouter.go_to(SceneRouter.ROGUE_HQ)
