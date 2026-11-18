class_name ImmersiveSceneShell
extends Control
## Screen-local, full-bleed 3D plus native overlays. The global CRT stays outside.

var viewport_3d: SubViewport
var world: Node3D
var overlays: Control
var image: TextureRect


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport_3d = SubViewport.new()
	viewport_3d.name = "ImmersiveWorld"
	viewport_3d.own_world_3d = true
	viewport_3d.msaa_3d = Viewport.MSAA_2X
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport_3d)
	image = TextureRect.new()
	image.name = "FullBleedScene"
	image.texture = viewport_3d.get_texture()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(image)
	overlays = Control.new()
	overlays.name = "FloatingOverlays"
	overlays.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlays)
	resized.connect(_resize_world)
	_resize_world()


func set_world(scene: PackedScene) -> Node3D:
	if is_instance_valid(world):
		viewport_3d.remove_child(world)
		world.queue_free()
	world = scene.instantiate()
	viewport_3d.add_child(world)
	return world


func _resize_world() -> void:
	viewport_3d.size = Vector2i(size).max(Vector2i.ONE)
