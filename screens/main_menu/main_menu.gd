extends Control

@onready var _sky: ColorRect = %Sky
@onready var _column: Control = %Column
@onready var _menu_box: Control = %MenuBox
@onready var _settings_box: Control = %SettingsBox
@onready var _play_button: Button = %PlayButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _resolution_prev: Button = %ResolutionPrev
@onready var _resolution_next: Button = %ResolutionNext
@onready var _resolution_value: Label = %ResolutionValue
@onready var _volume_slider: HSlider = %VolumeSlider
@onready var _volume_value: Label = %VolumeValue
@onready var _back_button: Button = %BackButton
@onready var _save_button: Button = %SaveButton
@onready var _mode_select: OptionButton = %ModeSelect
@onready var _display_note: Label = %DisplayNote

const SOURCES_NOTE := "A fan-made educational game by team Pharsyde.\nNot a NASA product: not affiliated with, sponsored or endorsed by NASA."
const SOURCES := ["JPL Concept Maturity Levels", "Goddard Mission Design Lab", "GMAT", "NASA Mission Viz", "NSSDCA Apollo Lunar Landings", "NSSDCA Apollo Landing Site Coordinates", "NASA Launch Services Program Launch Sites"]
const SOURCES_FONT := preload("res://assets/fonts/IBMPlexSans-Regular.woff2")
const RISE_FROM := 0.3
const RISE_TIME := 60.0

var _options: Array[Vector2i] = []
var _resolution := Vector2i.ZERO
var _volume := 0.0
var _mode := ""
var _display_settings: DisplaySettings
var _saved_visuals := {}
var _rise_tween: Tween
var _reveal_tween: Tween


func _ready() -> void:
	GameSettings.apply()
	theme = VisualTheme.shared()
	for mode: String in GameSettings.display_modes():
		_mode_select.add_item(GameSettings.mode_text(mode))
	_mode_select.item_selected.connect(_on_mode_selected)
	get_window().size_changed.connect(_update_display_note)
	_build_display_settings()
	GameSettings.events.visuals_changed.connect(_apply_motion_preferences)
	_play_button.pressed.connect(_on_play_pressed)
	_settings_button.pressed.connect(_open_settings)
	_quit_button.pressed.connect(_on_quit_pressed)
	_quit_button.visible = not OS.has_feature("web")
	_resolution_prev.pressed.connect(_step_resolution.bind(-1))
	_resolution_next.pressed.connect(_step_resolution.bind(1))
	_volume_slider.value_changed.connect(_on_volume_changed)
	_back_button.pressed.connect(_close_settings)
	_save_button.pressed.connect(_on_save_pressed)
	_add_sources()
	_open_scene()
	_apply_motion_preferences()
	_play_button.grab_focus()


func _open_scene() -> void:
	var sky := _sky.material as ShaderMaterial
	sky.set_shader_parameter("rise", RISE_FROM)
	_rise_tween = create_tween()
	_rise_tween.tween_method(func(value: float) -> void: sky.set_shader_parameter("rise", value), RISE_FROM, 1.0, RISE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_reveal_tween = UiMotion.reveal(_column, 0.45, 0.3)


func _build_display_settings() -> void:
	_display_settings = DisplaySettings.new()
	_display_settings.name = "DisplaySettings"
	_display_settings.anchor_left = 0.51
	_display_settings.anchor_right = 0.925
	_display_settings.anchor_top = 0.15
	_display_settings.anchor_bottom = 0.86
	_menu_box.get_parent().get_parent().add_child(_display_settings)
	_display_settings.visible = false
	_display_settings.changed.connect(_refresh)


func _apply_motion_preferences() -> void:
	var reduced := GameSettings.reduced_motion()
	(_sky.material as ShaderMaterial).set_shader_parameter("motion", 0.0 if reduced else 1.0)
	if reduced:
		if _rise_tween:
			_rise_tween.kill()
		if _reveal_tween:
			_reveal_tween.kill()
		_column.modulate.a = 1.0
		_column.scale = Vector2.ONE
		(_sky.material as ShaderMaterial).set_shader_parameter("rise", 1.0)


func _add_sources() -> void:
	var names := PackedStringArray()
	for source: String in SOURCES:
		names.append(source.replace(" ", "\u00a0"))
	var label := Label.new()
	label.text = "%s\nData and references:  %s" % [SOURCES_NOTE, "  ·  ".join(names)]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", SOURCES_FONT)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_constant_override("line_spacing", 2)
	label.add_theme_color_override("font_color", Color(0.74, 0.77, 0.83, 0.9))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.anchor_left = 0.075
	label.anchor_right = 0.49
	label.anchor_top = 1.0
	label.anchor_bottom = 1.0
	label.offset_top = -140.0
	label.offset_bottom = -64.0
	label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_menu_box.get_parent().get_parent().add_child(label)


func _unhandled_input(event: InputEvent) -> void:
	if _settings_box.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close_settings()


func _on_play_pressed() -> void:
	Campaign.reset()
	SceneRouter.go_to(SceneRouter.HQ)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _open_settings() -> void:
	_options = GameSettings.options()
	_resolution = GameSettings.resolution
	_mode = GameSettings.display_mode
	_mode_select.select(GameSettings.display_modes().find(_mode))
	_volume = GameSettings.music_volume
	_saved_visuals = GameSettings.visuals()
	_display_settings.set_values(_saved_visuals)
	_volume_slider.set_value_no_signal(roundf(_volume * 100.0))
	_refresh()
	_menu_box.visible = false
	_column.visible = false
	_settings_box.visible = true
	_display_settings.reveal()
	_resolution_next.grab_focus()


func _close_settings() -> void:
	GameSettings.set_visuals(_saved_visuals)
	_display_settings.visible = false
	_settings_box.visible = false
	_column.visible = true
	_menu_box.visible = true
	_settings_button.grab_focus()


func _step_resolution(step: int) -> void:
	var index := maxi(_options.find(_resolution), 0)
	_resolution = _options[wrapi(index + step, 0, _options.size())]
	_refresh()


func _on_volume_changed(value: float) -> void:
	_volume = value / 100.0
	_refresh()


func _on_mode_selected(index: int) -> void:
	_mode = GameSettings.display_modes()[index]
	_refresh()


func _update_display_note() -> void:
	if not is_instance_valid(_display_note):
		return
	var native := get_window().size
	_display_note.text = "Output  %d × %d\nInterface  %d × %d" % [native.x, native.y, roundi(get_viewport().get_visible_rect().size.x), roundi(get_viewport().get_visible_rect().size.y)]


func _on_save_pressed() -> void:
	GameSettings.save(_resolution, _volume, _display_settings.values(), _mode)
	_saved_visuals = GameSettings.visuals()
	if not GameSettings.can_resize() and _resolution != GameSettings.FULLSCREEN:
		push_warning("Игра встроена в окно редактора: размер окна сохранён, но применится только в отдельном окне.")
	_back_button.grab_focus()
	_refresh()


func _refresh() -> void:
	_resolution_value.text = GameSettings.text(_resolution)
	_volume_value.text = "%d" % roundi(_volume * 100.0)
	_resolution_prev.disabled = _mode != GameSettings.WINDOWED
	_resolution_next.disabled = _mode != GameSettings.WINDOWED
	_resolution_value.modulate.a = 1.0 if _mode == GameSettings.WINDOWED else 0.45
	_update_display_note()
	var changed := _resolution != GameSettings.resolution \
			or _mode != GameSettings.display_mode \
			or not is_equal_approx(_volume, GameSettings.music_volume) \
			or _display_settings.values() != _saved_visuals
	_save_button.visible = changed
