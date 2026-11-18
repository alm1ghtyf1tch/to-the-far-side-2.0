class_name CRTGeometry
extends RefCounted
## Keep this display-to-content mapping identical to crt.gdshader.

const MAX_CURVATURE := 0.08
const OVERSCAN_FRACTION := 0.95
const MAX_MOVEMENT := 0.018


static func glass_uv(display_uv: Vector2, curvature: float) -> Vector2:
	var p := display_uv * 2.0 - Vector2.ONE
	var k := clampf(curvature, 0.0, 1.0) * MAX_CURVATURE
	return p * (Vector2.ONE + Vector2(p.y * p.y, p.x * p.x) * k) * 0.5 + Vector2(0.5, 0.5)


static func source_uv(display_uv: Vector2, curvature: float, visible_fraction := 1.0, image_offset := Vector2.ZERO) -> Vector2:
	return (glass_uv(display_uv, curvature) - Vector2(0.5, 0.5) - image_offset) * visible_fraction + Vector2(0.5, 0.5)


static func on_screen(uv: Vector2) -> bool:
	return uv.x >= 0.0 and uv.y >= 0.0 and uv.x <= 1.0 and uv.y <= 1.0
