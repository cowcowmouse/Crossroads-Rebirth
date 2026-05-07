# 成员事件系统测试面板
# 功能：设置关系值 → 触发成员事件 → 弹出对话 → 验证效果
# 支持：个人事件、关键转阶事件、矛盾事件测试
extends Control

# 成员输入控件 {member_id: {input: LineEdit, stage_label: Label, status_label: Label}}
var member_controls: Dictionary = {}
var cohesion_input: LineEdit
var log_label: RichTextLabel
var mediation_toggle: CheckButton

# 事件对话框
var event_dialog_overlay: ColorRect
var event_title_label: Label
var event_desc_label: RichTextLabel
var event_options_container: VBoxContainer
var event_result_label: RichTextLabel
var event_close_btn: Button
var current_event_data: Dictionary = {}
var current_event_member: String = ""
var pending_events: Array = []

func _ready():
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_build_ui()
	_build_event_dialog()
	_refresh_all_status()
	_log("[color=cyan]成员事件测试面板就绪[/color]")
	_log("1. 设置各成员关系值 → 影响事件阶段")
	_log("2. 设置凝聚力 → 影响矛盾事件触发")
	_log("3. 点击按钮触发事件 → 弹出对话选项")

func _build_ui():
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.06, 0.1, 1.0)
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	var main_hbox = HBoxContainer.new()
	main_hbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	main_hbox.add_theme_constant_override("separation", 16)
	main_hbox.offset_left = 20
	main_hbox.offset_top = 20
	main_hbox.offset_right = -20
	main_hbox.offset_bottom = -20
	add_child(main_hbox)

	# ========== 左栏：控制面板 ==========
	var left_scroll = ScrollContainer.new()
	left_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.size_flags_stretch_ratio = 0.45
	main_hbox.add_child(left_scroll)

	var left_vbox = VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.add_theme_constant_override("separation", 6)
	left_scroll.add_child(left_vbox)

	# 标题
	var title = Label.new()
	title.text = "🎭 成员事件测试面板"
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_vbox.add_child(title)
	left_vbox.add_child(HSeparator.new())

	# --- 成员关系值设置 ---
	var rel_header = Label.new()
	rel_header.text = "【成员关系值设置】"
	rel_header.add_theme_font_size_override("font_size", 16)
	rel_header.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	left_vbox.add_child(rel_header)

	var unlocked = ResourceManager.get_unlocked_members()
	for member_id in unlocked:
		var member_data = ResourceManager.get_member_data(member_id)
		var name = member_data.get("name", member_id)
		_add_member_row(left_vbox, member_id, name)

	# 全部设置按钮
	var set_all_btn = Button.new()
	set_all_btn.text = "✅ 应用所有关系值"
	set_all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	set_all_btn.custom_minimum_size.y = 36
	set_all_btn.pressed.connect(_on_apply_all_relations)
	left_vbox.add_child(set_all_btn)

	left_vbox.add_child(HSeparator.new())

	# --- 全局设置 ---
	var global_header = Label.new()
	global_header.text = "【全局设置】"
	global_header.add_theme_font_size_override("font_size", 16)
	global_header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	left_vbox.add_child(global_header)

	# 凝聚力
	var coh_hbox = HBoxContainer.new()
	coh_hbox.add_theme_constant_override("separation", 8)
	left_vbox.add_child(coh_hbox)
	var coh_lbl = Label.new()
	coh_lbl.text = "🤝 凝聚力:"
	coh_lbl.add_theme_font_size_override("font_size", 15)
	coh_hbox.add_child(coh_lbl)
	cohesion_input = LineEdit.new()
	cohesion_input.text = str(ResourceManager.get_resource_value("cohesion"))
	cohesion_input.custom_minimum_size = Vector2(80, 30)
	coh_hbox.add_child(cohesion_input)
	var coh_btn = Button.new()
	coh_btn.text = "设置"
	coh_btn.custom_minimum_size = Vector2(60, 30)
	coh_btn.pressed.connect(func():
		var val = int(cohesion_input.text)
		var cur = ResourceManager.get_resource_value("cohesion")
		ResourceManager.modify_core_resource("cohesion", val - cur)
		_log("[color=yellow]凝聚力设置为: %d[/color]" % val)
	)
	coh_hbox.add_child(coh_btn)

	# 调解信号
	var med_hbox = HBoxContainer.new()
	med_hbox.add_theme_constant_override("separation", 8)
	left_vbox.add_child(med_hbox)
	var med_lbl = Label.new()
	med_lbl.text = "🕊️ 调解信号:"
	med_lbl.add_theme_font_size_override("font_size", 15)
	med_hbox.add_child(med_lbl)
	mediation_toggle = CheckButton.new()
	mediation_toggle.text = "关闭"
	mediation_toggle.toggled.connect(func(on):
		MemberEventManager.mediation_active = on
		mediation_toggle.text = "已激活" if on else "关闭"
		_log("[color=yellow]调解信号: %s[/color]" % ("激活" if on else "关闭"))
	)
	med_hbox.add_child(mediation_toggle)

	# 快捷预设
	var preset_header = Label.new()
	preset_header.text = "【快捷预设】"
	preset_header.add_theme_font_size_override("font_size", 14)
	preset_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	left_vbox.add_child(preset_header)

	var preset_grid = GridContainer.new()
	preset_grid.columns = 2
	preset_grid.add_theme_constant_override("h_separation", 6)
	preset_grid.add_theme_constant_override("v_separation", 4)
	left_vbox.add_child(preset_grid)
	_add_preset_btn(preset_grid, "全员关系→25", func(): _set_all_relations(25))
	_add_preset_btn(preset_grid, "全员关系→35", func(): _set_all_relations(35))
	_add_preset_btn(preset_grid, "全员关系→55", func(): _set_all_relations(55))
	_add_preset_btn(preset_grid, "全员关系→65", func(): _set_all_relations(65))
	_add_preset_btn(preset_grid, "凝聚力→30", func(): _quick_set_cohesion(30))
	_add_preset_btn(preset_grid, "凝聚力→60", func(): _quick_set_cohesion(60))

	left_vbox.add_child(HSeparator.new())

	# --- 触发按钮 ---
	var trigger_header = Label.new()
	trigger_header.text = "【事件触发】"
	trigger_header.add_theme_font_size_override("font_size", 16)
	trigger_header.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	left_vbox.add_child(trigger_header)

	var trigger_btn = Button.new()
	trigger_btn.text = "⚡ 触发周中成员事件（含概率）"
	trigger_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trigger_btn.custom_minimum_size.y = 48
	trigger_btn.add_theme_font_size_override("font_size", 18)
	trigger_btn.pressed.connect(_on_trigger_all_pressed)
	left_vbox.add_child(trigger_btn)

	# 单人强制触发
	var force_header = Label.new()
	force_header.text = "点击下方成员名强制触发其事件（无概率）:"
	force_header.add_theme_font_size_override("font_size", 13)
	force_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	left_vbox.add_child(force_header)

	var force_grid = GridContainer.new()
	force_grid.columns = 2
	force_grid.add_theme_constant_override("h_separation", 6)
	force_grid.add_theme_constant_override("v_separation", 4)
	left_vbox.add_child(force_grid)

	for member_id in unlocked:
		var mname = ResourceManager.get_member_data(member_id).get("name", member_id)
		var btn = Button.new()
		btn.text = "🎯 " + mname
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size.y = 32
		btn.pressed.connect(_on_force_trigger_member.bind(member_id))
		force_grid.add_child(btn)

	# 矛盾事件强制触发
	var conflict_btn = Button.new()
	conflict_btn.text = "💥 强制触发矛盾事件"
	conflict_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conflict_btn.custom_minimum_size.y = 38
	conflict_btn.pressed.connect(_on_force_trigger_conflict)
	left_vbox.add_child(conflict_btn)

	left_vbox.add_child(HSeparator.new())

	# 重置
	var reset_btn = Button.new()
	reset_btn.text = "🔄 重置所有数据"
	reset_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_btn.custom_minimum_size.y = 32
	reset_btn.pressed.connect(func():
		MemberEventManager.reset_all()
		_refresh_all_status()
		_log("[color=red]所有成员事件数据已重置[/color]")
	)
	left_vbox.add_child(reset_btn)

	# 返回按钮
	var back_btn = Button.new()
	back_btn.text = "← 返回主菜单"
	back_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_btn.custom_minimum_size.y = 36
	back_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://project/scenes/main/main.tscn")
	)
	left_vbox.add_child(back_btn)

	# ========== 右栏：状态 + 日志 ==========
	var right_vbox = VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.size_flags_stretch_ratio = 0.55
	right_vbox.add_theme_constant_override("separation", 8)
	main_hbox.add_child(right_vbox)

	# 成员状态面板
	var status_panel = PanelContainer.new()
	status_panel.custom_minimum_size.y = 180
	right_vbox.add_child(status_panel)

	var status_margin = MarginContainer.new()
	status_margin.add_theme_constant_override("margin_left", 12)
	status_margin.add_theme_constant_override("margin_right", 12)
	status_margin.add_theme_constant_override("margin_top", 8)
	status_margin.add_theme_constant_override("margin_bottom", 8)
	status_panel.add_child(status_margin)

	var status_vbox = VBoxContainer.new()
	status_vbox.add_theme_constant_override("separation", 4)
	status_margin.add_child(status_vbox)

	var status_title = Label.new()
	status_title.text = "📊 成员关系状态"
	status_title.add_theme_font_size_override("font_size", 18)
	status_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_vbox.add_child(status_title)
	status_vbox.add_child(HSeparator.new())

	for member_id in unlocked:
		var mdata = ResourceManager.get_member_data(member_id)
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		status_vbox.add_child(hbox)

		var name_lbl = Label.new()
		name_lbl.text = mdata.get("name", member_id) + "(" + mdata.get("role", "") + ")"
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.custom_minimum_size.x = 140
		hbox.add_child(name_lbl)

		var stage_lbl = Label.new()
		stage_lbl.add_theme_font_size_override("font_size", 15)
		stage_lbl.custom_minimum_size.x = 200
		hbox.add_child(stage_lbl)

		var status_lbl = Label.new()
		status_lbl.add_theme_font_size_override("font_size", 14)
		hbox.add_child(status_lbl)

		member_controls[member_id]["stage_label"] = stage_lbl
		member_controls[member_id]["status_label"] = status_lbl

	# 日志区
	var log_header = HBoxContainer.new()
	right_vbox.add_child(log_header)
	var log_title = Label.new()
	log_title.text = "📋 事件日志"
	log_title.add_theme_font_size_override("font_size", 16)
	log_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_header.add_child(log_title)
	var clear_btn = Button.new()
	clear_btn.text = "清空"
	clear_btn.custom_minimum_size = Vector2(60, 28)
	clear_btn.pressed.connect(func(): log_label.text = "")
	log_header.add_child(clear_btn)

	log_label = RichTextLabel.new()
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_label.bbcode_enabled = true
	log_label.scroll_following = true
	right_vbox.add_child(log_label)

