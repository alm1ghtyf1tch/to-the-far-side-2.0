extends Control

@onready var _board: FloorHotspot = %BoardFloor
@onready var _engineering: FloorHotspot = %EngineeringFloor
@onready var _science: FloorHotspot = %ScienceFloor
@onready var _stage_label: Label = %StageLabel
@onready var _title_label: Label = %TitleLabel
@onready var _body_label: Label = %BodyLabel
@onready var _info_box: Control = %InfoBox
@onready var _deadline_value: Label = %DeadlineValue
@onready var _budget_value: Label = %BudgetValue
@onready var _time_key: Label = %TimeKey
@onready var _time_value: Label = %TimeValue
@onready var _budget_top_label: Label = %BudgetTopLabel
@onready var _task_label: Label = %TaskLabel
@onready var _hint_label: Label = %HintLabel
@onready var _panel_content: Control = %PanelContent
@onready var _date_label: Label = %DateLabel
@onready var _day_label: Label = %DayLabel
@onready var _roadmap: RichTextLabel = %Roadmap

const BACKDROP := "drawn"
const DRAWN_BACKDROP := "res://assets/textures/hq_building_drawn.jpg"
const DRAWN_WALLS := Vector2(190.0, 1180.0)
const DRAWN_FLOORS := {"BoardFloor": Vector2(138.0, 372.0), "EngineeringFloor": Vector2(400.0, 614.0), "ScienceFloor": Vector2(642.0, 856.0)}

const ROADMAP: Array[String] = ["Board meeting", "Flight Dynamics", "Review", "Science plan", "Review", "Design", "Review", "Operations", "Review", "Flight", "Report"]
const ROADMAP_WINDOW := 7

var _goal: FloorHotspot = null
var _goal_scene := ""
var _hints := {}
var _shown_day := -1


func _ready() -> void:
	_apply_backdrop()
	for hotspot: FloorHotspot in [_board, _engineering, _science]:
		hotspot.clicked.connect(_on_floor_clicked)
	_hint_label.text = ""
	_show_stage()
	_update_date()
	_panel_content.modulate.a = 0.0
	create_tween().tween_property(_panel_content, "modulate:a", 1.0, 0.6).set_delay(0.3)


func _apply_backdrop() -> void:
	if BACKDROP != "drawn" or not ResourceLoader.exists(DRAWN_BACKDROP):
		return
	var building := get_node_or_null("Aspect/Frame/Building") as TextureRect
	if building == null:
		return
	building.texture = load(DRAWN_BACKDROP)
	for hotspot: FloorHotspot in [_board, _engineering, _science]:
		var span: Vector2 = DRAWN_FLOORS.get(str(hotspot.name), Vector2.ZERO)
		if span != Vector2.ZERO:
			hotspot.corners = PackedVector2Array([
				Vector2(DRAWN_WALLS.x, span.x), Vector2(DRAWN_WALLS.y, span.x), Vector2(DRAWN_WALLS.y, span.y), Vector2(DRAWN_WALLS.x, span.y)])


func _process(delta: float) -> void:
	Campaign.tick(delta)
	_update_date()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Campaign.clock_running = false
		SceneRouter.go_to(SceneRouter.MAIN_MENU)


