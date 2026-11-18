class_name AssemblyOverlay
extends Control
## Floating controls laid over a full-screen world; no reserved scene column.

signal slot_requested(slot: String)
signal sheet_requested(part: Dictionary)
signal notes_requested(part: Dictionary)
signal install_requested(part: String)

var sections: RetractablePanel
var metrics: RetractablePanel
var tray: RetractablePanel
var section_buttons := {}
var values := {}
var gauges := {}
var cards: GridContainer
var title: Label
var why: Label
var progress: Label
var budget: Label
var status: Label
var reserve_note: Label
var warnings: Label
var hand_over: Button
var callout: Label
var sheet: Control
var sheet_part := {}
var _sheet_title: Label
var _sheet_text: Label
var _sheet_specs: VBoxContainer
var _focus_button: Button
var _focused := false


func _ready() -> void:
	theme = VisualTheme.shared()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_edge_shade(true)
	_edge_shade(false)
	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 76
	header.offset_top = 54
	header.offset_right = -76
	add_child(header)
	var heading := VBoxContainer.new()
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	heading.add_child(label("ENGINEERING  /  VEHICLE INTEGRATION", 14, VisualTheme.CYAN, VisualTheme.MONO))
	heading.add_child(label("Build the journey", 40, VisualTheme.PAPER, VisualTheme.DISPLAY))
	var information := VBoxContainer.new()
	information.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(information)
	budget = label("", 20, VisualTheme.AMBER, VisualTheme.MONO)
	information.add_child(budget)
	information.add_child(label(Campaign.date_text() + "  /  DEADLINE " + Campaign.deadline_text(), 15, VisualTheme.MUTED))
	sections = _edge_panel("Sections", "left")
	metrics = _edge_panel("Vehicle check", "right")
	tray = _edge_panel("Parts rack", "right")
	var section_scroll := ScrollContainer.new()
	section_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	section_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sections.content.add_child(section_scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 5)
	section_scroll.add_child(list)
	var group := ""
	for index in Vehicle.slots().size():
		var slot: Dictionary = Vehicle.slots()[index]
		if str(slot.get("group", "")) != group:
			group = str(slot["group"])
			list.add_child(label(group.to_upper(), 13, VisualTheme.CYAN, VisualTheme.MONO))
		var button := button("%02d  %s" % [index + 1, slot["title"]], 42)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 17)
		button.pressed.connect(func() -> void: slot_requested.emit(str(slot["id"])))
		list.add_child(button)
		section_buttons[str(slot["id"])] = button
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	metrics.content.add_child(scroll)
	var figures := VBoxContainer.new()
	figures.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	figures.add_theme_constant_override("separation", 6)
	scroll.add_child(figures)
	for row: Array in [["rocket", "ROCKET Δv", true], ["ship", "SPACECRAFT Δv", true], ["cargo", "LUNAR PAYLOAD", true], ["power", "ELECTRICAL POWER", true], ["liftoff", "LIFT-OFF MASS / TWR", false], ["propellant", "PROPELLANT", false], ["crew", "CREW / MISSION LENGTH", false], ["supplies", "AIR, WATER & FOOD", false], ["suits", "TIME OUTSIDE", false], ["cost", "VEHICLE COST", false], ["people", "PEOPLE & FACILITIES", false], ["ready", "READY TO LAUNCH", false], ["reliability", "PREDICTED RELIABILITY", false]]:
		figures.add_child(label(row[1], 12, VisualTheme.MUTED, VisualTheme.MONO))
		var value := label("—", 17, VisualTheme.PAPER)
		value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		figures.add_child(value)
		values[row[0]] = value
		if row[2]:
			var gauge := GaugeBar.new()
			gauge.custom_minimum_size.y = 13
			figures.add_child(gauge)
			gauges[row[0]] = gauge
	warnings = label("", 15, VisualTheme.AMBER)
	warnings.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	figures.add_child(warnings)
	reserve_note = label("", 14, VisualTheme.MUTED)
	reserve_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	figures.add_child(reserve_note)
	title = label("", 24, VisualTheme.PAPER, VisualTheme.DISPLAY)
	tray.content.add_child(title)
	why = label("", 15, VisualTheme.MUTED)
	why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	why.max_lines_visible = 2
	why.mouse_filter = Control.MOUSE_FILTER_PASS
	tray.content.add_child(why)
	var rack_scroll := ScrollContainer.new()
	rack_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rack_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tray.content.add_child(rack_scroll)
	cards = GridContainer.new()
	cards.columns = 2
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("h_separation", 10)
	cards.add_theme_constant_override("v_separation", 10)
	rack_scroll.add_child(cards)
	callout = label("", 16, VisualTheme.AMBER, VisualTheme.MONO)
	callout.custom_minimum_size.x = 220
	callout.add_theme_stylebox_override("normal", VisualTheme.surface(Color(0.035, 0.07, 0.11, 0.9), Color("70909e"), 12))
	add_child(callout)
	var footer := HBoxContainer.new()
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 76
	footer.offset_right = -76
	footer.offset_top = -100
	footer.offset_bottom = -48
	footer.add_theme_constant_override("separation", 16)
	add_child(footer)
	var notes := VBoxContainer.new()
	notes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(notes)
	progress = label("", 17, VisualTheme.PAPER, VisualTheme.MONO)
	notes.add_child(progress)
	status = label("", 15, VisualTheme.AMBER)
	notes.add_child(status)
	_focus_button = button("Focus on vehicle", 48)
	_focus_button.pressed.connect(toggle_focus)
	footer.add_child(_focus_button)
	hand_over = button("Hand over to the Board  ›", 48)
	hand_over.custom_minimum_size.x = 310
	footer.add_child(hand_over)
	_build_sheet()
	resized.connect(_place_panels)
	_place_panels()


