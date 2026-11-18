class_name HQProps
extends RefCounted
## Authored low-poly furniture made from shared primitive resources.

var materials := {}
var _boxes := {}

const PALETTE := {
	"shell": "b8c5ca", "edge": "334c63", "floor": "26374b", "dark": "101f30",
	"navy": "23476c", "wood": "b78352", "paper": "e0e6df", "gold": "e8b84f",
	"teal": "358a91", "green": "668c79", "red": "bb5548", "metal": "80959c",
	"moon": "b8bdb6", "mare": "777f7c", "glass": "407887",
}


func _init() -> void:
	for key: String in PALETTE:
		materials[key] = material(Color(PALETTE[key]))
	var glass := materials["glass"] as StandardMaterial3D
	glass.emission_enabled = true
	glass.emission = Color(0.025, 0.085, 0.11)
	glass.emission_energy_multiplier = 0.7


func material(color: Color, luminous := false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.86
	if luminous:
		result.emission_enabled = true
		result.emission = color
		result.emission_energy_multiplier = 0.65
	return result


func box(parent: Node3D, at: Vector3, dimensions: Vector3, paint: String) -> MeshInstance3D:
	if not _boxes.has(dimensions):
		var shape := BoxMesh.new()
		shape.size = dimensions
		_boxes[dimensions] = shape
	return mesh(parent, at, _boxes[dimensions], materials[paint])


func mesh(parent: Node3D, at: Vector3, shape: Mesh, paint: Material) -> MeshInstance3D:
	var object := MeshInstance3D.new()
	object.mesh = shape
	object.material_override = paint
	object.position = at
	parent.add_child(object)
	return object


func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, paint: String, top := -1.0) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.bottom_radius = radius
	shape.top_radius = radius if top < 0.0 else top
	shape.height = height
	shape.radial_segments = 12
	shape.rings = 1
	return mesh(parent, at, shape, materials[paint])


func sphere(parent: Node3D, at: Vector3, radius: float, paint: String) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2.0
	shape.radial_segments = 16
	shape.rings = 8
	return mesh(parent, at, shape, materials[paint])


func rod(parent: Node3D, from: Vector3, to: Vector3, radius: float, paint: String) -> MeshInstance3D:
	var object := cylinder(parent, (from + to) * 0.5, radius, from.distance_to(to), paint)
	object.quaternion = Quaternion(Vector3.UP, (to - from).normalized())
	return object


func caption(parent: Node3D, at: Vector3, text: String, size := 30, color := Color("e0e6df")) -> Label3D:
	var label := Label3D.new()
	label.font = VisualTheme.MONO
	label.font_size = size
	label.pixel_size = 0.007
	label.text = text
	label.modulate = color
	label.outline_size = 0
	label.position = at
	parent.add_child(label)
	return label


func monitor(parent: Node3D, at: Vector3, color: String, wide := false) -> Node3D:
	var root := Node3D.new()
	root.position = at
	parent.add_child(root)
	var width := 1.65 if wide else 1.15
	box(root, Vector3.ZERO, Vector3(width, 0.84, 0.16), "dark")
	box(root, Vector3(0, 0, 0.09), Vector3(width - 0.13, 0.68, 0.02), "glass")
	var ink := material(Color(PALETTE[color]), true)
	ink.emission_energy_multiplier = 0.45
	for i in 5:
		var bar := box(root, Vector3(-width * 0.3 + i * width * 0.14, -0.16, 0.115), Vector3(0.09, 0.16 + float(i % 3) * 0.13, 0.025), color)
		bar.material_override = ink
	box(root, Vector3(0, -0.6, 0), Vector3(0.1, 0.38, 0.1), "metal")
	box(root, Vector3(0, -0.8, 0.1), Vector3(0.65, 0.06, 0.38), "dark")
	return root


func chair(parent: Node3D, at: Vector3, angle := 0.0, paint := "navy") -> void:
	var root := Node3D.new()
	root.position = at
	root.rotation.y = angle
	parent.add_child(root)
	cylinder(root, Vector3(0, 0.28, 0), 0.07, 0.48, "metal")
	box(root, Vector3(0, 0.58, 0), Vector3(0.65, 0.18, 0.62), paint)
	box(root, Vector3(0, 1.0, -0.23), Vector3(0.65, 0.8, 0.17), paint)
	box(root, Vector3(0, 0.06, 0), Vector3(0.72, 0.08, 0.16), "dark")
	box(root, Vector3(0, 0.06, 0), Vector3(0.16, 0.08, 0.72), "dark")


func desk(parent: Node3D, at: Vector3, width: float, paint := "paper") -> void:
	box(parent, at + Vector3(0, 0.78, 0), Vector3(width, 0.15, 1.05), paint)
	for x: float in [-width * 0.39, width * 0.39]:
		box(parent, at + Vector3(x, 0.36, 0), Vector3(0.5, 0.7, 0.8), "edge")


func rocket(parent: Node3D, at: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = at
	parent.add_child(root)
	cylinder(root, Vector3(0, 0.95, 0), 0.35, 1.7, "paper")
	cylinder(root, Vector3(0, 1.9, 0), 0.35, 0.45, "paper", 0.0)
	cylinder(root, Vector3(0, 0.13, 0), 0.25, 0.27, "dark", 0.13)
	for y: float in [0.56, 1.36]:
		cylinder(root, Vector3(0, y, 0), 0.355, 0.14, "navy")
	for x: float in [-0.44, 0.44]:
		cylinder(root, Vector3(x, 0.65, 0), 0.13, 1.1, "metal")
		cylinder(root, Vector3(x, 1.3, 0), 0.13, 0.2, "gold", 0.0)
	return root
