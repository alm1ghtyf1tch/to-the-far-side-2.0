class_name HeadquartersDiorama
extends Node3D
## Pure presentation: no campaign writes, routing, clocks, or simulation decisions.

signal framing_changed

const FLOOR_HEIGHT := 3.2
const HOME_EYE := Vector3(15.5, 11.3, 30.0)
const HOME_TARGET := Vector3(0, 4.5, 0)
const ACCENTS := [Color("54c7ba"), Color("57a9dd"), Color("edc16b")]

@onready var camera: Camera3D = %Camera

var props := HQProps.new()
var rooms: Array[Node3D] = []
var _strips: Array[StandardMaterial3D] = []
var _wash: Array[OmniLight3D] = []
var _levels: Array[float] = [0.0, 0.0, 0.0]
var _hovered := -1
var _goal := -1
var _time := 0.0
var _rocket: Node3D
var _globe: Node3D
var _dish: Node3D
var _board_status: Label3D
var _science_status: Label3D
var _engineering_status: Label3D
var _camera_tween: Tween
var _programme_ticks: Array[MeshInstance3D] = []
var _tick_active: StandardMaterial3D


func _ready() -> void:
	camera.position = HOME_EYE
	camera.look_at(HOME_TARGET)
	_build_shell()
	_board_room(rooms[2])
	_engineering_room(rooms[1])
	_science_room(rooms[0])
	_roof()
	get_viewport().size_changed.connect(func() -> void: framing_changed.emit())
	GameSettings.events.visuals_changed.connect(_motion_changed)


func set_programme(stage: int, site: Dictionary, design: Dictionary) -> void:
	_board_status.text = "STAGE %02d / 11" % stage
	for index in _programme_ticks.size():
		_programme_ticks[index].material_override = _tick_active if index < stage else props.materials["edge"]
	_science_status.text = "LUNAR SURVEY" if site.is_empty() else str(site.get("mission", "")) + "\n" + str(site.get("name", "")).to_upper()
	_engineering_status.text = "VEHICLE CONCEPT" if design.is_empty() else "%02d SECTIONS\nDESIGN FILED" % design.size()
	# Development is visible on the existing prototype, without inventing progress.
	_rocket.scale = Vector3.ONE * (0.82 if stage < 6 else 1.0)


func set_goal(index: int) -> void:
	_goal = index


func hover_room(index: int) -> void:
	_hovered = index


func room_polygon(index: int) -> PackedVector2Array:
	var base := FLOOR_HEIGHT * index
	var points := PackedVector2Array()
	for point: Vector3 in [Vector3(-7.45, base + 2.92, 2.34), Vector3(7.45, base + 2.92, 2.34), Vector3(7.45, base + 0.12, 2.34), Vector3(-7.45, base + 0.12, 2.34)]:
		points.append(camera.unproject_position(to_global(point)))
	return points


func enter_room(index: int, duration := 0.8) -> void:
	if _camera_tween:
		_camera_tween.kill()
	if GameSettings.reduced_motion():
		return
	var target := Vector3(0, index * FLOOR_HEIGHT + 1.35, 0.4)
	_camera_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_camera_tween.tween_method(func(weight: float) -> void:
		var aim := HOME_TARGET.lerp(target, weight)
		camera.position = HOME_EYE.lerp(target + Vector3(9, 5.8, 20), weight)
		camera.size = lerpf(12.8, 8.2, weight)
		camera.look_at(aim)
		framing_changed.emit(), 0.0, 1.0, duration * 0.9)


func _motion_changed() -> void:
	if GameSettings.reduced_motion() and _camera_tween:
		_camera_tween.kill()


func _process(delta: float) -> void:
	var reduced := GameSettings.reduced_motion()
	if not reduced:
		_time += delta
		if is_instance_valid(_rocket):
			_rocket.rotation.y += delta * 0.22
			_globe.rotation.y += delta * 0.09
			_dish.rotation.y = sin(_time * 0.18) * 0.14
	for index in _strips.size():
		var target := 1.0 if index == _hovered else (0.3 if index == _goal else 0.0)
		_levels[index] = target if reduced else lerpf(_levels[index], target, 1.0 - exp(-delta * 10.0))
		_strips[index].emission_energy_multiplier = 0.55 + _levels[index] * 1.4
		_wash[index].light_energy = 0.65 + _levels[index] * 0.7


