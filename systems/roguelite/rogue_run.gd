class_name RogueRun
extends RefCounted
## Persistent agency state. Original models remain authoritative inside the scope.

static var active := false
static var state := {}
static var last_error := ""
static var save_path := RogueSave.PATH


static func start(agency: String, doctrine_id: String, seed_text: String, emblem := 0) -> bool:
	var doctrine := RogueCatalog.find("doctrines", doctrine_id)
	if doctrine.is_empty():
		return fail("Unknown agency doctrine.")
	if active and not suspend():
		return false
	RogueBridge.enter()
	active = true
	var seed_value := seed_text.strip_edges().left(64)
	if seed_value.is_empty():
		seed_value = str(Time.get_unix_time_from_system())
	var stock := 20 + int(doctrine.get("material_adjustment", 0))
	state = {"schema": 1, "agency": agency.strip_edges().left(32) if not agency.strip_edges().is_empty() else "Far Side Agency",
		"run_id": seed_value + ":" + str(Time.get_ticks_usec()),
		"emblem": clampi(emblem, 0, 3), "doctrine": doctrine_id, "seed": seed_value, "mission": 1,
		"phase": "contract", "endless": false, "money": float(doctrine["money"]), "reputation": 50,
		"knowledge": int(doctrine["knowledge"]), "tests": int(doctrine["tests"]),
		"materials": {"structures": stock, "propulsion": stock, "electronics": stock},
		"inventory": {}, "science_stock": {}, "blueprints": {}, "qualified": [], "vehicle": {},
		"mods": {"radio_backup": false, "life_reserve": false}, "offers": {}, "offer_epochs": {},
		"history": [], "research": {}, "portfolio": [], "instruments": [], "site": "a11",
		"contract_offers": RogueCatalog.contract_offers(seed_value, 1), "contract": {},
		"operations": {"training": 1, "control": 1, "launch": 1, "recovery": 1, "computer": 1},
		"mission_day": int(doctrine.get("initial_days", 0)), "agency_days": 0, "actions": 4,
		"events": [], "pending_event": {}, "event_epoch": 0, "science_done": [],
		"work_left": 0, "work_bonus": int(doctrine.get("work_bonus", 0)), "command_done": {},
		"context": {}, "playback": {}, "loan_taken": false, "debt": 0.0, "science_confirmed": false}
	return save()


static func resume() -> bool:
	var loaded := RogueSave.read(save_path)
	if loaded.is_empty():
		return fail(RogueSave.last_error)
	if active and not suspend():
		return false
	RogueBridge.enter()
	active = true
	state = loaded
	RogueBridge.project(state)
	last_error = RogueSave.last_error
	return true


static func suspend() -> bool:
	if not active:
		return true
	var written := save()
	if not written:
		return false
	RogueBridge.leave()
	active = false
	return written


static func save() -> bool:
	if not active:
		return false
	if not RogueSave.write(state, save_path):
		return fail(RogueSave.last_error)
	last_error = ""
	return true


static func fail(message: String) -> bool:
	last_error = message
	return false


static func select_contract(index: int) -> bool:
	if not active or state.get("phase") != "contract" or index < 0 or index >= state["contract_offers"].size():
		return fail("Choose an available contract.")
	state["contract"] = state["contract_offers"][index].duplicate(true)
	var baseline := RogueCatalog.baseline(state["contract"])
	state["site"] = state["contract"]["sites"][0]
	state["portfolio"] = [state["contract"]["objective"]]
	state["work_left"] = int(state["contract"]["work"]) + (int(state["work_bonus"]) if int(state["mission"]) == 1 else 0)
	state["vehicle"] = {}
	for slot: String in baseline:
		var id := str(baseline[slot])
		state["blueprints"][id] = true
		if int(state["mission"]) == 1 and (RogueCatalog.rules()["starter_slots"] as Array).has(slot):
			state["inventory"][id] = int(state["inventory"].get(id, 0)) + 1
		if int(state["inventory"].get(id, 0)) > 0:
			state["vehicle"][slot] = id
	if state["doctrine"] == "conservative" and int(state["mission"]) == 1:
		state["qualified"].append(baseline["stage1"])
	state["funds_at_contract"] = float(state["money"])
	state["phase"] = "planning"
	generate_event()
	RogueBridge.project(state)
	return save()


