extends "res://tests/simulation_regression.gd"
## Full real-model runs and mathematical generation coverage, not human balance.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(150).timeout.connect(func() -> void:
		push_error("Rogue run regression timed out")
		quit(1))
	RogueRun.save_path = "res://.godot/rogue-runs-test.json"
	Campaign.reset()
	var story := RogueBridge.capture()
	assert(RogueRun.start("Seed sweep", "science", "generation"))
	assert(RogueRun.select_contract(0))
	var reference: Dictionary = RogueRun.state.duplicate(true)
	var checked := 0
	for seed_number in 500:
		var mission_number := seed_number % 12 + 1
		for contract: Dictionary in RogueCatalog.contract_offers("seed-%d" % seed_number, mission_number):
			var candidate := reference.duplicate(true)
			candidate["contract"] = contract
			candidate["vehicle"] = RogueCatalog.baseline(contract)
			candidate["instruments"] = RogueCatalog.find("objectives", str(contract["objective"]))["instruments"].duplicate()
			candidate["mission_day"] = 0
			for site: String in contract["sites"]:
				candidate["site"] = site
				var stats := RogueBridge.evaluate(candidate)
				assert(Vehicle.shortfalls(stats).is_empty(), "Seeded reference violates the original engineering model")
				assert(int(stats["program_days"]) + 14 * 7 + 5 + 35 <= int(contract["deadline"]), "Reference procurement/build schedule is impossible")
				checked += 1
			if mission_number == 1:
				for doctrine: Dictionary in RogueCatalog.rules()["doctrines"]:
					candidate["inventory"] = {}
					for slot: String in RogueCatalog.rules()["starter_slots"]:
						candidate["inventory"][candidate["vehicle"][slot]] = 1
					candidate["money"] = doctrine["money"]
					var cost := float(RogueDraft.cost_to_complete(candidate)["cost"])
					assert(cost + 4.0 + 1.5 <= float(candidate["money"]), "Starter reference has no funding path")
		if seed_number % 50 == 0:
			await process_frame
	print("PASS: %d allowed-site reference configurations across 500 seeds and bounded standard/Endless levels; starter funding paths in all four doctrines" % checked)
	RogueRun.suspend()
	for seed_text: String in ["horizon-11", "geology-42", "agency-900"]:
		assert(RogueRun.start("Run " + seed_text, "science", seed_text))
		for mission_index in 4:
			assert(_prepare_mission())
			var inventory: Dictionary = RogueRun.state["inventory"].duplicate()
			assert(RogueRun.launch(), RogueRun.last_error)
			assert(not RogueRun.launch())
			for slot: String in RogueRun.state["vehicle"]:
				var id := str(RogueRun.state["vehicle"][slot])
				assert(int(RogueRun.state["inventory"][id]) == int(inventory[id]) - (0 if slot in ["ground", "spaceport"] else 1))
			var flight := RogueBridge.capture()
			assert(RogueRun.save() and RogueRun.suspend() and RogueRun.resume())
			assert(_equivalent(RogueBridge.capture(), flight, "flight-resume"))
			RogueRun.state["flight_phase"] = "coast"
			for command: String in ["radio_backup", "life_reserve"]:
				if RogueRun.command_reason(command).is_empty():
					assert(RogueRun.command(command))
			RogueRun.state["flight_phase"] = "surface"
			var objective := str(RogueRun.state["contract"]["objective"])
			if Flight.result["outcome"] == "landed":
				assert(RogueRun.experiment(objective), RogueRun.last_error)
			var before_reward := float(RogueRun.state["money"])
			assert(RogueRun.resolve_flight())
			var after_reward := float(RogueRun.state["money"])
			assert(after_reward > before_reward and not RogueRun.resolve_flight() and float(RogueRun.state["money"]) == after_reward)
			assert(RogueRun.save() and RogueRun.suspend() and RogueRun.resume())
			print("Run %s mission %d: %s / funds %.1f cr / grade %s" % [seed_text, mission_index + 1, RogueRun.state["history"][-1]["result"]["outcome"], RogueRun.state["money"], RogueRun.state["history"][-1]["grade"]])
			if mission_index < 2:
				assert(RogueRun.next_mission())
			elif mission_index == 2:
				assert(RogueRun.state["phase"] == "complete" and RogueRun.state["history"].size() == 3)
				assert(RogueRun.next_mission(true))
		assert(RogueRun.state["endless"] and RogueRun.state["history"].size() == 4)
		RogueRun.suspend()
		assert(RogueBridge.capture() == story)
	assert(RogueRun.start("Contingency fixture", "science", "horizon-11"))
	assert(_prepare_mission())
	assert(RogueRun.launch())
	Flight.build["latent"] = {"comms": true, "life": true}
	Flight.fly()
	RogueRun.state["flight_phase"] = "coast"
	assert(RogueRun.command("radio_backup") and not RogueRun.command("radio_backup"))
	assert(not Flight.build["latent"].has("comms"))
	assert(RogueRun.command("life_reserve") and not Flight.build["latent"].has("life"))
	var budget := Campaign.budget_left
	assert(not RogueRun.command("life_reserve") and Campaign.budget_left == budget)
	# Original simulator's genuine abort result, then the distinct partial payout.
	Flight.fly({"landing": {"result": "abort", "speed": 8.0, "fuel": 2.0}})
	assert(Flight.result["outcome"] != "landed")
	assert(RogueRun.resolve_flight() and not RogueRun.state["history"][-1]["fulfilled"])
	RogueRun.suspend()
	assert(RogueRun.start("Unfunded fixture", "science", "unfunded"))
	assert(RogueRun.select_contract(0))
	RogueRun.state["inventory"] = {}
	RogueRun.state["money"] = 0.0
	RogueRun.state["loan_taken"] = true
	assert(RogueRun.close_unfunded() and RogueRun.state["phase"] == "failed")
	RogueRun.suspend()
	assert(RogueBridge.capture() == story)
	print("PASS: three standard runs, Endless missions, actual hardware consumption, planning/flight/between-mission saves, no repeated rewards, physical backup commands, real abort and agency failure")
	quit()


