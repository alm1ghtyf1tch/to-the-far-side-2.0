extends CanvasLayer

const MAIN_MENU := "res://screens/main_menu/main_menu.tscn"
const HQ := "res://screens/hq/hq.tscn"
const MEETING := "res://screens/meeting/meeting_report.tscn"
const SCIENCE_BUDGET := "res://screens/science/science_budget.tscn"
const CALC_GAME := "res://screens/science/calc_game.tscn"
const SCIENCE_REPORT := "res://screens/science/science_report.tscn"
const BOARD_REVIEW := "res://screens/board/board_review.tscn"
const SCIENCE_PLAN := "res://screens/science_plan/science_plan.tscn"
const ENGINEERING := "res://screens/engineering/vehicle_assembly.tscn"
const OPERATIONS := "res://screens/operations/operations_plan.tscn"
const MISSION_CONTROL := "res://screens/flight/mission_control.tscn"
const MISSION_REPORT := "res://screens/flight/mission_report.tscn"

const FADE_TIME := 0.25

var _fade: ColorRect
var _busy := false
var _presentation_host: Control


func _ready() -> void:
	layer = 100
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)


func go_to(path: String, fade_time := FADE_TIME) -> void:
	if _busy:
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade_to(1.0, fade_time)
	var error: Error
	if is_instance_valid(_presentation_host):
		error = _presentation_host.open_screen(path)
	else:
		# Direct editor scene runs retain their original routing behavior.
		error = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("SceneRouter: не удалось открыть сцену %s (код %d)" % [path, error])
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade_to(0.0, fade_time)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func is_busy() -> bool:
	return _busy


func set_presentation_host(host: Control) -> void:
	_presentation_host = host


func _fade_to(alpha: float, time := FADE_TIME) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_fade, "color:a", alpha, time)
	await tween.finished