func _build_shell() -> void:
	props.box(self, Vector3(0, -0.42, 0), Vector3(17.1, 0.65, 6.7), "dark")
	props.box(self, Vector3(0, -0.07, 0), Vector3(16.2, 0.16, 5.7), "edge")
	for index in 3:
		var room := Node3D.new()
		room.name = ["ScienceRoom", "EngineeringRoom", "BoardRoom"][index]
		room.position.y = index * FLOOR_HEIGHT
		add_child(room)
		rooms.append(room)
		props.box(room, Vector3(0, 0, 0), Vector3(15.8, 0.22, 5.1), "shell")
		props.box(room, Vector3(0, 0.14, 0), Vector3(15.0, 0.08, 4.7), "floor")
		props.box(room, Vector3(0, 1.6, -2.35), Vector3(15.4, 3.1, 0.22), "edge")
		props.box(room, Vector3(-7.65, 1.6, 0), Vector3(0.25, 3.1, 4.8), "navy")
		props.box(room, Vector3(7.65, 1.6, -1.5), Vector3(0.25, 3.1, 1.9), "navy")
		for x: float in [-7.5, 7.5]:
			props.box(room, Vector3(x, 1.5, 2.25), Vector3(0.21, 2.9, 0.2), "shell")
		var strip := props.material(ACCENTS[index], true)
		_strips.append(strip)
		var strip_mesh := BoxMesh.new()
		strip_mesh.size = Vector3(15.25, 0.055, 0.07)
		props.mesh(room, Vector3(0, 0.19, 2.59), strip_mesh, strip)
		for x: float in [-4.0, 3.5]:
			props.box(room, Vector3(x, 2.82, -0.6), Vector3(2.7, 0.1, 0.48), "paper")
		var wash := OmniLight3D.new()
		wash.position = Vector3(0, 2.5, 0.3)
		wash.omni_range = 8.0
		wash.light_color = ACCENTS[index]
		wash.light_energy = 0.3
		room.add_child(wash)
		_wash.append(wash)
		for x: float in [-6.5, 6.5]:
			props.box(room, Vector3(x, 0.35, 2.3), Vector3(1.1, 0.12, 0.12), "metal")
	props.box(self, Vector3(-4.8, -0.1, 3.05), Vector3(2.2, 0.22, 1.4), "metal")
	props.box(self, Vector3(-4.8, -0.22, 3.65), Vector3(2.5, 0.15, 0.7), "edge")


func _board_room(room: Node3D) -> void:
	props.desk(room, Vector3(-0.8, 0.18, 0.3), 7.8, "wood")
	for x: float in [-3.5, -1.8, 0.0, 1.8]:
		props.chair(room, Vector3(x, 0.18, 1.65), PI)
		props.chair(room, Vector3(x, 0.18, -1.05))
		props.box(room, Vector3(x, 1.06, 0.25), Vector3(0.55, 0.025, 0.35), "paper")
		props.cylinder(room, Vector3(x + 0.3, 1.13, 0.03), 0.075, 0.14, "dark")
	props.box(room, Vector3(-0.5, 1.85, -2.14), Vector3(5.6, 1.65, 0.12), "dark")
	props.box(room, Vector3(-0.5, 1.85, -2.06), Vector3(5.35, 1.4, 0.025), "glass")
	_board_status = props.caption(room, Vector3(-0.5, 1.85, -2.02), "PROGRAMME STATUS", 30)
	_tick_active = props.material(ACCENTS[2], true)
	for i in 11:
		_programme_ticks.append(props.box(room, Vector3(-2.8 + i * 0.46, 1.45, -2.02), Vector3(0.3, 0.12, 0.025), "edge"))
	props.monitor(room, Vector3(5.5, 1.45, -1.65), "gold", true)
	props.box(room, Vector3(5.5, 0.6, -1.6), Vector3(2.0, 0.85, 0.65), "wood")
	props.caption(room, Vector3(-5.7, 2.0, -2.13), "PHARSYDE\nDIRECTORS", 26, ACCENTS[2])
	props.cylinder(room, Vector3(-5.7, 0.7, -1.5), 0.24, 0.9, "metal")
	for x: float in [-0.2, 0.0, 0.2]:
		var leaf := props.box(room, Vector3(-5.7 + x, 1.55, -1.5), Vector3(0.2, 1.0, 0.12), "green")
		leaf.rotation.z = x * 2.0


