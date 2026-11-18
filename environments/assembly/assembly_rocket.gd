class_name AssemblyRocket
extends Node3D
## Read-only representation of the draft. Cached variants never write Vehicle state.

signal configuration_changed(height: float)

const ORDER := ["stage1", "stage2", "stage3", "lander", "service", "capsule", "escape"]
const HEIGHTS := {"stage1": 3.2, "stage2": 2.25, "stage3": 1.45, "lander": 0.85, "service": 1.0, "capsule": 0.8, "escape": 1.0}
var models := SpacecraftModels.new()
var actual := {}
var rendered := {}
var parts := {}
var active_slot := "stage1"
var preview_slot := ""
var preview_id := ""
var _cache := {}
var _bounds := {}
var _animations := {}
var _ghosts := {}
var _centres := {}
var _locator: Node3D
var _ring_paint: StandardMaterial3D
var _equipment: Node3D


func _ready() -> void:
	_locator = Node3D.new()
	_locator.name = "SectionLocator"
	add_child(_locator)
	_ring_paint = models.p.material(VisualTheme.AMBER, true)
	_ring_paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for y in [-0.32, 0.32]:
		var torus := TorusMesh.new()
		torus.inner_radius = 0.8
		torus.outer_radius = 0.825
		torus.rings = 32
		torus.ring_segments = 5
		models.p.mesh(_locator, Vector3(0, y, 0), torus, _ring_paint)
	_equipment = Node3D.new()
	_equipment.position = Vector3(-3, -4.4, 2.3)
	add_child(_equipment)
	models.p.box(_equipment, Vector3.ZERO, Vector3(1.2, 0.9, 0.65), "edge")
	models.p.box(_equipment, Vector3(0, 0.14, 0.34), Vector3(0.9, 0.26, 0.03), "glass")
	for x in [-0.4, 0.4]:
		models.p.cylinder(_equipment, Vector3(x, -0.5, 0), 0.13, 0.12, "dark").rotation.z = PI * 0.5
	GameSettings.events.visuals_changed.connect(_motion_changed)


func set_choice(choice: Dictionary, installed_slot := "", animate := true) -> void:
	actual = choice.duplicate()
	preview_slot = ""
	preview_id = ""
	_render(actual, installed_slot, animate)


func preview(slot: String, part_id: String) -> void:
	if slot == preview_slot and part_id == preview_id:
		return
	preview_slot = slot
	preview_id = part_id
	var draft := actual.duplicate()
	draft[slot] = part_id
	_render(draft, "", false)
	highlight(slot, true)


func clear_preview() -> void:
	if preview_slot.is_empty():
		return
	preview_slot = ""
	preview_id = ""
	_render(actual, "", false)
	highlight(active_slot)


func _render(choice: Dictionary, installed_slot: String, animate: bool) -> void:
	var outgoing: Node3D = parts.get(installed_slot)
	for animation: Tween in _animations.values():
		if animation and animation.is_valid():
			animation.kill()
	_animations.clear()
	for object: Node3D in _cache.values():
		object.hide()
	for guide: Node3D in _ghosts.values():
		guide.hide()
	parts.clear()
	_centres.clear()
	rendered = choice.duplicate()
	var side: bool = Vehicle.chosen(choice, "stage1").get("mount") == "side"
	var bottom := -4.65
	for slot: String in ORDER:
		var part := Vehicle.chosen(choice, slot)
		var separate: bool = slot == "lander" and part.get("orbit") == "nrho"
		var height := _height(slot, part)
		var at := Vector3(0, bottom + height * 0.5, 0)
		if slot == "stage1" and side:
			at.y = -2.3
		elif separate:
			at = Vector3(3.5, -3.82, 1.8)
		else:
			bottom += height
		_centres[slot] = at
		if part.is_empty():
			var guide := _guide(slot, height)
			guide.position = at
			guide.show()
			continue
		var object := _part(slot, part)
		object.position = at
		object.scale = Vector3.ONE
		object.rotation = Vector3.ZERO
		if slot == "lander" and not separate:
			object.scale = Vector3.ONE * 0.5
		object.set_meta("rest_position", at)
		object.show()
		parts[slot] = object
		if slot == installed_slot and animate and not GameSettings.reduced_motion():
			object.position = at + Vector3(0, 0.85, 0)
			var animation := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			animation.tween_property(object, "position", at, 0.38)
			_animations[object] = animation
	_build_system(choice)
	highlight(active_slot)
	configuration_changed.emit(bottom + 4.65)
	if outgoing and not choice.has(installed_slot) and animate and not GameSettings.reduced_motion():
		outgoing.show()
		var removal := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC)
		removal.tween_property(outgoing, "position", outgoing.position + Vector3(0.7, 0.4, 0), 0.2)
		removal.tween_property(outgoing, "scale", Vector3.ONE * 0.02, 0.2)
		removal.chain().tween_callback(outgoing.hide)
		_animations[outgoing] = removal


