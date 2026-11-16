extends Control

const MUTED := "#323a45"
const BLUE := "#0b3d91"
const RED := "#dd361c"

@onready var _report: RichTextLabel = %Report
@onready var _ack_button: Button = %AckButton
@onready var _status_label: Label = %StatusLabel
@onready var _date_label: Label = %DateLabel
@onready var _document_label: Label = %Document

var _menu_button: Button


var _number := 0


func _ready() -> void:
	if Flight.result.is_empty():
		Flight.quick_start(11)
	Campaign.clock_running = false
	_date_label.text = Campaign.date_text()
	_document_label.text = "MR-%d-001  Mission Report.pdf" % Campaign.year()
	_status_label.text = "%d of 5 objectives met  ·  For: Program Director" % Flight.objectives_met()
	_report.text = _build()
	_menu_button = _ack_button.duplicate() as Button
	_menu_button.text = "Main menu"
	_ack_button.add_sibling(_menu_button)
	_ack_button.get_parent().move_child(_menu_button, _ack_button.get_index())
	_menu_button.pressed.connect(_on_menu_pressed)
	_ack_button.text = "Fly a new mission"
	_ack_button.pressed.connect(_on_again_pressed)
	_ack_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		SceneRouter.go_to(SceneRouter.HQ)


func _on_again_pressed() -> void:
	_lock()
	Campaign.reset()
	SceneRouter.go_to(SceneRouter.HQ, 0.6)


func _on_menu_pressed() -> void:
	_lock()
	SceneRouter.go_to(SceneRouter.MAIN_MENU, 0.6)


func _lock() -> void:
	_ack_button.disabled = true
	_menu_button.disabled = true


