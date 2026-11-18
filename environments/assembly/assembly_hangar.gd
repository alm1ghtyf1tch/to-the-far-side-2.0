class_name AssemblyHangar
extends Node3D
## Authored industrial integration hall. No campaign or engineering state writes.

var camera: Camera3D
var rocket: AssemblyRocket
var _hook: Node3D
var _beacon: StandardMaterial3D
var _time := 0.0
var _site_label: Label3D
var _framing: Tween


func _ready() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("101c2d")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("6b8aa6")
	environment.ambient_light_energy = 0.32
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("263c50")
	environment.fog_density = 0.007
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-24, -25, 0)
	sun.light_color = Color("ffe5bd")
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(15, 155, 0)
	fill.light_color = Color("6fb7ed")
	fill.light_energy = 0.55
	add_child(fill)
	var p := HQProps.new()
	# Local hall materials keep the bright vehicle separated from its backdrop.
	(p.materials["edge"] as StandardMaterial3D).albedo_color = Color("172b40")
	(p.materials["metal"] as StandardMaterial3D).albedo_color = Color("40586a")
	(p.materials["glass"] as StandardMaterial3D).albedo_color = Color("1a3d55")
	p.box(self, Vector3(0, -5.4, 0), Vector3(32, 0.5, 27), "floor")
	p.box(self, Vector3(0, 4.0, -8), Vector3(30, 19, 0.5), "edge")
	p.box(self, Vector3(-13, 4, 0), Vector3(0.5, 19, 18), "dark")
	# The camera-facing wall is cut away so the world continues under all overlays.
	for i in 13:
		var x := -12.0 + i * 2.0
		p.box(self, Vector3(x, 4, -7.65), Vector3(0.16, 18, 0.2), "metal")
		p.box(self, Vector3(x, 10, -7.4), Vector3(0.9, 0.16, 0.08), "paper")
	for y in [-2.0, 1.0, 4.0, 7.0, 10.0]:
		p.box(self, Vector3(0, y, -7.3), Vector3(26, 0.18, 0.35), "dark")
		for x in [-9.0, -5.0, 5.0, 9.0]:
			p.box(self, Vector3(x, y + 0.8, -7.5), Vector3(1.4, 0.7, 0.06), "glass")
	# Gantries remain behind the vehicle, preserving its complete silhouette.
	for x in [-4.2, 4.2]:
		p.box(self, Vector3(x, 1.5, -2.3), Vector3(0.35, 13, 0.4), "navy")
		for y in [-2.0, 0.5, 3.0, 5.5]:
			p.box(self, Vector3(x * 0.75, y, -2), Vector3(2.6, 0.14, 1.4), "metal")
			p.rod(self, Vector3(x - 1.2, y + 0.6, -1.35), Vector3(x + 1.2, y + 0.6, -1.35), 0.035, "gold")
			for rail in 5:
				p.rod(self, Vector3(x - 1.2 + rail * 0.6, y, -1.35), Vector3(x - 1.2 + rail * 0.6, y + 0.6, -1.35), 0.025, "metal")
	p.box(self, Vector3(0, -5.0, 0), Vector3(4.6, 0.45, 4.2), "dark")
	for i in 16:
		p.box(self, Vector3(-2.1 + i * 0.28, -4.76, 2.13), Vector3(0.12, 0.08, 0.08), "gold")
	for side in [-1, 1]:
		p.box(self, Vector3(side * 3.1, -5.13, 3), Vector3(0.08, 0.02, 14), "gold")
		for stripe in 9:
			p.box(self, Vector3(side * (3.4 + stripe * 0.3), -5.12, 6), Vector3(0.12, 0.015, 2.0), "paper").rotation.y = 0.6
	for i in 4:
		p.box(self, Vector3(-7, -5.0 + i * 0.15, 1 - i * 0.3), Vector3(2.0, 0.15, 1.0), "metal")
	p.box(self, Vector3(0, 8.3, -2), Vector3(25, 0.6, 0.7), "gold")
	_hook = Node3D.new()
	_hook.position = Vector3(1.8, 7.8, -1.8)
	add_child(_hook)
	p.cylinder(_hook, Vector3(0, -0.7, 0), 0.016, 1.4, "metal")
	p.box(_hook, Vector3(0, -1.5, 0), Vector3(0.32, 0.35, 0.24), "gold")
	_beacon = p.material(VisualTheme.AMBER, true)
	p.mesh(_hook, Vector3(0, 0.2, 0), _lamp_mesh(), _beacon)
	for x in [-5.0, 5.0]:
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(x, 5, 2)
		lamp.omni_range = 10
		lamp.light_energy = 1.2
		lamp.light_color = Color("f5cc84")
		add_child(lamp)
	p.caption(self, Vector3(-7.4, 5.5, -7.0), "06", 190, Color("e6bd6b"))
	p.caption(self, Vector3(3.4, 8, -7.0), "VEHICLE INTEGRATION", 50)
	_site_label = p.caption(self, Vector3(6.5, -2.8, -6.9), "LAUNCH SITE\nUNASSIGNED", 35, VisualTheme.CYAN)
	rocket = AssemblyRocket.new()
	add_child(rocket)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 13.8
	camera.position = Vector3(15, 8, 26)
	camera.far = 100
	add_child(camera)
	camera.look_at(Vector3(1.5, 0.5, 0), Vector3.UP)
	rocket.configuration_changed.connect(_frame_vehicle)


func _frame_vehicle(height: float) -> void:
	# Tall mixed configurations still fit; the hero remains centred without orbiting.
	if _framing:
		_framing.kill()
	var extent := maxf(13.8, height * 1.24)
	var focus := Vector3(1.5, maxf(0.5, -4.65 + height * 0.5), 0)
	var target := camera.transform.looking_at(focus, Vector3.UP)
	if GameSettings.reduced_motion():
		camera.size = extent
		camera.transform = target
	else:
		_framing = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_framing.tween_property(camera, "size", extent, 0.26)
		_framing.tween_property(camera, "quaternion", target.basis.get_rotation_quaternion(), 0.26)


func _lamp_mesh() -> SphereMesh:
	var shape := SphereMesh.new()
	shape.radius = 0.12
	shape.height = 0.24
	shape.radial_segments = 8
	shape.rings = 4
	return shape


func set_site(part: Dictionary) -> void:
	_site_label.text = "LAUNCH SITE\n" + str(part.get("short", "UNASSIGNED")).to_upper()


func _process(delta: float) -> void:
	if GameSettings.reduced_motion():
		_hook.position.x = 1.8
		_beacon.emission_energy_multiplier = 0.65
		return
	_time += delta
	_hook.position.x = 1.8 + sin(_time * 0.45) * 0.035
	_beacon.emission_energy_multiplier = 0.65 + sin(_time * 1.4) * 0.1
