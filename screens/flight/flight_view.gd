class_name FlightView
extends Control

const ART := "res://assets/textures/flight/"
const VEHICLE := "res://assets/textures/vehicle/"
const CATALOG := "res://assets/textures/catalog/"
const FONT := preload("res://assets/fonts/IBMPlexSans-Regular.woff2")
const FONT_MONO := preload("res://assets/fonts/IBMPlexMono-Regular.woff2")
const SPACE := Color("04070d")
const WHITE := Color("ffffff")
const RED := Color("dd361c")
const SILVER := Color("aeb0b5")
const PAD_AXIS := 560.0
const PAD_BASE := 492.0
const TRAJECTORY := "res://data/trajectory.json"
const MAP_EARTH := Vector2(118.0, 208.0)
const MAP_SPAN := 784.0
const LENS_RADIUS := 104.0
const EARTH_LENS := Vector2(150.0, 478.0)
const MOON_LENS := Vector2(870.0, 478.0)

var view := "pad":
	set(value):
		view = value
		_stack.visible = value in ["pad", "ascent"]
		queue_redraw()
var progress := 0.0:
	set(value):
		progress = value
		queue_redraw()
var mode := "":
	set(value):
		if value == "fail" and mode != "fail":
			_wreck = 0.0
		mode = value
		queue_redraw()
var burning := false
var walkers := 0
var staged := 0

var _stack: RocketStack
var _textures := {}
var _time := 0.0
var _lander := ""
var _capsule := ""
var _site := ""
var _high_orbit := false
var _tween: Tween
var _fuels: Array[String] = ["kerosene", "hydrogen", "hydrogen"]
var _tower := false
var _pieces: Array = []
var _settle := 0.0
var _wreck := 0.0
var _legs := {}
var _site_longitude := 0.0
var _site_latitude := 0.0

static var _data := {}


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stack = RocketStack.new()
	_stack.stack_scale = 0.38
	_stack.show_empty = false
	_stack.axis_x = PAD_AXIS
	_stack.base_y = PAD_BASE
	add_child(_stack)


func _ready() -> void:
	_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_paths()


func _process(delta: float) -> void:
	_time += delta
	if mode == "fail":
		_wreck += delta
	for piece: Dictionary in _pieces:
		piece["age"] = float(piece["age"]) + delta
	_pieces = _pieces.filter(func(piece: Dictionary) -> bool: return float(piece["age"]) < 2.6)
	queue_redraw()


func setup(design: Dictionary, site: Dictionary, high_orbit: bool) -> void:
	for slot_id: String in ["stage1", "stage2", "stage3", "lander", "service", "capsule", "escape", "power", "comms"]:
		_stack.set_part(slot_id, Vehicle.chosen(design, slot_id), false)
	_lander = "lander_hls" if str(design.get("lander", "")) == "lander_hls" else str(design.get("lander", "lander_standard"))
	_capsule = str(design.get("capsule", "capsule_three"))
	_site = "site_%s" % site.get("id", "a11")
	_site_longitude = float(site.get("lon", 0.0))
	_site_latitude = float(site.get("lat", 0.0))
	_high_orbit = high_orbit
	_fuels = [str(Vehicle.chosen(design, "stage1").get("fuel", "kerosene")), str(Vehicle.chosen(design, "stage2").get("fuel", "hydrogen")), str(Vehicle.chosen(design, "stage3").get("fuel", "hydrogen"))]
	_tower = str(Vehicle.chosen(design, "escape").get("abort", "")) in ["tower", "tower_steered"]
	reset_stack()
	_build_paths()


func reset_stack() -> void:
	staged = 0
	_pieces.clear()
	_settle = 0.0
	_stack.dropped = {}
	_stack.modulate.a = 1.0


