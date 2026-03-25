extends Node

# 时钟状态枚举
enum ClockPhase {
	BEFORE_WEEK,   # 周前（可操作阶段）
	MID_WEEK,      # 周中（事件阶段）
	AFTER_WEEK     # 周后（结算阶段）
}

signal clock_phase_changed(phase: ClockPhase)

var current_phase: ClockPhase = ClockPhase.BEFORE_WEEK

func set_phase(phase: ClockPhase):
	if current_phase != phase:
		current_phase = phase
		clock_phase_changed.emit(current_phase)
		print("时钟状态变化: ", _get_phase_name(current_phase))

func get_current_phase() -> ClockPhase:
	return current_phase

func _get_phase_name(phase: ClockPhase) -> String:
	match phase:
		ClockPhase.BEFORE_WEEK:
			return "周前"
		ClockPhase.MID_WEEK:
			return "周中"
		ClockPhase.AFTER_WEEK:
			return "周后"
	return "未知"
