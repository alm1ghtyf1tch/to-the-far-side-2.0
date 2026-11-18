extends StagingGame
## Responsive dashboard skin. All timing, input, accuracy and outcomes are inherited.

var _skin := VisualTheme.surface(Color("102332"), VisualTheme.CYAN, 0)

func _ready() -> void:
	_button = TactileButton.new()
	_button.text = "DROP THE STAGE  [SPACE]"
	_button.theme = VisualTheme.shared()
	_button.focus_mode = Control.FOCUS_NONE
	_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_button.add_theme_font_size_override("font_size", 21)
	_button.pressed.connect(press)
	add_child(_button)
	resized.connect(_place_button)
	_place_button()


func _place_button() -> void:
	_button.position = Vector2(12, 270)
	_button.size = Vector2(maxf(size.x - 24, 100), 64)


func _draw() -> void:
	var phase := mini(_stage, 1)
	var part := clampf(_clock / BURN, 0, 1) if not _over else 1.0
	draw_style_box(_skin, Rect2(Vector2.ZERO, size))
	draw_string(FONT_BOLD, Vector2(14, 28), "MANUAL STAGING", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, VisualTheme.CYAN)
	draw_string(FONT_BOLD, Vector2(14, 62), str(_names[phase]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, WHITE)
	draw_string(FONT_MONO, Vector2(14, 89), "PROPELLANT REMAINING", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, SILVER)
	var bar := Rect2(14, 104, maxf(size.x - 28, 20), 30)
	draw_rect(bar, Color("304456"))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * (1.0 - part), 30)), VisualTheme.AMBER)
	draw_line(Vector2(14, 99), Vector2(14, 140), VisualTheme.DANGER, 4)
	draw_string(FONT_MONO, Vector2(14, 158), "EMPTY: DROP HERE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, SILVER)
	var speed := 0.0
	for index in _stage:
		speed += float(_speeds[index])
	if not _over:
		speed += float(_speeds[phase]) * part
	draw_string(FONT_MONO, Vector2(14, 194), "%.2f km/s built up" % speed, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, WHITE)
	draw_multiline_string(FONT, Vector2(14, 222), "Drop when the tanks run dry. Early wastes propellant; late carries dead weight.", HORIZONTAL_ALIGNMENT_LEFT, maxf(size.x - 28, 100), 16, 2, SILVER)
	if _note_left > 0:
		draw_string(FONT_BOLD, Vector2(14, 360), _note, HORIZONTAL_ALIGNMENT_LEFT, size.x - 28, 16, VisualTheme.AMBER)
