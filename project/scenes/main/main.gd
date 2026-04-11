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

@onready var action_skip_panel = $UILayer/TopBar/ActionSkipPanel
@onready var clock_icon = $UILayer/TopBar/ClockIcon
@onready var skip_button = $UILayer/SkipButton

# 管理器引用
@onready var week_cycle = get_node("/root/WeekCycleManager")
@onready var skip_panel_manager = get_node("/root/SkipPanelManager")

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
	
	# 初始化周循环
	_init_week_cycle()
	
	# 初始化跳过面板
	_init_skip_panel()
	
	# 初始化时钟显示
	_init_clock_display()
	
	# 连接信号
	_connect_week_cycle_signals()
	
	# 连接跳过按钮
	if skip_button:
		skip_button.pressed.connect(_on_skip_button_pressed)
	
	EventBus.minigame_finished.connect(_on_minigame_finished)
	
	# 创建调试面板
	_create_debug_panel()

	# 读取记忆事件配置
	_load_memory_event_data()
	
	# 创建记忆阶段事件面板
	_create_memory_event_panel()
	
	# 注册调试快捷键
	_register_debug_input()

func _register_debug_input():
	# 确保调试动作存在
	if not InputMap.has_action("toggle_debug"):
		InputMap.add_action("toggle_debug")
	
	# 添加 F12 键位（避免重复添加）
	var key_event = InputEventKey.new()
	key_event.keycode = KEY_F12
	
	# 检查是否已经添加过这个事件
	var existing_events = InputMap.action_get_events("toggle_debug")
	var already_exists = false
	for event in existing_events:
		if event is InputEventKey and event.keycode == KEY_F12:
			already_exists = true
			break
	
	if not already_exists:
		InputMap.action_add_event("toggle_debug", key_event)

func _input(event):
	if event.is_action_pressed("toggle_debug"):
		_toggle_debug_panel()

func _init_week_cycle():
	if not week_cycle:
		print("❌ WeekCycleManager 未找到")
		return
	
	# 不要强制设置阶段，保持 WeekCycleManager 当前阶段
	# week_cycle.set_phase(week_cycle.GamePhase.BEFORE_WEEK)  # 删除这行
	
	# 顶部UI统一从 ResourceManager 读取，避免与 week_cycle 显示冲突
	ResourceManager.refresh_current_scene_topbar()
		  
	# 如果当前资源管理器里的行动点已经耗尽，直接显示跳过面板
	if ResourceManager.get_action_points() == 0:
		if skip_panel_manager:
			skip_panel_manager.show_skip_panel(true)
	
	# 根据当前阶段更新UI
	match week_cycle.get_current_phase():
		0:
			print("当前阶段: 周前")
		1:
			print("当前阶段: 周中")
			_set_operation_ui_enabled(false)
		2:
			print("当前阶段: 周后")
			_set_operation_ui_enabled(false)
			
func _init_skip_panel():
	if action_skip_panel and skip_panel_manager:
		skip_panel_manager.register_panel(action_skip_panel)
		skip_panel_manager.skip_to_next_phase.connect(_on_skip_to_next_phase)

func _init_clock_display():
	# 时钟显示已在 clock_display.gd 中处理
	pass

func _connect_week_cycle_signals():
	if week_cycle:
		week_cycle.action_points_updated.connect(_on_action_points_updated)
	
	# 连接每周阶段变化信号（用于时钟）
	EventBus.week_phase_changed.connect(_on_week_phase_changed)

func _on_week_phase_changed(phase: int):
	# phase: 0=周前, 1=周中, 2=周后
	match phase:
		0:
			print("进入周前阶段 - 玩家可以操作")
			if week_cycle:
				week_cycle.set_phase(week_cycle.GamePhase.BEFORE_WEEK)
			_set_operation_ui_enabled(true)
			if skip_panel_manager:
				skip_panel_manager.hide_skip_panel()
		1:
			print("进入周中阶段 - 触发事件")
			if week_cycle:
				week_cycle.set_phase(week_cycle.GamePhase.MID_WEEK)
			_set_operation_ui_enabled(false)
			_trigger_mid_week_event()
		2:
			print("进入周后阶段 - 等待用户点击跳过按钮结算")
			if week_cycle:
				week_cycle.set_phase(week_cycle.GamePhase.AFTER_WEEK)
			_set_operation_ui_enabled(false)
			_enter_minigame()
			# 移除自动结算，只显示提示
			# 让用户点击跳过按钮来触发结算

