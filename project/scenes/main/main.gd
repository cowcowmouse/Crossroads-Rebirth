extends Node2D  # 核心：适配Node2D

# ===================== 节点引用 =====================
# 箭头节点
@onready var arrow_left = get_node_or_null("ArrowLeft")
@onready var arrow_right = get_node_or_null("ArrowRight")
# 对话按钮
@onready var button = get_node_or_null("Button")
# 引用康复面板
@onready var rehab_panel = $UILayer/Rehabpanel
# 顶部康复触发按钮
@onready var rehab_trigger_btn = $UILayer/TopBar/RehabBtn
# 顶部UI状态标签（这里改了文件结构，每个资源显示的UI单独开一组，方便设计单独图标）
@onready var money_label = get_node_or_null("UILayer/TopBar/MoneyGroup/MoneyLabel")
@onready var reputation_label = get_node_or_null("UILayer/TopBar/ReputationGroup/ReputationLabel")
@onready var cohesion_label = get_node_or_null("UILayer/TopBar/CohesionGroup/CohesionLabel")
@onready var creativity_label = get_node_or_null("UILayer/TopBar/CreativityGroup/CreativityLabel")
@onready var memory_label = get_node_or_null("UILayer/TopBar/MemoryGroup/MemoryLabel")
@onready var action_point_label = get_node_or_null("UILayer/TopBar/ActionPointGroup/ActionPointLabel")
@onready var money_icon = get_node_or_null("UILayer/TopBar/MoneyGroup/MoneyIcon")
@onready var reputation_icon = get_node_or_null("UILayer/TopBar/ReputationGroup/ReputationIcon")
@onready var cohesion_icon = get_node_or_null("UILayer/TopBar/CohesionGroup/CohesionIcon")
@onready var creativity_icon = get_node_or_null("UILayer/TopBar/CreativityGroup/CreativityIcon")
@onready var memory_icon = get_node_or_null("UILayer/TopBar/MemoryGroup/MemoryIcon")
@onready var action_point_icon = get_node_or_null("UILayer/TopBar/ActionPointGroup/ActionPointIcon")

@onready var tutorial_layer = $TutorialLayer

@onready var action_skip_panel = $UILayer/TopBar/ActionSkipPanel
@onready var clock_icon = $UILayer/TopBar/ClockIcon
@onready var skip_button = $UILayer/SkipButton
@onready var settings_button = $UILayer/SettingsButton

# 周数 / 阶段显示节点
@onready var week_phase_group = get_node_or_null("UILayer/TopBar/WeekPhaseGroup")
@onready var week_label = get_node_or_null("UILayer/TopBar/WeekPhaseGroup/WeekLabel")
@onready var divider_label = get_node_or_null("UILayer/TopBar/WeekPhaseGroup/DividerLabel")
@onready var phase_label = get_node_or_null("UILayer/TopBar/WeekPhaseGroup/PhaseLabel")
@onready var before_dot = get_node_or_null("UILayer/TopBar/WeekPhaseGroup/PhaseDotContainer/BeforeDot")
@onready var mid_dot = get_node_or_null("UILayer/TopBar/WeekPhaseGroup/PhaseDotContainer/MidDot")
@onready var after_dot = get_node_or_null("UILayer/TopBar/WeekPhaseGroup/PhaseDotContainer/AfterDot")

@onready var settings_panel = $UILayer/SettingsPanel
@onready var volume_slider = $UILayer/SettingsPanel/VolumeSlider
@onready var close_button = $UILayer/SettingsPanel/CloseButton

# 管理器引用
@onready var week_cycle = get_node("/root/WeekCycleManager")
@onready var skip_panel_manager = get_node("/root/SkipPanelManager")

# 周阶段 UI 颜色
const WEEK_PHASE_ACTIVE_COLOR := Color(0.98, 0.84, 0.42, 1.0)
const WEEK_PHASE_INACTIVE_COLOR := Color(0.42, 0.32, 0.20, 0.95)
const WEEK_PHASE_TEXT_COLOR := Color(1.0, 0.94, 0.82, 1.0)
const WEEK_PHASE_TEXT_DIM_COLOR := Color(0.72, 0.66, 0.58, 1.0)

# ClockIcon 在不同阶段的高亮颜色
const CLOCK_ICON_BEFORE_COLOR := Color(1.00, 0.93, 0.78, 1.0)
const CLOCK_ICON_MID_COLOR := Color(0.82, 0.90, 1.00, 1.0)
const CLOCK_ICON_AFTER_COLOR := Color(1.00, 0.82, 0.68, 1.0)
const CLOCK_ICON_DIM_COLOR := Color(0.65, 0.65, 0.65, 1.0)

# 周阶段切换演出脚本
const WEEK_TRANSITION_OVERLAY_SCRIPT = preload("res://project/scripts/ui/WeekTransitionOverlay.gd")
const MEMBER_EVENT_DIALOG_SCENE = preload("res://project/scenes/event/MemberEventDialog.tscn")

# SkipButton 防连点状态
var is_skip_button_processing: bool = false

# 记录上一次时钟阶段，避免重复播放动效
var _last_clock_phase: int = -1

# 记录上一次高亮的阶段点，避免重复播放动效
var _last_phase_dot_index: int = -1

# ===================== 周阶段切换演出层 =====================
var week_transition_overlay: Node = null
var is_week_transition_playing: bool = false

# 安全等待函数，避免 null 错误
func safe_wait_frames(frame_count: int):
	for i in range(frame_count):
		await Engine.get_main_loop().process_frame


# ===================== 初始化 =====================
func _ready():
	connect_dialogic_signals()

	# 初始化顶部UI显示（示例数值，可自定义）
	init_top_ui()
	_init_week_phase_ui()

	# 箭头节点绑定（保留你的原有逻辑）
	print("当前脚本附加的节点：", self.name)
	print("所有子节点：")
	for child in get_children():
		print("  - ", child.name)

	# 如果没找到，尝试用find_child再找一次
	if not arrow_left:
		arrow_left = find_child("ArrowLeft", true, false)
	if not arrow_right:
		arrow_right = find_child("ArrowRight", true, false)

	# ===== 连接箭头按钮 =====
	print("\n===== 连接按钮 =====")

	# 左箭头
	if arrow_left:
		print("左箭头找到，类型：", arrow_left.get_class())
		if arrow_left.has_signal("pressed"):
			arrow_left.pressed.connect(_on_arrow_left_pressed)
			print("左箭头连接成功")
		elif arrow_left.has_signal("gui_input"):
			arrow_left.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_on_arrow_left_pressed()
			)
			print("左箭头连接成功")
	else:
		print("左箭头未找到")

	# 右箭头
	if arrow_right:
		print("右箭头找到，类型：", arrow_right.get_class())
		if arrow_right.has_signal("pressed"):
			arrow_right.pressed.connect(_on_arrow_right_pressed)
			print("右箭头连接成功")
		elif arrow_right.has_signal("gui_input"):
			arrow_right.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_on_arrow_right_pressed()
			)
			print("右箭头连接成功")
	else:
		print("右箭头未找到")

	# 等待所有节点就绪
	await get_tree().process_frame

	# 手动添加分组
	ensure_button_groups()

	# 验证分组
	check_groups()

	# 初始化周循环
	_init_week_cycle()

	# 初始化跳过面板
	_init_skip_panel()

	# 初始化时钟显示
	_init_clock_display()

	# 创建周阶段切换演出层
	_create_week_transition_overlay()

	# 连接信号
	_connect_week_cycle_signals()

	# 连接跳过按钮
	if skip_button and not skip_button.pressed.is_connected(_on_skip_button_pressed):
		skip_button.pressed.connect(_on_skip_button_pressed)

	if not EventBus.minigame_finished.is_connected(_on_minigame_finished):
		EventBus.minigame_finished.connect(_on_minigame_finished)

	# 创建调试面板
	_create_debug_panel()

	# 读取记忆事件配置
	_load_memory_event_data()

	# 创建记忆阶段事件面板
	_create_memory_event_panel()

	# 注册调试快捷键
	_register_debug_input()

	if settings_button and not settings_button.pressed.is_connected(_on_settings_pressed):
		settings_button.pressed.connect(_on_settings_pressed)
	if close_button and not close_button.pressed.is_connected(_on_close_settings_pressed):
		close_button.pressed.connect(_on_close_settings_pressed)
	if volume_slider and not volume_slider.value_changed.is_connected(_on_volume_changed):
		volume_slider.value_changed.connect(_on_volume_changed)
	if rehab_trigger_btn and not rehab_trigger_btn.pressed.is_connected(_on_rehab_trigger):
		rehab_trigger_btn.pressed.connect(_on_rehab_trigger)

# 如果你的 Rehabpanel.gd 里定义的是 panel_closed 信号，就这样接
	if rehab_panel and rehab_panel.has_signal("panel_closed"):
		if not rehab_panel.panel_closed.is_connected(_on_rehab_panel_closed):
			rehab_panel.panel_closed.connect(_on_rehab_panel_closed)
	# 初始隐藏设置面板
	if settings_panel:
		settings_panel.visible = false

	# 加载保存的音量设置
	_load_volume_setting()
	call_deferred("_maybe_show_post_midweek_member_event")


func _maybe_show_post_midweek_member_event():
	if not MemberEventManager.has_post_midweek_return_events():
		return
	MemberEventManager.consume_post_midweek_return_flag()
	var dialog = MEMBER_EVENT_DIALOG_SCENE.instantiate()
	if dialog == null:
		return
	dialog.close_when_finished = true
	var ui_host = get_node_or_null("UILayer")
	if ui_host:
		ui_host.add_child(dialog)
	else:
		add_child(dialog)

func _on_settings_pressed():
	_play_ui_click_sound()
	print("打开设置面板")
	settings_panel.visible = true


func _on_close_settings_pressed():
	_play_ui_click_sound()
	print("关闭设置面板")
	settings_panel.visible = false


