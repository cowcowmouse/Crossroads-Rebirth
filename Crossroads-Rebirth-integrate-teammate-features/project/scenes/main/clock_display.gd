extends TextureRect

@onready var week_cycle = get_node("/root/WeekCycleManager")
@onready var clock_state = get_node("/root/ClockState")

# 三种状态的图片
var clock_textures = {
	0: preload("res://project/assets/images/ui/clock/clock_before.png"),   # 周前
	1: preload("res://project/assets/images/ui/clock/clock_mid.png"),      # 周中
	2: preload("res://project/assets/images/ui/clock/clock_after.png")     # 周后
}

func _ready():
	if week_cycle:
		week_cycle.phase_changed.connect(_on_phase_changed)
	if clock_state:
		clock_state.clock_phase_changed.connect(_on_clock_phase_changed)
	
	# 初始显示
	_update_clock(week_cycle.get_current_phase() if week_cycle else 0)

func _on_phase_changed(phase):
	_update_clock(phase)

func _on_clock_phase_changed(phase):
	_update_clock(phase)

func _update_clock(phase):
	var new_texture = clock_textures.get(phase, null)
	if new_texture:
		texture = new_texture  # 关键：这里要赋值给 texture
		print("时钟更新: 阶段 ", phase, " 图片已切换")
