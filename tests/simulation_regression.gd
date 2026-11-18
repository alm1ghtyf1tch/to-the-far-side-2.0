extends SceneTree
## Records the original game once; subsequent runs compare actual simulation results.
## godot --headless --path . --script tests/simulation_regression.gd [-- --record]

const FIXTURE := "res://tests/fixtures/simulation_baseline.json"


func _initialize() -> void:
	var actual := _capture()
	if OS.get_cmdline_user_args().has("--record"):
		DirAccess.make_dir_recursive_absolute("res://tests/fixtures")
		var file := FileAccess.open(FIXTURE, FileAccess.WRITE)
		file.store_string(JSON.stringify(actual, "\t", true, true) + "\n")
		print("Recorded original simulation baseline: ", actual.keys())
		quit()
		return
	var file := FileAccess.open(FIXTURE, FileAccess.READ)
	if file == null:
		push_error("Missing original simulation baseline")
		quit(1)
		return
	var expected: Variant = JSON.parse_string(file.get_as_text())
	if not _equivalent(actual, expected, "simulation"):
		push_error("Simulation changed from the original baseline")
		quit(1)
		return
	print("PASS: original simulation, deterministic replay, overrides and site totals")
	quit()


func _equivalent(actual: Variant, expected: Variant, path: String) -> bool:
	if (actual is float or actual is int) and (expected is float or expected is int):
		if absf(float(actual) - float(expected)) <= 1.0e-9 * maxf(1.0, absf(float(expected))):
			return true
	elif actual is Dictionary and expected is Dictionary:
		if actual.size() == expected.size():
			for key: Variant in actual:
				if not expected.has(key) or not _equivalent(actual[key], expected[key], "%s.%s" % [path, key]):
					return false
			return true
	elif actual is Array and expected is Array:
		if actual.size() == expected.size():
			for index in actual.size():
				if not _equivalent(actual[index], expected[index], "%s[%d]" % [path, index]):
					return false
			return true
	elif actual == expected:
		return true
	push_error("Baseline mismatch at %s: %s != %s" % [path, str(actual), str(expected)])
	return false


func _capture() -> Dictionary:
	var output := {}
	Flight.quick_start(10)
	output["preflight"] = _state()
	Flight.fly()
	output["automatic"] = _state()
	Flight.fly()
	output["replayed"] = _state()
	Flight.fly({"staging": [-0.8, 1.0], "landing": {"result": "abort", "speed": 8.0, "fuel": 2.0}})
	output["manual_overrides"] = _state()
	# A real, complete but poorly matched catalog configuration.
	Flight.quick_start(7)
	Vehicle.design["stage1"] = "s1_four"
	Vehicle.stats = Vehicle.evaluate(Vehicle.design)
	Campaign.pass_review()
	var plan := {}
	for item: Dictionary in Operations.items():
		plan[str(item["id"])] = 0
	Operations.confirm(plan)
	Campaign.pass_review()
	Flight.fly()
	output["poor_configuration"] = _state()
	var sites := []
	for site: Dictionary in Campaign.sites():
		sites.append({"id": site["id"], "totals": Campaign.plan_totals(site, Campaign.instrument_options())})
	output["site_totals"] = sites
	output["staging_gains"] = [Flight.staging_gain(-1.5), Flight.staging_gain(0.0), Flight.staging_gain(1.5)]
	return output


func _state() -> Dictionary:
	return {
		"stage": Campaign.stage, "days": Campaign.days, "budget": Campaign.budget_left,
		"margin": Campaign.margin, "accuracy": Campaign.accuracy, "round": Campaign.calc_round,
		"confidence": Campaign.board_confidence, "vehicle": Vehicle.stats.duplicate(true),
		"build": Flight.build.duplicate(true), "flight": Flight.result.duplicate(true),
	}
