extends Node

enum GamePhase {
	BEFORE_WEEK,   # 周前：玩家可操作
	MID_WEEK,      # 周中：触发事件
	AFTER_WEEK     # 周后：结算
}

signal phase_changed(phase: GamePhase)
signal action_points_updated(current: int, max: int)

var current_phase: GamePhase = GamePhase.BEFORE_WEEK
var current_week: int = 1
var action_points: int = 3
var max_action_points: int = 3

func _ready():
	process_mode = PROCESS_MODE_ALWAYS

func start_new_week():
	current_week += 1
	action_points = max_action_points
	set_phase(GamePhase.BEFORE_WEEK)
	action_points_updated.emit(action_points, max_action_points)
	print("=== 第", current_week, "周开始 ===")

func consume_action_point() -> bool:
	if current_phase != GamePhase.BEFORE_WEEK:
		print("当前不是周前阶段，无法消耗行动点")
		return false
	
	if action_points <= 0:
		print("行动点已耗尽")
		# 行动点已为0，不重复触发
		return false
	
	action_points -= 1
	action_points_updated.emit(action_points, max_action_points)
	
	print("消耗行动点，剩余: ", action_points)
	
	# 只有行动点归零时才强制进入周中
	if action_points == 0:
		print("行动点耗尽，自动进入周中阶段")
		force_to_mid_week()
	
	return true

func force_to_mid_week():
	if current_phase == GamePhase.BEFORE_WEEK:
		set_phase(GamePhase.MID_WEEK)

func set_phase(phase: GamePhase):
	if current_phase != phase:
		current_phase = phase
		phase_changed.emit(current_phase)
		print("游戏阶段变化: ", _get_phase_name(current_phase))

func complete_mid_week():
	if current_phase == GamePhase.MID_WEEK:
		set_phase(GamePhase.AFTER_WEEK)

func complete_week_settlement():
	if current_phase == GamePhase.AFTER_WEEK:
		# 结算完成后，进入下一周
		start_new_week()

func get_current_phase() -> GamePhase:
	return current_phase

func get_action_points() -> int:
	return action_points

func _get_phase_name(phase: GamePhase) -> String:
	match phase:
		GamePhase.BEFORE_WEEK:
			return "周前"
		GamePhase.MID_WEEK:
			return "周中"
		GamePhase.AFTER_WEEK:
			return "周后"
	return "未知"