static func next_mission(endless := false) -> bool:
	if state.get("phase") not in ["debrief", "complete"]:
		return fail("Resolve the current mission before starting another.")
	if state["phase"] == "complete" and not endless:
		return fail("Choose Finish or Endless continuation.")
	state["endless"] = bool(state["endless"]) or endless
	state["mission"] = int(state["mission"]) + 1
	state["phase"] = "contract"
	state["contract_offers"] = RogueCatalog.contract_offers(str(state["seed"]), int(state["mission"]))
	state["contract"] = {}
	state["vehicle"] = {}
	state["instruments"] = []
	state["portfolio"] = []
	state["science_confirmed"] = false
	state["mission_day"] = 0
	state["actions"] = 4
	state["offers"] = {}
	state["offer_epochs"] = {}
	state["context"] = {}
	state["playback"] = {}
	state["science_done"] = []
	state["command_done"] = {}
	state["pending_event"] = {}
	state["grant_objectives"] = []
	return save()


static func resolve_flight() -> bool:
	if state.get("phase") != "flight" or Flight.result.is_empty():
		return fail("No unresolved mission result.")
	var number := int(state["mission"])
	for record: Dictionary in state["history"]:
		if int(record["mission"]) == number:
			return fail("This mission was already evaluated.")
	var result := Flight.result.duplicate(true)
	var landed: bool = result.get("outcome") == "landed"
	var safe: bool = result.get("outcome") != "crew_lost"
	var on_time := int(result.get("launch_day", 99999)) <= int(state["contract"]["deadline"])
	var mandatory: bool = (state["science_done"] as Array).has(str(state["contract"]["objective"]))
	var fulfilled: bool = landed and safe and mandatory and on_time
	var knowledge := 0
	for id: String in state["science_done"]:
		knowledge += int(RogueCatalog.find("objectives", id).get("knowledge", 0))
		state["research"][id] = int(state["research"].get(id, 0)) + 1
	if not landed:
		knowledge = mini(knowledge, 1)
	if state.get("command_done", {}).get("survey", false):
		knowledge += 1 if safe else 0
	var reward := float(state["contract"]["reward"]) * (1.0 if fulfilled else (0.45 if safe else 0.15))
	reward += minf(knowledge * 2.0, 24.0) + (6.0 if safe else 0.0) - (0.0 if on_time else 10.0)
	var rep_delta := 10 if fulfilled else (-8 if safe else -35)
	for obligation: String in state.get("grant_objectives", []):
		if not (state["science_done"] as Array).has(obligation):
			reward -= 6.0
			rep_delta -= 4
	state["money"] = float(result["budget_left"]) + reward - float(state["debt"])
	state["debt"] = 0.0
	state["reputation"] = clampi(int(state["reputation"]) + rep_delta, 0, 100)
	state["knowledge"] = int(state["knowledge"]) + knowledge
	state["agency_days"] = int(state["agency_days"]) + int(Campaign.days)
	var engineering := clampf(float(Vehicle.stats["reliability"]) * 50.0 + 50.0 - Vehicle.shortfalls(Vehicle.stats).size() * 15.0, 0, 100)
	var science := clampf(float(result.get("science_returned", 0)) / maxf(float(result.get("science_planned", 1)), 1) * 50.0 + (50.0 if mandatory else 0), 0, 100)
	var schedule := clampf((int(state["contract"]["deadline"]) - int(result.get("launch_day", 99999))) / 200.0, 0, 1)
	var cash := clampf(float(result["budget_left"]) / maxf(float(state.get("funds_at_contract", 60)) * 0.1, 6), 0, 1)
	var operations := 70.0 if landed and safe else (40.0 if safe else 0.0)
	if state["command_done"].has("window_coast"):
		operations += 10
	if not Flight.build.get("latent", {}).has("comms") and not Flight.build.get("latent", {}).has("life"):
		operations += 10
	var staging_good := true
	for error: Variant in state.get("playback", {}).get("overrides", {}).get("staging", []):
		staging_good = staging_good and absf(float(error)) <= 0.15
	if staging_good and safe:
		operations += 10
	var dimensions := {"management": 50.0 * schedule + 50.0 * cash,
		"engineering": engineering, "operations": clampf(operations, 0, 100),
		"science": science, "safety": 100 if safe else 0, "contract": 100 if fulfilled else (35 if safe else 0)}
	var grade_value := 0.0
	for value: Variant in dimensions.values():
		grade_value += float(value) / dimensions.size()
	var record := {"mission": number, "contract": state["contract"].duplicate(true), "result": result,
		"dimensions": dimensions, "grade": "A" if grade_value >= 90 else ("B" if grade_value >= 75 else ("C" if grade_value >= 50 else "D")),
		"fulfilled": fulfilled, "knowledge": knowledge, "reward": reward, "science_done": state["science_done"].duplicate(),
		"vehicle": Vehicle.design.duplicate(), "commands": state["command_done"].duplicate()}
	state["history"].append(record)
	state["phase"] = "complete" if number >= 3 else "debrief"
	if int(state["reputation"]) <= 0 or float(state["money"]) < 0:
		state["phase"] = "failed"
	state["context"] = RogueBridge.capture()
	return save()


