class_name Campaign
extends RefCounted

const START_DATE := {"year": 2026, "month": 11, "day": 14}
const DEADLINE := {"year": 2033, "month": 7, "day": 20}
const BUDGET_BILLIONS := 60.0
const DAYS_PER_SECOND := 1.0
const CONFIG_PATH := "res://data/campaign.json"

const MONTHS: Array[String] = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
const SCIENCE_DEFAULTS := {
	"salaries_pct": 3.0, "max_pct": 20.0, "requested_pct": 9.0,
	"days_min": 90.0, "days_max": 270.0,
	"margin_best": 1.0, "margin_worst": 15.0,
	"minigame_weight": 0.15, "skip_hit_rate": 0.6,
	"margin_tight": 3.0, "margin_moderate": 8.0,
}

static var stage := 1
static var days := 0.0
static var clock_running := false
static var budget_left := 100.0

static var calc_funding := 0.0
static var calc_round := 0
static var research_days := 0
static var runs_hit := 0
static var runs_total := 0
static var accuracy := 0.0
static var margin := 0.0

static var site := {}
static var instruments: Array = []
static var payload_mass := 0.0
static var payload_power := 0.0
static var payload_cost := 0.0
static var science_value := 0
static var board_confidence := 80.0

static var _science := {}
static var _config := {}
static var _rounds: Array = []
static var _check_sum := 0.0


static func reset() -> void:
	stage = 1
	days = 0.0
	clock_running = false
	budget_left = 100.0
	calc_funding = 0.0
	calc_round = 0
	_check_sum = 0.0
	research_days = 0
	runs_hit = 0
	runs_total = 0
	accuracy = 0.0
	margin = 0.0
	site = {}
	instruments = []
	payload_mass = 0.0
	payload_power = 0.0
	payload_cost = 0.0
	science_value = 0
	Vehicle.reset()
	Operations.reset()
	Flight.reset()
	_load_config()
	board_confidence = float(_section("board").get("confidence_start", 80.0))


static func tick(delta: float) -> void:
	if clock_running:
		days += delta * DAYS_PER_SECOND


static func science() -> Dictionary:
	_load_config()
	return _science


static func calc_rounds() -> Array:
	_load_config()
	return _rounds


static func current_round() -> Dictionary:
	var rounds := calc_rounds()
	return rounds[mini(calc_round, rounds.size() - 1)]


static func _load_config() -> void:
	if not _science.is_empty():
		return
	_science = SCIENCE_DEFAULTS.duplicate()
	_rounds = [{"id": "analysis", "title": "Mission analysis", "when": "Now", "what": "Find the path and the fuel it costs."}]
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	_config = parsed
	if parsed.get("science") is Dictionary:
		for key: String in parsed["science"]:
			_science[key] = float(parsed["science"][key])
	if parsed.get("calc_rounds") is Array and not (parsed["calc_rounds"] as Array).is_empty():
		_rounds = parsed["calc_rounds"]


static func _section(key: String) -> Dictionary:
	_load_config()
	var value: Variant = _config.get(key)
	return value if value is Dictionary else {}


static func sites() -> Array:
	_load_config()
	var value: Variant = _config.get("sites")
	return value if value is Array else []


static func instrument_options() -> Array:
	_load_config()
	var value: Variant = _config.get("instruments")
	return value if value is Array else []


static func plan_totals(chosen_site: Dictionary, chosen: Array) -> Dictionary:
	var totals := {"mass": 0.0, "power": 0.0, "cost": 0.0, "science": int(chosen_site.get("science", 0))}
	for item: Dictionary in chosen:
		totals["mass"] += float(item.get("mass_kg", 0.0))
		totals["power"] += float(item.get("power_w", 0.0))
		totals["cost"] += float(item.get("cost_pct", 0.0))
		totals["science"] += int(item.get("science", 0))
	return totals


static func set_science_plan(chosen_site: Dictionary, chosen: Array) -> void:
	site = chosen_site
	instruments = chosen
	var totals := plan_totals(chosen_site, chosen)
	payload_mass = totals["mass"]
	payload_power = totals["power"]
	payload_cost = totals["cost"]
	science_value = totals["science"]
	budget_left -= payload_cost
	var plan := _section("science_plan")
	days += float(plan.get("days_base", 45.0)) + float(plan.get("days_per_instrument", 10.0)) * chosen.size()
	stage = 5


