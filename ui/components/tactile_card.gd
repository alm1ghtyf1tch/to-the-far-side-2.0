class_name TactileCard
extends TactileButton
## Native toggle semantics keep selection separate from temporary hover/focus.


func _ready() -> void:
	theme = VisualTheme.shared()
	theme_type_variation = &"MissionCard"
	toggle_mode = true
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	custom_minimum_size = Vector2(260, 84)
	super._ready()