func _add_member_row(parent: VBoxContainer, member_id: String, display_name: String):
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	parent.add_child(hbox)

	var lbl = Label.new()
	lbl.text = display_name + ":"
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.custom_minimum_size.x = 70
	hbox.add_child(lbl)

	var input = LineEdit.new()
	input.text = str(MemberEventManager.get_relationship(member_id))
	input.custom_minimum_size = Vector2(60, 28)
	hbox.add_child(input)

	var set_btn = Button.new()
	set_btn.text = "设置"
	set_btn.custom_minimum_size = Vector2(50, 28)
	set_btn.pressed.connect(func():
		MemberEventManager.set_relationship(member_id, int(input.text))
		_refresh_all_status()
		_log("[color=cyan]%s 关系值设为: %s[/color]" % [display_name, input.text])
	)
	hbox.add_child(set_btn)

	# 关系±按钮
	var plus_btn = Button.new()
	plus_btn.text = "+10"
	plus_btn.custom_minimum_size = Vector2(45, 28)
	plus_btn.pressed.connect(func():
		MemberEventManager.add_relationship(member_id, 10)
		input.text = str(MemberEventManager.get_relationship(member_id))
		_refresh_all_status()
	)
	hbox.add_child(plus_btn)

	var minus_btn = Button.new()
	minus_btn.text = "-10"
	minus_btn.custom_minimum_size = Vector2(45, 28)
	minus_btn.pressed.connect(func():
		MemberEventManager.add_relationship(member_id, -10)
		input.text = str(MemberEventManager.get_relationship(member_id))
		_refresh_all_status()
	)
	hbox.add_child(minus_btn)

	member_controls[member_id] = {"input": input}

