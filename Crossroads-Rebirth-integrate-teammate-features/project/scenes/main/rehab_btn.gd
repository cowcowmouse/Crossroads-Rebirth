# 挂在 Rehabpanel（Panel 节点）上的独立脚本
extends Panel

# ===================== 面板内子节点引用 =====================
@onready var title_label = $TitleLabel             # 标题标签
@onready var memory_progress = $MemoryProgress     # 记忆进度条
@onready var progress_label = $ProgressLabel       # 进度文字
@onready var start_rehab_btn = $StartRehabBtn      # 开始训练按钮
@onready var close_btn = $CloseBtn                 # 关闭按钮

# ===================== 配置参数 =====================
@export var max_memory = 100                       # 最大记忆值
@export var default_memory = 20                    # 初始记忆值
var current_memory = 0                             # 当前记忆值

# ===================== 初始化 =====================
func _ready():
	# 1. 初始隐藏面板
	self.visible = false
	
	# 2. 初始化记忆数值和进度条
	current_memory = default_memory
	_update_progress()
	
	# 3. 连接面板内按钮信号
	if start_rehab_btn:
		start_rehab_btn.pressed.connect(_on_start_rehab)
	if close_btn:
		close_btn.pressed.connect(_on_close_panel)
	
	# 4. 监听外部触发（比如Main节点调用显示面板）
	print("✅ 康复面板初始化完成")

# ===================== 核心逻辑：显示/隐藏面板 =====================
# 外部调用：显示康复面板（Main节点用这个函数触发）
func show_panel():
	self.visible = true
	# 显示时聚焦面板（可选）
	self.grab_focus()
	print("🏥 康复面板已显示")

# 外部调用：隐藏康复面板
func hide_panel():
	self.visible = false
	print("❌ 康复面板已隐藏")

# ===================== 进度条更新 =====================
# 更新进度条和文字显示
func _update_progress():
	if memory_progress:
		memory_progress.max_value = max_memory
		memory_progress.value = current_memory

	if progress_label:
		var percent := 0
		if max_memory > 0:
			percent = int(float(current_memory) / max_memory * 100)

		progress_label.text = "记忆恢复度：%d%%" % percent
# 外部调用：增加记忆值（完成小游戏后调用）
func add_memory(value: int):
	current_memory = clamp(current_memory + value, 0, max_memory)
	_update_progress()
	print("记忆值 +%d，当前：%d" % [value, current_memory])

# ===================== 按钮点击逻辑 =====================
# 开始记忆化训练小游戏
func _on_start_rehab():
	print("🎮 开始记忆化训练小游戏")
	# 跳转到康复小游戏场景（替换成你的小游戏场景路径）
	get_tree().change_scene_to_file("res://project/scenes/rehab/minigame_memory.tscn")

# 关闭面板
func _on_close_panel():
	hide_panel()
	
	# 直接调用根场景的恢复方法
	var main = get_tree().current_scene
	if main and main.has_method("_on_rehab_panel_closed"):
		main._on_rehab_panel_closed()
		print("✅ 调用 main._on_rehab_panel_closed() 成功")
	else:
		print("❌ 无法调用 main._on_rehab_panel_closed()")
		# 备用方案：尝试通过父节点调用
		if get_parent().has_method("_on_rehab_panel_closed"):
			get_parent()._on_rehab_panel_closed()
			print("✅ 调用父节点方法成功")
