class_name LunarCoordinates
extends RefCounted
## Right-handed, fixed Moon: north +Y, prime meridian +Z, east +X.
## NASA CGI Moon Kit: north at top, -180 at left, 0 at centre, +180 at right.

static func direction(latitude: float, longitude: float) -> Vector3:
	var lat := deg_to_rad(latitude)
	var lon := deg_to_rad(longitude)
	return Vector3(cos(lat) * sin(lon), sin(lat), cos(lat) * cos(lon)).normalized()


static func from_site(site: Dictionary) -> Vector3:
	return direction(float(site["lat"]), float(site["lon"]))


static func uv(direction_value: Vector3) -> Vector2:
	var n := direction_value.normalized()
	return Vector2(0.5 + atan2(n.x, n.z) / TAU, 0.5 - asin(clampf(n.y, -1, 1)) / PI)


static func visible(direction_value: Vector3, camera_position: Vector3, radius: float) -> bool:
	# A point can be in front of the camera yet hidden by the sphere.
	return direction_value.dot(camera_position) > radius + 0.04
