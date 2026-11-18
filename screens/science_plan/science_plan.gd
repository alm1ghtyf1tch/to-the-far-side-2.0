extends Control
## Local planning choices only. Campaign remains authoritative at final confirm.

const PICTURES := "res://assets/textures/catalog/"
const PHOTOS := "res://assets/textures/catalog/photos/"
const HOVER_DELAY := 0.14

var _ui: SciencePlannerUI
var _step := 0
var _site_index := -1
var _preview_index := -1
var _picked: Array[bool] = []
var _locked := false
var _site_cards: Array[PlannerCard] = []
var _gear_cards: Array[PlannerCard] = []
var _read_more: ReadMore
var _map_window: PanelContainer
var _map: SiteMap
var _hover_timer: Timer
var _pending_hover := -1


func _ready() -> void:
	_ui = SciencePlannerUI.new()
	add_child(_ui)
	_read_more = preload("res://screens/science_plan/planner_read_more.gd").new()
	add_child(_read_more)
	_hover_timer = Timer.new()
	_hover_timer.one_shot = true
	_hover_timer.wait_time = HOVER_DELAY
	add_child(_hover_timer)
	_hover_timer.timeout.connect(func() -> void:
		if _pending_hover >= 0 and not _locked:
			_preview_site(_pending_hover))
	var sites := Campaign.sites()
	for index in sites.size():
		var site: Dictionary = sites[index]
		var card := PlannerCard.new()
		card.compact = true
		card.tag = str(site["mission"]).to_upper()
		card.title = str(site["name"])
		card.description = str(site["what"])
		card.specifications = "+%d SCIENCE  /  %s RISK" % [site["science"], str(site["risk"]).to_upper()]
		card.pressed.connect(select_site.bind(index))
		card.mouse_entered.connect(_queue_preview.bind(index))
		card.focus_entered.connect(_queue_preview.bind(index))
		card.mouse_exited.connect(_cancel_preview.bind(index))
		card.focus_exited.connect(_cancel_preview.bind(index))
		_ui.site_grid.add_child(card)
		_site_cards.append(card)
	var options := Campaign.instrument_options()
	for index in options.size():
		var item: Dictionary = options[index]
		_picked.append(false)
		var card := PlannerCard.new()
		card.tag = "%s  /  +%d SCIENCE" % [str(item.get("era", "")).to_upper(), item["science"]]
		card.title = str(item["name"])
		card.description = str(item["what"])
		card.specifications = _gear_specs(item)
		card.image_path = _picture(str(item["id"]))
		card.pressed.connect(toggle_instrument.bind(index))
		card.details_requested.connect(_show_details.bind(item))
		_ui.gear_grid.add_child(card)
		_gear_cards.append(card)
	_build_map()
	_ui.site_tab.pressed.connect(show_step.bind(0))
	_ui.gear_tab.pressed.connect(show_step.bind(1))
	_ui.confirm.pressed.connect(_on_confirm_pressed)
	_ui.map_button.pressed.connect(_toggle_map)
	_ui.details.pressed.connect(func() -> void:
		if _preview_index >= 0:
			_show_details(Campaign.sites()[_preview_index]))
	_show_inspector(-1)
	show_step(0)


func show_step(step: int) -> void:
	if _locked:
		return
	_hover_timer.stop()
	_pending_hover = -1
	_step = step
	_ui.show_step(step)
	if step == 1:
		_map_window.hide()
		if _site_index >= 0:
			_preview_site(_site_index)
	_refresh()


func _queue_preview(index: int) -> void:
	if _locked or _step != 0:
		return
	_pending_hover = index
	_hover_timer.start()


func _cancel_preview(index: int) -> void:
	if _pending_hover == index:
		_hover_timer.stop()
		_pending_hover = -1


func _preview_site(index: int) -> void:
	_preview_index = index
	_ui.lunar.preview_site(index)
	_show_inspector(index)


func select_site(index: int) -> void:
	if _locked or index < 0 or index >= Campaign.sites().size():
		return
	_hover_timer.stop()
	_pending_hover = -1
	_site_index = index
	_preview_site(index)
	_offer(Campaign.sites()[index])
	_refresh()


func toggle_instrument(index: int) -> void:
	if _locked:
		return
	_picked[index] = not _picked[index]
	_offer(Campaign.instrument_options()[index])
	_refresh()


func _show_inspector(index: int) -> void:
	_ui.details.visible = index >= 0
	if index < 0:
		_ui.inspector_body.text = "Survey six historic Apollo landing regions. Dark volcanic plains offer gentler terrain; mountain sites reward a more demanding expedition."
		_ui.inspector_specs.text = "HOVER TO SURVEY\nCLICK TO SET DESTINATION\n\nYour choices stay provisional until\nyou confirm the science payload."
		return
	var site: Dictionary = Campaign.sites()[index]
	_ui.inspector_tag.text = "%s  /  SURFACE SURVEY" % str(site["mission"]).to_upper()
	_ui.inspector_title.text = str(site["name"])
	_ui.inspector_body.text = str(site["what"])
	_ui.inspector_specs.text = "%.3f° %s    %.3f° %s\n\nSCIENCE VALUE    +%d\nLANDING RISK     %s\nEXTRA Δv         %s" % [
		absf(float(site["lat"])), "N" if float(site["lat"]) >= 0 else "S",
		absf(float(site["lon"])), "E" if float(site["lon"]) >= 0 else "W",
		site["science"], str(site["risk"]).to_upper(),
		"None" if float(site["extra_dv"]) <= 0 else "+%.2f km/s" % float(site["extra_dv"])]
	UiMotion.reveal(_ui.inspector_title, 0.2)


