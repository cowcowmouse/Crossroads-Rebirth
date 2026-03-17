extends Node2D  # 核心：适配Node2D

# ===================== 节点引用 =====================
# 箭头节点
@onready var arrow_left = get_node_or_null("ArrowLeft")
@onready var arrow_right = get_node_or_null("ArrowRight")
# 对话按钮
@onready var button = get_node_or_null("Button")
# 引用康复面板
@onready var rehab_panel = $UILayer/Rehabpanel
# 顶部康复触发按钮
@onready var rehab_trigger_btn = $UILayer/TopBar/RehabBtn
# 顶部UI状态标签（这里改了文件结构，每个资源显示的UI单独开一组，方便设计单独图标）
@onready var money_label = get_node_or_null("UILayer/TopBar/MoneyGroup/MoneyLabel")
@onready var reputation_label = get_node_or_null("UILayer/TopBar/ReputationGroup/ReputationLabel")
@onready var cohesion_label = get_node_or_null("UILayer/TopBar/CohesionGroup/CohesionLabel")
@onready var creativity_label = get_node_or_null("UILayer/TopBar/CreativityGroup/CreativityLabel")
@onready var memory_label = get_node_or_null("UILayer/TopBar/MemoryGroup/MemoryLabel")
@onready var action_point_label = get_node_or_null("UILayer/TopBar/ActionPointGroup/ActionPointLabel")
@onready var money_icon = get_node_or_null("UILayer/TopBar/MoneyGroup/MoneyIcon")
@onready var reputation_icon = get_node_or_null("UILayer/TopBar/ReputationGroup/ReputationIcon")
@onready var cohesion_icon = get_node_or_null("UILayer/TopBar/CohesionGroup/CohesionIcon")
@onready var creativity_icon = get_node_or_null("UILayer/TopBar/CreativityGroup/CreativityIcon")
@onready var memory_icon = get_node_or_null("UILayer/TopBar/MemoryGroup/MemoryIcon")
@onready var action_point_icon = get_node_or_null("UILayer/TopBar/ActionPointGroup/ActionPointIcon")

@onready var tutorial_layer = $TutorialLayer

# 安全等待函数，避免 null 错误
func safe_wait_frames(frame_count: int):
	for i in range(frame_count):
		await Engine.get_main_loop().process_frame
# ===================== 初始化 =====================
func _ready():
	connect_dialogic_signals()
	# 初始化顶部UI显示（示例数值，可自定义）
	init_top_ui()
	
	# 箭头节点绑定（保留你的原有逻辑）
	print("当前脚本附加的节点：", self.name)
	print("所有子节点：")
	for child in get_children():
		print("  - ", child.name)
	
	# 如果没找到，尝试用find_child再找一次
	if not arrow_left:
		arrow_left = find_child("ArrowLeft", true, false)
	if not arrow_right:
		arrow_right = find_child("ArrowRight", true, false)
	
	# ===== 连接箭头按钮 =====
	print("\n===== 连接按钮 =====")
	
	# 左箭头
	if arrow_left:
		print("左箭头找到，类型：", arrow_left.get_class())
		if arrow_left.has_signal("pressed"):
			arrow_left.pressed.connect(_on_arrow_left_pressed)
			print("左箭头连接成功")
		elif arrow_left.has_signal("gui_input"):
			arrow_left.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_on_arrow_left_pressed()
			)
			print("左箭头连接成功")
	else:
		print("左箭头未找到")
	
	# 右箭头
	if arrow_right:
		print("右箭头找到，类型：", arrow_right.get_class())
		if arrow_right.has_signal("pressed"):
			arrow_right.pressed.connect(_on_arrow_right_pressed)
			print("右箭头连接成功")
		elif arrow_right.has_signal("gui_input"):
			arrow_right.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_on_arrow_right_pressed()
			)
			print("右箭头连接成功")
	else:
		print("右箭头未找到")
	
	
	# 等待所有节点就绪
	await get_tree().process_frame
	
	# 手动添加分组
	ensure_button_groups()
	
	# 验证分组
	check_groups()


func connect_dialogic_signals():
	print("\n=== 连接 Dialogic 信号 ===")
	
	# 检查 Dialogic 是否可用
	if not Dialogic:
		print("❌ Dialogic 不可用！")
		return
	
	# 使用正确的方式等待 Dialogic 就绪
	if not Dialogic.is_node_ready():
		print("⏳ 等待 Dialogic 就绪...")
		await Dialogic.ready
		print("✅ Dialogic 已就绪")
	else:
		print("✅ Dialogic 已就绪")
	
	# 先断开可能存在的旧连接
	if Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_timeline_ended)
	
	if Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.disconnect(_on_dialogic_signal)
	
	# 重新连接
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	Dialogic.signal_event.connect(_on_dialogic_signal)
	
	# 也连接开始信号用于调试
	if not Dialogic.timeline_started.is_connected(_on_timeline_started):
		Dialogic.timeline_started.connect(_on_timeline_started)
	
	print("✅ Dialogic 信号连接成功")
	print("   timeline_started 已连接: ", Dialogic.timeline_started.is_connected(_on_timeline_started))
	print("   timeline_ended 已连接: ", Dialogic.timeline_ended.is_connected(_on_timeline_ended))
	print("   signal_event 已连接: ", Dialogic.signal_event.is_connected(_on_dialogic_signal))
	
