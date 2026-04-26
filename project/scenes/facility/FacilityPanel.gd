extends Panel

var current_facility_type: String = ""

@onready var title_label = $TitleLabel
@onready var level_label = $LevelLabel
@onready var cost_label = $CostLabel
@onready var upgrade_button = $UpgradeButton
@onready var action_info_label = $ActionInfoLabel
@onready var action_button = $ActionButton
@onready var close_button = $CloseButton
@onready var facility_manager = get_node("/root/FacilityManager")
@onready var resource_manager = get_node("/root/ResourceManager")
@onready var event_bus = get_node("/root/EventBus")  # 添加 EventBus 引用

# ===================== 文字颜色 =====================
const COLOR_TEXT_TITLE := Color(0.95, 0.82, 0.55, 1.0)
const COLOR_TEXT_NORMAL := Color(0.95, 0.91, 0.82, 1.0)
const COLOR_TEXT_HIGHLIGHT := Color(0.85, 0.70, 0.37, 1.0)
const COLOR_TEXT_WARNING := Color(0.85, 0.70, 0.37, 1.0)
const COLOR_TEXT_SUCCESS := Color(0.49, 0.83, 0.42, 1.0)
const COLOR_TEXT_ERROR := Color(0.85, 0.42, 0.37, 1.0)
const COLOR_TEXT_DISABLED := Color(0.62, 0.57, 0.50, 1.0)
const COLOR_TEXT_OUTLINE := Color(0.16, 0.09, 0.04, 1.0)

func _ready():
	visible = false

	if upgrade_button and not upgrade_button.pressed.is_connected(_on_upgrade_pressed):
		upgrade_button.pressed.connect(_on_upgrade_pressed)
	if action_button and not action_button.pressed.is_connected(_on_action_pressed):
		action_button.pressed.connect(_on_action_pressed)
	if close_button and not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)

	# 让提示文字支持自动换行，避免长句直接溢出
	cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	action_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	_apply_text_style()

	# 通过 EventBus 监听资源变化
	if event_bus and not event_bus.core_resource_changed.is_connected(_on_resource_changed):
		event_bus.core_resource_changed.connect(_on_resource_changed)

func _apply_text_style():
	# 标题
	if title_label:
		title_label.add_theme_font_size_override("font_size", 26)
		title_label.add_theme_color_override("font_color", COLOR_TEXT_TITLE)
		title_label.add_theme_color_override("font_outline_color", COLOR_TEXT_OUTLINE)
		title_label.add_theme_constant_override("outline_size", 2)

	# 左侧信息
	if level_label:
		level_label.add_theme_font_size_override("font_size", 18)
		level_label.add_theme_color_override("font_color", COLOR_TEXT_NORMAL)
		level_label.add_theme_color_override("font_outline_color", COLOR_TEXT_OUTLINE)
		level_label.add_theme_constant_override("outline_size", 1)

	if cost_label:
		cost_label.add_theme_font_size_override("font_size", 18)
		cost_label.add_theme_color_override("font_color", COLOR_TEXT_NORMAL)
		cost_label.add_theme_color_override("font_outline_color", COLOR_TEXT_OUTLINE)
		cost_label.add_theme_constant_override("outline_size", 1)

	# 右侧说明
	if action_info_label:
		action_info_label.add_theme_font_size_override("font_size", 17)
		action_info_label.add_theme_color_override("font_color", COLOR_TEXT_HIGHLIGHT)
		action_info_label.add_theme_color_override("font_outline_color", COLOR_TEXT_OUTLINE)
		action_info_label.add_theme_constant_override("outline_size", 1)

	# 按钮文字
	if upgrade_button:
		upgrade_button.add_theme_font_size_override("font_size", 18)
		upgrade_button.add_theme_color_override("font_color", COLOR_TEXT_NORMAL)
		upgrade_button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
		upgrade_button.add_theme_color_override("font_pressed_color", COLOR_TEXT_NORMAL)
		upgrade_button.add_theme_color_override("font_disabled_color", COLOR_TEXT_DISABLED)

	if action_button:
		action_button.add_theme_font_size_override("font_size", 18)
		action_button.add_theme_color_override("font_color", COLOR_TEXT_NORMAL)
		action_button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
		action_button.add_theme_color_override("font_pressed_color", COLOR_TEXT_NORMAL)
		action_button.add_theme_color_override("font_disabled_color", COLOR_TEXT_DISABLED)

	if close_button:
		close_button.add_theme_font_size_override("font_size", 16)
		close_button.add_theme_color_override("font_color", COLOR_TEXT_NORMAL)
		close_button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))

