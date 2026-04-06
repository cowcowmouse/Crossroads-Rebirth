extends Node

var current_week = 1
var current_phase = "early"

func _ready():
	process_mode = PROCESS_MODE_ALWAYS

func get_current_week():
	return current_week

func get_current_phase():
	return current_phase

func next_week():
	current_week += 1
	
	# 新一周开始时，先重置本周方向值变化记录
	ResourceManager.reset_weekly_weight_changes()
	
	# 新一周开始时，应用上周待生效的设施升级
	ResourceManager.apply_pending_facility_upgrades()
	
	# 新一周开始时，统一由 ResourceManager 恢复行动点
	ResourceManager.restore_action_points()
	
	# 刷新顶部UI
	ResourceManager.refresh_current_scene_topbar()
	
	# 发射到 EventBus
	EventBus.week_changed.emit(current_week)
	check_phase_transition()
	
	print("=== 第", current_week, "周开始 ===")

func check_phase_transition():
	if current_week >= 13:
		set_phase("late")
	elif current_week >= 4:
		set_phase("mid")
	else:
		set_phase("early")
		
func set_phase(new_phase):
	current_phase = new_phase
	# 发射到 EventBus
	EventBus.phase_changed.emit(current_phase)

# 周结算
func weekly_settlement():
	print("=== 第", current_week, "周结算开始 ===")
	EventBus.weekly_settlement_started.emit(current_week)
	
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
	
	EventBus.weekly_settlement_finished.emit(current_week)
	print("=== 第", current_week, "周结算完成 ===")

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
	
	# 如果 EventBus 里有对应信号，就发出去
	if EventBus.has_signal("game_over_triggered"):
		EventBus.game_over_triggered.emit(game_over_type)
