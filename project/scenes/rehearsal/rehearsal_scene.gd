extends Node2D

func _ready():
	# 顶部资源栏统一由 ResourceManager 刷新
	ResourceManager.refresh_current_scene_topbar()

	var back_btn = find_child("BackButton", true, false)

	if back_btn:
		print("找到返回按钮")
		if back_btn.has_signal("pressed"):
			if not back_btn.pressed.is_connected(_on_back_pressed):
				back_btn.pressed.connect(_on_back_pressed)
			print("返回按钮连接成功")
		else:
			print("返回按钮没有 pressed 信号")
	else:
		print("未找到返回按钮，请检查节点名称是否为 'BackButton'")

func _on_back_pressed():
	print("返回主场景")
	get_tree().change_scene_to_file("res://project/scenes/main/main.tscn")


func _on_btn_team_overview_pressed() -> void:
	print("乐队成员按钮被点击！准备跳转...")  # 先打印测试
	
	var team_scene_path = "res://project/scenes/ui/TeamOverview.tscn"
	
	if ResourceLoader.exists(team_scene_path):
		var err = get_tree().change_scene_to_file(team_scene_path)
		if err != OK:
			print("跳转失败！错误码：", err)
		else:
			print("成功跳转到人物界面")
	else:
		print("错误：找不到 TeamOverview.tscn 文件")
		print("请确认路径是否正确")
