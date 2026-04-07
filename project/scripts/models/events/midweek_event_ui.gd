# 正式游戏流程中的周中事件弹窗UI
# 替代原来的黑框对话框，使用与游戏风格一致的弹窗+选项按钮
extends CanvasLayer

signal event_completed(event_id: String, option_index: int)

# 内部节点引用
var overlay: ColorRect
var panel: PanelContainer
var title_label: Label
var desc_label: RichTextLabel
var options_container: VBoxContainer
var result_container: VBoxContainer
var result_label: RichTextLabel
var confirm_btn: Button

var current_event_data: Dictionary = {}
var is_stage2_or_later: bool = false

func _ready():
	_build_ui()
	visible = false
	# 自动触发周中事件并显示（正式游戏流程从 main.gd 切换场景进入时）
	call_deferred("_auto_trigger_event")

func _auto_trigger_event():
	var event_data = EventManager.trigger_midweek_event()
	if event_data.is_empty():
		print("[MidweekEventUI] 没有可触发的事件，返回主场景")
		_return_to_main()
		return
	# 连锁事件视觉标识
	if event_data.get("requires_event", "") != "" or event_data.get("chain", "") != "":
		event_data["_is_chain"] = true
	show_event(event_data)

func _build_ui():
	# 半透明遮罩层
	overlay = ColorRect.new()
	overlay.color = Color(0.05, 0.03, 0.08, 0.75)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	
	# 居中容器
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	
	# 主面板 - 暖色调羊皮纸风格
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(780, 0)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.18, 0.14, 0.12, 0.95)
	panel_style.border_color = Color(0.55, 0.40, 0.25, 1.0)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(12)
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 8
	panel_style.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	
	# 内边距
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)
	
	# 装饰线
	var top_line = ColorRect.new()
	top_line.color = Color(0.65, 0.45, 0.25, 0.6)
	top_line.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(top_line)
	
	# 标题
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.55))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	# 分隔线
	var sep = ColorRect.new()
	sep.color = Color(0.55, 0.40, 0.25, 0.4)
	sep.custom_minimum_size = Vector2(0, 1)
	vbox.add_child(sep)
	
	# 描述文本
	desc_label = RichTextLabel.new()
	desc_label.bbcode_enabled = true
	desc_label.fit_content = true
	desc_label.custom_minimum_size = Vector2(0, 60)
	desc_label.scroll_active = false
	desc_label.add_theme_font_size_override("normal_font_size", 18)
	desc_label.add_theme_color_override("default_color", Color(0.85, 0.82, 0.75))
	vbox.add_child(desc_label)
	
	# 选项容器
	options_container = VBoxContainer.new()
	options_container.add_theme_constant_override("separation", 10)
	vbox.add_child(options_container)
	
	# 结果容器（初始隐藏）
	result_container = VBoxContainer.new()
	result_container.add_theme_constant_override("separation", 12)
	result_container.visible = false
	vbox.add_child(result_container)
	
	var result_sep = ColorRect.new()
	result_sep.color = Color(0.55, 0.40, 0.25, 0.4)
	result_sep.custom_minimum_size = Vector2(0, 1)
	result_container.add_child(result_sep)
	
	result_label = RichTextLabel.new()
	result_label.bbcode_enabled = true
	result_label.fit_content = true
	result_label.scroll_active = false
	result_label.custom_minimum_size = Vector2(0, 40)
	result_label.add_theme_font_size_override("normal_font_size", 17)
	result_label.add_theme_color_override("default_color", Color(0.7, 0.9, 0.7))
	result_container.add_child(result_label)
	
	confirm_btn = Button.new()
	confirm_btn.text = "继续"
	confirm_btn.custom_minimum_size = Vector2(180, 44)
	confirm_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	confirm_btn.add_theme_font_size_override("font_size", 18)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.35, 0.28, 0.18, 0.9)
	btn_style.border_color = Color(0.6, 0.45, 0.3)
	btn_style.set_border_width_all(2)
	btn_style.set_corner_radius_all(6)
	btn_style.set_content_margin_all(8)
	confirm_btn.add_theme_stylebox_override("normal", btn_style)
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(0.45, 0.35, 0.22, 0.95)
	confirm_btn.add_theme_stylebox_override("hover", btn_hover)
	var btn_pressed = btn_style.duplicate()
	btn_pressed.bg_color = Color(0.28, 0.22, 0.14, 0.95)
	confirm_btn.add_theme_stylebox_override("pressed", btn_pressed)
	confirm_btn.add_theme_color_override("font_color", Color(0.95, 0.85, 0.6))
	confirm_btn.pressed.connect(_on_confirm_pressed)
	result_container.add_child(confirm_btn)
	
	# 底部装饰线
	var bottom_line = ColorRect.new()
	bottom_line.color = Color(0.65, 0.45, 0.25, 0.6)
	bottom_line.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(bottom_line)