func _build() -> String:
	_number = 0
	var result := Flight.result
	var build := Flight.build
	var stats := Vehicle.stats
	var port := Vehicle.launch_site()
	var outcome := str(result.get("outcome", ""))
	var launch_day := int(result.get("launch_day", 0))
	var spare := Campaign.days_total() - launch_day
	var flew := outcome not in ["no_launch"]
	var landed := outcome == "landed"
	var left := float(result.get("budget_left", 0.0))
	var lines: Array[String] = []
	lines.append("[font_size=40][b]Mission Report[/b][/font_size]\n[font_size=24][color=%s][b]%s[/b][/color][/font_size]\n[font_size=17][color=%s]Ref. MR-%d-001  ·  %s  ·  Program Office[/color][/font_size]\n" % [
		BLUE if Flight.objectives_met() >= 4 else RED, result.get("headline", ""), MUTED, Campaign.year(), Campaign.date_text().capitalize()])
	lines.append(_table([
		["Launch", "%s  ·  %s" % [Campaign.date_text(launch_day).capitalize(), "%d days before the deadline" % spare if spare >= 0 else "%d days after the deadline" % -spare] if flew else "Did not happen"],
		["Launch site", "%s, %s%s" % [port.get("name", "—"), port.get("state", "—"), "  ·  moved from %s" % Vehicle.chosen(Vehicle.design, "spaceport").get("name", "—") if build.get("moved", false) else ""]],
		["Flight", "%s days" % _num(float(result.get("mission_days", 0.0))) if float(result.get("mission_days", 0.0)) > 0.0 else "Ended at launch"],
		["Crew", "%d aboard" % int(result.get("crew", 0))],
		["Landing site", "%s (%s site)" % [Campaign.site.get("name", "—"), Campaign.site.get("mission", "—")]],
		["Objectives met", "[b]%d of 5[/b]" % Flight.objectives_met()],
	]))

	lines.append("\nThis report closes the mission. It sets what was planned beside what happened, shows where every part of the budget went, and then does the most useful thing a report can do: it follows each result back to the decision that caused it. Some of those decisions were made years before launch, in a phase where their effect could not yet be seen.")

	lines.append(_numbered("Objectives"))
	lines.append("Five things were asked of this mission. The Government set the first two when it asked for a landing and a safe return. The deadline and the budget came with the request. The fifth, the science, is what makes a landing worth more than a visit.\n")
	var goals: Array[String] = []
	for goal: Dictionary in result.get("objectives", []):
		goals.append("[color=%s][b]%s[/b][/color]   %s" % [BLUE if goal["met"] else RED, "MET" if goal["met"] else "NOT MET", goal["text"]])
	lines.append("\n".join(goals))

	lines.append(_numbered("Plan and actual"))
	lines.append("The left column is what the programme intended on the day the design was approved. The right column is what the flight delivered. Where the two differ, the section “What decided the outcome” explains why.\n")
	var planned_stay := float(stats.get("stay_days", 0.0))
	lines.append(_table3([
		["", "[b]Plan[/b]", "[b]Actual[/b]"],
		["Launch date", "By %s" % Campaign.deadline_text().capitalize(), Campaign.date_text(launch_day).capitalize() if flew else "No launch"],
		["Launch attempts", "1", "%d" % (int(result.get("scrubs", 0)) + 1)],
		["Budget", "100%%  ·  $%s billion" % _num(Campaign.billions(100.0)), "%s%% spent  ·  %s%% %s" % [_num(100.0 - left), _num(absf(left)), "left" if left >= 0.0 else "over budget"]],
		["Trajectory uncertainty", "As small as the budget allows", "±%s%% with %s%% spent on Flight Dynamics" % [_num(Campaign.margin), _num(Campaign.calc_funding)]],
		["Crew on the surface", "%d" % int(stats.get("surface_crew", 0)), "%d" % int(result.get("surface_crew", 0))],
		["Time on the surface", "%s days" % _num(planned_stay), "%s days" % _num(maxf(float(result.get("mission_days", 0.0)) - float(Vehicle.rules().get("transit_days", 8.0)) - (float(Vehicle.rules().get("nrho_extra_days", 6.0)) if stats.get("high_orbit", false) else 0.0), 0.0)) if landed else "No landing"],
		["Science", "%d points" % int(result.get("science_planned", 0)), "%d points" % int(result.get("science_returned", 0))],
	]))

	lines.append("\n[b]Launch attempts[/b] counts every time the rocket was fuelled and the countdown started. A cancelled attempt costs days and money. [b]Trajectory uncertainty[/b] is how exactly the path was known: it set how much spare propellant the vehicle had to carry and how close to the target the lander arrived. [b]Science[/b] is counted in points: the value of the site plus every instrument that was set up and whose data reached Earth.")

	lines.append(_numbered("Where the money went"))
	lines.append("The whole mission was paid from one budget of $%s billion, counted as 100%%. Nothing was added along the way, so every line below was paid for by spending less on another.\n" % _num(Campaign.billions(100.0)))
	var surprises := float(build.get("cost", 0.0)) + float(build.get("idle_cost", 0.0))
	var money := [
		["Agency staff and management", Campaign.salaries_pct()],
		["Flight Dynamics", Campaign.calc_funding],
		["Science instruments", Campaign.payload_cost],
		["Vehicle: hardware, propellant and tests", float(stats.get("parts_cost", 0.0))],
		["Vehicle: people and factories during the build", float(stats.get("cost", 0.0)) - float(stats.get("parts_cost", 0.0))],
		["Flight operations", Operations.cost(Operations.choices)],
		["Problems during the build", surprises],
		["Cancelled launch attempts", float(result.get("scrub_cost", 0.0))],
	]
	var rows: Array = []
	for row: Array in money:
		if float(row[1]) > 0.004:
			rows.append([row[0], "%s%%" % _num2(float(row[1])), "$%s billion" % _num2(Campaign.billions(float(row[1])))])
	rows.append(["[b]%s[/b]" % ("Left in the reserve" if left >= 0.0 else "Over budget"), "[b]%s%%[/b]" % _num2(absf(left)), "[b]$%s billion[/b]" % _num2(Campaign.billions(absf(left)))])
	lines.append(_table3(rows))

	lines.append("\nThe vehicle takes the largest share in every Moon programme, and a good part of that is not hardware. It is the engineers, factories and test stands that are paid for every day the build lasts. That is why a part that takes longer to build, or a longer test programme, raises the cost even when its own price is small. The reserve is what stood between the programme and going over budget.")

	var science: Array = result.get("science_rows", [])
	if not science.is_empty():
		lines.append(_numbered("Science returned"))
		var science_rows: Array = []
		for row: Dictionary in science:
			science_rows.append([str(row["name"]), "%d points" % int(row["points"]), "[color=%s]%s[/color]" % [MUTED, row["note"]]])
		for item: Dictionary in build.get("left_behind", []):
			science_rows.append([str(item["name"]), "0 points", "[color=%s]stayed on Earth[/color]" % MUTED])
		lines.append(_table3(science_rows))
		lines.append("\nAn instrument earns its points only if four things all work: it fits in the lander, it has power, the crew has time outside to set it up, and its data gets home. Samples and the laser reflector need no radio link. Everything else depends on the antenna you chose and on how many hours a day somebody on Earth was listening.")

	lines.append(_numbered("The flight in numbers"))
	lines.append(_table(_flight_numbers()))

	lines.append(_numbered("What decided the outcome"))
	lines.append("Nothing in this flight happened by itself. Each entry below starts with a decision, names the phase in which it was made, and ends with what it led to. Read them in order: the earliest decisions come first, and several of them only showed their effect on launch day or at the Moon.\n")
	var bad: Array[String] = []
	var good: Array[String] = []
	for cause: Dictionary in result.get("causes", []):
		var text := "[color=%s]%s[/color]\n%s" % [MUTED, cause["decision"], cause["effect"]]
		if cause["good"]:
			good.append(text)
		else:
			bad.append(text)
	if not bad.is_empty():
		lines.append("[color=%s][b]WHAT COST THE MISSION[/b][/color]\n" % RED)
		lines.append("\n\n".join(bad))
	if not good.is_empty():
		lines.append("%s[color=%s][b]WHAT WORKED[/b][/color]\n" % ["\n" if not bad.is_empty() else "", BLUE])
		lines.append("\n\n".join(good))
	if bad.is_empty() and good.is_empty():
		lines.append("The flight went as planned from the first day to the last.")

	lines.append(_numbered("The mission as four segments"))
	lines.append(_segments())

	var twin := _real_mission()
	if not twin.is_empty():
		lines.append(_numbered("A real mission like yours"))
		lines.append("NASA's learning game “Build It Yourself: Satellite!” ends by showing the player the real mission closest to the one they designed. This report does the same.\n")
		lines.append(_table([
			["Closest real flight", "[b]%s[/b]  ·  %s" % [twin["name"], twin["when"]]],
			["What it did", twin["what"]],
			["Your flight", twin["yours"]],
		]))
		if not str(twin.get("hardware", "")).is_empty():
			lines.append("\n%s" % twin["hardware"])

	lines.append(_numbered("Words used in this report"))
	lines.append(_table([
		["Speed change (Δv)", "How much an engine can change the speed of what it pushes. It is the real currency of spaceflight: every manoeuvre has a price in km/s, and the tanks hold only so much."],
		["Orbit tilt", "The angle between an orbit and the equator. A launch site cannot reach a tilt smaller than its own latitude. The steeper the tilt, the less of the Earth's spin the rocket keeps, and the more speed it has to make itself."],
		["Reserve, or margin", "Extra kept on purpose: spare propellant for a path that is not known exactly, spare money for problems not yet found, spare days before a deadline."],
		["Flight rule", "A decision made on the ground, long before launch, about what to do when a number does not add up. Rules cut a mission short before they put a crew at risk."],
		["Abort", "Giving up the goal to keep the crew safe: an escape tower at launch, a return from Earth orbit, a climb back to lunar orbit instead of a landing."],
		["Free return", "A path that swings behind the Moon and falls back to Earth with no engine burn at all. A ship that cannot brake at the Moon still comes home."],
		["Hidden flaw", "A defect nobody knows about. Tests exist to find such flaws on the ground. The ones they miss appear in flight."],
	]))

	lines.append(_numbered("After the flight"))
	var met := Flight.objectives_met()
	var verdict := "The Government has asked the agency to prepare the next mission."
	if outcome == "crew_lost":
		verdict = "The programme is stopped. An accident board will work for months before anyone flies again."
	elif met <= 2:
		verdict = "The Government has opened a review of the programme before it pays for another flight."
	elif met <= 4:
		verdict = "The Board calls the mission a partial success and asks for the lessons to be built into the next one."
	lines.append("%s\n\nEvery space agency writes a report like this after every flight. It is the most useful document of a programme: the next mission starts from it. Fly again and change one decision to see what it changes." % verdict)
	return "\n".join(lines)


