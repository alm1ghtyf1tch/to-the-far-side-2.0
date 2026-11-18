class_name AnimatedPanel
extends PanelContainer

var _reveal: Tween


func _ready() -> void:
	GameSettings.events.visuals_changed.connect(_settings_changed)


func reveal() -> void:
	_reveal = UiMotion.reveal(self)


func _settings_changed() -> void:
	if GameSettings.reduced_motion() and _reveal and _reveal.is_valid():
		_reveal.kill()
		modulate.a = 1.0
		scale = Vector2.ONE
