class_name SpacecraftModels
extends RefCounted
## Original, code-authored low-poly hardware. Selection dictionaries are read-only.

var p := HQProps.new()


func module(slot: String, part: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = slot
	root.set_meta("part_id", str(part.get("id", "")))
	match slot:
		"stage1", "stage2", "stage3":
			_stage(root, slot, part)
		"service":
			p.cylinder(root, Vector3.ZERO, 0.47, 0.9, "paper")
			p.cylinder(root, Vector3(0, -0.48, 0), 0.46, 0.12, "dark")
			_nozzle(root, Vector3(0, -0.62, 0), 0.2, str(part.get("fuel", "storable")))
			for i in 8:
				var angle := i * TAU / 8.0
				p.box(root, Vector3(sin(angle) * 0.46, 0, cos(angle) * 0.46), Vector3(0.06, 0.6, 0.06), "metal")
			p.box(root, Vector3(0, 0.12, 0.48), Vector3(0.6, 0.22, 0.05), "gold")
		"capsule":
			var four: bool = part.get("id") == "capsule_four"
			var radius := 0.54 if four else (0.41 if part.get("id") == "capsule_two" else 0.49)
			p.cylinder(root, Vector3(0, -0.3, 0), radius, 0.14, "dark")
			p.cylinder(root, Vector3.ZERO, radius, 0.62, "paper", 0.16)
			p.cylinder(root, Vector3(0, 0.34, 0), 0.16, 0.12, "metal", 0.11)
			for side in [-1, 1]:
				p.box(root, Vector3(side * 0.16, 0.11, radius * 0.63), Vector3(0.15, 0.13, 0.08), "dark")
				p.box(root, Vector3(side * 0.16, 0.11, radius * 0.7), Vector3(0.11, 0.09, 0.02), "glass")
			p.rod(root, Vector3(0.25, -0.12, 0.3), Vector3(0.34, 0.16, 0.35), 0.02, "red")
		"escape":
			if str(part.get("abort", "")) in ["tower", "tower_steered"]:
				for x in [-0.13, 0.13]:
					for z in [-0.13, 0.13]:
						p.rod(root, Vector3(x, -0.4, z), Vector3(x * 0.6, 0.25, z * 0.6), 0.025, "red")
				p.cylinder(root, Vector3(0, 0.38, 0), 0.11, 0.65, "paper", 0.025)
		"lander":
			_lander(root, part)
	return root


func _stage(root: Node3D, slot: String, part: Dictionary) -> void:
	var id := str(part.get("id", ""))
	var height := 3.2 if slot == "stage1" else (4.7 if id == "s2_core" else (2.25 if slot == "stage2" else 1.45))
	var radius := 0.58 if slot != "stage3" else 0.45
	var fuel := str(part.get("fuel", "hydrogen"))
	root.set_meta("height", height)
	if part.get("mount") == "side":
		for side in [-1, 1]:
			var booster := Node3D.new()
			booster.name = "PortBooster" if side < 0 else "StarboardBooster"
			booster.position.x = side * 0.86
			booster.set_meta("assembled_transform", booster.transform)
			root.add_child(booster)
			p.cylinder(booster, Vector3.ZERO, 0.3, 4.35, "paper")
			p.cylinder(booster, Vector3(0, 2.4, 0), 0.3, 0.5, "paper", 0.02)
			for ring in 7:
				p.cylinder(booster, Vector3(0, -1.95 + ring * 0.65, 0), 0.315, 0.06, "dark")
			_nozzle(booster, Vector3(0, -2.38, 0), 0.23, fuel)
		return
	var paint := "wood" if id == "s2_core" else "paper"
	p.cylinder(root, Vector3.ZERO, radius, height, paint, radius * (0.84 if id == "s1_thirty" else 1.0))
	for end in [-1, 1]:
		p.cylinder(root, Vector3(0, end * (height * 0.5 - 0.12), 0), radius * 1.025, 0.2, "dark")
	for i in 12:
		var angle := i * TAU / 12.0
		p.box(root, Vector3(sin(angle) * radius, -height * 0.22, cos(angle) * radius), Vector3(0.028, height * 0.43, 0.028), "metal")
	for i in 4:
		var angle := i * TAU / 4.0
		var stripe := p.box(root, Vector3(sin(angle) * radius, height * 0.27, cos(angle) * radius), Vector3(0.13, height * 0.22, 0.035), "dark")
		stripe.rotation.y = angle
	var count: int = {"s1_five": 5, "s1_four": 4, "s1_thirty": 30, "s2_core": 4, "s2_hydrogen": 5, "s3_twin": 2}.get(id, 1)
	for i in count:
		var ring_count := count - 1 if count == 5 else count
		var angle := i * TAU / maxf(float(ring_count), 1)
		var r := 0.0 if count == 1 or (i == count - 1 and count == 5) else radius * (0.7 if count < 10 else (0.32 + 0.17 * (i % 3)))
		_nozzle(root, Vector3(sin(angle) * r, -height * 0.5 - 0.12, cos(angle) * r), 0.19 if count < 10 else 0.085, fuel)
	if slot == "stage1":
		for side in [-1, 1]:
			p.box(root, Vector3(side * 0.64, -1.3, 0), Vector3(0.28, 0.65, 0.08), "dark").rotation.z = side * -0.3


func _nozzle(root: Node3D, at: Vector3, radius: float, fuel := "storable") -> void:
	p.cylinder(root, at, radius, radius * 1.4, "dark", radius * 0.45)
	var anchor := Node3D.new()
	anchor.name = "Exhaust_%d" % root.get_child_count()
	anchor.position = at - Vector3(0, radius * 0.6, 0)
	anchor.set_meta("fuel", fuel)
	anchor.set_meta("radius", radius)
	root.add_child(anchor)


func _lander(root: Node3D, part: Dictionary) -> void:
	var hls: bool = part.get("id") == "lander_hls"
	var light: bool = part.get("id") == "lander_light"
	if hls:
		p.cylinder(root, Vector3(0, 0.75, 0), 0.48, 1.75, "metal", 0.36)
		p.cylinder(root, Vector3(0, 1.72, 0), 0.36, 0.25, "paper", 0.08)
		p.box(root, Vector3(0, 1.2, 0.41), Vector3(0.32, 0.19, 0.08), "dark")
	else:
		p.cylinder(root, Vector3(0, -0.1, 0), 0.62 if not light else 0.48, 0.48, "gold")
		p.box(root, Vector3(0, 0.37, 0), Vector3(0.63, 0.55, 0.56), "paper")
		for side in [-1, 1]:
			p.box(root, Vector3(side * 0.18, 0.48, 0.3), Vector3(0.2, 0.17, 0.05), "dark")
			p.box(root, Vector3(side * 0.18, 0.49, 0.33), Vector3(0.14, 0.1, 0.01), "glass")
		if part.get("id") == "lander_extended":
			for side in [-1, 1]:
				p.box(root, Vector3(side * 0.6, -0.02, 0), Vector3(0.18, 0.36, 0.45), "metal")
	for i in 4:
		var angle := PI * 0.25 + i * PI * 0.5
		var foot := Vector3(sin(angle) * 0.96, -0.76, cos(angle) * 0.96)
		p.rod(root, Vector3(sin(angle) * 0.43, 0.08, cos(angle) * 0.43), foot, 0.025, "metal")
		p.rod(root, Vector3(0, -0.25, 0), foot, 0.017, "dark")
		p.cylinder(root, foot, 0.15, 0.045, "metal")
	_nozzle(root, Vector3(0, -0.43, 0), 0.17)
	for i in 5:
		p.rod(root, Vector3(-0.13, -0.2 - i * 0.105, 0.57 + i * 0.06), Vector3(0.13, -0.2 - i * 0.105, 0.57 + i * 0.06), 0.015, "paper")
	p.rod(root, Vector3(0.2, 0.6, 0), Vector3(0.2, 1.1 if not hls else 2.0, 0), 0.012, "paper")


func solar_arrays(root: Node3D, at: Vector3) -> Node3D:
	var assembly := Node3D.new()
	assembly.position = at
	root.add_child(assembly)
	for side in [-1, 1]:
		p.rod(assembly, Vector3(side * 0.3, 0, 0), Vector3(side * 1.3, 0, 0), 0.035, "metal")
		p.box(assembly, Vector3(side * 1.28, 0, 0), Vector3(1.4, 0.05, 0.8), "navy")
		for i in 7:
			p.box(assembly, Vector3(side * (0.7 + i * 0.19), 0.03, 0), Vector3(0.015, 0.015, 0.79), "metal")
	return assembly
