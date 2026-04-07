# 周中事件系统测试场景（独立功能测试面板）
# 功能：输入方向值 → 展示当前事件池 → 触发事件 → 弹出选项对话框 → 验证后台数据变动
# 新增：阶段设置、连锁事件追踪、已触发/已解锁事件列表
extends Control

# UI引用
var art_input: LineEdit
var business_input: LineEdit
var human_input: LineEdit
var cohesion_input: LineEdit
var money_input: LineEdit
var creativity_input: LineEdit
var log_label: RichTextLabel
var resource_panel_labels: Dictionary = {}
var pool_info_label: Label
var stage_option: OptionButton
var triggered_list_label: RichTextLabel
var unlocked_list_label: RichTextLabel

# 事件对话框相关
var event_dialog_overlay: ColorRect
var event_dialog_panel: PanelContainer
var event_title_label: Label
var event_desc_label: Label
var event_options_container: VBoxContainer
var event_result_label: Label
var event_close_btn: Button
var current_event_data: Dictionary = {}

# 连锁事件测试
var chain_event_selector: OptionButton



func _ready():
	# 设置根节点为全屏
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	
	# 直接使用自动加载的全局单例
	# Constants, SignalBus, ResourceManager, EventManager 应该已经在项目中设置为自动加载
	
	# 连接信号
	if EventManager.has_signal("event_pool_determined"):
		EventManager.event_pool_determined.connect(_on_pool_determined)
	if EventManager.has_signal("event_effects_applied"):
		EventManager.event_effects_applied.connect(func(_e): _update_resource_display())
	if EventBus.has_signal("core_resource_changed"):
		EventBus.core_resource_changed.connect(func(_a, _b, _c): _update_resource_display())
	
	_build_ui()
	_build_event_dialog()
	_update_resource_display()
	_log("[color=cyan]测试场景就绪。[/color]")
	_log("1. 设置方向值 → 确定事件池")
	_log("2. 设置资源值 → 测试条件触发")
	_log("3. 点击「触发周中事件」→ 弹出事件选项")

# ===================== 主界面搭建 =====================