func _show_stage() -> void:
	var stage := Campaign.stage
	_stage_label.text = "STAGE %d" % stage
	_info_box.visible = stage > 1
	_deadline_value.text = Campaign.deadline_text()
	_budget_value.text = "%s%% available" % _num(Campaign.budget_left)
	_budget_top_label.text = "%d%%" % roundi(Campaign.budget_left)
	_time_key.text = "Trajectory"
	_time_value.text = "±%s%% after round %d of %d" % [_num(Campaign.margin), Campaign.calc_round, Campaign.calc_rounds().size()]
	_show_roadmap(stage)
	match stage:
		1:
			_title_label.text = "Meeting with the Board"
			_body_label.text = "Every mission to the Moon starts at a table, not on a launch pad. Before engineers draw a single part, the agency has to agree on why it is going, what it will cost and who will pay.\n\nThe Board of Directors is waiting for you on the top floor."
			_task_label.text = "Click the 3rd floor to join the meeting."
			_set_goal(_board, SceneRouter.MEETING, {
				_engineering: "Not yet. The Board has to approve the mission before Engineering can start work.",
				_science: "Not yet. The Board has to approve the mission before Science can start work.",
			})
		2:
			_title_label.text = "Flight Dynamics"
			_body_label.text = "Nothing can be built until the flight is calculated: the path, the speed changes and the fuel. That is the job of Flight Dynamics, a team inside Engineering.\n\nWhy engineers before scientists? Until the flight is calculated, nobody knows how much mass can reach the Moon, and that limits what the scientists may take."
			_time_key.text = "Time"
			_time_value.text = "1 second = 1 day"
			_task_label.text = "Click the 2nd floor to meet the Flight Dynamics team."
			_set_goal(_engineering, SceneRouter.SCIENCE_BUDGET, {
				_board: "The Board has already approved the mission. Come back with results.",
				_science: "The scientists are waiting for the first calculations.",
			})
		3:
			_title_label.text = "Board Review"
			_body_label.text = "The first round of calculations is filed. No mission moves to its next phase on trust: the Board wants to see the Mission Analysis Report before it opens the next one.\n\nThis checkpoint is the Mission Concept Review."
			_task_label.text = "Click the 3rd floor to present the report."
			_set_goal(_board, SceneRouter.BOARD_REVIEW, {
				_engineering: "Flight Dynamics has filed its report. Take it to the Board.",
				_science: "The Board has not opened the science phase yet.",
			})
		4:
			_title_label.text = "Science Plan"
			_body_label.text = "The flight is possible. Now the mission needs a reason to land.\n\nThe Science department decides where the crew will land and which instruments they take. You choose from six real Apollo landing sites. Every instrument adds mass, needs power and costs money."
			_task_label.text = "Click the 1st floor to meet the science team."
			_set_goal(_science, SceneRouter.SCIENCE_PLAN, {
				_board: "The Board expects a science plan before the next review.",
				_engineering: "Engineering can't size the spacecraft before it knows what it has to carry.",
			})
		5:
			_title_label.text = "Board Review"
			_body_label.text = "The science plan is ready. Before the engineers design anything, the Board checks the plan and freezes it as requirements: the mass to carry, the power to supply, the site to reach.\n\nThis checkpoint is the System Requirements Review."
			_show_payload()
			_task_label.text = "Click the 3rd floor to present the science plan."
			_set_goal(_board, SceneRouter.BOARD_REVIEW, {
				_engineering: "The requirements are not approved yet. Take the science plan to the Board.",
				_science: "The science team has finished its plan. Take it to the Board.",
			})
		6:
			_title_label.text = "Design the Vehicle"
			_body_label.text = "The requirements are frozen. Now the numbers have to become hardware: a rocket, a spacecraft and a lander.\n\nIn the assembly building you choose every section of the vehicle from a catalogue of real designs. Each part has a mass, a price and a build time, and each one changes what the others must do."
			_show_payload()
			_task_label.text = "Click the 2nd floor to enter the assembly building."
			_set_goal(_engineering, SceneRouter.ENGINEERING, {
				_board: "The Board expects a design, not just plans.",
				_science: "The science plan is frozen. The engineers are next.",
			})
		7:
			_title_label.text = "Board Review"
			_body_label.text = "The design is frozen. Before any metal is cut, the Board goes through it line by line: does the rocket reach the Moon, does the spacecraft come back, does it fit the budget and the deadline?\n\nThis checkpoint is the Critical Design Review."
			_show_vehicle()
			_task_label.text = "Click the 3rd floor to present the design."
			_set_goal(_board, SceneRouter.BOARD_REVIEW, {
				_engineering: "The design is finished. Take it to the Board.",
				_science: "The scientists are waiting to hear whether their instruments will fly.",
			})
		8:
			_title_label.text = "Flight Operations"
			_body_label.text = "The design is approved and the factories are starting work. A rocket does not fly by itself: it needs a trained crew, a control room, a launch team and ships waiting at sea.\n\nWhat is left of the budget has to pay for all of them, and still leave a reserve for the problems nobody has found yet."
			_show_vehicle()
			_task_label.text = "Click the 2nd floor to plan the operations."
			_set_goal(_engineering, SceneRouter.OPERATIONS, {
				_board: "The Board has approved the design. Now it wants a plan for flying it.",
				_science: "The instruments are being built for the flight.",
			})
		9:
			_title_label.text = "Board Review"
			_body_label.text = "Years have passed. The vehicle has been built and tested, and not everything went to plan. The Board wants to hear what happened, what it cost and what is flying.\n\nThis checkpoint is the Flight Readiness Review: the last one before launch."
			_show_launch()
			_task_label.text = "Click the 3rd floor to report readiness."
			_set_goal(_board, SceneRouter.BOARD_REVIEW, {
				_engineering: "The vehicle is finished. Report to the Board.",
				_science: "The instruments are packed. The scientists are waiting for the Board.",
			})
		10:
			_title_label.text = "Launch"
			_body_label.text = "The vehicle is on the pad and the crew is ready. Every decision of the last seven years is now inside this rocket.\n\nFrom here on you watch. Mission control follows the flight phase by phase, and the flight rules decide what happens when something goes wrong."
			_show_launch()
			_task_label.text = "Click the 2nd floor to enter mission control."
			_set_goal(_engineering, SceneRouter.MISSION_CONTROL, {
				_board: "The Board has given its go. Mission control is on the 2nd floor.",
				_science: "The scientists are watching from the back room of mission control.",
			})
		_:
			_title_label.text = "Mission Report"
			_body_label.text = "The flight is over. What is left is the most useful document a programme writes: what was planned, what really happened, and which decision led to which result.\n\nThe Board is waiting for it."
			_time_key.text = "Result"
			_time_value.text = "%d of 5 objectives met" % Flight.objectives_met()
			_task_label.text = "Click the 3rd floor to read the mission report."
			_set_goal(_board, SceneRouter.MISSION_REPORT, {
				_engineering: "Mission control has closed its consoles. The report is with the Board.",
				_science: "The scientists are already working on the data. The report is with the Board.",
			})


