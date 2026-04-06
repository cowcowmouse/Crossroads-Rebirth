extends Panel

@onready var week_label = $WeekLabel
@onready var expense_label = $ExpenseLabel
@onready var income_label = $IncomeLabel
@onready var net_change_label = $NetChangeLabel
@onready var money_after_label = $MoneyAfterLabel
@onready var lounge_bonus_label = $LoungeBonusLabel
@onready var weight_change_label = $WeightChangeLabel
@onready var debt_status_label = $DebtStatusLabel
@onready var confirm_button = $ConfirmButton

func _ready():
	visible = false
	confirm_button.pressed.connect(_on_confirm_pressed)

# 显示结算数据（GameManager 会调用这个）
func show_settlement(data: Dictionary):
	visible = true
	
	week_label.text = "第 %d 周结算" % int(data.get("week", 0))
	expense_label.text = "固定支出：-%d" % int(data.get("expense", 0))
	income_label.text = "酒吧收入：+%d" % int(data.get("bar_income", 0))
	
	var net_change = int(data.get("net_change", 0))
	if net_change >= 0:
		net_change_label.text = "本周净变化：+%d" % net_change
		net_change_label.modulate = Color.GREEN
	else:
		net_change_label.text = "本周净变化：%d" % net_change
		net_change_label.modulate = Color.RED
	
	money_after_label.text = "结算后资金：%d" % int(data.get("money_after", 0))
	
	var fatigue = int(data.get("lounge_fatigue_recovery", 0))
	var cohesion = int(data.get("lounge_cohesion_bonus", 0))
	lounge_bonus_label.text = "休息室恢复：疲劳-%d / 凝聚力+%d" % [fatigue, cohesion]
	
	# 显示方向值变化
	var art_change = int(data.get("art_change", 0))
	var business_change = int(data.get("business_change", 0))
	var human_change = int(data.get("human_change", 0))
	weight_change_label.text = "方向值变化：商业 %+d / 艺术 %+d / 人情 %+d" % [business_change, art_change, human_change]
	
	var is_in_debt = bool(data.get("is_in_debt", false))
	var debt_weeks = int(data.get("debt_weeks", 0))
	
	if is_in_debt:
		debt_status_label.text = "负债状态：是（%d周）" % debt_weeks
		debt_status_label.modulate = Color.RED
	else:
		debt_status_label.text = "负债状态：否"
		debt_status_label.modulate = Color.WHITE

func _on_confirm_pressed():
	visible = false
	WeekCycleManager.start_new_week()
