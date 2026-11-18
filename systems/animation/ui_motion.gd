class_name UiMotion
extends Node
## Attach to a native button and animate only its non-interactive visual face.

const HOVER_TIME := 0.14
const PRESS_TIME := 0.08
const RETURN_TIME := 0.24
const PANEL_TIME := 0.3

var visual: Control
var source: BaseButton
var _hovered := false
var _focused := false
var _down := false
var _tween: Tween


static func bind(button: BaseButton, face: Control) -> UiMotion:
	var motion := UiMotion.new()
	motion.source = button
	motion.visual = face
	button.add_child(motion)
	return motion


func _ready() -> void:
	source.mouse_entered.connect(func() -> void: _hovered = true; refresh())
	source.mouse_exited.connect(func() -> void: _hovered = false; refresh())
	source.focus_entered.connect(func() -> void: _focused = true; refresh())
	source.focus_exited.connect(func() -> void: _focused = false; refresh())
	source.button_down.connect(func() -> void: _down = true; refresh())
	source.button_up.connect(func() -> void: _down = false; refresh())
	visual.resized.connect(_pivot)
	GameSettings.events.visuals_changed.connect(_settings_changed)
	_pivot()


func refresh(immediate := false) -> void:
	if _tween:
		_tween.kill()
	var target := 1.0
	if not GameSettings.reduced_motion() and not source.disabled:
		target = 0.96 if _down else (1.025 if _hovered or _focused else 1.0)
	if immediate or GameSettings.reduced_motion():
		visual.scale = Vector2.ONE * target
		return
	_tween = visual.create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC if _down else Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(visual, "scale", Vector2.ONE * target, PRESS_TIME if _down else (HOVER_TIME if target > 1.0 else RETURN_TIME))


func _settings_changed() -> void:
	refresh(true)


func _pivot() -> void:
	visual.pivot_offset = visual.size * 0.5


static func reveal(target: Control, duration := PANEL_TIME, delay := 0.0) -> Tween:
	if target.has_meta(&"reveal_tween"):
		var previous: Tween = target.get_meta(&"reveal_tween")
		if previous and previous.is_valid():
			previous.kill()
	target.visible = true
	if GameSettings.reduced_motion():
		target.modulate.a = 1.0
		target.scale = Vector2.ONE
		return null
	target.modulate.a = 0.0
	target.scale = Vector2.ONE * 0.985
	target.pivot_offset = target.size * 0.5
	var tween := target.create_tween().set_parallel(true)
	tween.tween_property(target, "modulate:a", 1.0, duration).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", Vector2.ONE, duration).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	target.set_meta(&"reveal_tween", tween)
	return tween
