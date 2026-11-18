class_name SpacecraftVisual
extends Node3D
## Authored observation-stage poses and interruptible local effects; no flight maths.

var models := SpacecraftModels.new()
var parts := {}
var launch: Node3D
var ship: Node3D
var lander: Node3D
var capsule: Node3D
var configuration := "launch"
var separated := {}
var engine_amount := 0.0
var engine_target := 0.0
var fault := ""
var recovered := false
var _design := {}
var _homes := {}
var _engines := {}
var _active_flames: Array[Node3D] = []
var _engine_light: OmniLight3D
var _debris: Node3D
var _arrays: Node3D
var _antenna: Node3D
var _chutes: Node3D
var _payload: Node3D
var _thrusters: Node3D
var _heat: MeshInstance3D
var _rcs_left := 0.0
var _time := 0.0
var _animations: Array[Tween] = []
var _burn_tween: Tween
var _pose_tweens := {}
var _pose_targets := {}


func _ready() -> void:
	GameSettings.events.visuals_changed.connect(_settings_changed)


func _settings_changed() -> void:
	if not GameSettings.reduced_motion():
		return
	settle()
	for object: Node3D in _pose_targets:
		var pose: Array = _pose_targets[object]
		object.position = pose[0]
		object.scale = Vector3.ONE * float(pose[1])
		object.rotation = Vector3(0, 0, float(pose[2]))


func configure(design: Dictionary) -> void:
	_design = design.duplicate()
	launch = Node3D.new()
	launch.name = "LaunchVehicle"
	add_child(launch)
	var side: bool = Vehicle.chosen(design, "stage1").get("mount") == "side"
	var base := -4.7
	for slot: String in ["stage1", "stage2", "stage3", "lander", "service", "capsule", "escape"]:
		var part := Vehicle.chosen(design, slot)
		if part.is_empty():
			continue
		if slot == "lander" and str(part["id"]) == "lander_hls":
			continue # This option is sent ahead in the existing high-orbit mission.
		var object := models.module(slot, part)
		launch.add_child(object)
		parts[slot] = object
		if slot == "stage1" and side:
			object.position.y = -2.3
		else:
			var height := float(object.get_meta("height", {"lander": 0.8, "service": 1.0, "capsule": 0.8, "escape": 1.0}.get(slot, 1.0)))
			object.position.y = base + height * 0.5
			base += height
		if slot == "lander":
			object.scale = Vector3.ONE * 0.56
		_homes[slot] = object.transform
		_add_exhaust(object)
	ship = Node3D.new()
	ship.name = "CruiseSpacecraft"
	add_child(ship)
	var service := models.module("service", Vehicle.chosen(design, "service"))
	ship.add_child(service)
	var cabin := models.module("capsule", Vehicle.chosen(design, "capsule"))
	cabin.position.y = 0.82
	ship.add_child(cabin)
	_add_exhaust(ship)
	if design.get("power") == "power_solar":
		_arrays = models.solar_arrays(ship, Vector3(0, -0.1, 0))
	if design.get("comms") != "comms_omni":
		_antenna = Node3D.new()
		ship.add_child(_antenna)
		models.p.rod(_antenna, Vector3(0.4, 0.1, 0), Vector3(0.8, 0.35, 0), 0.025, "metal")
		models.p.cylinder(_antenna, Vector3(0.85, 0.4, 0), 0.22, 0.07, "paper", 0.08).rotation.z = -0.5
	lander = models.module("lander", Vehicle.chosen(design, "lander"))
	lander.name = "LunarLander"
	add_child(lander)
	_add_exhaust(lander)
	capsule = models.module("capsule", Vehicle.chosen(design, "capsule"))
	capsule.name = "ReturnCapsule"
	add_child(capsule)
	_heat = models.p.cylinder(capsule, Vector3(0, -0.33, 0), 0.56, 0.12, "gold", 0.5)
	_heat.material_override = models.p.material(Color("f66c32"), true)
	_heat.hide()
	_debris = Node3D.new()
	_debris.name = "SeparatedHardware"
	add_child(_debris)
	_chutes = _make_chutes()
	add_child(_chutes)
	_payload = Node3D.new()
	_payload.name = "ConfirmedSurfaceWork"
	add_child(_payload)
	_thrusters = Node3D.new()
	ship.add_child(_thrusters)
	for side_value in [-1, 1]:
		models.p.cylinder(_thrusters, Vector3(side_value * 0.57, 0.35, 0), 0.04, 0.3, "paper", 0).rotation.z = side_value * PI * 0.5
	_thrusters.hide()
	_engine_light = OmniLight3D.new()
	_engine_light.light_color = Color("a6d5ff")
	_engine_light.omni_range = 5.0
	_engine_light.light_energy = 0.0
	add_child(_engine_light)
	reset_stack()


