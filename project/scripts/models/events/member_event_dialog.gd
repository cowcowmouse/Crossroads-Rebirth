# 成员事件对话场景
# 从 MemberEventManager.pending_midweek_events 消费事件队列
# 每次显示一个事件，玩家选择后应用效果，全部结束后跳转公共事件池
extends Control

# ── UI 节点引用（_build_ui 中创建）──
var _overlay_bg: ColorRect
var _panel: PanelContainer
var _top_line: ColorRect
var _bottom_line: ColorRect
var _type_label: Label
var _title_label: Label
var _desc_label: RichTextLabel
var _opts_container: VBoxContainer
var _result_label: RichTextLabel
var _continue_btn: Button

# 当前处理的事件
var _current: Dictionary = {}
# 事件队列副本
var _queue: Array = []
var close_when_finished: bool = false

# ────────────────────────────────────────────────
func _ready() -> void:
	_build_ui()
	_play_fade_in()
	# 从 MemberEventManager 取出本周队列
	_queue = MemberEventManager.pending_midweek_events.duplicate()
	MemberEventManager.pending_midweek_events.clear()

	if _queue.is_empty():
		_go_next_scene()
		return

	_show_next()

# ────────────────────────────────────────────────
func _show_next() -> void:
	if _queue.is_empty():
		_go_next_scene()
		return

	_current = _queue.pop_front()
	_populate(_current)

func _go_next_scene() -> void:
	if close_when_finished:
		queue_free()
		return
	# 成员事件全部结束 → 进入公共事件池
	get_tree().change_scene_to_file("res://project/scenes/event/EventDialog.tscn")

# ────────────────────────────────────────────────
func _populate(event: Dictionary) -> void:
	# 清除旧选项
	for c in _opts_container.get_children():
		c.queue_free()
	_result_label.visible = false
	_continue_btn.visible = false
	_apply_event_theme(event)

	# 类型标签
	var etype = event.get("_event_type", "personal")
	var mid = event.get("_member_id", "")
	var name_a = MemberEventManager.get_member_display_name(event.get("member_a", mid))
	var name_b = MemberEventManager.get_member_display_name(event.get("member_b", ""))
	match etype:
		"key", "special":
			_type_label.text = "⭐ 特殊事件 — " + name_a
		"conflict":
			_type_label.text = "💥 矛盾事件 — " + name_a + " × " + name_b
		_:
			_type_label.text = "📌 个人事件 — " + name_a

	_title_label.text = event.get("title", "")
	_desc_label.text = event.get("description", "")

	var options: Array = event.get("options", [])
	for i in range(options.size()):
		var opt: Dictionary = options[i]
		var btn := Button.new()
		btn.text = opt.get("text", "选项 %d" % (i + 1))
		btn.custom_minimum_size = Vector2(0, 48)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 17)
		_style_option_button(btn)

		btn.pressed.connect(_on_option.bind(i))
		_opts_container.add_child(btn)

	# 矛盾事件 + 调解激活 → 加调解按钮
	if etype == "conflict" and MemberEventManager.mediation_active:
		if not event.get("mediation_result", {}).is_empty():
			var med_btn := Button.new()
			med_btn.text = "🕊️ 梅出面调解"
			med_btn.custom_minimum_size = Vector2(0, 48)
			med_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			med_btn.add_theme_font_size_override("font_size", 17)
			_style_option_button(med_btn)
			med_btn.pressed.connect(_on_mediation)
			_opts_container.add_child(med_btn)

