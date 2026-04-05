# 行动点控制器，严格遵循设计文档：3点/周，仅周前操作消耗
extends Node

@onready var signal_bus = SignalBus

@onready var constants: Node = Constants
# 当前行动点，带setter自动触发UI刷新与边界校验
var current_ap: int:
	set(value):
		var old_value = current_ap
		current_ap = clamp(value, 0, constants.MAX_ACTION_POINT)
		# 发射信号通知UI刷新
		signal_bus.action_point_changed.emit(current_ap, constants.MAX_ACTION_POINT)
		# 行动点耗尽时触发信号
		if current_ap == 0 and old_value > 0:
			signal_bus.action_point_depleted.emit()

# 节点就绪时初始化（@onready变量此时已完成赋值，不会再是Nil）
func _ready():
	init_new_game()

# 新游戏初始化
func init_new_game():
	# 此时constants已经完成赋值，不会报错
	current_ap = constants.MAX_ACTION_POINT
	print("行动点初始化完成，当前：", current_ap, "/", constants.MAX_ACTION_POINT)

# 消耗行动点，返回是否成功
func consume_action_point(consume_count: int = 1) -> bool:
	if current_ap < consume_count:
		print("行动点不足，无法执行操作")
		return false
	current_ap -= consume_count
	print("消耗{consume_count}点行动点，剩余{current_ap}点")
	return true

# 恢复行动点（每周结算后调用）
func restore_action_point():
	current_ap = constants.MAX_ACTION_POINT
	print("行动点已恢复至上限{constants.MAX_ACTION_POINT}")

# 检查是否可执行操作
func can_execute_action(consume_count: int = 1) -> bool:
	return current_ap >= consume_count