func _on_action_points_updated(current: int, max: int):
	_update_action_point_display(current, max)
	
	# 如果行动点为0，显示强制跳过面板
	if current == 0:
		if skip_panel_manager:
			skip_panel_manager.show_skip_panel(true)

func _update_action_point_display(current: int, max: int):
	# 行动点显示统一同步到 ResourceManager，再由顶部UI统一刷新
	ResourceManager.action_points = current
	ResourceManager.refresh_current_scene_topbar()
	
	# 行动点耗尽时改变颜色
	if action_point_label:
		if current == 0:
			action_point_label.modulate = Color.RED
		else:
			action_point_label.modulate = Color.WHITE

func _set_operation_ui_enabled(enabled: bool):
	# 禁用/启用设施升级按钮
	var facility_panel = $UILayer/FacilityPanel
	if facility_panel and facility_panel.upgrade_button:
		facility_panel.upgrade_button.disabled = not enabled
	
	# 禁用/启用康复按钮
	if rehab_trigger_btn:
		rehab_trigger_btn.disabled = not enabled
	
	# 禁用/启用成员对话按钮（如果有）
	# 可以根据需要添加更多

func _trigger_mid_week_event():
	print("触发周中事件...")
	
	# 测试：直接加载 test_event.tscn 场景
	get_tree().change_scene_to_file("res://project/scenes/event/EventDialog.tscn")

func _safe_wait(seconds: float):
	if is_inside_tree() and get_tree():
		await get_tree().create_timer(seconds).timeout
	else:
		await Engine.get_main_loop().create_timer(seconds).timeout

func _check_game_over():
	var money = ResourceManager.get_resource_value(Constants.RES_MONEY)
	var cohesion = ResourceManager.get_resource_value(Constants.RES_COHESION)
	
	if money <= 0:
		print("游戏结束：资金耗尽")
		EventBus.game_over.emit("bankrupt")
	elif cohesion <= 0:
		print("游戏结束：成员解散")
		EventBus.game_over.emit("band_broken")

func _on_skip_to_next_phase():
	# 手动跳过当前阶段
	if week_cycle.get_current_phase() == week_cycle.GamePhase.BEFORE_WEEK:
		week_cycle.force_to_mid_week()
	elif week_cycle.get_current_phase() == week_cycle.GamePhase.MID_WEEK:
		week_cycle.complete_mid_week()
	elif week_cycle.get_current_phase() == week_cycle.GamePhase.AFTER_WEEK:
		week_cycle.complete_week_settlement()

# 手动进入周中（可选：右下角按钮）
func _on_skip_to_mid_week_pressed():
	if week_cycle and week_cycle.get_current_phase() == week_cycle.GamePhase.BEFORE_WEEK:
		week_cycle.force_to_mid_week()
		
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
	ResourceManager.refresh_current_scene_topbar()
	if money_label:
		money_label.text = "资金: %d" % ResourceManager.get_resource_value(Constants.RES_MONEY)

	if reputation_label:
		reputation_label.text = "声誉: %d" % ResourceManager.get_resource_value(Constants.RES_REPUTATION)

	if cohesion_label:
		cohesion_label.text = "凝聚力: %d" % ResourceManager.get_resource_value(Constants.RES_COHESION)

	if creativity_label:
		creativity_label.text = "创造力: %d" % ResourceManager.get_resource_value(Constants.RES_CREATIVITY)

	if memory_label:
		memory_label.text = "记忆恢复度: %d" % ResourceManager.get_resource_value(Constants.RES_MEMORY)

# ===================== 箭头点击事件 =====================
func _on_arrow_left_pressed():
	print("左箭头被点击")

	$UILayer/FacilityPanel.close_panel()

	if tutorial_layer:
		tutorial_layer.hide_all()

	get_tree().change_scene_to_file("res://project/scenes/lounge/lounge_scene.tscn")