# ────────────────────────────────────────────────
func _on_option(idx: int) -> void:
	var options: Array = _current.get("options", [])
	if idx >= options.size():
		return
	var chosen: Dictionary = options[idx]

	for c in _opts_container.get_children():
		c.visible = false

	# 确定矛盾双方列表
	var conflict_members: Array = []
	if _current.get("_event_type", "") == "conflict":
		conflict_members = [_current.get("member_a", ""), _current.get("member_b", "")]

	MemberEventManager.apply_member_event_effects(
		_current.get("_member_id", ""), chosen, conflict_members
	)
	MemberEventManager.mark_event_completed(_current)

	# 构建结果 BBCode
	var result := "[color=#b8d4a0]%s[/color]" % chosen.get("result_text", "你做出了选择。")
	var changes: PackedStringArray = []
	for key in chosen.get("effects", {}):
		var val := int(chosen["effects"][key])
		var col := "green" if val > 0 else "red"
		changes.append("[color=%s]%s %+d[/color]" % [col, _eff_name(key), val])
	if changes.size() > 0:
		result += "\n\n" + "  ".join(changes)
	if chosen.get("advance", false):
		result += "\n\n[color=gold]⭐ 关系阶段提升！[/color]"
	if chosen.get("lock_zero", false):
		result += "\n\n[color=red]⚠ 关系已锁定为0[/color]"

	_result_label.text = result
	_result_label.visible = true
	_continue_btn.text = "继续" if _queue.is_empty() else "下一个事件 ▶"
	_continue_btn.visible = true

func _on_mediation() -> void:
	for c in _opts_container.get_children():
		c.visible = false

	MemberEventManager.apply_mediation_result(_current)
	MemberEventManager.mark_event_completed(_current)

	var desc: String = _current.get("mediation_result", {}).get("description", "调解成功。")
	_result_label.text = "[color=#a0d4b8]%s[/color]\n\n[color=gold]🕊️ 矛盾已永久化解！[/color]" % desc
	_result_label.visible = true
	_continue_btn.text = "继续" if _queue.is_empty() else "下一个事件 ▶"
	_continue_btn.visible = true

func _on_continue() -> void:
	_show_next()

func _style_option_button(btn: Button) -> void:
	var accent := _title_label.get_theme_color("font_color")
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.25, 0.20, 0.15, 0.85)
	normal_style.border_color = accent.darkened(0.15)
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(8)
	normal_style.set_content_margin_all(12)
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = Color(0.35, 0.28, 0.18, 0.95)
	hover_style.border_color = accent
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := normal_style.duplicate()
	pressed_style.bg_color = Color(0.18, 0.14, 0.10, 0.95)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_color_override("font_color", Color(0.90, 0.85, 0.72))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.7))

func _get_theme_member_id(event: Dictionary) -> String:
	if event.get("_member_id", "") != "":
		return event.get("_member_id", "")
	if event.get("member_a", "") != "":
		return event.get("member_a", "")
	return "alexi"

func _get_member_accent(member_id: String) -> Color:
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

func _apply_event_theme(event: Dictionary) -> void:
	var member_id := _get_theme_member_id(event)
	var accent := _get_member_accent(member_id)
	var label_color := accent.lightened(0.08)
	if member_id == "sebastian":
		label_color = Color(0.84, 0.84, 0.84)
	_type_label.add_theme_color_override("font_color", label_color)
	_title_label.add_theme_color_override("font_color", label_color)
	if _panel:
		var panel_style := _panel.get_theme_stylebox("panel").duplicate()
		panel_style.border_color = accent
		_panel.add_theme_stylebox_override("panel", panel_style)
	if _top_line:
		_top_line.color = accent
	if _bottom_line:
		_bottom_line.color = accent

# ────────────────────────────────────────────────
func _eff_name(key: String) -> String:
	match key:
		"relationship":      return "❤️关系"
		"each_relationship": return "❤️双方关系"
		"cohesion":          return "🤝凝聚力"
		"creativity":        return "🎨创造力"
		"money":             return "💰资金"
		"reputation":        return "⭐声誉"
		"memory":            return "🧠记忆"
		"recovery":          return "💊恢复度"
		"mood":              return "😊心情"
		_:
			if key.ends_with("_relationship"):
				return "❤️" + key.replace("_relationship", "")
			return key

