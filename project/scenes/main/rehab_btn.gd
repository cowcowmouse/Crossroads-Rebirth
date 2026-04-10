extends Panel

# ===================== 面板内子节点引用 =====================
@onready var title_label = $TitleLabel
@onready var memory_value_label = get_node_or_null("MemoryValueLabel")
@onready var target_value_label = get_node_or_null("TargetValueLabel")
@onready var cost_value_label = get_node_or_null("CostValueLabel")
@onready var effect_value_label = get_node_or_null("EffectValueLabel")
@onready var action_point_value_label = get_node_or_null("ActionPointValueLabel")
@onready var memory_progress = $MemoryProgress
@onready var progress_label = $ProgressLabel                  # 只显示状态提示
@onready var start_rehab_btn = $StartRehabBtn
@onready var close_btn = $CloseBtn
@onready var stage_event_btn = get_node_or_null("StageEventBtn")

# ===================== 全局管理器引用 =====================
@onready var resource_manager = get_node("/root/ResourceManager")
@onready var constants = get_node("/root/Constants")
@onready var event_bus = get_node_or_null("/root/EventBus")

# ===================== 配置参数 =====================
@export var max_memory: int = 100
@export var training_memory_gain: int = 5

# 防止成功提示被资源刷新立刻覆盖
var _lock_feedback_refresh: bool = false

# ===================== 初始化 =====================
func _ready():
	visible = false

	if title_label:
		title_label.text = "个人状态"

	# 状态提示标签单独居中
	if progress_label:
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if start_rehab_btn:
		start_rehab_btn.pressed.connect(_on_start_rehab)

	if stage_event_btn:
		stage_event_btn.pressed.connect(_on_stage_event_pressed)
		stage_event_btn.visible = false

	if close_btn:
		close_btn.pressed.connect(_on_close_panel)

	if event_bus and event_bus.has_signal("core_resource_changed"):
		event_bus.core_resource_changed.connect(_on_core_resource_changed)

	_refresh_panel()
	print("✅ 康复面板初始化完成")

# ===================== 显示 / 隐藏 =====================
func show_panel():
	_refresh_panel()
	visible = true
	grab_focus()
	print("🏥 康复面板已显示")

func hide_panel():
	visible = false
	print("❌ 康复面板已隐藏")

func open_panel():
	show_panel()

func close_panel():
	hide_panel()

# ===================== 面板刷新 =====================
func _refresh_panel():
	if not resource_manager or not constants:
		return

	var current_memory = resource_manager.get_resource_value(constants.RES_MEMORY)
	var current_ap = resource_manager.get_action_points()
	var max_ap = resource_manager.get_max_action_points()

	var memory_stage = 0
	if resource_manager.has_method("get_memory_stage"):
		memory_stage = resource_manager.get_memory_stage()

	var stage_cap = max_memory
	if resource_manager.has_method("get_memory_stage_cap"):
		stage_cap = resource_manager.get_memory_stage_cap()

	_update_progress(current_memory)

	# 标题固定
	if title_label:
		title_label.text = "个人状态"

	# 分项标签显示
	if memory_value_label:
		memory_value_label.text = "记忆恢复度：%d%%" % current_memory

	if target_value_label:
		target_value_label.text = "目标恢复度：%d%%" % stage_cap

	if cost_value_label:
		cost_value_label.text = "消耗：1 行动点"

	if effect_value_label:
		effect_value_label.text = "效果：记忆恢复度 +%d" % training_memory_gain

	if action_point_value_label:
		action_point_value_label.text = "当前行动点：%d/%d" % [current_ap, max_ap]

	# 检查当前是否可触发阶段关键事件
	var can_trigger_stage_event := false
	var stage_event_reason := ""
	if resource_manager.has_method("can_trigger_memory_stage_event"):
		var stage_event_check = resource_manager.can_trigger_memory_stage_event()
		can_trigger_stage_event = bool(stage_event_check.get("success", false))
		stage_event_reason = str(stage_event_check.get("reason", ""))

	# 状态提示文本单独显示
	if progress_label:
		if memory_stage >= 3 and current_memory >= max_memory:
			progress_label.text = "当前记忆已完全恢复"
			progress_label.modulate = Color.YELLOW
		elif can_trigger_stage_event:
			progress_label.text = "当前恢复已达到目标\n可触发关键事件"
			progress_label.modulate = Color(1.0, 0.95, 0.6)
		elif current_ap <= 0:
			progress_label.text = "行动点不足"
			progress_label.modulate = Color.RED
		else:
			progress_label.text = ""
			progress_label.modulate = Color.WHITE

	# 日常恢复按钮
	if start_rehab_btn:
		if resource_manager.has_method("can_do_rehab_training"):
			var rehab_check = resource_manager.can_do_rehab_training()
			start_rehab_btn.disabled = not rehab_check.get("success", false)
		else:
			start_rehab_btn.disabled = (current_memory >= max_memory or current_ap <= 0)

		# 达到当前阶段目标后，隐藏日常恢复按钮
		if can_trigger_stage_event:
			start_rehab_btn.visible = false
		else:
			start_rehab_btn.visible = true

		# 最终恢复完成后，不再显示日常恢复按钮
		if memory_stage >= 3 and current_memory >= max_memory:
			start_rehab_btn.visible = false

	# 阶段事件按钮
	if stage_event_btn:
		stage_event_btn.text = "触发关键事件"

		# 只有达到当前阶段目标时，才显示关键事件按钮
		if can_trigger_stage_event:
			stage_event_btn.visible = true
			stage_event_btn.disabled = false
		else:
			stage_event_btn.visible = false
			stage_event_btn.disabled = true

		# 最终阶段满值后，不再开放事件按钮
		if memory_stage >= 3 and current_memory >= max_memory:
			stage_event_btn.disabled = true
			stage_event_btn.visible = false

		# 如果还不能触发，就显示提示
		if not can_trigger_stage_event and stage_event_reason != "":
			stage_event_btn.tooltip_text = stage_event_reason
		else:
			stage_event_btn.tooltip_text = ""

