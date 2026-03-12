extends Panel

# UI节点绑定
@onready var background: ColorRect = $Background
@onready var content_panel: PanelContainer = $ContentPanel
@onready var progress_bar: ProgressBar = $ContentPanel/VBoxContainer/ProgressBar
@onready var progress_label: Label = $ContentPanel/VBoxContainer/ProgressLabel
@onready var mini_game_btn: Button = $ContentPanel/VBoxContainer/MiniGameBtn
@onready var close_btn: Button = $ContentPanel/VBoxContainer/CloseBtn

# 全局单例
var resource_manager: Node = null
var constants: Node = null

func _ready():
	# 获取全局单例
	resource_manager = get_node("/root/ResourceManager")
	constants = get_node("/root/Constants")
	
	# 绑定按钮事件
	mini_game_btn.pressed.connect(_on_mini_game_clicked)
	close_btn.pressed.connect(_on_close_clicked)
	
	# 初始隐藏
	visible = false
	background.modulate = Color(1,1,1,0)
	content_panel.modulate = Color(1,1,1,0)
	content_panel.scale = Vector2(0.8, 0.8)

# 打开弹窗（外部调用接口）
func open_panel():
	if not resource_manager or not constants:
		return
	
	# 更新恢复程度显示
	_update_progress_display()
	
	# 显示并播放淡入动画
	visible = true
	var tween = create_tween()
	tween.tween_property(background, "modulate:a", 0.7, 0.2)
	tween.parallel().tween_property(content_panel, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(content_panel, "scale", Vector2(1, 1), 0.2).set_ease(Tween.EASE_OUT)

# 关闭弹窗
func close_panel():
	# 播放淡出动画
	var tween = create_tween()
	tween.tween_property(background, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(content_panel, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(content_panel, "scale", Vector2(0.8, 0.8), 0.2)
	await tween.finished
	visible = false

# 更新恢复程度显示
func _update_progress_display():
	if not resource_manager or not constants:
		return
	
	var memory_value = resource_manager.get_resource_value(constants.RES_MEMORY)
	progress_bar.value = memory_value
	progress_label.text = "记忆恢复度：%d%%" % memory_value
	
	# 根据恢复程度改变进度条颜色
	if memory_value < 30:
		progress_bar.get("custom_styles/fill").bg_color = Color(0.8, 0.2, 0.2, 1)  # 红色
	elif memory_value < 70:
		progress_bar.get("custom_styles/fill").bg_color = Color(0.8, 0.6, 0.2, 1)  # 黄色
	else:
		progress_bar.get("custom_styles/fill").bg_color = Color(0.2, 0.8, 0.4, 1)  # 绿色

# 小游戏按钮点击
func _on_mini_game_clicked():
	print("进入记忆训练小游戏（后续扩展）")
	# TODO: 这里可以加载小游戏场景
	# get_tree().change_scene_to_file("res://scenes/mini_game_memory.tscn")
	# 或者发送信号给主场景
	close_panel()

# 关闭按钮点击
func _on_close_clicked():
	close_panel()
