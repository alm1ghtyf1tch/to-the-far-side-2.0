class_name GameSettings
extends RefCounted

const PATH := "user://settings.cfg"
const MUSIC_BUS := "Music"
const FULLSCREEN := Vector2i.ZERO
const SIZES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

static var resolution := Vector2i(1280, 720)
static var music_volume := 0.8
static var _loaded := false


static func apply() -> void:
	if _loaded:
		return
	_loaded = true
	var file := ConfigFile.new()
	if file.load(PATH) == OK:
		var saved: Variant = file.get_value("video", "resolution", resolution)
		if saved is Vector2i:
			resolution = saved
		music_volume = clampf(float(file.get_value("audio", "music_volume", music_volume)), 0.0, 1.0)
		_apply_resolution()
	_apply_volume()


static func save(new_resolution: Vector2i, new_volume: float) -> void:
	var resized := new_resolution != resolution
	resolution = new_resolution
	music_volume = clampf(new_volume, 0.0, 1.0)
	if resized:
		_apply_resolution()
	_apply_volume()
	var file := ConfigFile.new()
	file.set_value("video", "resolution", resolution)
	file.set_value("audio", "music_volume", music_volume)
	file.save(PATH)


static func options() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var usable := _usable_size()
	for size in SIZES:
		if usable == Vector2i.ZERO or (size.x <= usable.x and size.y <= usable.y):
			result.append(size)
	if result.is_empty():
		result.append(SIZES[0])
	if not result.has(resolution) and resolution != FULLSCREEN:
		result.append(resolution)
		result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x)
	result.append(FULLSCREEN)
	return result


static func text(size: Vector2i) -> String:
	if size == FULLSCREEN:
		return "Fullscreen"
	return "%d × %d" % [size.x, size.y]


static func can_resize() -> bool:
	return not Engine.is_embedded_in_editor() and DisplayServer.get_name() != "headless"


static func _apply_resolution() -> void:
	if not can_resize():
		return
	if resolution == FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	var window_mode := DisplayServer.window_get_mode()
	if window_mode != DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var screen := DisplayServer.window_get_current_screen()
	var scale := DisplayServer.screen_get_scale(screen)
	var pixels := Vector2i((Vector2(resolution) * scale).round())
	var usable := DisplayServer.screen_get_usable_rect(screen)
	pixels = pixels.min(usable.size)
	DisplayServer.window_set_size(pixels)
	DisplayServer.window_set_position(usable.position + (usable.size - pixels) / 2)


static func _usable_size() -> Vector2i:
	if DisplayServer.get_name() == "headless":
		return Vector2i.ZERO
	var screen := DisplayServer.window_get_current_screen()
	var scale := maxf(DisplayServer.screen_get_scale(screen), 1.0)
	return Vector2i((Vector2(DisplayServer.screen_get_usable_rect(screen).size) / scale).floor())


static func _apply_volume() -> void:
	var bus := AudioServer.get_bus_index(MUSIC_BUS)
	if bus == -1:
		AudioServer.add_bus()
		bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus, MUSIC_BUS)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(music_volume, 0.0001)))
	AudioServer.set_bus_mute(bus, music_volume <= 0.0)