func _on_volume_changed(value: float):
	print("音量变化: ", value)
	AudioManager.set_bgm_volume(value)
	_save_volume_setting(value)


func _save_volume_setting(value: float):
	var config = ConfigFile.new()
	config.set_value("audio", "bgm_volume", value)
	config.save("user://settings.cfg")


func _load_volume_setting():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var volume = config.get_value("audio", "bgm_volume", 0.8)
		volume_slider.value = volume
		AudioManager.set_bgm_volume(volume)
	else:
		volume_slider.value = 0.8
		AudioManager.set_bgm_volume(0.8)


# ===================== UI点击音效 =====================
func _play_ui_click_sound():
	if AudioManager and AudioManager.has_method("play_ui_click"):
		AudioManager.play_ui_click()


func _register_debug_input():
	# 确保调试动作存在
	if not InputMap.has_action("toggle_debug"):
		InputMap.add_action("toggle_debug")

	# 添加 F12 键位（避免重复添加）
	var key_event = InputEventKey.new()
	key_event.keycode = KEY_F12

	# 检查是否已经添加过这个事件
	var existing_events = InputMap.action_get_events("toggle_debug")
	var already_exists = false
	for event in existing_events:
		if event is InputEventKey and event.keycode == KEY_F12:
			already_exists = true
			break

	if not already_exists:
		InputMap.action_add_event("toggle_debug", key_event)


func _input(event):
	if event.is_action_pressed("toggle_debug"):
		_toggle_debug_panel()


func _init_week_cycle():
	if not week_cycle:
		print("❌ WeekCycleManager 未找到")
		return

	# 不要强制设置阶段，保持 WeekCycleManager 当前阶段
	# week_cycle.set_phase(week_cycle.GamePhase.BEFORE_WEEK)  # 删除这行

	# 顶部UI统一从 ResourceManager 读取，避免与 week_cycle 显示冲突
	ResourceManager.refresh_current_scene_topbar()

	# 如果当前资源管理器里的行动点已经耗尽，直接显示跳过面板
	if ResourceManager.get_action_points() == 0:
		if skip_panel_manager:
			skip_panel_manager.show_skip_panel(true)

	# 根据当前阶段更新UI
	match week_cycle.get_current_phase():
		0:
			print("当前阶段: 周前")
		1:
			print("当前阶段: 周中")
			_set_operation_ui_enabled(false)
		2:
			print("当前阶段: 周后")
			_set_operation_ui_enabled(false)

	_refresh_week_phase_ui()
	_refresh_skip_button_ui()


func _init_skip_panel():
	if action_skip_panel and skip_panel_manager:
		skip_panel_manager.register_panel(action_skip_panel)
		skip_panel_manager.skip_to_next_phase.connect(_on_skip_to_next_phase)


func _init_clock_display():
	# 时钟显示已在 clock_display.gd 中处理
	pass


func _connect_week_cycle_signals():
	if week_cycle:
		if not week_cycle.action_points_updated.is_connected(_on_action_points_updated):
			week_cycle.action_points_updated.connect(_on_action_points_updated)

	if not EventBus.week_phase_changed.is_connected(_on_week_phase_changed):
		EventBus.week_phase_changed.connect(_on_week_phase_changed)

	if not EventBus.week_changed.is_connected(_on_week_changed):
		EventBus.week_changed.connect(_on_week_changed)


# ===================== 周数 / 阶段显示 UI =====================
func _init_week_phase_ui():
	if week_phase_group:
		week_phase_group.visible = true

	if week_label:
		week_label.add_theme_color_override("font_color", WEEK_PHASE_TEXT_COLOR)
	if divider_label:
		divider_label.text = "｜"
		divider_label.add_theme_color_override("font_color", WEEK_PHASE_TEXT_DIM_COLOR)
	if phase_label:
		phase_label.add_theme_color_override("font_color", WEEK_PHASE_ACTIVE_COLOR)

	_init_phase_dot(before_dot)
	_init_phase_dot(mid_dot)
	_init_phase_dot(after_dot)

	if clock_icon:
		clock_icon.scale = Vector2.ONE

	_refresh_week_phase_ui()
	_refresh_clock_icon_ui()
	_refresh_skip_button_ui()
	_set_skip_button_enabled(true)
	_init_skip_button_feedback()
	call_deferred("_prepare_skip_button_pivot")


func _init_phase_dot(dot: ColorRect):
	if not dot:
		return
	dot.custom_minimum_size = Vector2(14, 14)
	dot.color = WEEK_PHASE_INACTIVE_COLOR
	dot.scale = Vector2.ONE
	var style = StyleBoxFlat.new()
	style.bg_color = dot.color
	style.set_corner_radius_all(999)
	dot.add_theme_stylebox_override("panel", style)


func _prepare_skip_button_pivot():
	if skip_button:
		skip_button.pivot_offset = skip_button.size * 0.5


func _init_skip_button_feedback():
	if not skip_button:
		return

	if not skip_button.mouse_entered.is_connected(_on_skip_button_mouse_entered):
		skip_button.mouse_entered.connect(_on_skip_button_mouse_entered)
	if not skip_button.mouse_exited.is_connected(_on_skip_button_mouse_exited):
		skip_button.mouse_exited.connect(_on_skip_button_mouse_exited)


func _on_skip_button_mouse_entered():
	if not skip_button or skip_button.disabled:
		return

	var tween = create_tween()
	tween.tween_property(skip_button, "scale", Vector2(1.04, 1.04), 0.08)


func _on_skip_button_mouse_exited():
	if not skip_button:
		return

	var tween = create_tween()
	tween.tween_property(skip_button, "scale", Vector2.ONE, 0.08)


func _on_week_changed(week: int):
	_refresh_week_phase_ui()
	_refresh_all_facility_buttons()

func _refresh_all_facility_buttons():
	var button_paths = [
		"UILayer/StageButton",
		"UILayer/BarButton",
		"UILayer/LoungeButton",
		"UILayer/RehearsalButton"
	]

	for path in button_paths:
		var btn = get_node_or_null(path)
		if btn and btn.has_method("refresh_repair_state"):
			btn.refresh_repair_state()

func _get_week_phase_display_name(phase: int) -> String:
	match phase:
		0:
			return "周初"
		1:
			return "周中"
		2:
			return "周末"
	return "未知"


func _refresh_week_phase_ui():
	if not week_cycle:
		return

	var current_week = week_cycle.get_current_week()
	var current_phase = week_cycle.get_current_phase()

	if week_label:
		week_label.text = "第 %d 周" % current_week

	if phase_label:
		phase_label.text = _get_week_phase_display_name(current_phase)

	_update_phase_dots(current_phase)
	_refresh_clock_icon_ui()


func _update_phase_dots(current_phase: int):
	# 先同步三颗点的基础颜色
	if before_dot:
		before_dot.color = WEEK_PHASE_ACTIVE_COLOR if current_phase == 0 else WEEK_PHASE_INACTIVE_COLOR
	if mid_dot:
		mid_dot.color = WEEK_PHASE_ACTIVE_COLOR if current_phase == 1 else WEEK_PHASE_INACTIVE_COLOR
	if after_dot:
		after_dot.color = WEEK_PHASE_ACTIVE_COLOR if current_phase == 2 else WEEK_PHASE_INACTIVE_COLOR

	# 第一次初始化时只记录，不播放动画
	if _last_phase_dot_index == -1:
		_last_phase_dot_index = current_phase
		return

	# 阶段没变，不重复播放
	if _last_phase_dot_index == current_phase:
		return

	_last_phase_dot_index = current_phase

	# 只让当前高亮的那颗点播放轻微弹动
	match current_phase:
		0:
			_play_phase_dot_feedback(before_dot)
		1:
			_play_phase_dot_feedback(mid_dot)
		2:
			_play_phase_dot_feedback(after_dot)


# 当前阶段点切换时的轻微弹动效果
func _play_phase_dot_feedback(dot: ColorRect):
	if not dot:
		return

	# 确保 pivot 在中心，放大时更自然
	dot.pivot_offset = dot.size * 0.5

	var tween = create_tween()
	tween.tween_property(dot, "scale", Vector2(1.28, 1.28), 0.08)
	tween.tween_property(dot, "scale", Vector2.ONE, 0.10)


# 刷新 ClockIcon 的阶段高亮，并在阶段切换时播放轻微反馈
func _refresh_clock_icon_ui():
	if not clock_icon or not week_cycle:
		return

	var current_phase = week_cycle.get_current_phase()
	var target_color = CLOCK_ICON_DIM_COLOR

	match current_phase:
		week_cycle.GamePhase.BEFORE_WEEK:
			target_color = CLOCK_ICON_BEFORE_COLOR
		week_cycle.GamePhase.MID_WEEK:
			target_color = CLOCK_ICON_MID_COLOR
		week_cycle.GamePhase.AFTER_WEEK:
			target_color = CLOCK_ICON_AFTER_COLOR
		_:
			target_color = CLOCK_ICON_DIM_COLOR

	# 第一次初始化时不播动效，只记录状态并设置颜色
	if _last_clock_phase == -1:
		_last_clock_phase = current_phase
		clock_icon.modulate = target_color
		return

	# 阶段没变，只同步颜色，不重复播动画
	if _last_clock_phase == current_phase:
		clock_icon.modulate = target_color
		return

	_last_clock_phase = current_phase
	_play_clock_icon_phase_feedback(target_color)


# 时钟图标阶段切换动效：轻微放大 + 颜色过渡
func _play_clock_icon_phase_feedback(target_color: Color):
	if not clock_icon:
		return

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(clock_icon, "modulate", target_color, 0.16)
	tween.tween_property(clock_icon, "scale", Vector2(1.10, 1.10), 0.10)
	tween.set_parallel(false)
	tween.tween_property(clock_icon, "scale", Vector2.ONE, 0.10)