static func purchase(slot: String, id: String, emergency := false) -> bool:
	if state.get("phase") != "planning":
		return fail("Procurement is available during planning.")
	var part := RogueCatalog.part(slot, id)
	if part.is_empty():
		return fail("Unknown component.")
	if emergency:
		if not state["blueprints"].has(id):
			return fail("This blueprint has not been acquired.")
	elif not RogueDraft.offers(state, slot).has(id):
		return fail("This component is not in the current draft.")
	var price := float(part.get("cost_pct", 0)) * (1.25 if emergency else 1.0)
	var recipe := RogueCatalog.material_recipe(slot, id)
	if float(state["money"]) < price:
		return fail("Not enough funding; preserve an integration and operations reserve.")
	for material: String in recipe:
		if int(state["materials"].get(material, 0)) < int(recipe[material]):
			return fail("Manufacturing needs more " + material + ". Agency procurement can order stock.")
	state["money"] = float(state["money"]) - price
	for material: String in recipe:
		state["materials"][material] = int(state["materials"][material]) - int(recipe[material])
	state["inventory"][id] = int(state["inventory"].get(id, 0)) + 1
	state["blueprints"][id] = true
	state["mission_day"] = int(state["mission_day"]) + (14 if emergency else 7)
	state["offer_epochs"][slot] = int(state["offer_epochs"].get(slot, 0)) + 1
	state["offers"].erase(slot)
	RogueBridge.project(state)
	return save()


static func install(slot: String, id: String) -> bool:
	if state.get("phase") != "planning" or RogueCatalog.part(slot, id).is_empty():
		return fail("Cannot install that component here.")
	if int(state["inventory"].get(id, 0)) < 1:
		return fail("Procure a physical unit before installing it.")
	if state["vehicle"].get(slot) == id:
		state["vehicle"].erase(slot)
	else:
		state["vehicle"][slot] = id
	RogueBridge.project(state)
	return save()


static func skip_draft(slot: String) -> bool:
	if state.get("phase") != "planning" or available_actions() <= 0:
		return fail("Skipping a draft consumes one remaining agency action.")
	state["actions"] = int(state["actions"]) - 1
	state["materials"]["structures"] = int(state["materials"]["structures"]) + 1
	state["mission_day"] = int(state["mission_day"]) + 15
	state["offer_epochs"][slot] = int(state["offer_epochs"].get(slot, 0)) + 1
	state["offers"].erase(slot)
	return save()


static func buy_material(material: String, quantity := 8) -> bool:
	var price := quantity * 0.75
	if state.get("phase") != "planning" or quantity not in [8, 16] or not state["materials"].has(material) or available_actions() <= 0 or float(state["money"]) < price:
		return fail("An order needs one free agency action and 6 cr per 8 stock units.")
	state["money"] = float(state["money"]) - price
	state["actions"] = int(state["actions"]) - 1
	state["materials"][material] = int(state["materials"][material]) + quantity
	state["mission_day"] = int(state["mission_day"]) + 15
	return save()


