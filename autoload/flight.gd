class_name Flight
extends RefCounted

static var build := {}
static var result := {}
static var _before := {}


static func reset() -> void:
	build = {}
	result = {}
	_before = {}


static func _rng(tag: String) -> RandomNumberGenerator:
	var parts: Array = [tag, Campaign.calc_funding, snappedf(Campaign.accuracy, 0.01), str(Campaign.site.get("id", ""))]
	for item: Dictionary in Campaign.instruments:
		parts.append(str(item.get("id", "")))
	for slot: Dictionary in Vehicle.slots():
		parts.append(str(Vehicle.design.get(str(slot["id"]), "")))
	for item: Dictionary in Operations.items():
		parts.append(Operations.level(str(item["id"])))
	var rng := RandomNumberGenerator.new()
	rng.seed = str(parts).hash()
	return rng


static func prepare() -> void:
	var rng := _rng("build")
	var stats := Vehicle.stats
	var rule := Vehicle.rules()
	var tests := Vehicle.chosen(Vehicle.design, "tests")
	var found_table: Array = rule.get("test_found", [0.0, 0.55, 0.85, 0.92])
	var found := float(found_table[clampi(int(tests.get("test_level", 0)), 0, found_table.size() - 1)])
	var events: Array = []
	var latent := {}
	for slot: Dictionary in Vehicle.slots():
		var slot_id := str(slot["id"])
		var part := Vehicle.chosen(Vehicle.design, slot_id)
		var risk := float(part.get("risk", 0.0)) * float(rule.get("risk_scale", 2.0))
		if risk <= 0.0 or rng.randf() >= risk:
			continue
		if rng.randf() < found:
			events.append({
				"kind": "flaw", "slot": slot_id,
				"text": "Testing found a flaw in the %s (%s). It was fixed before flight." % [str(slot["title"]).to_lower(), str(part["name"]).to_lower()],
				"days": rng.randi_range(25, 60), "cost": snappedf(rng.randf_range(0.6, 1.6), 0.1),
			})
		else:
			latent[slot_id] = true
	var chosen_port := Vehicle.chosen(Vehicle.design, "spaceport")
	var launch_from := str(chosen_port.get("id", ""))
	if bool(chosen_port.get("overland", false)):
		launch_from = str(rule.get("move_to", "port_ksc"))
		var new_port := Vehicle.chosen({"spaceport": launch_from}, "spaceport")
		events.append({
			"kind": "move", "slot": "spaceport",
			"text": "Range safety did not approve a launch from %s: every flight path crosses land, and the spent stages would fall on it. The rocket and its ground equipment were moved to %s." % [str(chosen_port.get("name", "the chosen site")), str(new_port.get("name", "the coast"))],
			"days": int(rule.get("move_days", 240)), "cost": float(rule.get("move_cost_pct", 2.4)),
		})
	var pool: Array = (Operations.rules().get("ordinary_events", []) as Array).duplicate()
	var count := 1 + (1 if rng.randf() < 0.55 else 0)
	for index in count:
		if pool.is_empty():
			break
		var pick := rng.randi_range(0, pool.size() - 1)
		events.append({"kind": "ordinary", "slot": "", "text": str(pool[pick]), "days": rng.randi_range(10, 30), "cost": snappedf(rng.randf_range(0.3, 0.8), 0.1)})
		pool.remove_at(pick)

	_before = {}
	var kept: Array = Campaign.instruments.duplicate()
	var left_behind: Array = []
	var capacity := float(stats.get("cargo_capacity", 0.0))
	var mass := 0.0
	for item: Dictionary in kept:
		mass += float(item.get("mass_kg", 0.0))
	while mass > capacity and not kept.is_empty():
		var worst := 0
		var worst_value := INF
		for index in kept.size():
			var value := float(kept[index].get("science", 0)) / maxf(float(kept[index].get("mass_kg", 1.0)), 1.0)
			if value < worst_value:
				worst_value = value
				worst = index
		mass -= float(kept[worst].get("mass_kg", 0.0))
		left_behind.append({"name": str(kept[worst].get("name", "")), "reason": "mass"})
		kept.remove_at(worst)
	var power_need := float(stats.get("power_need", 0.0))
	var power_have := float(stats.get("power_have", 0.0))
	while power_need > power_have + 0.0001:
		var hungry := -1
		for index in kept.size():
			if float(kept[index].get("power_w", 0.0)) > 0.0 and (hungry < 0 or float(kept[index]["power_w"]) > float(kept[hungry]["power_w"])):
				hungry = index
		if hungry < 0:
			break
		power_need -= float(kept[hungry]["power_w"]) / 1000.0
		left_behind.append({"name": str(kept[hungry].get("name", "")), "reason": "power"})
		kept.remove_at(hungry)

	var delay := 0
	var cost := 0.0
	for event: Dictionary in events:
		delay += int(event["days"])
		cost += float(event["cost"])
	var idle_cost := snappedf(float(rule.get("workforce_pct_per_100_days", 0.3)) * delay / 100.0, 0.01)
	var reserve_before := Campaign.budget_left
	Campaign.budget_left -= cost + idle_cost
	Campaign.auto_round()
	build = {
		"events": events, "latent": latent, "kept": kept, "left_behind": left_behind,
		"power_short": power_need > power_have + 0.0001,
		"delay": delay, "cost": cost, "idle_cost": idle_cost,
		"reserve_before": reserve_before, "reserve_after": Campaign.budget_left,
		"launch_day": int(stats.get("ready_day", int(Campaign.days))) + delay,
		"found_fraction": found, "tests": str(tests.get("name", "")),
		"launch_from": launch_from, "moved": launch_from != str(chosen_port.get("id", "")),
	}


static func staging_gain(error: float) -> float:
	if absf(error) <= 0.15:
		return 0.02
	if error > 0.0:
		return lerpf(0.02, -0.02, clampf((error - 0.15) / 1.2, 0.0, 1.0))
	return lerpf(0.02, -0.03, clampf((-error - 0.15) / 1.2, 0.0, 1.0))