func ensure_button_groups():
	print("\n=== 手动添加按钮分组 ===")
	
	# 左箭头
	if arrow_left:
		if not arrow_left.is_in_group("left_arrow"):
			arrow_left.add_to_group("left_arrow")
			print("✅ 左箭头已加入 left_arrow 分组")
		else:
			print("左箭头已在分组中")
	
	# 右箭头
	if arrow_right:
		if not arrow_right.is_in_group("right_arrow"):
			arrow_right.add_to_group("right_arrow")
			print("✅ 右箭头已加入 right_arrow 分组")
		else:
			print("右箭头已在分组中")
	
	# 检查返回按钮（如果存在）
	var back_btn = find_child("BackButton", true, false)
	if back_btn:
		if not back_btn.is_in_group("back_button"):
			back_btn.add_to_group("back_button")
			print("✅ 返回按钮已加入 back_button 分组")
	
func check_groups():
	print("\n=== 检查按钮分组 ===")
	var left = get_tree().get_nodes_in_group("left_arrow")
	var right = get_tree().get_nodes_in_group("right_arrow")
	
	print("left_arrow 组: ", left.size())
	for btn in left:
		print("  - ", btn.name)
	
	print("right_arrow 组: ", right.size())
	for btn in right:
		print("  - ", btn.name)
		
func _on_timeline_started(timeline_name: String):
	print("📢 对话开始：", timeline_name)
func _on_timeline_ended(timeline_name: String):
	print("📢 对话结束：", timeline_name)
	
	# 检查是否是我们要触发引导的对话
	if timeline_name == "old_nail":  # 你的对话文件名
		# 延迟一点点，让场景稳定
		await get_tree().create_timer(0.3).timeout
		
		# 开始引导
		start_tutorial()
		
func _on_dialogic_signal(argument: String):
	print("📢 收到 Dialogic 自定义信号: ", argument)
	
	if argument == "old_nail_ended":
		print("✅ 匹配到 old_nail_ended 信号，开始引导")
		await get_tree().create_timer(0.3).timeout
		start_tutorial()
		
func start_tutorial():
	print("🎯 开始引导流程")
	
	# 第一步：高亮左箭头
	# 注意：这里不需要 await，因为 highlight_button 内部会处理等待
	tutorial_layer.highlight_button("left_arrow", "点击左箭头切换场景")
# ===================== 顶部UI初始化 =====================
func init_top_ui():
	# 初始化数值（你可以根据游戏逻辑修改）
	if money_label:
		money_label.text = "资金: 1000"
	if reputation_label:
		reputation_label.text = "声誉: 50"
	if cohesion_label:
		cohesion_label.text = "凝聚力: 30"
	if creativity_label:
		creativity_label.text = "创造力: 40"
	if memory_label:
		memory_label.text = "记忆恢复度: 20"
	if action_point_label:
		action_point_label.text = "行动点: 3/3"

# ===================== 箭头点击事件 =====================
func _on_arrow_left_pressed():
	print("左箭头被点击")
	
	# 隐藏引导层
	if tutorial_layer:
		tutorial_layer.hide_all()
	
	# 切换场景
	get_tree().change_scene_to_file("res://project/scenes/lounge/lounge_scene.tscn")

func _on_arrow_right_pressed():
	print("右箭头被点击")
	
	if tutorial_layer and tutorial_layer.visible:
		tutorial_layer.on_button_clicked(arrow_right)
	
	# 切换场景
	get_tree().change_scene_to_file("res://project/scenes/rehearsal/rehearsal_scene.tscn")

# ===================== 对话按钮事件 =====================
func _on_button_pressed():
	print("🔥 main.gd 收到按钮点击通知")
	
# 点击顶部按钮显示康复面板
func _on_rehab_trigger():
	if rehab_panel:
		rehab_panel.show_panel()
		# 禁用箭头/对话按钮，防止误操作
		_set_ui_enabled(false)
# 康复面板关闭后恢复交互
func _on_rehab_panel_closed():
	print("🔔 _on_rehab_panel_closed 被调用了！")
	print("当前按钮状态 - 左箭头: ", arrow_left.disabled if arrow_left else "不存在")
	print("当前按钮状态 - 右箭头: ", arrow_right.disabled if arrow_right else "不存在")
	print("当前按钮状态 - 对话按钮: ", button.disabled if button else "不存在")

	_set_ui_enabled(true)

	# 再次检查设置后的状态
	print("设置后状态 - 左箭头: ", arrow_left.disabled if arrow_left else "不存在")
	print("设置后状态 - 右箭头: ", arrow_right.disabled if arrow_right else "不存在")
	print("设置后状态 - 对话按钮: ", button.disabled if button else "不存在")

func _set_ui_enabled(enabled: bool):
	print("设置UI可用性: ", enabled)

	# 使用 @onready 变量而不是 $
	if arrow_left: 
		arrow_left.disabled = not enabled
		print("左箭头设置 disabled = ", arrow_left.disabled)
	else:
		print("警告: arrow_left 为 null")

	if arrow_right: 
		arrow_right.disabled = not enabled
		print("右箭头设置 disabled = ", arrow_right.disabled)
	else:
		print("警告: arrow_right 为 null")

	if button: 
		button.disabled = not enabled
		print("对话按钮设置 disabled = ", button.disabled)
	else:
		print("警告: button 为 null")
	
