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

const SOURCES_NOTE := "A fan-made educational game by team Pharsyde.\nNot a NASA product: not affiliated with, sponsored or endorsed by NASA."
const SOURCES := ["JPL Concept Maturity Levels", "Goddard Mission Design Lab", "GMAT", "NASA Mission Viz", "NSSDCA Apollo Lunar Landings", "NSSDCA Apollo Landing Site Coordinates", "NASA Launch Services Program Launch Sites"]
const SOURCES_FONT := preload("res://assets/fonts/IBMPlexSans-Regular.woff2")
const RISE_FROM := 0.3
const RISE_TIME := 60.0

var _options: Array[Vector2i] = []
var _resolution := Vector2i.ZERO
var _volume := 0.0


func _ready() -> void:
	GameSettings.apply()
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
	_play_button.grab_focus()


func _open_scene() -> void:
	var sky := _sky.material as ShaderMaterial
	sky.set_shader_parameter("rise", RISE_FROM)
	var lift := create_tween()
	lift.tween_method(func(value: float) -> void: sky.set_shader_parameter("rise", value), RISE_FROM, 1.0, RISE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_column.modulate.a = 0.0
	var reveal := create_tween()
	reveal.tween_interval(0.3)
	reveal.tween_property(_column, "modulate:a", 1.0, 1.0)


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
	label.anchor_left = 0.0625
	label.anchor_right = 0.4375
	label.anchor_top = 1.0
	label.anchor_bottom = 1.0
	label.offset_top = -136.0
	label.offset_bottom = -22.0
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
	_volume = GameSettings.music_volume
	_volume_slider.set_value_no_signal(roundf(_volume * 100.0))
	_refresh()
	_menu_box.visible = false
	_settings_box.visible = true
	_resolution_next.grab_focus()


func _close_settings() -> void:
	_settings_box.visible = false
	_menu_box.visible = true
	_settings_button.grab_focus()


func _step_resolution(step: int) -> void:
	var index := maxi(_options.find(_resolution), 0)
	_resolution = _options[wrapi(index + step, 0, _options.size())]
	_refresh()


func _on_volume_changed(value: float) -> void:
	_volume = value / 100.0
	_refresh()


func _on_save_pressed() -> void:
	GameSettings.save(_resolution, _volume)
	if not GameSettings.can_resize() and _resolution != GameSettings.FULLSCREEN:
		push_warning("Игра встроена в окно редактора: размер окна сохранён, но применится только в отдельном окне.")
	_back_button.grab_focus()
	_refresh()


func _refresh() -> void:
	_resolution_value.text = GameSettings.text(_resolution)
	_volume_value.text = "%d" % roundi(_volume * 100.0)
	var changed := _resolution != GameSettings.resolution \
			or not is_equal_approx(_volume, GameSettings.music_volume)
	_save_button.visible = changed