# 统一设置 SkipButton 是否可点，防止连点
func _set_skip_button_enabled(enabled: bool):
	if not skip_button:
		return

	skip_button.disabled = not enabled
	skip_button.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE

	if not enabled:
		skip_button.scale = Vector2.ONE


func _refresh_skip_button_ui():
	if not skip_button or not week_cycle:
		return

	var phase = week_cycle.get_current_phase()
	var button_text := ""
	var tooltip := ""
	var base_color := Color(0.30, 0.22, 0.18, 0.95)

	match phase:
		week_cycle.GamePhase.BEFORE_WEEK:
			button_text = "▶ 进入周中"
			tooltip = "结束当前操作阶段，进入周中事件阶段"
			base_color = Color(0.36, 0.26, 0.18, 0.96)
		week_cycle.GamePhase.MID_WEEK:
			button_text = "▶ 进入周末"
			tooltip = "结束周中事件，进入周末阶段"
			base_color = Color(0.30, 0.24, 0.14, 0.96)
		week_cycle.GamePhase.AFTER_WEEK:
			button_text = "★ 开始结算"
			tooltip = "执行周末结算 / 进入下一周"
			base_color = Color(0.46, 0.28, 0.12, 0.98)

	skip_button.text = button_text
	skip_button.tooltip_text = tooltip
	_apply_skip_button_style(base_color)


func _apply_skip_button_style(base_color: Color):
	if not skip_button:
		return

	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = base_color
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.96, 0.82, 0.48, 1.0)
	normal_style.set_corner_radius_all(10)

	var hover_style = normal_style.duplicate()
	hover_style.bg_color = base_color.lightened(0.12)

	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = base_color.darkened(0.14)

	var disabled_style = normal_style.duplicate()
	disabled_style.bg_color = Color(0.22, 0.22, 0.22, 0.80)
	disabled_style.border_color = Color(0.55, 0.55, 0.55, 0.80)

	skip_button.add_theme_stylebox_override("normal", normal_style)
	skip_button.add_theme_stylebox_override("hover", hover_style)
	skip_button.add_theme_stylebox_override("pressed", pressed_style)
	skip_button.add_theme_stylebox_override("disabled", disabled_style)
	skip_button.add_theme_color_override("font_color", Color(1, 0.97, 0.88, 1))
	skip_button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	skip_button.add_theme_color_override("font_pressed_color", Color(1, 0.95, 0.85, 1))
	skip_button.add_theme_color_override("font_disabled_color", Color(0.72, 0.72, 0.72, 0.9))


func _play_skip_button_press_feedback():
	if not skip_button:
		return

	var tween = create_tween()
	tween.tween_property(skip_button, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(skip_button, "scale", Vector2.ONE, 0.08)
	await tween.finished


# ===================== 周阶段切换演出 =====================
func _create_week_transition_overlay():
	var root_node = get_tree().root
	if not root_node:
		print("❌ 未找到 root，无法创建周阶段切换演出层")
		return

	# 避免重复创建
	if week_transition_overlay and is_instance_valid(week_transition_overlay):
		return

	var existing = root_node.get_node_or_null("WeekTransitionOverlay")
	if existing:
		week_transition_overlay = existing
		return

	week_transition_overlay = WEEK_TRANSITION_OVERLAY_SCRIPT.new()
	week_transition_overlay.name = "WeekTransitionOverlay"
	root_node.add_child(week_transition_overlay)


func _play_week_phase_transition(on_midpoint: Callable = Callable()):
	# 避免重复播放
	if is_week_transition_playing:
		return

	if not week_transition_overlay or not is_instance_valid(week_transition_overlay):
		_create_week_transition_overlay()

	# 如果演出层创建失败，则直接执行后续逻辑
	if not week_transition_overlay or not week_transition_overlay.has_method("play_transition"):
		if on_midpoint.is_valid():
			on_midpoint.call()
		_finish_week_phase_transition()
		return

	is_week_transition_playing = true

	# 演出期间统一锁住主要交互
	_set_skip_button_enabled(false)
	_set_ui_enabled(false)

	if settings_button:
		settings_button.disabled = true
	if rehab_trigger_btn:
		rehab_trigger_btn.disabled = true

	# 黑幕完全盖住时执行真正的切换逻辑；淡出结束后再恢复状态
	week_transition_overlay.play_transition(
		on_midpoint,
		Callable(self, "_finish_week_phase_transition")
	)


func _finish_week_phase_transition():
	is_week_transition_playing = false
	is_skip_button_processing = false

	# 默认恢复交互
	_set_ui_enabled(true)
	_set_skip_button_enabled(true)

	if settings_button:
		settings_button.disabled = false
	if rehab_trigger_btn:
		rehab_trigger_btn.disabled = false


func _after_week_transition_to_before():
	# 周初阶段恢复操作
	_set_operation_ui_enabled(true)
	_set_ui_enabled(true)
	_set_skip_button_enabled(true)

	if settings_button:
		settings_button.disabled = false
	if rehab_trigger_btn:
		rehab_trigger_btn.disabled = false

	if skip_panel_manager:
		skip_panel_manager.hide_skip_panel()

	_refresh_week_phase_ui()
	_refresh_clock_icon_ui()
	_refresh_skip_button_ui()


func _after_week_transition_to_mid():
	# 周中阶段进入事件
	_trigger_mid_week_event()


func _after_week_transition_to_after():
	# 周末阶段进入小游戏 / 周末流程
	_enter_minigame()


func _on_week_phase_changed(phase: int):
	# phase: 0=周前, 1=周中, 2=周后
	match phase:
		0:
			print("进入周初阶段 - 玩家可以操作")
			if week_cycle:
				week_cycle.set_phase(week_cycle.GamePhase.BEFORE_WEEK)
			_play_week_phase_transition(Callable(self, "_after_week_transition_to_before"))
		1:
			print("进入周中阶段 - 触发事件")
			if week_cycle:
				week_cycle.set_phase(week_cycle.GamePhase.MID_WEEK)
			_set_operation_ui_enabled(false)
			_play_week_phase_transition(Callable(self, "_after_week_transition_to_mid"))
		2:
			print("进入周末阶段 - 等待用户点击跳过按钮结算")
			if week_cycle:
				week_cycle.set_phase(week_cycle.GamePhase.AFTER_WEEK)
			_set_operation_ui_enabled(false)
			_play_week_phase_transition(Callable(self, "_after_week_transition_to_after"))

	_refresh_week_phase_ui()
	_refresh_clock_icon_ui()
	_refresh_skip_button_ui()


func _on_action_points_updated(current: int, max: int):
	_update_action_point_display(current, max)

	# 如果行动点为0，显示强制跳过面板
	if current == 0:
		if skip_panel_manager:
			skip_panel_manager.show_skip_panel(true)


func _update_action_point_display(current: int, max: int):
	# 行动点显示统一同步到 ResourceManager，再由顶部UI统一刷新
	ResourceManager.action_points = current
	ResourceManager.refresh_current_scene_topbar()

	# 行动点耗尽时改变颜色
	if action_point_label:
		if current == 0:
			action_point_label.modulate = Color.RED
		else:
			action_point_label.modulate = Color.WHITE


func _set_operation_ui_enabled(enabled: bool):
	# 禁用/启用设施升级按钮
	var facility_panel = $UILayer/FacilityPanel
	if facility_panel and facility_panel.upgrade_button:
		facility_panel.upgrade_button.disabled = not enabled

	# 禁用/启用康复按钮
	if rehab_trigger_btn:
		rehab_trigger_btn.disabled = not enabled

	# 禁用/启用成员对话按钮（如果有）
	# 可以根据需要添加更多


func _trigger_mid_week_event():
	print("触发周中事件...")

	# 测试：直接加载 test_event.tscn 场景
	get_tree().change_scene_to_file("res://project/scenes/event/EventDialog.tscn")


func _safe_wait(seconds: float):
	if is_inside_tree() and get_tree():
		await get_tree().create_timer(seconds).timeout
	else:
		await Engine.get_main_loop().create_timer(seconds).timeout


func _check_game_over():
	var money = ResourceManager.get_resource_value(Constants.RES_MONEY)
	var cohesion = ResourceManager.get_resource_value(Constants.RES_COHESION)

	if money <= 0:
		print("游戏结束：资金耗尽")
		EventBus.game_over.emit("bankrupt")
	elif cohesion <= 0:
		print("游戏结束：成员解散")
		EventBus.game_over.emit("band_broken")


func _on_skip_to_next_phase():
	# 演出期间不允许继续推进阶段
	if is_week_transition_playing:
		return

	_play_ui_click_sound()

	# 手动跳过当前阶段
	if week_cycle.get_current_phase() == week_cycle.GamePhase.BEFORE_WEEK:
		week_cycle.force_to_mid_week()
	elif week_cycle.get_current_phase() == week_cycle.GamePhase.MID_WEEK:
		week_cycle.complete_mid_week()
	elif week_cycle.get_current_phase() == week_cycle.GamePhase.AFTER_WEEK:
		week_cycle.complete_week_settlement()


# 手动进入周中（可选：右下角按钮）
func _on_skip_to_mid_week_pressed():
	# 演出期间不允许继续推进阶段
	if is_week_transition_playing:
		return

	_play_ui_click_sound()

	if week_cycle and week_cycle.get_current_phase() == week_cycle.GamePhase.BEFORE_WEEK:
		week_cycle.force_to_mid_week()


func connect_dialogic_signals():
	print("\n=== 连接 Dialogic 信号 ===")

	# 检查 Dialogic 是否可用
	if not Dialogic:
		print("❌ Dialogic 不可用！")
		return

	# 使用正确的方式等待 Dialogic 就绪
	if not Dialogic.is_node_ready():
		print("⏳ 等待 Dialogic 就绪...")
		await Dialogic.ready
		print("✅ Dialogic 已就绪")
	else:
		print("✅ Dialogic 已就绪")

	# 先断开可能存在的旧连接
	if Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_timeline_ended)

	if Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.disconnect(_on_dialogic_signal)

	# 重新连接
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	Dialogic.signal_event.connect(_on_dialogic_signal)

	# 也连接开始信号用于调试
	if not Dialogic.timeline_started.is_connected(_on_timeline_started):
		Dialogic.timeline_started.connect(_on_timeline_started)

	print("✅ Dialogic 信号连接成功")
	print("   timeline_started 已连接: ", Dialogic.timeline_started.is_connected(_on_timeline_started))
	print("   timeline_ended 已连接: ", Dialogic.timeline_ended.is_connected(_on_timeline_ended))
	print("   signal_event 已连接: ", Dialogic.signal_event.is_connected(_on_dialogic_signal))


