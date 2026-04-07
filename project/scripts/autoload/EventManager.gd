# 周中事件管理器 - 负责事件池选择、概率触发、后台数据结算
# 核心流程：方向值 → 事件池选择 → 条件筛选(含阶段/连锁/不重复) → 加权随机 → 唯一触发 → 数据结算
extends Node

signal event_pool_determined(pool_name: String)
signal event_selected(event_data: Dictionary)
signal event_effects_applied(effects: Dictionary)

# 事件池阈值（方向值高低分界线，可调整）
const DIRECTION_THRESHOLD: int = 50

# 6个事件池数据，按池名索引
var event_pools: Dictionary = {}

# 连锁事件数据（跨池引用）
var chain_events: Array = []

# 基准方向值（用于事件池选择，不受事件效果影响）
var base_direction_values: Dictionary = {"art": 0, "business": 0, "human": 0}

# 已触发事件ID集合（防重复触发）
var triggered_event_ids: Dictionary = {}

# 上一次触发的事件记录（用于测试展示）
var last_triggered_pool: String = ""
var last_triggered_event: Dictionary = {}
var last_eligible_events: Array = []

# 防止可重复事件连续触发：记录上次是否为可重复事件
var _last_was_repeatable: bool = false
var _consecutive_repeatable_count: int = 0

# 当前游戏阶段: 1=前期, 2=中期, 3=后期
var current_stage: int = 1

var resource_manager: Node = null
var constants: Node = null

func _ready():
	resource_manager = get_node_or_null("/root/ResourceManager")
	constants = get_node_or_null("/root/Constants")
	_load_all_event_pools()
	_load_chain_events()
	# 监听周变化以更新阶段
	var game_mgr = get_node_or_null("/root/GameManager")
	if game_mgr:
		EventBus.week_changed.connect(_on_week_changed)

func _on_week_changed(week: int):
	if week >= 13:
		current_stage = 3
	elif week >= 5:
		current_stage = 2
	else:
		current_stage = 1
	print("[EventManager] 当前阶段:", current_stage)

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

func _load_chain_events():
	var path = "res://project/data/events/chain_events.json"
	chain_events = _load_json_file(path)
	if chain_events.size() > 0:
		# 将连锁事件注入到对应的事件池中
		for evt in chain_events:
			var pool_name = evt.get("pool", "")
			if pool_name != "" and event_pools.has(pool_name):
				event_pools[pool_name].append(evt)
				print("[EventManager] 连锁事件注入池:", pool_name, " id:", evt.get("id", "?"))
			elif pool_name != "":
				push_warning("[EventManager] 连锁事件的池不存在:" + pool_name)
		print("[EventManager] 加载连锁事件:", chain_events.size(), "个")

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

func trigger_midweek_event() -> Dictionary:
	if not resource_manager or not constants:
		resource_manager = get_node_or_null("/root/ResourceManager")
		constants = get_node_or_null("/root/Constants")
	
	# 第1步：确定事件池
	var pool_name = determine_event_pool()
	last_triggered_pool = pool_name
	print("\n========== 周中事件触发 (阶段:%d) ==========" % current_stage)
	print("[EventManager] 当前事件池: ", pool_name)
	event_pool_determined.emit(pool_name)
	
	# 第2步：从事件池中筛选合格事件（含阶段、连锁前置、不重复检查）
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
	
	# 记录已触发（非repeatable事件）
	var event_id = selected.get("id", "")
	if event_id != "" and not selected.get("repeatable", false):
		triggered_event_ids[event_id] = true
		_last_was_repeatable = false
		_consecutive_repeatable_count = 0
	else:
		_last_was_repeatable = true
		_consecutive_repeatable_count += 1
	
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
	
	# 处理连锁解锁：选项中的 unlocks 字段记录要解锁的后续事件ID
	var unlocks = option.get("unlocks", [])
	for unlock_id in unlocks:
		# 解锁标记：在triggered_event_ids中用特殊前缀记录
		triggered_event_ids["_unlocked_" + str(unlock_id)] = true
		print("[EventManager] 解锁连锁事件:", unlock_id)
	
	event_effects_applied.emit(effects)

# ===================== 事件池选择逻辑 =====================

func determine_event_pool() -> String:
	var art = base_direction_values.get("art", 0)
	var business = base_direction_values.get("business", 0)
	var human = base_direction_values.get("human", 0)
	
	print("[EventManager] 基准方向值 => 艺术:", art, " 商业:", business, " 人情:", human)
	
	var max_val = art
	var max_dim = "art"
	
	if business > max_val:
		max_val = business
		max_dim = "business"
	
	if human > max_val:
		max_val = human
		max_dim = "human"
	
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
	
	var level = "high" if max_val > DIRECTION_THRESHOLD else "low"
	var pool_name = level + "_" + max_dim
	
	print("[EventManager] 最高方向:", max_dim, "=", max_val, " 阈值:", DIRECTION_THRESHOLD, " => 池:", pool_name)
	return pool_name

# ===================== 事件筛选逻辑 =====================

