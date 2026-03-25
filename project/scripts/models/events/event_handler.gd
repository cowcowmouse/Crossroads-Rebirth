extends Node

# 信号：事件完成
signal event_completed(event_id: String, option_index: int)

# 预加载事件对话框场景
var event_dialog_scene = preload("res://project/scenes/event/EventDialog.tscn")

# 存储事件数据
var event_pool: Array = []
var current_dialog = null

func _ready():
	print("EventHandler: 初始化")
	load_events()

# 加载事件配置文件
func load_events():
	var file_path = "res://project/data/events/midweek_events.json"
	
	print("尝试加载: ", file_path)
	
	if not FileAccess.file_exists(file_path):
		print("错误: 找不到事件文件 ", file_path)
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	
	var json = JSON.new()
	var error = json.parse(content)
	
	if error == OK:
		event_pool = json.data
		print("成功加载 ", event_pool.size(), " 个事件")
		for event in event_pool:
			print("  - ", event.get("title", "无标题"))
	else:
		print("JSON 解析错误: ", json.get_error_message())

# 触发随机事件（由按钮调用）
func trigger_random_event():
	print("触发随机事件...")
	
	if event_pool.is_empty():
		print("事件池为空，无法触发")
		return
	
	# 随机抽取一个事件
	var random_index = randi() % event_pool.size()
	var event_data = event_pool[random_index]
	
	print("抽中事件: ", event_data.get("title", "未知"))
	
	# 如果已有对话框在显示，先关闭旧的
	if current_dialog:
		current_dialog.queue_free()
	
	# 创建新对话框
	current_dialog = event_dialog_scene.instantiate()
	add_child(current_dialog)
	
	# 连接信号
	current_dialog.option_selected.connect(_on_option_selected)
	
	# 显示事件
	current_dialog.show_event(event_data)

# 玩家选择了选项
func _on_option_selected(event_id: String, option_index: int, effects: Dictionary):
	print("=====================================================")
	print("事件选项被选中")
	print("事件ID: ", event_id)
	print("选项索引: ", option_index)
	print("效果: ", effects)
	print("=====================================================")
	
	_apply_effects(effects)
	event_completed.emit(event_id, option_index)
	
	# 注意：不在这里清理对话框，让对话框自己处理关闭

func _apply_effects(effects: Dictionary):
	print("应用效果:")
	for key in effects:
		var delta = effects[key]
		match key:
			"money":
				ResourceManager.add_money(delta)
			"reputation":
				ResourceManager.add_reputation(delta)
			"cohesion":
				ResourceManager.add_cohesion(delta)
			"creativity":
				ResourceManager.add_creativity(delta)
			"art_weight":
				ResourceManager.modify_ai_weight(Constants.WEIGHT_ART, delta)
			"business_weight":
				ResourceManager.modify_ai_weight(Constants.WEIGHT_BUSINESS, delta)
			"human_weight":
				ResourceManager.modify_ai_weight(Constants.WEIGHT_HUMAN, delta)
