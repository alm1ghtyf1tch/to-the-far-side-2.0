class_name FlightPlanets
extends RefCounted
## Authored stylized Earth; the Moon reuses the approved Phase 3 surface assets.

static var _earth_map: ImageTexture


static func earth() -> MeshInstance3D:
	if _earth_map == null:
		_earth_map = _draw_continents()
	var result := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 5.0
	sphere.height = 10.0
	sphere.radial_segments = 64
	sphere.rings = 32
	result.mesh = sphere
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/flight/earth.gdshader")
	material.set_shader_parameter("continents", _earth_map)
	result.material_override = material
	return result


static func moon() -> MeshInstance3D:
	var result := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 4.4
	sphere.height = 8.8
	sphere.radial_segments = 128
	sphere.rings = 64
	result.mesh = sphere
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/lunar/lunar_surface.gdshader")
	material.set_shader_parameter("albedo_map", preload("res://assets/moon/lroc_color_2k.jpg"))
	material.set_shader_parameter("elevation_map", preload("res://assets/moon/lola_height_2k.png"))
	result.material_override = material
	return result


static func _draw_continents() -> ImageTexture:
	# Simplified art contours in east-positive longitude / latitude. No scientific use.
	var outlines := [
		PackedVector2Array([Vector2(-168, 65), Vector2(-135, 70), Vector2(-125, 52), Vector2(-115, 30), Vector2(-98, 17), Vector2(-83, 10), Vector2(-78, 25), Vector2(-65, 45), Vector2(-55, 52), Vector2(-80, 65), Vector2(-105, 73)]),
		PackedVector2Array([Vector2(-80, 12), Vector2(-60, 8), Vector2(-36, -8), Vector2(-48, -25), Vector2(-55, -40), Vector2(-69, -56), Vector2(-75, -25)]),
		PackedVector2Array([Vector2(-17, 32), Vector2(10, 37), Vector2(35, 30), Vector2(50, 12), Vector2(42, -12), Vector2(20, -35), Vector2(8, -23), Vector2(-8, 5)]),
		PackedVector2Array([Vector2(-10, 36), Vector2(-5, 57), Vector2(12, 72), Vector2(38, 63), Vector2(70, 75), Vector2(130, 65), Vector2(175, 55), Vector2(142, 36), Vector2(120, 21), Vector2(107, 0), Vector2(85, 10), Vector2(70, 25), Vector2(44, 13), Vector2(28, 40)]),
		PackedVector2Array([Vector2(112, -13), Vector2(137, -11), Vector2(153, -27), Vector2(145, -39), Vector2(116, -32)]),
		PackedVector2Array([Vector2(-54, 60), Vector2(-30, 68), Vector2(-23, 81), Vector2(-46, 83), Vector2(-64, 73)]),
	]
	var image := Image.create(512, 256, false, Image.FORMAT_RGB8)
	for y in 256:
		for x in 512:
			var lonlat := Vector2(float(x) / 512.0 * 360.0 - 180.0, 90.0 - float(y) / 256.0 * 180.0)
			var land := false
			for polygon: PackedVector2Array in outlines:
				if Geometry2D.is_point_in_polygon(lonlat, polygon):
					land = true
					break
			var color := Color("43796b") if land else Color("123853")
			if absf(lonlat.y) > 73.0 or lonlat.y < -66.0:
				color = Color("9eb7bb")
			elif land and absf(lonlat.y) < 30 and lonlat.x > -10 and lonlat.x < 50:
				color = Color("a29564")
			var clouds := sin(lonlat.x * 0.12 + sin(lonlat.y * 0.17) * 3.0) * sin(lonlat.y * 0.25 + lonlat.x * 0.04)
			if clouds > 0.72:
				color = color.lerp(Color("c1d3d3"), 0.45)
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)
