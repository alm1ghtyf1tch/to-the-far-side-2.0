class_name RogueDraft
extends RefCounted
## Explicit seeded offers, compatible reference plans and physical stock recipes.


static func offers(state: Dictionary, slot_id: String) -> Array:
	if state["offers"].has(slot_id):
		return state["offers"][slot_id]
	var baseline := RogueCatalog.baseline(state["contract"])
	var reference := state.duplicate(true)
	reference["vehicle"] = baseline
	reference["instruments"] = RogueCatalog.find("objectives", str(state["contract"]["objective"]))["instruments"].duplicate()
	var pool := []
	for group: Dictionary in RogueCatalog.base_vehicle()["slots"]:
		if group["id"] != slot_id:
			continue
		for part: Dictionary in group["parts"]:
			var id := str(part["id"])
			if (RogueCatalog.rules()["experimental"] as Array).has(id) and int(state["knowledge"]) < 6 and id != baseline[slot_id] and state["doctrine"] != "innovation":
				continue
			var candidate := baseline.duplicate()
			candidate[slot_id] = id
			if compatible(candidate):
				var result := RogueBridge.evaluate(reference, candidate)
				var problems := Vehicle.shortfalls(result)
				problems.erase("late")
				if problems.is_empty():
					pool.append(id)
	var epoch := int(state["offer_epochs"].get(slot_id, 0))
	pool = RogueCatalog.shuffled(pool, RogueCatalog.rng(str(state["seed"]), "draft/%d/%s/%d" % [state["mission"], slot_id, epoch]))
	pool.erase(baseline[slot_id])
	var out: Array = [baseline[slot_id]]
	for id: String in pool.slice(0, 2):
		out.append(id)
	state["offers"][slot_id] = out
	return out


static func compatible(choice: Dictionary) -> bool:
	return choice.get("stage1") != "s1_solid" or choice.get("stage2") == "s2_core"


static func cost_to_complete(state: Dictionary) -> Dictionary:
	var baseline := RogueCatalog.baseline(state["contract"])
	var missing_materials := {"structures": 0, "propulsion": 0, "electronics": 0}
	var cost := 0.0
	for slot: String in baseline:
		if int(state["inventory"].get(baseline[slot], 0)) > 0:
			continue
		cost += float(RogueCatalog.part(slot, baseline[slot]).get("cost_pct", 0)) * 1.25
		for material: String in RogueCatalog.material_recipe(slot):
			missing_materials[material] += int(RogueCatalog.material_recipe(slot)[material])
	for material: String in missing_materials:
		var shortage := maxi(0, int(missing_materials[material]) - int(state["materials"].get(material, 0)))
		cost += ceilf(shortage / 8.0) * 6.0
	var result := RogueBridge.evaluate(state, baseline)
	cost += float(result["workforce_cost"]) + Operations.cost(state["operations"]) + 6.0
	return {"cost": cost, "stats": result, "materials": missing_materials, "baseline": baseline}
