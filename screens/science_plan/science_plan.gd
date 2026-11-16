extends Control

const FONT := preload("res://assets/fonts/IBMPlexSans-Regular.woff2")
const FONT_BOLD := preload("res://assets/fonts/IBMPlexSans-SemiBold.woff2")
const PICTURES := "res://assets/textures/catalog/"
const PHOTOS := "res://assets/textures/catalog/photos/"
const INK := Color("212121")
const MUTED := Color("323a45")
const BLUE := Color("0b3d91")
const PHOTO_HEIGHT := 136.0
const MAP_HINT := "Click a red dot to choose a site. North is up."
const INTRO := [
	"Step 1 of 2  ·  Choose where the crew will land. All six are real Apollo landing sites. Richer science comes with a harder landing.",
	"Step 2 of 2  ·  Choose what the crew will take. Every item adds mass, needs power and costs money. Scroll down for the newest instruments.",
]

@onready var _site_tab: Button = %SiteTab
@onready var _gear_tab: Button = %GearTab
@onready var _map_button: Button = %MapButton
@onready var _intro: Label = %Intro
@onready var _site_grid: GridContainer = %SiteGrid
@onready var _gear_grid: GridContainer = %GearGrid
@onready var _science_value: Label = %ScienceValue
@onready var _mass_value: Label = %MassValue
@onready var _power_value: Label = %PowerValue
@onready var _cost_value: Label = %CostValue
@onready var _left_value: Label = %LeftValue
@onready var _status_label: Label = %StatusLabel
@onready var _confirm_button: Button = %ConfirmButton
@onready var _date_label: Label = %DateLabel

var _step := 0
var _site_index := -1
var _picked: Array[bool] = []
var _locked := false
var _site_cards: Array[Dictionary] = []
var _gear_cards: Array[Dictionary] = []
var _read_more: ReadMore
var _map_layer: CanvasLayer
var _map_window: PanelContainer
var _map: SiteMap
var _gear_scroll: ScrollContainer


func _ready() -> void:
	_date_label.text = Campaign.date_text()
	_read_more = ReadMore.new()
	add_child(_read_more)
	var sites := Campaign.sites()
	for index in sites.size():
		var site: Dictionary = sites[index]
		var card := _make_card(site, _picture("site_%s" % site.get("id", "")), "%s site" % site.get("mission", ""),
				str(site.get("name", "")), str(site.get("what", "")), _site_specs(site), "Select", select_site.bind(index))
		_site_grid.add_child(card["panel"])
		_site_cards.append(card)
	var options := Campaign.instrument_options()
	for index in options.size():
		var item: Dictionary = options[index]
		_picked.append(false)
		var era := str(item.get("era", ""))
		var card := _make_card(item, _picture(str(item.get("id", ""))), "" if era.is_empty() else "%s era" % era, str(item.get("name", "")),
				str(item.get("what", "")), _gear_specs(item), "Add", toggle_instrument.bind(index))
		(card["panel"] as Control).custom_minimum_size = Vector2(0.0, 262.0)
		(card["panel"] as Control).size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		_gear_grid.add_child(card["panel"])
		_gear_cards.append(card)
	_gear_scroll = ScrollContainer.new()
	_gear_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_gear_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_gear_scroll.visible = false
	var grid_parent := _gear_grid.get_parent()
	grid_parent.add_child(_gear_scroll)
	grid_parent.move_child(_gear_scroll, _gear_grid.get_index())
	_gear_grid.reparent(_gear_scroll)
	_gear_grid.visible = true
	_gear_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build_map()
	_map_button.pressed.connect(_toggle_map)
	_site_tab.pressed.connect(show_step.bind(0))
	_gear_tab.pressed.connect(show_step.bind(1))
	_confirm_button.pressed.connect(_on_confirm_pressed)
	show_step(0)