func _on_arrow_right_pressed():
	print("右箭头被点击")

	$UILayer/FacilityPanel.close_panel()

	if tutorial_layer and tutorial_layer.visible:
		tutorial_layer.on_button_clicked(arrow_right)

	get_tree().change_scene_to_file("res://project/scenes/rehearsal/rehearsal_scene.tscn")

# ===================== 对话按钮事件 =====================
func _on_button_pressed():
	print("🔥 main.gd 收到按钮点击通知")
	
# 点击顶部按钮显示康复面板
func _on_rehab_trigger():
	if not rehab_panel:
		return

	if rehab_panel.visible:
		rehab_panel.hide_panel()
		_set_ui_enabled(true)
	else:
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

	# 这里只恢复 UI，不再扣行动点
	# 行动点已经在 Rehabpanel._on_start_rehab() 中扣除
	ResourceManager.refresh_current_scene_topbar()

	if ResourceManager.get_action_points() == 0:
		if skip_panel_manager:
			skip_panel_manager.show_skip_panel(true)

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
	
# ===================== 设施升级后消耗行动点 =====================
# 在 FacilityPanel 升级成功后，需要通知主场景消耗行动点
func on_facility_upgraded():
	# 设施升级的行动点已经在 FacilityManager / ResourceManager 中扣除了
	# 这里不要再重复扣减，只负责刷新显示与处理跳过提示
	ResourceManager.refresh_current_scene_topbar()
	
	if ResourceManager.get_action_points() == 0:
		if skip_panel_manager:
			skip_panel_manager.show_skip_panel(true)

func _on_skip_button_pressed():
	print("跳过按钮被点击")
	if week_cycle:
		match week_cycle.get_current_phase():
			week_cycle.GamePhase.BEFORE_WEEK:
				print("强制从周前跳到周中")
				week_cycle.force_to_mid_week()
			week_cycle.GamePhase.MID_WEEK:
				print("强制从周中跳到周后")
				week_cycle.complete_mid_week()
			week_cycle.GamePhase.AFTER_WEEK:
				print("执行周末结算")
				GameManager.weekly_settlement()

# ===================== 小游戏相关 =====================

func _enter_minigame():
	"""进入小游戏场景"""
	print("进入小游戏场景...")
	
	# 切换到小游戏场景
	get_tree().change_scene_to_file("res://project/scenes/minigame/game_level.tscn")

func _on_minigame_finished(score: int, rank: String):
	"""小游戏结束回调"""
	print("小游戏结束，得分: ", score, " 评级: ", rank)
	
	# 根据评级计算奖励
	var reward = _calculate_minigame_reward(rank)
	
	# 应用奖励
	if reward.money != 0:
		ResourceManager.add_money(reward.money)
		print("获得资金: ", reward.money)
	if reward.cohesion != 0:
		ResourceManager.add_cohesion(reward.cohesion)
		print("获得凝聚力: ", reward.cohesion)
	if reward.creativity != 0:
		ResourceManager.add_creativity(reward.creativity)
		print("获得创造力: ", reward.creativity)
	
	# 切换回主场景
	get_tree().change_scene_to_file("res://project/scenes/main/main.tscn")
	
	# 等待场景切换完成
	await get_tree().process_frame
	
	# 执行周末结算
	GameManager.weekly_settlement()

func _calculate_minigame_reward(rank: String) -> Dictionary:
	"""根据评级计算奖励"""
	var reward = {
		"money": 0,
		"cohesion": 0,
		"creativity": 0
	}
	
	match rank:
		"S":
			reward.money = 2000
			reward.cohesion = 15
			reward.creativity = 10
			print("S级评价！完美通关！")
		"A":
			reward.money = 1500
			reward.cohesion = 10
			reward.creativity = 5
			print("A级评价！表现优秀！")
		"B":
			reward.money = 1000
			reward.cohesion = 5
			print("B级评价！表现良好！")
		"C":
			reward.money = 500
			reward.cohesion = 2
			print("C级评价！继续努力！")
		"D":
			reward.money = 0
			reward.cohesion = -3
			print("D级评价！表现不佳...")
	
	return reward

