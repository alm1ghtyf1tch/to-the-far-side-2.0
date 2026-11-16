extends Control

const FONT := preload("res://assets/fonts/IBMPlexSans-Regular.woff2")
const FONT_BOLD := preload("res://assets/fonts/IBMPlexSans-SemiBold.woff2")
const BLUE := "#0b3d91"
const MUTED := "#323a45"

@onready var _content: VBoxContainer = %Content
@onready var _file_button: Button = %FileButton
@onready var _status_label: Label = %StatusLabel
@onready var _date_label: Label = %DateLabel


func _ready() -> void:
	if Campaign.runs_total == 0:
		Campaign.fund_calculations(float(Campaign.science()["requested_pct"]))
		Campaign.days += Campaign.research_days
		Campaign.finish_calculations(30, 40)
	_date_label.text = Campaign.date_text()
	_status_label.text = "From: Head of Flight Dynamics  ·  Awaiting filing: Program Director"
	_file_button.pressed.connect(_on_file_pressed)
	_build()
	_file_button.grab_focus()


func _on_file_pressed() -> void:
	_file_button.disabled = true
	_file_button.text = "Filed"
	_status_label.text = "Filed by the Program Director  ·  %s" % Campaign.date_text()
	Campaign.clock_running = true
	await get_tree().create_timer(0.8).timeout
	SceneRouter.go_to(SceneRouter.HQ, 0.6)


