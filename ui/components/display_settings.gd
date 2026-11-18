class_name DisplaySettings
extends AnimatedPanel
## A reversible live preview. The existing menu owns Save/Back semantics.

signal changed

const SLIDERS := {
	"curvature": "Screen curvature", "scanlines": "Scanlines",
	"chromatic_aberration": "Color separation", "glow": "Display glow",
	"movement_strength": "Movement strength",
}

var _values := {}
var _sliders := {}
var _numbers := {}
var _crt: TactileCard
var _motion: CheckButton
var _dynamic: CheckButton


func _ready() -> void:
	super._ready()
	theme = VisualTheme.shared()
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	scroll.add_child(box)
	box.add_child(_label("DISPLAY / LIVE PREVIEW", &"Eyebrow"))
	box.add_child(_label("Signal & motion", &"PanelTitle"))
	_crt = TactileCard.new()
	_crt.toggled.connect(func(enabled: bool) -> void:
		_values["crt_enabled"] = enabled
		_update())
	box.add_child(_crt)
	_dynamic = CheckButton.new()
	_dynamic.text = "Dynamic screen movement"
	_dynamic.custom_minimum_size.y = 46
	_dynamic.toggled.connect(func(enabled: bool) -> void:
		_values["dynamic_movement"] = enabled
		_update())
	box.add_child(_dynamic)
	for key: String in SLIDERS:
		var heading := HBoxContainer.new()
		box.add_child(heading)
		var caption := _label(SLIDERS[key])
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(caption)
		var number := _label("", &"Telemetry")
		heading.add_child(number)
		_numbers[key] = number
		var slider := HSlider.new()
		slider.custom_minimum_size = Vector2(0, 26)
		slider.max_value = 100.0
		slider.step = 1.0
		slider.value_changed.connect(func(value: float) -> void:
			_values[key] = value / 100.0
			_update())
		box.add_child(slider)
		_sliders[key] = slider
	_motion = CheckButton.new()
	_motion.text = "Reduced motion"
	_motion.custom_minimum_size.y = 48
	_motion.toggled.connect(func(enabled: bool) -> void:
		_values["reduced_motion"] = enabled
		_update())
	box.add_child(_motion)
	var note := _label("Preview changes here. Save keeps them; Back restores your saved display.")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", VisualTheme.MUTED)
	note.add_theme_font_size_override("font_size", 18)
	box.add_child(note)
	set_values(GameSettings.visuals())


func set_values(values: Dictionary) -> void:
	_values = values.duplicate()
	_crt.set_pressed_no_signal(bool(_values["crt_enabled"]))
	_motion.set_pressed_no_signal(bool(_values["reduced_motion"]))
	_dynamic.set_pressed_no_signal(bool(_values["dynamic_movement"]))
	for key: String in _sliders:
		(_sliders[key] as HSlider).set_value_no_signal(float(_values[key]) * 100.0)
	_refresh()


func values() -> Dictionary:
	return _values.duplicate()


func _update() -> void:
	_refresh()
	GameSettings.set_visuals(_values)
	changed.emit()


func _refresh() -> void:
	_crt.text = "CRT display   /   %s" % ("ON" if _values["crt_enabled"] else "OFF")
	_dynamic.disabled = bool(_values["reduced_motion"])
	for key: String in _sliders:
		(_numbers[key] as Label).text = "%d%%" % roundi(float(_values[key]) * 100.0)
		var enabled: bool = (bool(_values["dynamic_movement"]) and not bool(_values["reduced_motion"])) if key == "movement_strength" else bool(_values["crt_enabled"])
		(_sliders[key] as HSlider).editable = enabled
		(_sliders[key] as HSlider).modulate.a = 1.0 if enabled else 0.4


func _label(text: String, variation: StringName = &"") -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
