extends Control

const MUTED := "#323a45"
const BLUE := "#0b3d91"
const PROGRESS := {
	3: ["End of Pre-Phase A, Conceptual Study  ·  next: Phase A, Preliminary Analysis", "CML 2 of 9  ·  Initial Feasibility"],
	5: ["End of Phase A, Preliminary Analysis  ·  next: Phase B, Definition", "CML 3 of 9  ·  Trade Space"],
	7: ["End of Phase B, Definition  ·  next: Phase C/D, Design and Development", "CML 4 of 9  ·  Point Design"],
	9: ["End of Phase C/D, Design and Development  ·  next: Phase E, Operations", ""],
}

@onready var _report: RichTextLabel = %Report
@onready var _ack_button: Button = %AckButton
@onready var _status_label: Label = %StatusLabel
@onready var _date_label: Label = %DateLabel
@onready var _document_label: Label = %Document


func _ready() -> void:
	if Campaign.stage not in [3, 5, 7, 9]:
		Campaign.reset()
		Campaign.fund_calculations(float(Campaign.science()["requested_pct"]))
		Campaign.finish_calculations(30, 40)
	_date_label.text = Campaign.date_text()
	_status_label.text = "Decision of the Board  ·  For: Program Director"
	_document_label.text = "BD-%d-%03d  Board Decision.pdf" % [Campaign.year(), {3: 2, 5: 3, 7: 4, 9: 5}[Campaign.stage]]
	_report.text = {3: _concept_review, 5: _requirements_review, 7: _design_review, 9: _readiness_review}[Campaign.stage].call()
	_ack_button.pressed.connect(_on_ack_pressed)
	_ack_button.grab_focus()


func _on_ack_pressed() -> void:
	_ack_button.disabled = true
	_ack_button.text = "Acknowledged"
	Campaign.pass_review()
	Campaign.clock_running = true
	_status_label.text = "Acknowledged by the Program Director  ·  %s" % Campaign.date_text()
	await get_tree().create_timer(0.8).timeout
	SceneRouter.go_to(SceneRouter.HQ, 0.6)


func _concept_review() -> String:
	var finding: String = {
		"strong": "The analysis is convincing. The Board has no reservations.",
		"fair": "The analysis is acceptable. The Board notes the remaining uncertainty and expects it to shrink in the next round of calculations.",
		"weak": "[color=#dd361c][b]The Board is concerned.[/b][/color] The uncertainty is large for this stage. The mission may continue, but the Board will look closely at the next round of calculations.",
	}[Campaign.review_finding()]
	var lines: Array[String] = []
	lines.append(_header("Mission Concept Review", 2))
	lines.append(_table([
		["Presented", "Mission Analysis Report, round %d of %d" % [Campaign.calc_round, Campaign.calc_rounds().size()]],
		["Trajectory uncertainty", "±%s%%" % _num(Campaign.margin)],
		["Budget left", "%s%% of the mission budget" % _num(Campaign.budget_left)],
		["Time left", "%d days to the launch deadline" % Campaign.days_left()],
	] + _progress_rows()))
	lines.append(_section("1", "Why this review"))
	lines.append("No mission moves to its next phase on trust. At the end of each phase an independent board checks that the work so far is good enough to build on. Real space agencies run every mission through a chain of such reviews, from the first concept to the day of launch.\n\nThe reason is cost. A weak idea stopped here costs a few months of calculation. The same idea stopped after the rocket is built costs years and most of the budget. Each review is a gate: once you pass it, the decisions behind it become very expensive to change.")
	lines.append(_section("2", "How to read the numbers above"))
	lines.append(_explain([
		["Trajectory uncertainty", "How well Flight Dynamics knows the path to the Moon and back. ±%s%% means that every change of speed in the flight plan may turn out up to %s%% larger than calculated. Engineering has to carry propellant for that extra, whether it is used or not. Propellant is by far the heaviest thing on a rocket, so a wider uncertainty means a bigger and more expensive vehicle for the same mission." % [_num(Campaign.margin), _num(Campaign.margin)]],
		["Budget left", "The share of the mission budget that has not been spent. So far the money went to the agency's staff and to the calculations. Everything still to come is paid from what is left: the science instruments, the rocket and the spacecraft, the people who will fly them, and a reserve for problems nobody can predict today."],
		["Time left", "Days until the launch deadline set by the Government. The deadline does not move. Later you will see that the vehicle is ready only when its slowest part is ready, so days spent in this phase cannot be won back."],
	]))
	lines.append(_section("3", "Findings"))
	lines.append(finding)
	lines.append("\nThe calculations do not end here. Flight Dynamics will repeat them three more times as the mission becomes real: for the finished vehicle, for the day of launch, and during the flight itself. Each round is paid for at the funding level you chose.")
	lines.append(_section("4", "In real programmes"))
	lines.append("NASA calls this checkpoint the [b]Mission Concept Review[/b]. It is the first gate in the life of every project. The board asks three questions: is the goal clear, is there at least one workable way to reach it, and are the first estimates of cost and schedule believable? Many proposed missions never get past this gate. That is the system working as intended.\n\nEngineers at NASA's Jet Propulsion Laboratory grade how far an idea has come on a scale of nine [b]Concept Maturity Levels[/b]. The Government's request was level 1, which they call the “cocktail napkin”: a need, a goal and the limits, short enough to fit on one. The calculations you paid for made it level 2, initial feasibility: the key numbers are worked out to first order, and nothing in them rules the mission out. NASA Goddard's Mission Design Lab calls a study of this depth Concept Development. It takes a few half-days and delivers two things: a feasibility check and a list of risks.")
	lines.append(_decision("The mission concept is approved. The next phase is the [b]science plan[/b]: where to land and which instruments to take.", "5"))
	return "\n".join(lines)


