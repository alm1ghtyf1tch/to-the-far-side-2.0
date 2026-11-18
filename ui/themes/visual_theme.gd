class_name VisualTheme
extends RefCounted
## Shared presentation tokens. Existing document themes migrate in later phases.

const SPACE := Color("071629")
const NAVY := Color("0b3d91")
const CYAN := Color("42b9e8")
const AMBER := Color("f2b632")
const PAPER := Color("f0f4f8")
const MUTED := Color("a7b9d0")
const DANGER := Color("dd361c")
const BODY := preload("res://assets/fonts/IBMPlexSans-Regular.woff2")
const BOLD := preload("res://assets/fonts/IBMPlexSans-SemiBold.woff2")
const MONO := preload("res://assets/fonts/IBMPlexMono-Regular.woff2")
const DISPLAY := preload("res://assets/fonts/Saira-Display.ttf")

static var _theme: Theme


static func shared() -> Theme:
	if _theme != null:
		return _theme
	_theme = Theme.new()
	_theme.default_font = BODY
	_theme.default_font_size = 22
	_theme.set_color("font_color", "Label", PAPER)
	for variation: String in ["Telemetry", "Eyebrow", "PanelTitle"]:
		_theme.set_type_variation(variation, "Label")
	_theme.set_font("font", "Telemetry", MONO)
	_theme.set_font_size("font_size", "Telemetry", 20)
	_theme.set_font("font", "Eyebrow", BOLD)
	_theme.set_font_size("font_size", "Eyebrow", 15)
	_theme.set_color("font_color", "Eyebrow", CYAN)
	_theme.set_font("font", "PanelTitle", DISPLAY)
	_theme.set_font_size("font_size", "PanelTitle", 38)
	_theme.set_font("font", "Button", BOLD)
	_theme.set_font_size("font_size", "Button", 22)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		_theme.set_color(state, "Button", PAPER)
	_theme.set_color("font_disabled_color", "Button", Color("61738a"))
	_theme.set_stylebox("normal", "Button", surface(Color("112a45"), Color("36506b")))
	_theme.set_stylebox("hover", "Button", surface(Color("193957"), CYAN))
	_theme.set_stylebox("pressed", "Button", surface(Color("244b6c"), AMBER))
	_theme.set_stylebox("hover_pressed", "Button", _theme.get_stylebox("pressed", "Button"))
	_theme.set_stylebox("disabled", "Button", surface(Color("101e30"), Color("27394c")))
	var focus := surface(Color.TRANSPARENT, AMBER)
	focus.draw_center = false
	focus.set_expand_margin_all(3.0)
	_theme.set_stylebox("focus", "Button", focus)
	_theme.set_type_variation("MissionCard", "Button")
	_theme.set_stylebox("panel", "PanelContainer", surface(Color("0b1c30"), Color("36506b"), 24.0))
	var rail := StyleBoxFlat.new()
	rail.bg_color = Color("233b53")
	rail.set_content_margin_all(4.0)
	rail.set_corner_radius_all(4)
	var fill := rail.duplicate() as StyleBoxFlat
	fill.bg_color = CYAN
	_theme.set_stylebox("slider", "HSlider", rail)
	_theme.set_stylebox("grabber_area", "HSlider", fill)
	_theme.set_stylebox("grabber_area_highlight", "HSlider", fill)
	return _theme


static func surface(fill: Color, border: Color, padding := 16.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(padding)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 4)
	return style
