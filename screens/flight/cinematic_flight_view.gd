class_name CinematicFlightView
extends FlightView
## Preserve FlightView's public contract for StagingGame and its trajectory data.
## The 2D renderer is replaced by an isolated 3D observation stage.

var space: SpaceflightStage
var presentation := MissionPresentation.new()
var viewport_3d: SubViewport
var _last_burn := false


func _ready() -> void:
	_stack.self_modulate.a = 0.0
	_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stack.hide()
	_stack.process_mode = Node.PROCESS_MODE_DISABLED
	_build_paths()
	viewport_3d = SubViewport.new()
	viewport_3d.own_world_3d = true
	viewport_3d.size = Vector2i(1200, 760)
	viewport_3d.msaa_3d = Viewport.MSAA_2X
	add_child(viewport_3d)
	space = preload("res://environments/flight/space_stage.tscn").instantiate()
	viewport_3d.add_child(space)
	presentation.stage = space
	var image := TextureRect.new()
	image.texture = viewport_3d.get_texture()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(image)
	resized.connect(_resize_view)
	_resize_view()


func _resize_view() -> void:
	if viewport_3d:
		viewport_3d.size = Vector2i(size).max(Vector2i.ONE)


func setup(design: Dictionary, site: Dictionary, high_orbit: bool) -> void:
	# Original trajectory data remains available for the read-only navigation panel.
	super.setup(design, site, high_orbit)
	space.spacecraft.configure(design)


func _process(_delta: float) -> void:
	_stack.hide()
	if space and presentation.current_phase in ["countdown", "ascent"] and _last_burn != burning:
		_last_burn = burning
		space.spacecraft.launch_burn(staged, burning)
	if space and presentation.current_phase == "landing" and mode == "descent" and space.spacecraft.configuration == "lander":
		space.spacecraft.lander.position.y = lerpf(-0.5, -2.25, progress)


func _draw() -> void:
	pass


func reset_stack() -> void:
	staged = 0
	if space:
		space.spacecraft.reset_stack()


func drop_stage(number: int, animate := true) -> void:
	while staged < number and staged < 2:
		staged += 1
		space.spacecraft.separate(staged, not animate)
	space.spacecraft.launch_burn(staged, burning, not animate)


func settle_wreck() -> void:
	space.spacecraft.mark_fault("stage1", true)


func present_phase(phase: Dictionary, instant := false) -> void:
	presentation.begin(phase, instant)
	_last_burn = false
	if str(phase["id"]) == "landing" and not bool(phase.get("manual", false)):
		# Failed hardware/no surface crew: no fabricated normal descent burn.
		space.spacecraft.burn([], false, instant)
	elif str(phase["id"]) == "landing":
		space.spacecraft.burn([space.spacecraft.lander], true, instant)
	if str(phase["id"]) == "landing" and int(Vehicle.stats.get("surface_crew", 0)) <= 0:
		space.spacecraft.show_configuration("ship", instant)
		space.spacecraft.burn([], false, instant)


func present_landing_result(outcome: Dictionary) -> void:
	space.spacecraft.burn([], false, true)
	if str(outcome.get("result", "abort")) in ["landed", "hard"]:
		space.set_context("surface")
		space.spacecraft.show_configuration("surface", true)
	else:
		space.set_context("moon")
		space.spacecraft.show_configuration("ship", true)


func present_line(phase: Dictionary, line: Dictionary, index: int, instant := false) -> void:
	presentation.receive(phase, line, index, instant)