func _build_ui():
	# 背景色
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0)
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	
	# 主布局：水平分两栏
	var main_hbox = HBoxContainer.new()
	main_hbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	main_hbox.add_theme_constant_override("separation", 16)
	# 添加内边距
	main_hbox.offset_left = 24
	main_hbox.offset_top = 24
	main_hbox.offset_right = -24
	main_hbox.offset_bottom = -24
	add_child(main_hbox)
	
	# ========== 左栏：控制面板 ==========
	var left_panel = PanelContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_stretch_ratio = 0.45
	main_hbox.add_child(left_panel)
	
	var left_margin = MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 16)
	left_margin.add_theme_constant_override("margin_right", 16)
	left_margin.add_theme_constant_override("margin_top", 12)
	left_margin.add_theme_constant_override("margin_bottom", 12)
	left_panel.add_child(left_margin)
	
	var left_vbox = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 8)
	left_margin.add_child(left_vbox)
	
	# --- 标题 ---
	var title = Label.new()
	title.text = "🎸 周中事件系统测试"
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_vbox.add_child(title)
	
	left_vbox.add_child(HSeparator.new())
	
	# --- 方向值设置区 ---
	var dir_header = Label.new()
	dir_header.text = "【方向值设置】影响事件池选择"
	dir_header.add_theme_font_size_override("font_size", 16)
	dir_header.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	left_vbox.add_child(dir_header)
	
	var dir_grid = GridContainer.new()
	dir_grid.columns = 3
	dir_grid.add_theme_constant_override("h_separation", 12)
	dir_grid.add_theme_constant_override("v_separation", 6)
	left_vbox.add_child(dir_grid)
	
	art_input = _add_grid_input(dir_grid, "🎭 艺术:", "30")
	business_input = _add_grid_input(dir_grid, "💼 商业:", "30")
	human_input = _add_grid_input(dir_grid, "❤️ 人情:", "30")
	
	var set_dir_btn = Button.new()
	set_dir_btn.text = "✅ 应用方向值"
	set_dir_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	set_dir_btn.custom_minimum_size.y = 36
	set_dir_btn.pressed.connect(_on_set_direction_pressed)
	left_vbox.add_child(set_dir_btn)
	
	left_vbox.add_child(HSeparator.new())
	
	# --- 资源值设置区 ---
	var res_header = Label.new()
	res_header.text = "【资源值设置】测试事件条件"
	res_header.add_theme_font_size_override("font_size", 16)
	res_header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	left_vbox.add_child(res_header)
	
	var res_grid = GridContainer.new()
	res_grid.columns = 3
	res_grid.add_theme_constant_override("h_separation", 12)
	res_grid.add_theme_constant_override("v_separation", 6)
	left_vbox.add_child(res_grid)
	
	cohesion_input = _add_grid_input(res_grid, "🤝 凝聚力:", "60")
	money_input = _add_grid_input(res_grid, "💰 资  金:", "5000")
	creativity_input = _add_grid_input(res_grid, "🎨 创造力:", "50")
	
	var set_res_btn = Button.new()
	set_res_btn.text = "✅ 应用资源值"
	set_res_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	set_res_btn.custom_minimum_size.y = 36
	set_res_btn.pressed.connect(_on_set_resources_pressed)
	left_vbox.add_child(set_res_btn)
	
	# --- 阶段设置区 ---
	var stage_header = Label.new()
	stage_header.text = "【阶段设置】影响事件影响程度"
	stage_header.add_theme_font_size_override("font_size", 16)
	stage_header.add_theme_color_override("font_color", Color(0.85, 0.6, 1.0))
	left_vbox.add_child(stage_header)
	
	var stage_hbox = HBoxContainer.new()
	stage_hbox.add_theme_constant_override("separation", 8)
	left_vbox.add_child(stage_hbox)
	
	var stage_lbl = Label.new()
	stage_lbl.text = "阶段:"
	stage_lbl.add_theme_font_size_override("font_size", 16)
	stage_hbox.add_child(stage_lbl)
	
	stage_option = OptionButton.new()
	stage_option.add_item("阶段1 (前期)", 1)
	stage_option.add_item("阶段2 (中期)", 2)
	stage_option.add_item("阶段3 (后期)", 3)
	stage_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_option.item_selected.connect(_on_stage_selected)
	stage_hbox.add_child(stage_option)
	
	# --- 快捷按钮 ---
	var quick_header = Label.new()
	quick_header.text = "【快捷预设】"
	quick_header.add_theme_font_size_override("font_size", 14)
	quick_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	left_vbox.add_child(quick_header)
	
	var quick_grid = GridContainer.new()
	quick_grid.columns = 2
	quick_grid.add_theme_constant_override("h_separation", 8)
	quick_grid.add_theme_constant_override("v_separation", 4)
	left_vbox.add_child(quick_grid)
	
	_add_quick_btn(quick_grid, "凝聚力→30", func(): _quick_set_resource("cohesion", 30))
	_add_quick_btn(quick_grid, "凝聚力→70", func(): _quick_set_resource("cohesion", 70))
	_add_quick_btn(quick_grid, "资金→1000", func(): _quick_set_resource("money", 1000))
	_add_quick_btn(quick_grid, "资金→8000", func(): _quick_set_resource("money", 8000))
	_add_quick_btn(quick_grid, "创造力→20", func(): _quick_set_resource("creativity", 20))
	_add_quick_btn(quick_grid, "创造力→80", func(): _quick_set_resource("creativity", 80))
	
	left_vbox.add_child(HSeparator.new())
	
	# --- 连锁/重置按钮 ---
	var chain_header = Label.new()
	chain_header.text = "【连锁事件测试】"
	chain_header.add_theme_font_size_override("font_size", 14)
	chain_header.add_theme_color_override("font_color", Color(1.0, 0.6, 0.6))
	left_vbox.add_child(chain_header)
	
	# 连锁事件下拉选择 + 触发按钮
	var chain_test_hbox = HBoxContainer.new()
	chain_test_hbox.add_theme_constant_override("separation", 6)
	left_vbox.add_child(chain_test_hbox)
	
	chain_event_selector = OptionButton.new()
	chain_event_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chain_event_selector.custom_minimum_size.y = 32
	chain_test_hbox.add_child(chain_event_selector)
	_populate_chain_selector()
	
	var chain_trigger_btn = Button.new()
	chain_trigger_btn.text = "🔗 触发"
	chain_trigger_btn.custom_minimum_size = Vector2(80, 32)
	chain_trigger_btn.pressed.connect(_on_trigger_chain_pressed)
	chain_test_hbox.add_child(chain_trigger_btn)
	
	# 解锁全部前置 + 逐步推进按钮
	var chain_btn_grid = GridContainer.new()
	chain_btn_grid.columns = 2
	chain_btn_grid.add_theme_constant_override("h_separation", 6)
	chain_btn_grid.add_theme_constant_override("v_separation", 4)
	left_vbox.add_child(chain_btn_grid)
	
	var unlock_all_btn = Button.new()
	unlock_all_btn.text = "🔓 解锁全部前置"
	unlock_all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unlock_all_btn.custom_minimum_size.y = 30
	unlock_all_btn.pressed.connect(_on_unlock_all_chain_prereqs)
	chain_btn_grid.add_child(unlock_all_btn)
	
	var walk_chain_btn = Button.new()
	walk_chain_btn.text = "⏩ 逐步走完整条链"
	walk_chain_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	walk_chain_btn.custom_minimum_size.y = 30
	walk_chain_btn.pressed.connect(_on_walk_chain_pressed)
	chain_btn_grid.add_child(walk_chain_btn)
	
	var reset_btn = Button.new()
	reset_btn.text = "🔄 重置已触发事件记录"
	reset_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_btn.custom_minimum_size.y = 32
	reset_btn.pressed.connect(func():
		EventManager.reset_triggered_events()
		_update_chain_display()
		_populate_chain_selector()
		_log("[color=red]已重置所有事件触发记录！[/color]")
	)
	left_vbox.add_child(reset_btn)
	
	left_vbox.add_child(HSeparator.new())
	
	# --- 触发按钮 ---
	var trigger_btn = Button.new()
	trigger_btn.text = "⚡ 触发周中事件"
	trigger_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trigger_btn.custom_minimum_size.y = 52
	trigger_btn.add_theme_font_size_override("font_size", 20)
	trigger_btn.pressed.connect(_on_trigger_event_pressed)
	left_vbox.add_child(trigger_btn)
	
	var trigger_multi_btn = Button.new()
	trigger_multi_btn.text = "🔄 连续触发5次（验证随机性）"
	trigger_multi_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trigger_multi_btn.custom_minimum_size.y = 38
	trigger_multi_btn.pressed.connect(_on_trigger_multi_pressed)
	left_vbox.add_child(trigger_multi_btn)
	
	# ========== 右栏：数据 + 日志 ==========
	var right_vbox = VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.size_flags_stretch_ratio = 0.55
	right_vbox.add_theme_constant_override("separation", 12)
	main_hbox.add_child(right_vbox)
	
	# --- 资源实时面板 ---
	var res_panel = PanelContainer.new()
	res_panel.custom_minimum_size.y = 200
	right_vbox.add_child(res_panel)
	
	var res_margin = MarginContainer.new()
	res_margin.add_theme_constant_override("margin_left", 16)
	res_margin.add_theme_constant_override("margin_right", 16)
	res_margin.add_theme_constant_override("margin_top", 10)
	res_margin.add_theme_constant_override("margin_bottom", 10)
	res_panel.add_child(res_margin)
	
	var res_inner_vbox = VBoxContainer.new()
	res_inner_vbox.add_theme_constant_override("separation", 2)
	res_margin.add_child(res_inner_vbox)
	
	var res_panel_title = Label.new()
	res_panel_title.text = "📊 后台数据实时面板"
	res_panel_title.add_theme_font_size_override("font_size", 18)
	res_panel_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	res_inner_vbox.add_child(res_panel_title)
	
	res_inner_vbox.add_child(HSeparator.new())
	
	# 两列布局显示资源
	var data_hbox = HBoxContainer.new()
	data_hbox.add_theme_constant_override("separation", 32)
	res_inner_vbox.add_child(data_hbox)
	
	var col1 = VBoxContainer.new()
	col1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col1.add_theme_constant_override("separation", 4)
	data_hbox.add_child(col1)
	
	var col2 = VBoxContainer.new()
	col2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col2.add_theme_constant_override("separation", 4)
	data_hbox.add_child(col2)
	
	var label_configs_col1 = [
		["MoneyLabel", "💰 资金:"],
		["ReputationLabel", "⭐ 声誉:"],
		["CohesionLabel", "🤝 凝聚力:"],
		["CreativityLabel", "🎨 创造力:"],
	]
	var label_configs_col2 = [
		["MemoryLabel", "🧠 记忆恢复:"],
		["ArtWeightLabel", "🎭 艺术方向:"],
		["BusinessWeightLabel", "💼 商业方向:"],
		["HumanWeightLabel", "❤️ 人情方向:"],
	]
	
	for config in label_configs_col1:
		var lbl = Label.new()
		lbl.name = config[0]
		lbl.add_theme_font_size_override("font_size", 16)
		col1.add_child(lbl)
		resource_panel_labels[config[0]] = lbl
	
	for config in label_configs_col2:
		var lbl = Label.new()
		lbl.name = config[0]
		lbl.add_theme_font_size_override("font_size", 16)
		col2.add_child(lbl)
		resource_panel_labels[config[0]] = lbl
	
	# --- 事件池信息 ---
	pool_info_label = Label.new()
	pool_info_label.text = "🎯 当前事件池: (未确定)"
	pool_info_label.add_theme_font_size_override("font_size", 18)
	pool_info_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
	pool_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_vbox.add_child(pool_info_label)
	
	# --- 日志区 ---
	var log_header_hbox = HBoxContainer.new()
	right_vbox.add_child(log_header_hbox)
	
	var log_header = Label.new()
	log_header.text = "📋 事件日志"
	log_header.add_theme_font_size_override("font_size", 16)
	log_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_header_hbox.add_child(log_header)
	
	var clear_log_btn = Button.new()
	clear_log_btn.text = "清空"
	clear_log_btn.custom_minimum_size = Vector2(60, 28)
	clear_log_btn.pressed.connect(func(): log_label.text = "")
	log_header_hbox.add_child(clear_log_btn)
	
	log_label = RichTextLabel.new()
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_label.size_flags_stretch_ratio = 0.6
	log_label.bbcode_enabled = true
	log_label.scroll_following = true
	right_vbox.add_child(log_label)
	
	# --- 连锁事件追踪面板 ---
	var chain_panel = PanelContainer.new()
	chain_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chain_panel.size_flags_stretch_ratio = 0.4
	right_vbox.add_child(chain_panel)
	
	var chain_margin = MarginContainer.new()
	chain_margin.add_theme_constant_override("margin_left", 10)
	chain_margin.add_theme_constant_override("margin_right", 10)
	chain_margin.add_theme_constant_override("margin_top", 6)
	chain_margin.add_theme_constant_override("margin_bottom", 6)
	chain_panel.add_child(chain_margin)
	
	var chain_vbox = VBoxContainer.new()
	chain_vbox.add_theme_constant_override("separation", 4)
	chain_margin.add_child(chain_vbox)
	
	var chain_title = Label.new()
	chain_title.text = "🔗 连锁事件追踪"
	chain_title.add_theme_font_size_override("font_size", 15)
	chain_title.add_theme_color_override("font_color", Color(1.0, 0.7, 0.5))
	chain_vbox.add_child(chain_title)
	
	var triggered_header = Label.new()
	triggered_header.text = "已触发事件:"
	triggered_header.add_theme_font_size_override("font_size", 13)
	chain_vbox.add_child(triggered_header)
	
	triggered_list_label = RichTextLabel.new()
	triggered_list_label.bbcode_enabled = true
	triggered_list_label.fit_content = true
	triggered_list_label.custom_minimum_size = Vector2(0, 30)
	triggered_list_label.add_theme_font_size_override("normal_font_size", 12)
	chain_vbox.add_child(triggered_list_label)
	
	var unlocked_header = Label.new()
	unlocked_header.text = "已解锁后续事件:"
	unlocked_header.add_theme_font_size_override("font_size", 13)
	chain_vbox.add_child(unlocked_header)
	
	unlocked_list_label = RichTextLabel.new()
	unlocked_list_label.bbcode_enabled = true
	unlocked_list_label.fit_content = true
	unlocked_list_label.custom_minimum_size = Vector2(0, 30)
	unlocked_list_label.add_theme_font_size_override("normal_font_size", 12)
	chain_vbox.add_child(unlocked_list_label)
	
	# --- 返回按钮---
	var back_button = Button.new()
	back_button.text = "← 返回主菜单"
	back_button.custom_minimum_size = Vector2(140, 40)
	
	# 必须设置锚点为右下角
	back_button.anchor_left = 1.0
	back_button.anchor_right = 1.0
	back_button.anchor_top = 1.0
	back_button.anchor_bottom = 1.0
	
	# 现在修改偏移才会生效
	back_button.offset_left = -164   # 按钮宽度 + 右边距
	back_button.offset_right = -100  # 距离右边100像素
	back_button.offset_top = -64     # 按钮高度 + 底边距  
	back_button.offset_bottom = -100 # 距离底边100像素
	
	back_button.pressed.connect(_on_back_button_pressed)
	add_child(back_button)
	