func _flight_numbers() -> Array:
	var result := Flight.result
	var stats := Vehicle.stats
	var outcome := str(result.get("outcome", ""))
	var path := {}
	var file := FileAccess.open("res://data/trajectory.json", FileAccess.READ)
	if file != null:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			path = parsed
	var stage_dv: Array = stats.get("stage_dv", [0.0, 0.0, 0.0])
	var port := Vehicle.launch_site()
	var rows: Array = [
		["Launch site", "%s, at %s° north. The Earth's spin gave the rocket %d m/s there. At the equator it would be 465 m/s" % [port.get("name", "—"), _num(float(port.get("lat", 0.0))), int(port.get("spin", 0))]],
		["Mass at lift-off", "%s tonnes, of which %s tonnes were propellant" % [_num(roundf(float(stats.get("liftoff_mass", 0.0)))), _num(roundf(float(stats.get("propellant", 0.0))))]],
		["Thrust against weight", "%.2f at lift-off. Below 1.00 a rocket cannot leave the ground" % float(stats.get("thrust_to_weight", 0.0))],
		["Speed from each stage", "%.2f + %.2f + %.2f km/s. The first stage burned for about %d seconds" % [float(stage_dv[0]), float(stage_dv[1]), float(stage_dv[2]), roundi(float(stats.get("stage1_burn", 0.0)))]],
	]
	if outcome in ["landed", "orbit", "flyby", "earth_orbit"]:
		rows.append(["Parking orbit", "%d km above the Earth at %s km/s, one lap in about 88 minutes" % [roundi(float(path.get("parking_altitude", 185.0))), _num2(float(path.get("parking_speed", 7.79)))]])
	if outcome in ["landed", "orbit", "flyby"]:
		rows.append(["Leaving for the Moon", "The burn raised the speed to %s km/s. By the time the Moon's pull took over, Earth's gravity had slowed the ship to about 1 km/s" % _num2(float(path.get("tli_speed", 10.95)))])
		rows.append(["Coast to the Moon", "%s hours with the engine off, across %s km" % [_num(roundf(float(path.get("out_hours", 69.0)))), "384,400"]])
	if outcome in ["landed", "orbit"] and not bool(stats.get("high_orbit", false)):
		rows.append(["Braking at the Moon", "From %s to %s km/s behind the far side, into an orbit %d km above the surface" % [_num2(float(path.get("arrival_speed", 2.55))), _num2(float(path.get("lunar_orbit_speed", 1.63))), roundi(float(path.get("lunar_orbit_altitude", 110.0)))]])
	if outcome in ["landed", "orbit"] and bool(stats.get("high_orbit", false)):
		rows.append(["Orbit at the Moon", "A long, stretched orbit that passes 3,000 km over one pole and swings 70,000 km out over the other, one lap in about six and a half days"])
	if outcome in ["landed", "orbit", "flyby"]:
		rows.append(["Coming home", "The capsule met the air at %s km/s, about %s km/h" % [_num2(float(path.get("entry_speed", 11.0))), "40,000"]])
	rows.append(["Crew time in space", "%s days" % _num(float(result.get("mission_days", 0.0))) if float(result.get("mission_days", 0.0)) > 0.0 else "None"])
	if outcome in ["landed", "orbit", "flyby"]:
		rows.append(["Checked against open software", "The path on the flight map comes from the equations of gravity for the Earth and the Moon. Run on a lunar transfer computed in NASA's GMAT and published in NASA's Mission Viz, the same equations end four days of coasting within 2,700 km of GMAT's answer, 0.7% of the way to the Moon. GMAT also counts the pull of the Sun. With it added, the difference is 3 km"])
	return rows


