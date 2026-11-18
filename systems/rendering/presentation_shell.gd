extends Control
## Persistent display surface. Routed scenes and their CanvasLayers stay together.

@onready var content: SubViewport = %Content
@onready var screen: TextureRect = %Screen

var active_screen: Node
var _mouse_inside := false
var _curvature := 0.0
var _visible_fraction := 1.0
var _image_offset := Vector2.ZERO
var _pointer_uv := Vector2(0.5, 0.5)
var _movement_strength := 0.0
var _last_pointer: InputEventMouseMotion
var _last_mapped := Vector2.ZERO
var _have_mapped := false


func _ready() -> void:
	GameSettings.apply()
	screen.texture = content.get_texture()
	screen.gui_input.connect(_forward_pointer)
	screen.mouse_exited.connect(_screen_mouse_exited)
	get_viewport().size_changed.connect(_resize_content)
	get_window().focus_exited.connect(_release_input)
	GameSettings.events.visuals_changed.connect(_apply_visuals)
	_resize_content()
	_apply_visuals()
	SceneRouter.set_presentation_host(self)
	var error := open_screen(SceneRouter.MAIN_MENU)
	if error != OK:
		push_error("Cannot open the main menu: %d" % error)


func _exit_tree() -> void:
	SceneRouter.set_presentation_host(null)
	if GameSettings.events.visuals_changed.is_connected(_apply_visuals):
		GameSettings.events.visuals_changed.disconnect(_apply_visuals)


func open_screen(path: String) -> Error:
	var packed := load(path) as PackedScene
	if packed == null:
		return ERR_CANT_OPEN
	var next := packed.instantiate()
	if next == null:
		return ERR_CANT_CREATE
	if is_instance_valid(active_screen):
		content.remove_child(active_screen)
		active_screen.queue_free()
	active_screen = next
	# Like SceneTree.change_scene_to_file, detach now and attach at frame end.
	content.add_child.call_deferred(next)
	return OK


func _input(event: InputEvent) -> void:
	# Pointer events arrive through Screen.gui_input in its correctly scaled space.
	if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag:
		return
	if not SceneRouter.is_busy():
		content.push_input(event)
	get_viewport().set_input_as_handled()


func _forward_pointer(event: InputEvent) -> void:
	if SceneRouter.is_busy():
		return
	if event is InputEventMouse:
		# This is the physical, unwarped display position; never feed mapped input
		# back into the movement target.
		_pointer_uv = (event.position / screen.size).clamp(Vector2.ZERO, Vector2.ONE)
		if _last_pointer == null:
			_last_pointer = InputEventMouseMotion.new()
		_last_pointer.position = event.position
		_last_pointer.button_mask = event.button_mask
	_dispatch_pointer(event)


func _process(delta: float) -> void:
	var target := (_pointer_uv * 2.0 - Vector2.ONE) * _movement_strength
	var next := _image_offset.lerp(target, 1.0 - exp(-delta / 0.16))
	if next.distance_squared_to(_image_offset) < 1.0e-14:
		return
	_image_offset = next
	(screen.material as ShaderMaterial).set_shader_parameter("image_offset", _image_offset)
	# A settling image moves beneath a stationary pointer. Refresh hover/drag using
	# that pointer, without moving the physical target or delivering another click.
	if _last_pointer != null and not SceneRouter.is_busy():
		_dispatch_pointer(_last_pointer)


func _dispatch_pointer(event: InputEvent) -> void:
	var position_in_screen: Vector2
	if event is InputEventMouse:
		position_in_screen = event.position
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		position_in_screen = event.position
	else:
		return
	var display_uv := position_in_screen / screen.size
	var uv := CRTGeometry.source_uv(display_uv, _curvature, _visible_fraction, _image_offset)
	var inside := CRTGeometry.on_screen(CRTGeometry.glass_uv(display_uv, _curvature)) and CRTGeometry.on_screen(uv)
	if inside and not _mouse_inside:
		content.notify_mouse_entered()
		_mouse_inside = true
	elif not inside:
		_mouse_exited()
	# Forward motion and releases outside the curved image so sliders/holds release.
	if not inside and event is InputEventMouseButton and event.pressed:
		return
	var forwarded := event.duplicate() as InputEvent
	# push_input(..., true) takes logical viewport coordinates, including overrides.
	var mapped := uv * Vector2(content.size_2d_override)
	forwarded.position = mapped
	if forwarded is InputEventMouse:
		forwarded.global_position = mapped
	if forwarded is InputEventMouseMotion or forwarded is InputEventScreenDrag:
		forwarded.relative = mapped - _last_mapped if _have_mapped else Vector2.ZERO
	_last_mapped = mapped
	_have_mapped = true
	content.push_input(forwarded, true)
	var hovered := content.gui_get_hovered_control()
	screen.mouse_default_cursor_shape = hovered.get_cursor_shape(hovered.get_local_mouse_position()) if hovered else Control.CURSOR_ARROW
	screen.accept_event()


func _mouse_exited() -> void:
	if _mouse_inside:
		content.notify_mouse_exited()
		_mouse_inside = false
	screen.mouse_default_cursor_shape = Control.CURSOR_ARROW
	_have_mapped = false


func _screen_mouse_exited() -> void:
	_pointer_uv = Vector2(0.5, 0.5)
	_last_pointer = null
	_mouse_exited()


func _release_input() -> void:
	_screen_mouse_exited()
	# Window focus loss must not leave an on-screen hold button pressed.
	for button: int in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
		var release := InputEventMouseButton.new()
		release.button_index = button
		release.position = Vector2(-1.0, -1.0)
		content.push_input(release, true)


func _resize_content() -> void:
	# Native output resolution for sharp type; retain the root's canvas_items sizing.
	content.size = Vector2i((Vector2(get_window().size) / _visible_fraction).ceil()).max(Vector2i.ONE)
	content.size_2d_override = Vector2i(get_viewport().get_visible_rect().size).max(Vector2i.ONE)
	(screen.material as ShaderMaterial).set_shader_parameter("output_size", Vector2(get_window().size))


func _apply_visuals() -> void:
	var values := GameSettings.visuals()
	var material := screen.material as ShaderMaterial
	for key: String in ["crt_enabled", "curvature", "scanlines", "chromatic_aberration", "glow"]:
		material.set_shader_parameter(key, values[key])
	_curvature = float(values["curvature"]) if values["crt_enabled"] else 0.0
	var moving: bool = values["dynamic_movement"] and not values["reduced_motion"]
	var fraction := CRTGeometry.OVERSCAN_FRACTION if moving else 1.0
	_movement_strength = CRTGeometry.MAX_MOVEMENT * float(values["movement_strength"]) if moving else 0.0
	if not moving:
		_image_offset = Vector2.ZERO
	material.set_shader_parameter("image_offset", _image_offset)
	material.set_shader_parameter("visible_fraction", fraction)
	if fraction != _visible_fraction:
		_visible_fraction = fraction
		_resize_content()
