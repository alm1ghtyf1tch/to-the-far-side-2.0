extends "res://screens/engineering/vehicle_assembly.gd"
## Mode-specific procurement; the approved hangar/controller remain reusable.


func _ready() -> void:
	RogueBridge.project(RogueRun.state)
	super._ready()
	var skip := RogueWidgets.button("Skip draft / +1 stock / 1 action", func() -> void:
		RogueRun.skip_draft(_slot_id)
		_fill_cards()
		_refresh())
	skip.tooltip_text = "Spend one agency action and 15 days; receive one structural stock and a new seeded offer."
	_ui.sections.content.add_child(skip)
	_ui.sections.content.move_child(skip, 0)
	_refresh()


func _fill_cards() -> void:
	super._fill_cards()
	if _slot_id == "spaceport":
		return
	var offers := RogueDraft.offers(RogueRun.state, _slot_id)
	for card: AssemblyOptionCard in _option_cards.duplicate():
		var id := str(card.part["id"])
		if not offers.has(id) and not RogueRun.state["blueprints"].has(id) and int(RogueRun.state["inventory"].get(id, 0)) <= 0:
			_option_cards.erase(card)
			_ui.cards.remove_child(card)
			card.queue_free()
			continue
		card.tooltip_text = "Owned physical units: %d\nMaterials: %s\n%s" % [RogueRun.state["inventory"].get(id, 0), RogueWidgets.stock_text(RogueCatalog.material_recipe(_slot_id, id)), "Current draft offer" if offers.has(id) else "Known blueprint / 25% expedited manufacture surcharge"]
		var action := _find_action(card, "Install")
		if action and int(RogueRun.state["inventory"].get(id, 0)) <= 0:
			action.text = "Buy %.1f cr" % (float(RogueCatalog.part(_slot_id, id).get("cost_pct", 0)) * (1 if offers.has(id) else 1.25))
			var reason := _purchase_reason(id)
			action.disabled = not reason.is_empty()
			card.disabled = action.disabled
			if not reason.is_empty():
				card.tooltip_text += "\nUNAVAILABLE / " + reason
		card.details_requested.connect(_sheet_availability.bind(id))


func _purchase_reason(id: String) -> String:
	var price := float(RogueCatalog.part(_slot_id, id).get("cost_pct", 0)) * (1.0 if RogueDraft.offers(RogueRun.state, _slot_id).has(id) else 1.25)
	if float(RogueRun.state["money"]) < price:
		return "Insufficient funding for this quote."
	for material: String in RogueCatalog.material_recipe(_slot_id, id):
		if int(RogueRun.state["materials"].get(material, 0)) < int(RogueCatalog.material_recipe(_slot_id, id)[material]):
			return "Order more " + material + " from the agency."
	return ""


func _sheet_availability(id: String) -> void:
	var action := _find_action(_ui.sheet, "Install / remove")
	if action:
		action.disabled = false
		action.tooltip_text = ""
	if action and int(RogueRun.state["inventory"].get(id, 0)) <= 0:
		var reason := _purchase_reason(id)
		action.disabled = not reason.is_empty()
		action.tooltip_text = reason


func _fill_site_info() -> void:
	super._fill_site_info()
	if _shown_site.is_empty():
		return
	var action := _find_action(_site_info, "Launch from here")
	if action and not RogueDraft.offers(RogueRun.state, "spaceport").has(_shown_site) and not RogueRun.state["blueprints"].has(_shown_site):
		action.disabled = true
		action.text = "Not in this procurement window"


func install(part_id: String) -> void:
	if int(RogueRun.state["inventory"].get(part_id, 0)) <= 0:
		var emergency := not RogueDraft.offers(RogueRun.state, _slot_id).has(part_id)
		if not RogueRun.purchase(_slot_id, part_id, emergency):
			_status.text = RogueRun.last_error
			return
	super.install(part_id)
	RogueRun.state["vehicle"] = _choice
	RogueRun.save()


func _refresh() -> void:
	RogueBridge.project(RogueRun.state)
	super._refresh()
	var result := Vehicle.evaluate(_choice)
	var integration := float(result["cost"]) - RogueBridge.owned_value(_choice)
	_ui.budget.text = "FUNDS %.1f cr / %d ACTIONS" % [RogueRun.state["money"], RogueRun.state["actions"]]
	_values["cost"].text = "%.1f cr valuation / %.1f cr integration & modifications still unpaid" % [result["cost"], integration]
	var spare := int(RogueRun.state["contract"]["deadline"]) - int(result["ready_day"])
	_values["ready"].text = "Prep day %d / %d days %s the contract deadline" % [result["ready_day"], absi(spare), "before" if spare >= 0 else "after"]
	(_ui.budget.get_parent().get_child(1) as Label).text = "PREP DAY %d / CONTRACT DEADLINE %d" % [RogueRun.state["mission_day"], RogueRun.state["contract"]["deadline"]]
	_reserve_note.text = "Every speed requirement retains the reference analysis reserve of ±%.1f%%. Hardware is paid at procurement. Integration, configured reserve equipment and operations are paid at launch. Contract deadline: preparation day %d." % [Campaign.margin, RogueRun.state["contract"]["deadline"]]
	if spare < 0:
		_ui.warnings.text += "\nContract schedule overrun: %d days" % -spare
	_status.text = RogueRun.last_error if not RogueRun.last_error.is_empty() else "Hardware is paid at procurement; physical units are consumed at launch. Esc returns to the agency."
	_hand_over.text = "Return to agency / readiness"
	_hand_over.disabled = false
	var skip := _find_action(_ui.sections, "Skip draft / +1 stock / 1 action")
	if skip:
		skip.disabled = RogueRun.available_actions() <= 0


func _on_hand_over_pressed() -> void:
	RogueRun.save()
	SceneRouter.go_to(SceneRouter.ROGUE_HQ)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _read_more.is_open():
			_read_more.close()
		elif _ui.sheet.visible:
			_ui.sheet.hide()
		elif _site_overlay.visible:
			_site_overlay.hide()
		else:
			_on_hand_over_pressed()


func _find_action(node: Node, text: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == text:
			return child
		var result := _find_action(child, text)
		if result:
			return result
	return null