static func review_finding() -> String:
	if stage == 3:
		return {"tight": "strong", "moderate": "fair", "wide": "weak"}[margin_level()]
	if stage == 7:
		var open_items := Vehicle.shortfalls(Vehicle.stats).size()
		return "strong" if open_items == 0 else ("fair" if open_items == 1 else "weak")
	if stage == 9:
		var late := int(Flight.build.get("launch_day", 0)) > days_total()
		if float(Flight.build.get("reserve_after", 0.0)) < 0.0 or late:
			return "weak"
		return "strong" if (Flight.build.get("left_behind", []) as Array).is_empty() else "fair"
	var board := _section("board")
	if instruments.is_empty() or science_value < int(board.get("science_weak", 30)):
		return "weak"
	return "strong" if science_value >= int(board.get("science_strong", 80)) else "fair"


static func pass_review() -> void:
	var change := {"strong": 5.0, "fair": 0.0, "weak": -15.0 if stage == 3 else -10.0}
	board_confidence = clampf(board_confidence + float(change[review_finding()]), 0.0, 100.0)
	days += review_days()
	if stage == 9:
		days = maxf(days, float(Flight.build.get("launch_day", int(days))) - 3.0)
	stage += 1


static func review_days() -> float:
	return float(_section("board").get("review_days", 14.0))


static func confidence_text() -> String:
	if board_confidence >= 75.0:
		return "High"
	return "Medium" if board_confidence >= 55.0 else "Low"


static func salaries_pct() -> float:
	return float(science()["salaries_pct"])


static func billions(pct: float) -> float:
	return BUDGET_BILLIONS * pct / 100.0


static func fund_calculations(pct: float) -> void:
	var s := science()
	calc_funding = clampf(pct, 0.0, float(s["max_pct"]))
	budget_left = 100.0 - salaries_pct() - calc_funding
	research_days = roundi(lerpf(float(s["days_min"]), float(s["days_max"]), calc_funding / float(s["max_pct"])))


static func finish_calculations(hits: int, total: int) -> void:
	var s := science()
	runs_hit = hits
	runs_total = total
	calc_round = mini(calc_round + 1, calc_rounds().size())
	var requested := float(s["requested_pct"])
	var funded := minf(calc_funding / requested, 1.0)
	if calc_funding > requested:
		funded += 0.2 * (calc_funding - requested) / (float(s["max_pct"]) - requested)
	var weight := float(s["minigame_weight"])
	_check_sum += float(hits) / maxf(float(total), 1.0)
	var hit_rate := _check_sum / maxf(float(calc_round), 1.0)
	accuracy = funded * (1.0 - weight + weight * hit_rate)
	var best := float(s["margin_best"])
	var worst := float(s["margin_worst"])
	margin = lerpf(worst, best, minf(accuracy, 1.0))
	if accuracy > 1.0:
		margin = best * (1.0 - 2.0 * (accuracy - 1.0))
	margin = snappedf(maxf(margin, 0.5), 0.1)
	stage = maxi(stage, 3)


static func auto_round() -> void:
	if calc_round >= calc_rounds().size():
		return
	_check_sum += _check_sum / maxf(float(calc_round), 1.0)
	calc_round += 1


static func margin_level() -> String:
	var s := science()
	if margin <= float(s["margin_tight"]):
		return "tight"
	if margin <= float(s["margin_moderate"]):
		return "moderate"
	return "wide"


static func day_number() -> int:
	return int(days) + 1


static func date_text(extra_days := -1) -> String:
	var d := Time.get_datetime_dict_from_unix_time(_start_unix() + int(days if extra_days < 0 else extra_days) * 86400)
	return "%02d %s %d" % [d.day, MONTHS[d.month - 1], d.year]


static func year() -> int:
	return int(Time.get_datetime_dict_from_unix_time(_start_unix() + int(days) * 86400).year)


static func deadline_text() -> String:
	return "%02d %s %d" % [DEADLINE.day, MONTHS[DEADLINE.month - 1], DEADLINE.year]


static func days_left() -> int:
	return days_total() - int(days)


static func days_total() -> int:
	return int((Time.get_unix_time_from_datetime_dict(DEADLINE) - _start_unix()) / 86400)


static func _start_unix() -> int:
	return Time.get_unix_time_from_datetime_dict(START_DATE)