func _chosen() -> Array:
	var options := Campaign.instrument_options()
	var chosen := []
	for index in options.size():
		if _picked[index]:
			chosen.append(options[index])
	return chosen


func _refresh() -> void:
	for index in _site_cards.size():
		_site_cards[index].mark(index == _site_index)
	for index in _gear_cards.size():
		_gear_cards[index].mark(_picked[index])
	_map.selected = _site_index
	_ui.lunar.set_states(_site_index, _preview_index)
	var site: Dictionary = Campaign.sites()[_site_index] if _site_index >= 0 else {}
	var chosen := _chosen()
	var totals := Campaign.plan_totals(site, chosen)
	AnimatedValue.show_value(_ui.values["science"], float(totals["science"]))
	AnimatedValue.show_value(_ui.values["mass"], float(totals["mass"]), " kg")
	AnimatedValue.show_value(_ui.values["power"], float(totals["power"]), " W")
	AnimatedValue.show_value(_ui.values["cost"], float(totals["cost"]), "%", 1)
	AnimatedValue.show_value(_ui.values["left"], Campaign.budget_left - float(totals["cost"]), "%", 1)
	_ui.site_tab.text = "01   LANDING SITE" + ("  ✓" if _site_index >= 0 else "")
	_ui.gear_tab.text = "02   SCIENCE PAYLOAD  (%d)" % chosen.size()
	_ui.confirm.text = "Next: equipment  ›" if _step == 0 else "Confirm plan"
	_ui.confirm.disabled = _site_index < 0 or _locked
	_ui.selected_label.text = "DESTINATION  /  " + ("AWAITING SELECTION" if site.is_empty() else "%s · %s" % [site["mission"], site["name"]])
	_ui.status.text = "Choose a landing site to continue" if _site_index < 0 else "%s (%s site)  ·  %d items  ·  USD %.2f billion" % [site["name"], site["mission"], chosen.size(), Campaign.billions(float(totals["cost"]))]
	for child in _ui.tray.get_children():
		_ui.tray.remove_child(child)
		child.queue_free()
	if chosen.is_empty():
		_ui.tray.add_child(_ui.label("No instruments selected. Add equipment from the rack above.", 16, VisualTheme.MUTED))
	for index in _picked.size():
		if not _picked[index]:
			continue
		var item: Dictionary = Campaign.instrument_options()[index]
		var chip := _ui.button(str(item["id"]).replace("_", " ").to_upper() + "  ×")
		chip.custom_minimum_size.y = 36
		chip.add_theme_font_size_override("font_size", 14)
		chip.tooltip_text = str(item["name"]) + " · Click to remove"
		chip.pressed.connect(toggle_instrument.bind(index))
		_ui.tray.add_child(chip)
		UiMotion.reveal(chip, 0.2)


func _on_confirm_pressed() -> void:
	if _locked or _site_index < 0:
		return
	if _step == 0:
		show_step(1)
		return
	_locked = true
	_hover_timer.stop()
	_ui.confirm.disabled = true
	_ui.confirm.text = "Confirmed"
	_map_window.hide()
	_read_more.clear()
	# The original single commit boundary, calculation, clock and route timings.
	Campaign.set_science_plan(Campaign.sites()[_site_index], _chosen())
	Campaign.clock_running = true
	await get_tree().create_timer(0.6).timeout
	SceneRouter.go_to(SceneRouter.HQ, 0.6)


func _picture(file_name: String) -> String:
	for extension: String in ["jpg", "jpeg", "png", "webp"]:
		var photo := "%s%s.%s" % [PHOTOS, file_name, extension]
		if ResourceLoader.exists(photo):
			return photo
	var drawing := "%s%s.png" % [PICTURES, file_name]
	return drawing if ResourceLoader.exists(drawing) else ""


func _offer(item: Dictionary) -> void:
	var topic: Dictionary = (item.get("read_more", {}) as Dictionary).duplicate()
	if topic.is_empty():
		return
	topic["title"] = str(item.get("name", ""))
	var is_site := item.has("mission")
	topic["image"] = _picture(("site_%s" if is_site else "%s") % item.get("id", ""))
	topic["image_note"] = "" if str(topic["image"]).begins_with(PHOTOS) else "Illustration made for this game, not a photograph."
	_read_more.offer(topic)


func _show_details(item: Dictionary) -> void:
	_offer(item)
	_read_more.open()


func _gear_specs(item: Dictionary) -> String:
	var power := float(item.get("power_w", 0.0))
	return "%d kg  ·  %s  ·  cost %s%%" % [roundi(float(item.get("mass_kg", 0.0))),
		"no power" if power <= 0.0 else "%d W" % roundi(power), ("%.1f" % float(item.get("cost_pct", 0.0))).trim_suffix(".0")]


func _build_map() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	_map_window = _ui.panel(Color("101e30"))
	_map_window.position = Vector2(100, 80)
	_map_window.hide()
	layer.add_child(_map_window)
	var box := VBoxContainer.new()
	_map_window.add_child(box)
	var close := _ui.button("Near-side reference map   /   Close ×")
	close.pressed.connect(_toggle_map)
	box.add_child(close)
	_map = SiteMap.new()
	_map.custom_minimum_size = Vector2(660, 660)
	_map.sites = Campaign.sites()
	_map.site_clicked.connect(select_site)
	box.add_child(_map)
	var caption := _ui.label("Click a red dot to choose a site. North is up.", 16, VisualTheme.MUTED)
	box.add_child(caption)
	_map.caption_changed.connect(func(text: String) -> void:
		caption.text = "Click a red dot to choose a site. North is up." if text.is_empty() else text)


func _toggle_map() -> void:
	_map_window.visible = not _map_window.visible