static func sell(slot: String, id: String) -> bool:
	if state.get("phase") != "planning" or int(state["inventory"].get(id, 0)) <= 0:
		return fail("There is no unused physical unit to sell.")
	if state["vehicle"].get(slot) == id:
		return fail("Remove the installed unit before selling it.")
	state["inventory"][id] = int(state["inventory"][id]) - 1
	state["money"] = float(state["money"]) + float(RogueCatalog.part(slot, id).get("cost_pct", 0)) * 0.55
	return save()


static func set_operation(id: String, level: int) -> bool:
	if state.get("phase") != "planning" or not state["operations"].has(id) or level < 0 or level > 2:
		return fail("Operations levels must be set during planning.")
	state["operations"][id] = level
	RogueBridge.project(state)
	return save()


static func readiness() -> Array[String]:
	var messages: Array[String] = []
	if state.get("phase") != "planning":
		messages.append("Accept a contract and enter planning.")
		return messages
	if not state.get("science_confirmed", false):
		messages.append("Confirm a site, research portfolio and science payload.")
	var choice: Dictionary = state["vehicle"]
	if Vehicle.missing(choice) > 0:
		messages.append("Fill all 14 engineering sections.")
	for slot: String in choice:
		if int(state["inventory"].get(choice[slot], 0)) <= 0:
			messages.append("Missing physical unit: " + str(choice[slot]))
	var result := RogueBridge.evaluate(state)
	var warnings := {"liftoff": "Lift-off thrust is insufficient", "rocket": "Launcher delta-v is below the requirement", "ship": "Spacecraft delta-v is below the requirement", "cargo": "Payload exceeds lander capacity", "power": "Electrical power is insufficient", "suits": "Surface EVA capability is missing", "range": "Range safety cannot approve an overland launch"}
	for shortfall: String in Vehicle.shortfalls(result):
		if shortfall != "late":
			messages.append("Engineering: " + str(warnings.get(shortfall, shortfall)))
	if not RogueDraft.compatible(choice):
		messages.append("Side boosters require the compatible core second stage.")
	var integration := float(result["cost"]) - RogueBridge.owned_value(choice)
	if float(state["money"]) < integration + Operations.cost(state["operations"]) + 6.0:
		messages.append("Keep enough funding for integration, operations and a 6 cr contingency reserve.")
	var reserve_stock := int(bool(state["mods"]["radio_backup"])) + int(bool(state["mods"]["life_reserve"]))
	if int(state["materials"]["electronics"]) < reserve_stock:
		messages.append("Order electronics stock for the configured reserve hardware.")
	if not state.get("pending_event", {}).is_empty():
		messages.append("Resolve the outstanding agency event.")
	return messages


static func generate_event() -> void:
	var pool := []
	for event: Dictionary in RogueCatalog.rules()["events"]:
		if event["id"] == "supplier" and int(state["materials"]["electronics"]) >= 20:
			continue
		if event["id"] == "quality" and int(state["tests"]) <= 0:
			continue
		if event["id"] == "quality" and (state["qualified"] as Array).has(RogueCatalog.baseline(state["contract"])["stage1"]):
			continue
		pool.append(event)
	var random := RogueCatalog.rng(str(state["seed"]), "event/%d/%d" % [state["mission"], state["event_epoch"]])
	state["pending_event"] = pool[random.randi_range(0, pool.size() - 1)].duplicate(true)
	state["event_epoch"] = int(state["event_epoch"]) + 1


static func event_reason(choice: Dictionary) -> String:
	if int(state["actions"]) <= 0:
		return "No agency actions remain."
	if float(state["money"]) + float(choice.get("money", 0)) < 0:
		return "Insufficient funding."
	if int(state["tests"]) + int(choice.get("tests", 0)) < 0:
		return "Insufficient test capacity."
	if choice.has("qualify") and (state["qualified"] as Array).has(RogueCatalog.baseline(state["contract"])[choice["qualify"]]):
		return "This design is already qualified; retain the normal programme."
	if choice.has("research"):
		var required := RogueCatalog.find("objectives", str(state["contract"]["objective"]))
		var extra := RogueCatalog.find("objectives", str(choice["research"]))
		if int(state["work_left"]) < int(required["work"]) + int(extra["work"]):
			return "Negotiate more science work before accepting this additional commitment."
	return ""