func ensure_button_groups():
	print("\n=== 手动添加按钮分组 ===")

	# 左箭头
	if arrow_left:
		if not arrow_left.is_in_group("left_arrow"):
			arrow_left.add_to_group("left_arrow")
			print("✅ 左箭头已加入 left_arrow 分组")
		else:
			print("左箭头已在分组中")

	# 右箭头
	if arrow_right:
		if not arrow_right.is_in_group("right_arrow"):
			arrow_right.add_to_group("right_arrow")
			print("✅ 右箭头已加入 right_arrow 分组")
		else:
			print("右箭头已在分组中")

	# 检查返回按钮（如果存在）
	var back_btn = find_child("BackButton", true, false)
	if back_btn:
		if not back_btn.is_in_group("back_button"):
			back_btn.add_to_group("back_button")
			print("✅ 返回按钮已加入 back_button 分组")


func check_groups():
	print("\n=== 检查按钮分组 ===")
	var left = get_tree().get_nodes_in_group("left_arrow")
	var right = get_tree().get_nodes_in_group("right_arrow")

	print("left_arrow 组: ", left.size())
	for btn in left:
		print("  - ", btn.name)

	print("right_arrow 组: ", right.size())
	for btn in right:
		print("  - ", btn.name)


func _on_timeline_started(timeline_name: String):
	print("📢 对话开始：", timeline_name)


func _on_timeline_ended(timeline_name: String):
	print("📢 对话结束：", timeline_name)

	# 检查是否是我们要触发引导的对话
	if timeline_name == "old_nail":  # 你的对话文件名
		# 延迟一点点，让场景稳定
		await get_tree().create_timer(0.3).timeout

		# 开始引导
		start_tutorial()


func _on_dialogic_signal(argument: String):
	print("📢 收到 Dialogic 自定义信号: ", argument)

	if argument == "old_nail_ended":
		print("✅ 匹配到 old_nail_ended 信号，开始引导")
		await get_tree().create_timer(0.3).timeout
		start_tutorial()


func start_tutorial():
	print("🎯 开始引导流程")

	# 第一步：高亮左箭头
	# 注意：这里不需要 await，因为 highlight_button 内部会处理等待
	tutorial_layer.highlight_button("left_arrow", "点击左箭头切换场景")


# ===================== 顶部UI初始化 =====================
func init_top_ui():
	ResourceManager.refresh_current_scene_topbar()
	if money_label:
		money_label.text = "资金: %d" % ResourceManager.get_resource_value(Constants.RES_MONEY)

	if reputation_label:
		reputation_label.text = "声誉: %d" % ResourceManager.get_resource_value(Constants.RES_REPUTATION)

	if cohesion_label:
		cohesion_label.text = "凝聚力: %d" % ResourceManager.get_resource_value(Constants.RES_COHESION)

	if creativity_label:
		creativity_label.text = "创造力: %d" % ResourceManager.get_resource_value(Constants.RES_CREATIVITY)

	if memory_label:
		memory_label.text = "记忆恢复度: %d" % ResourceManager.get_resource_value(Constants.RES_MEMORY)


# ===================== 箭头点击事件 =====================
func _on_arrow_left_pressed():
	_play_ui_click_sound()
	print("左箭头被点击")

	$UILayer/FacilityPanel.close_panel()

	if tutorial_layer:
		tutorial_layer.hide_all()

	get_tree().change_scene_to_file("res://project/scenes/lounge/lounge_scene.tscn")


func _on_arrow_right_pressed():
	_play_ui_click_sound()
	print("右箭头被点击")

	$UILayer/FacilityPanel.close_panel()

	if tutorial_layer and tutorial_layer.visible:
		tutorial_layer.on_button_clicked(arrow_right)

	get_tree().change_scene_to_file("res://project/scenes/rehearsal/rehearsal_scene.tscn")


# ===================== 对话按钮事件 =====================
func _on_button_pressed():
	_play_ui_click_sound()
	print("🔥 main.gd 收到按钮点击通知")


# 点击顶部按钮显示康复面板
func _on_rehab_trigger():
	_play_ui_click_sound()

	if not rehab_panel:
		return

	if rehab_panel.visible:
		rehab_panel.hide_panel()
		_set_ui_enabled(true)
	else:
		rehab_panel.show_panel()
		# 禁用箭头/对话按钮，防止误操作
		_set_ui_enabled(false)


# 康复面板关闭后恢复交互
func _on_rehab_panel_closed():
	print("🔔 _on_rehab_panel_closed 被调用了！")
	print("当前按钮状态 - 左箭头: ", arrow_left.disabled if arrow_left else "不存在")
	print("当前按钮状态 - 右箭头: ", arrow_right.disabled if arrow_right else "不存在")
	print("当前按钮状态 - 对话按钮: ", button.disabled if button else "不存在")

	_set_ui_enabled(true)

	# 这里只恢复 UI，不再扣行动点
	# 行动点已经在 Rehabpanel._on_start_rehab() 中扣除
	ResourceManager.refresh_current_scene_topbar()

	if ResourceManager.get_action_points() == 0:
		if skip_panel_manager:
			skip_panel_manager.show_skip_panel(true)

	print("设置后状态 - 左箭头: ", arrow_left.disabled if arrow_left else "不存在")
	print("设置后状态 - 右箭头: ", arrow_right.disabled if arrow_right else "不存在")
	print("设置后状态 - 对话按钮: ", button.disabled if button else "不存在")


func _set_ui_enabled(enabled: bool):
	print("设置UI可用性: ", enabled)

	# 使用 @onready 变量而不是 $
	if arrow_left:
		arrow_left.disabled = not enabled
		print("左箭头设置 disabled = ", arrow_left.disabled)
	else:
		print("警告: arrow_left 为 null")

	if arrow_right:
		arrow_right.disabled = not enabled
		print("右箭头设置 disabled = ", arrow_right.disabled)
	else:
		print("警告: arrow_right 为 null")

	if button:
		button.disabled = not enabled
		print("对话按钮设置 disabled = ", button.disabled)
	else:
		print("警告: button 为 null")


# ===================== 设施升级后消耗行动点 =====================
# 在 FacilityPanel 升级成功后，需要通知主场景消耗行动点
func on_facility_upgraded():
	# 设施升级的行动点已经在 FacilityManager / ResourceManager 中扣除了
	# 这里不要再重复扣减，只负责刷新显示与处理跳过提示
	ResourceManager.refresh_current_scene_topbar()

	if ResourceManager.get_action_points() == 0:
		if skip_panel_manager:
			skip_panel_manager.show_skip_panel(true)


func _on_skip_button_pressed():
	# 防止连点
	if is_skip_button_processing or is_week_transition_playing:
		return

	_play_ui_click_sound()

	is_skip_button_processing = true
	_set_skip_button_enabled(false)

	print("跳过按钮被点击")
	await _play_skip_button_press_feedback()

	# 场景可能已经切走，先做安全判断
	if not is_inside_tree():
		return

	if week_cycle:
		match week_cycle.get_current_phase():
			week_cycle.GamePhase.BEFORE_WEEK:
				print("强制从周初跳到周中")
				week_cycle.force_to_mid_week()
			week_cycle.GamePhase.MID_WEEK:
				print("强制从周中跳到周末")
				week_cycle.complete_mid_week()
			week_cycle.GamePhase.AFTER_WEEK:
				print("执行周末结算")
				GameManager.weekly_settlement()

	# 等一帧，让阶段/周数/UI先完成刷新
	if is_inside_tree():
		await get_tree().process_frame

	if not is_inside_tree():
		return

	_refresh_week_phase_ui()
	_refresh_clock_icon_ui()
	_refresh_skip_button_ui()

	# 只有当前没有播放阶段演出时，才恢复按钮
	if not is_week_transition_playing:
		_set_skip_button_enabled(true)
		is_skip_button_processing = false


# ===================== 小游戏相关 =====================
func _enter_minigame():
	"""进入小游戏场景"""
	print("进入小游戏场景...")

	# 切换到小游戏场景
	get_tree().change_scene_to_file("res://project/scenes/minigame/game_level.tscn")


func _on_minigame_finished(score: int, rank: String):
	"""小游戏结束回调"""
	print("小游戏结束，得分: ", score, " 评级: ", rank)

	# 根据评级计算奖励
	var reward = _calculate_minigame_reward(rank)

	# 应用奖励
	if reward.money != 0:
		ResourceManager.add_money(reward.money)
		print("获得资金: ", reward.money)
	if reward.cohesion != 0:
		ResourceManager.add_cohesion(reward.cohesion)
		print("获得凝聚力: ", reward.cohesion)
	if reward.creativity != 0:
		ResourceManager.add_creativity(reward.creativity)
		print("获得创造力: ", reward.creativity)

	# 切换回主场景
	get_tree().change_scene_to_file("res://project/scenes/main/main.tscn")

	# 等待场景切换完成
	await get_tree().process_frame

	# 执行周末结算
	GameManager.weekly_settlement()