# ===================== 调试面板 =====================

var debug_panel: Panel = null
var week_input: LineEdit = null
var jump_button: Button = null

# ===================== 记忆阶段事件系统 =====================

var memory_event_overlay: Control = null
var memory_event_backdrop: ColorRect = null
var memory_event_panel: Panel = null
var memory_event_image_box: ColorRect = null
var memory_event_image_label: Label = null
var memory_event_title_label: Label = null
var memory_event_text_label: Label = null
var memory_event_choice_container: VBoxContainer = null

var current_memory_event_id: String = ""
var current_memory_event_selected_option: Dictionary = {}

# 记忆事件数据改为从 JSON 文件读取
var memory_event_data: Dictionary = {}

func _create_debug_panel():
	# 创建调试面板
	debug_panel = Panel.new()
	debug_panel.size = Vector2(220, 120)
	debug_panel.position = Vector2(10, 200)
	
	# 设置面板样式 - 浅灰色半透明
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.85, 0.85, 0.85, 0.9)  # 浅灰色，透明度0.9
	panel_style.set_corner_radius_all(8)  # 圆角
	debug_panel.add_theme_stylebox_override("panel", panel_style)
	
	# 创建输入框
	week_input = LineEdit.new()
	week_input.size = Vector2(80, 30)
	week_input.position = Vector2(10, 10)
	week_input.placeholder_text = "周数(1-18)"
	week_input.add_theme_color_override("font_color", Color(1, 1, 1))  # 白色文字
	week_input.add_theme_color_override("placeholder_color", Color(0.3, 0.3, 0.3))
	
	# 创建跳转按钮
	jump_button = Button.new()
	jump_button.size = Vector2(80, 30)
	jump_button.position = Vector2(100, 10)
	jump_button.text = "跳转"
	jump_button.add_theme_color_override("font_color", Color(1, 1, 1))
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.3, 0.5, 0.8)
	button_style.set_corner_radius_all(4)
	jump_button.add_theme_stylebox_override("normal", button_style)
	jump_button.pressed.connect(_on_debug_jump_pressed)
	
	# 添加关闭按钮
	var close_btn = Button.new()
	close_btn.size = Vector2(30, 30)
	close_btn.position = Vector2(180, 10)
	close_btn.text = "X"
	close_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.8, 0.3, 0.3)
	close_style.set_corner_radius_all(4)
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.pressed.connect(_toggle_debug_panel)
	
	# 添加提示标签
	var tip_label = Label.new()
	tip_label.text = "按 F12 隐藏/显示"
	tip_label.position = Vector2(10, 50)
	tip_label.size = Vector2(200, 20)
	tip_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))  # 深灰色文字
	
	debug_panel.add_child(week_input)
	debug_panel.add_child(jump_button)
	debug_panel.add_child(close_btn)
	debug_panel.add_child(tip_label)
	
	# 默认打开
	debug_panel.visible = true
	add_child(debug_panel)

func _toggle_debug_panel():
	if debug_panel:
		debug_panel.visible = !debug_panel.visible

func _on_debug_jump_pressed():
	if not week_input:
		return
	
	var input_text = week_input.text.strip_edges()
	if input_text.is_empty():
		print("输入为空")
		return
	
	var target_week = input_text.to_int()
	if target_week < 1:
		target_week = 1
	if target_week > 18:
		target_week = 18
	
	print("调试：准备跳转到第", target_week, "周")
	
	# 调用 GameManager 的跳转方法
	if GameManager and GameManager.has_method("jump_to_week"):
		var success = GameManager.jump_to_week(target_week)
		if success:
			print("跳转成功")
			# 刷新当前场景的 UI
			refresh_ui()
			
			# 可选：显示提示
			_show_jump_notification(target_week)
		else:
			print("跳转失败")
	else:
		print("GameManager 不存在或没有 jump_to_week 方法")