# ===================== 事件对话框 =====================

func _build_event_dialog():
	event_dialog_overlay = ColorRect.new()
	event_dialog_overlay.color = Color(0.05, 0.03, 0.08, 0.75)
	event_dialog_overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	event_dialog_overlay.visible = false
	event_dialog_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(event_dialog_overlay)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	event_dialog_overlay.add_child(center)

	var panel = PanelContainer.new()
	panel.name = "EventPanel"
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

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var top_line = ColorRect.new()
	top_line.name = "EventTopLine"
	top_line.color = Color(0.65, 0.45, 0.25, 0.6)
	top_line.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(top_line)

	# 事件类型标签
	var type_lbl = Label.new()
	type_lbl.name = "TypeLabel"
	type_lbl.add_theme_font_size_override("font_size", 14)
	type_lbl.add_theme_color_override("font_color", Color(0.80, 0.72, 0.56))
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(type_lbl)

	event_title_label = Label.new()
	event_title_label.add_theme_font_size_override("font_size", 26)
	event_title_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.55))
	event_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(event_title_label)

	var sep = ColorRect.new()
	sep.color = Color(0.55, 0.40, 0.25, 0.4)
	sep.custom_minimum_size = Vector2(0, 1)
	vbox.add_child(sep)

	event_desc_label = RichTextLabel.new()
	event_desc_label.bbcode_enabled = true
	event_desc_label.fit_content = true
	event_desc_label.custom_minimum_size = Vector2(0, 60)
	event_desc_label.scroll_active = false
	event_desc_label.add_theme_font_size_override("normal_font_size", 18)
	event_desc_label.add_theme_color_override("default_color", Color(0.85, 0.82, 0.75))
	vbox.add_child(event_desc_label)

	event_options_container = VBoxContainer.new()
	event_options_container.add_theme_constant_override("separation", 10)
	vbox.add_child(event_options_container)

	event_result_label = RichTextLabel.new()
	event_result_label.bbcode_enabled = true
	event_result_label.fit_content = true
	event_result_label.scroll_active = false
	event_result_label.custom_minimum_size = Vector2(0, 40)
	event_result_label.add_theme_font_size_override("normal_font_size", 17)
	event_result_label.add_theme_color_override("default_color", Color(0.7, 0.9, 0.7))
	event_result_label.visible = false
	vbox.add_child(event_result_label)

	event_close_btn = Button.new()
	event_close_btn.text = "继续"
	event_close_btn.custom_minimum_size = Vector2(180, 44)
	event_close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	event_close_btn.add_theme_font_size_override("font_size", 18)
	_style_test_event_button(event_close_btn)
	event_close_btn.visible = false
	event_close_btn.pressed.connect(_on_event_dialog_close)
	vbox.add_child(event_close_btn)

	var bottom_line = ColorRect.new()
	bottom_line.name = "EventBottomLine"
	bottom_line.color = Color(0.65, 0.45, 0.25, 0.6)
	bottom_line.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(bottom_line)

