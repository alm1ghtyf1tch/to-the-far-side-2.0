class_name AssemblyOptionCard
extends TactileButton
## Stable input rectangle with a springy, illustrated face and explicit removal.

signal install_requested
signal details_requested
var part := {}
var installed := false


func _ready() -> void:
	theme = VisualTheme.shared()
	toggle_mode = true
	custom_minimum_size = Vector2(0, 274)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_stylebox_override("normal", VisualTheme.surface(Color("1a2c3a"), Color("536675"), 10))
	add_theme_stylebox_override("hover", VisualTheme.surface(Color("243d4d"), VisualTheme.CYAN, 10))
	add_theme_stylebox_override("pressed", VisualTheme.surface(Color("314044"), VisualTheme.AMBER, 10))
	super._ready()
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	_face.add_child(margin)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)
	box.add_child(_label("● INSTALLED" if installed else "○ AVAILABLE", 12, VisualTheme.AMBER if installed else VisualTheme.CYAN))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	var path := "res://assets/textures/vehicle/thumb_%s.png" % part.get("id", "")
	if ResourceLoader.exists(path):
		var image := TextureRect.new()
		image.texture = load(path)
		image.custom_minimum_size = Vector2(50, 64)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(image)
	var title := _label(str(part.get("name", "")), 18, VisualTheme.PAPER)
	title.add_theme_font_override("font", VisualTheme.BOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(title)
	var description := _label(str(part.get("what", "")), 15, VisualTheme.MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.max_lines_visible = 2
	box.add_child(description)
	var gap := Control.new()
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(gap)
	for spec: Array in part.get("specs", []):
		if str(spec[0]) in ["Cost", "Build time", "Efficiency (Isp)", "Lift-off thrust", "Power"]:
			box.add_child(_label("%s  %s" % [spec[0], spec[1]], 13, VisualTheme.PAPER))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 5)
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(actions)
	for label_text: String in ["Sheet ›", "Remove" if installed else "Install"]:
		var action := TactileButton.new()
		action.text = label_text
		action.custom_minimum_size = Vector2(0, 34)
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action.add_theme_font_size_override("font_size", 15)
		action.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if label_text == "Sheet ›":
			action.pressed.connect(func() -> void: details_requested.emit())
		else:
			action.pressed.connect(func() -> void: install_requested.emit())
		actions.add_child(action)
	# The explicit actions stay visible before the longer description and specs.
	box.move_child(actions, 2)
	margin.minimum_size_changed.connect(func() -> void:
		custom_minimum_size.y = maxf(274, margin.get_combined_minimum_size().y))
	set_pressed_no_signal(installed)
	_sync_face()


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
