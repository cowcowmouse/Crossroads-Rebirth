extends TextureButton

# --- 新增缩放相关的变量 ---
var normal_scale: Vector2
var pressed_scale := Vector2(0.94, 0.94) # 按下时缩小到 94%

func _ready():
	# 记录初始缩放比例
	normal_scale = scale
	
	# 加入返回按钮分组
	add_to_group("back_button")
	add_to_group("interactable")
	
	# 连接原本的点击信号
	pressed.connect(_on_pressed)
	
	# --- 新增：连接缩放相关的信号 ---
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	mouse_exited.connect(_on_mouse_exited)
	
	print("✅ 返回按钮已初始化: ", name)

# --- 新增：处理缩放的逻辑函数 ---
func _on_button_down():
	# 按下时缩小
	scale = Vector2(normal_scale.x * pressed_scale.x, normal_scale.y * pressed_scale.y)

func _on_button_up():
	# 抬起时恢复
	scale = normal_scale

func _on_mouse_exited():
	# 鼠标滑出时也恢复，防止按钮卡在缩小状态
	scale = normal_scale

# --- 原有的业务逻辑保持不变 ---
func _on_pressed():
	print("🔙 返回按钮被点击: ", name)
	scale = normal_scale # 确保点击触发后状态是正常的
	notify_tutorial()
	return_to_main_safe()

func notify_tutorial():
	var tree = get_tree()
	if not tree: return
	var current_scene = tree.current_scene
	if not current_scene: return
	
	var tutorial = current_scene.find_child("TutorialLayer", true, false)
	if tutorial and tutorial.visible:
		tutorial.on_button_clicked(self)

func return_to_main_safe():
	print("🚀 尝试返回主场景")
	Engine.get_main_loop().call_deferred("_return_to_main")

func _return_to_main():
	print("✅ 执行返回主场景")
	var main_path = "res://project/scenes/main/main.tscn"
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file(main_path)
	else:
		var err = Engine.get_main_loop().change_scene_to_file(main_path)
		if err != OK:
			print("❌ 切换失败，错误码: ", err)