func _segments() -> String:
	var result := Flight.result
	var design := Vehicle.design
	var outcome := str(result.get("outcome", ""))
	var helped := {"launch": 0, "space": 0, "ground": 0, "user": 0, "": 0}
	var hurt := helped.duplicate()
	for cause: Dictionary in result.get("causes", []):
		var key := _segment_of(str(cause["decision"]))
		if cause["good"]:
			helped[key] += 1
		else:
			hurt[key] += 1
	var launch: String = {
		"no_launch": "Did not fly.",
		"crew_lost": "Failed during the climb to orbit.",
		"launch_abort": "Failed during the climb to orbit.",
		"earth_orbit": "Reached Earth orbit. Could not send the ship on to the Moon.",
	}.get(outcome, "Put the ship on its way to the Moon on launch attempt %d." % (int(result.get("scrubs", 0)) + 1))
	var space: String = {
		"landed": "Took the crew to the surface and brought it home.",
		"orbit": "Reached lunar orbit and came home. No landing.",
		"flyby": "Rounded the Moon without stopping and came home.",
		"earth_orbit": "Never left Earth orbit. The capsule came home.",
		"launch_abort": "The capsule was pulled clear of the rocket. The crew survived.",
		"crew_lost": "Lost with its crew.",
	}.get(outcome, "Did not fly.")
	var rows: Array = [
		["", "[b]In this mission[/b]", "[b]How it did[/b]"],
		["[b]Launch segment[/b]", "Rocket: %s; %s; %s. Site: %s. Launch team: %s." % [
			Flight._part_name(design, "stage1"), Flight._part_name(design, "stage2"), Flight._part_name(design, "stage3"),
			Vehicle.launch_site().get("name", "Launch site"), Operations.level_name("launch").to_lower()],
			launch + _tally(helped["launch"], hurt["launch"])],
		["[b]Space segment[/b]", "%s; %s; %s. Power: %s. Radio: %s." % [
			Vehicle.chosen(design, "capsule").get("name", "Capsule"), Flight._part_name(design, "service"), Flight._part_name(design, "lander"),
			Flight._part_name(design, "power"), Flight._part_name(design, "comms")],
			space + _tally(helped["space"], hurt["space"])],
		["[b]Ground segment[/b]", "Flight Dynamics, funded at %s%%. Mission control: %s. Recovery forces: %s. Crew training: %s." % [
			_num(Campaign.calc_funding), Operations.level_name("control").to_lower(), Operations.level_name("recovery").to_lower(), Operations.level_name("training").to_lower()],
			"Knew the path to within ±%s%%." % _num(Campaign.margin) + _tally(helped["ground"], hurt["ground"])],
		["[b]User segment[/b]", "The scientists waiting for results from %s: %d instrument%s planned." % [
			Campaign.site.get("name", "the Moon"), Campaign.instruments.size(), "" if Campaign.instruments.size() == 1 else "s"],
			"Received %d of %d science points." % [int(result.get("science_returned", 0)), int(result.get("science_planned", 0))] + _tally(helped["user"], hurt["user"])],
	]
	var text := "NASA describes every space mission as four segments that have to work together. A mission fails if any one of them does. The same flight, sorted that way:\n\n" + _table3(rows)
	text += "\n\nThe [b]launch segment[/b] is the rocket and everything needed to get the spacecraft into space. The [b]space segment[/b] is the spacecraft itself, with its lander and instruments. The [b]ground segment[/b] is the stations and control centres that talk to the spacecraft, receive its data and run the mission. The [b]user segment[/b] is the people the mission works for: the scientists and the public who use what it brings back."
	var shared: int = int(helped[""]) + int(hurt[""])
	if shared > 0:
		text += " %s in the section above, about testing, the reserve and the schedule, belong%s to the programme as a whole." % ["One more entry" if shared == 1 else "%d more entries" % shared, "s" if shared == 1 else ""]
	return text