func _show_roadmap(stage: int) -> void:
	var parts: Array[String] = []
	var first := clampi(stage - 3, 0, ROADMAP.size() - ROADMAP_WINDOW)
	if first > 0:
		parts.append("[color=#6f819d]✓ %d done[/color]" % first)
	for index in range(first, first + ROADMAP_WINDOW):
		var number := index + 1
		if number < stage:
			parts.append("[color=#6f819d]✓ %s[/color]" % ROADMAP[index])
		elif number == stage:
			parts.append("[color=#ffc233][b]%d  %s[/b][/color]" % [number, ROADMAP[index]])
		else:
			parts.append("[color=#93a4bf]%d  %s[/color]" % [number, ROADMAP[index]])
	_roadmap.text = "[color=#6f819d]   ›   [/color]".join(PackedStringArray(parts))


func _show_payload() -> void:
	_time_key.text = "Payload"
	_time_value.text = "%d kg  ·  %d W" % [roundi(Campaign.payload_mass), roundi(Campaign.payload_power)]


func _show_launch() -> void:
	_time_key.text = "Launch"
	_time_value.text = Campaign.date_text(int(Flight.build.get("launch_day", int(Campaign.days))))


func _show_vehicle() -> void:
	_time_key.text = "Vehicle"
	_time_value.text = "%d t  ·  crew of %d" % [roundi(float(Vehicle.stats.get("liftoff_mass", 0.0))), int(Vehicle.stats.get("crew", 0))]


func _set_goal(hotspot: FloorHotspot, scene: String, hints: Dictionary) -> void:
	_goal = hotspot
	_goal_scene = scene
	_hints = hints
	for floor: FloorHotspot in [_board, _engineering, _science]:
		floor.is_goal = floor == hotspot
		floor.is_selected = false


func _on_floor_clicked(hotspot: FloorHotspot) -> void:
	if hotspot != _goal:
		_show_hint(str(_hints.get(hotspot, "")))
		return
	_goal.is_goal = false
	_goal.is_selected = true
	_hint_label.text = ""
	if Campaign.stage > 1:
		Campaign.clock_running = false
	SceneRouter.go_to(_goal_scene, 0.8)


func _update_date() -> void:
	var day := Campaign.day_number()
	if day == _shown_day:
		return
	_shown_day = day
	_date_label.text = Campaign.date_text()
	if Campaign.stage >= 11:
		_day_label.text = "DAY %d  ·  MISSION COMPLETE" % day
	elif Campaign.stage >= 9:
		_day_label.text = "DAY %d  ·  %d DAYS TO LAUNCH" % [day, maxi(int(Flight.build.get("launch_day", 0)) - int(Campaign.days), 0)]
	else:
		_day_label.text = "DAY %d  ·  %d DAYS TO LAUNCH" % [day, Campaign.days_left()]


func _show_hint(text: String) -> void:
	_hint_label.text = text
	_hint_label.modulate.a = 0.0
	create_tween().tween_property(_hint_label, "modulate:a", 1.0, 0.25)


func _num(value: float) -> String:
	return ("%.1f" % value).trim_suffix(".0")
