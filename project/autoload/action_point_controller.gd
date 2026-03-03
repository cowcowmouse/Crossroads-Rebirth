extends Node

## 行动点控制器
const MAX_ACTION_POINT: int = 3

@onready var signal_bus = SignalBus

var current_ap: int = MAX_ACTION_POINT:
    set(value):
        var old_value = current_ap
        current_ap = clamp(value, 0, MAX_ACTION_POINT)
        signal_bus.action_point_changed.emit(current_ap, MAX_ACTION_POINT)
        if current_ap == 0 and old_value > 0:
            signal_bus.action_point_depleted.emit()

func init_new_game():
    current_ap = MAX_ACTION_POINT

func consume_action_point(consume_count: int = 1) -> bool:
    if current_ap < consume_count:
        print("行动点不足，无法执行操作")
        return false
    current_ap -= consume_count
    print("消耗" + str(consume_count) + "点行动点，剩余" + str(current_ap) + "点")
    return true

func restore_action_point():
    current_ap = MAX_ACTION_POINT
    print("行动点已恢复至上限" + str(MAX_ACTION_POINT))

func can_execute_action(consume_count: int = 1) -> bool:
    return current_ap >= consume_count