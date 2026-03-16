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

# ===================== 初始化 =====================
func _ready():
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
	
	# 连接对话按钮
	if button:
		button.pressed.connect(_on_button_pressed)
		print("对话按钮连接成功")
	
	print("====================\n") 
	if rehab_trigger_btn:
		rehab_trigger_btn.pressed.connect(_on_rehab_trigger)

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
	get_tree().change_scene_to_file("res://project/scenes/lounge/lounge_scene.tscn")

func _on_arrow_right_pressed():
	print("右箭头被点击")
	get_tree().change_scene_to_file("res://project/scenes/rehearsal/rehearsal_scene.tscn")

# ===================== 对话按钮事件 =====================
func _on_button_pressed():
	print("🔥 成功！按钮点到了！")
	Dialogic.start("old_nail")  # 仅保留启动对话，暂不处理终止逻辑
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
	
