class_name RogueResearch
extends RefCounted
## Focused science work rewards; no mass, speed or unexplained physics bonuses.


static func offers(state: Dictionary) -> Array:
	var mandatory := str(state["contract"]["objective"])
	var pool := []
	for item: Dictionary in RogueCatalog.rules()["objectives"]:
		if item["id"] != mandatory:
			pool.append(item["id"])
	var out: Array = [mandatory]
	for id: String in RogueCatalog.shuffled(pool, RogueCatalog.rng(str(state["seed"]), "research/%d" % state["mission"])).slice(0, 2):
		out.append(id)
	for id: String in state.get("grant_objectives", []):
		if not out.has(id):
			out.append(id)
	return out


static func required_ids(state: Dictionary) -> Array:
	var ids := []
	for objective: String in state["portfolio"]:
		for id: String in RogueCatalog.find("objectives", objective).get("instruments", []):
			if not ids.has(id):
				ids.append(id)
	return ids


static func experiment_reason(state: Dictionary, id: String) -> String:
	if state.get("phase") != "flight" or state.get("flight_phase") != "surface":
		return "Focused surface work is available during lunar surface operations."
	if not (state["portfolio"] as Array).has(id) or (state["science_done"] as Array).has(id):
		return "Not in this portfolio, or already completed."
	var objective := RogueCatalog.find("objectives", id)
	if int(state["work_left"]) < int(objective.get("work", 999)):
		return "Insufficient scientific work periods."
	if Flight.result.get("outcome") != "landed" or int(Vehicle.stats.get("surface_crew", 0)) <= 0 or float(Vehicle.stats.get("eva_hours", 0)) <= 0:
		return "Crew, landing or EVA capability unavailable."
	for instrument: Dictionary in RogueCatalog.instruments(objective["instruments"]):
		var working := false
		for row: Dictionary in Flight.result.get("science_rows", []):
			if row.get("name") == instrument["name"] and float(row.get("points", 0)) > 0:
				working = true
		if not working:
			return "No usable returned data from " + str(instrument["name"]) + ". Check carried gear, power and communications."
	return ""
