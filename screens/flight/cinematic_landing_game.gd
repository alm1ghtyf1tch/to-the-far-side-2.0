extends LandingGame
## Original LandingGame physics/input/outcomes, with a read-only 3D presentation.

var _observation: Node3D
var _hud: Control


func _add_hold(text: String, rect: Rect2, change: Callable) -> void:
	var button := TactileButton.new()
	button.theme = VisualTheme.shared()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 19)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.button_down.connect(change.bind(true))
	button.button_up.connect(change.bind(false))
	add_child(button)


func _ready() -> void:
	super._ready()
	for child in get_children():
		if child is Button:
			child.z_index = 2
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.size = Vector2i(1020, 600)
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	_observation = preload("res://environments/flight/landing_observation.gd").new()
	viewport.add_child(_observation)
	var image := TextureRect.new()
	image.texture = viewport.get_texture()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(image)
	_hud = Control.new()
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.z_index = 1
	_hud.draw.connect(_draw_hud)
	add_child(_hud)


func start(setup: Dictionary, site_id: String) -> void:
	super.start(setup, site_id)
	_observation.build(self)


func _process(delta: float) -> void:
	super._process(delta)
	if _hud:
		_observation.sync(self, delta)
		_hud.queue_redraw()


func _draw() -> void:
	pass


func _draw_hud() -> void:
	var training := int(_setup.get("training", 1))
	if training >= 1:
		for zone: Vector2 in _clear:
			var a := _screen_x(zone.x)
			var b := _screen_x(zone.y)
			_hud.draw_line(Vector2(a, GROUND + 46.0), Vector2(b, GROUND + 46.0), WHITE, 2.0)
			_hud.draw_string(FONT_MONO, Vector2(a, GROUND + 41.0), "CLEAR GROUND", HORIZONTAL_ALIGNMENT_CENTER, b-a, 12, WHITE)
	var panel := Rect2(16.0, 60.0, 250.0, 236.0 if training >= 2 else 196.0)
	_hud.draw_rect(panel, Color(NAVY, 0.92))
	_hud.draw_rect(Rect2(panel.position, Vector2(5.0, panel.size.y)), RED)
	var blank := _alarm_left > 0.0
	var left := panel.position.x + 20.0
	_draw_number(Vector2(left, panel.position.y + 24.0), "ALTITUDE", "---" if blank else "%d m" % roundi(_height))
	var down := maxf(-_fall, 0.0)
	_draw_number(Vector2(left, panel.position.y + 80.0), "DESCENT RATE  ·  LAND BELOW 2.5", "---" if blank else "%.1f m/s" % down)
	_hud.draw_string(FONT_MONO, Vector2(left, panel.position.y + 136.0), "FUEL  ·  %d s" % roundi(_fuel) if not blank else "FUEL", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, SILVER)
	var bar := Rect2(left, panel.position.y + 146.0, 210.0, 14.0)
	_hud.draw_rect(bar, Color(1, 1, 1, 0.16))
	if not blank:
		_hud.draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(_fuel / 28.0, 0.0, 1.0), bar.size.y)), WHITE)
	_hud.draw_string(FONT_MONO, Vector2(left, panel.position.y + 182.0), "SIDEWAYS  %s" % ("---" if blank else "%.1f m/s" % absf(_slide)), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, SILVER)
	if training >= 2:
		var needed := maxf((down * down - 4.0) / (2.0 * (THRUST - GRAVITY)), 0.0)
		_hud.draw_string(FONT_MONO, Vector2(left, panel.position.y + 208.0), "HEIGHT NEEDED TO STOP", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, SILVER)
		_hud.draw_string(FONT_MONO, Vector2(left, panel.position.y + 228.0), "---" if blank else "%d m" % roundi(needed), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, WHITE)
	if blank:
		_hud.draw_rect(Rect2(panel.position.x, panel.end.y + 6.0, panel.size.x, 34.0), RED)
		_hud.draw_string(FONT_BOLD, Vector2(left, panel.end.y + 29.0), "COMPUTER ALARM", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, WHITE)

	_hud.draw_rect(Rect2(0.0, 526.0, size.x, 74.0), Color(NAVY, 0.92))
	_hud.draw_rect(Rect2(0.0, 526.0, size.x, 4.0), RED)
	_hud.draw_multiline_string(FONT, Vector2(24.0, 554.0), "Hold SPACE to fire the engine, A and D to slide sideways (or use the buttons). Touch down on clear ground slower than 2.5 m/s before the fuel runs out. If the descent goes wrong, the computer aborts and the crew returns to orbit.", HORIZONTAL_ALIGNMENT_LEFT, 680.0, 14, 3, SILVER)

	if _over:
		var title: String = {"landed": "TOUCHDOWN", "hard": "HARD LANDING", "abort": "ABORT"}.get(str(_outcome.get("result", "")), "")
		var detail := "%.1f m/s  ·  %d s of fuel left" % [float(_outcome.get("speed", 0.0)), roundi(float(_outcome.get("fuel", 0.0)))]
		if _outcome.get("result") == "abort":
			detail = "The ascent engine is taking the crew back to orbit."
		var card := Rect2(size.x * 0.5 - 250.0, 190.0, 500.0, 104.0)
		_hud.draw_rect(card, WHITE)
		_hud.draw_rect(Rect2(card.position, Vector2(10.0, card.size.y)), RED)
		_hud.draw_string(FONT_BOLD, card.position + Vector2(30.0, 46.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, NAVY)
		_hud.draw_string(FONT, card.position + Vector2(30.0, 80.0), detail, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("323a45"))


func _draw_number(at: Vector2, caption: String, value: String) -> void:
	_hud.draw_string(FONT_MONO, at, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, SILVER)
	_hud.draw_string(FONT_MONO, at + Vector2(0.0, 30.0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, WHITE)