# ===================== 事件对话框 =====================

func _build_event_dialog():
	# 全屏半透明遮罩
	event_dialog_overlay = ColorRect.new()
	event_dialog_overlay.color = Color(0, 0, 0, 0.6)
	event_dialog_overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	event_dialog_overlay.visible = false
	event_dialog_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(event_dialog_overlay)
	
	# 居中对话框容器
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	event_dialog_overlay.add_child(center)
	
	event_dialog_panel = PanelContainer.new()
	event_dialog_panel.custom_minimum_size = Vector2(700, 400)
	center.add_child(event_dialog_panel)
	
	var dialog_margin = MarginContainer.new()
	dialog_margin.add_theme_constant_override("margin_left", 28)
	dialog_margin.add_theme_constant_override("margin_right", 28)
	dialog_margin.add_theme_constant_override("margin_top", 20)
	dialog_margin.add_theme_constant_override("margin_bottom", 20)
	event_dialog_panel.add_child(dialog_margin)
	
	var dialog_vbox = VBoxContainer.new()
	dialog_vbox.add_theme_constant_override("separation", 12)
	dialog_margin.add_child(dialog_vbox)
	
	# 事件标题
	event_title_label = Label.new()
	event_title_label.add_theme_font_size_override("font_size", 24)
	event_title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	event_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_vbox.add_child(event_title_label)
	
	dialog_vbox.add_child(HSeparator.new())
	
	# 事件描述
	event_desc_label = Label.new()
	event_desc_label.add_theme_font_size_override("font_size", 17)
	event_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_desc_label.custom_minimum_size.y = 60
	dialog_vbox.add_child(event_desc_label)
	
	# 选项按钮容器
	var options_header = Label.new()
	options_header.text = "请选择："
	options_header.add_theme_font_size_override("font_size", 16)
	options_header.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	dialog_vbox.add_child(options_header)
	
	event_options_container = VBoxContainer.new()
	event_options_container.add_theme_constant_override("separation", 8)
	dialog_vbox.add_child(event_options_container)
	
	# 结果文本（选择后显示）
	event_result_label = Label.new()
	event_result_label.add_theme_font_size_override("font_size", 16)
	event_result_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	event_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_result_label.visible = false
	dialog_vbox.add_child(event_result_label)
	
	# 关闭按钮（选择后显示）
	event_close_btn = Button.new()
	event_close_btn.text = "确认关闭"
	event_close_btn.custom_minimum_size = Vector2(200, 42)
	event_close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	event_close_btn.add_theme_font_size_override("font_size", 16)
	event_close_btn.visible = false
	event_close_btn.pressed.connect(_on_event_dialog_close)
	dialog_vbox.add_child(event_close_btn)