func _show_event_dialog(event_data: Dictionary):
	current_event_data = event_data
	current_event_member = event_data.get("_member_id", "")
	_apply_test_event_theme(event_data)
	var btn_bg := Color(0.22, 0.18, 0.14, 0.85)
	var btn_border := _get_test_member_accent(_get_test_theme_member_id(event_data)).darkened(0.15)

	var event_type = event_data.get("_event_type", "personal")
	var type_text = ""
	match event_type:
		"personal":
			type_text = "📌 个人事件 — " + MemberEventManager.get_member_display_name(current_event_member)
		"key":
			type_text = "⭐ 关键转阶事件 — " + MemberEventManager.get_member_display_name(current_event_member)
		"conflict":
			var a = event_data.get("member_a", "")
			var b = event_data.get("member_b", "")
			type_text = "💥 矛盾事件 — " + MemberEventManager.get_member_display_name(a) + " × " + MemberEventManager.get_member_display_name(b)

	var type_lbl = event_dialog_overlay.find_child("TypeLabel", true, false)
	if type_lbl:
		type_lbl.text = type_text

	event_title_label.text = event_data.get("title", "事件")
	event_desc_label.text = event_data.get("description", "")
	event_result_label.visible = false
	event_close_btn.visible = false

	for child in event_options_container.get_children():
		child.queue_free()

	var options = event_data.get("options", [])
	for i in range(options.size()):
		var opt = options[i]
		var btn = Button.new()
		btn.text = opt.get("text", "选项 " + str(i + 1))
		btn.custom_minimum_size = Vector2(0, 48)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 17)

		_style_test_event_button(btn, btn_bg, btn_border)

		btn.pressed.connect(_on_event_option_chosen.bind(i))
		event_options_container.add_child(btn)

	# 矛盾事件：如果调解可用，加调解选项
	if event_type == "conflict" and MemberEventManager.mediation_active:
		var med_result = event_data.get("mediation_result", {})
		if not med_result.is_empty():
			var med_btn = Button.new()
			med_btn.text = "🕊️ 梅出面调解"
			med_btn.custom_minimum_size = Vector2(0, 48)
			med_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			med_btn.add_theme_font_size_override("font_size", 17)
			_style_test_event_button(med_btn, Color(0.15, 0.25, 0.18, 0.9), Color(0.3, 0.7, 0.4, 0.8))
			med_btn.pressed.connect(_on_mediation_chosen)
			event_options_container.add_child(med_btn)

	event_dialog_overlay.visible = true

