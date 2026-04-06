extends Control

# ------------- 配置区 -------------
@onready var panel_team = $Panel_Team
@onready var btn_close = $Btn_Close
@onready var grid_avatars = $Panel_Team/Grid_Avatars
@onready var slots = [
	$Panel_Team/Grid_Avatars/Slot_1,
	$Panel_Team/Grid_Avatars/Slot_2,
	$Panel_Team/Grid_Avatars/Slot_3,
	$Panel_Team/Grid_Avatars/Slot_4
]

# ------------- 逻辑 -------------
func _ready():
	# 初始状态：隐藏
	panel_team.visible = false
	btn_close.visible = false

# 切换显示/隐藏
func _toggle_panel():
	panel_team.visible = !panel_team.visible
	btn_close.visible = panel_team.visible

# 隐藏面板
func _hide_panel():
	panel_team.visible = false
	btn_close.visible = false

# 打开按钮（你已经绑好了）
func _on_btn_toggle_team_pressed() -> void:
	_toggle_panel()

# 关闭按钮（我帮你补全了！）
func _on_btn_close_pressed() -> void:
	_hide_panel()
