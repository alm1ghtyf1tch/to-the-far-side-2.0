extends Control
## Receives already CRT-mapped native GUI coordinates; no second display transform.

signal section_clicked(slot: String)
var hangar: AssemblyHangar
var shell: ImmersiveSceneShell


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var pixel: Vector2 = event.position / size * Vector2(shell.viewport_3d.size)
		var slot := hangar.rocket.pick(hangar.camera.project_ray_origin(pixel), hangar.camera.project_ray_normal(pixel))
		if not slot.is_empty():
			accept_event()
			section_clicked.emit(slot)
