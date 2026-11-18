class_name RogueWidgets
extends RefCounted
## Small composition helpers using the existing native tactile visual system.


static func label(text: String, size := 20, color := VisualTheme.PAPER) -> Label:
	var result := Label.new()
	result.text = text
	result.theme = VisualTheme.shared()
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


static func button(text: String, action: Callable, enabled := true) -> TactileButton:
	var result := TactileButton.new()
	result.theme = VisualTheme.shared()
	result.text = text
	result.custom_minimum_size.y = 42
	result.add_theme_font_size_override("font_size", 18)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.disabled = not enabled
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.pressed.connect(action)
	return result


static func sheet(parent: Node, heading: String) -> Dictionary:
	var layer := CanvasLayer.new()
	layer.layer = 60
	parent.add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var dark := ColorRect.new()
	dark.color = Color(0.01, 0.025, 0.05, 0.92)
	dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dark)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 240)
	for side: String in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 100)
	root.add_child(margin)
	var panel := PanelContainer.new()
	panel.theme = VisualTheme.shared()
	panel.add_theme_stylebox_override("panel", VisualTheme.surface(Color("12283a"), VisualTheme.CYAN, 24))
	margin.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	var close := button(heading + "  /  Close", layer.queue_free)
	content.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)
	UiMotion.reveal(root, 0.2)
	return {"layer": layer, "root": root, "body": body, "close": close}


static func edge_shade(parent: Control, top: bool) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.02, 0.045, 0.075, 0.9), Color(0.02, 0.045, 0.075, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 1
	texture.height = 180
	texture.fill_from = Vector2(0, 0 if top else 1)
	texture.fill_to = Vector2(0, 1 if top else 0)
	var shade := TextureRect.new()
	shade.texture = texture
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
	shade.offset_top = 0 if top else -180
	shade.offset_bottom = 180 if top else 0
	parent.add_child(shade)
	parent.move_child(shade, 0)


static func stock_text(recipe: Dictionary) -> String:
	var items := PackedStringArray()
	for key: String in recipe:
		items.append("%d %s" % [recipe[key], key])
	return ", ".join(items) if not items.is_empty() else "No manufacturing stock"


static func instrument_names(ids: Array) -> String:
	var names := PackedStringArray()
	for item: Dictionary in RogueCatalog.instruments(ids):
		names.append(str(item["name"]))
	return ", ".join(names)


static func research_names(ids: Array) -> String:
	var names := PackedStringArray()
	for id: String in ids:
		names.append(str(RogueCatalog.find("objectives", id).get("name", id)))
	return ", ".join(names) if not names.is_empty() else "None"


static func command_names(commands: Dictionary) -> String:
	var labels := {"survey": "Camera observations", "radio_backup": "Standby radio activated", "life_reserve": "Reserve cartridge used"}
	var names := PackedStringArray()
	for id: String in labels:
		if commands.get(id, false):
			names.append(labels[id])
	return ", ".join(names) if not names.is_empty() else "Planned operations; no optional command"