func _build() -> void:
	var margin := Campaign.margin
	var margin_text := ("%.1f" % margin).trim_suffix(".0")
	var flights := ReportChart.simulate(margin)
	var date := Campaign.date_text().capitalize()
	var rounds := Campaign.calc_rounds()
	var round_number := maxi(Campaign.calc_round, 1)
	var round_title: String = rounds[round_number - 1].get("title", "")

	_text("[font_size=40][b]Mission Analysis Report[/b][/font_size]\n[font_size=17][color=%s]Ref. FD-%d-014  ·  %s  ·  Flight Dynamics  ·  For: Program Director[/color][/font_size]" % [MUTED, Campaign.year(), date])
	_text(_table([
		["Round", "[b]%d of %d[/b] — %s" % [round_number, rounds.size(), round_title]],
		["Funding level", "%d%% of the mission budget reserved for all %d rounds (USD %.1f billion), plus %d%% for salaries" % [roundi(Campaign.calc_funding), rounds.size(), Campaign.billions(Campaign.calc_funding), roundi(Campaign.salaries_pct())]],
		["Work time", "%d days" % Campaign.research_days],
		["Runs verified", "%d of %d" % [Campaign.runs_hit, Campaign.runs_total]],
		["Result so far", "[b]Trajectory uncertainty: ±%s%%[/b]" % margin_text],
	]))

	_text("[b]In plain words.[/b] This report answers three questions. Which path takes a crew to the Moon and back? How much must the engines change the ship's speed along that path? And how sure are we of both answers? The last answer is the number at the bottom of the table above. It is the one figure from this report that every later phase will use, so it is worth reading how it was reached.")

	_text(_section("1", "The question") + "Find a path that takes a crew from Earth to the Moon and back, and work out how much rocket that path needs. Every later decision starts from these numbers: the size of the rocket, the fuel, the launch day.")

	_text(_section("2", "Gravity draws the path") + "A spacecraft spends almost the whole flight with its engines off. Its path is decided by gravity alone.")
	_formula("F  =  G · m₁ · m₂ / r²", "Newton's law of gravitation. The pull F between two masses gets four times weaker when the distance r doubles.")
	_text("With three bodies — Earth, Moon and ship — this has no exact solution. So we work the way flight planners have worked since the 1960s. First a quick estimate: near Earth we count only Earth's gravity, near the Moon only the Moon's, and we join the two curves. Then a computer refines it, moving the ship forward in small steps of time and adding up every pull at each step.")
	_formula("v²  =  GM · ( 2 / r  −  1 / a )", "The vis-viva equation: the ship's speed v at distance r from a body of mass M, on an orbit of size a.")
	_chart("trajectory", 340.0)
	_text("We chose a [b]free-return path[/b], shaped like a figure eight. If the engine fails after the first burn, the Moon's gravity turns the ship around and sends it home. Apollo 8, 10 and 11 began their flights this way, and so did Artemis II in 2026.")

	_text(_section("3", "The speed budget") + "Engines fire only in short burns that change the ship's speed. The size of each change is called Δv. Added together, they are the price of the mission.")
	_chart("dv", 280.0)
	_text("[font_size=16][color=%s]Approximate values from Apollo 11. Its burn toward the Moon lasted 5 minutes 48 seconds.[/color][/font_size]" % MUTED)

	_text(_section("4", "What speed costs in fuel").strip_edges())
	_formula("Δv  =  Isp · g₀ · ln( m₀ / m₁ )", "The rocket equation. m₀ is the mass when a burn starts, m₁ the mass when it ends. Isp measures how efficient the engine is.")
	_text("The logarithm is the hard part. To go a little faster you need much more propellant, and that propellant needs more propellant to lift it. This is why Moon rockets are enormous, why they drop empty stages on the way, and why every extra kilogram of payload is expensive.")
	_chart("rocket", 360.0)

	_text(_section("5", "When to launch") + "The Moon moves about one kilometre every second, so we aim at the place where it will be three days after launch. The landing site must also be in early-morning light, with the Sun low enough for shadows to show craters and rocks. Both conditions hold for only a few days each month. That is the [b]launch window[/b].")

	_text(_section("6", "How sure are we?") + "No engine burns exactly as planned and no measurement is perfect. So we flew the mission 1,000 times in the computer, each time with slightly different errors, and recorded how close the ship passes to the Moon. This is a Monte Carlo analysis, the method used to check real trajectories today.")
	_chart("dispersion", 330.0)
	var outcome := "Without any correction burns, [b]%d of 1,000[/b] simulated flights pass the Moon inside the safe corridor" % int(flights["inside"])
	if int(flights["impact"]) > 0:
		outcome += ", and [b]%d[/b] hit the surface" % int(flights["impact"])
	_text("[b]Trajectory uncertainty: ±%s%%.[/b] %s." % [margin_text, outcome])

	var conclusion := ""
	match Campaign.margin_level():
		"tight":
			conclusion = "The numbers are solid for this stage. Small correction burns on the way should be enough, and Engineering can design the rocket with normal fuel reserves."
		"moderate":
			conclusion = "The numbers are usable, but they have gaps. The crew will need larger correction burns on the way. We advise Engineering to carry extra fuel in reserve."
		_:
			conclusion = "[color=#dd361c][b]The uncertainty is large.[/b][/color] We did not have the resources to check enough cases. Flying with these numbers is a serious risk to the mission and to the crew. It can only be made up for later, and at a price: larger fuel reserves, a heavier rocket, and more expensive guidance and tracking equipment."
	_text(_section("7", "Where we stand after round %d" % round_number) + conclusion)

	var plan := "[table=3]"
	for index in rounds.size():
		var info: Dictionary = rounds[index]
		var state := "Done" if index < round_number else str(info.get("when", ""))
		var color := "#046b99" if index < round_number else MUTED
		plan += "[cell padding=0,6,20,6][b]%d.  %s[/b][/cell][cell padding=0,6,20,6][color=%s]%s[/color][/cell][cell padding=0,6,0,6]%s[/cell]" % [index + 1, info.get("title", ""), color, state, info.get("what", "")]
	plan += "[/table]"
	_text(_section("8", "This is not the last calculation") + "A flight is never calculated just once. The numbers in this report are a first answer, made before the rocket and the spacecraft exist. They will be worked out again every time we know more.")
	_text(plan)
	_text("Every round runs at the funding level you set, and after each one the uncertainty above is updated. The last round happens in flight. Apollo 11 had four correction burns scheduled on the way to the Moon; its launch was so accurate that only one was needed, a burn of three seconds.")

	_text(_section("9", "What this number is used for") + "The uncertainty of ±%s%% does not stay in this report. It travels with the mission.\n\n[b]In the design.[/b] Engineering adds it to every change of speed in the flight plan and sizes the tanks for the larger figure. Propellant that is carried just in case still has to be lifted off the ground.\n\n[b]At the Moon.[/b] The lander is aimed with these numbers. A path known exactly brings it down beside its target. A path known roughly can bring it down kilometres away, over ground nobody chose. The first crewed landing came down about six kilometres from its planned point. Four months later, with better tracking and a better map of the Moon's uneven gravity, the second landed within 200 metres of a probe that had stood there for two years.\n\n[b]On the way.[/b] Mission control measures where the ship really is and corrects the path with small burns. The less exact the plan, the more propellant those corrections take.\n\n[b]At the end.[/b] The same numbers aim the capsule at its splashdown point, where the recovery ships wait." % margin_text)
	_text(_section("10", "In real programmes") + "Flight dynamics teams do this work with software that models the pull of the Earth, the Moon and the Sun on a spacecraft and searches for the engine burns that reach the target. NASA's [b]General Mission Analysis Tool[/b], GMAT, is one such program. It is free and open source, built by NASA together with industry and universities, and it models flights in Earth orbit, to the Moon, to the Lagrange points, where the pull of two bodies balances, and to the planets.\n\nThe flight path of this mission comes from the same kind of equations, with the Earth and the Moon as the only bodies. As a check, they were run on a lunar transfer that was computed in GMAT and published by NASA. After four days of coasting the two answers were 2,700 km apart, 0.7% of the way to the Moon. GMAT also counts the pull of the Sun. With the Sun added, the difference was 3 km.")

	_text("\n[font_size=15][color=%s]Method notes. Real flight planners work the same way: quick estimates first, precise step-by-step integration after, then thousands of simulated flights. During Apollo the trajectory work ran on five IBM System/360 Model 75 mainframes, each with one megabyte of memory. Today NASA designs lunar trajectories with n-body tools such as Copernicus. The figures in this report are simplified.[/color][/font_size]" % MUTED)