func show_step(step: int) -> void:
	if _locked:
		return
	_step = step
	_site_grid.visible = step == 0
	_gear_scroll.visible = step == 1
	_map_button.visible = step == 0
	if step == 1 and _map_window.visible:
		_toggle_map()
	_intro.text = INTRO[step]
	_refresh()


func select_site(index: int) -> void:
	if _locked:
		return
	_site_index = index
	_offer(Campaign.sites()[index])
	_refresh()


func toggle_instrument(index: int) -> void:
	if _locked:
		return
	_picked[index] = not _picked[index]
	_offer(Campaign.instrument_options()[index])
	_refresh()


func _picture(file_name: String) -> String:
	for extension: String in ["jpg", "jpeg", "png", "webp"]:
		var photo := "%s%s.%s" % [PHOTOS, file_name, extension]
		if ResourceLoader.exists(photo):
			return photo
	var drawing := "%s%s.png" % [PICTURES, file_name]
	return drawing if ResourceLoader.exists(drawing) else ""


func _offer(item: Dictionary) -> void:
	var topic: Dictionary = (item.get("read_more", {}) as Dictionary).duplicate()
	if topic.is_empty():
		return
	topic["title"] = str(item.get("name", ""))
	var is_site := item.has("mission")
	topic["image"] = _picture(("site_%s" if is_site else "%s") % item.get("id", ""))
	topic["image_note"] = "" if str(topic["image"]).begins_with(PHOTOS) else "Illustration made for this game, not a photograph."
	_read_more.offer(topic)


func _show_details(item: Dictionary) -> void:
	_offer(item)
	_read_more.open()


func _chosen() -> Array:
	var options := Campaign.instrument_options()
	var chosen := []
	for index in options.size():
		if _picked[index]:
			chosen.append(options[index])
	return chosen


func _refresh() -> void:
	for index in _site_cards.size():
		_mark(_site_cards[index], index == _site_index, "Select", "Selected  ✓")
	for index in _gear_cards.size():
		_mark(_gear_cards[index], _picked[index], "Add", "Remove")
	_map.selected = _site_index
	var site: Dictionary = Campaign.sites()[_site_index] if _site_index >= 0 else {}
	var chosen := _chosen()
	var totals := Campaign.plan_totals(site, chosen)
	_science_value.text = "%d" % int(totals["science"])
	_mass_value.text = "%d kg" % roundi(totals["mass"])
	_power_value.text = "%d W" % roundi(totals["power"])
	_cost_value.text = "%s%%" % _num(totals["cost"])
	_left_value.text = "%s%%" % _num(Campaign.budget_left - float(totals["cost"]))
	_site_tab.text = "1  Landing site" + ("  ✓" if _site_index >= 0 else "")
	_gear_tab.text = "2  Equipment  (%d)" % chosen.size()
	_style_tab(_site_tab, _step == 0)
	_style_tab(_gear_tab, _step == 1)
	_confirm_button.text = "Next: equipment  ›" if _step == 0 else "Confirm plan"
	_confirm_button.disabled = _site_index < 0
	if _site_index < 0:
		_status_label.text = "Choose a landing site to continue" if _step == 0 else "Go back to step 1 and choose a landing site"
	else:
		_status_label.text = "%s (%s site)  ·  %d items  ·  USD %.2f billion" % [site.get("name", ""), site.get("mission", ""), chosen.size(), Campaign.billions(float(totals["cost"]))]


func _on_confirm_pressed() -> void:
	if _step == 0:
		show_step(1)
		return
	_locked = true
	_confirm_button.disabled = true
	_confirm_button.text = "Confirmed"
	_map_window.visible = false
	_read_more.clear()
	Campaign.set_science_plan(Campaign.sites()[_site_index], _chosen())
	Campaign.clock_running = true
	await get_tree().create_timer(0.6).timeout
	SceneRouter.go_to(SceneRouter.HQ, 0.6)


