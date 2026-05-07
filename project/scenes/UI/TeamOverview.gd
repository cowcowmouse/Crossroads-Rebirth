# res://project/scenes/ui/TeamOverview.gd
extends Control

@onready var grid = $GridContainer

# 安全引用 MemberManager
@onready var member_manager = get_node_or_null("/root/MemberManager")

const MEMBER_IDS = [
	"old_nail", "kira", "mei", "rio", "finn",
	"sebastian", "lily", "aya", "duane"
]

func _ready():
	anchor_left = 0
	anchor_top = 0
	anchor_right = 1
	anchor_bottom = 1
	print("TeamOverview 已加载，准备刷新成员列表")
	refresh_members()

func refresh_members():
	if not member_manager:
		print("错误：MemberManager 未找到！")
		return
	
	print("正在刷新9个成员槽位...")
	
	for i in grid.get_child_count():
		var slot = grid.get_child(i)
		if not slot:
			continue
		
		var member_id = MEMBER_IDS[i]
		var member = member_manager.get_member(member_id)
		
		# 显示名字和状态
		var name_label = slot.get_node_or_null("NameLabel")
		var status_label = slot.get_node_or_null("StatusLabel")
		
		if name_label:
			name_label.text = member.name if member else "未知"
		if status_label:
			if member and member.unlocked:
				status_label.text = "已入队"
				status_label.modulate = Color(0, 1, 0)
			else:
				status_label.text = "未招募"
				status_label.modulate = Color(0.6, 0.6, 0.6)
		
		# 【关键修复】确保信号只连接一次
		if not slot.is_connected("pressed", _on_slot_clicked):
			slot.pressed.connect(_on_slot_clicked.bind(member_id))
			print("已连接点击信号 -> ", member_id)

func _on_slot_clicked(member_id: String):
	print("✅ 点击了成员按钮：", member_id)   # 这行一定要在控制台看到！
	
	var recruit_scene = preload("res://project/scenes/UI/RecruitPanel.tscn")
	if not recruit_scene:
		print("错误：找不到 RecruitPanel.tscn")
		return
	
	var panel = recruit_scene.instantiate()
	get_tree().current_scene.add_child(panel)   # 改用 current_scene 更安全
	
	if panel.has_method("setup"):
		panel.setup(member_id)
		print("已打开招募面板：", member_id)
	else:
		print("错误：RecruitPanel 没有 setup 方法")

# 退出按钮保持不变
func _on_exit_button_pressed():
	print("退出 TeamOverview，准备返回：", Global.previous_scene_path)
	
	if Global.previous_scene_path != "":
		var err = get_tree().change_scene_to_file(Global.previous_scene_path)
		if err != OK:
			print("返回失败！错误码：", err)
	else:
		# 保险：如果没记录就回主场景
		get_tree().change_scene_to_file("res://project/scenes/main/main.tscn")
