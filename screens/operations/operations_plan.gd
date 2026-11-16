extends Control

const FONT := preload("res://assets/fonts/IBMPlexSans-Regular.woff2")
const FONT_BOLD := preload("res://assets/fonts/IBMPlexSans-SemiBold.woff2")
const FONT_MONO := preload("res://assets/fonts/IBMPlexMono-Regular.woff2")
const ART := "res://assets/textures/operations/%s.png"
const NAVY := Color("061f4a")
const BLUE := Color("0b3d91")
const RED := Color("dd361c")
const GOLD := Color("f2b632")
const INK := Color("212121")
const GRAY := Color("323a45")
const SILVER := Color("aeb0b5")
const PAPER := Color("e1f3f8")
const WHITE := Color("ffffff")
const COLORS := {
	"training": Color("0b3d91"), "control": Color("046b99"), "launch": Color("c62d1f"),
	"recovery": Color("105bd8"), "computer": Color("323a45"),
}

@onready var _box: VBoxContainer = %Box
@onready var _ack_button: Button = %AckButton
@onready var _status_label: Label = %StatusLabel
@onready var _date_label: Label = %DateLabel
@onready var _document_label: Label = %Document

var _choice := {}
var _cards := {}
var _segments := {}
var _spent_value: Label
var _reserve_value: Label
var _reserve_bar: ColorRect
var _read_more: ReadMore
var _available := 0.0


func _ready() -> void:
	if Campaign.stage != 8:
		Flight.quick_start(8)
	_read_more = ReadMore.new()
	add_child(_read_more)
	_available = Campaign.budget_left
	_choice = Operations.draft.duplicate()
	_date_label.text = Campaign.date_text()
	_document_label.text = "OPS-%d-001  Flight Operations Plan" % Campaign.year()
	_build()
	_ack_button.text = "Confirm plan"
	var idle := StyleBoxFlat.new()
	idle.bg_color = SILVER
	idle.set_corner_radius_all(4)
	idle.content_margin_left = 30.0
	idle.content_margin_right = 30.0
	idle.content_margin_top = 10.0
	idle.content_margin_bottom = 10.0
	_ack_button.add_theme_stylebox_override("disabled", idle)
	_ack_button.pressed.connect(_on_confirm_pressed)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Operations.draft = _choice.duplicate()
		Campaign.clock_running = true
		SceneRouter.go_to(SceneRouter.HQ)


func choose(item_id: String, level: int) -> void:
	_choice[item_id] = level
	Operations.draft = _choice.duplicate()
	_refresh()


func _on_confirm_pressed() -> void:
	if Operations.missing(_choice) > 0:
		return
	_ack_button.disabled = true
	_ack_button.text = "Confirmed"
	Operations.confirm(_choice)
	Campaign.clock_running = true
	_status_label.text = "Plan confirmed  ·  The vehicle goes into production"
	await get_tree().create_timer(0.8).timeout
	SceneRouter.go_to(SceneRouter.HQ, 0.6)


func _show_details(item: Dictionary) -> void:
	var topic: Dictionary = (item.get("read_more", {}) as Dictionary).duplicate()
	if topic.is_empty():
		return
	topic["title"] = str(item.get("title", ""))
	topic["image"] = ART % item.get("id", "")
	_read_more.offer(topic)
	_read_more.open()


func _build() -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 24)
	_box.add_child(head)
	var title := _label("Flight Operations Plan", FONT_BOLD, 26, INK)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(title)
	var intro := _label("The vehicle is paid for. What is left pays for the people who will fly it. Pick one level in each column. Whatever you do not spend stays in the reserve, and every problem found while the vehicle is built is paid from it.", FONT, 15, GRAY, true)
	intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(intro)
	_box.add_child(_rule(GOLD, 3))

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_box.add_child(columns)
	for item: Dictionary in Operations.items():
		columns.add_child(_build_column(item))

	var totals := HBoxContainer.new()
	totals.add_theme_constant_override("separation", 26)
	_box.add_child(totals)
	totals.add_child(_figure("LEFT AFTER THE VEHICLE", "%s%%  ·  $%sB" % [_num(_available), _num(Campaign.billions(_available))], INK))
	var spent := _figure("OPERATIONS", "", BLUE)
	_spent_value = spent.get_child(1) as Label
	totals.add_child(spent)
	var reserve := _figure("RESERVE", "", INK)
	_reserve_value = reserve.get_child(1) as Label
	totals.add_child(reserve)
	var bar_box := VBoxContainer.new()
	bar_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_box.alignment = BoxContainer.ALIGNMENT_CENTER
	bar_box.add_theme_constant_override("separation", 3)
	totals.add_child(bar_box)
	var bar := HBoxContainer.new()
	bar.custom_minimum_size = Vector2(0, 22)
	bar.add_theme_constant_override("separation", 2)
	bar_box.add_child(bar)
	for item: Dictionary in Operations.items():
		var segment := ColorRect.new()
		segment.color = COLORS.get(str(item["id"]), BLUE)
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segment.visible = false
		bar.add_child(segment)
		_segments[str(item["id"])] = segment
	_reserve_bar = ColorRect.new()
	_reserve_bar.color = Color("d6d7d9")
	_reserve_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(_reserve_bar)
	bar_box.add_child(_label("Each colour is one column above. The light part is the reserve.", FONT, 13, GRAY))