func _show_event_dialog(event_data: Dictionary):
	current_event_data = event_data
	
	event_title_label.text = "📌 " + event_data.get("title", "未知事件")
	event_desc_label.text = event_data.get("description", "")
	event_result_label.visible = false
	event_close_btn.visible = false
	
	# 清除旧按钮
	for child in event_options_container.get_children():
		child.queue_free()
	
	# 创建选项按钮
	var options = event_data.get("options", [])
	for i in range(options.size()):
		var opt = options[i]
		var btn = Button.new()
		btn.text = "【%d】%s" % [i + 1, opt.get("text", "选项")]
		btn.custom_minimum_size.y = 44
		btn.add_theme_font_size_override("font_size", 16)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# 阶段2及以后不显示效果数值预览
		if EventManager.get_current_stage() < 2:
			var effects = opt.get("effects", {})
			var effect_strs = []
			for key in effects:
				var val = effects[key]
				var display_name = _get_effect_display_name(key)
				effect_strs.append("%s %+d" % [display_name, val])
			if effect_strs.size() > 0:
				btn.tooltip_text = "效果: " + ", ".join(effect_strs)
		
		btn.pressed.connect(_on_event_option_chosen.bind(i))
		event_options_container.add_child(btn)
	
	event_dialog_overlay.visible = true

