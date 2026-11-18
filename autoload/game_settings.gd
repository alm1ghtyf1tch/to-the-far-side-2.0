class_name GameSettings
extends RefCounted

const PATH := "user://settings.cfg"
const MUSIC_BUS := "Music"
const VISUAL_DEFAULTS := {
	"crt_enabled": true,
	"curvature": 0.35,
	"scanlines": 0.18,
	"chromatic_aberration": 0.15,
	"glow": 0.12,
	"reduced_motion": false,
	"dynamic_movement": true,
	"movement_strength": 0.65,
}
const FULLSCREEN := Vector2i.ZERO
const WINDOWED := "windowed"
const BORDERLESS := "borderless"
const EXCLUSIVE := "exclusive"
const SIZES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

static var resolution := Vector2i(1600, 900)
static var display_mode := BORDERLESS
static var music_volume := 0.8
static var _loaded := false
static var _visuals := VISUAL_DEFAULTS.duplicate()
static var events := SettingsEvents.new()

class SettingsEvents extends RefCounted:
	signal visuals_changed


static func apply() -> void:
	if _loaded:
		return
	_loaded = true
	var file := ConfigFile.new()
	if file.load(PATH) == OK:
		_read_config(file)
	_apply_resolution()
	_apply_volume()


static func save(new_resolution: Vector2i, new_volume: float, new_visuals: Dictionary = {}, new_mode := "") -> void:
	var requested_mode := new_mode if not new_mode.is_empty() else (BORDERLESS if new_resolution == FULLSCREEN else display_mode)
	var resized := new_resolution != resolution or requested_mode != display_mode
	if new_resolution.x > 0 and new_resolution.y > 0:
		resolution = new_resolution
	display_mode = requested_mode if display_modes().has(requested_mode) else BORDERLESS
	music_volume = clampf(new_volume, 0.0, 1.0)
	if resized:
		_apply_resolution()
	_apply_volume()
	if not new_visuals.is_empty():
		set_visuals(new_visuals)
	var file := ConfigFile.new()
	file.load(PATH)
	_write_config(file)
	file.save(PATH)


static func _read_config(file: ConfigFile) -> void:
	var saved: Variant = file.get_value("video", "resolution", resolution)
	var saved_window: Variant = file.get_value("video", "windowed_resolution", saved)
	if saved_window is Vector2i and saved_window.x > 0 and saved_window.y > 0:
		resolution = saved_window
	# Migrate Phase 1's zero-vector fullscreen sentinel without losing window size.
	var migrated := BORDERLESS if saved == FULLSCREEN else WINDOWED
	var mode: Variant = file.get_value("video", "display_mode", migrated)
	display_mode = str(mode) if display_modes().has(mode) else BORDERLESS
	music_volume = clampf(float(file.get_value("audio", "music_volume", music_volume)), 0.0, 1.0)
	var saved_visuals := {}
	for key: String in VISUAL_DEFAULTS:
		saved_visuals[key] = file.get_value("presentation", key, VISUAL_DEFAULTS[key])
	set_visuals(saved_visuals)


static func _write_config(file: ConfigFile) -> void:
	file.set_value("video", "resolution", resolution if display_mode == WINDOWED else FULLSCREEN)
	file.set_value("video", "windowed_resolution", resolution)
	file.set_value("video", "display_mode", display_mode)
	file.set_value("audio", "music_volume", music_volume)
	for key: String in _visuals:
		file.set_value("presentation", key, _visuals[key])


static func visuals() -> Dictionary:
	return _visuals.duplicate()


static func set_visuals(values: Dictionary) -> void:
	var changed := false
	for key: String in VISUAL_DEFAULTS:
		if not values.has(key):
			continue
		var value: Variant = values[key]
		if VISUAL_DEFAULTS[key] is bool:
			value = value if value is bool else VISUAL_DEFAULTS[key]
		else:
			value = float(value) if value is float or value is int else float(VISUAL_DEFAULTS[key])
			value = clampf(value, 0.0, 1.0) if is_finite(value) else float(VISUAL_DEFAULTS[key])
		if _visuals[key] != value:
			_visuals[key] = value
			changed = true
	if changed:
		events.visuals_changed.emit()


static func reduced_motion() -> bool:
	return bool(_visuals["reduced_motion"])


static func options() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var usable := _usable_size()
	for size in SIZES:
		if usable == Vector2i.ZERO or (size.x <= usable.x and size.y <= usable.y):
			result.append(size)
	if result.is_empty():
		result.append(SIZES[0])
	if not result.has(resolution) and resolution != FULLSCREEN and (usable == Vector2i.ZERO or (resolution.x <= usable.x and resolution.y <= usable.y)):
		result.append(resolution)
		result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x)
	return result


static func display_modes() -> Array[String]:
	var modes: Array[String] = [WINDOWED, BORDERLESS]
	if OS.get_name() in ["Windows", "macOS", "Linux", "FreeBSD"] and DisplayServer.get_name() != "wayland":
		modes.append(EXCLUSIVE)
	return modes


static func mode_text(mode: String) -> String:
	return {WINDOWED: "Windowed", BORDERLESS: "Borderless fullscreen", EXCLUSIVE: "Exclusive fullscreen"}.get(mode, "Windowed")


static func apply_display(size: Vector2i, mode: String) -> void:
	# Also used by mode validation; persistence remains an explicit Save action.
	if size.x > 0 and size.y > 0:
		resolution = size
	display_mode = mode if display_modes().has(mode) else BORDERLESS
	_apply_resolution()


static func text(size: Vector2i) -> String:
	if size == FULLSCREEN:
		return "Fullscreen"
	return "%d × %d" % [size.x, size.y]


static func can_resize() -> bool:
	return not Engine.is_embedded_in_editor() and DisplayServer.get_name() != "headless"


static func _apply_resolution() -> void:
	if not can_resize():
		return
	if display_mode != WINDOWED:
		var mode := DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if display_mode == EXCLUSIVE else DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(mode)
		return
	var window_mode := DisplayServer.window_get_mode()
	if window_mode != DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
	var screen := DisplayServer.window_get_current_screen()
	var scale := DisplayServer.screen_get_scale(screen)
	var pixels := Vector2i((Vector2(resolution) * scale).round())
	var usable := DisplayServer.screen_get_usable_rect(screen)
	var decoration := DisplayServer.window_get_size_with_decorations() - DisplayServer.window_get_size()
	decoration = decoration.max(Vector2i((Vector2(16, 40) * scale).ceil()))
	pixels = pixels.min((usable.size - decoration).max(Vector2i(640, 360)))
	DisplayServer.window_set_size(pixels)
	DisplayServer.window_set_position(usable.position + (usable.size - pixels) / 2)


static func _usable_size() -> Vector2i:
	if DisplayServer.get_name() == "headless":
		return Vector2i.ZERO
	var screen := DisplayServer.window_get_current_screen()
	var scale := maxf(DisplayServer.screen_get_scale(screen), 1.0)
	var usable := Vector2(DisplayServer.screen_get_usable_rect(screen).size) / scale - Vector2(16, 40)
	return Vector2i(usable.floor())


static func _apply_volume() -> void:
	var bus := AudioServer.get_bus_index(MUSIC_BUS)
	if bus == -1:
		AudioServer.add_bus()
		bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus, MUSIC_BUS)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(music_volume, 0.0001)))
	AudioServer.set_bus_mute(bus, music_volume <= 0.0)
