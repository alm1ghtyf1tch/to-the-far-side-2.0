class_name TactileButton
extends Button
## The native Button keeps a stable hit rectangle, focus, signals and minimum size.
## Its child draws the face and receives all spring animation.

var _face: Button
var _motion: UiMotion
var _last_disabled := false


func _ready() -> void:
	_face = Button.new()
	_face.name = "VisualFace"
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.focus_mode = Control.FOCUS_NONE
	_face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_face)
	self_modulate.a = 0.0
	_motion = UiMotion.bind(self, _face)
	for event: Signal in [mouse_entered, mouse_exited, focus_entered, focus_exited, button_down, button_up, toggled, theme_changed]:
		if event == toggled:
			toggled.connect(func(_pressed: bool) -> void: _sync_face())
		else:
			event.connect(_sync_face)
	_face.draw.connect(_draw_focus)
	_sync_face()


func _process(_delta: float) -> void:
	# Native text/disabled properties have no change signal. No per-frame resources.
	if _face.text != text or _face.icon != icon or _last_disabled != disabled:
		_sync_face()
		_motion.refresh()


func _sync_face() -> void:
	if _face == null:
		return
	_last_disabled = disabled
	_face.text = text
	_face.icon = icon
	_face.alignment = alignment
	_face.autowrap_mode = autowrap_mode
	_face.text_overrun_behavior = text_overrun_behavior
	_face.add_theme_font_override("font", get_theme_font("font"))
	_face.add_theme_font_size_override("font_size", get_theme_font_size("font_size"))
	var state := "normal"
	if disabled:
		state = "disabled"
	elif is_pressed():
		state = "pressed"
	elif is_hovered():
		state = "hover"
	_face.add_theme_stylebox_override("normal", get_theme_stylebox(state))
	var color_key := "font_color" if state == "normal" else "font_%s_color" % state
	if has_focus() and state == "normal":
		color_key = "font_focus_color"
	_face.add_theme_color_override("font_color", get_theme_color(color_key))
	_face.queue_redraw()


func _draw_focus() -> void:
	if has_focus():
		_face.draw_style_box(get_theme_stylebox("focus"), Rect2(Vector2.ZERO, _face.size))