func _show_jump_notification(week: int):
	# 显示一个短暂的提示（简化版）
	var notification = Label.new()
	notification.text = "已跳转到第 %d 周" % week
	notification.position = Vector2(get_viewport().size.x / 2 - 100, 50)
	notification.size = Vector2(200, 30)
	notification.add_theme_color_override("font_color", Color(1, 1, 0))
	notification.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	
	add_child(notification)
	
	# 2秒后自动删除
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(notification):
		notification.queue_free()

func _refresh_resource_display():
	if money_label:
		money_label.text = str(ResourceManager.get_resource_value(Constants.RES_MONEY))
	if reputation_label:
		reputation_label.text = str(ResourceManager.get_resource_value(Constants.RES_REPUTATION))
	if cohesion_label:
		cohesion_label.text = str(ResourceManager.get_resource_value(Constants.RES_COHESION))
	if creativity_label:
		creativity_label.text = str(ResourceManager.get_resource_value(Constants.RES_CREATIVITY))

# 刷新整个 UI（供 GameManager 调用）
func refresh_ui():
	print("刷新主场景 UI")
	
	# 刷新资源显示
	_refresh_resource_display()
	
	# 刷新行动点显示
	var current_points = ResourceManager.get_action_points() if ResourceManager else 3
	var max_points = ResourceManager.get_max_action_points() if ResourceManager else 3
	_update_action_point_display(current_points, max_points)
	
	# 刷新设施面板（如果打开）
	var facility_panel = $UILayer/FacilityPanel
	if facility_panel and facility_panel.visible:
		facility_panel._refresh_panel()
	
	# 刷新阶段显示
	if week_cycle:
		match week_cycle.get_current_phase():
			0:
				print("当前阶段: 周前")
			1:
				print("当前阶段: 周中")
			2:
				print("当前阶段: 周后")
# ===================== 记忆事件数据读取 =====================

func _load_memory_event_data():
	var path = "res://project/data/story/memory_events.json"

	if not FileAccess.file_exists(path):
		push_error("找不到记忆事件配置文件: " + path)
		memory_event_data = {}
		return

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("无法打开记忆事件配置文件: " + path)
		memory_event_data = {}
		return

	var text = file.get_as_text()

	var json = JSON.new()
	var err = json.parse(text)

	if err != OK:
		push_error("memory_events.json 解析失败，错误码: %d" % err)
		memory_event_data = {}
		return

	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("memory_events.json 顶层不是 Dictionary")
		memory_event_data = {}
		return

	memory_event_data = json.data
	print("✅ 记忆事件数据加载完成: ", memory_event_data.keys())
# ===================== 记忆阶段事件系统 =====================