static func choose_event(index: int) -> bool:
	var event: Dictionary = state.get("pending_event", {})
	if state.get("phase") != "planning" or event.is_empty() or index < 0 or index >= event["choices"].size():
		return fail("No such pending event choice.")
	var choice: Dictionary = event["choices"][index]
	var reason := event_reason(choice)
	if not reason.is_empty():
		return fail(reason)
	state["money"] = float(state["money"]) + float(choice.get("money", 0))
	state["mission_day"] = int(state["mission_day"]) + int(choice.get("days", 0))
	state["tests"] = int(state["tests"]) + int(choice.get("tests", 0))
	state["actions"] = int(state["actions"]) - 1
	for material: String in choice.get("materials", {}):
		state["materials"][material] = int(state["materials"][material]) + int(choice["materials"][material])
	if choice.has("qualify"):
		var id := str(RogueCatalog.baseline(state["contract"])[choice["qualify"]])
		if not (state["qualified"] as Array).has(id):
			state["qualified"].append(id)
	if choice.has("research"):
		var obligations: Array = state.get("grant_objectives", [])
		obligations.append(str(choice["research"]))
		state["grant_objectives"] = obligations
	state["events"].append({"mission": state["mission"], "event": event["id"], "choice": choice.duplicate(true)})
	state["pending_event"] = {}
	RogueBridge.project(state)
	return save()


static func qualify(slot: String) -> bool:
	var id := str(state["vehicle"].get(slot, RogueCatalog.baseline(state["contract"]).get(slot, "")))
	if state.get("phase") != "planning" or id.is_empty() or (state["qualified"] as Array).has(id):
		return fail("This design is already qualified, or no design is selected.")
	if available_actions() <= 0 or int(state["tests"]) <= 0 or float(state["money"]) < 2.5:
		return fail("Qualification needs one action, one test slot, 2.5 cr and 30 days.")
	state["money"] = float(state["money"]) - 2.5
	state["tests"] = int(state["tests"]) - 1
	state["actions"] = int(state["actions"]) - 1
	state["mission_day"] = int(state["mission_day"]) + 30
	state["qualified"].append(id)
	RogueBridge.project(state)
	return save()


static func research_action() -> bool:
	if state.get("phase") != "planning" or available_actions() <= 0 or float(state["money"]) < 3:
		return fail("A research review needs one action, 3 cr and 20 days.")
	state["actions"] = int(state["actions"]) - 1
	state["money"] = float(state["money"]) - 3
	state["knowledge"] = int(state["knowledge"]) + 3
	state["mission_day"] = int(state["mission_day"]) + 20
	return save()


static func extend_science() -> bool:
	if state.get("phase") != "planning" or available_actions() <= 0 or float(state["money"]) < 4 or int(state["work_left"]) >= 5:
		return fail("An extra science work period needs one action, 4 cr and 20 days; maximum five.")
	state["actions"] = int(state["actions"]) - 1
	state["money"] = float(state["money"]) - 4
	state["mission_day"] = int(state["mission_day"]) + 20
	state["work_left"] = int(state["work_left"]) + 1
	return save()


static func toggle_mod(id: String) -> bool:
	if state.get("phase") != "planning" or not state["mods"].has(id):
		return fail("Unknown planning modification.")
	state["mods"][id] = not bool(state["mods"][id])
	RogueBridge.project(state)
	return save()


static func bridge_grant() -> bool:
	if state.get("phase") != "planning" or state["loan_taken"] or float(state["money"]) >= 20 or int(state["reputation"]) < 15:
		return fail("Bridge support needs reputation 15+, funds below 20 cr, and is available once per run.")
	state["loan_taken"] = true
	state["money"] = float(state["money"]) + 15
	state["debt"] = 20.0
	state["reputation"] = int(state["reputation"]) - 5
	return save()