func _part(slot: String, part: Dictionary) -> Node3D:
	var key := slot + ":" + str(part["id"])
	if not _cache.has(key):
		var object := models.module(slot, part)
		_variant_details(object, slot, part)
		if part["id"] == "escape_integrated":
			for side in [-1, 1]:
				models.p.cylinder(object, Vector3(side * 0.48, -0.05, 0.16), 0.09, 0.38, "red")
				models.p.cylinder(object, Vector3(side * 0.48, -0.26, 0.16), 0.1, 0.08, "dark")
		add_child(object)
		_cache[key] = object
		var box := AABB()
		var first := true
		for mesh: MeshInstance3D in object.find_children("*", "MeshInstance3D", true, false):
			var local := object.global_transform.affine_inverse() * mesh.global_transform
			var bounds: AABB = local * mesh.get_aabb()
			box = bounds if first else box.merge(bounds)
			first = false
		_bounds[object] = box
	return _cache[key]


func _height(slot: String, part: Dictionary) -> float:
	var id := str(part.get("id", ""))
	return float({"s2_core": 4.7, "s3_icps": 1.05, "service_small": 0.8, "service_esm": 0.72, "service_cryo": 1.18}.get(id, HEIGHTS.get(slot, 1.0)))


func _variant_details(object: Node3D, slot: String, part: Dictionary) -> void:
	var id := str(part["id"])
	if slot == "service" or id == "s3_icps":
		var geometry := Node3D.new()
		var children := object.get_children()
		object.add_child(geometry)
		for child: Node in children:
			child.reparent(geometry, false)
		geometry.scale.y = _height(slot, part) / float(HEIGHTS[slot])
		if id == "service_esm":
			geometry.scale.x = 0.9
			geometry.scale.z = 0.9
	if id == "service_cryo":
		for y in [-0.38, 0.38]:
			models.p.cylinder(object, Vector3(0, y, 0), 0.51, 0.1, "metal")
	elif id == "s3_storable":
		models.p.cylinder(object, Vector3(0, 0.28, 0), 0.465, 0.18, "teal")
	elif id == "escape_las":
		models.p.cylinder(object, Vector3(0, 0.14, 0), 0.18, 0.15, "dark")
		for side in [-1, 1]:
			models.p.cylinder(object, Vector3(side * 0.19, 0.14, 0), 0.045, 0.14, "metal").rotation.z = PI * 0.5


func _guide(slot: String, height: float) -> Node3D:
	if not _ghosts.has(slot):
		var guide := Node3D.new()
		guide.name = "EmptyBay_" + slot
		add_child(guide)
		var paint := models.p.material(Color("2d6279"), true)
		paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		for y in [-0.5, 0.5]:
			var ring := TorusMesh.new()
			ring.inner_radius = 0.47
			ring.outer_radius = 0.48
			ring.rings = 12
			ring.ring_segments = 4
			models.p.mesh(guide, Vector3(0, y, 0), ring, paint)
		for side in [-1, 1]:
			models.p.rod(guide, Vector3(side * 0.48, -0.5, 0), Vector3(side * 0.48, 0.5, 0), 0.008, "teal")
		_ghosts[slot] = guide
	var result: Node3D = _ghosts[slot]
	result.scale = Vector3(1, height, 1)
	return result


