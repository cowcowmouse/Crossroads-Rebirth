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
	
	# 新一周开始时，应用上周待生效的设施升级
	ResourceManager.apply_pending_facility_upgrades()
	
	# 发射到 EventBus
	EventBus.week_changed.emit(current_week)
	check_phase_transition()
	
func check_phase_transition():
	if current_week >= 13:
		set_phase("late")
	elif current_week >= 4:
		set_phase("mid")
		
func set_phase(new_phase):
	current_phase = new_phase
	# 发射到 EventBus
	EventBus.phase_changed.emit(current_phase)

# 周结算
func weekly_settlement():
	print("第", current_week, "周结算开始")
	EventBus.weekly_settlement_started.emit(current_week)
	# 1. 扣固定支出
	# 2. 加酒吧收入
	# 3. 成员状态变化
	# 4. 检查游戏结束
	EventBus.weekly_settlement_finished.emit(current_week)
