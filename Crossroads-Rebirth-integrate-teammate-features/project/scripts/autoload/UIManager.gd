extends Node

# 场景缓存（避免重复加载）
var scene_cache = {}

# 当前打开的界面
var current_dialog = null
var current_panel = null

# ==================== 初始化 ====================

func _ready():
	process_mode = PROCESS_MODE_ALWAYS


# ==================== 场景切换 ====================

func show_main_scene():
	"""显示主场景"""
	var scene = get_tree().current_scene
	if scene and scene.name != "Main":
		get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func show_sub_scene(scene_path: String):
	"""显示子场景（覆盖在当前场景上）"""
	var scene = load_scene(scene_path)
	if scene:
		var instance = scene.instantiate()
		get_tree().current_scene.add_child(instance)
		current_panel = instance
		EventBus.scene_opened.emit(scene_path)

func close_sub_scene():
	"""关闭当前子场景"""
	if current_panel:
		current_panel.queue_free()
		current_panel = null
		EventBus.scene_closed.emit()


# ==================== 对话框管理 ====================

func show_dialog(text: String, options: Array = [], callback = null):
	"""
	显示通用对话框
	options: [{"text": "确定", "action": "confirm"}, ...]
	callback: 回调函数，参数为选中的option索引
	"""
	var dialog = load_scene("res://scenes/shared/dialog_box.tscn")
	if dialog:
		var instance = dialog.instantiate()
		instance.set_text(text)
		instance.set_options(options)
		if callback:
			instance.connect("option_selected", callback)
		get_tree().current_scene.add_child(instance)
		current_dialog = instance

func show_member_dialogue(member_id: String):
	"""显示成员对话界面"""
	var dialogue = load_scene("res://scenes/member/MemberDialogue.tscn")
	if dialogue:
		var instance = dialogue.instantiate()
		instance.set_member(member_id)
		get_tree().current_scene.add_child(instance)
		current_dialog = instance

func show_event_dialog(event_id: String):
	"""显示事件对话框"""
	var event_dialog = load_scene("res://scenes/event/EventDialog.tscn")
	if event_dialog:
		var instance = event_dialog.instantiate()
		instance.set_event(event_id)
		get_tree().current_scene.add_child(instance)
		current_dialog = instance

func show_minigame(game_type: String, difficulty: String = "normal"):
	"""显示小游戏场景"""
	var minigame = load_scene("res://scenes/minigame/MiniGame.tscn")
	if minigame:
		var instance = minigame.instantiate()
		instance.set_game(game_type, difficulty)
		get_tree().current_scene.add_child(instance)
		current_dialog = instance

func show_settlement_panel(week_data: Dictionary):
	"""显示周结算面板"""
	var panel = load_scene("res://scenes/event/SettlementPanel.tscn")
	if panel:
		var instance = panel.instantiate()
		instance.set_data(week_data)
		get_tree().current_scene.add_child(instance)
		current_panel = instance

func close_dialog():
	"""关闭当前对话框"""
	if current_dialog:
		current_dialog.queue_free()
		current_dialog = null


# ==================== 提示与弹窗 ====================

func show_tooltip(text: String, position: Vector2 = Vector2.ZERO):
	"""显示浮动提示"""
	var tooltip = load_scene("res://scenes/shared/tooltip.tscn")
	if tooltip:
		var instance = tooltip.instantiate()
		instance.set_text(text)
		if position != Vector2.ZERO:
			instance.position = position
		get_tree().current_scene.add_child(instance)
		# 2秒后自动消失
		await get_tree().create_timer(2.0).timeout
		if is_instance_valid(instance):
			instance.queue_free()

func show_notification(text: String, duration: float = 2.0):
	"""显示通知（顶部/底部弹窗）"""
	var notification = load_scene("res://scenes/shared/notification.tscn")
	if notification:
		var instance = notification.instantiate()
		instance.set_text(text)
		get_tree().current_scene.add_child(instance)
		await get_tree().create_timer(duration).timeout
		if is_instance_valid(instance):
			instance.queue_free()

func show_confirm_dialog(text: String, on_confirm: Callable, on_cancel: Callable = Callable()):
	"""显示确认对话框"""
	var dialog = load_scene("res://scenes/shared/confirm_dialog.tscn")
	if dialog:
		var instance = dialog.instantiate()
		instance.set_text(text)
		instance.set_callbacks(on_confirm, on_cancel)
		get_tree().current_scene.add_child(instance)
		current_dialog = instance


# ==================== UI更新 ====================

func update_resource_display():
	"""刷新所有资源显示"""
	EventBus.ui_refresh_requested.emit("resources")


func update_member_display():
	"""刷新成员显示"""
	EventBus.ui_refresh_requested.emit("members")

func update_facility_display():
	"""刷新设施显示"""
	EventBus.ui_refresh_requested.emit("facilities")


# ==================== 新手引导 ====================

func highlight_element(element_path: String, highlight_text: String = ""):
	"""高亮某个UI元素（用于新手引导）"""
	var target = get_tree().current_scene.get_node(element_path)
	if target:
		EventBus.element_highlight.emit(target, highlight_text)

func clear_highlight():
	"""清除高亮"""
	EventBus.highlight_cleared.emit()


# ==================== 工具方法 ====================

func load_scene(path: String):
	"""加载场景（带缓存）"""
	if scene_cache.has(path):
		return scene_cache[path]
	
	if ResourceLoader.exists(path):
		var scene = load(path)
		scene_cache[path] = scene
		return scene
	else:
		print("[UIManager] 场景不存在: ", path)
		return null

func preload_scene(path: String):
	"""预加载场景（后台加载）"""
	if ResourceLoader.exists(path) and not scene_cache.has(path):
		scene_cache[path] = load(path)

func get_current_scene():
	"""获取当前活动场景"""
	return get_tree().current_scene
