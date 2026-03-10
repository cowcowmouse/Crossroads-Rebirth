# 周循环控制器，实现设计文档「经营→事件→抉择→结算」闭环
extends Node

@onready var signal_bus = SignalBus
@onready var constants = Constants
@onready var action_point_controller = ActionPointController
@onready var resource_manager = ResourceManager

var current_week: int = 1
var current_stage: constants.WeekCycleStage = constants.WeekCycleStage.PRE_WEEK:
	set(value):
		current_stage = value
		_on_stage_changed(value)

# 新游戏初始化
func init_new_game():
	current_week = 1
	current_stage = constants.WeekCycleStage.PRE_WEEK
	print("新游戏启动，进入第", current_week, "周")

# 阶段切换时自动执行对应逻辑
func _on_stage_changed(new_stage: constants.WeekCycleStage):
	match new_stage:
		# 周前经营阶段
		constants.WeekCycleStage.PRE_WEEK:
			print(f"===== 第{current_week}周 周前经营阶段 =====")
			signal_bus.pre_week_start.emit()
			action_point_controller.restore_action_point() # 恢复行动点
		
		# 周中事件阶段
		constants.WeekCycleStage.MID_WEEK:
			print(f"===== 第{current_week}周 周中事件阶段 =====")
			signal_bus.mid_week_start.emit()
			# 后续里程碑补充事件触发逻辑
		
		# 周末结算阶段
		constants.WeekCycleStage.WEEKEND:
			print(f"===== 第{current_week}周 周末结算阶段 =====")
			signal_bus.weekend_start.emit()
			_execute_weekend_settlement() # 执行周结算
		
		# 本周结束
		constants.WeekCycleStage.WEEK_END:
			print(f"===== 第{current_week}周 结束 =====")
			signal_bus.week_end.emit(current_week)

# 周结算核心逻辑（严格对齐设计文档）
func _execute_weekend_settlement():
	# 1. 扣除固定支出（租金+工资，新手期减半）
	var fixed_expense = 750 if current_week <= 3 else 1500
	resource_manager.modify_core_resource(constants.RES_MONEY, -fixed_expense)
	# 2. 计算酒吧基础收入（初始2200，后续里程碑按设施等级扩展）
	var bar_income = 2200
	resource_manager.modify_core_resource(constants.RES_MONEY, bar_income)
	# 3. 重置成员本周对话次数
	_reset_member_weekly_chat_count()
	print("周结算完成，固定支出：", fixed_expense, "，酒吧收入：", bar_income)

# 重置成员每周对话次数
func _reset_member_weekly_chat_count():
	for member_id in resource_manager.members:
		resource_manager.members[member_id].weekly_chat_count = 0

# ===================== 外部调用接口 =====================
# 进入周中阶段
func enter_mid_week():
	if current_stage == constants.WeekCycleStage.PRE_WEEK:
		current_stage = constants.WeekCycleStage.MID_WEEK

# 进入周末结算
func enter_weekend():
	if current_stage == constants.WeekCycleStage.MID_WEEK:
		current_stage = constants.WeekCycleStage.WEEKEND

# 进入下一周
func enter_next_week():
	if current_stage == constants.WeekCycleStage.WEEK_END:
		current_week += 1
		current_stage = constants.WeekCycleStage.PRE_WEEK
