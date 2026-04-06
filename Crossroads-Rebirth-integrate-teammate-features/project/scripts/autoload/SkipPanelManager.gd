extends Node

signal skip_panel_shown()
signal skip_panel_hidden()
signal skip_to_next_phase()

var is_forced: bool = false
var skip_panel: Panel = null

func register_panel(panel_node: Panel):
	skip_panel = panel_node
	skip_panel.visible = false
	
	# 连接跳过按钮
	var skip_btn = skip_panel.get_node("SkipButton")
	if skip_btn:
		skip_btn.pressed.connect(_on_skip_pressed)

func show_skip_panel(forced: bool = false):
	if not skip_panel:
		return
	
	is_forced = forced
	skip_panel.visible = true
	skip_panel_shown.emit()
	
	# 如果是强制显示，禁用其他UI
	if forced:
		_set_other_ui_enabled(false)

func hide_skip_panel():
	if not skip_panel:
		return
	
	skip_panel.visible = false
	is_forced = false
	skip_panel_hidden.emit()
	
	# 恢复UI
	_set_other_ui_enabled(true)

func _on_skip_pressed():
	hide_skip_panel()
	skip_to_next_phase.emit()

func _set_other_ui_enabled(enabled: bool):
	# 禁用/启用操作按钮（设施升级、成员管理等）
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("set_operation_ui_enabled"):
		main_scene.set_operation_ui_enabled(enabled)