func _on_event_option_chosen(index: int):
	var options = current_event_data.get("options", [])
	if index >= options.size():
		return
	var chosen = options[index]

	for child in event_options_container.get_children():
		child.visible = false

	# 确定矛盾成员列表
	var conflict_members: Array = []
	if current_event_data.get("_event_type", "") == "conflict":
		conflict_members = [current_event_data.get("member_a", ""), current_event_data.get("member_b", "")]

	# 应用效果
	MemberEventManager.apply_member_event_effects(current_event_member, chosen, conflict_members)

	# 构建结果文本
	var result_text = chosen.get("result_text", "你做出了选择。")
	var bbcode = "[color=#b8d4a0]%s[/color]" % result_text

	# 显示效果变化
	var effects = chosen.get("effects", {})
	var change_lines: Array = []
	for key in effects:
		var val = effects[key]
		var color = "green" if val > 0 else "red"
		change_lines.append("[color=%s]%s %+d[/color]" % [color, _effect_display(key), val])
	if change_lines.size() > 0:
		bbcode += "\n\n" + "  ".join(change_lines)

	# 晋级提示
	if chosen.get("advance", false):
		bbcode += "\n\n[color=gold]⭐ 关系阶段提升！[/color]"
	if chosen.get("lock_zero", false):
		bbcode += "\n\n[color=red]⚠ 关系已锁定为0！[/color]"

	event_result_label.text = bbcode
	event_result_label.visible = true
	event_close_btn.visible = true

	# 日志
	_log("[color=lime]选择: %s[/color]" % chosen.get("text", "?"))
	for line in change_lines:
		_log(line)

	_refresh_all_status()

func _on_mediation_chosen():
	for child in event_options_container.get_children():
		child.visible = false

	MemberEventManager.apply_mediation_result(current_event_data)

	var med_result = current_event_data.get("mediation_result", {})
	var bbcode = "[color=#a0d4b8]%s[/color]" % med_result.get("result_text", "调解成功。")
	bbcode += "\n\n[color=gold]🕊️ 矛盾已永久化解！[/color]"

	event_result_label.text = bbcode
	event_result_label.visible = true
	event_close_btn.visible = true
	_log("[color=lime]🕊️ 调解成功！矛盾永久化解[/color]")
	_refresh_all_status()

