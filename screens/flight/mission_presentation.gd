class_name MissionPresentation
extends RefCounted
## Read-only translation of existing phase dictionaries and revealed log entries.
## It never calls Flight.fly(), advances a phase, or writes campaign state.

var stage: SpaceflightStage
var current_phase := ""
var seen := {}
var event_count := 0
var _instant := false


func begin(phase: Dictionary, instant: bool) -> void:
	current_phase = str(phase["id"])
	_instant = instant
	var craft := stage.spacecraft
	craft.burn([], false, instant)
	match current_phase:
		"countdown":
			stage.set_context("earth")
			craft.reset_stack()
		"ascent":
			stage.set_context("earth")
			craft.show_configuration("launch", instant)
		"orbit", "tli":
			stage.set_context("earth")
			craft.show_configuration("upper", instant)
		"coast", "return":
			stage.set_context("deep")
			craft.show_configuration("ship", instant)
		"loi":
			stage.set_context("moon")
			craft.show_configuration("ship", instant)
			var first := str((phase["lines"] as Array)[0]["text"]) if not (phase["lines"] as Array).is_empty() else ""
			if first.begins_with("Braking burn") or first.begins_with("The main engine shut down"):
				craft.burn([craft.ship], true, instant)
		"landing":
			stage.set_context("moon")
			craft.show_configuration("lander", instant)
		"surface":
			stage.set_context("surface")
			craft.show_configuration("surface", instant)
		"entry":
			stage.set_context("earth")
			craft.show_configuration("capsule", instant)


func receive(phase: Dictionary, line: Dictionary, index: int, instant: bool) -> bool:
	var key := "%s:%d:%s" % [phase["id"], index, line["text"]]
	if seen.has(key):
		return false
	seen[key] = true
	event_count += 1
	_instant = instant
	var text := str(line["text"])
	var bad: bool = line["kind"] == "bad"
	var craft := stage.spacecraft
	match str(phase["id"]):
		"countdown":
			if text.begins_with("Ignition."):
				craft.launch_burn(0, true, instant)
		"ascent":
			if bad and str(phase.get("fail", "")) in ["stage1", "stage2"]:
				craft.mark_fault(str(phase["fail"]), instant)
			if text.begins_with("The escape tower fired") or text.begins_with("The capsule's own abort engines"):
				craft.show_configuration("capsule", instant)
		"tli":
			if text.begins_with("The third stage restarted"):
				craft.burn([craft.parts.get("stage3")], true, instant)
			elif text.contains("did not restart"):
				craft.mark_fault("restart", instant)
			elif text.contains("spacecraft lit its own engine"):
				craft.show_configuration("ship", instant)
				craft.burn([craft.ship], true, instant)
			elif bad:
				craft.burn([], false, instant)
		"coast":
			if text.contains("course correction"):
				craft.pulse_thrusters(instant)
			if text.contains("power system failed") or text.contains("needs more power"):
				craft.power_reduced()
			if text.contains("antenna stopped"):
				craft.communication_fault()
		"loi":
			if text.begins_with("The main engine shut down"):
				craft.mark_fault("lunar_burn", instant)
			elif bad:
				# A fuel-margin NO-GO or absent predeployed lander is not an engine fault.
				craft.burn([], false, instant)
		"landing":
			if text.contains("Touchdown"):
				stage.set_context("surface")
				craft.show_configuration("surface", instant)
				craft.burn([], false, instant)
			elif text.contains("Abort") or text.contains("abort") or text.contains("back in orbit") or text.contains("climbed back"):
				stage.set_context("moon")
				craft.show_configuration("ship", instant)
				craft.burn([], false, instant)
			elif text.contains("descent engine lost"):
				craft.mark_fault("descent", instant)
		"return":
			if text.begins_with("The engine fired"):
				craft.burn([craft.ship], true, instant)
		"entry":
			if text.begins_with("The capsule met the air"):
				craft.reentry_heat()
			elif text.begins_with("Three parachutes"):
				craft.parachutes(instant)
			elif text.contains("recovery ship"):
				stage.set_context("recovery")
				craft.splashdown(instant)
	# The existing abort path has no separate entry phase; its sea hint is authoritative.
	if line.get("view", "") == "sea":
		stage.set_context("recovery")
		craft.parachutes(instant)
	return true


func complete_phase() -> void:
	stage.spacecraft.burn([], false, _instant)


func finish(result: Dictionary) -> void:
	var craft := stage.spacecraft
	craft.settle()
	craft.burn([], false, true)
	match str(result.get("outcome", "")):
		"no_launch":
			stage.set_context("earth")
			craft.show_configuration("launch", true)
		"crew_lost":
			craft.mark_fault("stage1", true)
		_:
			stage.set_context("recovery")
			craft.splashdown(true)
