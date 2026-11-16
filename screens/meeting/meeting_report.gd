extends Control

@onready var _report: RichTextLabel = %Report
@onready var _approve_button: Button = %ApproveButton
@onready var _status_label: Label = %StatusLabel
@onready var _scroll: ScrollContainer = %Scroll


func _ready() -> void:
	_report.text = _build_report()
	_approve_button.pressed.connect(_on_approve_pressed)
	_status_label.text = "Awaiting approval: Program Director"
	_approve_button.grab_focus()


func _on_approve_pressed() -> void:
	_approve_button.disabled = true
	_approve_button.text = "Approved"
	_status_label.text = "Approved by the Program Director · %s" % Campaign.date_text()
	Campaign.stage = 2
	Campaign.clock_running = true
	await get_tree().create_timer(0.9).timeout
	SceneRouter.go_to(SceneRouter.HQ, 0.6)


func _build_report() -> String:
	var date := "14 November 2026"
	var deadline := "20 July 2033"
	var days := Campaign.days_total()
	var budget := "USD %.1f billion" % Campaign.BUDGET_BILLIONS
	var lines: Array[String] = []
	lines.append("[font_size=40][b]Meeting Summary[/b][/font_size]")
	lines.append("[font_size=17][color=#323a45]Ref. BD-2026-001  ·  %s  ·  Release: Public[/color][/font_size]" % date)
	lines.append("")
	lines.append(_table([
		["Date", date],
		["Place", "Headquarters, Floor 3 — Boardroom"],
		["Present", "Members of the Board of Directors, Chief Financial Officer, Chief Engineer, Head of Flight Dynamics, Head of Science, Chief of Crewed Spaceflight, Government Liaison"],
		["Recorded by", "Office of the Board Secretary"],
	]))
	lines.append(_section("1", "Purpose"))
	lines.append("To answer the Government's request for a crewed mission to the Moon and to set the mission's objective, deadline and budget.")
	lines.append(_section("2", "Government request"))
	lines.append("The Government Liaison informed the Board that the Government asks the agency to [b]land a crew on the Moon and return them safely to Earth[/b]. The request is a national priority. The Government will pay for the mission, but expects regular proof that the goal can be reached on time and within budget.")
	lines.append("")
	lines.append("A crewed Moon mission is the hardest thing a space agency can be asked to do. The Moon is 384,400 km away, a thousand times farther than a space station. A crew that leaves for it cannot turn back quickly and cannot be resupplied. Everything they need for the whole flight has to leave the ground with them on a single launch.")
	lines.append(_section("3", "Discussion"))
	lines.append("The Board compared three options: a flight around the Moon, a crew in lunar orbit, and a full landing.")
	lines.append("")
	lines.append(_table([
		["Flight around the Moon", "The ship loops behind the Moon and comes straight home. It needs no lander and the least propellant, and it proves that the rocket, the capsule and the heat shield work. Nobody touches the surface. Artemis II flew this kind of mission in April 2026."],
		["Crew in lunar orbit", "The ship brakes into orbit and stays for days. The crew can photograph and measure the Moon from 110 km up. It needs a larger engine and more propellant than a flight around, and still returns no samples."],
		["Landing", "Part of the crew goes down to the surface, works there and comes back up. It needs a second spacecraft, the lander, and that makes everything below it heavier. It is the only option that brings back rock, leaves instruments behind and answers the Government's request."],
	]))
	lines.append("")
	lines.append("The Chief of Crewed Spaceflight argued for the landing and proposed that the agency should:")
	lines.append("[indent][color=#0b3d91][i]“Adopt the lunar landing mission as its present long range objective with proper emphasis on intermediate steps because this approach will be easier to sell.”[/i][/color][/indent]")
	lines.append("[font_size=15][color=#323a45][indent]These words were first said in May 1959, inside NASA, by the official in charge of crewed spaceflight, during the earliest planning of the Moon landings.[/indent][/color][/font_size]")
	lines.append("")
	lines.append("The Chief Financial Officer warned that the budget is fixed: every dollar spent early is a dollar that will not be there later.")
	lines.append("")
	lines.append("The Head of Flight Dynamics noted that nothing can be designed before the flight is calculated: the trajectory, the mass and the fuel.")
	lines.append("")
	lines.append("The Chief Engineer added that the calendar is as tight as the money. A vehicle of this kind takes four to six years to build and test, so the first decisions leave little room to start again.")
	lines.append("")
	lines.append("The Head of Science reminded the Board that a landing with nothing to measure is only a visit. What the crew carries to the surface decides what the mission is worth afterwards.")
	lines.append(_section("4", "Decisions"))
	lines.append(_table([
		["Objective", "Land a crew on the Moon and return them safely to Earth"],
		["Launch deadline", "No later than [b]%s[/b] (%s days from today)" % [deadline, _thousands(days)]],
		["Mission budget", "[b]%s[/b], released to the Program Director as [b]100%%[/b] of the mission budget" % budget],
		["Program Director", "Appointed today. Reports to the Board"],
	]))
	lines.append(_section("5", "What the budget has to buy"))
	lines.append("The whole mission is paid from one budget, and it is counted in percent so that every decision can be compared with every other. Money spent in one place is not available in the next.")
	lines.append("")
	lines.append(_table([
		["Agency staff", "3% is set aside from the first day for management and salaries."],
		["Flight calculations", "Decided by you in the next phase. More money buys a path that is known more exactly."],
		["Science instruments", "Each instrument has a price, a weight and a need for power."],
		["Rocket and spacecraft", "By far the largest share: the hardware, its propellant, its tests, and the people and factories for every day the build lasts."],
		["Flight operations", "Crew training, mission control, the launch team, the recovery ships and the flight computer."],
		["Reserve", "Whatever is left. It pays for the problems that appear while the vehicle is being built."],
	]))
	lines.append(_section("6", "How the Board will check the work"))
	lines.append("The mission moves through phases, and each phase ends with a review. These are the reviews real space agencies hold, under the same names.")
	lines.append("")
	lines.append(_table([
		["Mission Concept Review", "After the first calculations: is there a workable path to the Moon?"],
		["System Requirements Review", "After the science plan: what exactly must the vehicle carry and where?"],
		["Critical Design Review", "After the design: does the vehicle close on speed, mass, power, cost and time?"],
		["Flight Readiness Review", "Before launch: is the vehicle built, tested and ready, and are the people ready to fly it?"],
	]))
	lines.append("")
	lines.append("The Board does not tell the Program Director what to choose. It records what was chosen, checks the numbers and says what it sees. What a choice really leads to will show later, often several phases later, and the final mission report will trace each result back to the decision behind it.")
	lines.append(_section("7", "Next steps"))
	lines.append("1.  The Flight Dynamics team, part of Engineering, will calculate the flight: trajectory, mass and fuel.")
	lines.append("2.  The Science department will then choose the landing site and the instruments.")
	lines.append("3.  Each phase ends with a review by the Board. The next phase opens only after the review.")
	lines.append("4.  Funds not spent on the calculations pass on to the launch vehicle, the spacecraft and the crew.")
	lines.append("5.  The mission calendar starts when this summary is approved.")
	lines.append("")
	return "\n".join(lines)


func _section(number: String, title: String) -> String:
	return "\n[font_size=22][color=#0b3d91][b]%s.  %s[/b][/color][/font_size]" % [number, title.to_upper()]


func _table(rows: Array) -> String:
	var text := "[table=2]"
	for row: Array in rows:
		text += "[cell padding=0,6,24,6][color=#323a45]%s[/color][/cell][cell padding=0,6,0,6]%s[/cell]" % row
	return text + "[/table]"


func _thousands(value: int) -> String:
	var text := str(value)
	var result := ""
	while text.length() > 3:
		result = "," + text.right(3) + result
		text = text.left(text.length() - 3)
	return text + result
