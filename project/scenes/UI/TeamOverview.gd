# res://project/scenes/ui/TeamOverview.gd
extends Control

@onready var grid = $GridContainer

const MEMBER_IDS = [
	"old_nail", "kira", "mei", "rio", "finn",
	"sebastian", "lily", "aya", "duane"
]

func _ready():
	# 确保全屏
	anchor_left = 0
	anchor_top = 0
	anchor_right = 1
	anchor_bottom = 1
	
	refresh_members()

func refresh_members():
	for i in grid.get_child_count():
		var slot = grid.get_child(i)
		if not slot: continue
		
		var member_id = MEMBER_IDS[i]
		var member = MemberManager.get_member(member_id)
		
		if not member:
			slot.text = "？？？"
			continue
		
		# 显示名字
		var name_label = slot.get_node_or_null("NameLabel") 
		if name_label:
			name_label.text = member.name
		
		# 显示招募状态
		var status_label = slot.get_node_or_null("StatusLabel")
		if status_label:
			if member.unlocked:
				status_label.text = "已入队"
				status_label.modulate = Color(0, 1, 0)
			else:
				status_label.text = "未招募"
				status_label.modulate = Color(0.6, 0.6, 0.6)

		# 点击槽位
		slot.pressed.connect(_on_slot_clicked.bind(member_id))

func _on_slot_clicked(member_id: String):
	print("点击了成员按钮：", member_id)   # 必须能打印这一行
	
	var recruit_scene = preload("res://project/scenes/UI/RecruitPanel.tscn")
	if not recruit_scene:
		print("错误：找不到 RecruitPanel.tscn 文件")
		return
	
	var panel = recruit_scene.instantiate()
	add_child(panel)
	
	# 调用 setup 方法传入成员ID
	if panel.has_method("setup"):
		panel.setup(member_id)
	else:
		print("错误：RecruitPanel 没有 setup 方法")

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://project/scenes/main/BarScene.tscn") 


func _on_exit_button_pressed():
	print("退出按钮被点击！正在返回主场景...")
	
	var main_scene_path = "res://project/scenes/main/main.tscn"
	
	if ResourceLoader.exists(main_scene_path):
		var err = get_tree().change_scene_to_file(main_scene_path)
		if err == OK:
			print("成功返回主场景")
		else:
			print("跳转失败，错误码：", err)
	else:
		print("错误：主场景路径不存在！")
		print("当前使用的路径是：", main_scene_path)
	
func _on_slot_clicked1(member_id: String):
	print("打开招募界面：", member_id)
	
	var recruit_panel_scene = preload("res://project/scenes/UI/RecruitPanel.tscn")
	var panel = recruit_panel_scene.instantiate()
	add_child(panel)
	panel.setup(member_id)
