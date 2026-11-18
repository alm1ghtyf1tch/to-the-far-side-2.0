class_name LunarScene3D
extends Node3D
## Presentation only. Never writes campaign state. One cached mesh and material.

const RADIUS := 2.65
var camera: OrbitCameraController
var moon: MeshInstance3D
var markers: Array[Node3D] = []
var selected := -1
var previewed := -1
var _paints: Array[StandardMaterial3D] = []


func _ready() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("070e19")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("63849b")
	environment.ambient_light_energy = 0.12
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	add_child(environment_node)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("fff0d7")
	sun.light_energy = 1.45
	add_child(sun)
	sun.look_at(-Vector3(-0.75, 0.45, 0.65), Vector3.UP)
	moon = MeshInstance3D.new()
	moon.name = "FixedMoon"
	var sphere := SphereMesh.new()
	sphere.radius = RADIUS
	sphere.height = RADIUS * 2.0
	sphere.radial_segments = 256
	sphere.rings = 128
	moon.mesh = sphere
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/lunar/lunar_surface.gdshader")
	material.set_shader_parameter("albedo_map", preload("res://assets/moon/lroc_color_2k.jpg"))
	material.set_shader_parameter("elevation_map", preload("res://assets/moon/lola_height_2k.png"))
	moon.material_override = material
	add_child(moon)
	camera = OrbitCameraController.new()
	add_child(camera)
	for site: Dictionary in Campaign.sites():
		var marker := Node3D.new()
		var normal := LunarCoordinates.from_site(site)
		marker.position = normal * (RADIUS + 0.028)
		add_child(marker)
		marker.quaternion = Quaternion(Vector3.UP, normal)
		var mesh := MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius = 0.025
		ring.outer_radius = 0.039
		ring.rings = 16
		ring.ring_segments = 6
		mesh.mesh = ring
		var ink := StandardMaterial3D.new()
		ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.material_override = ink
		marker.add_child(mesh)
		markers.append(marker)
		_paints.append(ink)
	set_states(-1, -1)
	_build_stars()


func _build_stars() -> void:
	var stars := MultiMeshInstance3D.new()
	var points := MultiMesh.new()
	points.transform_format = MultiMesh.TRANSFORM_3D
	points.use_colors = true
	var shape := SphereMesh.new()
	shape.radius = 0.018
	shape.height = 0.036
	shape.radial_segments = 6
	shape.rings = 3
	points.mesh = shape
	points.instance_count = 600
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.vertex_color_use_as_albedo = true
	stars.material_override = paint
	stars.multimesh = points
	add_child(stars)
	var random := RandomNumberGenerator.new()
	random.seed = 4720
	for index in points.instance_count:
		var direction_value := LunarCoordinates.direction(rad_to_deg(asin(random.randf_range(-1, 1))), random.randf_range(-180, 180))
		var transform_value := Transform3D.IDENTITY
		transform_value.origin = direction_value * 40.0
		points.set_instance_transform(index, transform_value)
		points.set_instance_color(index, Color("a2c0cf") * random.randf_range(0.2, 0.7))


func set_states(selection: int, preview: int) -> void:
	selected = selection
	previewed = preview
	for index in markers.size():
		_paints[index].albedo_color = VisualTheme.AMBER if index == selected else (VisualTheme.CYAN if index == previewed else Color("b7c6c8"))
		markers[index].scale = Vector3.ONE * (1.65 if index == selected else (1.4 if index == previewed else 0.75))


func preview_site(index: int) -> void:
	previewed = index
	camera.target_site(Campaign.sites()[index])
	set_states(selected, index)