func _site_specs(site: Dictionary) -> String:
	var extra := float(site.get("extra_dv", 0.0))
	var speed := "none" if extra <= 0.0 else "+%s km/s" % ("%.2f" % extra).trim_suffix("0")
	return "Risk: %s   ·   Extra speed: %s" % [site.get("risk", ""), speed]


func _gear_specs(item: Dictionary) -> String:
	var power := float(item.get("power_w", 0.0))
	return "%d kg  ·  %s  ·  cost %s%%" % [roundi(float(item.get("mass_kg", 0.0))),
			"no power" if power <= 0.0 else "%d W" % roundi(power), _num(float(item.get("cost_pct", 0.0)))]


func _make_card(item: Dictionary, picture: String, tag: String, title: String, text: String, specs: String, action_text: String, action: Callable) -> Dictionary:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.gui_input.connect(_on_card_input.bind(action))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	var photo := Control.new()
	photo.custom_minimum_size = Vector2(0.0, PHOTO_HEIGHT)
	photo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	photo.clip_contents = true
	photo.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_child(photo)
	var backdrop := ColorRect.new()
	backdrop.color = Color("212121")
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	photo.add_child(backdrop)
	if not picture.is_empty():
		var image := TextureRect.new()
		image.texture = load(picture)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		photo.add_child(image)
	var overlay := MarginContainer.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]:
		overlay.add_theme_constant_override("margin_" + side, 8)
	photo.add_child(overlay)
	var corners := VBoxContainer.new()
	corners.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(corners)
	var top_row := HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corners.add_child(top_row)
	if not tag.is_empty():
		top_row.add_child(_chip(tag.to_upper(), Color(0.04, 0.07, 0.13, 0.82), Color("ffffff")))
	top_row.add_child(_spacer())
	top_row.add_child(_chip("+%d science" % int(item.get("science", 0)), Color(BLUE, 0.92), Color.WHITE))
	var gap := _spacer()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corners.add_child(gap)
	var bottom_row := HBoxContainer.new()
	bottom_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corners.add_child(bottom_row)
	var ribbon := _chip("✓  IN THE PLAN", Color("046b99"), Color.WHITE)
	ribbon.visible = false
	bottom_row.add_child(ribbon)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	box.add_child(title_row)
	var title_label := _label(title, FONT_BOLD, 18, INK)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.clip_text = true
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_row.add_child(title_label)
	var details := Button.new()
	details.text = "Details  ›"
	details.focus_mode = Control.FOCUS_NONE
	details.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	details.add_theme_font_override("font", FONT_BOLD)
	details.add_theme_font_size_override("font_size", 15)
	for state: String in ["font_color", "font_pressed_color", "font_focus_color"]:
		details.add_theme_color_override(state, BLUE)
	details.add_theme_color_override("font_hover_color", Color("105bd8"))
	for state: String in ["normal", "hover", "pressed", "focus"]:
		details.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	details.pressed.connect(_show_details.bind(item))
	title_row.add_child(details)

	var text_label := _label(text, FONT, 14, MUTED, true)
	text_label.custom_minimum_size = Vector2(0.0, 46.0)
	text_label.max_lines_visible = 2
	box.add_child(text_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var specs_label := _label(specs, FONT_BOLD, 14, BLUE)
	specs_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	specs_label.clip_text = true
	row.add_child(specs_label)
	var action_button := Button.new()
	action_button.text = action_text
	action_button.custom_minimum_size = Vector2(124.0 if action_text == "Select" else 96.0, 0.0)
	action_button.focus_mode = Control.FOCUS_NONE
	action_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	action_button.add_theme_font_override("font", FONT_BOLD)
	action_button.add_theme_font_size_override("font_size", 15)
	action_button.pressed.connect(func() -> void:
		if not _locked:
			action.call())
	row.add_child(action_button)
	return {"panel": panel, "action": action_button, "ribbon": ribbon}


func _mark(card: Dictionary, chosen: bool, text: String, chosen_text: String) -> void:
	var panel: PanelContainer = card["panel"]
	var style := StyleBoxFlat.new()
	style.bg_color = Color("e1f3f8") if chosen else Color("ffffff")
	style.border_color = BLUE if chosen else Color("aeb0b5")
	style.set_border_width_all(2 if chosen else 1)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(8.0 if chosen else 9.0)
	panel.add_theme_stylebox_override("panel", style)
	(card["ribbon"] as Control).visible = chosen
	var button: Button = card["action"]
	button.text = chosen_text if chosen else text
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color.WHITE if chosen else BLUE
	fill.border_color = BLUE
	fill.set_border_width_all(2)
	fill.set_corner_radius_all(4)
	fill.content_margin_left = 12.0
	fill.content_margin_right = 12.0
	fill.content_margin_top = 4.0
	fill.content_margin_bottom = 4.0
	var hover := fill.duplicate() as StyleBoxFlat
	hover.bg_color = Color("9bdaf1") if chosen else Color("105bd8")
	button.add_theme_stylebox_override("normal", fill)
	button.add_theme_stylebox_override("pressed", fill)
	button.add_theme_stylebox_override("hover", hover)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, BLUE if chosen else Color.WHITE)