static func toggle_objective(id: String) -> bool:
	if state.get("phase") != "planning" or not RogueResearch.offers(state).has(id):
		return fail("This research objective is not in the current portfolio draft.")
	if id == state["contract"]["objective"]:
		return fail("The contract's mandatory research objective stays in the portfolio.")
	if (state["portfolio"] as Array).has(id):
		state["portfolio"].erase(id)
	elif state["portfolio"].size() < 2:
		state["portfolio"].append(id)
	else:
		return fail("Choose at most two focused research objectives.")
	state["science_confirmed"] = false
	return save()


static func confirm_science(site_id: String, ids: Array) -> bool:
	if state.get("phase") != "planning" or not (state["contract"]["sites"] as Array).has(site_id):
		return fail("Choose a landing site supported by this contract.")
	var selected := RogueCatalog.instruments(ids)
	if selected.size() != ids.size():
		return fail("Unknown or duplicated science instrument.")
	for id: String in RogueResearch.required_ids(state):
		if not ids.has(id):
			return fail("The portfolio requires: " + str(RogueResearch.required_ids(state)))
	var cost := 0.0
	var electronics := 0
	for instrument: Dictionary in selected:
		if int(state["science_stock"].get(instrument["id"], 0)) == 0:
			cost += float(instrument["cost_pct"])
			electronics += 1
	if float(state["money"]) < cost or int(state["materials"]["electronics"]) < electronics:
		return fail("Insufficient funding or electronics for this science payload.")
	state["money"] = float(state["money"]) - cost
	state["materials"]["electronics"] = int(state["materials"]["electronics"]) - electronics
	for instrument: Dictionary in selected:
		state["science_stock"][instrument["id"]] = maxi(1, int(state["science_stock"].get(instrument["id"], 0)))
	state["site"] = site_id
	state["instruments"] = ids.duplicate()
	if not state["science_confirmed"]:
		state["mission_day"] = int(state["mission_day"]) + 5
	state["science_confirmed"] = true
	RogueBridge.project(state)
	return save()


static func launch() -> bool:
	var problems := readiness()
	if not problems.is_empty():
		return fail("\n".join(PackedStringArray(problems)))
	var extras := int(bool(state["mods"]["radio_backup"])) + int(bool(state["mods"]["life_reserve"]))
	if int(state["materials"]["electronics"]) < extras:
		return fail("Reserve hardware needs one electronics stock per modification.")
	RogueBridge.project(state)
	var integration := float(Vehicle.stats["cost"]) - RogueBridge.owned_value(Vehicle.design)
	Campaign.budget_left = float(state["money"]) - integration
	Campaign.board_confidence = float(state["reputation"])
	Flight.reset()
	# Original confirmation performs preparation, costs, delays and latent flaws.
	Operations.confirm(state["operations"])
	Campaign.pass_review()
	Flight.fly()
	for slot: String in state["vehicle"]:
		if slot not in ["ground", "spaceport"]:
			var id := str(state["vehicle"][slot])
			state["inventory"][id] = int(state["inventory"][id]) - 1
	for id: String in state["instruments"]:
		state["science_stock"][id] = int(state["science_stock"][id]) - 1
	state["materials"]["electronics"] = int(state["materials"]["electronics"]) - extras
	state["money"] = Campaign.budget_left
	state["phase"] = "flight"
	state["flight_phase"] = "countdown"
	state["context"] = RogueBridge.capture()
	state["playback"] = {"phase": 0, "overrides": {}}
	return save()


