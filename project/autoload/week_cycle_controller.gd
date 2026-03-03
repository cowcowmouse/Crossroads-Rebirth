extends Node

enum WeekCycleStage {
    PRE_WEEK,  # 周前：经营规划
    MID_WEEK,  # 周中：事件触发
    WEEKEND,   # 周末：结算阶段
    WEEK_END   # 本周结束
}

@onready var signal_bus = SignalBus
@onready var action_point_controller = ActionPointController

var current_week: int = 1
var current_stage: WeekCycleStage = WeekCycleStage.PRE_WEEK:
    set(value):
        current_stage = value
        _on_stage_changed(value)

func init_new_game():
    current_week = 1
    current_stage = WeekCycleStage.PRE_WEEK

func _on_stage_changed(new_stage: WeekCycleStage):
    match new_stage:
        WeekCycleStage.PRE_WEEK:
            print("===== 第" + str(current_week) + "周 周前经营阶段 =====")
            signal_bus.pre_week_start.emit()
            action_point_controller.restore_action_point()
        WeekCycleStage.MID_WEEK:
            print("===== 第" + str(current_week) + "周 周中事件阶段 =====")
            signal_bus.mid_week_start.emit()
        WeekCycleStage.WEEKEND:
            print("===== 第" + str(current_week) + "周 周末结算阶段 =====")
            signal_bus.weekend_start.emit()
        WeekCycleStage.WEEK_END:
            print("===== 第" + str(current_week) + "周 结束 =====")
            signal_bus.week_end.emit(current_week)