# 创建记忆阶段事件面板（运行时创建，当前先用占位图 + 文本演出）
func _create_memory_event_panel():
	var ui_layer = get_node_or_null("UILayer")
	if not ui_layer:
		print("❌ 未找到 UILayer，无法创建记忆事件面板")
		return

	# 避免重复创建
	if memory_event_overlay and is_instance_valid(memory_event_overlay):
		return

	# 全屏遮罩
	memory_event_overlay = Control.new()
	memory_event_overlay.name = "MemoryEventOverlay"
	memory_event_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	memory_event_overlay.visible = false
	ui_layer.add_child(memory_event_overlay)

	# 半透明背景
	memory_event_backdrop = ColorRect.new()
	memory_event_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	memory_event_backdrop.color = Color(0, 0, 0, 0.72)
	memory_event_overlay.add_child(memory_event_backdrop)

	# 中央面板
	memory_event_panel = Panel.new()
	memory_event_panel.size = Vector2(900, 620)
	memory_event_panel.position = Vector2(510, 180)

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.10, 0.08, 0.06, 0.95)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color(0.85, 0.68, 0.32, 1.0)
	panel_style.set_corner_radius_all(16)
	memory_event_panel.add_theme_stylebox_override("panel", panel_style)
	memory_event_overlay.add_child(memory_event_panel)

	# 标题
	memory_event_title_label = Label.new()
	memory_event_title_label.position = Vector2(40, 25)
	memory_event_title_label.size = Vector2(820, 40)
	memory_event_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	memory_event_title_label.add_theme_font_size_override("font_size", 30)
	memory_event_title_label.add_theme_color_override("font_color", Color(0.95, 0.84, 0.52))
	memory_event_panel.add_child(memory_event_title_label)

	# 占位图区域
	memory_event_image_box = ColorRect.new()
	memory_event_image_box.position = Vector2(110, 85)
	memory_event_image_box.size = Vector2(680, 180)
	memory_event_image_box.color = Color(0.24, 0.18, 0.14, 1.0)
	memory_event_panel.add_child(memory_event_image_box)

	memory_event_image_label = Label.new()
	memory_event_image_label.position = Vector2(20, 20)
	memory_event_image_label.size = Vector2(640, 140)
	memory_event_image_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	memory_event_image_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	memory_event_image_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	memory_event_image_label.add_theme_font_size_override("font_size", 22)
	memory_event_image_label.add_theme_color_override("font_color", Color(0.90, 0.90, 0.90))
	memory_event_image_box.add_child(memory_event_image_label)

	# 正文文本
	memory_event_text_label = Label.new()
	memory_event_text_label.position = Vector2(85, 290)
	memory_event_text_label.size = Vector2(730, 120)
	memory_event_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	memory_event_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	memory_event_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	memory_event_text_label.add_theme_font_size_override("font_size", 24)
	memory_event_text_label.add_theme_color_override("font_color", Color(0.96, 0.92, 0.84))
	memory_event_panel.add_child(memory_event_text_label)

	# 选项按钮容器
	memory_event_choice_container = VBoxContainer.new()
	memory_event_choice_container.position = Vector2(180, 440)
	memory_event_choice_container.size = Vector2(540, 135)
	memory_event_choice_container.alignment = BoxContainer.ALIGNMENT_CENTER
	memory_event_choice_container.add_theme_constant_override("separation", 12)
	memory_event_panel.add_child(memory_event_choice_container)

	print("✅ 记忆阶段事件面板创建完成")

# 触发记忆阶段事件
# 由 Rehabpanel.gd 中的“触发关键事件”按钮调用
func start_memory_stage_event(event_id: String):
	if not memory_event_data.has(event_id):
		print("❌ 未找到记忆阶段事件：", event_id)
		return

	if not memory_event_overlay or not is_instance_valid(memory_event_overlay):
		_create_memory_event_panel()

	current_memory_event_id = event_id
	current_memory_event_selected_option = {}

	# 确保康复面板关闭
	if rehab_panel and rehab_panel.visible:
		rehab_panel.hide_panel()

	# 锁定普通交互
	_set_ui_enabled(false)

	# 显示当前事件
	_show_memory_stage_event(event_id)

# 显示记忆阶段事件内容
func _show_memory_stage_event(event_id: String):
	if not memory_event_data.has(event_id):
		return

	var event_data = memory_event_data[event_id]

	if memory_event_overlay:
		memory_event_overlay.visible = true

	if memory_event_title_label:
		memory_event_title_label.text = str(event_data.get("title", "关键事件"))

	if memory_event_image_label:
		memory_event_image_label.text = str(event_data.get("image_hint", "临时占位图"))

	if memory_event_text_label:
		memory_event_text_label.text = str(event_data.get("intro_text", ""))

	_clear_memory_event_choices()

	var options = event_data.get("options", [])
	for option in options:
		var choice_button = _create_memory_choice_button(option)
		memory_event_choice_container.add_child(choice_button)

	print("✅ 已显示记忆阶段事件：", event_id)

# 创建单个选项按钮
func _create_memory_choice_button(option: Dictionary) -> Button:
	var choice_button = Button.new()
	choice_button.custom_minimum_size = Vector2(520, 36)
	choice_button.text = str(option.get("text", "继续"))

	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.35, 0.26, 0.14, 0.95)
	button_style.border_width_left = 2
	button_style.border_width_top = 2
	button_style.border_width_right = 2
	button_style.border_width_bottom = 2
	button_style.border_color = Color(0.92, 0.75, 0.38, 1.0)
	button_style.set_corner_radius_all(8)
	choice_button.add_theme_stylebox_override("normal", button_style)
	choice_button.add_theme_stylebox_override("hover", button_style)
	choice_button.add_theme_stylebox_override("pressed", button_style)
	choice_button.add_theme_font_size_override("font_size", 20)
	choice_button.add_theme_color_override("font_color", Color(1, 1, 1))

	choice_button.pressed.connect(_on_memory_event_choice_selected.bind(option))
	return choice_button