func _prepare_mission() -> bool:
	var contract_index := 0
	for index in RogueRun.state["contract_offers"].size():
		if RogueRun.state["contract_offers"][index]["id"] == "mare":
			contract_index = index
	if not RogueRun.select_contract(contract_index):
		return false
	var event: Dictionary = RogueRun.state["pending_event"]
	if not RogueRun.choose_event(event["choices"].size() - 1):
		return false
	var baseline := RogueCatalog.baseline(RogueRun.state["contract"])
	var need := {"structures": 0, "propulsion": 0, "electronics": 2}
	for slot: String in baseline:
		if int(RogueRun.state["inventory"].get(baseline[slot], 0)) <= 0:
			for material: String in RogueCatalog.material_recipe(slot):
				need[material] += int(RogueCatalog.material_recipe(slot)[material])
	var gear := RogueResearch.required_ids(RogueRun.state)
	for id: String in gear:
		if int(RogueRun.state["science_stock"].get(id, 0)) <= 0:
			need["electronics"] += 1
	for material: String in need:
		var shortage := int(need[material]) - int(RogueRun.state["materials"][material])
		if shortage > 0 and not RogueRun.buy_material(material, 16 if shortage > 8 else 8):
			push_error(RogueRun.last_error)
			return false
	if not RogueRun.confirm_science(str(RogueRun.state["site"]), gear):
		return false
	for slot: String in baseline:
		if int(RogueRun.state["inventory"].get(baseline[slot], 0)) <= 0 and not RogueRun.purchase(slot, baseline[slot]):
			return false
		if RogueRun.state["vehicle"].get(slot) != baseline[slot] and not RogueRun.install(slot, baseline[slot]):
			return false
	for mod: String in ["radio_backup", "life_reserve"]:
		if not RogueRun.state["mods"][mod]:
			RogueRun.toggle_mod(mod)
	var problems := RogueRun.readiness()
	if problems.size() == 1 and problems[0].begins_with("Keep enough funding"):
		# A real scarcity decision: stop carrying optional reserves when the agency
		# needs that funding for integration/operations. Never inflate the budget.
		for mod: String in ["radio_backup", "life_reserve"]:
			if RogueRun.state["mods"][mod]:
				RogueRun.toggle_mod(mod)
		problems = RogueRun.readiness()
	if not problems.is_empty():
		push_error(str(problems))
	return problems.is_empty()