func _calculate_minigame_reward(rank: String) -> Dictionary:
	"""根据评级计算奖励"""
	var reward = {
		"money": 0,
		"cohesion": 0,
		"creativity": 0
	}

	match rank:
		"S":
			reward.money = 2000
			reward.cohesion = 15
			reward.creativity = 10
			print("S级评价！完美通关！")
		"A":
			reward.money = 1500
			reward.cohesion = 10
			reward.creativity = 5
			print("A级评价！表现优秀！")
		"B":
			reward.money = 1000
			reward.cohesion = 5
			print("B级评价！表现良好！")
		"C":
			reward.money = 500
			reward.cohesion = 2
			print("C级评价！继续努力！")
		"D":
			reward.money = 0
			reward.cohesion = -3
			print("D级评价！表现不佳...")

	return reward


# ===================== 调试面板 =====================
var debug_panel: Panel = null
var week_input: LineEdit = null
var jump_button: Button = null


func _create_debug_panel():
	# 创建调试面板（扩大尺寸）
	debug_panel = Panel.new()
	debug_panel.size = Vector2(520, 360)
	debug_panel.position = Vector2(10, 200)

	# 设置面板样式
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.2, 0.2, 0.2, 0.95)
	panel_style.set_corner_radius_all(8)
	debug_panel.add_theme_stylebox_override("panel", panel_style)

	# ===== 第一行：周数跳转 =====
	var week_label = Label.new()
	week_label.text = "跳转周数:"
	week_label.position = Vector2(10, 10)
	week_label.size = Vector2(80, 25)
	week_label.add_theme_color_override("font_color", Color(1, 1, 1))
	debug_panel.add_child(week_label)

	week_input = LineEdit.new()
	week_input.size = Vector2(80, 25)
	week_input.position = Vector2(95, 10)
	week_input.placeholder_text = "1-30"
	week_input.add_theme_color_override("font_color", Color(1, 1, 1))
	week_input.add_theme_color_override("placeholder_color", Color(0.7, 0.7, 0.7))
	debug_panel.add_child(week_input)

	jump_button = Button.new()
	jump_button.size = Vector2(60, 25)
	jump_button.position = Vector2(185, 10)
	jump_button.text = "跳转"
	jump_button.add_theme_color_override("font_color", Color(1, 1, 1))
	var jump_style = StyleBoxFlat.new()
	jump_style.bg_color = Color(0.3, 0.5, 0.8)
	jump_style.set_corner_radius_all(4)
	jump_button.add_theme_stylebox_override("normal", jump_style)
	jump_button.pressed.connect(_on_debug_jump_pressed)
	debug_panel.add_child(jump_button)

	# ===== 第二行：资金修改 =====
	var money_label = Label.new()
	money_label.text = "资金:"
	money_label.position = Vector2(10, 50)
	money_label.size = Vector2(50, 25)
	money_label.add_theme_color_override("font_color", Color(1, 1, 1))
	debug_panel.add_child(money_label)

	var money_value = LineEdit.new()
	money_value.name = "MoneyValue"
	money_value.size = Vector2(100, 25)
	money_value.position = Vector2(65, 50)
	money_value.placeholder_text = str(ResourceManager.get_money())
	money_value.add_theme_color_override("font_color", Color(1, 1, 1))
	debug_panel.add_child(money_value)

	var money_set_btn = Button.new()
	money_set_btn.size = Vector2(60, 25)
	money_set_btn.position = Vector2(175, 50)
	money_set_btn.text = "设置"
	money_set_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.4, 0.4, 0.5)
	btn_style.set_corner_radius_all(4)
	money_set_btn.add_theme_stylebox_override("normal", btn_style)
	money_set_btn.pressed.connect(_on_debug_set_money.bind(money_value))
	debug_panel.add_child(money_set_btn)

	# ===== 第三行：声誉修改 =====
	var rep_label = Label.new()
	rep_label.text = "声誉:"
	rep_label.position = Vector2(10, 85)
	rep_label.size = Vector2(50, 25)
	rep_label.add_theme_color_override("font_color", Color(1, 1, 1))
	debug_panel.add_child(rep_label)

	var rep_value = LineEdit.new()
	rep_value.name = "RepValue"
	rep_value.size = Vector2(100, 25)
	rep_value.position = Vector2(65, 85)
	rep_value.placeholder_text = str(ResourceManager.get_reputation())
	rep_value.add_theme_color_override("font_color", Color(1, 1, 1))
	debug_panel.add_child(rep_value)

	var rep_set_btn = Button.new()
	rep_set_btn.size = Vector2(60, 25)
	rep_set_btn.position = Vector2(175, 85)
	rep_set_btn.text = "设置"
	rep_set_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	rep_set_btn.add_theme_stylebox_override("normal", btn_style)
	rep_set_btn.pressed.connect(_on_debug_set_reputation.bind(rep_value))
	debug_panel.add_child(rep_set_btn)

	# ===== 第四行：凝聚力修改 =====
	var coh_label = Label.new()
	coh_label.text = "凝聚力:"
	coh_label.position = Vector2(260, 85)
	coh_label.size = Vector2(50, 25)
	coh_label.add_theme_color_override("font_color", Color(1, 1, 1))
	debug_panel.add_child(coh_label)

	var coh_value = LineEdit.new()
	coh_value.name = "CohValue"
	coh_value.size = Vector2(100, 25)
	coh_value.position = Vector2(320, 85)
	coh_value.placeholder_text = str(ResourceManager.get_cohesion())
	coh_value.add_theme_color_override("font_color", Color(1, 1, 1))
	debug_panel.add_child(coh_value)

	var coh_set_btn = Button.new()
	coh_set_btn.size = Vector2(60, 25)
	coh_set_btn.position = Vector2(430, 85)
	coh_set_btn.text = "设置"
	coh_set_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	coh_set_btn.add_theme_stylebox_override("normal", btn_style)
	coh_set_btn.pressed.connect(_on_debug_set_cohesion.bind(coh_value))
	debug_panel.add_child(coh_set_btn)

	# ===== 第五行：创造力修改 =====
	var cre_label = Label.new()
	cre_label.text = "创造力:"
	cre_label.position = Vector2(10, 120)
	cre_label.size = Vector2(50, 25)
	cre_label.add_theme_color_override("font_color", Color(1, 1, 1))
	debug_panel.add_child(cre_label)

	var cre_value = LineEdit.new()
	cre_value.name = "CreValue"
	cre_value.size = Vector2(100, 25)
	cre_value.position = Vector2(65, 120)
	cre_value.placeholder_text = str(ResourceManager.get_creativity())
	cre_value.add_theme_color_override("font_color", Color(1, 1, 1))
	debug_panel.add_child(cre_value)

	var cre_set_btn = Button.new()
	cre_set_btn.size = Vector2(60, 25)
	cre_set_btn.position = Vector2(175, 120)
	cre_set_btn.text = "设置"
	cre_set_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	cre_set_btn.add_theme_stylebox_override("normal", btn_style)
	cre_set_btn.pressed.connect(_on_debug_set_creativity.bind(cre_value))
	debug_panel.add_child(cre_set_btn)

	# ===== 第六行：记忆恢复度修改 =====
	var mem_label = Label.new()
	mem_label.text = "记忆:"
	mem_label.position = Vector2(260, 120)
	mem_label.size = Vector2(50, 25)
	mem_label.add_theme_color_override("font_color", Color(1, 1, 1))
	debug_panel.add_child(mem_label)

	var mem_value = LineEdit.new()
	mem_value.name = "MemValue"
	mem_value.size = Vector2(100, 25)
	mem_value.position = Vector2(320, 120)
	mem_value.placeholder_text = str(ResourceManager.get_memory())
	mem_value.add_theme_color_override("font_color", Color(1, 1, 1))
	debug_panel.add_child(mem_value)

	var mem_set_btn = Button.new()
	mem_set_btn.size = Vector2(60, 25)
	mem_set_btn.position = Vector2(430, 120)
	mem_set_btn.text = "设置"
	mem_set_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	mem_set_btn.add_theme_stylebox_override("normal", btn_style)
	mem_set_btn.pressed.connect(_on_debug_set_memory.bind(mem_value))
	debug_panel.add_child(mem_set_btn)

	# ===== 第七行：行动点修改 =====
	var action_label = Label.new()
	action_label.text = "行动点:"
	action_label.position = Vector2(10, 155)
	action_label.size = Vector2(50, 25)
	action_label.add_theme_color_override("font_color", Color(1, 1, 1))
	debug_panel.add_child(action_label)

	var action_value = LineEdit.new()
	action_value.name = "ActionValue"
	action_value.size = Vector2(100, 25)
	action_value.position = Vector2(65, 155)
	action_value.placeholder_text = str(ResourceManager.get_action_points())
	action_value.add_theme_color_override("font_color", Color(1, 1, 1))
	debug_panel.add_child(action_value)

	var action_set_btn = Button.new()
	action_set_btn.size = Vector2(60, 25)
	action_set_btn.position = Vector2(175, 155)
	action_set_btn.text = "设置"
	action_set_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	action_set_btn.add_theme_stylebox_override("normal", btn_style)
	action_set_btn.pressed.connect(_on_debug_set_action_points.bind(action_value))
	debug_panel.add_child(action_set_btn)

	# ===== 添加关闭按钮 =====
	var close_btn = Button.new()
	close_btn.size = Vector2(60, 25)
	close_btn.position = Vector2(320, 280)
	close_btn.text = "关闭"
	close_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.8, 0.3, 0.3)
	close_style.set_corner_radius_all(4)
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.pressed.connect(_toggle_debug_panel)
	debug_panel.add_child(close_btn)

	# 提示标签
	var tip_label = Label.new()
	tip_label.text = "按 F12 隐藏/显示"
	tip_label.position = Vector2(10, 260)
	tip_label.size = Vector2(200, 20)
	tip_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	debug_panel.add_child(tip_label)

	# 默认打开
	debug_panel.visible = true
	add_child(debug_panel)