func _requirements_review() -> String:
	var names: Array[String] = []
	for item: Dictionary in Campaign.instruments:
		names.append(str(item.get("name", "")))
	var finding: String = {
		"strong": "The scientific case is strong. This mission will answer real questions.",
		"fair": "The scientific case is sound.",
		"weak": "[color=#dd361c][b]The scientific case is weak.[/b][/color] The Board asks what this mission will bring back besides a flag. The Government will ask the same.",
	}[Campaign.review_finding()]
	if int(Campaign.site.get("risk_value", 1)) >= 3:
		finding += " The Board accepts the risk of the chosen site, and expects Engineering to show how it will be handled."
	var extra := float(Campaign.site.get("extra_dv", 0.0))
	var lines: Array[String] = []
	lines.append(_header("System Requirements Review", 3))
	lines.append(_table([
		["Landing site", "%s (%s site) — landing risk: %s" % [Campaign.site.get("name", "—"), Campaign.site.get("mission", "—"), Campaign.site.get("risk", "—")]],
		["Instruments", ", ".join(names) if not names.is_empty() else "None"],
		["Payload mass", "%d kg" % roundi(Campaign.payload_mass)],
		["Power needed", "%d W" % roundi(Campaign.payload_power)],
		["Extra speed", "None" if extra <= 0.0 else "+%s km/s for this site" % ("%.2f" % extra).trim_suffix("0")],
		["Science value", "%d points" % Campaign.science_value],
		["Budget left", "%s%% of the mission budget" % _num(Campaign.budget_left)],
	] + _progress_rows()))
	lines.append(_section("1", "Why this review"))
	lines.append("The science plan is now a list of requirements. Engineering has to build a spacecraft that can carry this mass, supply this power and reach this site. After this review the requirements are frozen: changing them later costs time and money.\n\nA requirement is a promise between departments. The scientists promise not to add instruments, and the engineers promise to deliver what is written here. Without that promise the design never ends, because every new wish changes the mass, the mass changes the propellant, and the propellant changes the rocket.")
	lines.append(_section("2", "How to read the numbers above"))
	lines.append(_explain([
		["Payload mass", "The weight of the instruments that must reach the surface. It is the most expensive kind of mass in the mission. Each kilogram set down on the Moon needs several hundred kilograms of rocket on the launch pad, because the lander, its propellant and every stage below have to grow to carry it."],
		["Power needed", "Electricity the instruments use while they work. The spacecraft's power source has to feed them as well as the cabin, the radio and the computers. An instrument that cannot be powered stays on Earth."],
		["Extra speed", "Sites far from the Moon's equator, or between mountains, need more manoeuvring to reach and to leave. That is paid in propellant, which the spacecraft has to carry all the way from Earth."],
		["Landing risk", "How rough the ground is. Flat lava plains are safe and scientifically plain. Mountains, valleys and old highlands tell more about the Moon's history, and they leave less clear ground to land on."],
		["Science value", "This game's measure of what the mission can bring back: the site itself plus every instrument. The final report will compare this plan with what the crew really returns."],
	]))
	lines.append(_section("3", "Findings"))
	lines.append(finding)
	lines.append(_section("4", "In real programmes"))
	lines.append("NASA calls this checkpoint the [b]System Requirements Review[/b]. After it, any change to a requirement has to be approved by a change board that counts what it will cost in mass, money and months. The six Apollo landings show why the science plan matters: the first crew spent about two and a half hours outside and brought back 22 kg of rock. The last crew stayed three days, drove a rover and brought back about 110 kg. The destination was the same Moon. The requirements were different.\n\nOn the scale of [b]Concept Maturity Levels[/b] used at NASA's Jet Propulsion Laboratory, the mission has now reached level 3, the trade space. The options were laid side by side, and each site and each instrument showed how science, cost and risk pull against one another. The advice that comes with this level is not to settle on one design before the options have been explored. NASA Goddard's Mission Design Lab calls work of this kind a trade study. Its products include a concept of operations and a summary of resources: in this review, the payload mass and the power in the table above.")
	lines.append(_decision("The requirements are approved and frozen. The next phase is the [b]design[/b] of the rocket and the spacecraft.", "5"))
	return "\n".join(lines)