# ===================== 更新进度条 =====================
func _update_progress(current_memory: int):
	if memory_progress:
		memory_progress.max_value = max_memory
		memory_progress.value = clamp(current_memory, 0, max_memory)

# ===================== 按钮点击逻辑 =====================
# 日常恢复按钮
func _on_start_rehab():
	if not resource_manager or not constants:
		return

	if not resource_manager.has_method("perform_rehab_training"):
		if progress_label:
			progress_label.text = "未接入康复训练逻辑"
			progress_label.modulate = Color.RED
		return

	var result = resource_manager.perform_rehab_training()

	if not result.get("success", false):
		if progress_label:
			progress_label.text = str(result.get("reason", "康复训练失败"))
			progress_label.modulate = Color.RED
		_refresh_panel()
		return

	var changes = result.get("changes", {})
	var memory_gain = int(changes.get("memory", 0))

	_lock_feedback_refresh = true

	if progress_label:
		progress_label.text = "康复训练完成\n记忆恢复度 +%d" % memory_gain
		progress_label.modulate = Color.GREEN

	if start_rehab_btn:
		start_rehab_btn.disabled = true

	print("✅ 康复训练成功：行动点-1，记忆恢复度+", memory_gain)

	await get_tree().create_timer(1.0).timeout
	_lock_feedback_refresh = false
	_refresh_panel()

# 阶段关键事件按钮
func _on_stage_event_pressed():
	if not resource_manager:
		return

	if not resource_manager.has_method("can_trigger_memory_stage_event"):
		if progress_label:
			progress_label.text = "未接入阶段事件逻辑"
			progress_label.modulate = Color.RED
		return

	var check_result = resource_manager.can_trigger_memory_stage_event()
	if not check_result.get("success", false):
		if progress_label:
			progress_label.text = str(check_result.get("reason", "当前无法触发阶段事件"))
			progress_label.modulate = Color.RED
		_refresh_panel()
		return

	var event_id := ""
	if resource_manager.has_method("get_memory_stage_event_id"):
		event_id = str(resource_manager.get_memory_stage_event_id())

	# 当前阶段事件入口：
	# 后续接剧情演出 / 对话框系统时，直接在主场景里实现 start_memory_stage_event(event_id) 即可
	var main = get_tree().current_scene
	if main and main.has_method("start_memory_stage_event"):
		hide_panel()
		main.start_memory_stage_event(event_id)
		print("✅ 已请求主场景触发记忆阶段事件：", event_id)
		return

	# 如果当前还没接剧情系统，这里先给出占位提示
	if progress_label:
		progress_label.text = "已解锁关键事件\n事件ID：%s" % event_id
		progress_label.modulate = Color(1.0, 0.9, 0.5)

# ===================== 关闭面板 =====================
func _on_close_panel():
	hide_panel()

	var main = get_tree().current_scene
	if main and main.has_method("_on_rehab_panel_closed"):
		main._on_rehab_panel_closed()
		print("✅ 调用 main._on_rehab_panel_closed() 成功")
	else:
		print("❌ 无法调用 main._on_rehab_panel_closed()")
		if get_parent() and get_parent().has_method("_on_rehab_panel_closed"):
			get_parent()._on_rehab_panel_closed()
			print("✅ 调用父节点方法成功")

# ===================== 外部资源变化监听 =====================
func _on_core_resource_changed(resource_name: String, new_value: int, delta: int):
	if not visible:
		return

	if _lock_feedback_refresh:
		return

	if resource_name == constants.RES_MEMORY:
		_refresh_panel()
