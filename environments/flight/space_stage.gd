class_name SpaceflightStage
extends Node3D
## One camera transform, authored once. Mission phases change stage props only.

var camera: Camera3D
var spacecraft: SpacecraftVisual
var earth: MeshInstance3D
var moon: MeshInstance3D
var terrain: Node3D
var ocean: Node3D
var context := "earth"
var _camera_pose: Transform3D


func _ready() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("050b15")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("62809b")
	environment.ambient_light_energy = 0.33
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("ffe8c8")
	sun.light_energy = 1.8
	add_child(sun)
	sun.rotation_degrees = Vector3(-25, -38, 0)
	var rim := DirectionalLight3D.new()
	rim.light_color = Color("79b5da")
	rim.light_energy = 0.75
	add_child(rim)
	rim.rotation_degrees = Vector3(20, 140, 0)
	camera = Camera3D.new()
	camera.name = "FixedObservationCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 14.0
	camera.position = Vector3(11, 6, 23)
	camera.far = 120.0
	add_child(camera)
	camera.look_at(Vector3(0, 0.3, 0), Vector3.UP)
	_camera_pose = camera.transform
	earth = FlightPlanets.earth()
	earth.position = Vector3(-5.8, 0.6, -7.0)
	earth.rotation_degrees.y = 26
	add_child(earth)
	moon = FlightPlanets.moon()
	moon.position = Vector3(-5.2, -0.4, -7.0)
	add_child(moon)
	var props := HQProps.new()
	terrain = Node3D.new()
	add_child(terrain)
	props.box(terrain, Vector3(0, -3.9, -1), Vector3(15, 0.75, 13), "moon")
	var random := RandomNumberGenerator.new()
	random.seed = 1969
	for i in 45:
		var rock := props.sphere(terrain, Vector3(random.randf_range(-7, 7), -3.45, random.randf_range(-6, 5)), random.randf_range(0.08, 0.35), "mare")
		rock.scale.y = 0.55
	ocean = Node3D.new()
	add_child(ocean)
	props.box(ocean, Vector3(0, -4.15, -1), Vector3(24, 0.4, 18), "glass")
	for i in 18:
		props.box(ocean, Vector3(-9 + i, -3.93, -1 + (i % 4)), Vector3(0.5 + (i % 3) * 0.4, 0.02, 0.08), "teal")
	spacecraft = SpacecraftVisual.new()
	add_child(spacecraft)
	_build_stars(props)
	set_context("earth")


func set_context(value: String) -> void:
	context = value
	earth.visible = value in ["earth", "surface"]
	earth.scale = Vector3.ONE * (0.2 if value == "surface" else 1.0)
	earth.position = Vector3(-6, 3.8, -12) if value == "surface" else Vector3(-5.8, 0.6, -7.0)
	moon.visible = value == "moon"
	terrain.visible = value == "surface"
	ocean.visible = value == "recovery"


func _build_stars(props: HQProps) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	var point := SphereMesh.new()
	point.radius = 0.025
	point.height = 0.05
	point.radial_segments = 4
	point.rings = 2
	multimesh.mesh = point
	multimesh.instance_count = 350
	var random := RandomNumberGenerator.new()
	random.seed = 4047
	for index in multimesh.instance_count:
		var transform_value := Transform3D.IDENTITY
		transform_value.origin = Vector3(random.randf_range(-32, 32), random.randf_range(-20, 20), random.randf_range(-35, -20))
		multimesh.set_instance_transform(index, transform_value)
		multimesh.set_instance_color(index, Color("8eabb6") * random.randf_range(0.25, 0.75))
	var stars := MultiMeshInstance3D.new()
	stars.multimesh = multimesh
	var ink := props.material(Color.WHITE)
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.vertex_color_use_as_albedo = true
	stars.material_override = ink
	add_child(stars)
