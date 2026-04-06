extends Node

enum GamePhase {
	BEFORE_WEEK,   # 周前：玩家可操作
	MID_WEEK,      # 周中：触发事件
	AFTER_WEEK     # 周后：结算
}

signal phase_changed(phase: GamePhase)
signal action_points_updated(current: int, max: int)  # 兼容旧UI引用，当前不再作为主逻辑使用

var current_phase: GamePhase = GamePhase.BEFORE_WEEK
var current_week: int = 1

func _ready():
	process_mode = PROCESS_MODE_ALWAYS

func start_new_week():
	current_week += 1
	
	# 新一周开始时，先重置本周方向值变化记录
	ResourceManager.reset_weekly_weight_changes()
	
	# 新一周开始时，应用上周待生效的设施升级
	ResourceManager.apply_pending_facility_upgrades()
	
	# 新一周开始时，统一由 ResourceManager 恢复行动点
	ResourceManager.restore_action_points()
	
	# 为兼容旧UI监听，这里仍发一次信号
	action_points_updated.emit(
		ResourceManager.get_action_points(),
		ResourceManager.get_max_action_points()
	)
	
	# 刷新顶部UI
	ResourceManager.refresh_current_scene_topbar()
	
	# 刷新当前场景里的设施按钮维修状态
	_refresh_all_facility_buttons()
	
	set_phase(GamePhase.BEFORE_WEEK)
	
	print("=== 第", current_week, "周开始 ===")

func force_to_mid_week():
	if current_phase == GamePhase.BEFORE_WEEK:
		set_phase(GamePhase.MID_WEEK)

func set_phase(phase: GamePhase):
	if current_phase != phase:
		current_phase = phase
		_update_clock_state(phase)
		EventBus.week_phase_changed.emit(current_phase)  # 发射每周内阶段信号
		print("每周阶段变化: ", _get_phase_name(current_phase))
		
func _update_clock_state(phase: GamePhase):
	var clock_state = get_node("/root/ClockState")
	if not clock_state:
		return
	
	match phase:
		GamePhase.BEFORE_WEEK:
			clock_state.set_phase(clock_state.ClockPhase.BEFORE_WEEK)
		GamePhase.MID_WEEK:
			clock_state.set_phase(clock_state.ClockPhase.MID_WEEK)
		GamePhase.AFTER_WEEK:
			clock_state.set_phase(clock_state.ClockPhase.AFTER_WEEK)
			
func complete_mid_week():
	if current_phase == GamePhase.MID_WEEK:
		set_phase(GamePhase.AFTER_WEEK)