func _on_event_option_chosen(option_index: int):
	var options = current_event_data.get("options", [])
	if option_index >= options.size():
		return
	
	var chosen = options[option_index]
	
	# 隐藏选项按钮
	for child in event_options_container.get_children():
		child.visible = false
	
	# 记录变动前
	var before = {
		"money": ResourceManager.get_resource_value("money"),
		"reputation": ResourceManager.get_resource_value("reputation"),
		"cohesion": ResourceManager.get_resource_value("cohesion"),
		"creativity": ResourceManager.get_resource_value("creativity"),
	}
	
	# 应用效果
	EventManager.apply_option_effects(chosen)
	
	# 记录变动后
	var after = {
		"money": ResourceManager.get_resource_value("money"),
		"reputation": ResourceManager.get_resource_value("reputation"),
		"cohesion": ResourceManager.get_resource_value("cohesion"),
		"creativity": ResourceManager.get_resource_value("creativity"),
	}
	
	# 显示结果
	var result_text = chosen.get("result_text", "你做出了选择。")
	var change_lines = []
	for key in before:
		if before[key] != after[key]:
			var delta = after[key] - before[key]
			var display = _get_effect_display_name(key)
			change_lines.append("  %s: %d → %d (%+d)" % [display, before[key], after[key], delta])
	
	if change_lines.size() > 0:
		result_text += "\n\n数据变动:\n" + "\n".join(change_lines)
	
	event_result_label.text = result_text
	event_result_label.visible = true
	event_close_btn.visible = true
	
	# 写入日志
	_log("[color=lime]选择: %s[/color]" % chosen.get("text", "?"))
	_log("[color=lime]结果: %s[/color]" % chosen.get("result_text", ""))
	for line in change_lines:
		_log("[color=lime]%s[/color]" % line)
	
	# 显示解锁信息
	var unlocks = chosen.get("unlocks", [])
	for uid in unlocks:
		_log("[color=orange]🔗 解锁连锁事件: %s[/color]" % str(uid))
	
	_update_resource_display()
	_update_chain_display()

