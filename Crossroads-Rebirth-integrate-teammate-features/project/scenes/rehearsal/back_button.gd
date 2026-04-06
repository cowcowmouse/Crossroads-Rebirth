extends TextureButton

func _ready():
	# 加入返回按钮分组
	add_to_group("back_button")
	add_to_group("interactable")
	
	# 连接信号
	pressed.connect(_on_pressed)
	
	print("✅ 返回按钮已初始化: ", name)

func _on_pressed():
	print("🔙 返回按钮被点击: ", name)
	
	# 通知引导层
	notify_tutorial()
	
	# 使用最安全的方式返回主场景
	return_to_main_safe()

func notify_tutorial():
	# 安全地通知引导层
	var tree = get_tree()
	if not tree:
		return
	
	var current_scene = tree.current_scene
	if not current_scene:
		return
	
	var tutorial = current_scene.find_child("TutorialLayer", true, false)
	if tutorial and tutorial.visible:
		tutorial.on_button_clicked(self)

func return_to_main_safe():
	print("🚀 尝试返回主场景")
	
	# 直接使用 Engine 的延迟调用，避免场景树问题
	Engine.get_main_loop().call_deferred("_return_to_main")

# 这个函数会在主循环中执行，最安全
func _return_to_main():
	print("✅ 执行返回主场景")
	
	# 主场景路径
	var main_path = "res://project/scenes/main/main.tscn"
	
	# 尝试切换场景
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file(main_path)
	else:
		# 如果 tree 还是 null，用更底层的方法
		var err = Engine.get_main_loop().change_scene_to_file(main_path)
		if err != OK:
			print("❌ 切换失败，错误码: ", err)