func get_eligible_events(pool_name: String) -> Array:
	if not event_pools.has(pool_name):
		push_warning("[EventManager] 事件池不存在:" + pool_name)
		return []
	
	var pool = event_pools[pool_name]
	var eligible = []
	
	for event_data in pool:
		if _check_all_conditions(event_data):
			eligible.append(event_data)
	
	# 安全兜底：如果没有任何事件满足条件，放入所有无条件的可重复事件
	if eligible.is_empty():
		print("[EventManager] 无事件满足条件，启用兜底：放入可重复事件")
		for event_data in pool:
			if event_data.get("repeatable", false):
				eligible.append(event_data)
	
	# 再次兜底：放入所有无条件且未触发的事件
	if eligible.is_empty():
		for event_data in pool:
			var conditions = event_data.get("trigger_conditions", {})
			if conditions.is_empty() and not event_data.get("requires_event", "").length() > 0:
				eligible.append(event_data)
	
	# 最终兜底
	if eligible.is_empty() and pool.size() > 0:
		print("[EventManager] 兜底：强制放入池中第一个事件")
		eligible.append(pool[0])
	
	return eligible

# 综合检查：触发条件 + 阶段 + 不重复 + 连锁前置
func _check_all_conditions(event_data: Dictionary) -> bool:
	var event_id = event_data.get("id", "")
	
	# 1. 不重复检查（repeatable事件跳过此检查）
	if not event_data.get("repeatable", false):
		if triggered_event_ids.has(event_id):
			return false
	
	# 2. 阶段检查
	var stage = event_data.get("stage", 0)  # 0=不限阶段
	if stage > 0 and stage != current_stage:
		return false
	
	# 允许的阶段范围：min_stage / max_stage
	var min_stage = event_data.get("min_stage", 0)
	var max_stage = event_data.get("max_stage", 0)
	if min_stage > 0 and current_stage < min_stage:
		return false
	if max_stage > 0 and current_stage > max_stage:
		return false
	
	# 3. 连锁前置事件检查
	var requires = event_data.get("requires_event", "")
	if requires != "":
		# 需要前置事件已被触发，且该事件被"解锁"（通过选项的unlocks字段）
		if not triggered_event_ids.has("_unlocked_" + requires):
			return false
	
	# 4. 资源条件检查
	if not _check_trigger_conditions(event_data):
		return false
	
	return true

func _check_trigger_conditions(event_data: Dictionary) -> bool:
	var conditions = event_data.get("trigger_conditions", {})
	
	if conditions.is_empty():
		return true
	
	for resource_name in conditions:
		var constraint = conditions[resource_name]
		var current_value = _get_resource_value(resource_name)
		
		if current_value == -1:
			print("[EventManager] 警告：未知资源名:", resource_name)
			continue
		
		if constraint.has("max"):
			if current_value > int(constraint["max"]):
				return false
		
		if constraint.has("min"):
			if current_value < int(constraint["min"]):
				return false
	
	return true

# ===================== 加权随机选择 =====================

func select_single_event(eligible_events: Array) -> Dictionary:
	if eligible_events.is_empty():
		return {}
	
	if eligible_events.size() == 1:
		return eligible_events[0]
	
	# 检查是否有非重复事件，若有则大幅削减重复事件权重
	var has_non_repeatable = false
	for evt in eligible_events:
		if not evt.get("repeatable", false):
			has_non_repeatable = true
			break
	
	var total_weight = 0
	var adjusted_weights = []
	for evt in eligible_events:
		var w = int(evt.get("weight", 10))
		if evt.get("repeatable", false):
			# 基础削减：有非重复事件时权重降为1/5
			if has_non_repeatable:
				w = maxi(w / 5, 1)
			# 连续触发惩罚：上次也是可重复事件，权重再 ÷ (连续次数+1)
			if _last_was_repeatable:
				w = maxi(w / (_consecutive_repeatable_count + 1), 1)
		# 已解锁的连锁事件：权重额外 ×2
		if evt.get("requires_event", "") != "":
			w = w * 2
		adjusted_weights.append(w)
		total_weight += w
	
	if total_weight <= 0:
		return eligible_events[randi() % eligible_events.size()]
	
	var roll = randi() % total_weight
	var cumulative = 0
	
	for i in range(eligible_events.size()):
		cumulative += adjusted_weights[i]
		if roll < cumulative:
			return eligible_events[i]
	
	return eligible_events[eligible_events.size() - 1]

# ===================== 效果应用 =====================

func _apply_single_effect(key: String, delta: int):
	if not resource_manager:
		push_warning("[EventManager] ResourceManager不可用，无法应用效果")
		return
	
	match key:
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

func set_direction_values(art: int, business: int, human: int):
	base_direction_values["art"] = art
	base_direction_values["business"] = business
	base_direction_values["human"] = human
	if not resource_manager:
		resource_manager = get_node_or_null("/root/ResourceManager")
	if resource_manager:
		resource_manager.ai_weights["art"] = art
		resource_manager.ai_weights["business"] = business
		resource_manager.ai_weights["human"] = human
	print("[EventManager] 基准方向值已设置 => 艺术:", art, " 商业:", business, " 人情:", human)