func drop_stage(number: int, animate := true) -> void:
	var gone := _stack.dropped.duplicate()
	while staged < number and staged < 2:
		staged += 1
		var slot_id := "stage1" if staged == 1 else "stage2"
		var rect := _stack.slot_rect(slot_id)
		var texture := _stack.slot_texture(slot_id)
		if animate and texture:
			rect.position += _stack.position
			if staged == 1 and _stack.has_side_boosters():
				var half := texture.get_size() * Vector2(0.5, 1.0)
				_pieces.append({"texture": texture, "rect": Rect2(rect.position, rect.size * Vector2(0.5, 1.0)), "region": Rect2(Vector2.ZERO, half), "age": 0.0, "drift": -70.0})
				_pieces.append({"texture": texture, "rect": Rect2(rect.position + Vector2(rect.size.x * 0.5, 0.0), rect.size * Vector2(0.5, 1.0)), "region": Rect2(Vector2(half.x, 0.0), half), "age": 0.0, "drift": 70.0})
			else:
				_pieces.append({"texture": texture, "rect": rect, "region": Rect2(Vector2.ZERO, texture.get_size()), "age": 0.0, "drift": 0.0})
				var target := _settle + rect.size.y * 0.55
				if is_inside_tree():
					create_tween().tween_property(self, "_settle", target, 0.9).set_trans(Tween.TRANS_SINE)
				else:
					_settle = target
		elif not (staged == 1 and _stack.has_side_boosters()):
			_settle += rect.size.y * 0.55
		gone[slot_id] = true
		if _tower:
			gone["escape"] = true
	_stack.dropped = gone


func _engine_base() -> Vector2:
	var slot_id: String = ["stage1", "stage2", "stage3"][staged]
	if staged == 0 and _stack.has_side_boosters():
		slot_id = "stage2"
	var rect := _stack.slot_rect(slot_id)
	return Vector2(PAD_AXIS, rect.end.y) + _stack.position


func play(from: float, to: float, seconds: float) -> void:
	if _tween:
		_tween.kill()
	progress = from
	_tween = create_tween().set_trans(Tween.TRANS_LINEAR if view == "map" else Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, "progress", to, maxf(seconds, 0.05))


func jump(value: float) -> void:
	if _tween:
		_tween.kill()
	progress = value


func settle_wreck() -> void:
	_wreck = 99.0


func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	return _textures[path]


func _draw() -> void:
	match view:
		"pad", "ascent":
			_draw_launch()
		"map":
			_draw_map()
		"surface":
			_draw_surface()
		"sea":
			_draw_sea()


func _draw_launch() -> void:
	var rise := progress if view == "ascent" else 0.0
	draw_rect(Rect2(Vector2.ZERO, size), Color("5c8aba"))
	var pad := _texture(ART + "pad.jpg")
	var shift := rise * rise * 2600.0
	if pad and shift < size.y:
		draw_texture_rect(pad, Rect2(0.0, shift, size.x, size.y), false)
		var sky := Color("5c8aba")
		draw_polygon(PackedVector2Array([Vector2(0.0, shift - 1.0), Vector2(size.x, shift - 1.0), Vector2(size.x, shift + 90.0), Vector2(0.0, shift + 90.0)]),
				PackedColorArray([sky, sky, Color(sky, 0.0), Color(sky, 0.0)]))
	var dark := clampf(rise * 1.5 - 0.25, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(SPACE, dark))
	if dark > 0.55:
		_draw_stars(clampf((dark - 0.55) * 2.5, 0.0, 1.0))
	var lift := -minf(rise * 4.0, 1.0) * 60.0
	_stack.position = Vector2(0.0, lift + _settle)
	var base := _engine_base()
	for piece: Dictionary in _pieces:
		var age := float(piece["age"])
		var rect: Rect2 = piece["rect"]
		rect.position += Vector2(float(piece["drift"]) * age, 30.0 * age + 150.0 * age * age)
		draw_texture_rect_region(piece["texture"], rect, piece["region"], Color(1, 1, 1, clampf(1.6 - age * 0.7, 0.0, 1.0)))
	if mode == "fail":
		var grow := clampf(_wreck / 1.6, 0.0, 1.0)
		_stack.modulate.a = 1.0 - grow
		for index in 9:
			var angle := index * 0.7 + 0.4
			var at := base + Vector2(cos(angle) * 60.0 * grow, -120.0 + sin(angle) * 90.0 * grow)
			draw_circle(at, 30.0 + 70.0 * grow, Color(0.62, 0.6, 0.58, 0.5))
		draw_circle(base + Vector2(0.0, -110.0), 46.0 * (1.0 - grow) + 12.0, Color(1.0, 0.75, 0.4, 0.8 * (1.0 - grow)))
		return
	_stack.modulate.a = 1.0
	if not burning:
		return
	var fuel := _fuels[mini(staged, 2)]
	var boosters := staged == 0 and _stack.has_side_boosters()
	var color := Color("ffb347")
	var strength := 1.0
	if fuel == "solid":
		color = Color("fff0b8")
	elif fuel == "hydrogen":
		color = Color("cfe6ff")
		strength = 0.6
	elif fuel == "storable":
		color = Color("ff9a5c")
		strength = 0.8
	var flicker := 0.85 + 0.15 * sin(_time * 31.0) * sin(_time * 17.0)
	var length := (150.0 + 130.0 * minf(rise * 3.0, 1.0)) * flicker * (1.0 if staged == 0 else 0.6)
	var width := (46.0 if boosters else 34.0) * (1.0 if staged == 0 else 0.6)
	if fuel == "solid":
		for index in 14:
			var down := 60.0 + index * 46.0
			var puff := 26.0 + index * 9.0
			draw_circle(base + Vector2(sin(_time * 2.0 + index) * 6.0, down), puff, Color(0.93, 0.93, 0.92, 0.32))
	draw_colored_polygon(PackedVector2Array([base + Vector2(-width, 0.0), base + Vector2(width, 0.0), base + Vector2(width * 0.5, length * 0.6), base + Vector2(0.0, length), base + Vector2(-width * 0.5, length * 0.6)]), Color(color, 0.9 * strength))
	draw_colored_polygon(PackedVector2Array([base + Vector2(-width * 0.5, 0.0), base + Vector2(width * 0.5, 0.0), base + Vector2(0.0, length * 0.55)]), Color(1.0, 0.98, 0.9, 0.95 * strength))
	if rise < 0.2 and staged == 0:
		var fade := 1.0 - rise / 0.2
		for index in 10:
			var side := -1.0 if index % 2 == 0 else 1.0
			var spread := 50.0 + index * 34.0 + _time * 14.0
			draw_circle(Vector2(PAD_AXIS + side * spread, PAD_BASE + 26.0 + shift + sin(index * 2.1) * 10.0), 36.0 + index * 5.0, Color(0.95, 0.94, 0.92, 0.42 * fade))