static func fly(overrides := {}) -> void:
	if _before.is_empty():
		_before = {"budget": Campaign.budget_left, "days": Campaign.days, "round": Campaign.calc_round, "check": Campaign._check_sum}
	else:
		Campaign.budget_left = float(_before["budget"])
		Campaign.days = float(_before["days"])
		Campaign.calc_round = int(_before["round"])
		Campaign._check_sum = float(_before["check"])
	var rng := _rng("flight")
	var stats := Vehicle.stats
	var design := Vehicle.design
	var rule := Vehicle.rules()
	var latent: Dictionary = build.get("latent", {})
	var accuracy := clampf(Campaign.accuracy, 0.0, 1.0)
	var margin := Campaign.margin
	var training := Operations.level("training")
	var control := Operations.level("control")
	var launch_team := Operations.level("launch")
	var recovery := Operations.level("recovery")
	var computer := Operations.level("computer")
	var high_orbit: bool = stats.get("high_orbit", false)
	var site := Campaign.site
	var port := Vehicle.launch_site()
	var port_name := str(port.get("name", "the launch site"))
	var port_text := "Stage 6  ·  Launch site: %s" % str(Vehicle.chosen(design, "spaceport").get("name", "—"))
	var phases: Array = []
	var causes: Array = []
	var outcome := "landed"
	var luck := rng.randf_range(0.15, 1.0)
	var funding_text := "Stage 2  ·  Flight Dynamics funded at %s%% (the team asked for %s%%)" % [_num(Campaign.calc_funding), _num(float(Campaign.science()["requested_pct"]))]
	var tests_text := "Stage 6  ·  Test programme: %s" % _lower(str(build.get("tests", "")))

	var flaws_found := 0
	for event: Dictionary in build.get("events", []):
		if event["kind"] == "flaw":
			flaws_found += 1
	if flaws_found > 0:
		causes.append(_cause(true, tests_text, "Testing found %d flaw%s on the ground. Each cost time and money then, and nothing in flight." % [flaws_found, "" if flaws_found == 1 else "s"]))
	var surprises := float(build.get("cost", 0.0)) + float(build.get("idle_cost", 0.0))
	if float(build.get("reserve_after", 0.0)) < 0.0:
		causes.append(_cause(false, "Stage 8  ·  Reserve kept: %s%%" % _num(float(build.get("reserve_before", 0.0))),
				"Delays and repairs during the build cost %s%%. The reserve could not cover them, and the programme went over budget." % _num(surprises)))
	elif surprises > 0.0:
		causes.append(_cause(true, "Stage 8  ·  Reserve kept: %s%%" % _num(float(build.get("reserve_before", 0.0))),
				"Delays and repairs during the build cost %s%%. The reserve paid for them." % _num(surprises)))
	var too_heavy: Array[String] = []
	var unpowered: Array[String] = []
	for item: Dictionary in build.get("left_behind", []):
		if item["reason"] == "mass":
			too_heavy.append(_lower(str(item["name"])))
		else:
			unpowered.append(_lower(str(item["name"])))
	if not too_heavy.is_empty():
		causes.append(_cause(false, "Stage 6  ·  Lander: %s" % _part_name(design, "lander"),
				"The science plan weighed more than the lander can carry. Left on Earth: %s." % ", ".join(too_heavy)))
	if not unpowered.is_empty():
		causes.append(_cause(false, "Stage 6  ·  Power: %s" % _part_name(design, "power"),
				"There was not enough electric power for every instrument. Left on Earth: %s." % ", ".join(unpowered)))

	if build.get("moved", false):
		causes.append(_cause(false, port_text, "Every flight path from there crosses land, so range safety did not allow the launch. Moving the rocket to %s cost %d days and %s%% of the budget." % [port_name, int(rule.get("move_days", 240)), _num(float(rule.get("move_cost_pct", 2.4)))]))

	var launch_day := maxi(int(Campaign.days), int(build.get("launch_day", int(Campaign.days))))
	var phase := _phase(phases, "countdown", "Countdown", "pad", 0.0)
	var scrubs: int = [2, 1, 0][launch_team] + (1 if latent.has("ground") else 0)
	var scrub_causes: Array = Operations.rules().get("scrub_causes", ["a technical fault"])
	var scrub_days := 0
	var two_pads := int(Vehicle.chosen(design, "ground").get("pads", 1)) >= 2
	for attempt in scrubs:
		var wait := rng.randi_range(2, 6)
		if two_pads:
			wait = maxi(1, wait / 2)
		scrub_days += wait
		_say(phase, "Launch attempt %d stopped at T−%d minutes: %s. Next attempt in %d days." % [attempt + 1, rng.randi_range(6, 55), str(scrub_causes[rng.randi_range(0, scrub_causes.size() - 1)]), wait], "bad")
	var weather := float(port.get("weather", 0.0))
	var weather_scrubs := 0
	var weather_days := 0
	for attempt in 2:
		if rng.randf() >= weather * (1.0 if attempt == 0 else 0.5):
			break
		var wait := rng.randi_range(1, 3)
		weather_scrubs += 1
		weather_days += wait
		_say(phase, "Launch attempt %d called off at T−%d minutes: %s. Next attempt in %d day%s." % [scrubs + weather_scrubs, rng.randi_range(9, 40), str(port.get("weather_cause", "the weather")), wait, "" if wait == 1 else "s"], "bad")
	scrubs += weather_scrubs
	scrub_days += weather_days
	var scrub_cost := scrubs * float(Operations.rules().get("scrub_cost_pct", 0.15))
	launch_day += scrub_days
	if weather_scrubs > 0:
		causes.append(_cause(false, port_text, "Weather at %s stopped %s. Waiting for clear skies cost %d day%s." % [port_name, "one launch attempt" if weather_scrubs == 1 else "%d launch attempts" % weather_scrubs, weather_days, "" if weather_days == 1 else "s"]))
	var team_scrubs := scrubs - weather_scrubs
	if team_scrubs >= 2:
		causes.append(_cause(false, "Stage 8  ·  Launch team: %s" % Operations.level_name("launch").to_lower(),
				"%d launch attempts were stopped by technical faults. They cost %d days and %s%% of the budget." % [team_scrubs, scrub_days - weather_days, _num(team_scrubs * float(Operations.rules().get("scrub_cost_pct", 0.15)))]))
	elif team_scrubs == 0 and launch_team == 2 and float(stats.get("thrust_to_weight", 0.0)) >= 1.0:
		causes.append(_cause(true, "Stage 8  ·  Launch team: %s" % Operations.level_name("launch").to_lower(),
				"The practice countdown had already found the leaks. The rocket left on the first attempt."))
	Campaign.auto_round()
	var thrust_to_weight := float(stats.get("thrust_to_weight", 0.0))
	var rocket_have := float(stats.get("rocket_dv", 0.0))
	phase["gate"] = (phase["lines"] as Array).size()
	if thrust_to_weight < 1.0:
		outcome = "no_launch"
		phase["status"] = "problem"
		_say(phase, "Ignition. The engines reached full thrust and the rocket did not move: it weighs more than its engines can lift. The computer shut them down.", "bad")
		causes.append(_cause(false, "Stage 6  ·  First stage: %s" % _part_name(design, "stage1"),
				"Thrust-to-weight at lift-off was %.2f. Below 1, a rocket cannot leave the ground." % thrust_to_weight))
	else:
		_say(phase, "Lift-off from %s on %s, %s." % [port_name, Campaign.date_text(launch_day).capitalize(), _deadline_words(launch_day)], "good" if launch_day <= Campaign.days_total() else "bad")
		if thrust_to_weight < 1.08:
			rocket_have -= 0.12
			_say(phase, "The rocket left the pad slowly and spent extra propellant holding itself up.", "info")

	var side := str(Vehicle.chosen(design, "stage1").get("mount", "")) == "side"
	var stage_names: Array = ["boosters", "core stage"] if side else ["first stage", "second stage"]
	if outcome == "landed":
		phase = _phase(phases, "ascent", "Ascent", "ascent", 0.0)
		var abort := str(stats.get("abort", "none"))
		phase["fail"] = "stage1" if latent.has("stage1") else ("stage2" if latent.has("stage2") else "")
		if latent.has("stage1"):
			phase["status"] = "problem"
			_say(phase, "T+72 seconds: a first-stage engine failed and the rocket began to break up.", "bad")
			causes.append(_cause(false, tests_text, "A flaw in the first stage (%s) was never found on the ground. It showed itself 72 seconds into the flight." % _part_name(design, "stage1")))
			var escape_text := "Stage 6  ·  Launch escape: %s" % _part_name(design, "escape")
			if abort == "none":
				outcome = "crew_lost"
				_say(phase, "There was no escape system. The crew was lost.", "bad")
				causes.append(_cause(false, escape_text, "With nothing to pull the capsule away, the crew had no way out."))
			else:
				outcome = "launch_abort"
				_say(phase, str({"tower": "The escape tower fired and pulled the capsule clear.", "tower_steered": "The escape tower fired, pulled the capsule clear and turned it heat shield first.",
						"integrated": "The capsule's own abort engines pushed it clear of the rocket."}.get(abort, "The escape system pulled the capsule clear.")), "good")
				_say(phase, "The capsule came down under parachutes a few kilometres offshore. The crew is safe.", "good", "sea")
				causes.append(_cause(true, escape_text, "The escape system worked. The mission was lost, the crew was not."))
		elif latent.has("stage2"):
			outcome = "launch_abort"
			phase["status"] = "problem"
			_say(phase, "%s and fell away on time." % ("The boosters burned out" if side else "First stage shut down"), "info", "drop1")
			_say(phase, "T+4 minutes: the %s lost thrust above the atmosphere." % stage_names[1], "bad")
			_say(phase, "The spacecraft separated and used its own engine to reach a safe path home. The crew is safe.", "good", "sea")
			causes.append(_cause(false, tests_text, "A flaw in the second stage (%s) was never found on the ground. It failed four minutes into the flight." % _part_name(design, "stage2")))
		else:
			var staging: Array = overrides.get("staging", [])
			if staging.is_empty():
				_say(phase, "%s and fell away on time." % ("The boosters burned out" if side else "First stage shut down"), "info", "drop1")
				if abort in ["tower", "tower_steered"]:
					_say(phase, "The escape tower was dropped, unused.", "info")
				_say(phase, "%s burned out and fell away. The stack is in space." % stage_names[1].capitalize(), "info", "drop2")
			else:
				var gained := 0.0
				for index in staging.size():
					var error := float(staging[index])
					var gain := staging_gain(error)
					gained += gain
					var when := "at the right moment" if absf(error) <= 0.15 else ("%.1f s late" % error if error > 0.0 else "%.1f s early" % -error)
					var effect := "Nothing wasted, nothing carried" if absf(error) <= 0.15 else ("An empty stage rode along as dead weight" if error > 0.0 else "Unburned propellant fell away with it")
					_say(phase, "You dropped the %s %s. %s: %s%d m/s." % [stage_names[mini(index, 1)], when, effect, "+" if gain >= 0.0 else "−", roundi(absf(gain) * 1000.0)], "good" if gain >= 0.0 else "bad")
				rocket_have += gained
				_say(phase, "The stack is in space.", "info")
				causes.append(_cause(gained >= 0.0, "Stage 10  ·  You dropped the stages by hand",
						"Your timing %s %d m/s of rocket speed compared with the automatic sequence." % ["added" if gained >= 0.0 else "cost", roundi(absf(gained) * 1000.0)]))

	if outcome == "landed":
		phase = _phase(phases, "orbit", "Earth orbit", "map", 0.1)
		_say(phase, "Parking orbit. The crew and mission control check every system before leaving Earth.", "info")
		if computer == 0 and rng.randf() < 0.4:
			_say(phase, "The flight computer restarted once during the checks. The crew reloaded it by hand.", "info")

	var ship_base := (float(rule.get("nrho_loi_dv", 0.45)) + float(rule.get("nrho_tei_dv", 0.45))) if high_orbit \
			else (float(rule.get("loi_dv", 0.95)) + float(rule.get("tei_dv", 1.05)))
	var ship_need := ship_base * (1.0 + margin / 100.0 * luck) + (0.0 if high_orbit else float(site.get("extra_dv", 0.0)))
	var ship_have := float(stats.get("ship_dv", 0.0))
	var mission_days := float(stats.get("mission_days", 9.0))
	var boil_off := 0.0
	if str(design.get("service", "")) == "service_cryo":
		boil_off = ship_have * 0.006 * maxf(mission_days - 3.0, 0.0)
		ship_have -= boil_off
	var made_up := 0.0
	if outcome == "landed":
		phase = _phase(phases, "tli", "Burn for the Moon", "map", 0.15)
		var site_dv := float(port.get("dv_penalty", 0.0))
		var rocket_need := float(rule.get("ascent_dv", 9.2)) + float(rule.get("tli_dv", 3.15)) * (1.0 + margin / 100.0 * luck) + site_dv
		phase["gauge"] = {"label": "Rocket speed", "have": rocket_have, "need": rocket_need}
		var rocket_text := "Stage 6  ·  Rocket: %s, %s, %s" % [_part_name(design, "stage1"), _part_name(design, "stage2"), _part_name(design, "stage3")]
		if latent.has("stage3"):
			outcome = "earth_orbit"
			phase["status"] = "problem"
			_say(phase, "The third stage did not restart. Without that burn the spacecraft cannot leave Earth orbit.", "bad")
			causes.append(_cause(false, tests_text, "A flaw in the third stage (%s) was never found on the ground. Its engine did not restart in orbit." % _part_name(design, "stage3")))
		elif rocket_have >= rocket_need:
			_say(phase, "The third stage restarted and burned for about six minutes. Speed needed: %.2f km/s. The rocket delivered it." % rocket_need, "good")
			var spare := rocket_have - rocket_need
			if site_dv <= 0.0 and spare < _worst_site_dv():
				causes.append(_cause(true, port_text, "The Earth's spin gave the rocket %d m/s at lift-off, the most of any site on the list. The rocket reached the speed for the Moon with %d m/s to spare." % [int(port.get("spin", 0)), roundi(spare * 1000.0)]))
			elif site_dv > 0.0:
				causes.append(_cause(true, port_text, "From %s the Earth's spin adds %d m/s, %d m/s less than from %s. The rocket was large enough to make up the difference." % [port_name, int(port.get("spin", 0)), roundi(site_dv * 1000.0), _best_site_name()]))
		else:
			var short := rocket_need - rocket_have
			if short <= minf(0.3, ship_have - ship_need):
				made_up = short
				ship_have -= short
				_say(phase, "The third stage ran dry %d m/s short. The spacecraft lit its own engine and made up the difference." % roundi(short * 1000.0), "bad")
				causes.append(_cause(false, rocket_text, "The rocket fell %d m/s short of the speed for the Moon. The spacecraft engine covered it out of its own reserve." % roundi(short * 1000.0)))
				if site_dv >= short:
					causes.append(_cause(false, port_text, "From %s the Earth's spin adds %d m/s, %d m/s less than from %s. That difference is more than the rocket lacked." % [port_name, int(port.get("spin", 0)), roundi(site_dv * 1000.0), _best_site_name()]))
			else:
				outcome = "earth_orbit"
				phase["status"] = "problem"
				_say(phase, "The third stage ran dry %d m/s short of the speed needed to reach the Moon." % roundi(short * 1000.0), "bad")
				_say(phase, "Flight rule: no translunar injection. The crew will return from Earth orbit.", "bad")
				causes.append(_cause(false, rocket_text, "The rocket could deliver %.2f km/s. This flight needed %.2f km/s." % [rocket_have, rocket_need]))
				if site_dv >= short:
					causes.append(_cause(false, port_text, "From %s the Earth's spin adds %d m/s, %d m/s less than from %s. That difference is more than the rocket lacked." % [port_name, int(port.get("spin", 0)), roundi(site_dv * 1000.0), _best_site_name()]))
				if rocket_have >= float(rule.get("ascent_dv", 9.2)) + float(rule.get("tli_dv", 3.15)):
					causes.append(_cause(false, funding_text, "The path was known only to within ±%s%%. With a path known exactly, the same rocket would have been enough." % _num(margin)))

	var link := str(stats.get("link", "basic"))
	var data_factor := 1.0
	var stay_factor := 1.0
	if outcome == "landed":
		phase = _phase(phases, "coast", "Coast to the Moon", "map", 0.3)
		var corrections := 1 + roundi((1.0 - accuracy) * 3.0)
		var tracking: float = [1.3, 1.0, 0.9][control]
		var correction_ms := maxi(2, roundi(ship_base * margin / 100.0 * luck * 400.0 * tracking))
		_say(phase, "%d course correction%s on the way out, %d m/s in total." % [corrections, "" if corrections == 1 else "s", correction_ms], "good" if correction_ms <= 12 else "info")
		if correction_ms <= 12:
			causes.append(_cause(true, funding_text, "The path was known to within ±%s%%. The spacecraft needed only %d m/s of corrections on the way to the Moon." % [_num(margin), correction_ms]))
		elif correction_ms >= 40:
			causes.append(_cause(false, funding_text, "The path was known only to within ±%s%%. Putting it right took %d corrections and %d m/s of propellant." % [_num(margin), corrections, correction_ms]))
		if latent.has("power"):
			data_factor *= 0.7
			phase["status"] = "problem"
			_say(phase, "Day 2: part of the power system failed. Mission control switched off everything that was not essential.", "bad")
			causes.append(_cause(false, tests_text, "A flaw in the power system (%s) was never found on the ground. The crew flew the rest of the mission on reduced power." % _part_name(design, "power")))
		if build.get("power_short", false):
			data_factor *= 0.8
			link = "basic"
			_say(phase, "The spacecraft needs more power than its source gives. The fast radio and the heaters stay off most of the time.", "bad")
			causes.append(_cause(false, "Stage 6  ·  Power: %s" % _part_name(design, "power"), "The power source gives %s kW and the spacecraft needs %s kW. The crew flew with systems switched off." % [_num(float(stats.get("power_have", 0.0))), _num(float(stats.get("power_need", 0.0)))]))
		if latent.has("life"):
			stay_factor = 0.5
			phase["status"] = "problem"
			_say(phase, "Day 3: the air system began to lose performance. The stay at the Moon will be cut short.", "bad")
			causes.append(_cause(false, tests_text, "A flaw in the life support (%s) was never found on the ground. The surface stay was cut by half." % _part_name(design, "life")))
		if latent.has("comms"):
			link = "basic"
			phase["status"] = "problem"
			_say(phase, "The main antenna stopped tracking Earth. Only the slow link is left.", "bad")
			causes.append(_cause(false, tests_text, "A flaw in the communications (%s) was never found on the ground. Most of the science data could not be sent home." % _part_name(design, "comms")))
		if phase["status"] == "ok" and not build.get("power_short", false):
			_say(phase, "Three quiet days. The Earth shrinks in the window.", "info")
		Campaign.auto_round()

	if outcome == "landed":
		phase = _phase(phases, "loi", "Lunar orbit", "map", 3.2)
		phase["gauge"] = {"label": "Spacecraft engine", "have": ship_have, "need": ship_need}
		var service_text := "Stage 6  ·  Service module: %s" % _part_name(design, "service")
		if latent.has("service"):
			outcome = "flyby"
			phase["status"] = "problem"
			_say(phase, "The main engine shut down seconds into the braking burn.", "bad")
			_say(phase, "Flight rule: do not stay. The spacecraft swings around the far side and heads home.", "bad")
			causes.append(_cause(false, tests_text, "A flaw in the service module engine (%s) was never found on the ground. It failed at the Moon." % _part_name(design, "service")))
		elif ship_have < ship_need:
			outcome = "flyby"
			phase["status"] = "problem"
			_say(phase, "Mission control added up the propellant. Entering lunar orbit and leaving it again needs %.2f km/s. The spacecraft has %.2f." % [ship_need, ship_have], "bad")
			_say(phase, "Flight rule: NO-GO for lunar orbit. The crew loops around the far side and comes home.", "bad")
			causes.append(_cause(false, service_text, "The spacecraft engine could give %.2f km/s. Stopping at the Moon and coming home needed %.2f km/s." % [ship_have, ship_need]))
			if boil_off > 0.0:
				causes.append(_cause(false, service_text, "Hydrogen boiled away during the flight: %d m/s of the engine's reserve was gone before it was needed." % roundi(boil_off * 1000.0)))
			if made_up > 0.0:
				causes.append(_cause(false, "Stage 6  ·  Rocket", "The spacecraft had already spent %d m/s finishing the rocket's job." % roundi(made_up * 1000.0)))
			if float(stats.get("ship_dv", 0.0)) - boil_off - made_up >= ship_base + (0.0 if high_orbit else float(site.get("extra_dv", 0.0))):
				causes.append(_cause(false, funding_text, "The path was known only to within ±%s%%. With a path known exactly, the same spacecraft would have had enough." % _num(margin)))
		else:
			if link in ["relay"]:
				_say(phase, "Braking burn behind the Moon. The relay satellite carried the signal, and mission control watched it live.", "good")
			else:
				_say(phase, "Braking burn behind the Moon, out of contact with Earth. %d minutes of silence, then a voice: the burn was good." % rng.randi_range(28, 36), "good")
			if high_orbit:
				if latent.has("lander"):
					outcome = "orbit"
					phase["status"] = "problem"
					_say(phase, "The spacecraft is in its high orbit, and the lander is not there. Its refuelling flights fell behind and it never left Earth.", "bad")
					causes.append(_cause(false, "Stage 6  ·  Lander: %s" % _part_name(design, "lander"), "A lander sent separately needs many launches that must all work. One part of that chain failed, and there was nothing to land in."))
				else:
					_say(phase, "The spacecraft settled into a high, slow orbit and docked with the lander that was sent ahead.", "good")

	var surface_crew := int(stats.get("surface_crew", 0))
	if outcome == "landed":
		phase = _phase(phases, "landing", "Landing", "surface", 6.0 if high_orbit else 4.0)
		var risk := int(site.get("risk_value", 1))
		var site_term := 0.07 * (risk - 1)
		var nav_term := 0.30 * (1.0 - accuracy)
		var raw := 0.04 + site_term + nav_term
		var chance := clampf(raw - 0.05 * training - 0.03 * computer, 0.01, 0.6)
		var draw := rng.randf()
		var site_text := "Stage 4  ·  Landing site: %s (risk: %s)" % [site.get("name", ""), str(site.get("risk", "")).to_lower()]
		var manual: Dictionary = overrides.get("landing", {})
		if surface_crew > 0 and not (latent.has("lander") and not high_orbit):
			phase["manual"] = true
			phase["setup"] = {
				"risk": risk, "accuracy": accuracy, "training": training, "computer": computer,
				"lander": str(design.get("lander", "")), "seed": str([site.get("id", ""), snappedf(accuracy, 0.01), training, computer]).hash(),
			}
		if surface_crew <= 0:
			outcome = "orbit"
			phase["status"] = "problem"
			_say(phase, "Somebody has to stay with the ship in orbit. With this capsule and this lander there is nobody left to go down.", "bad")
			causes.append(_cause(false, "Stage 6  ·  Crew capsule: %s" % _part_name(design, "capsule"), "The capsule seats too few people for one to stay in orbit while others land."))
		elif latent.has("lander") and not high_orbit:
			outcome = "orbit"
			phase["status"] = "problem"
			_say(phase, "The descent engine lost pressure three kilometres above the surface.", "bad")
			_say(phase, "The crew fired the ascent engine and climbed back to orbit.", "good")
			causes.append(_cause(false, tests_text, "A flaw in the lander (%s) was never found on the ground. The landing was abandoned three kilometres up." % _part_name(design, "lander")))
		elif not manual.is_empty():
			var speed := float(manual.get("speed", 0.0))
			var fuel := float(manual.get("fuel", 0.0))
			var pilot_text := "Stage 10  ·  You flew the landing by hand"
			match str(manual.get("result", "abort")):
				"landed":
					_say(phase, "The commander took the controls for the last hundred metres.", "info")
					_say(phase, "Touchdown at %s m/s with %d seconds of fuel left. Engine off." % [_num(snappedf(speed, 0.1)), roundi(fuel)], "good")
					causes.append(_cause(true, pilot_text, "You set the lander down at %s m/s on clear ground, with %d seconds of fuel to spare." % [_num(snappedf(speed, 0.1)), roundi(fuel)]))
					if risk >= 3:
						causes.append(_cause(true, site_text, "The hardest site on the list, and the landing worked."))
				"hard":
					stay_factor *= 0.5
					phase["status"] = "problem"
					_say(phase, "The commander took the controls for the last hundred metres.", "info")
					_say(phase, "Touchdown at %s m/s. The lander is down, tilted, with one leg bent." % _num(snappedf(speed, 0.1)), "bad")
					_say(phase, "Flight rule: a damaged lander leaves early. The stay on the surface is cut by half.", "bad")
					causes.append(_cause(false, pilot_text, "The touchdown was too hard or on rough ground. The lander was damaged and the stay was cut by half."))
				_:
					outcome = "orbit"
					phase["status"] = "problem"
					_say(phase, "The commander took the controls for the last hundred metres.", "info")
					_say(phase, "The descent went outside safe limits. The computer called the abort and fired the ascent engine.", "bad")
					_say(phase, "The crew is back in orbit.", "bad")
					causes.append(_cause(false, pilot_text, "The descent went outside safe limits and the landing was abandoned."))
					if accuracy < 0.8:
						causes.append(_cause(false, funding_text, "The path was known only to within ±%s%%, so the lander arrived over rough ground and you had to search for a clear spot." % _num(margin)))
					if risk >= 2:
						causes.append(_cause(false, site_text, "This site leaves little clear ground to choose from."))
		elif draw < chance:
			outcome = "orbit"
			phase["status"] = "problem"
			if nav_term >= site_term and nav_term > 0.06:
				_say(phase, "The computer brought the lander down %d km from the planned point, over a field of boulders." % maxi(2, roundi((1.0 - accuracy) * 9.0)), "bad")
				_say(phase, "Fuel for hovering ran low before a clear spot came into view. Abort. The crew is back in orbit.", "bad")
				causes.append(_cause(false, funding_text, "The landing was aimed with a path known only to within ±%s%%. The lander arrived kilometres off target and ran out of time to find safe ground." % _num(margin)))
			elif site_term > 0.0:
				_say(phase, "The ground was rougher than the maps showed. No safe spot was within reach.", "bad")
				_say(phase, "Abort. The crew is back in orbit.", "bad")
				causes.append(_cause(false, site_text, "The site promised the most science and the hardest landing. The crew found no safe ground and came back up."))
			else:
				_say(phase, "A guidance alarm appeared in the last minutes of the descent, and nobody could clear it in time.", "bad")
				_say(phase, "Abort. The crew is back in orbit.", "bad")
			if training < 2:
				causes.append(_cause(false, "Stage 8  ·  Crew training: %s" % Operations.level_name("training").to_lower(), "A crew that has flown more failed landings in the simulator has more options in the last minute of a real one."))
		else:
			var miss := 0.2 + (1.0 - accuracy) * 8.0 * luck
			_say(phase, "Touchdown, %s km from the planned point. Engine off." % _num(snappedf(miss, 0.1)), "good")
			if draw < raw:
				if training >= computer and training > 0:
					_say(phase, "An alarm sounded during the descent. The crew and the controllers had seen it in the simulator and kept going.", "good")
					causes.append(_cause(true, "Stage 8  ·  Crew training: %s" % Operations.level_name("training").to_lower(), "An alarm during the descent could have ended the landing. The crew had met it in training and flew on."))
				elif computer > 0:
					_say(phase, "The main computer faltered during the descent. The backup took over without a pause.", "good")
					causes.append(_cause(true, "Stage 8  ·  Flight computer: %s" % Operations.level_name("computer").to_lower(), "The main computer faltered during the descent. The backup carried the landing."))
			if risk >= 3:
				causes.append(_cause(true, site_text, "The hardest site on the list, and the landing worked."))

	var planned := Campaign.science_value
	var science_rows: Array = []
	var returned := 0.0
	var sample_points := 0.0
	if outcome == "landed":
		phase = _phase(phases, "surface", "On the Moon", "surface", 6.2 if high_orbit else 4.2)
		var stay := float(stats.get("stay_days", 1.0)) * stay_factor
		var eva_hours := float(stats.get("eva_hours", 0.0))
		var walks := clampi(ceili(stay), 1, 6)
		var per_walk := eva_hours if stay >= 1.0 else minf(eva_hours, 4.0)
		var skill: float = [0.85, 1.0, 1.12][training]
		var hours := per_walk * walks * (surface_crew / 2.0) * skill
		if latent.has("suits"):
			hours *= 0.5
			phase["status"] = "problem"
			_say(phase, "One suit began to leak during the first moonwalk. Every walk after it was cut short.", "bad")
			causes.append(_cause(false, tests_text, "A flaw in the spacesuits (%s) was never found on the ground. The crew lost half of its time outside." % _part_name(design, "suits")))
		if eva_hours <= 0.0:
			phase["status"] = "problem"
			_say(phase, "The lander is on the Moon and the hatch stays shut: the crew has cabin suits only.", "bad")
			causes.append(_cause(false, "Stage 6  ·  Spacesuits: %s" % _part_name(design, "suits"), "Cabin suits keep a person alive inside. Nobody could step out onto the surface."))
			science_rows.append({"name": "View from the windows", "points": roundi(float(site.get("science", 0)) * 0.15), "note": "photographs only"})
			returned += float(site.get("science", 0)) * 0.15
		else:
			_say(phase, "%d moonwalk%s, about %d hours outside in all." % [walks, "" if walks == 1 else "s", roundi(hours)], "good")
			var left := hours
			var has_rover := false
			var link_factor: float = {"basic": 0.75, "tv": 0.95, "relay": 1.0, "laser": 1.1}.get(link, 0.75)
			var send := data_factor * link_factor * (0.88 if control == 0 else 1.0)
			var unpacked: Array[String] = []
			var pending: Array = []
			for item: Dictionary in build.get("kept", []):
				var need := 2.0 if item.get("id") == "samples" else (1.0 if item.get("id") == "rover" else 1.5)
				var done := clampf(left / need, 0.0, 1.0)
				left = maxf(left - need, 0.0)
				if done < 0.5:
					unpacked.append(_lower(str(item.get("name", ""))))
					continue
				if item.get("id") == "rover":
					has_rover = true
				pending.append([item, done])
			var site_points := float(site.get("science", 0)) * clampf(hours / 2.0, 0.0, 1.0) * (1.25 if has_rover else 1.0)
			science_rows.append({"name": "The site itself: %s" % site.get("name", ""), "points": roundi(site_points), "note": "explored by rover" if has_rover else "explored on foot"})
			returned += site_points
			for pair: Array in pending:
				var item: Dictionary = pair[0]
				var points := float(item.get("science", 0)) * float(pair[1])
				var note := "set up and working" if float(pair[1]) >= 1.0 else "only partly set up"
				if item.get("id") == "samples":
					sample_points = points
					note = "brought home"
				elif item.get("id") == "tv" and link == "basic":
					points = 0.0
					note = "no link fast enough for television"
				elif item.get("id") not in ["reflector", "rover"]:
					points *= send
					if send < 0.9:
						note = "working, part of the data never reached Earth"
				science_rows.append({"name": str(item.get("name", "")), "points": roundi(points), "note": note})
				returned += points
			if not unpacked.is_empty():
				_say(phase, "No time left for: %s." % ", ".join(unpacked), "bad")
				causes.append(_cause(false, "Stage 6  ·  Lander and suits: %s, %s" % [_part_name(design, "lander"), _part_name(design, "suits")],
						"About %d hours outside were not enough for the whole plan. Left in their boxes: %s." % [roundi(hours), ", ".join(unpacked)]))
			if link_factor < 0.9 and not pending.is_empty():
				causes.append(_cause(false, "Stage 6  ·  Communications: %s" % _part_name(design, "comms"), "The link home was too slow for everything the instruments recorded. Part of the data stayed on the Moon."))
			if control == 0 and not pending.is_empty():
				causes.append(_cause(false, "Stage 8  ·  Mission control: %s" % Operations.level_name("control").to_lower(), "With borrowed antennas, nobody was listening for part of every day. Some of the science data was never received."))
			if link == "laser" and send >= 1.0:
				causes.append(_cause(true, "Stage 6  ·  Communications: %s" % _part_name(design, "comms"), "The laser link sent home everything the instruments recorded."))
			_say(phase, "Science on the surface: %d of %d planned points so far." % [roundi(returned), planned], "info")
	elif outcome == "orbit":
		returned = float(site.get("science", 0)) * 0.2
		science_rows.append({"name": "Observations from lunar orbit", "points": roundi(returned), "note": "photographs and measurements, no landing"})
	elif outcome == "flyby":
		returned = float(site.get("science", 0)) * 0.1
		science_rows.append({"name": "Observations during the flyby", "points": roundi(returned), "note": "a few hours near the Moon"})

	if outcome in ["landed", "orbit", "flyby"]:
		if outcome == "flyby":
			mission_days = 6.5
		elif outcome == "orbit":
			mission_days = float(rule.get("transit_days", 8.0)) + (float(rule.get("nrho_extra_days", 6.0)) if high_orbit else 0.0)
		else:
			mission_days = float(rule.get("transit_days", 8.0)) + float(stats.get("stay_days", 1.0)) * stay_factor + (float(rule.get("nrho_extra_days", 6.0)) if high_orbit else 0.0)
		phase = _phase(phases, "return", "Coast home", "map", mission_days - 2.8)
		if outcome == "landed":
			_say(phase, "Lift-off from the Moon. The crew is together again in orbit.", "good")
		if outcome != "flyby":
			_say(phase, "The engine fired behind the Moon one last time. The spacecraft is on its way home.", "good")
		else:
			_say(phase, "The Moon's gravity bent the path back toward Earth. No burn was needed.", "info")
	elif outcome == "earth_orbit":
		mission_days = 2.0

	if outcome in ["landed", "orbit", "flyby", "earth_orbit"]:
		phase = _phase(phases, "entry", "Re-entry and splashdown", "sea", mission_days - 0.1)
		_say(phase, "The capsule met the air at %s km/s." % ("7.8" if outcome == "earth_orbit" else "11"), "info")
		if latent.has("capsule"):
			phase["status"] = "problem"
			_say(phase, "The heat shield wore away more than predicted. The cabin stayed cool. Engineers will want to know why.", "bad")
			causes.append(_cause(false, tests_text, "A weakness in the heat shield (%s) was not found on the ground. It held, with less to spare than anyone had planned." % _part_name(design, "capsule")))
		var spread: float = [1.3, 1.0, 0.8][control]
		var off := (1.0 - accuracy) * 300.0 * luck * spread + 3.0
		var hours_to_crew: float = [2.0 + off / 40.0, 1.0 + off / 80.0, 0.7 + off / 160.0][recovery]
		_say(phase, "Three parachutes. Splashdown %d km from the planned point." % roundi(off), "good" if off < 40.0 else "info")
		if hours_to_crew > 5.0:
			phase["status"] = "problem"
			_say(phase, "The recovery ship reached the capsule after %d hours. The crew is safe and exhausted.%s" % [roundi(hours_to_crew), " Some sample boxes had warmed up." if sample_points > 0.0 else ""], "bad")
			returned -= sample_points * 0.2
			causes.append(_cause(false, "Stage 8  ·  Recovery forces: %s" % Operations.level_name("recovery").to_lower(), "The capsule came down %d km off target and the crew waited %d hours to be picked up.%s" % [roundi(off), roundi(hours_to_crew), " Part of the samples was spoiled." if sample_points > 0.0 else ""]))
		else:
			_say(phase, "The crew is aboard the recovery ship %s after splashdown." % ("within the hour" if hours_to_crew <= 1.2 else "%s hours" % _num(snappedf(hours_to_crew, 0.5))), "good")

	if outcome in ["no_launch", "launch_abort", "crew_lost"]:
		mission_days = 0.0
	Campaign.budget_left -= scrub_cost
	Campaign.days = float(launch_day) + mission_days
	var science_returned := maxi(roundi(returned), 0)
	var on_time := launch_day <= Campaign.days_total()
	var within_budget := Campaign.budget_left >= 0.0
	if not on_time:
		causes.append(_cause(false, "Stage 6  ·  Build time and test programme", "The vehicle left %d days after the deadline." % (launch_day - Campaign.days_total())))
	var crew_home := outcome not in ["crew_lost"]
	var objectives := [
		{"text": "Land a crew on the Moon", "met": outcome == "landed"},
		{"text": "Bring the crew home safely", "met": crew_home},
		{"text": "Launch by %s" % Campaign.deadline_text().capitalize(), "met": on_time and outcome != "no_launch"},
		{"text": "Stay within the budget", "met": within_budget},
		{"text": "Return the planned science", "met": outcome == "landed" and science_returned >= roundi(planned * 0.7)},
	]
	var headline: String = {
		"landed": "Mission accomplished" if science_returned >= roundi(planned * 0.7) else "The crew landed, with less science than planned",
		"orbit": "The crew reached the Moon but did not land",
		"flyby": "The crew flew around the Moon and came home",
		"earth_orbit": "The mission ended in Earth orbit",
		"launch_abort": "The launch failed. The crew escaped",
		"crew_lost": "The launch failed and the crew was lost",
		"no_launch": "The rocket never left the pad",
	}[outcome]
	result = {
		"outcome": outcome, "headline": headline, "phases": phases, "causes": causes, "objectives": objectives,
		"science_planned": planned, "science_returned": science_returned, "science_rows": science_rows,
		"launch_day": launch_day, "mission_days": mission_days, "scrubs": scrubs, "scrub_days": scrub_days, "scrub_cost": scrub_cost,
		"budget_left": Campaign.budget_left, "on_time": on_time, "within_budget": within_budget,
		"crew": int(stats.get("crew", 0)), "surface_crew": surface_crew if outcome == "landed" else 0,
		"ship_have": ship_have, "ship_need": ship_need,
		"side_boosters": side, "stage_names": stage_names,
		"spaceport": str(port.get("id", "")), "weather_scrubs": weather_scrubs,
	}
	Campaign.clock_running = false
	Campaign.stage = 11