func _design_review() -> String:
	var stats := Vehicle.stats
	var port := Vehicle.chosen(Vehicle.design, "spaceport")
	var open_items := Vehicle.shortfalls(stats)
	var notes := {
		"liftoff": "The first stage has too little thrust for a rocket of this mass. It will barely leave the pad.",
		"rocket": "The rocket delivers %.2f km/s. The flight needs %.2f km/s with the present reserve." % [stats["rocket_dv"], stats["rocket_need"]],
		"ship": "The spacecraft engine delivers %.2f km/s. Entering lunar orbit and coming home needs %.2f km/s." % [stats["ship_dv"], stats["ship_need"]],
		"cargo": "The lander carries %d kg to the surface. The science plan weighs %d kg. Some instruments will stay on Earth." % [roundi(stats["cargo_capacity"]), roundi(stats["cargo_need"])],
		"power": "The power source gives %s kW. The spacecraft and its instruments need %s kW." % [_num(stats["power_have"]), _num(stats["power_need"])],
		"suits": "The crew has cabin suits only. Nobody will be able to step out onto the surface.",
		"late": "The vehicle will be ready %d days after the deadline set by the Government." % -int(stats["spare_days"]),
		"range": "Every flight path from %s crosses land. Range safety has not approved a launch to orbit from there." % port.get("name", "the launch site"),
	}
	var finding := "The design closes: every number the Board checked is on the right side of its requirement."
	if not open_items.is_empty():
		var listed: Array[String] = []
		for key in open_items:
			listed.append("•  " + str(notes[key]))
		finding = ("[color=#dd361c][b]The Board has open items.[/b][/color] " if open_items.size() > 1 else "The Board has one open item. ") \
				+ "The design is frozen, so they go into the flight as known risks.\n\n" + "\n".join(listed)
	var parts: Array = []
	for row: Array in Vehicle.summary(Vehicle.design):
		parts.append([row[0], row[1]])
	var lines: Array[String] = []
	lines.append(_header("Critical Design Review", 4))
	lines.append(_table(parts + _progress_rows()))
	lines.append(_section("1", "Why this review"))
	lines.append("This is the last review before the vehicle is built. Until now a change cost a line on a drawing. From here on it costs hardware, money and months. Real programmes hold the same review for the same reason.")
	lines.append(_section("2", "What the Board checked"))
	lines.append(_table([
		["Rocket speed", "%.2f km/s  ·  needed %.2f" % [stats["rocket_dv"], stats["rocket_need"]]],
		["Launch site", "%s, %s  ·  %s° N  ·  the Earth's spin adds %d m/s" % [port.get("name", "—"), port.get("state", "—"), _num(float(port.get("lat", 0.0))), int(port.get("spin", 0))]],
		["Spacecraft engine", "%.2f km/s  ·  needed %.2f" % [stats["ship_dv"], stats["ship_need"]]],
		["Lander cargo", "%d kg  ·  needed %d" % [roundi(stats["cargo_capacity"]), roundi(stats["cargo_need"])]],
		["Electric power", "%s kW  ·  needed %s" % [_num(stats["power_have"]), _num(stats["power_need"])]],
		["Crew", "%d aboard, %d on the surface  ·  %s days  ·  %s t of air, water and food" % [stats["crew"], stats["surface_crew"], _num(stats["mission_days"]), _num(snappedf(float(stats["supplies"]), 0.01))]],
		["Cost of the vehicle", "%s%% of the mission budget, of which %s%% is people and facilities for %d days  ·  %s%% left" % [_num(stats["cost"]), _num(stats["workforce_cost"]), int(stats["program_days"]), _num(Campaign.budget_left)]],
		["Ready to launch", "%s  ·  deadline %s" % [Campaign.date_text(int(stats["ready_day"])).capitalize(), Campaign.deadline_text().capitalize()]],
	]))
	lines.append(_section("3", "How to read these checks"))
	lines.append(_explain([
		["Rocket speed", "Rockets are measured by how much they can change their speed. Reaching a low orbit takes about 9.2 km/s once the fight against gravity and air is counted, and leaving that orbit for the Moon takes about 3.2 km/s more. The second figure in the row is that total plus the reserve for the trajectory uncertainty. If the rocket gives less, the spacecraft does not reach the Moon."],
		["Launch site", "The Earth turns from west to east, about 465 m/s at the equator. A rocket launched eastward starts with part of that speed already. How much depends on how steeply its orbit is tilted against the equator. A site cannot reach an orbit tilted less than its own latitude, and a site that may only launch toward the poles gets less help still. What the Earth does not give, the rocket must: the speed needed in the row above already counts it. The site also decides what lies under the flight path, where the spent stages fall."],
		["Spacecraft engine", "After the rocket is gone the spacecraft has its own engine and two jobs for it: to slow down into orbit around the Moon, and to speed up again for the trip home. Both burns happen behind the Moon. The engine has to have enough for both before the first one starts."],
		["Lander cargo", "What the lander can set down on the surface compared with what the science plan weighs. Whatever does not fit is left behind before launch."],
		["Electric power", "What the power source gives compared with what the cabin, the radio, the life support and the instruments draw together."],
		["Crew", "People aboard, people who go down to the surface, the length of the flight, and the air, water and food all of that needs. One person always stays in orbit with the ship that brings everyone home."],
		["Cost of the vehicle", "Hardware is only part of it. The engineers, the factories and the test stands are paid for every day the build lasts, so a part that takes longer to build makes the whole vehicle more expensive."],
		["Ready to launch", "The vehicle is ready when its slowest part is built, everything is put together and the test programme is finished. Compare the date with the deadline, and remember that builds rarely run exactly to plan."],
	]))
	lines.append(_section("4", "Findings"))
	lines.append(finding)
	lines.append(_section("5", "In real programmes"))
	lines.append("NASA calls this checkpoint the [b]Critical Design Review[/b]. It is held when the drawings are nearly complete. After it they go to the factories, and from then on a change means scrapping metal. The Saturn V that flew the Apollo crews stood 110 metres tall and weighed almost 3,000 tonnes at lift-off, and about nine tenths of that weight was propellant. Thirteen were launched. Every one of them reached space.\n\nIn the [b]Concept Maturity Levels[/b] of NASA's Jet Propulsion Laboratory, what you handed over is level 4, a point design: one specific vehicle chosen from all the options, defined down to its main subsystems, with a cost and margins. NASA Goddard's Mission Design Lab produces a point design in six days, with specialists in flight dynamics, propulsion, power, communications, structures, thermal control, mission operations and cost working together. The checks in section 2 are theirs. A real programme then spends years taking the design through five more levels of detail: the critical design review is level 9, the top of the scale. The game makes that climb in one step.")
	lines.append(_decision("The design is approved for manufacture. The next phase is the [b]flight operations plan[/b]: the people and the ground systems that will fly this vehicle.", "6"))
	return "\n".join(lines)


