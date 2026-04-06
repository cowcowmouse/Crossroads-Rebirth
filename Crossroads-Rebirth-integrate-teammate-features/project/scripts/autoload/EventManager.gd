# 周中事件管理器 - 负责事件池选择、概率触发、后台数据结算
# 核心流程：方向值 → 事件池选择 → 条件筛选 → 加权随机 → 唯一触发 → 数据结算
extends Node

signal event_pool_determined(pool_name: String)
signal event_selected(event_data: Dictionary)
signal event_effects_applied(effects: Dictionary)

# 事件池阈值（方向值高低分界线，可调整）
const DIRECTION_THRESHOLD: int = 50

# 6个事件池数据，按池名索引
var event_pools: Dictionary = {}

# 基准方向值（用于事件池选择，不受事件效果影响）
# 只通过 set_direction_values() 显式设置，避免正反馈锁死
var base_direction_values: Dictionary = {"art": 0, "business": 0, "human": 0}

# 上一次触发的事件记录（用于测试展示）
var last_triggered_pool: String = ""
var last_triggered_event: Dictionary = {}
var last_eligible_events: Array = []

var resource_manager: Node = null
var constants: Node = null

func _ready():
	resource_manager = get_node_or_null("/root/ResourceManager")
	constants = get_node_or_null("/root/Constants")
	_load_all_event_pools()

# ===================== 数据加载 =====================

func _load_all_event_pools():
	var pool_files = {
		"low_art": "res://project/data/events/event_pool_low_art.json",
		"low_business": "res://project/data/events/event_pool_low_business.json",
		"low_human": "res://project/data/events/event_pool_low_human.json",
		"high_art": "res://project/data/events/event_pool_high_art.json",
		"high_business": "res://project/data/events/event_pool_high_business.json",
		"high_human": "res://project/data/events/event_pool_high_human.json",
	}
	
	for pool_name in pool_files:
		var path = pool_files[pool_name]
		var data = _load_json_file(path)
		if data.size() > 0:
			event_pools[pool_name] = data
			print("[EventManager] 加载事件池:", pool_name, " 事件数:", data.size())
		else:
			push_warning("[EventManager] 事件池为空或加载失败:" + pool_name)
	
	print("[EventManager] 共加载 ", event_pools.size(), " 个事件池")

