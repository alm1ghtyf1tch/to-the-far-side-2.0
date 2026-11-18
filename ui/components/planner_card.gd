class_name PlannerCard
extends TactileButton
## The stable native button owns input; the entire decorated face springs together.

signal details_requested

var tag := ""
var title := ""
var description := ""
var specifications := ""
var image_path := ""
var compact := false
var _state: Label


func _ready() -> void:
	toggle_mode = true
	theme = VisualTheme.shared()
	custom_minimum_size = Vector2(0, 124 if compact else 248)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_theme_stylebox_override("normal", VisualTheme.surface(Color("202b36"), Color("55636f"), 12))
	add_theme_stylebox_override("pressed", VisualTheme.surface(Color("293c47"), VisualTheme.AMBER, 12))
	add_theme_stylebox_override("hover", VisualTheme.surface(Color("2b3a46"), VisualTheme.CYAN, 12))
	super._ready()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 13)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(box)
	margin.minimum_size_changed.connect(func() -> void:
		custom_minimum_size.y = maxf(124 if compact else 248, margin.get_combined_minimum_size().y))
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(top)
	var label := _label(tag, 14, VisualTheme.CYAN)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(label)
	_state = _label("○", 14, VisualTheme.AMBER)
	top.add_child(_state)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	if not image_path.is_empty():
		var image := TextureRect.new()
		image.texture = load(image_path)
		image.custom_minimum_size = Vector2(74, 70)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(image)
	var heading := _label(title, 19 if compact else 20, VisualTheme.PAPER)
	heading.add_theme_font_override("font", VisualTheme.BOLD)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(heading)
	if not compact:
		var body := _label(description, 15, VisualTheme.MUTED)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(body)
	var gap := Control.new()
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(gap)
	var spec := _label(specifications, 14, Color("cfddd9"))
	spec.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(spec)
	if not compact:
		var details := Button.new()
		details.text = "Field notes  ›"
		details.add_theme_font_size_override("font_size", 14)
		details.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		details.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		details.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		details.pressed.connect(func() -> void: details_requested.emit())
		box.add_child(details)
	toggled.connect(func(value: bool) -> void: _state.text = "●" if value else "○")


func mark(value: bool) -> void:
	set_pressed_no_signal(value)
	_state.text = "●" if value else "○"
	_sync_face()


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