func _build_system(choice: Dictionary) -> void:
	# Systems are inspection cutaways, attached only when that system is selected.
	for slot: String in ["power", "comms"]:
		var id := str(choice.get(slot, ""))
		if id.is_empty():
			continue
		var key := slot + ":" + id
		if not _cache.has(key):
			var object := Node3D.new()
			object.set_meta("part_id", id)
			add_child(object)
			_cache[key] = object
			_system_model(object, id)
		var equipment: Node3D = _cache[key]
		equipment.position = _centres["service"] if slot == "power" else _centres["capsule"]
		equipment.scale = Vector3.ONE
		equipment.show()
		parts[slot] = equipment
		_centres[slot] = equipment.position
	if choice.get("escape") == "escape_integrated":
		(parts["escape"] as Node3D).position = _centres["capsule"]
		_centres["escape"] = _centres["capsule"]
	for slot: String in ["life", "suits", "comms", "spaceport", "ground", "tests", "power"]:
		if not _centres.has(slot):
			_centres[slot] = _centres.get("capsule", Vector3(0, 4, 0)) if slot in ["life", "comms", "power"] else _equipment.position


func _system_model(object: Node3D, id: String) -> void:
	var p := models.p
	if id in ["comms_dish", "comms_relay", "comms_laser"]:
		p.rod(object, Vector3(0.35, -0.12, 0.15), Vector3(0.74, 0.0, 0.3), 0.025, "metal")
		p.cylinder(object, Vector3(0.78, 0.08, 0.3), 0.3, 0.12, "paper", 0.12).rotation.z = -0.9
		p.rod(object, Vector3(0.78, 0.08, 0.3), Vector3(0.96, 0.3, 0.3), 0.012, "gold")
	match id:
		"power_solar":
			models.solar_arrays(object, Vector3.ZERO)
		"power_cells", "power_batteries":
			for index in (3 if id == "power_cells" else 2):
				p.box(object, Vector3(-0.28 + index * 0.25, -0.15, 0.48), Vector3(0.19, 0.22, 0.14), "teal" if id == "power_cells" else "gold")
		"comms_omni":
			for side in [-1, 1]:
				p.rod(object, Vector3(side * 0.38, -0.12, 0), Vector3(side * 0.85, 0.15, 0), 0.012, "metal")
		"comms_relay":
			p.box(object, Vector3(0.5, -0.1, 0.1), Vector3(0.22, 0.3, 0.26), "navy")
			p.rod(object, Vector3(0.5, -0.1, 0.1), Vector3(0.8, 0.38, 0.1), 0.015, "metal")
		"comms_laser":
			p.box(object, Vector3(0.53, -0.12, 0.2), Vector3(0.25, 0.26, 0.24), "metal")
			p.cylinder(object, Vector3(0.68, -0.12, 0.2), 0.08, 0.16, "glass").rotation.z = PI * 0.5


func highlight(slot: String, temporary := false) -> void:
	if not temporary:
		active_slot = slot
	_locator.position = _centres.get(slot, Vector3.ZERO)
	var height := _height(slot, Vehicle.chosen(rendered, slot))
	_locator.scale = Vector3(1.5 if slot == "stage1" else 1, maxf(height / 0.64, 0.8), 1)
	_ring_paint.albedo_color = VisualTheme.CYAN if temporary else VisualTheme.AMBER
	_locator.show()


func centre_of(slot: String) -> Vector3:
	return to_global(_centres.get(slot, Vector3.ZERO))


func pick(origin: Vector3, direction: Vector3) -> String:
	var nearest := INF
	var selected := ""
	for slot: String in parts:
		var object: Node3D = parts[slot]
		if not _bounds.has(object) or not object.is_visible_in_tree():
			continue
		var inverse := object.global_transform.affine_inverse()
		var hit: Variant = (_bounds[object] as AABB).intersects_ray(inverse * origin, inverse.basis * direction)
		if hit is Vector3:
			var distance := origin.distance_to(object.global_transform * (hit as Vector3))
			if distance < nearest:
				nearest = distance
				selected = slot
	return selected


func _motion_changed() -> void:
	if GameSettings.reduced_motion():
		_render(rendered, "", false)