func _readiness_review() -> String:
	var build := Flight.build
	var port := Vehicle.launch_site()
	var launch_day := int(build.get("launch_day", 0))
	var spare := Campaign.days_total() - launch_day
	var reserve := float(build.get("reserve_after", 0.0))
	var plan: Array = []
	for item: Dictionary in Operations.items():
		plan.append([str(item["title"]), Operations.level_name(str(item["id"]))])
	var events: Array[String] = []
	for event: Dictionary in build.get("events", []):
		events.append("•  %s  [color=%s]+%d days  ·  %s%% of the budget[/color]" % [event["text"], MUTED, int(event["days"]), _num(float(event["cost"]))])
	var left: Array[String] = []
	for item: Dictionary in build.get("left_behind", []):
		left.append("•  %s  [color=%s]%s[/color]" % [item["name"], MUTED, "too heavy for the lander" if item["reason"] == "mass" else "not enough electric power"])
	var findings: Array[String] = []
	if reserve < 0.0:
		findings.append("[color=#dd361c][b]The programme is over budget.[/b][/color] The reserve did not cover the problems of the build. The Government will have to be asked for %s%% more." % _num(-reserve))
	if spare < 0:
		findings.append("[color=#dd361c][b]The launch is %d days after the deadline.[/b][/color] The Board will have to explain this to the Government." % -spare)
	if not left.is_empty():
		findings.append("Part of the science plan cannot fly. It stays on Earth:\n" + "\n".join(left))
	if build.get("power_short", false):
		findings.append("The spacecraft still needs more electric power than it has. The crew will fly with some systems switched off.")
	if findings.is_empty():
		findings.append("The vehicle, the crew and the ground are ready. The Board has no open items.")
	var lines: Array[String] = []
	lines.append(_header("Flight Readiness Review", 5))
	lines.append(_table([
		["Vehicle", "Built and tested  ·  test programme: %s" % Flight._lower(str(build.get("tests", "—")))],
		["Launch site", "%s, %s%s" % [port.get("name", "—"), port.get("state", "—"), "  ·  moved from %s" % Vehicle.chosen(Vehicle.design, "spaceport").get("name", "—") if build.get("moved", false) else ""]],
		["Launch date", "%s  ·  %s" % [Campaign.date_text(launch_day).capitalize(), "%d days before the deadline" % spare if spare >= 0 else "%d days after the deadline" % -spare]],
		["Trajectory uncertainty", "±%s%% after round %d of %d" % [_num(Campaign.margin), Campaign.calc_round, Campaign.calc_rounds().size()]],
		["Budget left", "%s%% of the mission budget" % _num(Campaign.budget_left)],
	] + _progress_rows()))
	lines.append(_section("1", "Why this review"))
	lines.append("This is the last question a programme asks itself: is everything, and everyone, ready to fly? Real agencies hold a Flight Readiness Review before every crewed launch. Anyone in the room can say no.\n\nUntil today a mistake cost money or time. From the moment of launch it can cost the mission, and there is nothing more to decide: what was designed, tested, trained and paid for is what flies.")
	lines.append(_section("2", "What happened during the build"))
	lines.append("No vehicle of this size is built without surprises. Each one costs time, and time costs money: the factories and the people are paid while they wait.\n\nEvery part of the vehicle can hide a flaw that nobody knows about. The test programme you chose exists to find those flaws on the ground, where they cost days and money. A flaw that the tests did not find is still there. It flies with the crew, and it shows itself when that part is asked to work.\n")
	lines.append("\n".join(events) if not events.is_empty() else "Nothing unexpected happened.")
	lines.append("\n" + _table([
		["Delay", "%d days" % int(build.get("delay", 0))],
		["Repairs and rework", "%s%% of the budget" % _num(float(build.get("cost", 0.0)))],
		["People and factories waiting", "%s%% of the budget" % ("%.2f" % float(build.get("idle_cost", 0.0))).trim_suffix("0")],
		["Reserve", "%s%% before the build  ·  %s%% now" % [_num(float(build.get("reserve_before", 0.0))), _num(reserve)]],
	]))
	lines.append("\n[b]Delay[/b] is added to the launch date. [b]Repairs and rework[/b] is the direct price of fixing what went wrong. [b]People and factories waiting[/b] is what the programme pays simply because it lasted longer. The [b]reserve[/b] is the money you did not spend on operations: it is the only thing that pays for all three. When it runs out, the programme is over budget.")
	lines.append(_section("3", "Flight operations plan"))
	lines.append(_table(plan))
	lines.append("\nThese five lines are the people and systems around the vehicle. They build nothing, and they decide a great deal: whether the countdown reaches zero on the first attempt, how well the crew and the controllers handle the unexpected, how much of the science reaches Earth, and how long the crew waits in the sea after splashdown.")
	lines.append(_section("4", "Findings"))
	lines.append("\n\n".join(findings))
	lines.append(_section("5", "In real programmes"))
	lines.append("The [b]Flight Readiness Review[/b] is held a week or two before a crewed launch. Launch day itself is rarely simple. The first Artemis rocket was rolled to its pad and sent back more than once: practice countdowns found hydrogen leaks, and two launch attempts in 2022 were called off before it flew on the third. Programmes of this size plan for that. It is common to hold back a fifth to a third of the budget as a reserve for problems that have not happened yet.\n\nIn NASA's project calendar this review closes Phase C/D, Design and Development. What comes next is Phase E, Operations: the flight itself.")
	lines.append(_decision("The vehicle is cleared for launch on [b]%s[/b]. The next phase is the [b]flight[/b]. At launch and at the landing you may take the controls yourself, or leave them to the computer." % Campaign.date_text(launch_day).capitalize(), "6"))
	return "\n".join(lines)


