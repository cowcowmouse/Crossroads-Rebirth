extends Node

var current_week = 1
var current_phase = "early"  # early / mid / late

# 阶段配置
const PHASE_CONFIG = {
	"early": {"min": 1, "max": 3, "name": "前期"},
	"mid": {"min": 4, "max": 12, "name": "中期"},
	"late": {"min": 13, "max": 18, "name": "后期"}
}

# 游戏是否已结束
var is_game_ended: bool = false

func _ready():
	process_mode = PROCESS_MODE_ALWAYS

func get_current_week():
	return current_week

func get_current_phase():
	return current_phase

# 获取当前阶段的名称
func get_current_phase_name() -> String:
	return PHASE_CONFIG[current_phase]["name"]

# 获取阶段进度（0-1）
func get_phase_progress() -> float:
	var config = PHASE_CONFIG[current_phase]
	var week_in_phase = current_week - config["min"]
	var phase_length = config["max"] - config["min"]
	if phase_length <= 0:
		return 1.0
	return float(week_in_phase) / float(phase_length)

# 获取游戏总进度（0-1）
func get_game_progress() -> float:
	return float(current_week) / 18.0

func next_week():
	if is_game_ended:
		print("游戏已结束，无法进入下一周")
		return
	
	# 检查是否已经是第18周
	if current_week >= 18:
		print("已达最终周，触发游戏结局")
		_end_game()
		return
	
	current_week += 1
	
	# 新一周开始时，先重置本周方向值变化记录
	ResourceManager.reset_weekly_weight_changes()
	
	# 新一周开始时，应用上周待生效的设施升级
	ResourceManager.apply_pending_facility_upgrades()
	
	# 新一周开始时，统一由 ResourceManager 恢复行动点
	ResourceManager.restore_action_points()
	
	# 刷新顶部UI
	ResourceManager.refresh_current_scene_topbar()
	
	EventBus.phase_changed.emit("0")
	# 检查阶段切换
	check_phase_transition()
	
	EventBus.week_phase_changed.emit(0)
	
	var clock_state = get_node("/root/ClockState")
	if clock_state:
		clock_state.set_phase(clock_state.ClockPhase.BEFORE_WEEK)
	print("=== 第", current_week, "周开始 ===")

func check_phase_transition():
	var old_phase = current_phase
	
	if current_week >= 13:
		current_phase = "late"
	elif current_week >= 4:
		current_phase = "mid"
	else:
		current_phase = "early"
	
	if old_phase != current_phase:
		EventBus.game_phase_changed.emit(current_phase)
		print("阶段切换: ", old_phase, " -> ", current_phase)

func set_phase(new_phase):
	current_phase = new_phase
	EventBus.phase_changed.emit(current_phase)

# 跳转到指定周数（调试/作弊功能）
func jump_to_week(target_week: int):
	if is_game_ended:
		print("游戏已结束，先重置游戏")
		reset_game()
	
	target_week = clamp(target_week, 1, 18)
	
	if target_week == current_week:
		print("已经是第", target_week, "周")
		return true
	
	print("跳转周数: ", current_week, " -> ", target_week)
	
	current_week = target_week
	
	# 同步 WeekCycleManager 的周数
	var week_cycle = get_node("/root/WeekCycleManager")
	if week_cycle:
		week_cycle.current_week = current_week
		print("同步 WeekCycleManager 周数: ", week_cycle.current_week)
	
	# 重新检查阶段
	check_phase_transition()
	
	# 刷新资源
	_refresh_after_jump()
	
	# 发射周数变化信号
	EventBus.week_changed.emit(current_week)
	
	# 刷新 UI
	_refresh_all_ui()
	
	# 发射每周阶段变化信号，让 main.gd 重置阶段为周前
	EventBus.week_phase_changed.emit(0)  # 0 = BEFORE_WEEK
	
	print("=== 已跳转到第", current_week, "周，阶段: ", current_phase, " ===")
	return true

# 刷新所有 UI
func _refresh_all_ui():
	print("刷新所有 UI")
	
	# 同步 WeekCycleManager 的周数
	var week_cycle = get_node("/root/WeekCycleManager")
	if week_cycle:
		week_cycle.current_week = current_week
		print("刷新时同步 WeekCycleManager 周数: ", week_cycle.current_week)
		
	# 刷新顶部资源显示
	ResourceManager.refresh_current_scene_topbar()
	
	# 恢复行动点
	ResourceManager.restore_action_points()
	
	# 重置本周权重变化记录
	ResourceManager.reset_weekly_weight_changes()
	
	# 获取当前场景并刷新
	var current_scene = get_tree().current_scene
	if current_scene:
		# 刷新主场景 UI
		if current_scene.has_method("refresh_ui"):
			current_scene.refresh_ui()
		
		# 刷新结算面板（如果开着）
		var panel = current_scene.get_node_or_null("UILayer/SettlementPanel")
		if panel and panel.has_method("refresh"):
			panel.refresh()
			
