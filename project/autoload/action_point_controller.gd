extends Node

# 常量配置，数值调整仅需改这里
const MAX_ACTION_POINT: int = 3
@onready var signal_bus = SignalBus

# 当前行动点，带setter自动触发UI刷新与边界校验
var current_ap: int = MAX_ACTION_POINT:
    set(value):
        var old_value = current_ap
        current_ap = clamp(value, 0, MAX_ACTION_POINT)
        # 发射信号通知UI刷新
        signal_bus.action_point_changed.emit(current_ap, MAX_ACTION_POINT)
        # 行动点耗尽时触发信号
        if current_ap == 0 and old_value > 0:
            signal_bus.action_point_depleted.emit()

# 新游戏初始化
func init_new_game():
    current_ap = MAX_ACTION_POINT

# 消耗行动点，返回是否成功
func consume_action_point(consume_count: int = 1) -> bool:
    if current_ap < consume_count:
        print("行动点不足，无法执行操作")
        return false
    current_ap -= consume_count
    print(f"消耗{consume_count}点行动点，剩余{current_ap}点")
    return true

# 恢复行动点（每周结算后调用）
func restore_action_point():
    current_ap = MAX_ACTION_POINT
    print(f"行动点已恢复至上限{MAX_ACTION_POINT}")

# 检查是否可执行操作
func can_execute_action(consume_count: int = 1) -> bool:
return current_ap >= consume_count

UI 联动实现
表现层仅监听信号，无需关心逻辑，UI 与逻辑完全解耦：
# 主界面行动点显示脚本
extends Label
@onready var signal_bus = SignalBus

func _ready():
    signal_bus.action_point_changed.connect(_on_ap_changed)
    _on_ap_changed(ActionPointController.current_ap, ActionPointController.MAX_ACTION_POINT)

func _on_ap_changed(current: int, max: int):
    text = "行动点：%d/%d" % [current, max]
modulate = Color(1,1,1) if current > 0 else Color(0.5,0.5,0.5) # 0点变灰

操作校验示例（设施升级按钮）：
extends Button
@export var facility_id: String = "stage"
@onready var facility_controller = FacilityController
@onready var action_point_controller = ActionPointController

func _ready():
    pressed.connect(_on_upgrade_clicked)

func _on_upgrade_clicked():
    # 1. 先校验行动点
    if not action_point_controller.can_execute_action(1):
        UIManager.show_warning_popup("行动点已耗尽，将自动进入周中阶段")
        return
    # 2. 执行升级，成功才消耗行动点
    if facility_controller.upgrade_facility(facility_id):
        action_point_controller.consume_action_point(1)