func _build_column(item: Dictionary) -> Control:
	var item_id := str(item["id"])
	var color: Color = COLORS.get(item_id, BLUE)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 0)

	var frame := Control.new()
	frame.custom_minimum_size = Vector2(0, 112)
	frame.clip_contents = true
	column.add_child(frame)
	var picture := TextureRect.new()
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path := ART % item_id
	if ResourceLoader.exists(path):
		picture.texture = load(path)
	frame.add_child(picture)
	var more := Button.new()
	more.text = "Read more ›"
	more.focus_mode = Control.FOCUS_NONE
	more.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	more.add_theme_font_override("font", FONT_BOLD)
	more.add_theme_font_size_override("font_size", 13)
	var chip_normal := StyleBoxFlat.new()
	chip_normal.bg_color = Color(NAVY, 0.88)
	chip_normal.content_margin_left = 9.0
	chip_normal.content_margin_right = 9.0
	chip_normal.content_margin_top = 3.0
	chip_normal.content_margin_bottom = 4.0
	var chip_hover := chip_normal.duplicate() as StyleBoxFlat
	chip_hover.bg_color = RED
	for state: String in ["normal", "focus", "disabled"]:
		more.add_theme_stylebox_override(state, chip_normal)
	for state: String in ["hover", "pressed", "hover_pressed"]:
		more.add_theme_stylebox_override(state, chip_hover)
	for state: String in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color"]:
		more.add_theme_color_override(state, WHITE)
	more.pressed.connect(_show_details.bind(item))
	more.visible = not (item.get("read_more", {}) as Dictionary).is_empty()
	frame.add_child(more)
	more.anchor_left = 1.0
	more.anchor_right = 1.0
	more.offset_left = -104.0
	more.offset_right = 0.0
	more.offset_top = 0.0
	more.offset_bottom = 26.0

	var band := PanelContainer.new()
	var band_style := StyleBoxFlat.new()
	band_style.bg_color = color
	band_style.content_margin_left = 12.0
	band_style.content_margin_right = 8.0
	band_style.content_margin_top = 5.0
	band_style.content_margin_bottom = 5.0
	band.add_theme_stylebox_override("panel", band_style)
	column.add_child(band)
	var title := _label(str(item["title"]), FONT_BOLD, 17, WHITE)
	title.clip_text = true
	band.add_child(title)

	var why_box := MarginContainer.new()
	why_box.add_theme_constant_override("margin_top", 6)
	why_box.add_theme_constant_override("margin_bottom", 6)
	column.add_child(why_box)
	var why := _label(str(item["why"]), FONT, 14, GRAY, true)
	why.custom_minimum_size = Vector2(0, 100)
	why.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	why_box.add_child(why)

	var cards: Array[Button] = []
	var levels: Array = item["levels"]
	for index in levels.size():
		var level: Dictionary = levels[index]
		var card := Button.new()
		card.custom_minimum_size = Vector2(0, 104)
		card.clip_contents = true
		card.focus_mode = Control.FOCUS_NONE
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.pressed.connect(choose.bind(item_id, index))
		var margin := MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_theme_constant_override("margin_left", 13)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_top", 7)
		margin.add_theme_constant_override("margin_bottom", 7)
		card.add_child(margin)
		var inner := VBoxContainer.new()
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_theme_constant_override("separation", 2)
		margin.add_child(inner)
		var top := HBoxContainer.new()
		top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_theme_constant_override("separation", 7)
		inner.add_child(top)
		var meter := HBoxContainer.new()
		meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		meter.add_theme_constant_override("separation", 2)
		meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		for bar_index in 3:
			var pip := ColorRect.new()
			pip.custom_minimum_size = Vector2(5, 8 + bar_index * 4)
			pip.size_flags_vertical = Control.SIZE_SHRINK_END
			pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			meter.add_child(pip)
		top.add_child(meter)
		var name_label := _label(str(level["name"]), FONT_BOLD, 15, INK)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.clip_text = true
		top.add_child(name_label)
		var price := _label("%s%%" % _num(float(level["cost_pct"])), FONT_MONO, 15, WHITE)
		var chip := PanelContainer.new()
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(price)
		top.add_child(chip)
		var what := _label(str(level["what"]), FONT, 14, GRAY, true)
		what.size_flags_vertical = Control.SIZE_EXPAND_FILL
		what.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		inner.add_child(what)
		column.add_child(card)
		if index < levels.size() - 1:
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(0, 7)
			column.add_child(gap)
		cards.append(card)
	_cards[item_id] = cards
	return column