func _draw_stars(alpha: float) -> void:
	var stars := _texture("res://assets/textures/stars.png")
	if stars:
		draw_texture_rect_region(stars, Rect2(Vector2.ZERO, size), Rect2(600.0, 400.0, size.x * 1.6, size.y * 1.6), Color(1, 1, 1, alpha * 0.8))


func _build_paths() -> void:
	if _data.is_empty():
		var file := FileAccess.open(TRAJECTORY, FileAccess.READ)
		if file == null:
			push_error("FlightView: нет файла %s" % TRAJECTORY)
			return
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			_data = parsed
	_legs.clear()
	for leg: String in ["out", "flyby", "back"]:
		var hours := PackedFloat32Array()
		var km := PackedVector2Array()
		var speed := PackedFloat32Array()
		var on_map := PackedVector2Array()
		for point: Array in _data.get(leg, []):
			hours.append(float(point[0]))
			km.append(Vector2(float(point[1]), float(point[2])))
			speed.append(float(point[3]))
			on_map.append(_to_map(km[km.size() - 1]))
		_legs[leg] = {"hours": hours, "km": km, "speed": speed, "map": on_map}


func _to_map(km: Vector2) -> Vector2:
	var scale_by := MAP_SPAN / float(_data.get("moon_distance", 384400.0))
	return MAP_EARTH + Vector2(km.x, -km.y) * scale_by


func _leg_at(leg: String, fraction: float) -> Dictionary:
	var data: Dictionary = _legs.get(leg, {})
	var hours: PackedFloat32Array = data.get("hours", PackedFloat32Array())
	if hours.size() < 2:
		return {"km": Vector2.ZERO, "speed": 0.0, "hours": 0.0, "index": 0}
	var at := clampf(fraction, 0.0, 1.0) * hours[hours.size() - 1]
	var index := 0
	while index < hours.size() - 2 and hours[index + 1] < at:
		index += 1
	var part := clampf((at - hours[index]) / maxf(hours[index + 1] - hours[index], 0.0001), 0.0, 1.0)
	var km: PackedVector2Array = data["km"]
	var speed: PackedFloat32Array = data["speed"]
	return {"km": km[index].lerp(km[index + 1], part), "speed": lerpf(speed[index], speed[index + 1], part), "hours": at, "index": index}