func _on_event_dialog_close():
	event_dialog_overlay.visible = false

func _get_effect_display_name(key: String) -> String:
	match key:
		"money": return "💰资金"
		"reputation": return "⭐声誉"
		"cohesion": return "🤝凝聚力"
		"creativity": return "🎨创造力"
		"memory_recovery": return "🧠记忆"
		"art_weight": return "🎭艺术"
		"business_weight": return "💼商业"
		"human_weight": return "❤️人情"
		_: return key

# ===================== UI辅助 =====================

func _add_grid_input(grid: GridContainer, label_text: String, default_val: String) -> LineEdit:
	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 16)
	grid.add_child(lbl)
	
	var input = LineEdit.new()
	input.text = default_val
	input.custom_minimum_size = Vector2(90, 32)
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(input)
	
	# 第三列占位
	var spacer = Control.new()
	grid.add_child(spacer)
	
	return input

func _add_quick_btn(container: GridContainer, text: String, callback: Callable):
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 30)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(callback)
	container.add_child(btn)

# ===================== 按钮回调 =====================

func _on_set_direction_pressed():
	var art = int(art_input.text)
	var business = int(business_input.text)
	var human = int(human_input.text)
	
	EventManager.set_direction_values(art, business, human)
	_update_resource_display()
	
	var pool = EventManager.determine_event_pool()
	pool_info_label.text = "🎯 当前事件池: " + _get_pool_display_name(pool)
	
	_log("[color=cyan]方向值已设置: 艺术=%d 商业=%d 人情=%d → 事件池: %s[/color]" % [art, business, human, pool])

func _on_set_resources_pressed():
	var cohesion_val = int(cohesion_input.text)
	var money_val = int(money_input.text)
	var creativity_val = int(creativity_input.text)
	
	EventManager.set_resource_value("cohesion", cohesion_val)
	EventManager.set_resource_value("money", money_val)
	EventManager.set_resource_value("creativity", creativity_val)
	_update_resource_display()
	
	_log("[color=yellow]资源值已设置: 凝聚力=%d 资金=%d 创造力=%d[/color]" % [cohesion_val, money_val, creativity_val])

func _quick_set_resource(res_name: String, value: int):
	EventManager.set_resource_value(res_name, value)
	_update_resource_display()
	_log("[color=yellow]快捷设置: %s → %d[/color]" % [_get_effect_display_name(res_name), value])

func _on_trigger_event_pressed():
	_log("\n[color=white]══════ 触发周中事件 (阶段:%d) ══════[/color]" % EventManager.get_current_stage())
	
	var event_data = EventManager.trigger_midweek_event()
	
	if event_data.is_empty():
		_log("[color=red]❌ 没有可触发的事件![/color]")
		return
	
	# 日志输出
	_log("[color=green]事件池: %s[/color]" % EventManager.last_triggered_pool)
	_log("[color=green]合格事件:[/color]")
	for evt in EventManager.last_eligible_events:
		var cond = evt.get("trigger_conditions", {})
		var cond_str = "无条件" if cond.is_empty() else str(cond)
		var req = evt.get("requires_event", "")
		var req_str = "" if req == "" else " [需前置:%s]" % req
		var stage_str = ""
		if evt.get("stage", 0) > 0:
			stage_str = " [限阶段%d]" % evt.get("stage")
		elif evt.get("min_stage", 0) > 0 or evt.get("max_stage", 0) > 0:
			stage_str = " [阶段%d-%d]" % [evt.get("min_stage", 1), evt.get("max_stage", 3)]
		var repeat_str = " [可重复]" if evt.get("repeatable", false) else ""
		_log("  • %s (权重:%d) %s%s%s%s" % [evt.get("title", "?"), evt.get("weight", 0), cond_str, req_str, stage_str, repeat_str])
	
	_log("[color=orange]>>> 触发: 【%s】%s[/color]" % [event_data.get("id", "?"), event_data.get("title", "?")])
	
	_update_chain_display()
	
	# 弹出事件对话框让玩家选择
	_show_event_dialog(event_data)

