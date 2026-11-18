extends ReadMore
## Preserve the educational reader, inset within the existing CRT safe area.
## The planner has explicit field-note buttons instead of the floating offer chip.

func _place() -> void:
	super._place()
	_chip.hide()
	_panel.position.y = 70.0
	_panel.size.y = _view().y - 140.0
	if _panel.visible and (_tween == null or not _tween.is_running()):
		_panel.position.x = _view().x - PANEL_WIDTH - 90.0


func _slide(to_x: float, hide_after: bool) -> void:
	var destination := to_x if hide_after else to_x - 74.0
	if GameSettings.reduced_motion():
		if _tween:
			_tween.kill()
		_panel.position.x = destination
		if hide_after:
			_panel.hide()
	else:
		super._slide(destination, hide_after)


func close() -> void:
	super.close()
	_chip.hide()