func reset_stack() -> void:
	if launch == null:
		return
	settle()
	for slot: String in parts:
		var part: Node3D = parts[slot]
		if part.get_parent() != launch:
			part.reparent(launch)
		part.transform = _homes[slot]
		for child in part.get_children():
			if child is Node3D and child.has_meta("assembled_transform"):
				child.transform = child.get_meta("assembled_transform")
		part.show()
	separated.clear()
	fault = ""
	recovered = false
	_chutes.hide()
	_payload.hide()
	show_configuration("launch", true)


func show_configuration(kind: String, instant := false) -> void:
	configuration = kind
	launch.visible = kind in ["launch", "upper"]
	ship.visible = kind == "ship"
	lander.visible = kind in ["lander", "surface"]
	capsule.visible = kind in ["capsule", "recovery"]
	_chutes.visible = false
	_heat.hide()
	_payload.visible = kind == "surface" and _payload.get_child_count() > 0
	if kind == "upper":
		for slot: String in ["stage1", "stage2", "escape"]:
			if parts.has(slot):
				(parts[slot] as Node3D).hide()
	var object: Node3D = {"launch": launch, "upper": launch, "ship": ship, "lander": lander, "surface": lander, "capsule": capsule, "recovery": capsule}.get(kind, launch)
	var location: Vector3 = {"launch": Vector3(1.9, -0.1, 1), "upper": Vector3(1.7, -5.2, 1), "ship": Vector3(1.3, 0.1, 1), "lander": Vector3(1.4, -0.5, 1), "surface": Vector3(1.4, -2.25, 1), "capsule": Vector3(1.2, 0.3, 1), "recovery": Vector3(1.2, -3.1, 1)}.get(kind, Vector3.ZERO)
	var scale_value: float = {"launch": 1.0, "upper": 1.45, "ship": 3.3, "lander": 2.2, "surface": 1.6, "capsule": 4.5, "recovery": 3.0}.get(kind, 1.0)
	var angle: float = {"launch": -0.09, "upper": -0.15, "ship": -0.6, "lander": -0.05, "surface": 0.0, "capsule": 0.4, "recovery": 0.0}.get(kind, 0.0)
	_pose_targets[object] = [location, scale_value, angle]
	if _pose_tweens.has(object):
		var previous: Tween = _pose_tweens[object]
		if previous and previous.is_valid():
			previous.kill()
	if instant or GameSettings.reduced_motion():
		object.position = location
		object.scale = Vector3.ONE * scale_value
		object.rotation = Vector3(0, 0, angle)
	else:
		var animation := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		animation.tween_property(object, "position", location, 0.65)
		animation.tween_property(object, "scale", Vector3.ONE * scale_value, 0.65)
		animation.tween_property(object, "rotation", Vector3(0, 0, angle), 0.65)
		_animations.append(animation)
		_pose_tweens[object] = animation


func separate(number: int, instant := false) -> void:
	var slot := "stage1" if number == 1 else "stage2"
	if separated.has(slot) or not parts.has(slot):
		return
	separated[slot] = true
	var object: Node3D = parts[slot]
	object.reparent(_debris, true)
	if instant or GameSettings.reduced_motion():
		object.hide()
	else:
		var animation := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		if slot == "stage1" and _design.get("stage1") == "s1_solid":
			for booster: Node3D in object.get_children():
				var side := signf(booster.position.x)
				animation.tween_property(booster, "position", booster.position + Vector3(side * 2.1, -3.5, -0.5), 1.5)
				animation.tween_property(booster, "rotation:z", -side * 0.4, 1.5)
		else:
			animation.tween_property(object, "position", object.position + Vector3(-1.8, -4.0, -1), 1.5)
			animation.tween_property(object, "rotation:z", object.rotation.z - 0.4, 1.5)
		animation.chain().tween_callback(object.hide)
		_animations.append(animation)
	if parts.has("escape"):
		(parts["escape"] as Node3D).hide()


func burn(owners: Array, enabled: bool, instant := false) -> void:
	if _burn_tween:
		_burn_tween.kill()
	if enabled:
		for flame: Node3D in _active_flames:
			flame.hide()
		_active_flames.clear()
		for owner: Node3D in owners:
			if owner != null:
				for flame: Node3D in _engines.get(owner, []):
					_active_flames.append(flame)
	engine_target = 1.0 if enabled else 0.0
	if instant or GameSettings.reduced_motion():
		engine_amount = engine_target
		if not enabled:
			for flame: Node3D in _active_flames:
				flame.hide()
	else:
		_burn_tween = create_tween()
		_burn_tween.tween_property(self, "engine_amount", engine_target, 0.24 if enabled else 0.3)


func launch_burn(staged: int, enabled: bool, instant := false) -> void:
	var owners: Array = [parts.get(["stage1", "stage2", "stage3"][mini(staged, 2)])]
	if staged == 0 and _design.get("stage1") == "s1_solid":
		owners.append(parts.get("stage2"))
	burn(owners, enabled, instant)


