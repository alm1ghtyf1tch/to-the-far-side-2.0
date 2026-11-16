extends Control

@onready var _game: Control = %Game
@onready var _start_button: Button = %StartButton
@onready var _skip_button: Button = %SkipButton
@onready var _status_label: Label = %StatusLabel
@onready var _date_label: Label = %DateLabel
@onready var _document_label: Label = %Document

var _start_days := 0.0


func _ready() -> void:
	if Campaign.research_days == 0:
		Campaign.fund_calculations(float(Campaign.science()["requested_pct"]))
	_start_days = Campaign.days
	_start_button.pressed.connect(_on_start_pressed)
	_skip_button.pressed.connect(_on_skip_pressed)
	_game.connect("finished", _on_finished)
	_document_label.text = "%s  %s" % [_round_text(), Campaign.current_round().get("title", "")]
	_status_label.text = "%s  ·  %d days of work planned" % [_round_text(), Campaign.research_days]
	_date_label.text = Campaign.date_text()
	_start_button.grab_focus()


func _process(_delta: float) -> void:
	if _game.call("is_running"):
		Campaign.days = _start_days + Campaign.research_days * float(_game.call("progress"))
		_date_label.text = Campaign.date_text()
		_status_label.text = "Calculating…  day %d of %d" % [int(Campaign.days - _start_days) + 1, Campaign.research_days]


func _round_text() -> String:
	return "Round %d of %d" % [mini(Campaign.calc_round + 1, Campaign.calc_rounds().size()), Campaign.calc_rounds().size()]


func _on_start_pressed() -> void:
	_start_button.visible = false
	_start_button.release_focus()
	_game.call("start")


func _on_skip_pressed() -> void:
	_start_button.visible = false
	_game.call("skip", float(Campaign.science()["skip_hit_rate"]))


func _on_finished(hits: int, total: int) -> void:
	_skip_button.disabled = true
	Campaign.days = _start_days + Campaign.research_days
	Campaign.finish_calculations(hits, total)
	_date_label.text = Campaign.date_text()
	_status_label.text = "Round complete  ·  %d of %d runs verified" % [hits, total]
	await get_tree().create_timer(1.2).timeout
	SceneRouter.go_to(SceneRouter.SCIENCE_REPORT, 0.6)