func _draw_leg(leg: String, upto: float, color: Color, width: float, origin: Vector2, body: Vector2, px_per_km: float, clip := 0.0) -> void:
	var data: Dictionary = _legs.get(leg, {})
	var km: PackedVector2Array = data.get("km", PackedVector2Array())
	if km.size() < 2:
		return
	var stop := _leg_at(leg, upto)
	var points := PackedVector2Array()
	for index in int(stop["index"]) + 1:
		points.append(km[index])
	points.append(stop["km"])
	var previous := origin + Vector2(points[0].x - body.x, -(points[0].y - body.y)) * px_per_km
	for index in range(1, points.size()):
		var here := origin + Vector2(points[index].x - body.x, -(points[index].y - body.y)) * px_per_km
		if clip <= 0.0 or (previous.distance_to(origin) < clip and here.distance_to(origin) < clip):
			draw_line(previous, here, color, width, true)
		previous = here


func _draw_plan(leg: String, origin: Vector2, body: Vector2, px_per_km: float, clip := 0.0) -> void:
	var data: Dictionary = _legs.get(leg, {})
	var km: PackedVector2Array = data.get("km", PackedVector2Array())
	if km.size() < 2:
		return
	var color := Color(SILVER, 0.45)
	var travelled := 0.0
	var previous := origin + Vector2(km[0].x - body.x, -(km[0].y - body.y)) * px_per_km
	for index in range(1, km.size()):
		var here := origin + Vector2(km[index].x - body.x, -(km[index].y - body.y)) * px_per_km
		var length := previous.distance_to(here)
		if length > 0.01 and (clip <= 0.0 or (previous.distance_to(origin) < clip and here.distance_to(origin) < clip)):
			var start := 0.0
			while start < length:
				var phase := fposmod(travelled + start, 14.0)
				var step := minf(8.0 - phase if phase < 8.0 else 14.0 - phase, length - start)
				if phase < 8.0:
					draw_line(previous.lerp(here, start / length), previous.lerp(here, (start + step) / length), color, 1.5, true)
				start += maxf(step, 0.01)
		travelled += length
		previous = here


func _draw_ship(at: Vector2) -> void:
	draw_circle(at, 9.0, Color(RED, 0.35 + 0.25 * sin(_time * 4.0)))
	draw_circle(at, 4.5, WHITE)