func _engineering_room(room: Node3D) -> void:
	props.desk(room, Vector3(-4.3, 0.18, -0.2), 4.1, "metal")
	props.monitor(room, Vector3(-4.8, 1.76, -0.4), "teal")
	props.monitor(room, Vector3(-3.2, 1.76, -0.4), "gold")
	props.chair(room, Vector3(-4.3, 0.18, 1.1), PI, "teal")
	for i in 5:
		props.box(room, Vector3(-5.7 + i * 0.6, 1.9, -2.13), Vector3(0.12, 0.5, 0.08), "metal")
	props.box(room, Vector3(2.5, 0.3, 0), Vector3(3.1, 0.24, 2.5), "dark")
	_rocket = props.rocket(room, Vector3(2.5, 0.43, 0))
	for i in 9:
		var stripe := props.box(room, Vector3(1.12 + i * 0.34, 0.44, 1.23), Vector3(0.2, 0.03, 0.15), "gold")
		stripe.rotation.y = -0.35
	props.box(room, Vector3(5.7, 1.55, -0.65), Vector3(0.23, 2.8, 0.24), "gold")
	props.box(room, Vector3(4.45, 2.8, -0.65), Vector3(2.7, 0.18, 0.24), "gold")
	props.rod(room, Vector3(3.2, 2.8, -0.65), Vector3(3.2, 2.2, -0.65), 0.035, "metal")
	for x: float in [-0.8, 0.0]:
		props.cylinder(room, Vector3(x, 0.8, -1.5), 0.28, 1.15, "teal")
		props.cylinder(room, Vector3(x, 1.4, -1.5), 0.12, 0.1, "metal")
	for at: Vector3 in [Vector3(-6.2, 0.5, 1.25), Vector3(6.25, 0.55, 1.1)]:
		props.box(room, at, Vector3(0.85, 0.68, 0.85), "wood")
		props.box(room, at + Vector3(0, 0.35, 0), Vector3(0.9, 0.05, 0.9), "gold")
	_engineering_status = props.caption(room, Vector3(3.3, 1.75, -2.15), "VEHICLE CONCEPT", 25, ACCENTS[1])


func _science_room(room: Node3D) -> void:
	props.desk(room, Vector3(-4.6, 0.18, -0.4), 3.7)
	props.monitor(room, Vector3(-5.3, 1.76, -0.6), "teal")
	props.monitor(room, Vector3(-3.8, 1.76, -0.6), "paper")
	props.chair(room, Vector3(-4.5, 0.18, 1.0), PI, "green")
	props.cylinder(room, Vector3(0.5, 0.6, -0.1), 0.7, 0.9, "dark")
	_globe = Node3D.new()
	_globe.position = Vector3(0.5, 1.7, -0.1)
	room.add_child(_globe)
	props.sphere(_globe, Vector3.ZERO, 0.85, "moon")
	for direction: Vector3 in [Vector3(-0.3, 0.4, 1), Vector3(0.35, 0.1, 1), Vector3(-0.6, -0.2, 0.7), Vector3(0.1, -0.6, 0.8), Vector3(0.8, 0.5, 0.3)]:
		var n := direction.normalized()
		var mare := props.cylinder(_globe, n * 0.825, 0.23, 0.04, "mare")
		mare.quaternion = Quaternion(Vector3.UP, n)
	props.box(room, Vector3(5.5, 0.7, -1.4), Vector3(2.3, 1.0, 1.0), "paper")
	for i in 5:
		props.box(room, Vector3(4.65 + i * 0.4, 1.3, -1.4), Vector3(0.13, 0.3 + i % 2 * 0.16, 0.14), "teal")
	var scope_at := Vector3(4.25, 1.65, 1.0)
	for foot: Vector3 in [Vector3(-0.5, -1.45, 0.4), Vector3(0.5, -1.45, 0.4), Vector3(0, -1.45, -0.5)]:
		props.rod(room, scope_at + foot, scope_at, 0.04, "metal")
	var telescope := props.cylinder(room, scope_at + Vector3(0.1, 0.2, 0), 0.23, 1.25, "paper")
	telescope.rotation.z = -0.9
	_science_status = props.caption(room, Vector3(4.8, 1.9, -2.14), "LUNAR SURVEY", 23, ACCENTS[0])
	props.box(room, Vector3(-6.7, 1.9, -2.15), Vector3(0.55, 0.9, 0.05), "gold")


func _roof() -> void:
	props.box(self, Vector3(0, 9.6, 0), Vector3(16, 0.28, 5.4), "shell")
	props.box(self, Vector3(-3.6, 10.0, -0.4), Vector3(3.4, 0.65, 1.5), "edge")
	for i in 7:
		props.box(self, Vector3(-4.8 + i * 0.38, 10.35, -0.4), Vector3(0.12, 0.06, 1.3), "metal")
	_dish = Node3D.new()
	_dish.position = Vector3(3.9, 9.75, 0)
	add_child(_dish)
	props.rod(_dish, Vector3.ZERO, Vector3(0, 0.8, 0), 0.09, "metal")
	var dish := props.sphere(_dish, Vector3(0, 1.1, 0), 0.8, "paper")
	dish.scale = Vector3(1, 0.2, 1)
	dish.rotation.z = 0.45
	props.rod(_dish, Vector3(0, 1.15, 0), Vector3(-0.45, 1.9, 0), 0.025, "metal")
	props.rod(self, Vector3(6.5, 9.7, -1), Vector3(6.5, 11.1, -1), 0.035, "metal")
	var beacon := props.material(VisualTheme.AMBER, true)
	var light_shape := SphereMesh.new()
	light_shape.radius = 0.11
	light_shape.height = 0.22
	props.mesh(self, Vector3(6.5, 11.15, -1), light_shape, beacon)