# 清空当前事件选项
func _clear_memory_event_choices():
	if not memory_event_choice_container:
		return

	for child in memory_event_choice_container.get_children():
		child.queue_free()

# 玩家选中一个剧情选项
func _on_memory_event_choice_selected(option: Dictionary):
	current_memory_event_selected_option = option

	if memory_event_text_label:
		memory_event_text_label.text = str(option.get("result_text", "记忆的碎片重新浮现。"))

	_clear_memory_event_choices()

	var continue_button = Button.new()
	continue_button.custom_minimum_size = Vector2(240, 40)
	continue_button.text = "继续"

	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.48, 0.34, 0.16, 0.98)
	button_style.border_width_left = 2
	button_style.border_width_top = 2
	button_style.border_width_right = 2
	button_style.border_width_bottom = 2
	button_style.border_color = Color(0.95, 0.80, 0.42, 1.0)
	button_style.set_corner_radius_all(8)
	continue_button.add_theme_stylebox_override("normal", button_style)
	continue_button.add_theme_stylebox_override("hover", button_style)
	continue_button.add_theme_stylebox_override("pressed", button_style)
	continue_button.add_theme_font_size_override("font_size", 22)
	continue_button.add_theme_color_override("font_color", Color(1, 1, 1))

	continue_button.pressed.connect(_finish_memory_stage_event)
	memory_event_choice_container.add_child(continue_button)

# 应用当前选项带来的方向值 / 记忆值变化
func _apply_memory_stage_choice(option: Dictionary):
	if option.is_empty():
		return

	var weights = option.get("weights", {})
	if weights is Dictionary:
		if weights.has("art"):
			ResourceManager.modify_ai_weight(Constants.WEIGHT_ART, int(weights["art"]))
		if weights.has("human"):
			ResourceManager.modify_ai_weight(Constants.WEIGHT_HUMAN, int(weights["human"]))
		if weights.has("business"):
			ResourceManager.modify_ai_weight(Constants.WEIGHT_BUSINESS, int(weights["business"]))

	var memory_delta = int(option.get("memory_delta", 0))
	if memory_delta != 0:
		ResourceManager.add_memory(memory_delta)

# 完成当前记忆阶段事件
# 作用：
# 1. 正式调用 ResourceManager 完成阶段提升
# 2. 结算当前选项带来的方向值 / 记忆值变化
# 3. 关闭剧情面板，回到康复面板
func _finish_memory_stage_event():
	if current_memory_event_id == "":
		return

	# 先完成阶段提升
	if ResourceManager and ResourceManager.has_method("complete_memory_stage_event"):
		var complete_result = ResourceManager.complete_memory_stage_event()
		if not complete_result.get("success", false):
			print("❌ 记忆阶段事件完成失败：", complete_result.get("reason", "未知错误"))
			if memory_event_text_label:
				memory_event_text_label.text = "阶段事件完成失败：%s" % str(complete_result.get("reason", "未知错误"))
			return

	# 再应用选项收益
	_apply_memory_stage_choice(current_memory_event_selected_option)

	# 关闭事件面板
	if memory_event_overlay:
		memory_event_overlay.visible = false

	print("✅ 记忆阶段事件完成：", current_memory_event_id)

	current_memory_event_id = ""
	current_memory_event_selected_option = {}

	# 刷新顶部资源显示
	ResourceManager.refresh_current_scene_topbar()

	# 事件结束后重新打开康复面板，方便继续查看当前恢复阶段
	if rehab_panel and rehab_panel.has_method("show_panel"):
		rehab_panel.show_panel()
		_set_ui_enabled(false)
	else:
		_set_ui_enabled(true)
