class_name Vehicle
extends RefCounted

const PATH := "res://data/vehicle.json"

static var design := {}
static var stats := {}
static var reliability := 1.0
static var draft := {}

static var _data := {}


static func reset() -> void:
	design = {}
	draft = {}
	stats = {}
	reliability = 1.0


static func slots() -> Array:
	_load()
	var value: Variant = _data.get("slots")
	return value if value is Array else []


static func rules() -> Dictionary:
	_load()
	var value: Variant = _data.get("rules")
	return value if value is Dictionary else {}


static func slot(slot_id: String) -> Dictionary:
	for item: Dictionary in slots():
		if item.get("id") == slot_id:
			return item
	return {}


static func chosen(choice: Dictionary, slot_id: String) -> Dictionary:
	var part_id := str(choice.get(slot_id, ""))
	for part: Dictionary in slot(slot_id).get("parts", []):
		if part.get("id") == part_id:
			return part
	return {}


static func missing(choice: Dictionary) -> int:
	var count := 0
	for item: Dictionary in slots():
		if chosen(choice, str(item["id"])).is_empty():
			count += 1
	return count


static func evaluate(choice: Dictionary) -> Dictionary:
	var rule := rules()
	var g0 := float(rule.get("g0", 9.80665))
	var reserve := 1.0 + Campaign.margin / 100.0
	var stage1 := chosen(choice, "stage1")
	var stage2 := chosen(choice, "stage2")
	var stage3 := chosen(choice, "stage3")
	var lander := chosen(choice, "lander")
	var service := chosen(choice, "service")
	var capsule := chosen(choice, "capsule")
	var escape := chosen(choice, "escape")
	var life := chosen(choice, "life")
	var suits := chosen(choice, "suits")
	var power := chosen(choice, "power")
	var comms := chosen(choice, "comms")
	var tests := chosen(choice, "tests")
	var spaceport := chosen(choice, "spaceport")

	var parts_cost := 0.0
	var build_days := 0.0
	var risk_free := 1.0
	for item: Dictionary in slots():
		var part := chosen(choice, str(item["id"]))
		parts_cost += float(part.get("cost_pct", 0.0))
		if item["id"] != "tests":
			build_days = maxf(build_days, float(part.get("days", 0.0)))
		risk_free *= 1.0 - float(part.get("risk", 0.0))

	var seats := int(capsule.get("crew", 0))
	var surface_crew := mini(int(lander.get("crew", 0)), maxi(seats - 1, 0))
	var high_orbit := str(lander.get("orbit", "")) == "nrho"
	var mission_days := 0.0
	if seats > 0:
		mission_days = float(rule.get("transit_days", 8.0)) + float(lander.get("stay_days", 0.0)) \
				+ (float(rule.get("nrho_extra_days", 6.0)) if high_orbit else 0.0)
	var crew_days := seats * mission_days
	var per_day := float(life.get("per_day", 0.0))
	if bool(life.get("stored_water", false)) and bool(power.get("makes_water", false)):
		per_day = maxf(per_day - float(rule.get("water_from_cells_kg", 3.0)), 0.0)
	var supplies := 0.0
	if not life.is_empty():
		supplies = float(life.get("fixed", 0.0)) + per_day * crew_days / 1000.0
	var suits_mass := float(suits.get("suit_mass", 0.0)) * seats

	var payload_t := Campaign.payload_mass / 1000.0
	var ship_dry := float(capsule.get("mass", 0.0)) + float(escape.get("carried_mass", 0.0)) \
			+ float(power.get("mass", 0.0)) + float(comms.get("mass", 0.0)) + float(service.get("dry", 0.0)) \
			+ supplies + suits_mass
	var ship_prop := float(service.get("prop", 0.0))
	var lander_mass := float(lander.get("mass", 0.0)) + (0.0 if high_orbit else payload_t)
	var spacecraft := ship_dry + ship_prop + lander_mass

	var above := spacecraft + (float(rule.get("adapter_mass", 3.8)) if spacecraft > 0.0 else 0.0)
	var mass3 := above + float(stage3.get("dry", 0.0)) + float(stage3.get("prop", 0.0))
	var dv3 := _burn(float(stage3.get("isp", 0.0)), g0, mass3, float(stage3.get("prop", 0.0)))
	var mass2 := mass3 + float(stage2.get("dry", 0.0)) + float(stage2.get("prop", 0.0))
	var dv2 := _burn(float(stage2.get("isp", 0.0)), g0, mass2, float(stage2.get("prop", 0.0)))
	var liftoff := mass2 + float(stage1.get("dry", 0.0)) + float(stage1.get("prop", 0.0)) + float(escape.get("tower_mass", 0.0))
	var dv1 := _burn(float(stage1.get("isp", 0.0)), g0, liftoff, float(stage1.get("prop", 0.0)))
	var rocket_dv := dv1 + dv2 + dv3
	var thrust := float(stage1.get("thrust", 0.0))
	var burn1 := 0.0
	if thrust > 0.0 and float(stage1.get("isp", 0.0)) > 0.0:
		burn1 = float(stage1.get("prop", 0.0)) * 1000.0 / (thrust * 1.0e6 / (float(stage1.get("isp", 0.0)) * g0))
	var twr := thrust * 1000.0 / (liftoff * g0) if liftoff > 0.0 else 0.0
	var site_dv := float(spaceport.get("dv_penalty", 0.0))
	var rocket_need := float(rule.get("ascent_dv", 9.2)) + float(rule.get("tli_dv", 3.15)) * reserve + site_dv

	var loi_need := float(rule.get("nrho_loi_dv" if high_orbit else "loi_dv", 0.95)) * reserve
	var tei_need := float(rule.get("nrho_tei_dv" if high_orbit else "tei_dv", 1.05)) * reserve
	if not high_orbit:
		tei_need += float(Campaign.site.get("extra_dv", 0.0))
	var exhaust := float(service.get("isp", 0.0)) * g0 / 1000.0
	var ship_dv := 0.0
	if exhaust > 0.0 and ship_prop > 0.0:
		var loi_prop := (ship_dry + ship_prop + lander_mass) * (1.0 - exp(-loi_need / exhaust))
		if loi_prop >= ship_prop:
			ship_dv = exhaust * log((ship_dry + ship_prop + lander_mass) / (ship_dry + lander_mass))
		else:
			var left := ship_prop - loi_prop
			ship_dv = loi_need + exhaust * log((ship_dry + left) / ship_dry)

	var power_need := float(capsule.get("power_kw", 0.0)) + float(service.get("power_kw", 0.0)) \
			+ float(comms.get("power_kw", 0.0)) + float(life.get("power_kw", 0.0)) + Campaign.payload_power / 1000.0

	var prices: Dictionary = rule.get("propellant_usd_per_kg", {})
	var propellant := 0.0
	var propellant_usd := 0.0
	for stage: Dictionary in [stage1, stage2, stage3, service]:
		var tonnes := float(stage.get("prop", 0.0))
		propellant += tonnes
		propellant_usd += tonnes * 1000.0 * float(prices.get(str(stage.get("fuel", "")), 1.0))

	var program_days := roundi(build_days) + int(tests.get("extra_days", 0)) + int(rule.get("integration_days", 90))
	var workforce := 0.0
	if not choice.is_empty():
		workforce = float(rule.get("workforce_pct_per_100_days", 0.3)) * program_days / 100.0
	var cost := parts_cost + workforce
	var ready_day := int(Campaign.days) + program_days
	var found_table: Array = rule.get("test_found", [0.0, 0.55, 0.85, 0.92])
	var found := 0.0
	if not tests.is_empty():
		found = float(found_table[clampi(int(tests.get("test_level", 0)), 0, found_table.size() - 1)])
	return {
		"complete": missing(choice) == 0,
		"cost": cost,
		"parts_cost": parts_cost,
		"workforce_cost": workforce,
		"program_days": program_days,
		"budget_after": Campaign.budget_left - cost,
		"build_days": roundi(build_days),
		"ready_day": ready_day,
		"spare_days": Campaign.days_total() - ready_day,
		"liftoff_mass": liftoff,
		"thrust_to_weight": twr,
		"rocket_dv": rocket_dv,
		"stage_dv": [dv1, dv2, dv3],
		"stage1_burn": burn1,
		"rocket_need": rocket_need,
		"site_dv": site_dv,
		"spaceport": str(spaceport.get("id", "")),
		"overland": bool(spaceport.get("overland", false)),
		"rocket_built": not stage1.is_empty() and not stage2.is_empty() and not stage3.is_empty(),
		"spacecraft_mass": spacecraft,
		"ship_dv": ship_dv,
		"ship_need": loi_need + tei_need,
		"ship_built": not service.is_empty(),
		"high_orbit": high_orbit,
		"cargo_need": Campaign.payload_mass,
		"cargo_capacity": float(lander.get("cargo_kg", 0.0)),
		"lander_built": not lander.is_empty(),
		"power_need": power_need,
		"power_have": float(power.get("power_kw", 0.0)),
		"power_built": not power.is_empty(),
		"crew": seats,
		"surface_crew": surface_crew,
		"mission_days": mission_days,
		"crew_days": crew_days,
		"supplies": supplies,
		"life_built": not life.is_empty(),
		"eva_hours": float(suits.get("eva_hours", 0.0)),
		"suits_built": not suits.is_empty(),
		"propellant": propellant,
		"propellant_usd": propellant_usd,
		"reserve_pct": Campaign.margin,
		"reliability": 1.0 - (1.0 - risk_free) * (1.0 - found),
		"abort": str(escape.get("abort", "none")),
		"link": str(comms.get("link", "basic")),
		"stay_days": float(lander.get("stay_days", 0.0)),
	}