static func quick_start(to_stage: int) -> void:
	Campaign.reset()
	Campaign.fund_calculations(float(Campaign.science()["requested_pct"]))
	Campaign.finish_calculations(40, 50)
	Campaign.pass_review()
	var picks: Array = []
	for index: int in [0, 7, 8, 9]:
		picks.append(Campaign.instrument_options()[index])
	Campaign.set_science_plan(Campaign.sites()[5], picks)
	Campaign.pass_review()
	Campaign.days = 220.0
	Vehicle.hand_over({
		"stage1": "s1_solid", "stage2": "s2_core", "stage3": "s3_icps", "lander": "lander_hls", "service": "service_esm",
		"capsule": "capsule_four", "escape": "escape_las", "life": "life_regen", "suits": "suits_flex", "power": "power_solar",
		"comms": "comms_laser", "spaceport": "port_ksc", "ground": "ground_existing", "tests": "tests_allup",
	})
	if to_stage <= 7:
		return
	Campaign.pass_review()
	if to_stage <= 8:
		return
	var plan := {}
	for item: Dictionary in Operations.items():
		plan[str(item["id"])] = 1
	Operations.confirm(plan)
	if to_stage <= 9:
		return
	Campaign.pass_review()
	if to_stage <= 10:
		return
	fly()