func _progress_rows() -> Array:
	var entry: Array = PROGRESS.get(Campaign.stage, ["", ""])
	var rows: Array = [["Project phase", entry[0]]]
	if not str(entry[1]).is_empty():
		rows.append(["Concept maturity", entry[1]])
	return rows


func _header(title: String, number: int) -> String:
	return "[font_size=40][b]Board Decision[/b][/font_size]\n[font_size=24][color=%s][b]%s[/b][/color][/font_size]\n[font_size=17][color=%s]Ref. BD-%d-%03d  ·  %s  ·  Board of Directors[/color][/font_size]\n" % [BLUE, title, MUTED, Campaign.year(), number, Campaign.date_text().capitalize()]


func _decision(text: String, number := "3") -> String:
	return _section(number, "Decision") + "\n[b]Approved.[/b] %s\n\n[color=%s]Board confidence in the program: [/color][b]%s[/b][color=%s]  ·  The review takes %d days.[/color]" % [text, MUTED, _confidence_after(), MUTED, roundi(Campaign.review_days())]


func _confidence_after() -> String:
	var before := Campaign.board_confidence
	var change := {"strong": 5.0, "fair": 0.0, "weak": -15.0 if Campaign.stage == 3 else -10.0}
	if not change.has(Campaign.review_finding()):
		return Campaign.confidence_text()
	var after := clampf(before + float(change[Campaign.review_finding()]), 0.0, 100.0)
	if after >= 75.0:
		return "High"
	return "Medium" if after >= 55.0 else "Low"


func _explain(rows: Array) -> String:
	var parts: Array[String] = []
	for row: Array in rows:
		parts.append("[b]%s.[/b]  %s" % [row[0], row[1]])
	return "\n\n".join(parts)


func _section(number: String, title: String) -> String:
	return "\n[font_size=22][color=%s][b]%s.  %s[/b][/color][/font_size]" % [BLUE, number, title.to_upper()]


func _table(rows: Array) -> String:
	var text := "[table=2]"
	for row: Array in rows:
		text += "[cell padding=0,6,24,6][color=%s]%s[/color][/cell][cell padding=0,6,0,6]%s[/cell]" % [MUTED, row[0], row[1]]
	return text + "[/table]"


func _num(value: float) -> String:
	return ("%.1f" % value).trim_suffix(".0")
