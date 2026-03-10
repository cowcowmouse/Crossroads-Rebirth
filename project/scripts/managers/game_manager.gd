extends Node
@onready var signal_bus = SignalBus
@onready var action_point_controller = ActionPointController
@onready var event_manager = EventManager
@onready var resource_manager = ResourceManager
@onready var game_manager = GameManager

var current_week: int = 1
var current_stage: WeekCycleStage = WeekCycleStage.PRE_WEEK:
    set(value):
        current_stage = value
        _on_stage_changed(value)

# 新游戏初始化
func init_new_game():
    current_week = 1
    current_stage = WeekCycleStage.PRE_WEEK

# 阶段切换时自动执行对应逻辑
func _on_stage_changed(new_stage: WeekCycleStage):
    match new_stage:
        WeekCycleStage.PRE_WEEK:
            print(f"===== 第{current_week}周 周前经营阶段 =====")
            signal_bus.pre_week_start.emit()
            action_point_controller.restore_action_point() # 恢复行动点
            UIManager.set_pre_week_operation_enabled(true) # 解锁操作
        
        WeekCycleStage.MID_WEEK:
            print(f"===== 第{current_week}周 周中事件阶段 =====")
            signal_bus.mid_week_start.emit()
            UIManager.set_pre_week_operation_enabled(false) # 锁定操作
            event_manager.trigger_mid_week_core_event() # 触发周中事件
        
        WeekCycleStage.WEEKEND:
            print(f"===== 第{current_week}周 周末结算阶段 =====")
            signal_bus.weekend_start.emit()
            _execute_weekend_settlement() # 执行周结算
            UIManager.show_settlement_panel() # 弹出结算面板
        
        WeekCycleStage.WEEK_END:
            print(f"===== 第{current_week}周 结束 =====")
            signal_bus.week_end.emit(current_week)
            game_manager.check_game_stage(current_week) # 检查游戏阶段切换
            if current_week >= 18: # 18周触发结局
                game_manager.trigger_ending_calculation()

# 周结算核心逻辑（严格对齐文档）
func _execute_weekend_settlement():
    resource_manager.deduct_fixed_expense(current_week) # 扣租金+工资
    resource_manager.calculate_bar_income() # 计算酒吧收入
    resource_manager.update_member_state_natural_change() # 成员状态自然变化
    resource_manager.apply_facility_weekend_bonus() # 设施增益生效
    game_manager.check_unlock_content() # 检查解锁内容
    game_manager.check_game_over_condition() # 检查游戏失败条件

# 外部调用接口
func enter_mid_week():
    if current_stage == WeekCycleStage.PRE_WEEK:
        current_stage = WeekCycleStage.MID_WEEK

func enter_weekend():
    if current_stage == WeekCycleStage.MID_WEEK:
        current_stage = WeekCycleStage.WEEKEND

func enter_next_week():
    if current_stage == WeekCycleStage.WEEK_END:
        current_week += 1
        current_stage = WeekCycleStage.PRE_WEEK
