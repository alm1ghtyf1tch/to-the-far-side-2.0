extends SceneTree

func _initialize() -> void:
	create_timer(25).timeout.connect(func() -> void: quit(1))
	RogueRun.save_path = "res://.godot/rogue-save-test.json"
	assert(RogueRun.start("Save test", "science", "durable-offers"))
	assert(RogueRun.select_contract(0))
	var offers := RogueDraft.offers(RogueRun.state, "stage3").duplicate()
	assert(RogueRun.save() and RogueRun.save())
	var malformed := FileAccess.open(RogueRun.save_path, FileAccess.WRITE)
	malformed.store_string("{broken")
	malformed.close()
	var backup := RogueSave.read(RogueRun.save_path)
	assert(not backup.is_empty() and RogueSave.last_error.contains("backup"))
	assert(backup["offers"]["stage3"] == offers)
	var newer := RogueRun.state.duplicate(true)
	newer["schema"] = 999
	assert(not RogueSave.valid(newer))
	var missing := RogueRun.state.duplicate(true)
	missing.erase("operations")
	assert(not RogueSave.valid(missing))
	var negative := RogueRun.state.duplicate(true)
	negative["materials"]["structures"] = -1
	assert(not RogueSave.valid(negative))
	var unknown := RogueRun.state.duplicate(true)
	unknown["vehicle"]["stage1"] = "unknown_part"
	assert(not RogueSave.valid(unknown))
	assert(RogueRun.save() and RogueRun.suspend() and RogueRun.resume())
	assert(RogueDraft.offers(RogueRun.state, "stage3") == offers)
	# A failed save must not replace the active agency when starting/resuming.
	var guarded := RogueRun.state.duplicate(true)
	RogueRun.state["actions"] = 99
	assert(not RogueRun.start("Replacement", "science", "replacement"))
	assert(RogueRun.state["seed"] == guarded["seed"])
	assert(not RogueRun.resume() and RogueRun.state["actions"] == 99)
	RogueRun.state = guarded
	RogueRun.suspend()
	print("PASS: atomic run saves, last-good recovery, malformed/newer/missing data rejection, failed-save replacement guards, invalid resources/parts and unchanged saved offers")
	quit()