func _refresh() -> void:
	for item_id: String in _cards:
		var cards: Array = _cards[item_id]
		for index in cards.size():
			_style_card(cards[index] as Button, COLORS.get(item_id, BLUE), index, int(_choice.get(item_id, -1)) == index)
	var spent := Operations.cost(_choice)
	var reserve := _available - spent
	var missing := Operations.missing(_choice)
	_spent_value.text = "%s%%  ·  $%sB" % [_num(spent), _num(snappedf(Campaign.billions(spent), 0.01))]
	_reserve_value.text = "%s%%  ·  $%sB" % [_num(reserve), _num(snappedf(Campaign.billions(reserve), 0.01))]
	_reserve_value.add_theme_color_override("font_color", RED if reserve < 0.0 else INK)
	for item: Dictionary in Operations.items():
		var item_id := str(item["id"])
		var segment: ColorRect = _segments[item_id]
		var level := int(_choice.get(item_id, -1))
		segment.visible = level >= 0
		if level >= 0:
			segment.size_flags_stretch_ratio = float((item["levels"] as Array)[level]["cost_pct"])
	_reserve_bar.visible = reserve > 0.01
	_reserve_bar.size_flags_stretch_ratio = maxf(reserve, 0.01)
	_ack_button.disabled = missing > 0
	if missing > 0:
		_status_label.text = "%d of %d columns still need a level." % [missing, Operations.items().size()]
	elif reserve < 0.0:
		_status_label.text = "This plan spends more than the budget has. The mission will go over budget."
	else:
		_status_label.text = "Every column has a level. The reserve is %s%% of the mission budget." % _num(reserve)


func _style_card(card: Button, color: Color, level: int, chosen: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = color if chosen else WHITE
	normal.border_color = color
	normal.border_width_left = 6
	normal.border_width_top = 2 if chosen else 1
	normal.border_width_right = 2 if chosen else 1
	normal.border_width_bottom = 2 if chosen else 1
	if not chosen:
		normal.border_color = SILVER
	var hover := normal.duplicate() as StyleBoxFlat
	if not chosen:
		hover.bg_color = PAPER
		hover.border_color = color
	for state: String in ["normal", "pressed", "focus"]:
		card.add_theme_stylebox_override(state, normal)
	card.add_theme_stylebox_override("hover", hover)
	var inner := card.get_child(0).get_child(0)
	var top := inner.get_child(0)
	var meter := top.get_child(0)
	for index in meter.get_child_count():
		var lit := index <= level
		(meter.get_child(index) as ColorRect).color = (WHITE if lit else Color(WHITE, 0.3)) if chosen else (color if lit else Color(SILVER, 0.6))
	(top.get_child(1) as Label).add_theme_color_override("font_color", WHITE if chosen else INK)
	var chip := top.get_child(2) as PanelContainer
	var chip_style := StyleBoxFlat.new()
	chip_style.bg_color = WHITE if chosen else color
	chip_style.set_corner_radius_all(3)
	chip_style.content_margin_left = 5.0
	chip_style.content_margin_right = 5.0
	chip_style.content_margin_top = 0.0
	chip_style.content_margin_bottom = 1.0
	chip.add_theme_stylebox_override("panel", chip_style)
	(chip.get_child(0) as Label).add_theme_color_override("font_color", color if chosen else WHITE)
	(inner.get_child(1) as Label).add_theme_color_override("font_color", Color(WHITE, 0.92) if chosen else GRAY)


func _figure(caption: String, value: String, color: Color) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 0)
	box.add_child(_label(caption, FONT_BOLD, 13, GRAY))
	box.add_child(_label(value, FONT_MONO, 20, color))
	return box


func _rule(color: Color, height: int) -> ColorRect:
	var line := ColorRect.new()
	line.color = color
	line.custom_minimum_size = Vector2(0, height)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


func _label(text: String, font: Font, size: int, color: Color, wrap := false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _num(value: float) -> String:
	return ("%.2f" % value).trim_suffix("0").trim_suffix("0").trim_suffix(".")
