extends SceneTree
## Exercise the real settings codec without writing the player's settings.cfg.


func _initialize() -> void:
	var legacy := ConfigFile.new()
	legacy.set_value("video", "resolution", Vector2i(1600, 900))
	legacy.set_value("audio", "music_volume", 0.45)
	GameSettings._read_config(legacy)
	assert(GameSettings.resolution == Vector2i(1600, 900))
	assert(is_equal_approx(GameSettings.music_volume, 0.45))
	assert(GameSettings.visuals() == GameSettings.VISUAL_DEFAULTS)
	GameSettings.set_visuals({"crt_enabled": false, "curvature": 0.82, "scanlines": 0.45, "glow": 0.3, "reduced_motion": true})
	var intended := GameSettings.visuals()
	legacy.set_value("future", "keep", "existing settings")
	GameSettings._write_config(legacy)
	var path := "res://.godot/presentation-settings-test.cfg"
	assert(legacy.save(path) == OK)
	var loaded := ConfigFile.new()
	assert(loaded.load(path) == OK)
	GameSettings.set_visuals(GameSettings.VISUAL_DEFAULTS)
	GameSettings._read_config(loaded)
	assert(GameSettings.visuals() == intended)
	assert(loaded.get_value("future", "keep") == "existing settings")
	GameSettings.set_visuals({"curvature": 100.0, "scanlines": -2.0, "glow": NAN, "reduced_motion": "invalid"})
	var sanitized := GameSettings.visuals()
	assert(sanitized["curvature"] == 1.0 and sanitized["scanlines"] == 0.0)
	assert(sanitized["glow"] == GameSettings.VISUAL_DEFAULTS["glow"])
	assert(sanitized["reduced_motion"] == false)
	print("PASS: legacy settings, persisted display values, unknown keys and sanitization")
	quit()