static func command_reason(id: String) -> String:
	if state.get("phase") != "flight" or state.get("flight_phase") != "coast" or state["command_done"].has(id):
		return "Available once during the outbound coast."
	var reached_coast := false
	for phase: Dictionary in Flight.result.get("phases", []):
		reached_coast = reached_coast or phase.get("id") == "coast"
	if not reached_coast:
		return "The original flight did not reach the outbound coast."
	match id:
		"radio_backup":
			if not state["mods"]["radio_backup"] or not Flight.build.get("latent", {}).has("comms"):
				return "Requires an installed standby radio and an actual primary-radio fault."
			if float(Vehicle.stats["power_have"]) < float(Vehicle.stats["power_need"]):
				return "Insufficient electrical power for the backup."
		"life_reserve":
			if not state["mods"]["life_reserve"] or not Flight.build.get("latent", {}).has("life"):
				return "Requires the carried reserve cartridge and an actual life-support fault."
		"survey":
			if int(state["work_left"]) < 1 or not (state["instruments"] as Array).has("tv") or Vehicle.stats.get("link") == "basic" or float(Vehicle.stats["power_have"]) < float(Vehicle.stats["power_need"]) + 0.15:
				return "Needs a carried camera, suitable data link, 150 W electrical margin and one science work period."
		_:
			return "Unknown spacecraft command."
	return ""


static func command(id: String) -> bool:
	var reason := command_reason(id)
	if not reason.is_empty():
		return fail(reason)
	state["command_done"][id] = true
	if id == "survey":
		state["work_left"] = int(state["work_left"]) - 1
	else:
		var fault := "comms" if id == "radio_backup" else "life"
		Flight.build["latent"].erase(fault)
		# Original replay restores its before-flight boundary; no duplicate costs or
		# fresh preparation draws. Only the supported failed subsystem is replaced.
		Flight.fly(state["playback"].get("overrides", {}))
	state["context"] = RogueBridge.capture()
	return save()


static func experiment(id: String) -> bool:
	var reason := RogueResearch.experiment_reason(state, id)
	if not reason.is_empty():
		return fail(reason)
	state["work_left"] = int(state["work_left"]) - int(RogueCatalog.find("objectives", id)["work"])
	state["science_done"].append(id)
	state["context"] = RogueBridge.capture()
	return save()


static func available_actions() -> int:
	# Reserve the last action for the already-disclosed event to avoid a softlock.
	return maxi(0, int(state.get("actions", 0)) - (1 if not state.get("pending_event", {}).is_empty() else 0))


static func can_close_unfunded() -> bool:
	if state.get("phase") != "planning" or float(state["money"]) > 0 or not state["loan_taken"]:
		return false
	for slot: Dictionary in RogueCatalog.base_vehicle()["slots"]:
		for part: Dictionary in slot["parts"]:
			if int(state["inventory"].get(part["id"], 0)) > 0 and float(part.get("cost_pct", 0)) > 0:
				return false
	return true


static func close_unfunded() -> bool:
	if not can_close_unfunded():
		return fail("Recovery funding or unspent hardware is still available.")
	state["phase"] = "failed"
	state["terminal_reason"] = "No funding, no unused hardware to sell, and bridge support exhausted."
	return save()


static func summary() -> Dictionary:
	var dimensions := {"management": 0.0, "engineering": 0.0, "operations": 0.0, "science": 0.0, "safety": 0.0, "contract": 0.0}
	var completed := 0
	var raw_science := 0
	for record: Dictionary in state["history"]:
		completed += int(bool(record["fulfilled"]))
		raw_science += int(record["result"].get("science_returned", 0))
		for key: String in dimensions:
			dimensions[key] += float(record["dimensions"][key]) / maxf(state["history"].size(), 1)
	var aggregate := 0.0
	for value: Variant in dimensions.values():
		aggregate += float(value) / dimensions.size()
	return {"missions": state["history"].size(), "contracts_fulfilled": completed, "cumulative_science": raw_science,
		"dimensions": dimensions, "grade": "A" if aggregate >= 90 else ("B" if aggregate >= 75 else ("C" if aggregate >= 50 else "D")), "seed": state["seed"]}


static func book_tests() -> bool:
	if state.get("phase") != "planning" or available_actions() <= 0 or float(state["money"]) < 3:
		return fail("A laboratory batch needs one free action, 3 cr and 20 days.")
	state["tests"] = int(state["tests"]) + 2
	state["money"] = float(state["money"]) - 3
	state["actions"] = int(state["actions"]) - 1
	state["mission_day"] = int(state["mission_day"]) + 20
	return save()