# ===================== 调试数值设置 =====================

func _on_debug_set_money(input_field: LineEdit):
	var value = input_field.text.to_int()
	ResourceManager.add_money(value - ResourceManager.get_money())
	input_field.placeholder_text = str(ResourceManager.get_money())
	_refresh_resource_display()
	print("设置资金为: ", ResourceManager.get_money())

func _on_debug_set_reputation(input_field: LineEdit):
	var value = input_field.text.to_int()
	value = clamp(value, 0, 100)
	ResourceManager.add_reputation(value - ResourceManager.get_reputation())
	input_field.placeholder_text = str(ResourceManager.get_reputation())
	_refresh_resource_display()
	print("设置声誉为: ", ResourceManager.get_reputation())

func _on_debug_set_cohesion(input_field: LineEdit):
	var value = input_field.text.to_int()
	value = clamp(value, 0, 100)
	ResourceManager.add_cohesion(value - ResourceManager.get_cohesion())
	input_field.placeholder_text = str(ResourceManager.get_cohesion())
	_refresh_resource_display()
	print("设置凝聚力为: ", ResourceManager.get_cohesion())

func _on_debug_set_creativity(input_field: LineEdit):
	var value = input_field.text.to_int()
	value = clamp(value, 0, 100)
	ResourceManager.add_creativity(value - ResourceManager.get_creativity())
	input_field.placeholder_text = str(ResourceManager.get_creativity())
	_refresh_resource_display()
	print("设置创造力为: ", ResourceManager.get_creativity())

func _on_debug_set_memory(input_field: LineEdit):
	var value = input_field.text.to_int()
	value = clamp(value, 0, 100)
	ResourceManager.add_memory(value - ResourceManager.get_memory())
	input_field.placeholder_text = str(ResourceManager.get_memory())
	_refresh_resource_display()
	print("设置记忆恢复度为: ", ResourceManager.get_memory())

func _on_debug_set_action_points(input_field: LineEdit):
	var value = input_field.text.to_int()
	value = clamp(value, 0, 3)
	
	# 修改行动点
	var current = ResourceManager.get_action_points()
	var delta = value - current
	if delta > 0:
		for i in range(delta):
			ResourceManager.consume_action_point()  # 实际是增加，需要特殊处理
			# 由于 ResourceManager 的 action_points 可以直接设置，建议添加一个方法
	# 更好的方法：直接修改 ResourceManager 的 action_points
	ResourceManager.set_action_points(value)
	input_field.placeholder_text = str(ResourceManager.get_action_points())
	_refresh_resource_display()
	print("设置行动点为: ", ResourceManager.get_action_points())
	
func _toggle_debug_panel():
	if debug_panel:
		debug_panel.visible = !debug_panel.visible


func _on_debug_jump_pressed():
	if not week_input:
		return

	_play_ui_click_sound()

	var input_text = week_input.text.strip_edges()
	if input_text.is_empty():
		print("输入为空")
		return

	var target_week = input_text.to_int()
	if target_week < 1:
		target_week = 1
	if target_week > 30:
		target_week = 30

	print("调试：准备跳转到第", target_week, "周")

	# 调用 GameManager 的跳转方法
	if GameManager and GameManager.has_method("jump_to_week"):
		var success = GameManager.jump_to_week(target_week)
		if success:
			print("跳转成功")
			# 刷新当前场景的 UI
			refresh_ui()

			# 可选：显示提示
			_show_jump_notification(target_week)
		else:
			print("跳转失败")
	else:
		print("GameManager 不存在或没有 jump_to_week 方法")


func _show_jump_notification(week: int):
	# 显示一个短暂的提示（简化版）
	var notification = Label.new()
	notification.text = "已跳转到第 %d 周" % week
	notification.position = Vector2(get_viewport().size.x / 2 - 100, 50)
	notification.size = Vector2(200, 30)
	notification.add_theme_color_override("font_color", Color(1, 1, 0))
	notification.add_theme_color_override("font_outline_color", Color(0, 0, 0))

	add_child(notification)

	# 2秒后自动删除
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(notification):
		notification.queue_free()


func _refresh_resource_display():
	if money_label:
		money_label.text = "资金: %d" % ResourceManager.get_money()
	if reputation_label:
		reputation_label.text = "声誉: %d" % ResourceManager.get_reputation()
	if cohesion_label:
		cohesion_label.text = "凝聚力: %d" % ResourceManager.get_cohesion()
	if creativity_label:
		creativity_label.text = "创造力: %d" % ResourceManager.get_creativity()
	if memory_label:
		memory_label.text = "记忆恢复度: %d" % ResourceManager.get_memory()


# 刷新整个 UI（供 GameManager 调用）
func refresh_ui():
	print("刷新主场景 UI")

	# 刷新资源显示
	_refresh_resource_display()

	# 刷新行动点显示
	var current_points = ResourceManager.get_action_points() if ResourceManager else 3
	var max_points = ResourceManager.get_max_action_points() if ResourceManager else 3
	_update_action_point_display(current_points, max_points)

	# 刷新设施面板（如果打开）
	var facility_panel = $UILayer/FacilityPanel
	if facility_panel and facility_panel.visible:
		facility_panel._refresh_panel()

	# 刷新阶段显示
	_refresh_week_phase_ui()
	_refresh_clock_icon_ui()
	_refresh_skip_button_ui()

	if week_cycle:
		match week_cycle.get_current_phase():
			0:
				print("当前阶段: 周初")
			1:
				print("当前阶段: 周中")
			2:
				print("当前阶段: 周末")


# ===================== 记忆阶段事件系统 =====================
var memory_event_overlay: Control = null
var memory_event_backdrop: TextureRect = null
var memory_event_panel: Panel = null
var memory_event_image_box: Control = null
var memory_event_image_texture: TextureRect = null
var memory_event_image_label: Label = null
var memory_event_title_label: Label = null
var memory_event_text_label: RichTextLabel = null
var memory_event_choice_container: VBoxContainer = null

var current_memory_event_id: String = ""
var current_memory_event_selected_option: Dictionary = {}
var current_memory_event_pages: Array = []
var current_memory_event_page_index: int = 0

# 记忆事件数据改为从 JSON 文件读取
var memory_event_data: Dictionary = {}

const MEMORY_DIALOG_SPEAKER_COLORS := {
	"narration": "#F2E6D2",
	"alexi": "#D6B36A",
	"alexi_inner": "#E8D2A3",
	"old_nail": "#8FB7D9",
	"finn": "#B8A0E8"
}

const MEMORY_DIALOG_SPEAKER_NAMES := {
	"narration": "",
	"alexi": "你",
	"alexi_inner": "你（内心）",
	"old_nail": "老钉子",
	"finn": "芬恩"
}


# ===================== 记忆事件数据读取 =====================
func _load_memory_event_data():
	var path = "res://project/data/story/memory_events.json"

	if not FileAccess.file_exists(path):
		push_error("找不到记忆事件配置文件: " + path)
		memory_event_data = {}
		return

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("无法打开记忆事件配置文件: " + path)
		memory_event_data = {}
		return

	var text = file.get_as_text()

	var json = JSON.new()
	var err = json.parse(text)

	if err != OK:
		push_error("memory_events.json 解析失败，错误码: %d" % err)
		memory_event_data = {}
		return

	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("memory_events.json 顶层不是 Dictionary")
		memory_event_data = {}
		return

	memory_event_data = json.data
	print("✅ 记忆事件数据加载完成: ", memory_event_data.keys())


# ===================== 记忆事件显示辅助 =====================

# 把 JSON 里的多行文本数组拼成面板可显示的字符串
func _build_event_text(lines_data) -> String:
	# Godot 4 的静态类型检查下，直接 return str(null) 可能被判定为返回 null，
	# 这里显式兜底为空字符串，避免 “Cannot return value of type null” 报错
	if lines_data == null:
		return ""

	if lines_data is Array:
		var result := ""
		for i in range(lines_data.size()):
			if i > 0:
				result += "\n\n"
			result += "%s" % lines_data[i]
		return result

	return "%s" % lines_data


func _escape_memory_bbcode_text(text: String) -> String:
	return text.replace("[", "[lb]").replace("]", "[rb]")


func _build_event_rich_text(dialogues_data) -> String:
	if dialogues_data == null:
		return ""

	var result := ""

	if dialogues_data is Array:
		var last_speaker := ""

		for i in range(dialogues_data.size()):
			var entry = dialogues_data[i]
			if not (entry is Dictionary):
				continue

			var speaker := str(entry.get("speaker", "narration"))
			var raw_text := str(entry.get("text", ""))
			var text := _escape_memory_bbcode_text(raw_text)

			if text == "":
				continue

			var color := str(MEMORY_DIALOG_SPEAKER_COLORS.get(speaker, "#F2E6D2"))
			var speaker_name := str(MEMORY_DIALOG_SPEAKER_NAMES.get(speaker, ""))

			# 旁白：始终不显示名字
			if speaker == "narration":
				result += "[color=%s]%s[/color]\n\n" % [color, text]
			else:
				# 同一页里，同一个说话人只在第一句显示名字
				if speaker != last_speaker:
					result += "[color=%s]【%s】%s[/color]\n\n" % [color, speaker_name, text]
				else:
					result += "[color=%s]%s[/color]\n\n" % [color, text]

			last_speaker = speaker

		return result.strip_edges()

	return "[color=#F2E6D2]%s[/color]" % _escape_memory_bbcode_text(str(dialogues_data))


# 兼容旧结构：如果还没改成 pages，就自动转成单页结构
func _build_memory_event_pages(event_data: Dictionary) -> Array:
	var pages: Array = []

	if event_data.has("pages") and event_data["pages"] is Array and event_data["pages"].size() > 0:
		return event_data["pages"]

	var first_page := {
		"title": event_data.get("title", "关键事件"),
		"image_path": event_data.get("image_path", ""),
		"dialogues": event_data.get("dialogues", []),
		"lines": event_data.get("intro_lines", [event_data.get("intro_text", "")]),
		"choices": event_data.get("options", [])
	}
	pages.append(first_page)
	return pages