static func shortfalls(result: Dictionary) -> Array[String]:
	var found: Array[String] = []
	if float(result["thrust_to_weight"]) < 1.05:
		found.append("liftoff")
	if float(result["rocket_dv"]) < float(result["rocket_need"]):
		found.append("rocket")
	if float(result["ship_dv"]) < float(result["ship_need"]):
		found.append("ship")
	if float(result["cargo_need"]) > float(result["cargo_capacity"]):
		found.append("cargo")
	if float(result["power_need"]) > float(result["power_have"]):
		found.append("power")
	if float(result.get("eva_hours", 1.0)) <= 0.0:
		found.append("suits")
	if int(result["spare_days"]) < 0:
		found.append("late")
	if bool(result.get("overland", false)):
		found.append("range")
	return found


static func hand_over(choice: Dictionary) -> void:
	design = choice.duplicate()
	stats = evaluate(choice)
	reliability = float(stats["reliability"])
	Campaign.budget_left -= float(stats["cost"])
	Campaign.stage = 7


static func launch_site() -> Dictionary:
	var moved := str(Flight.build.get("launch_from", ""))
	return chosen({"spaceport": moved if not moved.is_empty() else str(design.get("spaceport", ""))}, "spaceport")


static func summary(choice: Dictionary) -> Array:
	var rows := []
	for item: Dictionary in slots():
		rows.append([str(item["title"]), str(chosen(choice, str(item["id"])).get("name", "—"))])
	return rows


static func _burn(isp: float, g0: float, start_mass: float, propellant: float) -> float:
	if isp <= 0.0 or propellant <= 0.0 or start_mass <= propellant:
		return 0.0
	return isp * g0 * log(start_mass / (start_mass - propellant)) / 1000.0


static func _load() -> void:
	if not _data.is_empty():
		return
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		push_error("Vehicle: нет файла %s" % PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_data = parsed
