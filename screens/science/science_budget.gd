extends Control

const MARK_FONT := preload("res://assets/fonts/IBMPlexSans-Regular.woff2")
const BOLD_FONT := preload("res://assets/fonts/IBMPlexSans-SemiBold.woff2")

@onready var _bar: Control = %BudgetBar
@onready var _slider: HSlider = %CalcSlider
@onready var _calc_title: Label = %CalcTitle
@onready var _mark: Control = %RequestMark
@onready var _salary_value: Label = %SalaryValue
@onready var _calc_value: Label = %CalcValue
@onready var _left_value: Label = %LeftValue
@onready var _status_label: Label = %StatusLabel
@onready var _confirm_button: Button = %ConfirmButton
@onready var _date_label: Label = %DateLabel
@onready var _rounds: HBoxContainer = %Rounds


func _ready() -> void:
	_slider.max_value = float(Campaign.science()["max_pct"])
	_slider.value = 0.0
	_slider.value_changed.connect(func(_value: float) -> void: _refresh())
	_mark.draw.connect(_draw_mark)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_date_label.text = Campaign.date_text()
	_build_rounds()
	_refresh()
	_slider.grab_focus()


func _refresh() -> void:
	var salaries := Campaign.salaries_pct()
	var calc := _slider.value
	var left := 100.0 - salaries - calc
	_bar.call("set_parts", salaries, calc)
	_calc_title.text = "Calculations, all %s rounds: %d%%" % [_count_word(), roundi(calc)]
	_salary_value.text = "%d%%" % roundi(salaries)
	_calc_value.text = "%d%%" % roundi(calc)
	_left_value.text = "%d%%" % roundi(left)
	_status_label.text = "Calculations: USD %.1f billion  ·  Left for the next phases: USD %.1f billion" % [Campaign.billions(calc), Campaign.billions(left)]


func _build_rounds() -> void:
	var rounds := Campaign.calc_rounds()
	for index in rounds.size():
		var info: Dictionary = rounds[index]
		var is_now := index == Campaign.calc_round
		var style := StyleBoxFlat.new()
		style.bg_color = Color("e1f3f8") if is_now else Color("e1f3f8")
		style.border_color = Color("0b3d91") if is_now else Color("aeb0b5")
		style.border_width_left = 4
		style.content_margin_left = 16.0
		style.content_margin_right = 12.0
		style.content_margin_top = 8.0
		style.content_margin_bottom = 8.0
		var chip := PanelContainer.new()
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.add_theme_stylebox_override("panel", style)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 0)
		chip.add_child(box)
		box.add_child(_chip_label("%d  %s" % [index + 1, info.get("title", "")], BOLD_FONT, 18, Color("061f4a") if is_now else Color("323a45")))
		box.add_child(_chip_label(str(info.get("when", "")), MARK_FONT, 15, Color("323a45")))
		_rounds.add_child(chip)


func _chip_label(text: String, font: Font, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _count_word() -> String:
	var words := ["zero", "one", "two", "three", "four", "five", "six"]
	var count := Campaign.calc_rounds().size()
	return words[count] if count < words.size() else str(count)


func _draw_mark() -> void:
	var requested := float(Campaign.science()["requested_pct"])
	var grabber := 16.0
	var x := grabber * 0.5 + (_mark.size.x - grabber) * requested / _slider.max_value
	var ink := Color("323a45")
	_mark.draw_line(Vector2(x, 0.0), Vector2(x, 12.0), ink, 2.0)
	_mark.draw_string(MARK_FONT, Vector2(x - 150.0, 34.0), "Flight Dynamics asks for %d%%" % roundi(requested), HORIZONTAL_ALIGNMENT_CENTER, 300.0, 17, ink)
	_mark.draw_string(MARK_FONT, Vector2(0.0, 34.0), "0%", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, ink)
	_mark.draw_string(MARK_FONT, Vector2(_mark.size.x - 60.0, 34.0), "%d%%" % roundi(_slider.max_value), HORIZONTAL_ALIGNMENT_RIGHT, 60.0, 17, ink)


func _on_confirm_pressed() -> void:
	_confirm_button.disabled = true
	_slider.editable = false
	_confirm_button.text = "Confirmed"
	Campaign.fund_calculations(_slider.value)
	await get_tree().create_timer(0.5).timeout
	SceneRouter.go_to(SceneRouter.CALC_GAME, 0.6)