func _draw_map() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), SPACE)
	_draw_stars(0.55)
	var distance := float(_data.get("moon_distance", 384400.0))
	var earth_radius := float(_data.get("earth_radius", 6378.0))
	var moon_radius := float(_data.get("moon_radius", 1737.0))
	var park := earth_radius + float(_data.get("parking_altitude", 185.0))
	var low := moon_radius + float(_data.get("lunar_orbit_altitude", 110.0))
	var moon_km := Vector2(distance, 0.0)
	var map_scale := MAP_SPAN / distance
	var moon_at := _to_map(moon_km)
	var home := "flyby" if mode == "flyby" else "back"

	var ship_km := Vector2(park, 0.0)
	var speed := float(_data.get("parking_speed", 7.79))
	var clock := ""
	var out_done := 0.0
	var home_done := -1.0
	var turn_angle := 0.0
	var depart := deg_to_rad(float(_data.get("departure_angle", 227.4)))
	var orbit_turn := float(_data.get("orbit_turn", -1))
	var arrive: Vector2 = (_legs["out"]["km"] as PackedVector2Array)[(_legs["out"]["km"] as PackedVector2Array).size() - 1] if _legs.has("out") else moon_km
	var arrive_angle := (arrive - moon_km).angle()
	var near_moon := false
	var halo := Vector2.ZERO
	match mode:
		"earth_orbit":
			turn_angle = depart - TAU * 1.25 * (1.0 - progress)
			ship_km = Vector2(cos(turn_angle), sin(turn_angle)) * park
			clock = "ONE LAP OF THE EARTH: 88 MIN"
		"outbound":
			var at := _leg_at("out", progress)
			ship_km = at["km"]
			speed = at["speed"]
			out_done = progress
			clock = "SINCE THE BURN FOR THE MOON: %s" % _hours_text(float(at["hours"]))
		"moon_orbit":
			out_done = 1.0
			near_moon = true
			if _high_orbit:
				var lap := TAU * progress * 1.5 - PI / 2.0
				halo = Vector2(cos(lap) * 18400.0, sin(lap) * 38240.0)
				ship_km = moon_km
				speed = 0.0
				clock = "ONE LAP OF THE MOON: ABOUT 6.5 DAYS"
			else:
				turn_angle = arrive_angle + orbit_turn * TAU * 2.0 * progress
				ship_km = moon_km + Vector2(cos(turn_angle), sin(turn_angle)) * low
				speed = float(_data.get("lunar_orbit_speed", 1.63))
				clock = "ONE LAP OF THE MOON: 2 HOURS"
		"flyby", "return":
			out_done = 1.0
			home_done = progress
			var at := _leg_at(home, progress)
			ship_km = at["km"]
			speed = at["speed"]
			clock = "SINCE %s: %s" % ["THE FAR SIDE" if mode == "flyby" else "THE BURN FOR HOME", _hours_text(float(at["hours"]))]

	draw_line(MAP_EARTH, moon_at, Color(SILVER, 0.16), 1.0)
	for mark: int in [100000, 200000, 300000]:
		var x := MAP_EARTH.x + mark * map_scale
		draw_line(Vector2(x, MAP_EARTH.y - 5.0), Vector2(x, MAP_EARTH.y + 5.0), Color(SILVER, 0.5), 1.0)
		draw_string(FONT_MONO, Vector2(x - 50.0, MAP_EARTH.y + 22.0), "%d,000 km" % (mark / 1000), HORIZONTAL_ALIGNMENT_CENTER, 100.0, 12, Color(SILVER, 0.65))
	_draw_plan("out", MAP_EARTH, Vector2.ZERO, map_scale)
	_draw_plan(home, MAP_EARTH, Vector2.ZERO, map_scale)
	if out_done > 0.0:
		_draw_leg("out", out_done, WHITE, 2.5, MAP_EARTH, Vector2.ZERO, map_scale)
	if home_done >= 0.0:
		_draw_leg(home, home_done, WHITE, 2.5, MAP_EARTH, Vector2.ZERO, map_scale)
	var earth := _texture(ART + "earth.png")
	var moon := _texture(ART + "moon.png")
	var earth_px := earth_radius * map_scale
	var moon_px := maxf(moon_radius * map_scale, 3.0)
	if earth:
		draw_texture_rect(earth, Rect2(MAP_EARTH - Vector2.ONE * earth_px, Vector2.ONE * earth_px * 2.0), false)
	if moon:
		draw_texture_rect(moon, Rect2(moon_at - Vector2.ONE * moon_px, Vector2.ONE * moon_px * 2.0), false)
	draw_string(FONT, MAP_EARTH + Vector2(-60.0, -24.0), "EARTH", HORIZONTAL_ALIGNMENT_CENTER, 120.0, 15, SILVER)
	draw_string(FONT, moon_at + Vector2(-60.0, -16.0), "MOON", HORIZONTAL_ALIGNMENT_CENTER, 120.0, 15, SILVER)
	if _high_orbit and near_moon:
		draw_circle(moon_at, 7.0, Color(RED, 0.3 + 0.2 * sin(_time * 4.0)))
	else:
		_draw_ship(_to_map(ship_km) if not near_moon else moon_at + (ship_km - moon_km).normalized() * Vector2(1.0, -1.0) * (moon_px + 4.0))

	var earth_zoom := 46.0 / earth_radius
	_draw_lens(EARTH_LENS, MAP_EARTH, "EARTH, CLOSE UP")
	if earth:
		draw_texture_rect(earth, Rect2(EARTH_LENS - Vector2.ONE * 46.0, Vector2.ONE * 92.0), false)
	draw_arc(EARTH_LENS, park * earth_zoom, 0.0, TAU, 96, Color(SILVER, 0.5), 1.0, true)
	_draw_plan("out", EARTH_LENS, Vector2.ZERO, earth_zoom, LENS_RADIUS - 3.0)
	_draw_plan(home, EARTH_LENS, Vector2.ZERO, earth_zoom, LENS_RADIUS - 3.0)
	if mode == "earth_orbit":
		draw_arc(EARTH_LENS, park * earth_zoom, -turn_angle, -turn_angle + TAU * 0.25, 32, WHITE, 2.0, true)
	if out_done > 0.0:
		_draw_leg("out", out_done, WHITE, 2.0, EARTH_LENS, Vector2.ZERO, earth_zoom, LENS_RADIUS - 3.0)
	if home_done >= 0.0:
		_draw_leg(home, home_done, WHITE, 2.0, EARTH_LENS, Vector2.ZERO, earth_zoom, LENS_RADIUS - 3.0)
	var burn_at := EARTH_LENS + Vector2(cos(depart), -sin(depart)) * park * earth_zoom
	draw_circle(burn_at, 3.5, RED)
	var ship_near_earth := EARTH_LENS + Vector2(ship_km.x, -ship_km.y) * earth_zoom
	if ship_near_earth.distance_to(EARTH_LENS) < LENS_RADIUS - 6.0:
		_draw_ship(ship_near_earth)

	_draw_lens(MOON_LENS, moon_at, "MOON, CLOSE UP" if not _high_orbit else "HIGH ORBIT, FROM THE SIDE")
	if _high_orbit:
		var zoom := 95.0 / 38240.0
		var moon_in_lens := MOON_LENS + Vector2(0.0, -33500.0 * zoom)
		var loop := PackedVector2Array()
		for index in 73:
			var angle := TAU * index / 72.0
			loop.append(MOON_LENS + Vector2(cos(angle) * 18400.0, sin(angle) * 38240.0) * zoom)
		draw_polyline(loop, Color(SILVER, 0.5) if not near_moon else WHITE, 1.5 if not near_moon else 2.0, true)
		if moon:
			draw_texture_rect(moon, Rect2(moon_in_lens - Vector2.ONE * 5.0, Vector2.ONE * 10.0), false)
		draw_string(FONT_MONO, MOON_LENS + Vector2(-94.0, 4.0), "70,000 km", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(SILVER, 0.9))
		if near_moon:
			_draw_ship(MOON_LENS + halo * zoom)
	else:
		var moon_zoom := 40.0 / moon_radius
		if moon:
			draw_texture_rect(moon, Rect2(MOON_LENS - Vector2.ONE * 40.0, Vector2.ONE * 80.0), false)
		draw_arc(MOON_LENS, low * moon_zoom, 0.0, TAU, 96, Color(SILVER, 0.5), 1.0, true)
		_draw_plan("out", MOON_LENS, moon_km, moon_zoom, LENS_RADIUS - 3.0)
		_draw_plan(home, MOON_LENS, moon_km, moon_zoom, LENS_RADIUS - 3.0)
		if out_done > 0.0:
			_draw_leg("out", out_done, WHITE, 2.0, MOON_LENS, moon_km, moon_zoom, LENS_RADIUS - 3.0)
		if home_done >= 0.0:
			_draw_leg(home, home_done, WHITE, 2.0, MOON_LENS, moon_km, moon_zoom, LENS_RADIUS - 3.0)
		if mode == "moon_orbit":
			draw_arc(MOON_LENS, low * moon_zoom, 0.0, TAU, 96, WHITE, 2.0, true)
		var longitude := deg_to_rad(_site_longitude)
		var site_at := MOON_LENS + Vector2(-cos(longitude), sin(longitude)) * 40.0 * cos(deg_to_rad(_site_latitude))
		draw_circle(site_at, 4.0, RED)
		draw_circle(site_at, 4.0, WHITE, false, 1.0)
		draw_string(FONT_MONO, MOON_LENS + Vector2(-80.0, 66.0), "near side", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(SILVER, 0.9))
		draw_string(FONT_MONO, MOON_LENS + Vector2(16.0, 66.0), "far side", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(SILVER, 0.9))
		var ship_near_moon := MOON_LENS + Vector2(ship_km.x - moon_km.x, -(ship_km.y - moon_km.y)) * moon_zoom
		if ship_near_moon.distance_to(MOON_LENS) < LENS_RADIUS - 6.0:
			_draw_ship(ship_near_moon)

	var from_earth := maxf(ship_km.length() - earth_radius, 0.0)
	var to_moon := maxf(ship_km.distance_to(moon_km) - moon_radius, 0.0)
	if _high_orbit and near_moon:
		to_moon = halo.distance_to(Vector2(0.0, -33500.0)) - moon_radius
	var left := 300.0
	_draw_number(Vector2(left, 388.0), "ABOVE THE EARTH", "%s km" % _thousands(roundi(from_earth)))
	_draw_number(Vector2(left + 230.0, 388.0), "TO THE MOON'S SURFACE", "%s km" % _thousands(roundi(to_moon)))
	if speed > 0.0:
		_draw_number(Vector2(left, 454.0), "SPEED" if not near_moon else "SPEED AROUND THE MOON", "%.2f km/s" % speed)
		_draw_number(Vector2(left + 230.0, 454.0), "THAT IS", "%s km/h" % _thousands(roundi(speed * 3600.0)))
	draw_string(FONT_MONO, Vector2(left, 532.0), clock, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(SILVER, 0.95))
	draw_string(FONT_MONO, Vector2(left, 558.0), "Path computed from the pull of Earth and Moon. Distances to scale.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(SILVER, 0.7))
	draw_string(FONT_MONO, Vector2(left, 574.0), "The view turns with the Moon, so the Moon stays on the right.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(SILVER, 0.7))
	draw_string(FONT_MONO, Vector2(left, 590.0), "Red dots: the burn for the Moon and the landing site.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(SILVER, 0.7))


func _draw_number(at: Vector2, caption: String, value: String) -> void:
	draw_string(FONT_MONO, at, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(SILVER, 0.9))
	draw_string(FONT_MONO, at + Vector2(0.0, 30.0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 25, WHITE)


func _draw_lens(center: Vector2, target: Vector2, title: String) -> void:
	var toward := (target - center).normalized()
	draw_line(center + toward * LENS_RADIUS, target - toward * 16.0, Color(SILVER, 0.35), 1.0, true)
	draw_circle(center, LENS_RADIUS, Color("0a111d"))
	draw_circle(center, LENS_RADIUS, Color(SILVER, 0.75), false, 2.0, true)
	draw_string(FONT_MONO, center + Vector2(-LENS_RADIUS - 12.0, -LENS_RADIUS - 10.0), title, HORIZONTAL_ALIGNMENT_CENTER, LENS_RADIUS * 2.0 + 24.0, 12, SILVER)


func _hours_text(hours: float) -> String:
	var whole := int(hours)
	return "%d H" % whole if whole < 24 else "%d D %02d H" % [whole / 24, whole % 24]


func _thousands(value: int) -> String:
	var text := str(absi(value))
	var out := ""
	while text.length() > 3:
		out = "," + text.substr(text.length() - 3) + out
		text = text.substr(0, text.length() - 3)
	return text + out


func _draw_surface() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
	var picture := _texture(CATALOG + _site + ".png")
	if picture:
		var scale_up := size.y / picture.get_height()
		var width := picture.get_width() * scale_up
		draw_texture_rect(picture, Rect2((size.x - width) * 0.5, 0.0, width, size.y), false)
	var lander := _texture(ART + _lander + ".png")
	if lander == null:
		return
	var tall := _lander == "lander_hls"
	var scale_down := 0.74 if tall else 0.56
	var box := lander.get_size() * scale_down
	var ground := 474.0
	var height := 0.0
	var firing := false
	match mode:
		"descent":
			height = (1.0 - progress) * (1.0 - progress) * 620.0
			firing = progress < 0.985
		"abort":
			var down := minf(progress / 0.55, 1.0)
			var up := clampf((progress - 0.6) / 0.4, 0.0, 1.0)
			height = (1.0 - down * 0.72) * 520.0 + up * up * 700.0
			firing = true
	var feet := Vector2(470.0, ground - height)
	var near := clampf(1.0 - height / 300.0, 0.0, 1.0)
	draw_set_transform(Vector2(feet.x + box.x * 0.42, ground + 4.0), 0.0, Vector2(1.0, 0.16))
	draw_circle(Vector2.ZERO, box.x * 0.62, Color(0, 0, 0, 0.6 * near))
	draw_set_transform(Vector2.ZERO)
	if firing:
		var flicker := 0.8 + 0.2 * sin(_time * 29.0)
		var nozzle := feet + Vector2(0.0, -box.y * 0.14)
		draw_colored_polygon(PackedVector2Array([nozzle + Vector2(-9.0, 0.0), nozzle + Vector2(9.0, 0.0), nozzle + Vector2(20.0, 64.0 * flicker), nozzle + Vector2(-20.0, 64.0 * flicker)]), Color(1.0, 0.97, 0.9, 0.45))
		if height < 90.0:
			for index in 8:
				var side := -1.0 if index % 2 == 0 else 1.0
				var out := 40.0 + index * 30.0 + fposmod(_time * 60.0, 30.0)
				draw_circle(Vector2(feet.x + side * out, ground - 6.0 - index * 1.5), 18.0 + index * 3.0, Color(0.8, 0.79, 0.76, 0.22 * (1.0 - height / 90.0)))
	draw_texture_rect(lander, Rect2(feet.x - box.x * 0.5, feet.y - box.y, box.x, box.y), false)
	if mode == "landed":
		for index in walkers:
			_draw_walker(Vector2(feet.x - box.x * 0.5 - 60.0 - index * 58.0 + sin(_time * 0.7 + index * 2.0) * 10.0, ground + 14.0 + index * 9.0), 1.0 if not tall else 0.8)


func _draw_walker(feet: Vector2, scale_by: float) -> void:
	var s := 1.0 * scale_by
	draw_set_transform(Vector2(feet.x + 16.0 * s, feet.y + 1.0), 0.0, Vector2(1.0, 0.2))
	draw_circle(Vector2.ZERO, 16.0 * s, Color(0, 0, 0, 0.55))
	draw_set_transform(Vector2.ZERO)
	var suit := Color("eef0f2")
	draw_rect(Rect2(feet.x - 7.0 * s, feet.y - 20.0 * s, 6.0 * s, 20.0 * s), suit)
	draw_rect(Rect2(feet.x + 1.0 * s, feet.y - 20.0 * s, 6.0 * s, 20.0 * s), suit)
	draw_rect(Rect2(feet.x - 9.0 * s, feet.y - 42.0 * s, 18.0 * s, 24.0 * s), suit)
	draw_rect(Rect2(feet.x - 15.0 * s, feet.y - 44.0 * s, 7.0 * s, 22.0 * s), Color("c9ced4"))
	draw_circle(Vector2(feet.x, feet.y - 50.0 * s), 9.0 * s, suit)
	draw_circle(Vector2(feet.x + 3.0 * s, feet.y - 50.0 * s), 5.5 * s, Color("d4a544"))


func _draw_sea() -> void:
	var sea := _texture(ART + "sea.jpg")
	if sea:
		draw_texture_rect(sea, Rect2(Vector2.ZERO, size), false)
	var capsule := _texture(VEHICLE + _capsule + ".png")
	if capsule == null:
		return
	var box := capsule.get_size() * 0.8
	var water := 446.0
	var down := clampf(progress / 0.8, 0.0, 1.0)
	var floating := progress >= 0.8
	var at := Vector2(430.0 + sin(_time * 0.8) * 4.0 * (1.0 - down), lerpf(-140.0, water, down))
	if floating:
		at.y = water + sin(_time * 1.6) * 3.0
	var top := at + Vector2(0.0, -box.y)
	var open := clampf(1.0 - (progress - 0.8) / 0.12, 0.0, 1.0)
	if open > 0.0:
		for index in 3:
			var center := top + Vector2((index - 1) * 92.0, -170.0 - (20.0 if index == 1 else 0.0))
			_draw_canopy(center, 58.0, open)
			draw_line(center + Vector2(-56.0, 0.0), top, Color(1, 1, 1, 0.75 * open), 1.2, true)
			draw_line(center + Vector2(56.0, 0.0), top, Color(1, 1, 1, 0.75 * open), 1.2, true)
			draw_line(center, top, Color(1, 1, 1, 0.5 * open), 1.0, true)
	draw_texture_rect(capsule, Rect2(at.x - box.x * 0.5, at.y - box.y + (10.0 if floating else 0.0), box.x, box.y), false)
	if floating:
		draw_rect(Rect2(at.x - box.x * 0.6, at.y - 4.0, box.x * 1.2, 16.0), Color("123e68"))
		draw_set_transform(Vector2(at.x, at.y - 3.0), 0.0, Vector2(1.0, 0.14))
		draw_arc(Vector2.ZERO, box.x * 0.62, 0.0, TAU, 40, Color(1, 1, 1, 0.75), 14.0, true)
		draw_arc(Vector2.ZERO, box.x * (0.8 + 0.25 * fposmod(_time * 0.35, 1.0)), 0.0, TAU, 40, Color(1, 1, 1, 0.35 * (1.0 - fposmod(_time * 0.35, 1.0))), 8.0, true)
		draw_set_transform(Vector2.ZERO)


func _draw_canopy(center: Vector2, radius: float, alpha: float) -> void:
	var gores := 8
	for index in gores:
		var from := PI + PI * index / gores
		var to := PI + PI * (index + 1) / gores
		var points := PackedVector2Array([center])
		for step in 5:
			var angle := lerpf(from, to, step / 4.0)
			points.append(center + Vector2(cos(angle) * radius, sin(angle) * radius * 0.78))
		draw_colored_polygon(points, Color(RED if index % 2 == 0 else WHITE, alpha))