# 跳转后刷新资源状态
func _refresh_after_jump():
	# 恢复行动点
	if ResourceManager:
		ResourceManager.restore_action_points()
	
	# 重置本周权重变化记录
	if ResourceManager:
		ResourceManager.reset_weekly_weight_changes()
	
	# 应用待生效的设施升级
	if ResourceManager:
		ResourceManager.apply_pending_facility_upgrades()
# 结束游戏，显示结局界面
func _end_game():
	if is_game_ended:
		return
	
	is_game_ended = true
	print("=== 游戏结束！第18周已完成 ===")
	
	# 发射游戏结束信号
	EventBus.game_over.emit("game_complete")
	
	# 切换到结束场景
	_show_end_scene()

# 显示结局场景
func _show_end_scene():
	# 获取当前场景树
	var tree = get_tree()
	if not tree:
		return
	
	# 切换到结局场景（根据你的场景路径修改）
	var end_scene_path = "res://project/scenes/end/EndScene.tscn"
	
	# 检查文件是否存在
	if ResourceLoader.exists(end_scene_path):
		tree.change_scene_to_file(end_scene_path)
	else:
		print("结局场景不存在: ", end_scene_path)
		# 如果没有结局场景，显示一个简单的提示
		_show_end_notification()

# 简单的结束提示（备用）
func _show_end_notification():
	print("=========================================")
	print("        游戏通关！")
	print("    你完成了18周的乐队经营")
	print("=========================================")

# 周结算（保持原有逻辑）
func weekly_settlement():
	
	var is_final_week = (current_week >= 18)
	
	print("=== 第", current_week, "周结算开始 ===")
	EventBus.weekly_settlement_started.emit(current_week)
	
	# 记录结算前资金
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
	
	if is_final_week:
		print("第18周结算完成，游戏结束")
		_end_game()
		return
	
	# 否则进入下一周
	_delayed_next_week()
	
func _show_settlement_panel(settlement_data: Dictionary):
	var current_scene = get_tree().current_scene
	if not current_scene:
		return
	
	var panel = current_scene.get_node_or_null("UILayer/SettlementPanel")
	if panel and panel.has_method("show_settlement"):
		panel.show_settlement(settlement_data)
		# 等待3秒让玩家查看结算结果
		await get_tree().create_timer(3.0).timeout
		
		# 检查面板是否仍然有效
		if is_instance_valid(panel) and not panel.is_queued_for_deletion():
			panel.visible = false
	else:
		print("未找到 SettlementPanel")

func _delayed_next_week():
	# 如果是第18周，结束游戏
	if current_week >= 18:
		print("第18周结算完成，游戏结束")
		_end_game()
		return
	
	# 进入下一周
	next_week()
	
func _check_game_over_condition():
	if ResourceManager.should_trigger_debt_game_over():
		print("触发失败结局：资金负债持续 1 周")
		_trigger_game_over("debt_one_week")

func _trigger_game_over(game_over_type: String):
	print("游戏失败接口已调用，类型：", game_over_type)
	
	# 标记游戏已结束
	is_game_ended = true
	
	if EventBus.has_signal("game_over_triggered"):
		EventBus.game_over_triggered.emit(game_over_type)
	
	# 切换到失败结局场景
	_show_end_scene()

# 重置游戏（用于重新开始）
func reset_game():
	print("重置游戏...")
	
	# 重置状态
	is_game_ended = false
	current_week = 1
	current_phase = "early"
	
	# 重置资源管理器
	if ResourceManager:
		ResourceManager.init_new_game()
	
	# 重置周循环管理器
	var week_cycle = get_node("/root/WeekCycleManager")
	if week_cycle:
		week_cycle.current_week = 1
		week_cycle.set_phase(week_cycle.GamePhase.BEFORE_WEEK)
	
	# 重置时钟状态
	var clock_state = get_node("/root/ClockState")
	if clock_state:
		clock_state.set_phase(clock_state.ClockPhase.BEFORE_WEEK)
	
	# 发射重置信号
	EventBus.game_reset.emit()
	
	print("游戏已重置，回到第1周")