func open_panel(facility_type: String):
	current_facility_type = facility_type
	_refresh_panel()
	visible = true

func _refresh_panel():
	if not facility_manager or not resource_manager:
		print("管理器未就绪")
		return

	var info = facility_manager.get_facility_info(current_facility_type)
	if info.is_empty():
		title_label.text = "未知设施"
		level_label.text = "当前等级：-"
		cost_label.text = "升级费用：-"
		cost_label.modulate = COLOR_TEXT_NORMAL
		upgrade_button.disabled = true

		action_info_label.text = "互动信息：-"
		action_info_label.modulate = COLOR_TEXT_DISABLED
		action_button.text = "互动未开放"
		action_button.disabled = true
		return

	title_label.text = str(info["name"])

	var current_level = int(info["level"])
	var pending_level = ResourceManager.get_facility_pending_level(current_facility_type)
	var is_repairing = ResourceManager.is_facility_upgrading(current_facility_type)
	var cost = facility_manager.get_upgrade_cost(current_facility_type)

	if is_repairing and pending_level > current_level:
		level_label.text = "当前等级：%d → %d" % [current_level, pending_level]
	else:
		level_label.text = "当前等级：%d" % current_level

	level_label.modulate = COLOR_TEXT_NORMAL

	# ===================== 升级区域刷新 =====================
	if is_repairing:
		cost_label.text = "维修中（下周生效）"
		cost_label.modulate = COLOR_TEXT_WARNING
		upgrade_button.disabled = true
	elif cost < 0:
		cost_label.text = "已满级"
		cost_label.modulate = COLOR_TEXT_WARNING
		upgrade_button.disabled = true
	else:
		# 检查是否可升级（等级未满 + 资金足够 + 有行动点 + 主设施等级限制）
		var can_upgrade = facility_manager.can_upgrade(current_facility_type)
		upgrade_button.disabled = not can_upgrade

		# 显示提示信息
		if not can_upgrade:
			var fail_reason = ""

			# 优先使用 FacilityManager 返回的精确失败原因
			if facility_manager.has_method("get_upgrade_fail_reason"):
				fail_reason = facility_manager.get_upgrade_fail_reason(current_facility_type)

			if fail_reason == "":
				fail_reason = "当前不可升级"

			cost_label.text = fail_reason
			cost_label.modulate = COLOR_TEXT_ERROR
		else:
			cost_label.text = "升级费用：%d" % cost
			cost_label.modulate = COLOR_TEXT_NORMAL

	# ===================== 互动区域刷新 =====================
	_refresh_action_area()

func _refresh_action_area():
	if not facility_manager.has_method("get_facility_action_info"):
		action_info_label.text = "互动信息：未开放"
		action_info_label.modulate = COLOR_TEXT_DISABLED
		action_button.text = "互动未开放"
		action_button.disabled = true
		return

	var action_info = facility_manager.get_facility_action_info(current_facility_type)

	var action_name = str(action_info.get("action_name", "未开放"))
	var cost_text = str(action_info.get("cost_text", ""))
	var reward_text = str(action_info.get("reward_text", ""))
	var enabled = bool(action_info.get("enabled", false))
	var reason = str(action_info.get("reason", ""))

	action_button.text = action_name

	if action_name == "未开放":
		action_info_label.text = "互动信息：未开放"
		action_info_label.modulate = COLOR_TEXT_DISABLED
		action_button.disabled = true
		return

	if enabled:
		action_info_label.text = "%s\n%s" % [cost_text, reward_text]
		action_info_label.modulate = COLOR_TEXT_HIGHLIGHT
		action_button.disabled = false
	else:
		if reason == "":
			reason = "当前无法执行"
		action_info_label.text = "%s\n%s\n%s" % [cost_text, reward_text, reason]
		action_info_label.modulate = COLOR_TEXT_WARNING
		action_button.disabled = true