func _style_tab(tab: Button, active: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = BLUE if active else Color("e1f3f8")
	style.border_color = BLUE if active else Color("aeb0b5")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	for state: String in ["normal", "hover", "pressed"]:
		tab.add_theme_stylebox_override(state, style)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		tab.add_theme_color_override(state, Color.WHITE if active else BLUE)


func _on_card_input(event: InputEvent, action: Callable) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT and not _locked:
		action.call()


func _build_map() -> void:
	_map_layer = CanvasLayer.new()
	_map_layer.layer = 40
	add_child(_map_layer)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("061f4a")
	style.border_color = Color("105bd8")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(14.0)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 14
	_map_window = PanelContainer.new()
	_map_window.position = Vector2(16.0, 12.0)
	_map_window.add_theme_stylebox_override("panel", style)
	_map_window.visible = false
	_map_layer.add_child(_map_window)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_map_window.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	var title := _label("Landing sites  ·  near side of the Moon", FONT_BOLD, 18, Color("ffffff"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close_button := Button.new()
	close_button.text = "Close  ×"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_button.add_theme_font_override("font", FONT_BOLD)
	close_button.add_theme_font_size_override("font_size", 16)
	close_button.add_theme_color_override("font_color", Color("02bfe7"))
	close_button.add_theme_color_override("font_hover_color", Color.WHITE)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		close_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	close_button.pressed.connect(_toggle_map)
	head.add_child(close_button)
	_map = SiteMap.new()
	_map.custom_minimum_size = Vector2(660.0, 660.0)
	_map.sites = Campaign.sites()
	_map.site_clicked.connect(select_site)
	box.add_child(_map)
	var caption := _label(MAP_HINT, FONT_BOLD, 16, Color("aeb0b5"))
	box.add_child(caption)
	_map.caption_changed.connect(func(text: String) -> void:
		caption.text = MAP_HINT if text.is_empty() else text
		caption.add_theme_color_override("font_color", Color("aeb0b5") if text.is_empty() else Color("e59892")))


func _toggle_map() -> void:
	_map_window.visible = not _map_window.visible
	_map_button.text = "Close the Moon map" if _map_window.visible else "Open the Moon map"


func _chip(text: String, fill: Color, color: Color) -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(3)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 1.0
	style.content_margin_bottom = 2.0
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", style)
	chip.add_child(_label(text, FONT_BOLD, 13, color))
	return chip


func _spacer() -> Control:
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spacer


func _label(text: String, font: Font, font_size: int, color: Color, wrap := false) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _num(value: float) -> String:
	return ("%.1f" % value).trim_suffix(".0")
