extends SceneTree

func _initialize() -> void:
	create_timer(30).timeout.connect(func() -> void: quit(1))
	RogueRun.save_path = "res://.godot/rogue-economy-test.json"
	Campaign.reset()
	var original := RogueBridge.capture()
	assert(RogueRun.start("Procurement", "science", "economy"))
	assert(RogueRun.select_contract(0))
	var baseline := RogueCatalog.baseline(RogueRun.state["contract"])
	var stock_before: Dictionary = RogueRun.state["inventory"].duplicate()
	for slot: String in baseline:
		var offers := RogueDraft.offers(RogueRun.state, slot)
		assert(offers.has(baseline[slot]) and offers.size() <= 3)
		if int(RogueRun.state["inventory"].get(baseline[slot], 0)) == 0:
			assert(RogueRun.purchase(slot, baseline[slot]))
		if RogueRun.state["vehicle"].get(slot) != baseline[slot]:
			assert(RogueRun.install(slot, baseline[slot]))
	var result := RogueBridge.evaluate(RogueRun.state)
	assert(result["complete"] and Vehicle.shortfalls(result).is_empty())
	assert(RogueRun.state["inventory"].size() > stock_before.size())
	assert(float(RogueRun.state["money"]) >= float(result["workforce_cost"]) + Operations.cost(RogueRun.state["operations"]) + 6)
	var before: Dictionary = RogueRun.state.duplicate(true)
	RogueRun.state["money"] = 0.0
	assert(not RogueRun.purchase("stage1", baseline["stage1"]))
	assert(RogueRun.state["inventory"] == before["inventory"] and RogueRun.state["materials"] == before["materials"])
	RogueRun.state = before
	var seen := RogueDraft.offers(RogueRun.state, "stage3").duplicate()
	assert(RogueRun.save() and RogueRun.suspend() and RogueRun.resume())
	assert(RogueDraft.offers(RogueRun.state, "stage3") == seen)
	RogueRun.suspend()
	assert(RogueBridge.capture() == original)
	print("PASS: paid compatible draft, complete viable baseline, inventory/material expenditure, reserve feasibility, failed transaction isolation and saved offers")
	quit()