func set_resource_value(resource_name: String, new_value: int):
	if not resource_manager:
		resource_manager = get_node_or_null("/root/ResourceManager")
	if resource_manager and resource_manager.core_resources.has(resource_name):
		var old_value = resource_manager.core_resources[resource_name].value
		var delta = new_value - old_value
		resource_manager.modify_core_resource(resource_name, delta)
		print("[EventManager] 资源设置 ", resource_name, " => ", new_value)

func get_all_pool_names() -> Array:
	return event_pools.keys()

func get_pool_summary(pool_name: String) -> String:
	if not event_pools.has(pool_name):
		return "池不存在: " + pool_name
	
	var summary = "事件池[" + pool_name + "] 共" + str(event_pools[pool_name].size()) + "个事件:\n"
	for evt in event_pools[pool_name]:
		var cond_str = "无条件" if evt.get("trigger_conditions", {}).is_empty() else str(evt.get("trigger_conditions", {}))
		summary += "  " + evt.get("id", "?") + " | " + evt.get("title", "?") + " | 权重:" + str(evt.get("weight", 0)) + " | 条件:" + cond_str + "\n"
	return summary

# 检查某事件是否已触发
func is_event_triggered(event_id: String) -> bool:
	return triggered_event_ids.has(event_id)

# 检查某事件是否已解锁（连锁前置满足）
func is_event_unlocked(event_id: String) -> bool:
	return triggered_event_ids.has("_unlocked_" + event_id)

# 获取当前阶段
func get_current_stage() -> int:
	return current_stage

# 手动设置阶段（测试用）
func set_stage(stage: int):
	current_stage = clampi(stage, 1, 3)
	print("[EventManager] 阶段设置为:", current_stage)

# 重置已触发记录（测试用）
func reset_triggered_events():
	triggered_event_ids.clear()
	print("[EventManager] 已触发事件记录已清空")

# 获取已触发事件列表（测试/调试用）
func get_triggered_event_ids() -> Array:
	var ids = []
	for key in triggered_event_ids:
		if not key.begins_with("_unlocked_"):
			ids.append(key)
	return ids

# 获取已解锁事件列表（测试/调试用）
func get_unlocked_event_ids() -> Array:
	var ids = []
	for key in triggered_event_ids:
		if key.begins_with("_unlocked_"):
			ids.append(key.substr(10))  # 去掉 "_unlocked_" 前缀
	return ids

# 获取所有连锁事件数据（测试用）
func get_all_chain_events() -> Array:
	return chain_events

# 直接按ID触发指定连锁事件（测试用，绕过事件池和条件检查）
func trigger_chain_event_by_id(event_id: String) -> Dictionary:
	for evt in chain_events:
		if evt.get("id", "") == event_id:
			last_triggered_event = evt
			# 标记已触发
			triggered_event_ids[event_id] = true
			print("[EventManager] 测试触发连锁事件:", event_id, " - ", evt.get("title", "?"))
			event_selected.emit(evt)
			return evt
	push_warning("[EventManager] 未找到连锁事件:" + event_id)
	return {}

# 强制解锁指定事件（测试用）
func force_unlock_event(event_id: String):
	triggered_event_ids["_unlocked_" + event_id] = true
	print("[EventManager] 强制解锁:", event_id)

# 获取连锁事件的链式关系描述（测试用）
func get_chain_info() -> Array:
	# 返回所有链的起点事件（没有 requires_event 的连锁事件，或其前置在普通池中）
	var chains = []  # [{name, events: [{id, title, status}]}]
	
	# 找出所有链的入口（前置事件在普通池而非连锁列表中的事件）
	var chain_ids = {}
	for evt in chain_events:
		chain_ids[evt.get("id", "")] = evt
	
	# 按链分组
	var visited = {}
	for evt in chain_events:
		var req = evt.get("requires_event", "")
		# 如果前置不在连锁列表中，说明这是链的入口（B节点，A在普通池中）
		if req != "" and not chain_ids.has(req) and not visited.has(evt.get("id", "")):
			var chain = {"name": "", "events": []}
			# 先加入前置事件（A节点，在普通池中）
			chain["events"].append({
				"id": req,
				"title": "(前置) " + req,
				"triggered": triggered_event_ids.has(req),
				"unlocked": triggered_event_ids.has("_unlocked_" + req) or not chain_ids.has(req)
			})
			# 沿着链走
			var current = evt
			while current != null:
				var cid = current.get("id", "")
				visited[cid] = true
				chain["events"].append({
					"id": cid,
					"title": current.get("title", "?"),
					"triggered": triggered_event_ids.has(cid),
					"unlocked": triggered_event_ids.has("_unlocked_" + cid)
				})
				# 找下一个：看谁的 requires_event == cid
				var next_evt = null
				for candidate in chain_events:
					if candidate.get("requires_event", "") == cid:
						next_evt = candidate
						break
				current = next_evt
			chain["name"] = chain["events"][0]["id"].split("_")[0] if chain["events"].size() > 0 else "unknown"
			chains.append(chain)
	
	return chains
