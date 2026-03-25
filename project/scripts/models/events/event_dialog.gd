extends Panel

# 信号：告诉 EventHandler 玩家选了哪个选项
signal option_selected(event_id: String, option_index: int, effects: Dictionary)

# 获取子节点引用
@onready var title_label = $TitleLabel
@onready var desc_label = $DescLabel
@onready var button_container = $ButtonContainer
@onready var result_panel = $ResultPanel
@onready var result_label = $ResultPanel/ResultLabel
@onready var close_button = $CloseButton

# 存储当前事件数据
var current_event_id: String = ""
var current_options: Array = []

func _ready():
	# 连接关闭按钮信号
	close_button.pressed.connect(_on_close_pressed)
	
	# 初始隐藏
	close_button.visible = false
	result_panel.visible = false
	
	# 设置 ResultPanel 的样式（确保能看到）
	_setup_result_panel_style()
	
	# 隐藏整个对话框
	hide()

# 设置 ResultPanel 的样式，确保文字可见
func _setup_result_panel_style():
	# 给 ResultPanel 设置一个背景色
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)  # 深色半透明背景
	style.set_corner_radius_all(10)  # 圆角
	result_panel.add_theme_stylebox_override("panel", style)
	
	# 设置 ResultLabel 的文字颜色为白色
	result_label.add_theme_color_override("font_color", Color(1, 1, 1))
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# 设置 ResultPanel 的大小
	result_panel.size = Vector2(400, 150)

# 显示事件
func show_event(event_data: Dictionary):
	print("EventDialog: 开始显示事件")
	
	# 保存事件数据
	current_event_id = event_data.get("event_id", event_data.get("id", "unknown"))
	current_options = event_data.get("options", [])
	
	# 设置标题和描述
	title_label.text = event_data.get("title", "事件")
	desc_label.text = event_data.get("description", event_data.get("dialog", ""))
	
	# 设置选项按钮
	_setup_option_buttons()
	
	# 重置显示状态
	result_panel.visible = false
	close_button.visible = false
	button_container.visible = true
	
	# 显示面板
	show()
	
	# 确保对话框在最上层
	z_index = 100
	
	print("显示事件: ", title_label.text)

# 根据选项数量设置按钮
func _setup_option_buttons():
	var buttons = button_container.get_children()
	
	# 先隐藏所有按钮
	for btn in buttons:
		btn.visible = false
	
	# 根据实际选项数量显示按钮
	for i in range(current_options.size()):
		if i < buttons.size():
			var btn = buttons[i]
			var option = current_options[i]
			
			btn.visible = true
			btn.text = option.get("text", "选项 " + str(i + 1))
			
			# 检查选项是否可用
			if option.get("unavailable", false):
				btn.disabled = true
				print("选项 ", i, " 不可用: ", btn.text)
			else:
				btn.disabled = false
			
			# 断开旧连接避免重复
			if btn.pressed.is_connected(_on_option_pressed):
				btn.pressed.disconnect(_on_option_pressed)
			# 绑定新连接，传递选项索引
			btn.pressed.connect(_on_option_pressed.bind(i))
	
	print("设置了 ", current_options.size(), " 个选项按钮")

# 玩家点击选项
func _on_option_pressed(option_index: int):
	var option = current_options[option_index]
	
	# 如果选项不可用，不处理
	if option.get("unavailable", false):
		return
	
	print("玩家选择了选项: ", option.get("text"))
	
	# 构建结果文本，包含资源变化信息
	var result_text = option.get("result_text", "你做出了选择")
	var effects = option.get("effects", {})
	
	# 在结果文本中添加资源变化详情
	if effects.size() > 0:
		result_text += "\n\n【资源变化】"
		for key in effects:
			var delta = effects[key]
			var delta_text = ""
			if delta > 0:
				delta_text = "+" + str(delta)
			else:
				delta_text = str(delta)
			
			match key:
				"money":
					result_text += "\n💰 资金: " + delta_text
				"reputation":
					result_text += "\n⭐ 声誉: " + delta_text
				"cohesion":
					result_text += "\n🤝 凝聚力: " + delta_text
				"creativity":
					result_text += "\n🎨 创造力: " + delta_text
				"art_weight":
					result_text += "\n🎭 艺术权重: " + delta_text
				"business_weight":
					result_text += "\n💼 商业权重: " + delta_text
				"human_weight":
					result_text += "\n❤️ 人情权重: " + delta_text
	
	# 显示结果文本
	result_label.text = result_text
	result_panel.visible = true
	
	# 隐藏选项按钮
	button_container.visible = false
	
	# 显示关闭按钮
	close_button.visible = true
	
	# 发射信号，让 EventHandler 处理数值变化
	option_selected.emit(
		current_event_id,
		option_index,
		effects
	)

# 关闭对话框
func _on_close_pressed():
	print("EventDialog: 关闭对话框")
	hide()
	
	# 先切换回主场景
	get_tree().change_scene_to_file("res://project/scenes/main/Main.tscn")
	
	# 延迟删除对话框
	call_deferred("queue_free")
