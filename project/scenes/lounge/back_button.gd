extends TextureButton

# --- 缩放参数设定 ---
var normal_scale: Vector2
var pressed_scale := Vector2(0.94, 0.94)

func _ready():
	# 记录初始大小（确保记录的是你编辑器里调好的大小）
	normal_scale = scale
	
	# 设置处理模式，确保它能一直运行
	set_process(true)
	
	# 加入原有分组
	add_to_group("back_button")
	add_to_group("interactable")
	
	# 连接核心逻辑信号
	pressed.connect(_on_pressed)
	
	print("✅ 返回按钮初始化成功")

# --- 强制缩放逻辑：每一帧都会检查按钮状态 ---
func _process(_delta):
	if is_pressed():
		# 只要按钮是“按住”状态，强制变小
		scale = normal_scale * pressed_scale
	else:
		# 只要没按住，强制回弹
		scale = normal_scale

# --- 原有的点击跳转逻辑 ---
func _on_pressed():
	print("🔙 点击跳转中...")
	# 执行跳转前再次确保大小正常
	scale = normal_scale
	
	notify_tutorial()
	return_to_main_safe()

# --- 原有逻辑（保持不变） ---
func notify_tutorial():
	var tree = get_tree()
	if not tree or not tree.current_scene: return
	var tutorial = tree.current_scene.find_child("TutorialLayer", true, false)
	if tutorial and tutorial.visible:
		tutorial.on_button_clicked(self)

func return_to_main_safe():
	Engine.get_main_loop().call_deferred("_return_to_main")

func _return_to_main():
	var main_path = "res://project/scenes/main/main.tscn"
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file(main_path)