# 切换背景图，给后续插图留好位置
func _switch_memory_event_background(image_path: String, image_hint: String = ""):
	if memory_event_backdrop == null:
		return

	if image_path != "" and ResourceLoader.exists(image_path):
		var texture = load(image_path)
		if texture:
			memory_event_backdrop.texture = texture
			memory_event_backdrop.visible = true
			if memory_event_image_label:
				memory_event_image_label.visible = false
			return

	# 没图时显示提示文案
	memory_event_backdrop.texture = null
	memory_event_backdrop.visible = false

	if memory_event_image_label:
		if image_hint.strip_edges() != "":
			memory_event_image_label.text = "背景图需求：\n" + image_hint
		else:
			memory_event_image_label.text = "暂无事件插图"
		memory_event_image_label.visible = true


# 根据 image_path 显示图片；如果图片不存在，则回退显示文字提示
func _set_memory_event_image(event_data: Dictionary):
	var image_path = str(event_data.get("image_path", ""))
	_switch_memory_event_background(image_path)


# 让当前页标题、正文、按钮渐变出现
func _animate_memory_event_page():
	if memory_event_title_label:
		memory_event_title_label.modulate = Color(1, 1, 1, 0)

	if memory_event_text_label:
		memory_event_text_label.modulate = Color(1, 1, 1, 0)

	var tween = create_tween()
	tween.set_parallel(true)

	if memory_event_title_label:
		tween.tween_property(memory_event_title_label, "modulate", Color(1, 1, 1, 1), 0.20)

	if memory_event_text_label:
		tween.tween_property(memory_event_text_label, "modulate", Color(1, 1, 1, 1), 0.28)

	call_deferred("_animate_memory_event_choices")


# 选项按钮依次淡入
func _animate_memory_event_choices():
	if not memory_event_choice_container:
		return

	var delay := 0.0
	for child in memory_event_choice_container.get_children():
		if child is Control:
			child.modulate = Color(1, 1, 1, 0)

			var tween = create_tween()
			tween.tween_interval(delay)
			tween.tween_property(child, "modulate", Color(1, 1, 1, 1), 0.18)
			delay += 0.06


# ===================== 记忆阶段事件系统 =====================

# 创建记忆阶段事件面板（运行时创建，改为全屏演出式事件）
func _create_memory_event_panel():
	var ui_layer = get_node_or_null("UILayer")
	if not ui_layer:
		print("❌ 未找到 UILayer，无法创建记忆事件面板")
		return

	# 避免重复创建
	if memory_event_overlay and is_instance_valid(memory_event_overlay):
		return

	# 全屏根节点
	memory_event_overlay = Control.new()
	memory_event_overlay.name = "MemoryEventOverlay"
	memory_event_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	memory_event_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	memory_event_overlay.z_index = 999
	memory_event_overlay.visible = false
	ui_layer.add_child(memory_event_overlay)

	# 全屏背景图（后续每一页都可以切）
	memory_event_backdrop = TextureRect.new()
	memory_event_backdrop.name = "Backdrop"
	memory_event_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	memory_event_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	memory_event_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	memory_event_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	memory_event_overlay.add_child(memory_event_backdrop)

	# 保留占位层，无图时显示提示
	memory_event_image_box = Control.new()
	memory_event_image_box.name = "FallbackLayer"
	memory_event_image_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	memory_event_image_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	memory_event_overlay.add_child(memory_event_image_box)

	memory_event_image_texture = TextureRect.new()
	memory_event_image_texture.name = "FullScreenBackground"
	memory_event_image_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	memory_event_image_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	memory_event_image_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	memory_event_image_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	memory_event_image_texture.visible = false
	memory_event_overlay.add_child(memory_event_image_texture)

	# 无图时的占位文字
	memory_event_image_label = Label.new()
	memory_event_image_label.name = "FallbackLabel"
	memory_event_image_label.anchor_left = 0.20
	memory_event_image_label.anchor_top = 0.18
	memory_event_image_label.anchor_right = 0.80
	memory_event_image_label.anchor_bottom = 0.42
	memory_event_image_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	memory_event_image_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	memory_event_image_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	memory_event_image_label.add_theme_font_size_override("font_size", 20)
	memory_event_image_label.add_theme_color_override("font_color", Color(0.90, 0.90, 0.90))
	memory_event_image_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	memory_event_image_label.add_theme_constant_override("outline_size", 6)
	memory_event_image_box.add_child(memory_event_image_label)

	# 暗层遮罩（全屏）
	var dark_mask = ColorRect.new()
	dark_mask.name = "DarkMask"
	dark_mask.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark_mask.color = Color(0, 0, 0, 0.42)
	dark_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	memory_event_overlay.add_child(dark_mask)

	# 顶部标题
	memory_event_title_label = Label.new()
	memory_event_title_label.name = "TitleLabel"
	memory_event_title_label.anchor_left = 0.08
	memory_event_title_label.anchor_top = 0.09
	memory_event_title_label.anchor_right = 0.92
	memory_event_title_label.anchor_bottom = 0.16
	memory_event_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	memory_event_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	memory_event_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	memory_event_title_label.add_theme_font_size_override("font_size", 34)
	memory_event_title_label.add_theme_color_override("font_color", Color(0.96, 0.87, 0.58))
	memory_event_title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	memory_event_title_label.add_theme_constant_override("outline_size", 8)
	memory_event_overlay.add_child(memory_event_title_label)

	# 底部大对话框
	memory_event_panel = Panel.new()
	memory_event_panel.name = "DialogPanel"
	memory_event_panel.anchor_left = 0.04
	memory_event_panel.anchor_top = 0.70
	memory_event_panel.anchor_right = 0.96
	memory_event_panel.anchor_bottom = 0.97

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.05, 0.04, 0.90)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.85, 0.68, 0.32, 0.95)
	panel_style.set_corner_radius_all(18)
	panel_style.shadow_color = Color(0, 0, 0, 0.45)
	panel_style.shadow_size = 10
	memory_event_panel.add_theme_stylebox_override("panel", panel_style)
	memory_event_overlay.add_child(memory_event_panel)

	# 正文文本
	memory_event_text_label = RichTextLabel.new()
	memory_event_text_label.name = "TextLabel"
	memory_event_text_label.anchor_left = 0.04
	memory_event_text_label.anchor_top = 0.11
	memory_event_text_label.anchor_right = 0.96
	memory_event_text_label.anchor_bottom = 0.86
	memory_event_text_label.bbcode_enabled = true
	memory_event_text_label.fit_content = false
	memory_event_text_label.scroll_active = true
	memory_event_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	memory_event_text_label.add_theme_font_size_override("normal_font_size", 22)
	memory_event_text_label.selection_enabled = false
	memory_event_panel.add_child(memory_event_text_label)

	# 选项按钮容器：放到屏幕中央 / 偏上区域，不再压在底部对话框上
	memory_event_choice_container = VBoxContainer.new()
	memory_event_choice_container.name = "ChoiceContainer"
	memory_event_choice_container.anchor_left = 0.18
	memory_event_choice_container.anchor_top = 0.43
	memory_event_choice_container.anchor_right = 0.82
	memory_event_choice_container.anchor_bottom = 0.64
	memory_event_choice_container.alignment = BoxContainer.ALIGNMENT_CENTER
	memory_event_choice_container.add_theme_constant_override("separation", 12)
	memory_event_choice_container.mouse_filter = Control.MOUSE_FILTER_STOP
	memory_event_overlay.add_child(memory_event_choice_container)

	print("✅ 全屏记忆阶段事件面板创建完成")


# 触发记忆阶段事件
# 由 Rehabpanel.gd 中的“触发关键事件”按钮调用
func start_memory_stage_event(event_id: String):
	if not memory_event_data.has(event_id):
		print("❌ 未找到记忆阶段事件：", event_id)
		return

	if not memory_event_overlay or not is_instance_valid(memory_event_overlay):
		_create_memory_event_panel()

	current_memory_event_id = event_id
	current_memory_event_selected_option = {}
	current_memory_event_pages = _build_memory_event_pages(memory_event_data[event_id])
	current_memory_event_page_index = 0

	# 确保康复面板关闭
	if rehab_panel and rehab_panel.visible:
		rehab_panel.hide_panel()

	# 锁定普通交互
	_set_ui_enabled(false)

	# 显示遮罩并淡入
	if memory_event_overlay:
		memory_event_overlay.visible = true
		memory_event_overlay.modulate = Color(1, 1, 1, 0)
		var tween = create_tween()
		tween.tween_property(memory_event_overlay, "modulate", Color(1, 1, 1, 1), 0.25)

	# 显示第一页
	_show_memory_event_page(current_memory_event_page_index)