func show_event(event_data: Dictionary):
	current_event_data = event_data
	is_stage2_or_later = EventManager.get_current_stage() >= 2
	
	# 连锁事件标题加前缀和特殊颜色
	var title_text = event_data.get("title", "事件")
	if event_data.get("_is_chain", false):
		title_text = "🔗 " + title_text
		title_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.3))
		# 面板边框变为金色突显连锁事件
		var chain_style = panel.get_theme_stylebox("panel").duplicate()
		chain_style.border_color = Color(0.85, 0.6, 0.15, 1.0)
		chain_style.set_border_width_all(4)
		panel.add_theme_stylebox_override("panel", chain_style)
	else:
		title_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.55))
	
	title_label.text = title_text
	desc_label.text = event_data.get("description", "")
	
	# 清旧选项
	for child in options_container.get_children():
		child.queue_free()
	
	# 创建选项按钮
	var options = event_data.get("options", [])
	for i in range(options.size()):
		var opt = options[i]
		var btn = _create_option_button(opt, i)
		options_container.add_child(btn)
	
	options_container.visible = true
	result_container.visible = false
	visible = true

func _create_option_button(option: Dictionary, index: int) -> Button:
	var btn = Button.new()
	btn.text = option.get("text", "选项 " + str(index + 1))
	btn.custom_minimum_size = Vector2(0, 48)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 17)
	
	# 按钮样式 - 与面板风格一致
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.25, 0.20, 0.15, 0.85)
	normal_style.border_color = Color(0.50, 0.38, 0.25, 0.7)
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(8)
	normal_style.set_content_margin_all(12)
	btn.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.35, 0.28, 0.18, 0.95)
	hover_style.border_color = Color(0.70, 0.55, 0.35, 0.9)
	btn.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.18, 0.14, 0.10, 0.95)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	
	btn.add_theme_color_override("font_color", Color(0.90, 0.85, 0.72))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.7))
	
	# 阶段2及以后：鼠标悬停不显示数值变化
	if not is_stage2_or_later:
		var effects = option.get("effects", {})
		var effect_strs = []
		for key in effects:
			var val = effects[key]
			var display_name = _get_effect_display_name(key)
			effect_strs.append("%s %+d" % [display_name, val])
		if effect_strs.size() > 0:
			btn.tooltip_text = "预计效果: " + ", ".join(effect_strs)
	
	if option.get("unavailable", false):
		btn.disabled = true
		btn.modulate = Color(0.5, 0.5, 0.5, 0.7)
	
	btn.pressed.connect(_on_option_pressed.bind(index))
	return btn

func _on_option_pressed(option_index: int):
	var options = current_event_data.get("options", [])
	if option_index >= options.size():
		return
	
	var chosen = options[option_index]
	
	# 记录变动前
	var before = {
		"money": ResourceManager.get_resource_value("money"),
		"reputation": ResourceManager.get_resource_value("reputation"),
		"cohesion": ResourceManager.get_resource_value("cohesion"),
		"creativity": ResourceManager.get_resource_value("creativity"),
	}
	
	# 应用效果（含连锁解锁）
	EventManager.apply_option_effects(chosen)
	
	# 记录变动后
	var after = {
		"money": ResourceManager.get_resource_value("money"),
		"reputation": ResourceManager.get_resource_value("reputation"),
		"cohesion": ResourceManager.get_resource_value("cohesion"),
		"creativity": ResourceManager.get_resource_value("creativity"),
	}
	
	# 构建结果文本
	var result_text = chosen.get("result_text", "你做出了选择。")
	var change_lines = []
	for key in before:
		if before[key] != after[key]:
			var delta = after[key] - before[key]
			var display = _get_effect_display_name(key)
			var color = "green" if delta > 0 else "red"
			change_lines.append("[color=%s]%s %+d[/color]" % [color, display, delta])
	
	var bbcode = "[color=#b8d4a0]%s[/color]" % result_text
	if change_lines.size() > 0:
		bbcode += "\n\n" + "  ".join(change_lines)
	
	result_label.text = bbcode
	
	# 显示结果，隐藏选项
	options_container.visible = false
	result_container.visible = true
	
	# 发射信号
	var event_id = current_event_data.get("id", "unknown")
	event_completed.emit(event_id, option_index)

func _on_confirm_pressed():
	visible = false
	_return_to_main()

func _return_to_main():
	# 返回主场景
	var main_scene_path = "res://project/scenes/main/main.tscn"
	if ResourceLoader.exists(main_scene_path):
		get_tree().change_scene_to_file(main_scene_path)
	else:
		push_warning("[MidweekEventUI] 主场景不存在，尝试返回上一场景")
		get_tree().quit()

func _get_effect_display_name(key: String) -> String:
	match key:
		"money": return "资金"
		"reputation": return "声誉"
		"cohesion": return "凝聚力"
		"creativity": return "创造力"
		"memory_recovery": return "记忆"
		"art_weight": return "艺术"
		"business_weight": return "商业"
		"human_weight": return "人情"
		_: return key
