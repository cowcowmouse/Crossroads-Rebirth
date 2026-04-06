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
