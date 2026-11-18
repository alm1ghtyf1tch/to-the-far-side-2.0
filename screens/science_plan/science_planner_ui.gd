class_name SciencePlannerUI
extends Control
## Terminal layout and display controls. No simulation calculations or writes.

var lunar: LunarScene3D
var lunar_viewport: SubViewport
var site_tab: Button
var gear_tab: Button
var map_button: Button
var confirm: Button
var details: Button
var site_grid: GridContainer
var gear_grid: GridContainer
var gear_scroll: ScrollContainer
var inspector: VBoxContainer
var inspector_title: Label
var inspector_tag: Label
var inspector_body: Label
var inspector_specs: Label
var selected_label: Label
var intro: Label
var status: Label
var tray: HFlowContainer
var tray_panel: PanelContainer
var values := {}
var moon_panel: PanelContainer
var right_panel: PanelContainer
var _main: HBoxContainer
var _right: VBoxContainer
var _moon_slot: Control
var _inspector_gap: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = VisualTheme.shared()
	var background := ColorRect.new()
	background.color = Color("141d28")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + edge, 86)
	for edge: String in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 62)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 24)
	box.add_child(header)
	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	brand.add_child(label("LUNAR SCIENCE DIVISION   /   FLIGHT PLANNING TERMINAL", 14, VisualTheme.CYAN, VisualTheme.MONO))
	brand.add_child(label("Choose our next horizon", 42, VisualTheme.PAPER, VisualTheme.DISPLAY))
	var date := label("MISSION DATE\n" + Campaign.date_text(), 17, VisualTheme.MUTED, VisualTheme.MONO)
	date.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(date)
	var navigation := HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 12)
	box.add_child(navigation)
	site_tab = button("01   LANDING SITE", 240)
	gear_tab = button("02   SCIENCE PAYLOAD", 285)
	map_button = button("Reference map  ↗", 220)
	navigation.add_child(site_tab)
	navigation.add_child(gear_tab)
	intro = label("", 16, VisualTheme.MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation.add_child(intro)
	navigation.add_child(map_button)
	_main = HBoxContainer.new()
	_main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_main.add_theme_constant_override("separation", 14)
	box.add_child(_main)
	moon_panel = panel(Color("070e19"))
	moon_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	moon_panel.size_flags_stretch_ratio = 2.15
	_main.add_child(moon_panel)
	var moon_box := VBoxContainer.new()
	moon_box.add_theme_constant_override("separation", 2)
	moon_panel.add_child(moon_box)
	moon_box.add_child(label("◉  LUNAR RECONNAISSANCE     /     NORTH UP · EAST RIGHT", 13, VisualTheme.MUTED, VisualTheme.MONO))
	_moon_slot = Control.new()
	_moon_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	moon_box.add_child(_moon_slot)
	lunar_viewport = SubViewport.new()
	lunar_viewport.name = "LunarSubViewport"
	lunar_viewport.own_world_3d = true
	lunar_viewport.size = Vector2i(1120, 550)
	lunar_viewport.msaa_3d = Viewport.MSAA_2X
	lunar_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_moon_slot.add_child(lunar_viewport)
	lunar = preload("res://environments/lunar/lunar_scene.tscn").instantiate()
	lunar_viewport.add_child(lunar)
	var image := TextureRect.new()
	image.texture = lunar_viewport.get_texture()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moon_slot.add_child(image)
	var annotations := preload("res://environments/lunar/lunar_annotations.gd").new()
	annotations.scene = lunar
	annotations.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_moon_slot.add_child(annotations)
	_moon_slot.resized.connect(func() -> void:
		lunar_viewport.size = Vector2i(_moon_slot.size).max(Vector2i.ONE))
	moon_box.add_child(label("LRO / LOLA SURFACE DATA   ·   RELIEF ×2.2   ·   ARTISTIC EDGE LIGHT", 12, Color("71868d"), VisualTheme.MONO))
	right_panel = panel(Color("18232e"))
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main.add_child(right_panel)
	_right = VBoxContainer.new()
	_right.add_theme_constant_override("separation", 12)
	right_panel.add_child(_right)
	inspector = VBoxContainer.new()
	inspector.add_theme_constant_override("separation", 16)
	_right.add_child(inspector)
	inspector_tag = label("MISSION DESTINATION", 15, VisualTheme.CYAN, VisualTheme.MONO)
	inspector.add_child(inspector_tag)
	inspector_title = label("Six sites.\nOne expedition.", 38, VisualTheme.PAPER, VisualTheme.DISPLAY)
	inspector_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspector.add_child(inspector_title)
	inspector_body = label("", 20, Color("c0cdd0"))
	inspector_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspector.add_child(inspector_body)
	inspector_specs = label("", 17, VisualTheme.PAPER, VisualTheme.MONO)
	inspector_specs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspector.add_child(inspector_specs)
	details = button("Field notes & scientific context  ›")
	inspector.add_child(details)
	_inspector_gap = Control.new()
	_inspector_gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right.add_child(_inspector_gap)
	selected_label = label("DESTINATION  /  AWAITING SELECTION", 15, VisualTheme.AMBER, VisualTheme.MONO)
	selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_right.add_child(selected_label)
	gear_scroll = ScrollContainer.new()
	gear_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	gear_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right.add_child(gear_scroll)
	gear_grid = GridContainer.new()
	gear_grid.columns = 3
	gear_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gear_grid.add_theme_constant_override("h_separation", 10)
	gear_grid.add_theme_constant_override("v_separation", 10)
	gear_scroll.add_child(gear_grid)
	site_grid = GridContainer.new()
	site_grid.columns = 6
	site_grid.add_theme_constant_override("h_separation", 12)
	box.add_child(site_grid)
	tray_panel = panel(Color("101c27"))
	box.add_child(tray_panel)
	var tray_box := VBoxContainer.new()
	tray_panel.add_child(tray_box)
	tray_box.add_child(label("PAYLOAD MANIFEST   /   CLICK AN INSTALLED ITEM TO REMOVE", 13, VisualTheme.MUTED, VisualTheme.MONO))
	tray = HFlowContainer.new()
	tray.custom_minimum_size.y = 42
	tray.add_theme_constant_override("h_separation", 8)
	tray_box.add_child(tray)
	var footer := panel(Color("202c36"))
	box.add_child(footer)
	var footer_row := HBoxContainer.new()
	footer_row.add_theme_constant_override("separation", 26)
	footer.add_child(footer_row)
	for entry: Array in [["science", "SCIENCE VALUE"], ["mass", "PAYLOAD MASS"], ["power", "POWER DRAW"], ["cost", "PAYLOAD COST"], ["left", "BUDGET AFTER PLAN"]]:
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		footer_row.add_child(column)
		column.add_child(label(entry[1], 12, VisualTheme.MUTED, VisualTheme.MONO))
		var value := label("0", 26, VisualTheme.AMBER if entry[0] == "science" else VisualTheme.PAPER, VisualTheme.MONO)
		column.add_child(value)
		values[entry[0]] = value
	confirm = button("Next: equipment  ›", 270)
	footer_row.add_child(confirm)
	status = label("", 14, VisualTheme.MUTED)
	box.add_child(status)


func show_step(step: int) -> void:
	site_grid.visible = step == 0
	inspector.visible = step == 0
	_inspector_gap.visible = step == 0
	gear_scroll.visible = step == 1
	tray_panel.visible = step == 1
	map_button.visible = step == 0
	moon_panel.size_flags_stretch_ratio = 2.15 if step == 0 else 1.0
	right_panel.size_flags_stretch_ratio = 1.0 if step == 0 else 1.45
	intro.text = "Hover to survey. Click to choose." if step == 0 else "Select your instruments. Scroll for all 11."
	site_tab.add_theme_color_override("font_color", VisualTheme.AMBER if step == 0 else VisualTheme.MUTED)
	gear_tab.add_theme_color_override("font_color", VisualTheme.AMBER if step == 1 else VisualTheme.MUTED)
	UiMotion.reveal(right_panel, 0.24)
	UiMotion.reveal(site_grid if step == 0 else tray_panel, 0.24)


func label(text: String, font_size: int, color: Color, font: Font = VisualTheme.BODY) -> Label:
	var result := Label.new()
	result.text = text
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_override("font", font)
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	return result


func button(text: String, width := 0.0) -> TactileButton:
	var result := TactileButton.new()
	result.text = text
	result.custom_minimum_size = Vector2(width, 46)
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.add_theme_font_size_override("font_size", 18)
	return result


func panel(color: Color) -> PanelContainer:
	var result := preload("res://ui/components/terminal_panel.gd").new()
	result.add_theme_stylebox_override("panel", VisualTheme.surface(color, Color("46535e"), 16))
	return result
