extends Node3D
## Fixed front observation view using the original game's screen-to-metre mapping.
## Reads LandingGame; never integrates motion or determines a result.

var models := SpacecraftModels.new()
var body: Node3D
var flame: MeshInstance3D
var _jets: Node3D
var _abort_age := 0.0


func build(game: LandingGame) -> void:
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("070f1b")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("869bae")
	world.environment.ambient_light_energy = 0.35
	add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -45, 0)
	light.light_color = Color("f6e8cb")
	light.light_energy = 1.5
	add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.0
	camera.position = Vector3(0, 0, 20)
	add_child(camera)
	var p := models.p
	# 600 display pixels span 12 units. Ground +14 is the original feet plane.
	p.box(self, Vector3(0, -5.0, -1), Vector3(22, 2.48, 5), "moon")
	for i in 15:
		var hill := p.sphere(self, Vector3(-12 + i * 1.7, -3.8, -5), 1.4 + (i % 3) * 0.35, "edge")
		hill.scale.y = 0.3
	for rock: Array in game._rocks:
		var radius := float(rock[1]) * 0.068
		var object := p.sphere(self, Vector3(float(rock[0]) * 0.0816, -3.76 + radius * 0.25, 1.6), radius, "mare")
		object.scale = Vector3(1, 0.7, 0.8)
	if int(game._setup.get("training", 1)) >= 1:
		for zone: Vector2 in game._clear:
			p.box(self, Vector3((zone.x + zone.y) * 0.0408, -3.75, 1.8), Vector3((zone.y - zone.x) * 0.0816, 0.035, 0.04), "teal")
	body = models.module("lander", Vehicle.chosen({"lander": game._lander}, "lander"))
	body.scale = Vector3.ONE * (0.65 if game._lander == "lander_hls" else 0.85)
	add_child(body)
	var shape := CylinderMesh.new()
	shape.top_radius = 0.1
	shape.bottom_radius = 0.012
	shape.height = 0.85
	shape.radial_segments = 8
	flame = MeshInstance3D.new()
	flame.mesh = shape
	flame.material_override = p.material(Color("ffe6b0"), true)
	flame.position = Vector3(0, -0.9, 0)
	body.add_child(flame)
	_jets = Node3D.new()
	body.add_child(_jets)
	for side in [-1, 1]:
		p.cylinder(_jets, Vector3(side * 0.65, 0.3, 0.1), 0.04, 0.3, "paper", 0).rotation.z = PI * 0.5
	sync(game, 0.0)


func sync(game: LandingGame, delta: float) -> void:
	if body == null:
		return
	body.position = Vector3(game._x * 0.0816, -3.76 + game._height * 0.05 + 0.76 * body.scale.y, 2)
	flame.visible = game._engine
	_jets.visible = game._push != 0.0
	if game._over:
		if game._outcome.get("result") == "hard":
			body.rotation.z = 0.15
		elif game._outcome.get("result") == "abort":
			_abort_age += delta
			body.position.y += _abort_age * 1.2
			flame.show()
