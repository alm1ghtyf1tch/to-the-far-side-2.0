extends SceneTree

func _initialize() -> void:
	create_timer(20).timeout.connect(func() -> void: quit(1))
	RogueRun.save_path = "res://.godot/rogue-framework-test.json"
	Flight.quick_start(10)
	var story := RogueBridge.capture()
	assert(RogueRun.start("Test agency", "science", "framework-seed"))
	var offers: Array = RogueRun.state["contract_offers"].duplicate(true)
	assert(RogueRun.save())
	assert(RogueRun.suspend())
	var restored := RogueBridge.capture()
	for model: String in story:
		for field: String in story[model]:
			if restored[model][field] != story[model][field]:
				print("RESTORE DIFFERENCE ", model, ".", field, ": ", story[model][field], " -> ", restored[model][field])
	assert(RogueBridge.capture() == story)
	assert(RogueRun.resume())
	# JSON numbers reload as floats; compare the serialized values, not Variant tags.
	assert(RogueRun.state["contract_offers"] == JSON.parse_string(JSON.stringify(offers)))
	assert(RogueRun.select_contract(0))
	assert(RogueRun.state["vehicle"].size() == 8)
	for number in 3:
		Flight.quick_start(11)
		RogueRun.state["phase"] = "flight"
		RogueRun.state["science_done"] = [RogueRun.state["contract"]["objective"]]
		assert(RogueRun.resolve_flight())
		var money := float(RogueRun.state["money"])
		assert(not RogueRun.resolve_flight() and float(RogueRun.state["money"]) == money)
		if number < 2:
			assert(RogueRun.next_mission())
			assert(RogueRun.select_contract(0))
	assert(RogueRun.state["phase"] == "complete" and RogueRun.state["history"].size() == 3)
	assert(RogueRun.next_mission(true))
	assert(RogueRun.state["endless"] and int(RogueRun.state["mission"]) == 4)
	RogueRun.suspend()
	assert(RogueBridge.capture() == story)
	print("PASS: Rogue framework, isolated Story state, saved offers, three real mission evaluations, duplicate reward guard and Endless transition")
	quit()