func _on_upgrade_pressed():
	if not facility_manager or not resource_manager:
		return

	# 维修中时禁止重复点击
	if ResourceManager.is_facility_upgrading(current_facility_type):
		cost_label.text = "维修中（下周生效）"
		cost_label.modulate = COLOR_TEXT_WARNING
		return

	# 执行升级
	var result = facility_manager.upgrade_facility(current_facility_type)

	if result["success"]:
		print("设施升级成功 - 类型: %s" % current_facility_type)

		# 立刻刷新当前场景里的对应设施按钮，不用切场景
		_refresh_current_scene_facility_button()

		_refresh_panel()

		# 通知主场景升级完成
		var main_scene = get_tree().current_scene
		if main_scene and main_scene.has_method("on_facility_upgraded"):
			main_scene.on_facility_upgraded()

		# 显示成功提示
		cost_label.text = "升级成功！"
		cost_label.modulate = COLOR_TEXT_SUCCESS
		await get_tree().create_timer(1.0).timeout
		_refresh_panel()
	else:
		# 升级失败时显示短提示
		cost_label.text = str(result["reason"])
		cost_label.modulate = COLOR_TEXT_ERROR
		upgrade_button.disabled = true

func _on_action_pressed():
	if not facility_manager or not resource_manager:
		return

	if not facility_manager.has_method("perform_facility_action"):
		action_info_label.text = "互动功能未接入"
		action_info_label.modulate = COLOR_TEXT_ERROR
		return

	var result = facility_manager.perform_facility_action(current_facility_type)

	if result.get("success", false):
		var changes = result.get("changes", {})
		var tips := []

		if changes.has("money"):
			var money_change = int(changes["money"])
			tips.append("资金 %+d" % money_change)

		if changes.has("creativity"):
			var creativity_change = int(changes["creativity"])
			tips.append("创造力 %+d" % creativity_change)

		if changes.has("cohesion"):
			var cohesion_change = int(changes["cohesion"])
			tips.append("凝聚力 %+d" % cohesion_change)

		if changes.has("reputation"):
			var reputation_change = int(changes["reputation"])
			tips.append("声誉 %+d" % reputation_change)

		if changes.has("fatigue_recovery"):
			var fatigue_recovery = int(changes["fatigue_recovery"])
			tips.append("全员疲劳 -%d" % fatigue_recovery)

		if tips.is_empty():
			action_info_label.text = "互动执行成功！"
		else:
			action_info_label.text = "互动成功：\n" + "\n".join(tips)

		action_info_label.modulate = COLOR_TEXT_SUCCESS
		action_button.disabled = true
		upgrade_button.disabled = true

		await get_tree().create_timer(1.0).timeout
		_refresh_panel()
	else:
		action_info_label.text = str(result.get("reason", "互动失败"))
		action_info_label.modulate = COLOR_TEXT_ERROR
		action_button.disabled = true

func _on_resource_changed(resource_name: String, new_value: int, delta: int):
	# 当核心资源变化时刷新面板显示
	if visible and (
		resource_name == "money" or
		resource_name == "creativity" or
		resource_name == "cohesion" or
		resource_name == "reputation"
	):
		_refresh_panel()

func _refresh_current_scene_facility_button():
	var current_scene = get_tree().current_scene
	if not current_scene:
		return

	var button_path := ""

	match current_facility_type:
		"stage":
			button_path = "UILayer/StageButton"
		"bar":
			button_path = "UILayer/BarButton"
		"lounge":
			button_path = "UILayer/LoungeButton"
		"rehearsal":
			button_path = "UILayer/RehearsalButton"

	if button_path == "":
		return

	var facility_button = current_scene.get_node_or_null(button_path)
	if facility_button and facility_button.has_method("refresh_repair_state"):
		facility_button.refresh_repair_state()

func _on_close_pressed():
	visible = false

func close_panel():
	visible = false
