# 周循环控制器，实现设计文档「经营→事件→抉择→结算」闭环
extends Node

# 手动获取全局单例，避免 @onready 时机问题
var signal_bus: Node = null
var constants: Node = null
var action_point_controller: Node = null
var resource_manager: Node = null

var current_week: int = 1
# 直接用 int 存储阶段值，避免枚举类型注解问题
var current_stage: int = 0

# 节点就绪后手动获取全局单例（最稳妥的方式）
func _ready():
	# 从根节点获取所有全局单例
	constants = get_node("/root/Constants")
	signal_bus = get_node("/root/SignalBus")
	action_point_controller = get_node("/root/ActionPointController")
	resource_manager = get_node("/root/ResourceManager")
	
	# 空值校验：确保所有依赖加载完成
	if not constants or not signal_bus or not action_point_controller or not resource_manager:
		push_error("全局单例加载失败，请检查自动加载配置！")
		return
	
	# 初始化阶段
	current_stage = constants.WeekCycleStage.PRE_WEEK
	init_new_game()

# 新游戏初始化
func init_new_game():
	current_week = 1
	current_stage = constants.WeekCycleStage.PRE_WEEK
	print("新游戏启动，进入第", current_week, "周")

# 阶段切换时自动执行对应逻辑
func _on_stage_changed(new_stage: int):
	if not constants or not signal_bus:
		return
	
	match new_stage:
		# 周前经营阶段
		constants.WeekCycleStage.PRE_WEEK:
			print("===== 第", current_week, "周 周前经营阶段 =====")
			signal_bus.pre_week_start.emit()
			action_point_controller.restore_action_point() # 恢复行动点
		
		# 周中事件阶段
		constants.WeekCycleStage.MID_WEEK:
			print("===== 第", current_week, "周 周中事件阶段 =====")
			signal_bus.mid_week_start.emit()
			# 后续里程碑补充事件触发逻辑
		
		# 周末结算阶段
		constants.WeekCycleStage.WEEKEND:
			print("===== 第", current_week, "周 周末结算阶段 =====")
			signal_bus.weekend_start.emit()
			_execute_weekend_settlement() # 执行周结算
		
		# 本周结束
		constants.WeekCycleStage.WEEK_END:
			print("===== 第", current_week, "周 结束 =====")
			signal_bus.week_end.emit(current_week)

# 周结算核心逻辑（严格对齐设计文档）
func _execute_weekend_settlement():
	if not constants or not resource_manager:
		return
	
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
	if not resource_manager:
		return
	
	for member_id in resource_manager.members:
		resource_manager.members[member_id].weekly_chat_count = 0

# ===================== 外部调用接口 =====================
# 进入周中阶段
func enter_mid_week():
	if not constants:
		return
	if current_stage == constants.WeekCycleStage.PRE_WEEK:
		current_stage = constants.WeekCycleStage.MID_WEEK
		_on_stage_changed(current_stage)

# 进入周末结算
func enter_weekend():
	if not constants:
		return
	if current_stage == constants.WeekCycleStage.MID_WEEK:
		current_stage = constants.WeekCycleStage.WEEKEND
		_on_stage_changed(current_stage)

# 进入下一周
func enter_next_week():
	if not constants:
		return
	if current_stage == constants.WeekCycleStage.WEEK_END:
		current_week += 1
		current_stage = constants.WeekCycleStage.PRE_WEEK
		_on_stage_changed(current_stage)
