extends Control

# 评级规则（可根据需求修改分数阈值）
const RANK_S: int = 12000
const RANK_A: int = 10000
const RANK_B: int = 8000
const RANK_C: int = 6000

# 存储最终得分和星级
var final_score: int = 0
var final_star_rating: int = 0

# ===================== 修复：无论从哪里打开都强制显示 =====================
func _ready():
	z_index = 999
	z_as_relative = false
	move_to_front()

	# 如果是单独运行这个场景（F6），自动显示预览
	if get_tree().current_scene == self:
		show_result(8500, 45)   # 测试用预览分数
	else:
		visible = false         # 正常游戏时默认隐藏

# ===================== 主函数：显示结算面板 =====================
func show_result(score: int, max_combo: int):
	self.final_score = score
	
	# 获取节点
	var rank_label = get_node_or_null("RankLabel")
	var score_label = get_node_or_null("ScoreLabel")
	var combo_label = get_node_or_null("MaxComboLabel")
	
	if not is_instance_valid(rank_label) or not is_instance_valid(score_label) or not is_instance_valid(combo_label):
		print("错误：结算面板节点未找到！请检查节点名称是否正确")
		return
	
	# 显示得分和连击
	score_label.text = "最终得分：%d PTS" % score
	combo_label.text = "最高连击：%d COMBO" % max_combo
	
	# 计算评级
	var rank_text = "D"
	var rank_color = Color("5a5758")
	if score >= RANK_S:
		rank_text = "S"
		rank_color = Color("ffbe00")
	elif score >= RANK_A:
		rank_text = "A"
		rank_color = Color("32cd32")
	elif score >= RANK_B:
		rank_text = "B"
		rank_color = Color("e2dd25")
	elif score >= RANK_C:
		rank_text = "C"
		rank_color = Color("8dbfc7")
	
	rank_label.text = rank_text
	rank_label.add_theme_color_override("font_color", rank_color)
	
	# ===================== 新增：声誉阶段 + 数值结算 =====================
	var stage_info = ResourceManager.get_reputation_stage()
	var performance_level = ""
	var rep_gain = 0
	var cohesion_gain = 0
	var money_gain = 0
	
	# 根据得分判断表演质量
	if score >= 11000:
		performance_level = "完美演出！"
		rep_gain = 28
		cohesion_gain = 15
		money_gain = 1500
	elif score >= 9000:
		performance_level = "优秀演出"
		rep_gain = 20
		cohesion_gain = 10
		money_gain = 1000
	elif score >= 7000:
		performance_level = "良好演出"
		rep_gain = 14
		cohesion_gain = 7
		money_gain = 700
	elif score >= 5000:
		performance_level = "普通演出"
		rep_gain = 8
		cohesion_gain = 4
		money_gain = 400
	else:
		performance_level = "发挥一般"
		rep_gain = 3
		cohesion_gain = 2
		money_gain = 150
	
	# 应用声誉阶段规模加成
	rep_gain = int(rep_gain * stage_info.scale)
	cohesion_gain = int(cohesion_gain * stage_info.scale)
	money_gain = int(money_gain * stage_info.scale)
	
	# 更新后台资源
	ResourceManager.add_reputation(rep_gain)
	ResourceManager.add_cohesion(cohesion_gain)
	ResourceManager.add_money(money_gain)
	
	# 显示结果说明
	show_performance_summary(performance_level, rep_gain, cohesion_gain, money_gain, stage_info.name)
	
	# 显示面板
	visible = true
	z_index = 999
	move_to_front()
	position = (get_viewport().get_visible_rect().size - size) / 2

# ===================== 显示表演总结 =====================
func show_performance_summary(level: String, rep: int, cohesion: int, money: int, stage_name: String):
	var summary = """
    当前表演规模：%s
    
    表演表现：%s
    
    获得奖励：
    声誉 +%d
    凝聚力 +%d
    资金 +%d
	""" % [stage_name, level, rep, cohesion, money]
	
	# 你可以改成 AcceptDialog、RichTextLabel 或自定义弹窗
	var dialog = AcceptDialog.new()
	dialog.title = "本周表演总结"
	dialog.dialog_text = summary
	add_child(dialog)
	dialog.popup_centered()

# ===================== 重新开始 / 返回 =====================
func _on_restart_pressed():
	_close_panel_and_return()

func _close_panel_and_return():
	visible = false
	# 发射信号给其他系统（可选）
	if EventBus.has_signal("minigame_finished"):
		EventBus.minigame_finished.emit(final_score, _get_current_rank())
	
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://project/scenes/main/Main.tscn")

func _get_current_rank() -> String:
	var rank_label = get_node_or_null("RankLabel")
	return rank_label.text if is_instance_valid(rank_label) else "D"
