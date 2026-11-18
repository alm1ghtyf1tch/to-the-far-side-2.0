class_name RetractablePanel
extends Control
## A stationary native tab remains accessible while the surface slides aside.

signal changed(open: bool)
var title := "Panel"
var edge := "right"
var opened := true
var surface: PanelContainer
var content: VBoxContainer
var tab: TactileButton
var _slide: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	surface = PanelContainer.new()
	surface.mouse_filter = Control.MOUSE_FILTER_STOP
	surface.add_theme_stylebox_override("panel", VisualTheme.surface(Color(0.045, 0.085, 0.13, 0.96), Color("526373"), 14))
	surface.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	surface.offset_top = 42
	add_child(surface)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	surface.add_child(content)
	tab = TactileButton.new()
	tab.theme = VisualTheme.shared()
	tab.text = title + "  −"
	tab.size = Vector2(210, 36)
	tab.add_theme_font_size_override("font_size", 17)
	tab.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tab.pressed.connect(func() -> void: set_open(not opened))
	add_child(tab)
	resized.connect(_layout)
	GameSettings.events.visuals_changed.connect(_settle_motion)
	_layout()


func set_open(value: bool, immediate := false) -> void:
	opened = value
	if _slide:
		_slide.kill()
	tab.text = title + ("  −" if opened else "  +")
	surface.show()
	var target := Vector2(0, 42) if opened else _closed_position()
	if immediate or GameSettings.reduced_motion():
		surface.position = target
		surface.visible = opened
	else:
		_slide = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_slide.tween_property(surface, "position", target, 0.23)
		if not opened:
			_slide.tween_callback(surface.hide)
	changed.emit(opened)


func _closed_position() -> Vector2:
	return Vector2(-size.x - 4 if edge == "left" else size.x + 4, 42)


func _layout() -> void:
	tab.position.x = 0 if edge == "left" else maxf(0, size.x - tab.size.x)
	surface.size = Vector2(size.x, maxf(1, size.y - 42))
	set_open(opened, true)


func _settle_motion() -> void:
	if GameSettings.reduced_motion():
		set_open(opened, true)
