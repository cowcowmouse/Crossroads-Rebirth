extends Panel

# ===================== 面板内子节点引用 =====================
@onready var title_label = $TitleLabel
@onready var memory_progress = $MemoryProgress
@onready var progress_label = $ProgressLabel
@onready var start_rehab_btn = $StartRehabBtn
@onready var close_btn = $CloseBtn

# ===================== 全局管理器引用 =====================
@onready var resource_manager = get_node("/root/ResourceManager")
@onready var constants = get_node("/root/Constants")
@onready var event_bus = get_node_or_null("/root/EventBus")

# ===================== 配置参数 =====================
@export var max_memory: int = 100
@export var training_memory_gain: int = 5
@export var minigame_scene_path: String = "res://project/scenes/rehab/minigame_memory.tscn"
@export var jump_to_minigame: bool = false   # 当前先 false，后续接小游戏时改 true

# 防止成功提示被资源刷新立刻覆盖
var _lock_feedback_refresh: bool = false

# ===================== 初始化 =====================
func _ready():
	visible = false

	if title_label:
		title_label.text = "个人状态"

	if progress_label:
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if start_rehab_btn:
		start_rehab_btn.pressed.connect(_on_start_rehab)

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

	_update_progress(current_memory)

	var percent := 0
	if max_memory > 0:
		percent = int(round(float(current_memory) / float(max_memory) * 100.0))

	if progress_label:
		if current_memory >= max_memory:
			progress_label.text = "记忆恢复度：%d%%\n\n记忆恢复度已满" % percent
			progress_label.modulate = Color.YELLOW
		elif current_ap <= 0:
			progress_label.text = "记忆恢复度：%d%%\n\n行动点不足\n当前行动点：%d/%d" % [percent, current_ap, max_ap]
			progress_label.modulate = Color.RED
		else:
			progress_label.text = "记忆恢复度：%d%%\n\n消耗：1 行动点\n效果：记忆恢复度 +%d\n\n当前行动点：%d/%d" % [
				percent,
				training_memory_gain,
				current_ap,
				max_ap
			]
			progress_label.modulate = Color.WHITE

	if start_rehab_btn:
		start_rehab_btn.disabled = (current_memory >= max_memory or current_ap <= 0)

# ===================== 更新进度条 =====================
func _update_progress(current_memory: int):
	if memory_progress:
		memory_progress.max_value = max_memory
		memory_progress.value = clamp(current_memory, 0, max_memory)

# ===================== 按钮点击逻辑 =====================
func _on_start_rehab():
	if not resource_manager or not constants:
		return

	var current_memory = resource_manager.get_resource_value(constants.RES_MEMORY)

	if current_memory >= max_memory:
		if progress_label:
			progress_label.text = "记忆恢复度已满"
			progress_label.modulate = Color.YELLOW
		return

	if not resource_manager.can_consume_action_points(1):
		if progress_label:
			progress_label.text = "行动点不足，无法进行康复训练"
			progress_label.modulate = Color.RED
		if start_rehab_btn:
			start_rehab_btn.disabled = true
		return

	# 后续接小游戏时打开
	if jump_to_minigame:
		print("🎮 开始康复训练小游戏：", minigame_scene_path)
		get_tree().change_scene_to_file(minigame_scene_path)
		return

	# ===================== 当前占位逻辑 =====================
	# 消耗1行动点，记忆恢复度 + training_memory_gain
	if not resource_manager.consume_action_point(1):
		if progress_label:
			progress_label.text = "行动点扣除失败"
			progress_label.modulate = Color.RED
		return

	var before_memory = resource_manager.get_resource_value(constants.RES_MEMORY)
	resource_manager.add_memory(training_memory_gain)
	var after_memory = resource_manager.get_resource_value(constants.RES_MEMORY)
	var actual_gain = after_memory - before_memory

	_lock_feedback_refresh = true

	if progress_label:
		progress_label.text = "康复训练完成\n\n行动点 -1\n记忆恢复度 +%d" % actual_gain
		progress_label.modulate = Color.GREEN

	if start_rehab_btn:
		start_rehab_btn.disabled = true

	print("✅ 康复训练成功：行动点-1，记忆恢复度+", actual_gain)

	await get_tree().create_timer(1.0).timeout
	_lock_feedback_refresh = false
	_refresh_panel()

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
