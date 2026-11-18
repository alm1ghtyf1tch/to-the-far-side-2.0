class_name AnimatedValue
extends RefCounted
## Interruptible display interpolation. Callers supply authoritative totals.

static func show_value(label: Label, value: float, unit := "", precision := 0) -> void:
	var previous: Tween = label.get_meta("number_tween") if label.has_meta("number_tween") else null
	if previous:
		previous.kill()
	label.set_meta("target_value", value)
	if GameSettings.reduced_motion():
		_render(value, label, unit, precision)
		return
	var tween := label.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	label.set_meta("number_tween", tween)
	tween.tween_method(_render.bind(label, unit, precision), float(label.get_meta("display_value", value)), value, 0.28)


static func _render(value: float, label: Label, unit: String, precision: int) -> void:
	label.set_meta("display_value", value)
	label.text = (("%.1f" % value).trim_suffix(".0") if precision == 1 else "%d" % roundi(value)) + unit