# 执行周后结算
func _execute_week_settlement():
	# 从 GameManager 获取正确的周数
	var game_manager = get_node("/root/GameManager")
	if game_manager:
		current_week = game_manager.get_current_week()
	
	print("=== 第", current_week, "周结算开始 ===")
	
	# 记录结算前资金（用于计算净变化）
	var money_before = ResourceManager.get_resource_value(Constants.RES_MONEY)
	
	# 1. 扣固定支出
	var expense = ResourceManager.get_weekly_expense()
	var expense_ok = ResourceManager.apply_weekly_expense()
	print("本周固定支出：", expense, "，扣除结果：", expense_ok)
	
	# 2. 加酒吧收入
	var bar_income = ResourceManager.apply_bar_base_income()
	print("本周酒吧基础收入：", bar_income)
	
	# 3. 成员状态变化
	ResourceManager.apply_member_natural_change()
	print("成员自然状态变化已应用")
	
	# 4. 应用休息室周结算恢复效果
	ResourceManager.apply_lounge_weekly_bonus()
	print("休息室周结算加成已应用")
	
	# 5. 更新负债状态，并检查游戏结束
	ResourceManager.update_debt_status_after_settlement()
	_check_game_over_condition()
	
	# 记录结算后资金
	var money_after = ResourceManager.get_resource_value(Constants.RES_MONEY)
	var net_change = money_after - money_before
	
	# 读取休息室效果用于展示
	var lounge_fatigue_recovery = ResourceManager.get_lounge_fatigue_recovery()
	var lounge_cohesion_bonus = ResourceManager.get_lounge_cohesion_bonus()
	
	# 读取本周方向值变化用于展示
	var weekly_weight_changes = ResourceManager.get_weekly_weight_changes()
	var art_change = int(weekly_weight_changes.get(Constants.WEIGHT_ART, 0))
	var business_change = int(weekly_weight_changes.get(Constants.WEIGHT_BUSINESS, 0))
	var human_change = int(weekly_weight_changes.get(Constants.WEIGHT_HUMAN, 0))
	
	# 负债状态
	var is_in_debt = ResourceManager.is_in_debt()
	var debt_weeks = ResourceManager.get_debt_weeks()
	
	# 刷新顶部UI
	ResourceManager.refresh_current_scene_topbar()
	
	# 组织一份结算展示数据
	var settlement_data = {
		"week": current_week,
		"money_before": money_before,
		"expense": expense,
		"bar_income": bar_income,
		"net_change": net_change,
		"money_after": money_after,
		"lounge_fatigue_recovery": lounge_fatigue_recovery,
		"lounge_cohesion_bonus": lounge_cohesion_bonus,
		"is_in_debt": is_in_debt,
		"debt_weeks": debt_weeks,
		"art_change": art_change,
		"business_change": business_change,
		"human_change": human_change
	}
	
	# 显示结算面板
	_show_settlement_panel(settlement_data)
	
	print("=== 第", current_week, "周结算完成 ===")

func complete_week_settlement():
	if current_phase == GamePhase.AFTER_WEEK:
		# 先执行周结算
		_execute_week_settlement()
		
		# 注意：
		# 这里不要立刻 start_new_week()
		# 改为让 SettlementPanel 的确认按钮里再调用 start_new_week()

# 显示周结算面板
func _show_settlement_panel(settlement_data: Dictionary):
	var current_scene = get_tree().current_scene
	if not current_scene:
		return
	
	var panel = current_scene.get_node_or_null("UILayer/SettlementPanel")
	if panel and panel.has_method("show_settlement"):
		panel.show_settlement(settlement_data)
	else:
		print("未找到 SettlementPanel，或缺少 show_settlement(data) 方法")

# 检查游戏结束
# 当前只先接一个接口：
# - 若负债持续 1 周，则触发失败结局接口
func _check_game_over_condition():
	if ResourceManager.should_trigger_debt_game_over():
		print("触发失败结局：资金负债持续 1 周")
		_trigger_game_over("debt_one_week")

# 失败结局接口（目前只留接口，后续再接具体结局表现）
func _trigger_game_over(game_over_type: String):
	print("游戏失败接口已调用，类型：", game_over_type)
	
	if EventBus.has_signal("game_over_triggered"):
		EventBus.game_over_triggered.emit(game_over_type)

func get_current_phase() -> GamePhase:
	return current_phase

func get_current_week() -> int:
	return current_week

func _get_phase_name(phase: GamePhase) -> String:
	match phase:
		GamePhase.BEFORE_WEEK:
			return "周前"
		GamePhase.MID_WEEK:
			return "周中"
		GamePhase.AFTER_WEEK:
			return "周后"
	return "未知"

func _refresh_all_facility_buttons():
	var current_scene = get_tree().current_scene
	if not current_scene:
		return

	var button_paths = [
		"UILayer/StageButton",
		"UILayer/BarButton",
		"UILayer/LoungeButton",
		"UILayer/RehearsalButton"
	]

	for path in button_paths:
		var facility_button = current_scene.get_node_or_null(path)
		if facility_button and facility_button.has_method("refresh_repair_state"):
			facility_button.refresh_repair_state()

# 设置当前周数（用于跳转后同步）
func set_current_week(week: int):
	current_week = week
	print("WeekCycleManager 周数已同步: ", current_week)
