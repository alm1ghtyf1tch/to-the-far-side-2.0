class_name Operations
extends RefCounted

const PATH := "res://data/operations.json"

static var choices := {}
static var draft := {}

static var _data := {}


static func reset() -> void:
	choices = {}
	draft = {}


static func items() -> Array:
	_load()
	var value: Variant = _data.get("items")
	return value if value is Array else []


static func rules() -> Dictionary:
	_load()
	var value: Variant = _data.get("rules")
	return value if value is Dictionary else {}


static func level(item_id: String) -> int:
	return int(choices.get(item_id, int(rules().get("default_level", 1))))


static func level_name(item_id: String) -> String:
	for item: Dictionary in items():
		if item.get("id") == item_id:
			return str((item["levels"] as Array)[level(item_id)]["name"])
	return ""


static func item_title(item_id: String) -> String:
	for item: Dictionary in items():
		if item.get("id") == item_id:
			return str(item.get("title", ""))
	return ""


static func cost(choice: Dictionary) -> float:
	var total := 0.0
	for item: Dictionary in items():
		var chosen := int(choice.get(str(item["id"]), -1))
		if chosen >= 0:
			total += float((item["levels"] as Array)[chosen]["cost_pct"])
	return total


static func missing(choice: Dictionary) -> int:
	var count := 0
	for item: Dictionary in items():
		if not choice.has(str(item["id"])):
			count += 1
	return count


static func confirm(choice: Dictionary) -> void:
	choices = choice.duplicate()
	Campaign.budget_left -= cost(choice)
	Flight.prepare()
	Campaign.days = maxf(Campaign.days, float(Flight.build.get("launch_day", int(Campaign.days))) - 3.0 - Campaign.review_days())
	Campaign.stage = 9


static func _load() -> void:
	if not _data.is_empty():
		return
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		push_error("Operations: нет файла %s" % PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_data = parsed