func _load_json_file(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_warning("[EventManager] 文件不存在:" + path)
		return []
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("[EventManager] 无法打开文件:" + path)
		return []
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_warning("[EventManager] JSON解析失败:" + path + " 错误:" + json.get_error_message())
		return []
	
	var result = json.data
	if result is Array:
		return result
	return []

# ===================== 核心流程：周中事件触发 =====================

# 主入口：触发一次周中事件，返回触发的事件数据
func trigger_midweek_event() -> Dictionary:
	if not resource_manager or not constants:
		resource_manager = get_node_or_null("/root/ResourceManager")
		constants = get_node_or_null("/root/Constants")
	
	# 第1步：确定事件池
	var pool_name = determine_event_pool()
	last_triggered_pool = pool_name
	print("\n========== 周中事件触发 ==========")
	print("[EventManager] 当前事件池: ", pool_name)
	event_pool_determined.emit(pool_name)
	
	# 第2步：从事件池中筛选合格事件
	var eligible = get_eligible_events(pool_name)
	last_eligible_events = eligible
	print("[EventManager] 合格事件数: ", eligible.size())
	for evt in eligible:
		print("  - ", evt.get("id", "?"), " | ", evt.get("title", "?"), " | 权重:", evt.get("weight", 0))
	
	# 第3步：加权随机选择唯一事件
	var selected = select_single_event(eligible)
	last_triggered_event = selected
	if selected.is_empty():
		push_warning("[EventManager] 没有可触发的事件!")
		return {}
	
	print("[EventManager] >>> 触发事件: ", selected.get("id", "?"), " - ", selected.get("title", "?"))
	event_selected.emit(selected)
	return selected

# 应用玩家选择的选项效果到后台数据
func apply_option_effects(option: Dictionary):
	var effects = option.get("effects", {})
	if effects.is_empty():
		return
	
	print("[EventManager] 应用事件效果:")
	for key in effects:
		var delta = int(effects[key])
		_apply_single_effect(key, delta)
	
	event_effects_applied.emit(effects)

# ===================== 事件池选择逻辑 =====================

# 根据基准方向值确定应触发的事件池
# 使用 base_direction_values（显式设置），不受事件效果的 *_weight 修改影响
# 逻辑：取3个方向值中最高者，>THRESHOLD则high池，<=THRESHOLD则low池
func determine_event_pool() -> String:
	var art = base_direction_values.get("art", 0)
	var business = base_direction_values.get("business", 0)
	var human = base_direction_values.get("human", 0)
	
	print("[EventManager] 基准方向值 => 艺术:", art, " 商业:", business, " 人情:", human)
	
	# 找最高方向值及其维度
	var max_val = art
	var max_dim = "art"
	
	if business > max_val:
		max_val = business
		max_dim = "business"
	
	if human > max_val:
		max_val = human
		max_dim = "human"
	
	# 如果有并列最高值，随机选一个
	var tied_dims = []
	if art == max_val:
		tied_dims.append("art")
	if business == max_val:
		tied_dims.append("business")
	if human == max_val:
		tied_dims.append("human")
	
	if tied_dims.size() > 1:
		max_dim = tied_dims[randi() % tied_dims.size()]
		print("[EventManager] 方向值并列，随机选择:", max_dim)
	
	# 根据阈值决定高/低池
	var level = "high" if max_val > DIRECTION_THRESHOLD else "low"
	var pool_name = level + "_" + max_dim
	
	print("[EventManager] 最高方向:", max_dim, "=", max_val, " 阈值:", DIRECTION_THRESHOLD, " => 池:", pool_name)
	return pool_name

# ===================== 事件筛选逻辑 =====================

# 从指定事件池中获取满足触发条件的事件列表
func get_eligible_events(pool_name: String) -> Array:
	if not event_pools.has(pool_name):
		push_warning("[EventManager] 事件池不存在:" + pool_name)
		return []
	
	var pool = event_pools[pool_name]
	var eligible = []
	
	for event_data in pool:
		if _check_trigger_conditions(event_data):
			eligible.append(event_data)
	
	# 安全兜底：如果没有任何事件满足条件，放入所有无条件事件
	if eligible.is_empty():
		print("[EventManager] 无事件满足条件，启用兜底：放入所有无条件事件")
		for event_data in pool:
			var conditions = event_data.get("trigger_conditions", {})
			if conditions.is_empty():
				eligible.append(event_data)
	
	# 最终兜底：如果还是空的，放入池中第一个事件
	if eligible.is_empty() and pool.size() > 0:
		print("[EventManager] 兜底：强制放入池中第一个事件")
		eligible.append(pool[0])
	
	return eligible

# 检查单个事件的触发条件是否满足
func _check_trigger_conditions(event_data: Dictionary) -> bool:
	var conditions = event_data.get("trigger_conditions", {})
	
	# 无条件 = 始终满足
	if conditions.is_empty():
		return true
	
	# 遍历所有条件，全部满足才返回true
	for resource_name in conditions:
		var constraint = conditions[resource_name]
		var current_value = _get_resource_value(resource_name)
		
		if current_value == -1:
			print("[EventManager] 警告：未知资源名:", resource_name)
			continue
		
		# 检查最大值约束
		if constraint.has("max"):
			if current_value > int(constraint["max"]):
				return false
		
		# 检查最小值约束
		if constraint.has("min"):
			if current_value < int(constraint["min"]):
				return false
	
	return true

# ===================== 加权随机选择 =====================

# 从合格事件中加权随机选择唯一一个
func select_single_event(eligible_events: Array) -> Dictionary:
	if eligible_events.is_empty():
		return {}
	
	if eligible_events.size() == 1:
		return eligible_events[0]
	
	# 计算总权重
	var total_weight = 0
	for evt in eligible_events:
		total_weight += int(evt.get("weight", 10))
	
	if total_weight <= 0:
		# 所有权重为0，等概率随机
		return eligible_events[randi() % eligible_events.size()]
	
	# 加权随机选择
	var roll = randi() % total_weight
	var cumulative = 0
	
	for evt in eligible_events:
		cumulative += int(evt.get("weight", 10))
		if roll < cumulative:
			return evt
	
	# 理论上不会到这里，兜底返回最后一个
	return eligible_events[eligible_events.size() - 1]

# ===================== 效果应用 =====================

# 将单个效果应用到后台数据
func _apply_single_effect(key: String, delta: int):
	if not resource_manager:
		push_warning("[EventManager] ResourceManager不可用，无法应用效果")
		return
	
	match key:
		# 核心资源
		"money":
			resource_manager.modify_core_resource("money", delta)
		"reputation":
			resource_manager.modify_core_resource("reputation", delta)
		"cohesion":
			resource_manager.modify_core_resource("cohesion", delta)
		"creativity":
			resource_manager.modify_core_resource("creativity", delta)
		"memory_recovery":
			resource_manager.modify_core_resource("memory_recovery", delta)
		# 方向权重
		"art_weight":
			resource_manager.modify_ai_weight("art", delta)
		"business_weight":
			resource_manager.modify_ai_weight("business", delta)
		"human_weight":
			resource_manager.modify_ai_weight("human", delta)
		_:
			print("[EventManager] 未知效果key:", key, " delta:", delta)

# ===================== 辅助方法 =====================

func _get_weight(weight_name: String) -> int:
	if resource_manager and resource_manager.ai_weights.has(weight_name):
		return resource_manager.ai_weights[weight_name]
	return 0

func _get_resource_value(resource_name: String) -> int:
	if not resource_manager:
		return -1
	return resource_manager.get_resource_value(resource_name)

# 设置基准方向值（影响事件池选择，不受事件效果影响）
func set_direction_values(art: int, business: int, human: int):
	base_direction_values["art"] = art
	base_direction_values["business"] = business
	base_direction_values["human"] = human
	# 同步更新 ResourceManager 的 ai_weights（供其他系统使用）
	if not resource_manager:
		resource_manager = get_node_or_null("/root/ResourceManager")
	if resource_manager:
		resource_manager.ai_weights["art"] = art
		resource_manager.ai_weights["business"] = business
		resource_manager.ai_weights["human"] = human
	print("[EventManager] 基准方向值已设置 => 艺术:", art, " 商业:", business, " 人情:", human)

# 用于测试：手动修改核心资源值
func set_resource_value(resource_name: String, new_value: int):
	if not resource_manager:
		resource_manager = get_node_or_null("/root/ResourceManager")
	if resource_manager and resource_manager.core_resources.has(resource_name):
		var old_value = resource_manager.core_resources[resource_name].value
		var delta = new_value - old_value
		resource_manager.modify_core_resource(resource_name, delta)
		print("[EventManager] 资源设置 ", resource_name, " => ", new_value)

# 获取所有池名列表
func get_all_pool_names() -> Array:
	return event_pools.keys()

# 获取指定池中所有事件简述
func get_pool_summary(pool_name: String) -> String:
	if not event_pools.has(pool_name):
		return "池不存在: " + pool_name
	
	var summary = "事件池[" + pool_name + "] 共" + str(event_pools[pool_name].size()) + "个事件:\n"
	for evt in event_pools[pool_name]:
		var cond_str = "无条件" if evt.get("trigger_conditions", {}).is_empty() else str(evt.get("trigger_conditions", {}))
		summary += "  " + evt.get("id", "?") + " | " + evt.get("title", "?") + " | 权重:" + str(evt.get("weight", 0)) + " | 条件:" + cond_str + "\n"
	return summary