func _on_trigger_multi_pressed():
	_log("\n[color=white]══════ 连续触发5次 ══════[/color]")
	var results = {}
	
	for i in range(5):
		var event_data = EventManager.trigger_midweek_event()
		if not event_data.is_empty():
			var eid = event_data.get("id", "unknown")
			var title = event_data.get("title", "?")
			if not results.has(eid):
				results[eid] = {"title": title, "count": 0}
			results[eid]["count"] += 1
	
	_log("[color=orange]触发统计:[/color]")
	for eid in results:
		_log("  %s (%s): %d次" % [results[eid]["title"], eid, results[eid]["count"]])
	if results.size() > 1:
		_log("[color=cyan]✅ 随机性验证通过（触发了不同事件）[/color]")
	else:
		_log("[color=yellow]⚠ 仅触发了1种事件，可多试几次[/color]")

# ===================== 连锁事件测试 =====================

func _populate_chain_selector():
	if not chain_event_selector:
		return
	chain_event_selector.clear()
	var chain_events = EventManager.get_all_chain_events()
	for evt in chain_events:
		var eid = evt.get("id", "?")
		var title = evt.get("title", "?")
		var req = evt.get("requires_event", "")
		var status = ""
		if EventManager.is_event_triggered(eid):
			status = " ✅"
		elif req != "" and not EventManager.is_event_unlocked(eid):
			status = " 🔒"
		else:
			status = " ⬜"
		chain_event_selector.add_item("%s%s [%s]" % [title, status, eid])
		chain_event_selector.set_item_metadata(chain_event_selector.item_count - 1, eid)

func _on_trigger_chain_pressed():
	if chain_event_selector.selected < 0:
		_log("[color=red]请先选择一个连锁事件[/color]")
		return
	
	var event_id = chain_event_selector.get_item_metadata(chain_event_selector.selected)
	_log("\n[color=orange]══════ 测试触发连锁事件 ══════[/color]")
	
	# 自动解锁前置（测试模式）
	var chain_events = EventManager.get_all_chain_events()
	for evt in chain_events:
		if evt.get("id", "") == event_id:
			var req = evt.get("requires_event", "")
			if req != "" and not EventManager.is_event_unlocked(event_id):
				EventManager.force_unlock_event(event_id)
				_log("[color=yellow]自动解锁前置: %s[/color]" % req)
			break
	
	var event_data = EventManager.trigger_chain_event_by_id(event_id)
	if event_data.is_empty():
		_log("[color=red]❌ 未找到连锁事件: %s[/color]" % event_id)
		return
	
	_log("[color=lime]🔗 触发连锁事件: 【%s】%s[/color]" % [event_id, event_data.get("title", "?")])
	_log("[color=lime]   描述: %s[/color]" % event_data.get("description", ""))
	
	_update_chain_display()
	_populate_chain_selector()
	_show_event_dialog(event_data)

func _on_unlock_all_chain_prereqs():
	_log("\n[color=orange]══════ 解锁全部连锁前置 ══════[/color]")
	var chain_events = EventManager.get_all_chain_events()
	for evt in chain_events:
		var eid = evt.get("id", "")
		# 解锁每个连锁事件
		EventManager.force_unlock_event(eid)
		_log("[color=yellow]解锁: %s (%s)[/color]" % [evt.get("title", "?"), eid])
		# 同时标记前置事件中普通池的事件为已触发
		var req = evt.get("requires_event", "")
		if req != "":
			if not EventManager.is_event_triggered(req):
				EventManager.triggered_event_ids[req] = true
				_log("[color=yellow]标记前置已触发: %s[/color]" % req)
	
	_update_chain_display()
	_populate_chain_selector()
	_log("[color=lime]✅ 所有连锁事件的前置已解锁[/color]")

