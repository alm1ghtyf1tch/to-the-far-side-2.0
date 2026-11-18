class_name OrbitCameraController
extends Camera3D
## Retargetable unit-vector interpolation. No Euler interpolation or queued tweens.

const DISTANCE := 8.5
var orbital_direction := LunarCoordinates.direction(12.0, 7.0)
var target_direction := orbital_direction
var _start := orbital_direction
var _elapsed := 1.0
var _interacted := false
var _idle_time := 0.0
const DURATION := 0.85


func _ready() -> void:
	fov = 40.0
	near = 0.1
	far = 100.0
	get_viewport().size_changed.connect(_frame)
	_frame()
	_place()


func _frame() -> void:
	var dimensions := get_viewport().get_visible_rect().size
	keep_aspect = Camera3D.KEEP_HEIGHT if dimensions.x >= dimensions.y else Camera3D.KEEP_WIDTH


func target_site(site: Dictionary) -> void:
	_interacted = true
	target_direction = LunarCoordinates.from_site(site)
	_start = orbital_direction
	_elapsed = 0.0
	if GameSettings.reduced_motion():
		orbital_direction = target_direction
		_elapsed = DURATION
		_place()


func _process(delta: float) -> void:
	if not _interacted and not GameSettings.reduced_motion():
		_idle_time += delta
		orbital_direction = LunarCoordinates.direction(12.0 + sin(_idle_time * 0.12) * 0.6, 7.0 + sin(_idle_time * 0.08) * 1.4)
		_place()
	if _elapsed < DURATION:
		_elapsed = minf(_elapsed + delta, DURATION)
		var t := _elapsed / DURATION
		t = t * t * (3.0 - 2.0 * t)
		orbital_direction = _start.slerp(target_direction, t).normalized()
		if GameSettings.reduced_motion():
			orbital_direction = target_direction
			_elapsed = DURATION
		_place()


func _place() -> void:
	position = orbital_direction * DISTANCE
	# Project north onto the camera tangent plane; a deterministic polar fallback.
	var north := Vector3.UP - orbital_direction * orbital_direction.y
	if north.length_squared() < 0.0001:
		north = Vector3.FORWARD - orbital_direction * Vector3.FORWARD.dot(orbital_direction)
	look_at(Vector3.ZERO, north.normalized())