static func objectives_met() -> int:
	var count := 0
	for objective: Dictionary in result.get("objectives", []):
		if objective["met"]:
			count += 1
	return count


static func _phase(phases: Array, id: String, title: String, view: String, day: float) -> Dictionary:
	var phase := {"id": id, "title": title, "view": view, "day": day, "status": "ok", "lines": []}
	phases.append(phase)
	return phase


static func _say(phase: Dictionary, text: String, kind := "info", view := "") -> void:
	(phase["lines"] as Array).append({"text": text, "kind": kind, "view": view})


static func _cause(good: bool, decision: String, effect: String) -> Dictionary:
	return {"good": good, "decision": decision, "effect": effect}


static func _part_name(design: Dictionary, slot_id: String) -> String:
	return _lower(str(Vehicle.chosen(design, slot_id).get("name", "—")))


static func _lower(text: String) -> String:
	if text.length() < 2 or text.substr(0, 2) == text.substr(0, 2).to_upper():
		return text
	return text.substr(0, 1).to_lower() + text.substr(1)


static func _worst_site_dv() -> float:
	var worst := 0.0
	for part: Dictionary in Vehicle.slot("spaceport").get("parts", []):
		if not bool(part.get("overland", false)):
			worst = maxf(worst, float(part.get("dv_penalty", 0.0)))
	return worst


static func _best_site_name() -> String:
	var best := {}
	for part: Dictionary in Vehicle.slot("spaceport").get("parts", []):
		if not bool(part.get("overland", false)) and float(part.get("spin", 0.0)) > float(best.get("spin", 0.0)):
			best = part
	return str(best.get("name", "the best site on the list"))


static func _deadline_words(launch_day: int) -> String:
	var spare := Campaign.days_total() - launch_day
	return "%d days before the deadline" % spare if spare >= 0 else "%d days after the deadline" % -spare


static func _num(value: float) -> String:
	return ("%.1f" % value).trim_suffix(".0")
