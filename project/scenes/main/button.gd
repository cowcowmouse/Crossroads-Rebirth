extends Button

var has_been_clicked: bool = false
var tutorial_overlay: Control = null

func _ready():
	pressed.connect(_on_button_pressed)
	_check_and_update_visibility()

func _check_and_update_visibility():
	var game_manager = get_node("/root/GameManager")
	if not game_manager:
		return
	
	var current_week = game_manager.get_current_week()
	
	if current_week == 1 and not has_been_clicked:
		visible = true
	else:
		visible = false

func _on_button_pressed():
	if has_been_clicked:
		return
	
	has_been_clicked = true
	print("🔥 按钮点到了！准备启动对话: old_nail")
	
	# 隐藏自身按钮
	visible = false
	
	# 启动 Dialogic 对话
	Dialogic.start("old_nail")
	
	# 等待对话结束
	await Dialogic.timeline_ended
	print("Dialogic 对话结束")
	
	# 对话结束后显示新手教程
	_show_tutorial_dialog()

func _show_tutorial_dialog():
	print("显示新手教程对话框")
	
	# 获取屏幕尺寸
	var screen_size = get_viewport().get_visible_rect().size
	
	# 全屏遮罩层
	tutorial_overlay = Control.new()
	tutorial_overlay.anchor_right = 1.0
	tutorial_overlay.anchor_bottom = 1.0
	tutorial_overlay.z_index = 200
	
	# 半透明背景
	var dark_bg = ColorRect.new()
	dark_bg.anchor_right = 1.0
	dark_bg.anchor_bottom = 1.0
	dark_bg.color = Color(0, 0, 0, 0.6)
	tutorial_overlay.add_child(dark_bg)
	
	# ========== 对话框容器（绝对位置，基于屏幕左上角）==========
	var dialog_panel = Panel.new()
	
	# 直接使用绝对坐标（不依赖锚点）
	var panel_x = -350      # 距离屏幕左边 100px
	var panel_y = -100      # 距离屏幕顶部 300px
	var panel_width = 700
	var panel_height = 320
	
	dialog_panel.position = Vector2(panel_x, panel_y)
	dialog_panel.size = Vector2(panel_width, panel_height)
	dialog_panel.z_index = 210
	
	# 对话框样式
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.05, 0.95)
	panel_style.border_color = Color(0.8, 0.6, 0.3, 0.8)
	panel_style.border_width_top = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.set_corner_radius_all(16)
	dialog_panel.add_theme_stylebox_override("panel", panel_style)
	
	# ========== 文字内容 ==========
	var text_label = Label.new()
	text_label.text = "新手指导\n\n📌 点击左右箭头切换场景\n📌 点击右下角按钮切换周阶段\n📌 点击设施图标可进行升级\n\n祝你经营顺利！"
	text_label.position = Vector2(40, 40)
	text_label.size = Vector2(panel_width - 80, 180)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	text_label.add_theme_font_size_override("font_size", 20)
	text_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.75, 1.0))
	text_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	text_label.add_theme_constant_override("outline_size", 4)
	
	# ========== 高亮箭头 ==========
	var arrow_label = Label.new()
	arrow_label.text = "▼"
	arrow_label.position = Vector2(panel_width / 2 - 20, 250)
	arrow_label.size = Vector2(40, 40)
	arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow_label.add_theme_font_size_override("font_size", 28)
	arrow_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3, 1.0))
	
	# ========== 继续按钮 ==========
	var continue_button = Button.new()
	continue_button.text = "点击继续"
	continue_button.position = Vector2(panel_width / 2 - 90, 280)
	continue_button.size = Vector2(180, 45)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.4, 0.25, 0.12, 1.0)
	btn_style.border_color = Color(0.9, 0.7, 0.3, 1.0)
	btn_style.border_width_left = 2
	btn_style.border_width_top = 2
	btn_style.border_width_right = 2
	btn_style.border_width_bottom = 2
	btn_style.set_corner_radius_all(12)
	
	var btn_hover_style = btn_style.duplicate()
	btn_hover_style.bg_color = Color(0.55, 0.35, 0.18, 1.0)
	
	continue_button.add_theme_stylebox_override("normal", btn_style)
	continue_button.add_theme_stylebox_override("hover", btn_hover_style)
	continue_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	continue_button.add_theme_font_size_override("font_size", 18)
	
	# 组装到对话框
	dialog_panel.add_child(text_label)
	dialog_panel.add_child(arrow_label)
	dialog_panel.add_child(continue_button)
	tutorial_overlay.add_child(dialog_panel)
	
	# 添加到当前场景
	get_tree().current_scene.add_child(tutorial_overlay)
	
	await continue_button.pressed
	tutorial_overlay.queue_free()
	print("新手教程结束")