# ────────────────────────────────────────────────
func _build_ui() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)

	# ── 半透明遮罩（拦截鼠标）──
	_overlay_bg = ColorRect.new()
	_overlay_bg.color = Color(0.06, 0.04, 0.09, 0.92)
	_overlay_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay_bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(_overlay_bg)

	# ── 居中容器（与测试面板完全相同的写法）──
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_overlay_bg.add_child(center)

	# ── 主面板：固定宽度 + 最大高度（防止长文溢出屏幕）──
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(760, 0)
	var st := StyleBoxFlat.new()
	st.bg_color     = Color(0.18, 0.14, 0.12, 0.95)
	st.border_color = Color(0.55, 0.40, 0.25, 1.0)
	st.set_border_width_all(3)
	st.set_corner_radius_all(12)
	st.shadow_color = Color(0, 0, 0, 0.5)
	st.shadow_size  = 8
	st.set_content_margin_all(0)
	_panel.add_theme_stylebox_override("panel", st)
	center.add_child(_panel)

	var mg := MarginContainer.new()
	mg.add_theme_constant_override("margin_left",   36)
	mg.add_theme_constant_override("margin_right",  36)
	mg.add_theme_constant_override("margin_top",    28)
	mg.add_theme_constant_override("margin_bottom", 28)
	_panel.add_child(mg)

	var vbox := VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 16)
	mg.add_child(vbox)

	_top_line = ColorRect.new()
	_top_line.color = Color(0.65, 0.45, 0.25, 0.6)
	_top_line.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(_top_line)

	# 类型行
	_type_label = Label.new()
	_type_label.add_theme_font_size_override("font_size", 14)
	_type_label.add_theme_color_override("font_color", Color(0.80, 0.72, 0.56))
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_type_label)

	# 标题行
	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 26)
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.50))
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_title_label)

	var sep := ColorRect.new()
	sep.color = Color(0.55, 0.40, 0.25, 0.35)
	sep.custom_minimum_size = Vector2(0, 1)
	vbox.add_child(sep)

	# 描述：ScrollContainer 包裹，长文不再撑开面板
	var desc_scroll := ScrollContainer.new()
	desc_scroll.custom_minimum_size    = Vector2(0, 80)
	desc_scroll.size_flags_vertical    = Control.SIZE_EXPAND_FILL
	desc_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(desc_scroll)

	_desc_label = RichTextLabel.new()
	_desc_label.bbcode_enabled        = true
	_desc_label.fit_content           = true
	_desc_label.scroll_active         = false
	_desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_desc_label.add_theme_font_size_override("normal_font_size", 18)
	_desc_label.add_theme_color_override("default_color", Color(0.85, 0.82, 0.75))
	desc_scroll.add_child(_desc_label)

	# 选项按钮区
	_opts_container = VBoxContainer.new()
	_opts_container.add_theme_constant_override("separation", 10)
	vbox.add_child(_opts_container)

	# 结果文本
	_result_label = RichTextLabel.new()
	_result_label.bbcode_enabled = true
	_result_label.fit_content    = true
	_result_label.scroll_active  = false
	_result_label.custom_minimum_size = Vector2(0, 40)
	_result_label.add_theme_font_size_override("normal_font_size", 17)
	_result_label.add_theme_color_override("default_color", Color(0.75, 0.92, 0.75))
	_result_label.visible = false
	vbox.add_child(_result_label)

	# 继续按钮
	_continue_btn = Button.new()
	_continue_btn.text = "继续"
	_continue_btn.custom_minimum_size  = Vector2(180, 44)
	_continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_continue_btn.add_theme_font_size_override("font_size", 18)
	_style_option_button(_continue_btn)
	_continue_btn.visible = false
	_continue_btn.pressed.connect(_on_continue)
	vbox.add_child(_continue_btn)

	_bottom_line = ColorRect.new()
	_bottom_line.color = Color(0.65, 0.45, 0.25, 0.6)
	_bottom_line.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(_bottom_line)

func _play_fade_in() -> void:
	_overlay_bg.modulate.a = 0.0
	modulate.a = 0.0
	if _panel:
		_panel.scale = Vector2(0.985, 0.985)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_overlay_bg, "modulate:a", 1.0, 0.22)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.22)
	if _panel:
		tween.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.24)
