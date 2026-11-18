class_name RogueBridge
extends RefCounted
## A scoped projection into the ORIGINAL scientific models, never a second solver.

const FIELDS := {
	"campaign": ["stage", "days", "clock_running", "budget_left", "calc_funding", "calc_round", "research_days", "runs_hit", "runs_total", "accuracy", "margin", "site", "instruments", "payload_mass", "payload_power", "payload_cost", "science_value", "board_confidence", "_check_sum"],
	"vehicle": ["design", "stats", "reliability", "draft"],
	"operations": ["choices", "draft"],
	"flight": ["build", "result", "_before"]
}
static var _story := {}
static var _story_catalog := {}


static func models() -> Dictionary:
	return {"campaign": Campaign, "vehicle": Vehicle, "operations": Operations, "flight": Flight}


static func capture(deep := true) -> Dictionary:
	var out := {}
	var scripts := models()
	for model: String in FIELDS:
		out[model] = {}
		var script: Script = scripts[model]
		for field: String in FIELDS[model]:
			var value: Variant = script.get(field)
			out[model][field] = value.duplicate(true) if deep and (value is Array or value is Dictionary) else value
	return out


static func restore(snapshot: Dictionary, deep := true) -> void:
	var scripts := models()
	for model: String in FIELDS:
		var script: Script = scripts[model]
		for field: String in FIELDS[model]:
			if not snapshot.get(model, {}).has(field):
				continue
			var value: Variant = snapshot[model][field]
			match typeof(script.get(field)):
				TYPE_INT: value = int(value)
				TYPE_FLOAT: value = float(value)
				TYPE_BOOL: value = bool(value)
			if deep and (value is Dictionary or value is Array):
				value = value.duplicate(true)
			script.set(field, value)


static func enter() -> void:
	Vehicle.slots()
	_story = capture()
	_story_catalog = Vehicle._data


static func leave() -> void:
	if not _story.is_empty():
		restore(_story)
		Vehicle._data = _story_catalog
	_story = {}
	_story_catalog = {}


static func modified_catalog(state: Dictionary) -> Dictionary:
	var data := RogueCatalog.base_vehicle().duplicate(true)
	for slot: Dictionary in data["slots"]:
		var slot_id := str(slot["id"])
		for part: Dictionary in slot["parts"]:
			if (state.get("qualified", []) as Array).has(str(part["id"])):
				part["risk"] = float(part.get("risk", 0)) * 0.65
				part["specs"].append(["Run qualification", "Design risk ×0.65; does not eliminate manufacturing flaws"])
			if slot_id == "comms" and state.get("mods", {}).get("radio_backup", false):
				part["mass"] = float(part.get("mass", 0)) * 2
				part["power_kw"] = float(part.get("power_kw", 0)) + 0.03
				part["cost_pct"] = float(part.get("cost_pct", 0)) + 1.5
				part["specs"].append(["Standby transceiver", "Duplicate radio mass; +30 W; +1.5 cr; one backup switch"])
			if slot_id == "life" and state.get("mods", {}).get("life_reserve", false):
				part["fixed"] = float(part.get("fixed", 0)) + 0.3
				part["cost_pct"] = float(part.get("cost_pct", 0)) + 1.0
				part["specs"].append(["Reserve cartridge", "+300 kg; +1 cr; one life-support recovery"])
			for spec: Array in part.get("specs", []):
				if spec[0] == "Cost":
					spec[1] = "%.1f cr hardware valuation" % float(part.get("cost_pct", 0))
				elif slot_id == "comms" and spec[0] == "Mass":
					spec[1] = "%.3f t including configured radio hardware" % float(part.get("mass", 0))
				elif slot_id == "comms" and spec[0] == "Power use":
					spec[1] = "%.3f kW including standby demand" % float(part.get("power_kw", 0))
				elif slot_id == "life" and spec[0] == "Equipment":
					spec[1] = "%.3f t including configured reserve equipment" % float(part.get("fixed", 0))
	return data


static func owned_value(choice: Dictionary) -> float:
	var total := 0.0
	for slot: String in choice:
		total += float(RogueCatalog.part(slot, str(choice[slot])).get("cost_pct", 0))
	return total


static func project(state: Dictionary) -> void:
	Vehicle._data = modified_catalog(state)
	if state.get("phase") in ["flight", "debrief", "complete", "failed", "finished"] and not state.get("context", {}).is_empty():
		restore(state["context"])
		return
	Campaign.stage = 6
	Campaign.clock_running = false
	Campaign.days = float(state.get("mission_day", 0))
	var analysis: Dictionary = RogueCatalog.rules()["reference_analysis"]
	Campaign.calc_funding = float(analysis["funding"])
	Campaign.accuracy = float(analysis["accuracy"])
	Campaign.margin = float(analysis["reserve_pct"])
	Campaign.calc_round = 1
	Campaign._check_sum = 0.96
	Campaign.site = RogueCatalog.site(str(state.get("site", "a11")))
	Campaign.instruments = RogueCatalog.instruments(state.get("instruments", []))
	var totals := Campaign.plan_totals(Campaign.site, Campaign.instruments)
	Campaign.payload_mass = totals["mass"]
	Campaign.payload_power = totals["power"]
	Campaign.payload_cost = totals["cost"]
	Campaign.science_value = totals["science"]
	Vehicle.draft = state.get("vehicle", {})
	Vehicle.design = Vehicle.draft.duplicate()
	# Parts were procured already. Only integration and unbuilt modifications are
	# unpaid. Add back the base valuation so the original cost calculation nets it.
	Campaign.budget_left = float(state.get("money", 0)) + owned_value(Vehicle.draft)
	Vehicle.stats = Vehicle.evaluate(Vehicle.draft)
	Vehicle.reliability = float(Vehicle.stats["reliability"])
	Operations.choices = state.get("operations", {}).duplicate()
	Flight.reset()


static func evaluate(state: Dictionary, choice := {}) -> Dictionary:
	var snapshot := capture(false)
	var catalog := Vehicle._data
	var projected := state.duplicate(true)
	if not choice.is_empty():
		projected["vehicle"] = choice
	projected["phase"] = "planning"
	project(projected)
	var result := Vehicle.stats.duplicate(true)
	restore(snapshot, false)
	Vehicle._data = catalog
	return result