func pulse_thrusters(instant := false) -> void:
	_rcs_left = 0.0 if instant or GameSettings.reduced_motion() else 0.75
	_thrusters.visible = _rcs_left > 0.0


func mark_fault(kind: String, instant := false) -> void:
	fault = kind
	burn([], false, instant)
	if kind == "stage1" and not instant and not GameSettings.reduced_motion():
		var animation := create_tween()
		animation.tween_property(launch, "rotation:z", 0.18, 0.6)
		_animations.append(animation)


func power_reduced() -> void:
	if _arrays:
		_arrays.rotation.z = 0.12


func communication_fault() -> void:
	if _antenna:
		_antenna.rotation.z = -0.8


func parachutes(instant := false) -> void:
	show_configuration("capsule", instant)
	_chutes.show()
	_chutes.position = Vector3(1.2, 2.7, 1)
	_chutes.scale = Vector3.ONE
	if not instant and not GameSettings.reduced_motion():
		_chutes.scale = Vector3.ONE * 0.08
		var animation := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		animation.tween_property(_chutes, "scale", Vector3.ONE, 0.75)
		_animations.append(animation)


func reentry_heat() -> void:
	_heat.show()


func splashdown(instant := false) -> void:
	recovered = true
	show_configuration("recovery", instant)
	_chutes.hide()
	burn([], false, instant)


func surface_work(rows: Array) -> void:
	if _payload.get_child_count() > 0:
		_payload.show()
		return
	var at := -1.8
	for row: Dictionary in rows:
		if int(row.get("points", 0)) <= 0 or str(row.get("name", "")).begins_with("The site"):
			continue
		models.p.box(_payload, Vector3(at, -3.32, 1.6), Vector3(0.35, 0.22, 0.3), "gold")
		models.p.rod(_payload, Vector3(at, -3.2, 1.6), Vector3(at, -2.8, 1.6), 0.02, "paper")
		at -= 0.65
	_payload.visible = configuration == "surface"


func settle() -> void:
	for animation: Tween in _animations:
		if animation and animation.is_valid():
			animation.kill()
	_animations.clear()
	if _burn_tween:
		_burn_tween.kill()
	engine_amount = engine_target
	_rcs_left = 0.0
	if _thrusters:
		_thrusters.hide()
	if _debris:
		for part in _debris.get_children():
			(part as Node3D).hide()


func _process(delta: float) -> void:
	_time += delta
	_rcs_left = maxf(_rcs_left - delta, 0.0)
	if _thrusters:
		_thrusters.visible = _rcs_left > 0.0
	var flicker := 1.0 if GameSettings.reduced_motion() else 0.94 + 0.06 * sin(_time * 31.0) * sin(_time * 17.0)
	for flame: Node3D in _active_flames:
		flame.visible = engine_amount > 0.005
		flame.scale.y = engine_amount * flicker
	if _engine_light:
		_engine_light.light_energy = engine_amount * 1.8
		if not _active_flames.is_empty():
			_engine_light.global_position = _active_flames[0].global_position
	# Engine vibration moves only this physical assembly, never the camera.
	if launch and configuration == "launch":
		launch.position.x = 1.9 + (sin(_time * 42.0) * 0.012 * engine_amount if not GameSettings.reduced_motion() else 0.0)
	if _animations.size() > 20:
		_animations = _animations.filter(func(animation: Tween) -> bool: return animation.is_valid())


func _add_exhaust(owner: Node3D) -> void:
	var flames: Array[Node3D] = []
	for anchor: Node in owner.find_children("Exhaust*", "Node3D", true, false):
		var plume := Node3D.new()
		anchor.add_child(plume)
		var radius := float(anchor.get_meta("radius"))
		var shape := CylinderMesh.new()
		shape.top_radius = radius * 0.7
		shape.bottom_radius = 0.015
		shape.height = radius * 7.5
		shape.radial_segments = 8
		var mesh := MeshInstance3D.new()
		mesh.mesh = shape
		mesh.position.y = -shape.height * 0.5
		var hydrogen: bool = anchor.get_meta("fuel") == "hydrogen"
		mesh.material_override = models.p.material(Color("a9dcff") if hydrogen else Color("ffc76b"), true)
		plume.add_child(mesh)
		plume.hide()
		flames.append(plume)
	_engines[owner] = flames


func _make_chutes() -> Node3D:
	var group := Node3D.new()
	group.name = "ReportedParachutes"
	for i in 3:
		var at := Vector3((i - 1) * 1.75, 2.1 + (0.3 if i == 1 else 0), 0)
		models.p.cylinder(group, at, 1.1, 0.65, "red", 0.22)
		for side in [-1, 1]:
			models.p.rod(group, at + Vector3(side * 0.94, -0.32, 0), Vector3(0, -0.6, 0), 0.012, "paper")
	group.hide()
	return group