func _section(number: String, title: String) -> String:
	return "[font_size=22][color=%s][b]%s.  %s[/b][/color][/font_size]\n" % [BLUE, number, title.to_upper()]


func _table(rows: Array) -> String:
	var text := "[table=2]"
	for row: Array in rows:
		text += "[cell padding=0,6,24,6][color=%s]%s[/color][/cell][cell padding=0,6,0,6]%s[/cell]" % [MUTED, row[0], row[1]]
	return text + "[/table]"


func _text(bbcode: String) -> void:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("normal_font", FONT)
	label.add_theme_font_override("bold_font", FONT_BOLD)
	label.add_theme_font_size_override("normal_font_size", 19)
	label.add_theme_font_size_override("bold_font_size", 19)
	label.add_theme_color_override("default_color", Color("212121"))
	label.text = bbcode
	_content.add_child(label)


func _formula(expression: String, caption: String) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("e1f3f8")
	style.border_color = Color("0b3d91")
	style.border_width_left = 4
	style.content_margin_left = 28.0
	style.content_margin_right = 24.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	var formula := Label.new()
	formula.text = expression
	formula.add_theme_font_override("font", FONT_BOLD)
	formula.add_theme_font_size_override("font_size", 30)
	formula.add_theme_color_override("font_color", Color("061f4a"))
	box.add_child(formula)
	var note := Label.new()
	note.text = caption
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_override("font", FONT)
	note.add_theme_font_size_override("font_size", 16)
	note.add_theme_color_override("font_color", Color("323a45"))
	box.add_child(note)
	_content.add_child(panel)


func _chart(kind: String, height: float) -> void:
	var chart := ReportChart.new()
	chart.kind = kind
	chart.margin_pct = Campaign.margin
	chart.custom_minimum_size = Vector2(0.0, height)
	chart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(chart)
