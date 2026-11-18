class_name RogueSave
extends RefCounted
## Independent, versioned save with an atomic replacement and last-good backup.

const PATH := "user://rogue_rocket_v1.json"
static var last_error := ""


static func valid(value: Variant) -> bool:
	if not value is Dictionary or value.get("schema") != 1:
		return false
	for key: String in ["vehicle", "inventory", "science_stock", "blueprints", "materials", "offers", "offer_epochs", "operations", "mods", "command_done", "context", "playback", "research", "contract", "pending_event"]:
		if not value.get(key) is Dictionary:
			return false
	for key: String in ["contract_offers", "history", "qualified", "portfolio", "instruments", "science_done", "events"]:
		if not value.get(key) is Array:
			return false
	for key: String in ["seed", "agency", "doctrine", "phase"]:
		if not value.get(key) is String or str(value[key]).is_empty():
			return false
	if RogueCatalog.find("doctrines", value["doctrine"]).is_empty() or value["phase"] not in ["contract", "planning", "flight", "debrief", "complete", "failed", "finished"]:
		return false
	if not amount(value.get("money"), -1.0e9, 1.0e9) or not amount(value.get("mission"), 1, 100000):
		return false
	for key: String in ["knowledge", "tests", "mission_day", "agency_days", "debt", "event_epoch", "work_bonus"]:
		if not amount(value.get(key), 0, 1.0e9):
			return false
	if not amount(value.get("emblem"), 0, 3) or not amount(value.get("reputation"), 0, 100) or not amount(value.get("actions"), 0, 4) or not amount(value.get("work_left"), 0, 5):
		return false
	for key: String in ["endless", "loan_taken", "science_confirmed"]:
		if not value.get(key) is bool:
			return false
	for key: String in ["radio_backup", "life_reserve"]:
		if not value["mods"].get(key) is bool:
			return false
	for key: String in ["structures", "propulsion", "electronics"]:
		if not amount(value["materials"].get(key), 0, 10000):
			return false
	for key: String in ["training", "control", "launch", "recovery", "computer"]:
		if not amount(value["operations"].get(key), 0, 2):
			return false
	for collection: String in ["inventory", "science_stock", "offer_epochs"]:
		for quantity: Variant in value[collection].values():
			if not amount(quantity, 0, 10000) or float(quantity) != floorf(float(quantity)):
				return false
	for slot: String in value["vehicle"]:
		if RogueCatalog.part(slot, str(value["vehicle"][slot])).is_empty():
			return false
	for contract: Variant in value["contract_offers"]:
		if not valid_contract(contract):
			return false
	if value["phase"] != "contract" and not valid_contract(value["contract"]):
		return false
	if value["phase"] == "flight":
		for model: String in RogueBridge.FIELDS:
			if not value["context"].get(model) is Dictionary:
				return false
		var result: Variant = value["context"]["flight"].get("result")
		if not result is Dictionary or not result.get("phases") is Array or not result.get("outcome") is String:
			return false
		for phase: Variant in result["phases"]:
			if not phase is Dictionary or not phase.get("lines") is Array or not phase.get("id") is String:
				return false
	for record: Variant in value["history"]:
		if not record is Dictionary or not record.get("result") is Dictionary or not record.get("dimensions") is Dictionary or not record.has_all(["mission", "contract", "grade", "fulfilled", "knowledge", "reward", "science_done", "vehicle", "commands"]):
			return false
	return true


static func amount(value: Variant, low: float, high: float) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and float(value) >= low and float(value) <= high


static func valid_contract(value: Variant) -> bool:
	if not value is Dictionary or not value.has_all(["id", "title", "architecture", "objective", "deadline", "reward", "sites", "work", "mission"]):
		return false
	return not RogueCatalog.find("contracts", str(value["id"])).is_empty() and RogueCatalog.rules()["baselines"].has(value["architecture"]) and not RogueCatalog.find("objectives", str(value["objective"])).is_empty() and value["sites"] is Array and amount(value["deadline"], 1, 10000) and amount(value["reward"], 0, 10000)


static func write(state: Dictionary, path := PATH) -> bool:
	last_error = ""
	if not valid(state):
		last_error = "Save validation failed; existing save was preserved."
		return false
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if not file:
		last_error = "Cannot write run save."
		return false
	file.store_string(JSON.stringify(state))
	file.flush()
	file.close()
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.remove_absolute(path + ".bak")
		if DirAccess.rename_absolute(path, path + ".bak") != OK:
			last_error = "Cannot rotate the last-good run save."
			return false
	if DirAccess.rename_absolute(path + ".tmp", path) != OK:
		DirAccess.rename_absolute(path + ".bak", path)
		last_error = "Cannot replace run save; previous save restored."
		return false
	return true


static func read(path := PATH) -> Dictionary:
	last_error = ""
	for candidate: String in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(candidate)) == OK and valid(parser.data):
			if candidate != path:
				last_error = "Recovered the last-good backup; the primary save was invalid."
			return parser.data
	last_error = "No compatible run save. Missing, corrupt or newer saves are kept intact."
	return {}