func _segment_of(decision: String) -> String:
	var subject := decision.get_slice("·", 1).strip_edges()
	for start: String in ["First stage", "Second stage", "Third stage", "Rocket", "Launch site", "Launch pad", "Launch team", "You dropped the stages"]:
		if subject.begins_with(start):
			return "launch"
	for start: String in ["Mission control", "Recovery forces", "Flight Dynamics", "Crew training"]:
		if subject.begins_with(start):
			return "ground"
	for start: String in ["Test programme", "Reserve kept", "Build time"]:
		if subject.begins_with(start):
			return ""
	return "user" if subject.begins_with("Landing site") else "space"


func _tally(helped: int, hurt: int) -> String:
	if helped + hurt == 0:
		return ""
	var parts: Array[String] = []
	if helped > 0:
		parts.append("%d decision%s helped" % [helped, "" if helped == 1 else "s"])
	if hurt > 0:
		parts.append("%d hurt" % hurt if helped > 0 else "%d decision%s hurt" % [hurt, "" if hurt == 1 else "s"])
	return "\n[color=%s]%s.[/color]" % [MUTED, ", ".join(parts)]


func _real_mission() -> Dictionary:
	var result := Flight.result
	var stats := Vehicle.stats
	var design := Vehicle.design
	var crew := int(result.get("crew", 0))
	var days := float(result.get("mission_days", 0.0))
	var surface := maxf(days - float(Vehicle.rules().get("transit_days", 8.0)) - (float(Vehicle.rules().get("nrho_extra_days", 6.0)) if stats.get("high_orbit", false) else 0.0), 0.0)
	var twin := {}
	match str(result.get("outcome", "")):
		"landed":
			var yours := "%d of %d crew on the surface for %s days. %d of %d science points returned." % [int(result.get("surface_crew", 0)), crew, _num(surface), int(result.get("science_returned", 0)), int(result.get("science_planned", 0))]
			if surface >= 2.0:
				twin = {"name": "Apollo 15, 16 and 17", "when": "1971–1972", "yours": yours,
					"what": "On each of these flights two of the three crew spent about three days on the surface, drove a rover and went outside three times. The last of them brought back about 110 kg of rock and soil."}
			else:
				twin = {"name": "Apollo 11", "when": "July 1969", "yours": yours,
					"what": "Two of the three crew spent 21 and a half hours on the surface, two and a half of them outside. They set up a few experiments and brought back about 22 kg of rock and soil."}
		"orbit":
			twin = {"name": "Apollo 10", "when": "May 1969", "yours": "%d crew, %s days, lunar orbit reached, no landing." % [crew, _num(days)],
				"what": "A full rehearsal of the landing. Two of the crew flew the lander down to about 15 km above the surface, then climbed back to the main ship. The first landing followed two months later."}
		"flyby":
			twin = {"name": "Artemis II", "when": "April 2026", "yours": "%d crew, %s days, around the Moon and home without stopping." % [crew, _num(days)],
				"what": "Four people flew around the far side of the Moon without entering orbit and came home after about ten days. At 406,771 km they were farther from Earth than any crew before them."}
		"earth_orbit":
			twin = {"name": "Apollo 7", "when": "October 1968", "yours": "%d crew, %s days in Earth orbit." % [crew, _num(days)],
				"what": "The first crew to fly the Apollo spacecraft spent almost eleven days in Earth orbit testing it. Two months later the next crew went to the Moon."}
		"launch_abort":
			twin = {"name": "Pad Abort-1", "when": "White Sands, May 2010", "yours": "The escape system pulled %d people away from a failing rocket." % crew,
				"what": "No NASA crew has had to ride an escape system off a rocket. The systems are fired in tests without people: in this one an escape rocket pulled an empty Orion capsule off its pad and set it down 135 seconds later."}
		_:
			return {}
	match str(design.get("stage1", "")):
		"s1_five":
			twin["hardware"] = "[b]Your rocket.[/b] A first stage with five kerosene engines is how the Saturn V was built. It launched every Apollo crew that went to the Moon."
		"s1_solid":
			if str(design.get("stage2", "")) == "s2_core":
				twin["hardware"] = "[b]Your rocket.[/b] Two solid boosters beside a hydrogen core stage is how the Space Launch System is built. It launched Artemis I in 2022 and Artemis II in 2026."
		"s1_thirty":
			twin["hardware"] = "[b]Your rocket.[/b] A first stage with thirty kerosene engines is how the Soviet N1 Moon rocket was built. It was launched four times between 1969 and 1972 and never reached orbit."
	return twin


func _numbered(title: String) -> String:
	_number += 1
	return _section(str(_number), title)


func _section(number: String, title: String) -> String:
	return "\n[font_size=22][color=%s][b]%s.  %s[/b][/color][/font_size]" % [BLUE, number, title.to_upper()]


func _table(rows: Array) -> String:
	var text := "[table=2]"
	for row: Array in rows:
		text += "[cell padding=0,6,24,6][color=%s]%s[/color][/cell][cell padding=0,6,0,6]%s[/cell]" % [MUTED, row[0], row[1]]
	return text + "[/table]"


func _table3(rows: Array) -> String:
	var text := "[table=3]"
	for row: Array in rows:
		text += "[cell padding=0,6,32,6][color=%s]%s[/color][/cell][cell padding=0,6,32,6]%s[/cell][cell padding=0,6,0,6]%s[/cell]" % [MUTED, row[0], row[1], row[2]]
	return text + "[/table]"


func _num(value: float) -> String:
	return ("%.1f" % value).trim_suffix(".0")


func _num2(value: float) -> String:
	return ("%.2f" % value).trim_suffix("0").trim_suffix("0").trim_suffix(".")
