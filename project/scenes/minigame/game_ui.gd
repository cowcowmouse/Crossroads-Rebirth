extends Control

var score: int = 0
var combo_count: int = 0
var max_combo: int = 0 # 新增：记录最高连击

# Called when the node enters the scene tree for the first time.
func _ready():
	Signals.IncrementScore.connect(IncrementScore)
	Signals.IncrementCombo.connect(IncrementCombo)
	Signals.ResetCombo.connect(ResetCombo)
	
	ResetCombo()

func IncrementScore(incr: int):
	score += incr
	%ScoreLabel.text = " " + str(score) + " pts"

func IncrementCombo():
	combo_count += 1
	# 新增：更新最高连击
	if combo_count > max_combo:
		max_combo = combo_count
	%ComboLabel.text = " " + str(combo_count) + "x combo"

func ResetCombo():
	combo_count = 0
	%ComboLabel.text = ""

# 新增：给结算面板提供最终数据
func get_final_score() -> int:	
	return score

func get_max_combo() -> int:
	return max_combo
