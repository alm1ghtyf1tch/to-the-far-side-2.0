class_name ReadMore
extends CanvasLayer

const FONT := preload("res://assets/fonts/IBMPlexSans-Regular.woff2")
const FONT_BOLD := preload("res://assets/fonts/IBMPlexSans-SemiBold.woff2")
const FONT_TITLE := preload("res://assets/fonts/Saira-Display.ttf")
const PANEL_WIDTH := 580.0
const EDGE := 16.0
const NAVY := Color("061f4a")
const LINE := Color("105bd8")
const ACCENT := Color("02bfe7")
const AMBER := Color("9bdaf1")

var _topic := {}
var _chip: Button
var _panel: PanelContainer
var _kicker: Label
var _title: Label
var _image: TextureRect
var _image_note: Label
var _body: RichTextLabel
var _source: Label
var _tween: Tween


func _ready() -> void:
	layer = 50
	_build_chip()
	_build_panel()
	_chip.visible = false
	_panel.visible = false
	get_viewport().size_changed.connect(_place)
	_panel.resized.connect(_fit.call_deferred)
	_panel.minimum_size_changed.connect(_fit.call_deferred)
	_place()


func offer(topic: Dictionary) -> void:
	if topic.is_empty() or str(topic.get("title", "")).is_empty():
		return
	_topic = topic
	_chip.text = "Read more about\n%s   ›" % topic["title"]
	if _panel.visible:
		_fill()
	else:
		_chip.visible = true
		_chip.modulate.a = 0.0
		create_tween().tween_property(_chip, "modulate:a", 1.0, 0.2)
	_place()


func clear() -> void:
	_topic = {}
	_chip.visible = false
	close()


func is_open() -> bool:
	return _panel.visible


func open() -> void:
	if _topic.is_empty():
		return
	_fill()
	_chip.visible = false
	_panel.visible = true
	var view := _view()
	_panel.position.x = view.x
	_slide(view.x - PANEL_WIDTH - EDGE, false)


func close() -> void:
	if not _panel.visible:
		return
	_slide(_view().x, true)
	_chip.visible = not _topic.is_empty()


func _unhandled_input(event: InputEvent) -> void:
	if _panel.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _slide(to_x: float, hide_after: bool) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_panel, "position:x", to_x, 0.28)
	if hide_after:
		_tween.tween_callback(func() -> void: _panel.visible = false)


func _fill() -> void:
	_kicker.text = str(_topic.get("kicker", "")).to_upper()
	_kicker.visible = not _kicker.text.is_empty()
	_title.text = str(_topic.get("title", ""))
	var image_path := str(_topic.get("image", ""))
	_image.visible = not image_path.is_empty() and ResourceLoader.exists(image_path)
	if _image.visible:
		var texture: Texture2D = load(image_path)
		_image.texture = texture
		var height := (PANEL_WIDTH - 60.0) * texture.get_height() / maxf(float(texture.get_width()), 1.0)
		_image.custom_minimum_size.y = clampf(roundf(height), 120.0, 340.0)
	_image_note.text = str(_topic.get("image_note", ""))
	_image_note.visible = _image.visible and not _image_note.text.is_empty()
	var text := ""
	var facts: Array = _topic.get("facts", [])
	if not facts.is_empty():
		text += "[table=2]"
		for fact: Array in facts:
			text += "[cell padding=0,5,18,5][color=#aeb0b5]%s[/color][/cell][cell padding=0,5,0,5][b]%s[/b][/cell]" % [fact[0], fact[1]]
		text += "[/table]\n\n"
	var paragraphs: Array = _topic.get("text", [])
	text += "\n\n".join(PackedStringArray(paragraphs))
	_body.text = text
	_source.text = str(_topic.get("source", ""))
	_source.visible = not _source.text.is_empty()


func _view() -> Vector2:
	return get_viewport().get_visible_rect().size


func _fit() -> void:
	var limit := _view().y - EDGE * 2.0
	if _panel.size.y > limit + 0.5:
		_panel.size.y = limit


func _place() -> void:
	var view := _view()
	_chip.size = Vector2(380.0, 0.0)
	_chip.position = Vector2(view.x - 380.0 - EDGE, EDGE - 4.0)
	_panel.size = Vector2(PANEL_WIDTH, view.y - EDGE * 2.0)
	_panel.position.y = EDGE
	if _panel.visible and (_tween == null or not _tween.is_running()):
		_panel.position.x = view.x - PANEL_WIDTH - EDGE


func _build_chip() -> void:
	_chip = Button.new()
	_chip.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_chip.focus_mode = Control.FOCUS_NONE
	_chip.add_theme_font_override("font", FONT_BOLD)
	_chip.add_theme_font_size_override("font_size", 17)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_chip.add_theme_color_override(state, Color.WHITE)
	_chip.add_theme_stylebox_override("normal", _box(Color("0b3d91"), ACCENT, 0, 14.0, 8.0))
	_chip.add_theme_stylebox_override("hover", _box(Color("105bd8"), Color.WHITE, 0, 14.0, 8.0))
	_chip.add_theme_stylebox_override("pressed", _box(Color("105bd8"), Color.WHITE, 0, 14.0, 8.0))
	_chip.pressed.connect(open)
	add_child(_chip)


func _build_panel() -> void:
	_panel = PanelContainer.new()
	var panel_style := _box(NAVY, LINE, 0, 30.0, 26.0)
	panel_style.border_color = Color("f2b632")
	panel_style.border_width_top = 6
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 18
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_panel.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	_kicker = _label(FONT_BOLD, 15, AMBER)
	_kicker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_kicker.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(_kicker)
	var close_button := Button.new()
	close_button.text = "Close  ×"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_button.add_theme_font_override("font", FONT_BOLD)
	close_button.add_theme_font_size_override("font_size", 16)
	for state in ["font_color", "font_pressed_color", "font_focus_color"]:
		close_button.add_theme_color_override(state, Color.WHITE)
	close_button.add_theme_color_override("font_hover_color", AMBER)
	for state in ["normal", "hover", "pressed", "focus"]:
		close_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	close_button.pressed.connect(close)
	head.add_child(close_button)
	_title = _label(FONT_TITLE, 28, Color("ffffff"))
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_title)
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(0.0, 2.0)
	line.color = Color(1, 1, 1, 0.25)
	box.add_child(line)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)
	_image = TextureRect.new()
	_image.custom_minimum_size = Vector2(0.0, 260.0)
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	content.add_child(_image)
	_image_note = _label(FONT, 14, Color("aeb0b5"))
	content.add_child(_image_note)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.fit_content = true
	_body.scroll_active = false
	_body.add_theme_font_override("normal_font", FONT)
	_body.add_theme_font_override("bold_font", FONT_BOLD)
	_body.add_theme_font_size_override("normal_font_size", 20)
	_body.add_theme_font_size_override("bold_font_size", 20)
	_body.add_theme_color_override("default_color", Color("e1f3f8"))
	_body.add_theme_constant_override("line_separation", 5)
	content.add_child(_body)
	_source = _label(FONT, 15, Color("aeb0b5"))
	_source.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_source)


func _label(font: Font, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _box(fill: Color, border: Color, border_width: int, margin_x: float, margin_y: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(4)
	style.content_margin_left = margin_x
	style.content_margin_right = margin_x
	style.content_margin_top = margin_y
	style.content_margin_bottom = margin_y
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 12
	return style
