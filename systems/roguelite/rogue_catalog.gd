class_name RogueCatalog
extends RefCounted
## Curated run content; engineering numbers continue to come from Vehicle.

static var _rules := {}
static var _vehicle := {}


static func rules() -> Dictionary:
	if _rules.is_empty():
		_rules = JSON.parse_string(FileAccess.get_file_as_string("res://data/roguelite/rules.json"))
	return _rules


static func base_vehicle() -> Dictionary:
	if _vehicle.is_empty():
		_vehicle = JSON.parse_string(FileAccess.get_file_as_string(Vehicle.PATH))
	return _vehicle


static func find(collection: String, id: String) -> Dictionary:
	for item: Dictionary in rules().get(collection, []):
		if str(item["id"]) == id:
			return item
	return {}


static func site(id: String) -> Dictionary:
	for item: Dictionary in Campaign.sites():
		if item["id"] == id:
			return item
	return {}


static func instruments(ids: Array) -> Array:
	var out := []
	for item: Dictionary in Campaign.instrument_options():
		if ids.has(str(item["id"])):
			out.append(item)
	return out


static func part(slot: String, id: String) -> Dictionary:
	for group: Dictionary in base_vehicle()["slots"]:
		if group["id"] == slot:
			for item: Dictionary in group["parts"]:
				if item["id"] == id:
					return item
	return {}


static func rng(seed_text: String, tag: String) -> RandomNumberGenerator:
	var random := RandomNumberGenerator.new()
	random.seed = (seed_text + "/" + tag).hash()
	return random


static func shuffled(items: Array, random: RandomNumberGenerator) -> Array:
	var out := items.duplicate(true)
	for index in range(out.size() - 1, 0, -1):
		var other := random.randi_range(0, index)
		var swap: Variant = out[index]
		out[index] = out[other]
		out[other] = swap
	return out


static func contract_offers(seed_text: String, mission: int) -> Array:
	var pool := shuffled(rules()["contracts"], rng(seed_text, "contracts/%d" % mission))
	var out := []
	for index in 3:
		var contract: Dictionary = pool[index]
		contract["deadline"] = maxi(2280, 2360 - mini(mission - 1, 8) * 10)
		contract["reward"] = 72.0 - minf(mission - 1, 6) * 3.0
		contract["work"] = 3
		contract["mission"] = mission
		out.append(contract)
	return out


static func baseline(contract: Dictionary) -> Dictionary:
	return (rules()["baselines"][str(contract["architecture"])] as Dictionary).duplicate()


static func material_recipe(slot: String, part_id := "") -> Dictionary:
	if part_id in ["escape_none", "tests_none"]:
		return {}
	return (rules()["recipes"].get(slot, {}) as Dictionary).duplicate()
