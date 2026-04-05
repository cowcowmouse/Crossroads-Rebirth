extends Control

# 评级规则（可根据需求修改分数阈值）
const RANK_S: int = 12000  # 90%以上
const RANK_A: int = 10000  # 75%以上
const RANK_B: int = 8000   # 60%以上
const RANK_C: int = 6000   # 40%以上
# 低于6000为D级

# 存储最终得分和星级
var final_score: int = 0
var final_star_rating: int = 0

func _ready():
	# 绑定重新开始按钮的点击事件
	var restart_button = get_node_or_null("RestartButton")
	if is_instance_valid(restart_button):
		restart_button.pressed.connect(_on_restart_pressed)

	# ===================== 【修复1：单独运行场景自动显示，F5运行也不冲突】 =====================
	# 无论从哪里打开，都先强制设置最高层级，绝对不被挡住
	z_index = 999
	z_as_relative = false
	move_to_front()

	# 如果是直接打开这个场景（F6单独运行），自动显示预览
	if get_tree().current_scene == self:
		show_result(5000, 50)  # 预览分数
	else:
		visible = false  # 正常游戏时默认隐藏

# 外部调用：显示结算面板，传入最终数据
func show_result(final_score: int, max_combo: int):
	self.final_score = final_score
	# ========== 逐个获取节点，精准定位哪个节点找不到 ==========
	var rank_label = get_node_or_null("RankLabel")
	var score_label = get_node_or_null("ScoreLabel")
	var combo_label = get_node_or_null("MaxComboLabel")

	# 精准报错
	if not is_instance_valid(rank_label):
		print("错误：找不到RankLabel节点！请检查场景里的节点名是否完全一致")
		return
	if not is_instance_valid(score_label):
		print("错误：找不到ScoreLabel节点！请检查场景里的节点名是否完全一致")
		return
	if not is_instance_valid(combo_label):
		print("错误：找不到MaxComboLabel节点！请检查场景里的节点名是否完全一致")
		return

	# 1. 显示得分和连击
	score_label.text = "最终得分：%s PTS" % final_score
	combo_label.text = "最高连击：%s COMBO" % max_combo

	# 2. 计算并显示评级
	var rank_text: String = "D"
	var rank_color: Color = Color("5a5758") # 默认D级灰色

	if final_score >= RANK_S:
		rank_text = "S"
		rank_color = Color("ffbe00") # 金色
	elif final_score >= RANK_A:
		rank_text = "A"
		rank_color = Color("32cd32") # 亮绿色
	elif final_score >= RANK_B:
		rank_text = "B"
		rank_color = Color("e2dd25") # 黄绿色
	elif final_score >= RANK_C:
		rank_text = "C"
		rank_color = Color("8dbfc7") # 浅蓝色
	else:
		rank_text = "D"
		rank_color = Color("5a5758") # 灰色

	rank_label.text = rank_text
	rank_label.add_theme_color_override("font_color", rank_color)

	
	# 3. 显示面板（【修复2：强制层级+居中，F5运行也绝对可见】）
	visible = true
	z_index = 999
	z_as_relative = false
	move_to_front()
	# 强制面板居中，解决位置偏移
	position = (get_viewport().get_visible_rect().size - size) / 2
	print("结算面板已正常弹出！层级：", z_index, " | 位置：", position)

# 重新开始游戏
func _on_restart_pressed():
	_close_panel_and_return()

# ===================== 新增：小游戏结束返回主场景 =====================

# 重新开始按钮的替代处理（如果需要返回主场景）
func _on_back_to_main_pressed():
	print("返回主场景")
	_close_panel_and_return()

# 关闭面板并返回主场景
func _close_panel_and_return():
	# 隐藏面板
	visible = false
	
	# 获取当前评级
	var rank = _get_current_rank()
	
	# 发射小游戏结束信号（传递得分和评级）
	if Engine.has_singleton("EventBus"):
		EventBus.minigame_finished.emit(final_score, rank)
	
	# 延迟一点，确保信号发送完成
	await get_tree().create_timer(0.1).timeout
	
	# 切换回主场景
	get_tree().change_scene_to_file("res://project/scenes/main/Main.tscn")

# 获取当前评级
func _get_current_rank() -> String:
	var rank_label = get_node_or_null("RankLabel")
	if not is_instance_valid(rank_label):
		return "D"
	return rank_label.text