func _edge_shade(top: bool) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.02, 0.045, 0.075, 0.88), Color(0.02, 0.045, 0.075, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 1
	texture.height = 160
	texture.fill_from = Vector2(0, 0 if top else 1)
	texture.fill_to = Vector2(0, 1 if top else 0)
	var shade := TextureRect.new()
	shade.texture = texture
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
	shade.offset_top = 0 if top else -130
	shade.offset_bottom = 160 if top else 0
	add_child(shade)


func _edge_panel(text: String, edge: String) -> RetractablePanel:
	var panel := RetractablePanel.new()
	panel.title = text
	panel.edge = edge
	add_child(panel)
	return panel


func _place_panels() -> void:
	sections.position = Vector2(76, 150)
	sections.size = Vector2(260, maxf(440, size.y - 270))
	metrics.position = Vector2(size.x - 510, 150)
	metrics.size = Vector2(434, 350)
	tray.position = Vector2(size.x - 616, 510)
	tray.size = Vector2(540, maxf(330, size.y - 630))


func toggle_focus() -> void:
	_focused = not _focused
	for panel: RetractablePanel in [sections, metrics, tray]:
		panel.set_open(not _focused)
	_focus_button.text = "Show controls" if _focused else "Focus on vehicle"


func _build_sheet() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 42
	add_child(layer)
	sheet = Control.new()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(sheet)
	var dark := ColorRect.new()
	dark.color = Color(0.015, 0.035, 0.06, 0.78)
	dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.add_child(dark)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + edge, 460)
	for edge: String in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 120)
	sheet.add_child(margin)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", VisualTheme.surface(Color("142737"), VisualTheme.CYAN, 24))
	margin.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var close := button("TECHNICAL SHEET   /   Close ×", 42)
	close.pressed.connect(sheet.hide)
	box.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	scroll.add_child(body)
	_sheet_title = label("", 34, VisualTheme.PAPER, VisualTheme.DISPLAY)
	_sheet_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_sheet_title)
	_sheet_text = label("", 21, VisualTheme.MUTED)
	_sheet_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_sheet_text)
	_sheet_specs = VBoxContainer.new()
	_sheet_specs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_sheet_specs)
	var actions := HBoxContainer.new()
	box.add_child(actions)
	var read := button("Read the science & history  ›", 48)
	read.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	read.pressed.connect(func() -> void: notes_requested.emit(sheet_part))
	actions.add_child(read)
	var install := button("Install / remove", 48)
	install.pressed.connect(func() -> void:
		sheet.hide()
		install_requested.emit(str(sheet_part["id"])))
	actions.add_child(install)
	sheet.hide()


func show_sheet(part: Dictionary) -> void:
	sheet_part = part
	_sheet_title.text = str(part.get("name", ""))
	_sheet_text.text = str(part.get("what", ""))
	for child in _sheet_specs.get_children():
		_sheet_specs.remove_child(child)
		child.queue_free()
	for spec: Array in part.get("specs", []):
		var value := label("%s    %s" % [spec[0], spec[1]], 20, VisualTheme.PAPER, VisualTheme.MONO)
		value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_sheet_specs.add_child(value)
	UiMotion.reveal(sheet, 0.22)


func label(text: String, font_size: int, color: Color, font: Font = VisualTheme.BODY) -> Label:
	var result := Label.new()
	result.text = text
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_override("font", font)
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	return result


func button(text: String, height: float) -> TactileButton:
	var result := TactileButton.new()
	result.text = text
	result.custom_minimum_size.y = height
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.add_theme_font_size_override("font_size", 18)
	return result