func _on_walk_chain_pressed():
	_log("\n[color=orange]══════ 逐步走完连锁链 ══════[/color]")
	var chain_events = EventManager.get_all_chain_events()
	
	# 找出当前可以触发的下一个连锁事件（前置已解锁且自身未触发）
	var next_event = null
	for evt in chain_events:
		var eid = evt.get("id", "")
		if EventManager.is_event_triggered(eid):
			continue
		var req = evt.get("requires_event", "")
		if req == "" or EventManager.is_event_unlocked(eid):
			next_event = evt
			break
	
	if next_event == null:
		_log("[color=yellow]没有可推进的连锁事件了（全部已触发或前置未解锁）[/color]")
		_log("[color=yellow]提示: 先点「解锁全部前置」再试[/color]")
		return
	
	var eid = next_event.get("id", "")
	_log("[color=lime]🔗 推进连锁: 【%s】%s[/color]" % [eid, next_event.get("title", "?")])
	
	var event_data = EventManager.trigger_chain_event_by_id(eid)
	if not event_data.is_empty():
		_update_chain_display()
		_populate_chain_selector()
		_show_event_dialog(event_data)

# ===================== 信号回调 =====================

func _on_pool_determined(pool_name: String):
	pool_info_label.text = "🎯 当前事件池: " + _get_pool_display_name(pool_name)

# ===================== 显示更新 =====================

func _update_resource_display():
	if not ResourceManager:
		return
	
	var data = {
		"MoneyLabel": "💰 资金: %d" % ResourceManager.get_resource_value("money"),
		"ReputationLabel": "⭐ 声誉: %d" % ResourceManager.get_resource_value("reputation"),
		"CohesionLabel": "🤝 凝聚力: %d" % ResourceManager.get_resource_value("cohesion"),
		"CreativityLabel": "🎨 创造力: %d" % ResourceManager.get_resource_value("creativity"),
		"MemoryLabel": "🧠 记忆恢复: %d" % ResourceManager.get_resource_value("memory_recovery"),
		"ArtWeightLabel": "🎭 艺术方向: %d" % ResourceManager.ai_weights.get("art", 0),
		"BusinessWeightLabel": "💼 商业方向: %d" % ResourceManager.ai_weights.get("business", 0),
		"HumanWeightLabel": "❤️ 人情方向: %d" % ResourceManager.ai_weights.get("human", 0),
	}
	for key in data:
		if resource_panel_labels.has(key):
			resource_panel_labels[key].text = data[key]

func _get_pool_display_name(pool_name: String) -> String:
	match pool_name:
		"low_art": return "低艺术事件池"
		"high_art": return "高艺术事件池"
		"low_business": return "低商业事件池"
		"high_business": return "高商业事件池"
		"low_human": return "低人情事件池"
		"high_human": return "高人情事件池"
		_: return pool_name

# ===================== 日志 =====================

func _log(text: String):
	if log_label:
		log_label.append_text(text + "\n")
	# 清理BBCode后输出到控制台
	var clean = text
	for tag in ["cyan", "green", "orange", "yellow", "red", "white", "lime"]:
		clean = clean.replace("[color=%s]" % tag, "").replace("[/color]", "")
	print(clean)

# ===================== 阶段/连锁 =====================

func _on_stage_selected(index: int):
	var stage = index + 1
	EventManager.set_stage(stage)
	_log("[color=cyan]阶段设置为: %d[/color]" % stage)
	_update_chain_display()

func _update_chain_display():
	if triggered_list_label:
		var triggered = EventManager.get_triggered_event_ids()
		if triggered.is_empty():
			triggered_list_label.text = "[color=gray]（无）[/color]"
		else:
			triggered_list_label.text = "[color=lime]" + ", ".join(triggered) + "[/color]"
	
	if unlocked_list_label:
		var unlocked = EventManager.get_unlocked_event_ids()
		if unlocked.is_empty():
			unlocked_list_label.text = "[color=gray]（无）[/color]"
		else:
			unlocked_list_label.text = "[color=orange]" + ", ".join(unlocked) + "[/color]"
	
func _on_back_button_pressed():
	print("返回按钮被点击！尝试切换到主场景...")
	
	# 检查文件是否存在
	var main_scene_path = "res://project/scenes/main/main.tscn"
	if ResourceLoader.exists(main_scene_path):
		print("找到主场景文件，正在切换...")
		get_tree().change_scene_to_file(main_scene_path)
	else:
		print("错误：找不到主场景文件 " + main_scene_path)
		# 可选：显示错误提示对话框
		var error_dialog = AcceptDialog.new()
		error_dialog.dialog_text = "错误：找不到主场景文件\n" + main_scene_path
		error_dialog.title = "场景切换失败"
		add_child(error_dialog)
		error_dialog.popup_centered()
