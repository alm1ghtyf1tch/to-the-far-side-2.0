extends SceneTree
## External probe for an exported Windows executable; this file is not packaged.

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(25).timeout.connect(func() -> void: quit(1))
	DirAccess.make_dir_recursive_absolute("user://qa")
	RogueRun.save_path = "user://qa/rogue_export_probe.json"
	assert(RogueRun.start("Packaged agency", "science", "horizon-11"))
	assert(RogueRun.select_contract(0))
	var event: Dictionary = RogueRun.state["pending_event"]
	assert(RogueRun.choose_event(event["choices"].size() - 1))
	assert(RogueRun.confirm_science(str(RogueRun.state["site"]), RogueResearch.required_ids(RogueRun.state)))
	var baseline := RogueCatalog.baseline(RogueRun.state["contract"])
	for slot: String in baseline:
		if int(RogueRun.state["inventory"].get(baseline[slot], 0)) == 0:
			assert(RogueRun.purchase(slot, baseline[slot]))
		if RogueRun.state["vehicle"].get(slot) != baseline[slot]:
			assert(RogueRun.install(slot, baseline[slot]))
	assert(RogueRun.launch())
	var control: Control = load(SceneRouter.ROGUE_CONTROL).instantiate()
	root.add_child(control)
	await process_frame
	await process_frame
	assert(not Flight.result.is_empty())
	assert(RogueRun.suspend())
	print("PASS: exported pack loads bundled Rogue/vehicle/science JSON, compiled models, paid procurement, original flight, UI scene and independent save on matching Godot runtime")
	quit()