func _on_event_dialog_close():
	event_dialog_overlay.visible = false
	# 如果有排队的事件，继续展示
	if pending_events.size() > 0:
		var next = pending_events.pop_front()
		_show_event_dialog(next)

func _style_test_event_button(btn: Button, bg: Color = Color(0.25, 0.20, 0.15, 0.85), border: Color = Color(0.50, 0.38, 0.25, 0.7)):
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = bg
	normal_style.border_color = border
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

func _get_test_theme_member_id(event_data: Dictionary) -> String:
	if event_data.get("_member_id", "") != "":
		return event_data.get("_member_id", "")
	if event_data.get("member_a", "") != "":
		return event_data.get("member_a", "")
	return "alexi"

func _get_test_member_accent(member_id: String) -> Color:
	match member_id:
		"alexi":
			return Color(0.95, 0.78, 0.22)
		"old_nail":
			return Color(0.95, 0.95, 0.95)
		"finn":
			return Color(0.62, 0.62, 0.62)
		"rio":
			return Color(0.55, 0.34, 0.18)
		"kira":
			return Color(0.62, 0.35, 0.78)
		"mei":
			return Color(0.24, 0.78, 0.78)
		"sebastian":
			return Color(0.02, 0.02, 0.02)
		"lily":
			return Color(0.96, 0.62, 0.78)
		"aya":
			return Color(0.36, 0.75, 0.36)
		"duan":
			return Color(0.30, 0.52, 0.88)
		_:
			return Color(0.95, 0.82, 0.55)

func _apply_test_event_theme(event_data: Dictionary):
	var member_id = _get_test_theme_member_id(event_data)
	var accent = _get_test_member_accent(member_id)
	var label_color = accent.lightened(0.08)
	if member_id == "sebastian":
		label_color = Color(0.84, 0.84, 0.84)
	event_title_label.add_theme_color_override("font_color", label_color)
	event_desc_label.add_theme_color_override("default_color", Color(0.85, 0.82, 0.75))
	var type_lbl = event_dialog_overlay.find_child("TypeLabel", true, false)
	if type_lbl:
		type_lbl.add_theme_color_override("font_color", label_color)
	var panel = event_dialog_overlay.find_child("EventPanel", true, false)
	if panel:
		var panel_style = panel.get_theme_stylebox("panel").duplicate()
		panel_style.border_color = accent
		panel.add_theme_stylebox_override("panel", panel_style)
	var top_line = event_dialog_overlay.find_child("EventTopLine", true, false)
	if top_line:
		top_line.color = accent
	var bottom_line = event_dialog_overlay.find_child("EventBottomLine", true, false)
	if bottom_line:
		bottom_line.color = accent

# ===================== 按钮回调 =====================

func _on_apply_all_relations():
	for member_id in member_controls:
		var input = member_controls[member_id]["input"] as LineEdit
		MemberEventManager.set_relationship(member_id, int(input.text))
	_refresh_all_status()
	_log("[color=cyan]所有关系值已应用[/color]")

func _on_trigger_all_pressed():
	_log("\n[color=white]══════ 触发周中成员事件 ══════[/color]")
	_log("[color=white]凝聚力: %d | 调解: %s[/color]" % [
		ResourceManager.get_resource_value("cohesion"),
		"激活" if MemberEventManager.mediation_active else "关闭"
	])

	var events = MemberEventManager.process_midweek_member_events()
	if events.is_empty():
		_log("[color=yellow]本周无成员事件触发（概率未命中）[/color]")
		_log("[color=gray]提示: 个人事件25%概率，矛盾事件30%概率[/color]")
		return

	_log("[color=green]触发了 %d 个事件:[/color]" % events.size())
	for evt in events:
		var etype = evt.get("_event_type", "?")
		var mid = evt.get("_member_id", "")
		match etype:
			"personal":
				_log("  📌 %s - %s" % [MemberEventManager.get_member_display_name(mid), evt.get("title", "?")])
			"key":
				_log("  ⭐ %s - %s (关键事件)" % [MemberEventManager.get_member_display_name(mid), evt.get("title", "?")])
			"conflict":
				var a = evt.get("member_a", "")
				var b = evt.get("member_b", "")
				_log("  💥 %s × %s - %s" % [MemberEventManager.get_member_display_name(a), MemberEventManager.get_member_display_name(b), evt.get("title", "?")])

	# 显示第一个事件，其余排队
	pending_events = events.slice(1)
	_show_event_dialog(events[0])

