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
		week_cycle.phase_changed.connect(_on_game_phase_changed)
		# 保留行动点信号连接，但收到信号后统一同步到 ResourceManager
		week_cycle.action_points_updated.connect(_on_action_points_updated)

func _on_game_phase_changed(phase):
	match phase:
		0:  # BEFORE_WEEK
			print("进入周前阶段 - 玩家可以操作")
			_set_operation_ui_enabled(true)
			if skip_panel_manager:
				skip_panel_manager.hide_skip_panel()
		1:  # MID_WEEK
			print("进入周中阶段 - 触发事件")
			_set_operation_ui_enabled(false)
			_trigger_mid_week_event()
		2:  # AFTER_WEEK
			print("进入周后阶段 - 等待用户点击跳过按钮结算")
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
	get_tree().change_scene_to_file("res://project/Tests/test_event.tscn")

func _execute_weekly_settlement():
	print("执行周结算...")
	
	# 1. 扣除固定支出
	var expense = ResourceManager.get_weekly_expense()
	ResourceManager.add_money(-expense)
	print("扣除每周支出: ", expense)
	
	# 2. 增加酒吧收入（暂用固定值，等设施系统完善后替换）
	var bar_income = 1500
	ResourceManager.add_money(bar_income)
	print("酒吧收入: ", bar_income)
	
	# 3. 成员状态自然变化
	ResourceManager.apply_member_natural_change()
	
	# 4. 检查游戏结束条件
	_check_game_over()
	
	# 5. 结算完成，进入下一周
	await get_tree().create_timer(3.0).timeout
	week_cycle.complete_week_settlement()

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
	if rehab_panel:
		rehab_panel.show_panel()
		# 禁用箭头/对话按钮，防止误操作
		_set_ui_enabled(false)
# 康复面板关闭后恢复交互
# 康复面板关闭后恢复交互
func _on_rehab_panel_closed():
	print("🔔 _on_rehab_panel_closed 被调用了！")
	print("当前按钮状态 - 左箭头: ", arrow_left.disabled if arrow_left else "不存在")
	print("当前按钮状态 - 右箭头: ", arrow_right.disabled if arrow_right else "不存在")
	print("当前按钮状态 - 对话按钮: ", button.disabled if button else "不存在")

	_set_ui_enabled(true)
	
	# 消耗行动点
	# 优先走 week_cycle，保持周循环逻辑；其信号会同步到 ResourceManager
	if week_cycle:
		week_cycle.consume_action_point()
	else:
		ResourceManager.consume_action_point(1)
		
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
		# 强制进入下一阶段
		match week_cycle.get_current_phase():
			week_cycle.GamePhase.BEFORE_WEEK:
				print("强制从周前跳到周中")
				week_cycle.force_to_mid_week()
			week_cycle.GamePhase.MID_WEEK:
				print("强制从周中跳到周后")
				week_cycle.complete_mid_week()
			week_cycle.GamePhase.AFTER_WEEK:
				print("强制完成周结算")
				_execute_weekly_settlement()  # 直接调用结算函数

# ===================== 周中事件触发 =====================
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
	get_tree().change_scene_to_file("res://project/scenes/main/Main.tscn")
	
	# 等待场景切换完成
	await get_tree().process_frame
	
	# 执行周末结算
	_execute_weekly_settlement()

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