# 显示当前页
func _show_memory_event_page(page_index: int):
	if page_index < 0 or page_index >= current_memory_event_pages.size():
		print("❌ 记忆事件页索引超出范围: ", page_index)
		_finish_memory_stage_event()
		return

	current_memory_event_page_index = page_index
	var event_data: Dictionary = memory_event_data.get(current_memory_event_id, {})
	var page_data: Dictionary = current_memory_event_pages[page_index]

	# 标题：页标题优先，没有就用事件标题
	if memory_event_title_label:
		memory_event_title_label.text = str(page_data.get("title", event_data.get("title", "关键事件")))

	# 背景：页 image_path 优先，没有就回退事件 image_path
	var page_image_path := str(page_data.get("image_path", event_data.get("image_path", "")))
	var page_image_hint := str(page_data.get("image_hint", event_data.get("image_hint", "")))
	_switch_memory_event_background(page_image_path, page_image_hint)

	# 正文
	if memory_event_text_label:
		memory_event_text_label.clear()

		if page_data.has("dialogues"):
			memory_event_text_label.append_text(_build_event_rich_text(page_data.get("dialogues", [])))
		elif page_data.has("lines"):
			memory_event_text_label.append_text("[color=#F2E6D2]%s[/color]" % _escape_memory_bbcode_text(_build_event_text(page_data.get("lines", []))))
		elif page_data.has("intro_lines"):
			memory_event_text_label.append_text("[color=#F2E6D2]%s[/color]" % _escape_memory_bbcode_text(_build_event_text(page_data.get("intro_lines", []))))
		else:
			memory_event_text_label.append_text("[color=#F2E6D2]%s[/color]" % _escape_memory_bbcode_text(str(page_data.get("text", ""))))

	# 清空旧按钮
	_clear_memory_event_choices()

	# 构建当前页按钮
	var choices = page_data.get("choices", [])

	# 有 choices 就按 choices 生成；没有就给一个“继续”
	if choices is Array and choices.size() > 0:
		for option_data in choices:
			if option_data is Dictionary:
				var choice_button = _create_memory_choice_button(option_data)
				memory_event_choice_container.add_child(choice_button)
	else:
		var continue_button = _create_memory_continue_button("继续")
		continue_button.pressed.connect(_on_memory_event_continue_pressed)
		memory_event_choice_container.add_child(continue_button)

	# 当前页内容渐变出现
	_animate_memory_event_page()

	print("✅ 已显示记忆事件页：", page_index)


# 创建单个选项按钮
func _create_memory_choice_button(option: Dictionary) -> Button:
	var choice_button = Button.new()
	choice_button.custom_minimum_size = Vector2(0, 46)
	choice_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	choice_button.text = str(option.get("text", "继续"))

	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.32, 0.22, 0.12, 0.94)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.90, 0.74, 0.38, 0.95)
	normal_style.set_corner_radius_all(10)

	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.44, 0.30, 0.16, 1.0)
	hover_style.border_color = Color(1.00, 0.85, 0.48, 1.0)

	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.58, 0.38, 0.18, 1.0)
	pressed_style.border_color = Color(1.00, 0.92, 0.60, 1.0)

	choice_button.add_theme_stylebox_override("normal", normal_style)
	choice_button.add_theme_stylebox_override("hover", hover_style)
	choice_button.add_theme_stylebox_override("pressed", pressed_style)
	choice_button.add_theme_font_size_override("font_size", 18)
	choice_button.add_theme_color_override("font_color", Color(1, 1, 1))

	choice_button.pressed.connect(_on_memory_event_choice_selected.bind(option))
	return choice_button


# 创建继续按钮
func _create_memory_continue_button(button_text: String) -> Button:
	var continue_button = Button.new()
	continue_button.custom_minimum_size = Vector2(0, 46)
	continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	continue_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	continue_button.text = button_text

	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.42, 0.28, 0.14, 0.96)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.95, 0.80, 0.42, 1.0)
	normal_style.set_corner_radius_all(10)

	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.54, 0.36, 0.18, 1.0)

	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.66, 0.44, 0.20, 1.0)

	continue_button.add_theme_stylebox_override("normal", normal_style)
	continue_button.add_theme_stylebox_override("hover", hover_style)
	continue_button.add_theme_stylebox_override("pressed", pressed_style)
	continue_button.add_theme_font_size_override("font_size", 18)
	continue_button.add_theme_color_override("font_color", Color(1, 1, 1))

	return continue_button


# 清空当前事件选项
func _clear_memory_event_choices():
	if not memory_event_choice_container:
		return

	for child in memory_event_choice_container.get_children():
		child.queue_free()


# 点击“继续”时推进到下一页
func _on_memory_event_continue_pressed():
	_play_ui_click_sound()

	if current_memory_event_page_index < current_memory_event_pages.size() - 1:
		_show_memory_event_page(current_memory_event_page_index + 1)
	else:
		_finish_memory_stage_event()


# 玩家选中一个选项
func _on_memory_event_choice_selected(option: Dictionary):
	_play_ui_click_sound()

	current_memory_event_selected_option = option

	# 如果这个选项带结果文本，先显示结果文本，再让玩家继续
	if option.has("result_dialogues") or option.has("result_lines") or option.has("result_text"):
		if memory_event_text_label:
			memory_event_text_label.clear()

			if option.has("result_dialogues"):
				memory_event_text_label.append_text(_build_event_rich_text(option.get("result_dialogues", [])))
			elif option.has("result_lines"):
				memory_event_text_label.append_text("[color=#F2E6D2]%s[/color]" % _escape_memory_bbcode_text(_build_event_text(option.get("result_lines", []))))
			else:
				memory_event_text_label.append_text("[color=#F2E6D2]%s[/color]" % _escape_memory_bbcode_text(str(option.get("result_text", "记忆的碎片重新浮现。"))))

		# 如果结果页也有背景图，先切一次
		var result_image_path := str(option.get("result_image_path", ""))
		var result_image_hint := str(option.get("result_image_hint", ""))

		if result_image_path != "" or result_image_hint != "":
			_switch_memory_event_background(result_image_path, result_image_hint)

		_clear_memory_event_choices()

		var continue_button = _create_memory_continue_button("继续")
		continue_button.pressed.connect(_on_memory_event_choice_result_continue.bind(option))
		memory_event_choice_container.add_child(continue_button)

		_animate_memory_event_page()
		return

	# 没有结果文本就直接推进
	_on_memory_event_choice_result_continue(option)


# 选项结果页点击继续后推进
func _on_memory_event_choice_result_continue(option: Dictionary):
	# 先应用选项效果
	_apply_memory_stage_choice(option)

	# 可跳转到指定页；没有指定就默认下一页；最后一页就结束
	if option.get("end_event", false):
		_finish_memory_stage_event()
		return

	var next_page = int(option.get("next_page", -1))
	if next_page >= 0:
		_show_memory_event_page(next_page)
		return

	if current_memory_event_page_index < current_memory_event_pages.size() - 1:
		_show_memory_event_page(current_memory_event_page_index + 1)
	else:
		_finish_memory_stage_event()


# 应用当前选项带来的方向值 / 记忆值变化
func _apply_memory_stage_choice(option: Dictionary):
	if option.is_empty():
		return

	var weights = option.get("weights", {})
	if weights is Dictionary:
		if weights.has("art"):
			ResourceManager.modify_ai_weight(Constants.WEIGHT_ART, int(weights["art"]))
		if weights.has("human"):
			ResourceManager.modify_ai_weight(Constants.WEIGHT_HUMAN, int(weights["human"]))
		if weights.has("business"):
			ResourceManager.modify_ai_weight(Constants.WEIGHT_BUSINESS, int(weights["business"]))

	var memory_delta = int(option.get("memory_delta", 0))
	if memory_delta != 0:
		ResourceManager.add_memory(memory_delta)


# 完成当前记忆阶段事件
# 作用：
# 1. 正式调用 ResourceManager 完成阶段提升
# 2. 结算当前选项带来的方向值 / 记忆值变化
# 3. 关闭剧情面板，回到康复面板
func _finish_memory_stage_event():
	if current_memory_event_id == "":
		return

	# 先完成阶段提升
	if ResourceManager and ResourceManager.has_method("complete_memory_stage_event"):
		var complete_result = ResourceManager.complete_memory_stage_event()
		if not complete_result.get("success", false):
			print("❌ 记忆阶段事件完成失败：", complete_result.get("reason", "未知错误"))
			if memory_event_text_label:
				memory_event_text_label.clear()
				memory_event_text_label.append_text("[color=#F2E6D2]%s[/color]" % _escape_memory_bbcode_text("阶段事件完成失败：%s" % str(complete_result.get("reason", "未知错误"))))
			return

	# 如果当前选项还没结算过，并且没有通过结果继续页推进，这里补一次
	# 只在确实有选项且 end_event 直接结束时需要兜底
	if not current_memory_event_selected_option.is_empty():
		# 这里不重复加数值，因为正常流程已在 _on_memory_event_choice_result_continue 中应用
		pass

	# 淡出关闭事件面板
	if memory_event_overlay:
		var tween = create_tween()
		tween.tween_property(memory_event_overlay, "modulate", Color(1, 1, 1, 0), 0.20)
		await tween.finished
		memory_event_overlay.visible = false
		memory_event_overlay.modulate = Color(1, 1, 1, 1)

	print("✅ 记忆阶段事件完成：", current_memory_event_id)

	current_memory_event_id = ""
	current_memory_event_selected_option = {}
	current_memory_event_pages = []
	current_memory_event_page_index = 0

	# 刷新顶部资源显示
	ResourceManager.refresh_current_scene_topbar()

	# 事件结束后重新打开康复面板，方便继续查看当前恢复阶段
	if rehab_panel and rehab_panel.has_method("show_panel"):
		rehab_panel.show_panel()
		_set_ui_enabled(false)
	else:
		_set_ui_enabled(true)
# 主场景里的按钮 pressed 信号连接的函数
func _on_team_button_pressed():
	get_tree().change_scene_to_file("res://project/scenes/ui/TeamOverview.tscn")


# 主场景里的按钮 pressed 信号连接的函数
func _on_team_button_pressed1():
	get_tree().change_scene_to_file("res://project/scenes/ui/TeamOverview.tscn")


func _on_btn_team_overview_pressed():
	print("乐队成员按钮被点击！准备跳转...")  # 先打印测试
	
	var team_scene_path = "res://project/scenes/ui/TeamOverview.tscn"
	
	if ResourceLoader.exists(team_scene_path):
		var err = get_tree().change_scene_to_file(team_scene_path)
		if err != OK:
			print("跳转失败！错误码：", err)
		else:
			print("成功跳转到人物界面")
	else:
		print("错误：找不到 TeamOverview.tscn 文件")
		print("请确认路径是否正确")