func _on_force_trigger_member(member_id: String):
	var name = MemberEventManager.get_member_display_name(member_id)
	_log("\n[color=orange]══════ 强制触发: %s ══════[/color]" % name)

	var event = MemberEventManager.force_trigger_member_event(member_id)
	if event.is_empty():
		_log("[color=red]无可触发事件（可能所有事件已完成或关系阶段不匹配）[/color]")
		var rel = MemberEventManager.get_relationship(member_id)
		var stage = MemberEventManager.get_relationship_stage(member_id)
		_log("[color=gray]当前关系: %d, 阶段: %d[/color]" % [rel, stage])
		return

	_log("[color=green]事件: %s (%s)[/color]" % [event.get("title", "?"), event.get("_event_type", "?")])
	_show_event_dialog(event)

func _on_force_trigger_conflict():
	_log("\n[color=red]══════ 强制触发矛盾事件 ══════[/color]")

	var conflict = MemberEventManager.force_trigger_conflict()
	if conflict.is_empty():
		_log("[color=red]无矛盾事件可触发[/color]")
		return

	if conflict.get("_forced", false):
		_log("[color=yellow]⚠ 条件不满足，强制触发[/color]")

	var a = conflict.get("member_a", "")
	var b = conflict.get("member_b", "")
	_log("[color=red]💥 %s × %s: %s[/color]" % [
		MemberEventManager.get_member_display_name(a),
		MemberEventManager.get_member_display_name(b),
		conflict.get("title", "?")
	])
	_show_event_dialog(conflict)

# ===================== 辅助 =====================

func _refresh_all_status():
	for member_id in member_controls:
		if not member_controls[member_id].has("stage_label"):
			continue
		var rel = MemberEventManager.get_relationship(member_id)
		var stage = MemberEventManager.get_relationship_stage(member_id)
		var locked = MemberEventManager.locked_members.has(member_id)

		var stage_lbl = member_controls[member_id]["stage_label"] as Label
		var stage_names = {1: "陌生", 2: "熟悉", 3: "信任"}
		stage_lbl.text = "关系:%d  阶段:%d(%s)" % [rel, stage, stage_names.get(stage, "?")]
		stage_lbl.add_theme_color_override("font_color", Color(0.5, 1, 0.5) if stage >= 2 else Color(0.8, 0.8, 0.8))

		var status_lbl = member_controls[member_id]["status_label"] as Label
		if locked:
			status_lbl.text = "🔒锁0"
			status_lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		else:
			status_lbl.text = ""

		# 同步输入框
		var input = member_controls[member_id]["input"] as LineEdit
		input.text = str(rel)

func _set_all_relations(value: int):
	for member_id in member_controls:
		MemberEventManager.set_relationship(member_id, value)
	_refresh_all_status()
	_log("[color=cyan]全员关系值设为: %d[/color]" % value)

func _quick_set_cohesion(value: int):
	var cur = ResourceManager.get_resource_value("cohesion")
	ResourceManager.modify_core_resource("cohesion", value - cur)
	cohesion_input.text = str(value)
	_log("[color=yellow]凝聚力设为: %d[/color]" % value)

func _add_preset_btn(container: GridContainer, text: String, callback: Callable):
	var btn = Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size.y = 28
	btn.pressed.connect(callback)
	container.add_child(btn)

func _effect_display(key: String) -> String:
	match key:
		"relationship": return "❤️关系"
		"each_relationship": return "❤️双方关系"
		"cohesion": return "🤝凝聚力"
		"creativity": return "🎨创造力"
		"money": return "💰资金"
		"reputation": return "⭐声誉"
		"memory": return "🧠记忆"
		"recovery": return "💊恢复度"
		"mood": return "😊心情"
		_:
			if key.ends_with("_relationship"):
				return "❤️" + key.replace("_relationship", "")
			return key

func _log(text: String):
	if log_label:
		log_label.append_text(text + "\n")
