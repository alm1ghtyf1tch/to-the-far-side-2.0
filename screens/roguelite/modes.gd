extends Control

var _sheet := {}
var _body: VBoxContainer
var _error: Label


func _ready() -> void:
	if RogueRun.active:
		RogueRun.suspend()
	var background: Control = load(SceneRouter.MAIN_MENU).instantiate()
	# Reuse the authored backdrop without rerunning the menu's settings/routing.
	background.set_script(null)
	add_child(background)
	background.get_node("%Column").hide()
	background.get_node("%MenuBox").hide()
	(background.get_node("%Sky").material as ShaderMaterial).set_shader_parameter("rise", 1.0)
	(background.get_node("%Sky").material as ShaderMaterial).set_shader_parameter("motion", 0.0 if GameSettings.reduced_motion() else 1.0)
	_sheet = RogueWidgets.sheet(self, "MISSION DIRECTOR / PROGRAMME SELECTION")
	_sheet["close"].pressed.connect(func() -> void: SceneRouter.go_to(SceneRouter.MAIN_MENU))
	_body = _sheet["body"]
	_show_modes()


func _clear() -> void:
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()


func _show_modes() -> void:
	_clear()
	_body.add_child(RogueWidgets.label("To the Far Side", 40))
	_body.add_child(RogueWidgets.label("Choose a programme", 26, VisualTheme.AMBER))
	_body.add_child(RogueWidgets.button("Story Campaign / original authored lunar mission", story))
	if Campaign.stage > 1:
		_body.add_child(RogueWidgets.button("Continue Story session", func() -> void: SceneRouter.go_to(SceneRouter.HQ)))
	_body.add_child(RogueWidgets.button("Rogue Rocket / create a space agency", _create_agency))
	_body.add_child(RogueWidgets.button("Resume saved Rogue Rocket run", _resume, FileAccess.file_exists(RogueRun.save_path) or FileAccess.file_exists(RogueRun.save_path + ".bak")))
	_body.add_child(RogueWidgets.label("Three contracts. Limited hardware. Research priorities. One agency.\nStory and Rogue Rocket keep separate progress.", 20, VisualTheme.MUTED))
	_error = RogueWidgets.label("", 18, VisualTheme.AMBER)
	_body.add_child(_error)


func story() -> void:
	Campaign.reset()
	SceneRouter.go_to(SceneRouter.HQ)


func _resume() -> void:
	if RogueRun.resume():
		SceneRouter.go_to(SceneRouter.ROGUE_CONTROL if RogueRun.state["phase"] == "flight" else SceneRouter.ROGUE_HQ)
	else:
		_error.text = RogueRun.last_error


func _create_agency() -> void:
	_clear()
	_body.add_child(RogueWidgets.label("Create your agency", 32))
	var name_input := LineEdit.new()
	name_input.text = "Far Side Agency"
	name_input.max_length = 32
	name_input.custom_minimum_size.y = 48
	_body.add_child(name_input)
	_body.add_child(RogueWidgets.label("Run seed / use the same seed to repeat offers and events", 18, VisualTheme.MUTED))
	var seed_input := LineEdit.new()
	seed_input.placeholder_text = "Optional seed"
	seed_input.max_length = 64
	seed_input.custom_minimum_size.y = 44
	_body.add_child(seed_input)
	var doctrines := OptionButton.new()
	doctrines.custom_minimum_size.y = 44
	for item: Dictionary in RogueCatalog.rules()["doctrines"]:
		doctrines.add_item(str(item["name"]))
	_body.add_child(doctrines)
	var description := RogueWidgets.label(str(RogueCatalog.rules()["doctrines"][0]["description"]), 20, VisualTheme.MUTED)
	_body.add_child(description)
	doctrines.item_selected.connect(func(index: int) -> void: description.text = str(RogueCatalog.rules()["doctrines"][index]["description"]))
	var emblem := OptionButton.new()
	for identity: String in ["Amber / Horizon", "Cyan / Orbital", "Ivory / Expedition", "Red / Pioneer"]:
		emblem.add_item(identity)
	emblem.custom_minimum_size.y = 44
	_body.add_child(emblem)
	_body.add_child(RogueWidgets.button("Start new run / replace saved Rogue run", func() -> void:
		var doctrine: Dictionary = RogueCatalog.rules()["doctrines"][doctrines.selected]
		if RogueRun.start(name_input.text, str(doctrine["id"]), seed_input.text, emblem.selected):
			SceneRouter.go_to(SceneRouter.ROGUE_HQ)))
	_body.add_child(RogueWidgets.button("Back to programme selection", _show_modes))
	name_input.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		SceneRouter.go_to(SceneRouter.MAIN_MENU)
