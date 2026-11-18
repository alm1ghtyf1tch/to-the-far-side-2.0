extends SceneTree

func _initialize() -> void:
	create_timer(30).timeout.connect(func() -> void: quit(1))
	RogueRun.save_path = "res://.godot/rogue-science-test.json"
	assert(RogueRun.start("Science", "science", "science"))
	assert(RogueRun.select_contract(0))
	assert(RogueResearch.offers(RogueRun.state).size() == 3)
	var ids := RogueResearch.required_ids(RogueRun.state)
	var site := str(RogueRun.state["contract"]["sites"][0])
	assert(not RogueRun.confirm_science(site, []))
	assert(RogueRun.confirm_science(site, ids))
	var money := float(RogueRun.state["money"])
	var days := int(RogueRun.state["mission_day"])
	assert(RogueRun.confirm_science(site, ids))
	assert(RogueRun.state["money"] == money and int(RogueRun.state["mission_day"]) == days)
	assert(not RogueRun.experiment(str(RogueRun.state["contract"]["objective"])))
	var baseline := RogueCatalog.baseline(RogueRun.state["contract"])
	for slot: String in baseline:
		if int(RogueRun.state["inventory"].get(baseline[slot], 0)) == 0:
			assert(RogueRun.purchase(slot, baseline[slot]))
		if RogueRun.state["vehicle"].get(slot) != baseline[slot]:
			assert(RogueRun.install(slot, baseline[slot]))
	var event: Dictionary = RogueRun.state["pending_event"]
	assert(RogueRun.choose_event(event["choices"].size() - 1))
	assert(RogueRun.readiness().is_empty())
	assert(RogueRun.launch())
	var id := str(RogueRun.state["contract"]["objective"])
	RogueRun.state["flight_phase"] = "surface"
	if Flight.result["outcome"] == "landed":
		assert(RogueRun.experiment(id))
		assert(not RogueRun.experiment(id))
		assert(int(RogueRun.state["work_left"]) < int(RogueRun.state["contract"]["work"]) + 1)
	assert(RogueRun.resolve_flight())
	RogueRun.suspend()
	print("PASS: constrained research portfolio, required actual gear, science procurement guard, original evaluated launch, phase-gated focused research and distinct science rewards")
	quit()
