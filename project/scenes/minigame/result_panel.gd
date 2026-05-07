extends Control

# ===================== 评级规则 =====================
const RANK_S: int = 12000
const RANK_A: int = 10000
const RANK_B: int = 8000
const RANK_C: int = 6000

var final_score: int = 0
var max_combo: int = 0

func _ready():
	# 强制置顶
	z_index = 999
	move_to_front()
	
	# 自动绑定按钮（防止信号没连上）
	var restart_button = get_node_or_null("RestartButton")
	if is_instance_valid(restart_button):
		# 如果已经连过，就不再重复连接
		if not restart_button.pressed.is_connected(_on_restart_pressed):
			restart_button.pressed.connect(_on_restart_pressed)
		print("ResultPanel: 重新开始按钮已连接")
	else:
		print("错误：找不到 RestartButton 节点！请检查场景中节点名称是否为 RestartButton")
	
	# 测试模式：如果单独运行这个场景，自动显示测试数据
	if get_tree().current_scene == self:
		show_result(6000, 0)
	else:
		visible = false

# ===================== 显示结算面板 =====================
func show_result(score: int, combo: int):
	final_score = score
	max_combo = combo
	
	var rank_label = get_node_or_null("RankLabel")
	var score_label = get_node_or_null("ScoreLabel")
	var combo_label = get_node_or_null("MaxComboLabel")
	
	if not is_instance_valid(rank_label) or not is_instance_valid(score_label) or not is_instance_valid(combo_label):
		print("错误：节点查找失败！请确认节点名为 RankLabel、ScoreLabel、MaxComboLabel")
		return
	
	score_label.text = "最终得分：%d PTS" % score
	combo_label.text = "最高连击：%d COMBO" % combo
	
	# 计算评级
	var rank_text = "D"
	var rank_color = Color("5a5758")
	if score >= RANK_S:
		rank_text = "S"; rank_color = Color("ffbe00")
	elif score >= RANK_A:
		rank_text = "A"; rank_color = Color("32cd32")
	elif score >= RANK_B:
		rank_text = "B"; rank_color = Color("e2dd25")
	elif score >= RANK_C:
		rank_text = "C"; rank_color = Color("8dbfc7")
	
	rank_label.text = rank_text
	rank_label.add_theme_color_override("font_color", rank_color)
	
	# 表演总结与资源加成
	_calculate_and_apply_rewards(score)
	
	visible = true
	move_to_front()
	position = (get_viewport().get_visible_rect().size - size) / 2

# ===================== 表演总结与资源奖励 =====================
func _calculate_and_apply_rewards(score: int):
	var stage_info = ResourceManager.get_reputation_stage()
	var performance_level = ""
	var rep_gain = 0
	var cohesion_gain = 0
	var money_gain = 0
	
	if score >= 11000:
		performance_level = "完美演出！"
		rep_gain = 28; cohesion_gain = 15; money_gain = 1500
	elif score >= 9000:
		performance_level = "优秀演出"
		rep_gain = 20; cohesion_gain = 10; money_gain = 1000
	elif score >= 7000:
		performance_level = "良好演出"
		rep_gain = 14; cohesion_gain = 7; money_gain = 700
	elif score >= 5000:
		performance_level = "普通演出"
		rep_gain = 8; cohesion_gain = 4; money_gain = 400
	else:
		performance_level = "发挥一般"
		rep_gain = 3; cohesion_gain = 2; money_gain = 150
	
	rep_gain = int(rep_gain * stage_info.scale)
	cohesion_gain = int(cohesion_gain * stage_info.scale)
	money_gain = int(money_gain * stage_info.scale)
	
	ResourceManager.add_reputation(rep_gain)
	ResourceManager.add_cohesion(cohesion_gain)
	ResourceManager.add_money(money_gain)
	
	show_performance_summary(performance_level, rep_gain, cohesion_gain, money_gain, stage_info.name)

func show_performance_summary(level: String, rep: int, cohesion: int, money: int, stage_name: String):
	# 创建一个漂亮的自定义面板
	var panel = Panel.new()
	panel.name = "PerformanceSummaryPanel"
	panel.z_index = 3000
	panel.size = Vector2(560, 380)
	panel.position = (get_viewport_rect().size - panel.size) / 2
	
	# 半透明深色背景 + 边框
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.95, 0.75, 0.3, 0.9)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	panel.add_theme_stylebox_override("panel", style)
	
	# 标题
	var title = Label.new()
	title.text = "本周表演总结"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	title.position = Vector2(0, 30)
	title.size = Vector2(560, 50)
	panel.add_child(title)
	
	# 内容
	var summary_text = """
当前表演规模：%s

表演表现：%s

获得奖励：
声誉 +%d
凝聚力 +%d
资金 +%d
""" % [stage_name, level, rep, cohesion, money]
	
	var content = RichTextLabel.new()
	content.bbcode_enabled = true
	content.text = summary_text
	content.add_theme_font_size_override("normal_font_size", 22)
	content.add_theme_color_override("default_color", Color(0.95, 0.95, 0.95))
	content.position = Vector2(50, 100)
	content.size = Vector2(460, 250)
	panel.add_child(content)
	
	# 确定按钮
	var ok_btn = Button.new()
	ok_btn.text = "确定"
	ok_btn.position = Vector2(210, 320)
	ok_btn.size = Vector2(140, 45)
	ok_btn.add_theme_font_size_override("font_size", 24)
	ok_btn.pressed.connect(func():
		panel.queue_free()
	)
	panel.add_child(ok_btn)

	add_child(panel)
	panel.move_to_front()

# ===================== 重新开始按钮 =====================
func _on_restart_pressed():
	print("重新开始按钮被点击 → 返回主界面")
	_close_panel_and_return_to_main()

func _close_panel_and_return_to_main():
	visible = false
	
	if EventBus.has_signal("minigame_finished"):
		EventBus.minigame_finished.emit(final_score, _get_current_rank())
	
	await get_tree().create_timer(0.1).timeout
	
	var main_path = "res://project/scenes/main/Main.tscn"
	if ResourceLoader.exists(main_path):
		get_tree().change_scene_to_file(main_path)
	else:
		print("错误：找不到主场景文件 ", main_path)

func _get_current_rank() -> String:
	var rank_label = get_node_or_null("RankLabel")
	return rank_label.text if is_instance_valid(rank_label) else "D"
