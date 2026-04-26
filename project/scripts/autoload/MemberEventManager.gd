# 成员专属事件管理器
# 负责成员个人事件、关键转阶事件、矛盾事件的触发与管理
# 独立于周中公共事件池（EventManager），在周中阶段概率触发
extends Node

signal member_event_triggered(member_id: String, event_data: Dictionary)
signal conflict_event_triggered(conflict_data: Dictionary)
signal relationship_stage_changed(member_id: String, new_stage: int)
signal relationship_locked(member_id: String)

# ===================== 常量 =====================

# 个人事件触发概率（每个成员独立25%）
const PERSONAL_EVENT_CHANCE: float = 0.25
# 矛盾事件触发概率（满足条件时30%）
const CONFLICT_EVENT_CHANCE: float = 0.30
# 矛盾事件凝聚力阈值（低于此值才可能触发）
const COHESION_THRESHOLD: int = 35
# 关系阶段阈值
const STAGE_2_THRESHOLD: int = 30
const STAGE_3_THRESHOLD: int = 60

# ===================== 数据 =====================

# 成员个人事件数据 {member_id: {stage_1_events, key_1to2, stage_2_events, key_2to3, stage_3_events}}
var personal_events: Dictionary = {}
# 矛盾事件数据 [conflict_data]
var conflict_events: Array = []

# ===================== 运行时状态 =====================

# 成员关系值 {member_id: int}（0-100）
var relationships: Dictionary = {}
# 成员关系阶段 {member_id: int}（1/2/3）
var relationship_stages: Dictionary = {}
# 已完成的关键事件 {event_id: true}
var completed_key_events: Dictionary = {}
# 关系被锁0的成员 {member_id: true}
var locked_members: Dictionary = {}
# 调解信号（梅的调解能力激活后为true）
var mediation_active: bool = false
# 已永久解决的矛盾 {conflict_id: true}
var resolved_conflicts: Dictionary = {}
# 已解锁的特殊标志 {flag_name: true}（用于trigger_conditions检查）
var unlocked_flags: Dictionary = {}
# 本周已触发事件的成员 {member_id: true}（每周重置）
var _weekly_triggered: Dictionary = {}

# 上次触发的事件（调试用）
var last_triggered_events: Array = []
# 当前待显示的成员事件队列（供 MemberEventDialog 消费）
var pending_midweek_events: Array = []
var show_after_midweek_return: bool = false
var completed_event_ids: Dictionary = {}
var recent_member_ids: Array = []
var recent_event_ids: Array = []

func _ready():
	_load_personal_events()
	_load_conflict_events()
	_init_relationships()
	# 监听周变化，每周重置
	if EventBus.has_signal("week_changed"):
		EventBus.week_changed.connect(_on_week_changed)

func _on_week_changed(_week: int):
	_weekly_triggered.clear()

func prepare_post_midweek_return_events() -> Array:
	_init_relationships()
	var event = _pick_post_midweek_event()
	if event.is_empty():
		pending_midweek_events.clear()
		show_after_midweek_return = false
		return []
	pending_midweek_events = [event]
	last_triggered_events = pending_midweek_events.duplicate(true)
	show_after_midweek_return = true
	print("[MemberEventManager] 返回主界面后待触发成员事件:", event.get("id", "?"))
	return pending_midweek_events.duplicate(true)

func has_post_midweek_return_events() -> bool:
	return show_after_midweek_return and not pending_midweek_events.is_empty()

func consume_post_midweek_return_flag() -> void:
	show_after_midweek_return = false

func mark_event_completed(event_data: Dictionary) -> void:
	var event_id = event_data.get("id", "")
	if event_id != "":
		completed_event_ids[event_id] = true
		_push_recent_event(event_id)
	if event_data.get("_event_type", "") == "key" or event_data.get("_event_type", "") == "special":
		if event_id != "":
			completed_key_events[event_id] = true
	for member_id in _extract_event_member_ids(event_data):
		_push_recent_member(member_id)

func _pick_post_midweek_event() -> Dictionary:
	var candidates: Array = []
	var unlocked = ResourceManager.get_unlocked_members()
	for member_id in unlocked:
		if locked_members.has(member_id):
			continue
		candidates.append_array(_collect_member_candidates(member_id))
	candidates.append_array(_collect_conflict_candidates(unlocked))
	if candidates.is_empty():
		return {}

	var preferred: Array = []
	for event_data in candidates:
		var event_id = event_data.get("id", "")
		var member_ids = _extract_event_member_ids(event_data)
		var hit_recent_member = false
		for member_id in member_ids:
			if recent_member_ids.has(member_id):
				hit_recent_member = true
				break
		if not recent_event_ids.has(event_id) and not hit_recent_member:
			preferred.append(event_data)

	var pool: Array = preferred if not preferred.is_empty() else candidates
	return pool[randi() % pool.size()].duplicate(true)

func _collect_member_candidates(member_id: String) -> Array:
	var candidates: Array = []
	if not personal_events.has(member_id):
		return candidates
	var member_data = personal_events[member_id]
	var stage = int(relationship_stages.get(member_id, 1))
	var rel = int(relationships.get(member_id, 0))

	# 仅收集当前阶段的日常事件，保证不会出现“二阶段先于一阶段”。
	var stage_key = "stage_%d_events" % stage
	for event_data in member_data.get(stage_key, []):
		var event_id = event_data.get("id", "")
		if event_id == "" or completed_event_ids.has(event_id):
			continue
		var copied = event_data.duplicate(true)
		copied["_event_type"] = "personal"
		copied["_member_id"] = member_id
		candidates.append(copied)

	# 转阶关键事件作为“特殊事件”参与抽取，但仍遵循阶段与阈值。
	if stage == 1 and rel >= STAGE_2_THRESHOLD:
		var key_1to2 = member_data.get("key_1to2", {})
		var key_1to2_id = key_1to2.get("id", "")
		if not key_1to2.is_empty() and key_1to2_id != "" and not completed_event_ids.has(key_1to2_id):
			if _check_trigger_conditions(key_1to2.get("trigger_conditions", {})):
				var copied_key_1to2 = key_1to2.duplicate(true)
				copied_key_1to2["_event_type"] = "special"
				copied_key_1to2["_member_id"] = member_id
				candidates.append(copied_key_1to2)

	if stage == 2 and rel >= STAGE_3_THRESHOLD:
		var key_2to3 = member_data.get("key_2to3", {})
		var key_2to3_id = key_2to3.get("id", "")
		if not key_2to3.is_empty() and key_2to3_id != "" and not completed_event_ids.has(key_2to3_id):
			if _check_trigger_conditions(key_2to3.get("trigger_conditions", {})):
				var copied_key_2to3 = key_2to3.duplicate(true)
				copied_key_2to3["_event_type"] = "special"
				copied_key_2to3["_member_id"] = member_id
				candidates.append(copied_key_2to3)
	return candidates

func _collect_conflict_candidates(unlocked: Array) -> Array:
	var candidates: Array = []
	var cohesion = ResourceManager.get_resource_value("cohesion")
	for conflict in conflict_events:
		var conflict_id = conflict.get("id", "")
		if conflict_id == "" or completed_event_ids.has(conflict_id) or resolved_conflicts.has(conflict_id):
			continue
		var member_a = conflict.get("member_a", "")
		var member_b = conflict.get("member_b", "")
		if member_a not in unlocked or member_b not in unlocked:
			continue
		if cohesion >= int(conflict.get("cohesion_threshold", COHESION_THRESHOLD)):
			continue
		var copied = conflict.duplicate(true)
		copied["_event_type"] = "conflict"
		candidates.append(copied)
	return candidates

func _extract_event_member_ids(event_data: Dictionary) -> Array:
	var ids: Array = []
	var member_id = event_data.get("_member_id", "")
	if member_id != "":
		ids.append(member_id)
	var member_a = event_data.get("member_a", "")
	if member_a != "" and not ids.has(member_a):
		ids.append(member_a)
	var member_b = event_data.get("member_b", "")
	if member_b != "" and not ids.has(member_b):
		ids.append(member_b)
	return ids

func _push_recent_member(member_id: String) -> void:
	if member_id == "":
		return
	recent_member_ids.erase(member_id)
	recent_member_ids.push_back(member_id)
	while recent_member_ids.size() > 3:
		recent_member_ids.pop_front()

func _push_recent_event(event_id: String) -> void:
	if event_id == "":
		return
	recent_event_ids.erase(event_id)
	recent_event_ids.push_back(event_id)
	while recent_event_ids.size() > 5:
		recent_event_ids.pop_front()

# ===================== 数据加载 =====================

func _load_personal_events():
	var path = "res://project/data/events/member_personal_events.json"
	var data = _load_json(path)
	if data is Dictionary:
		personal_events = data
		print("[MemberEventManager] 加载成员事件数据:", personal_events.size(), "个成员")
	else:
		push_warning("[MemberEventManager] 成员事件数据加载失败")

func _load_conflict_events():
	var path = "res://project/data/events/member_conflict_events.json"
	var data = _load_json(path)
	if data is Array:
		conflict_events = data
		print("[MemberEventManager] 加载矛盾事件:", conflict_events.size(), "个")

func _load_json(path: String):
	if not FileAccess.file_exists(path):
		push_warning("[MemberEventManager] 文件不存在:" + path)
		return null
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var json_text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_text) != OK:
		push_warning("[MemberEventManager] JSON解析失败:" + path)
		return null
	return json.data

func _init_relationships():
	var unlocked = ResourceManager.get_unlocked_members()
	for member_id in unlocked:
		if not relationships.has(member_id):
			relationships[member_id] = 0
			relationship_stages[member_id] = 1

# ===================== 核心流程：周中成员事件触发 =====================

## 处理周中成员事件，返回本周所有要触发的成员事件列表
## 每个事件为 Dictionary，含 _event_type ("personal"/"conflict"/"key") 和 _member_id
func process_midweek_member_events() -> Array:
	_init_relationships()  # 确保新成员被注册
	var triggered_events: Array = []
	var members_with_events: Array = []

	# 第1步：优先判定矛盾事件（30%概率）
	if not mediation_active:
		var eligible_conflicts = _get_eligible_conflicts()
		if eligible_conflicts.size() > 0 and randf() < CONFLICT_EVENT_CHANCE:
			var conflict = eligible_conflicts[randi() % eligible_conflicts.size()]
			conflict["_event_type"] = "conflict"
			triggered_events.append(conflict)
			members_with_events.append(conflict.get("member_a", ""))
			members_with_events.append(conflict.get("member_b", ""))
			print("[MemberEventManager] 触发矛盾事件:", conflict.get("id", "?"))

	# 第2步：逐个成员判定个人事件（25%独立概率）
	var unlocked = ResourceManager.get_unlocked_members()
	for member_id in unlocked:
		if member_id in members_with_events:
			continue  # 已在矛盾事件中，本周不再触发个人事件
		if locked_members.has(member_id):
			continue  # 关系锁0，不触发事件

		# 25%概率
		if randf() > PERSONAL_EVENT_CHANCE:
			continue

		# 优先检查关键转阶事件
		var event = _try_get_key_event(member_id)
		if event != null:
			event["_event_type"] = "key"
			event["_member_id"] = member_id
			triggered_events.append(event)
			members_with_events.append(member_id)
			continue

		# 随机阶段事件
		event = _try_get_stage_event(member_id)
		if event != null:
			event["_event_type"] = "personal"
			event["_member_id"] = member_id
			triggered_events.append(event)
			members_with_events.append(member_id)

	last_triggered_events = triggered_events
	pending_midweek_events = triggered_events.duplicate()
	print("[MemberEventManager] 本周触发成员事件数:", triggered_events.size())
	return triggered_events

# ===================== 矛盾事件检查 =====================

func _get_eligible_conflicts() -> Array:
	var eligible: Array = []
	var cohesion = ResourceManager.get_resource_value("cohesion")

	for conflict in conflict_events:
		var cid = conflict.get("id", "")
		# 已永久解决
		if resolved_conflicts.has(cid):
			continue
		var member_a = conflict.get("member_a", "")
		var member_b = conflict.get("member_b", "")
		var threshold = conflict.get("cohesion_threshold", COHESION_THRESHOLD)

		# 凝聚力低于阈值
		if cohesion >= threshold:
			continue
		# 双方都已入队
		var unlocked = ResourceManager.get_unlocked_members()
		if member_a not in unlocked or member_b not in unlocked:
			continue
		# 调解信号未激活（已在上层检查）
		eligible.append(conflict)

	return eligible

# ===================== 关键事件检查 =====================

func _try_get_key_event(member_id: String) -> Dictionary:
	if not personal_events.has(member_id):
		return {}
	var member_data = personal_events[member_id]
	var stage = relationship_stages.get(member_id, 1)
	var rel = relationships.get(member_id, 0)

	# 阶段1 → 检查1转2关键事件
	if stage == 1 and rel >= STAGE_2_THRESHOLD:
		var key_event = member_data.get("key_1to2", {})
		if not key_event.is_empty() and not completed_key_events.has(key_event.get("id", "")):
			if _check_trigger_conditions(key_event.get("trigger_conditions", {})):
				return key_event.duplicate(true)

	# 阶段2 → 检查2转3关键事件
	if stage == 2 and rel >= STAGE_3_THRESHOLD:
		var key_event = member_data.get("key_2to3", {})
		if not key_event.is_empty() and not completed_key_events.has(key_event.get("id", "")):
			if _check_trigger_conditions(key_event.get("trigger_conditions", {})):
				return key_event.duplicate(true)

	return {}

## 检查关键事件的额外触发条件
## conditions 格式: {"recovery":{"min":30}, "reputation":{"min":200}, "cohesion":{"max":50}, ...}
## 支持字段: recovery(记忆恢复度), reputation, money, cohesion, creativity
## 以及布尔标志: father_relic_unlocked 等
func _check_trigger_conditions(conditions: Dictionary) -> bool:
	if conditions.is_empty():
		return true
	for key in conditions:
		var rule = conditions[key]
		# 布尔型标志检查
		if typeof(rule) == TYPE_BOOL:
			var flag_val = unlocked_flags.get(key, false)
			if bool(flag_val) != bool(rule):
				return false
			continue
		# 数值范围检查
		var current_val: int = _get_condition_value(key)
		if rule.has("min") and current_val < int(rule["min"]):
			return false
		if rule.has("max") and current_val > int(rule["max"]):
			return false
	return true

## 根据条件键名获取对应数值
func _get_condition_value(key: String) -> int:
	match key:
		"recovery":
			return ResourceManager.get_resource_value("memory_recovery")
		"reputation":
			return ResourceManager.get_resource_value("reputation")
		"money":
			return ResourceManager.get_resource_value("money")
		"cohesion":
			return ResourceManager.get_resource_value("cohesion")
		"creativity":
			return ResourceManager.get_resource_value("creativity")
		_:
			return 0

# ===================== 阶段随机事件 =====================

func _try_get_stage_event(member_id: String) -> Dictionary:
	if not personal_events.has(member_id):
		return {}
	var member_data = personal_events[member_id]
	var stage = relationship_stages.get(member_id, 1)

	var stage_key = "stage_%d_events" % stage
	var events = member_data.get(stage_key, [])
	if events.is_empty():
		return {}

	# 随机选一个
	var event = events[randi() % events.size()]
	return event.duplicate(true)

# ===================== 效果应用 =====================

## 应用成员事件选项效果
## member_id: 关联的成员ID（个人/关键事件时有效）
## option: 玩家选择的选项 Dictionary
## conflict_members: 矛盾事件涉及的成员列表（矛盾事件时有效）
func apply_member_event_effects(member_id: String, option: Dictionary, conflict_members: Array = []):
	var effects = option.get("effects", {})

	for key in effects:
		var delta = int(effects[key])

		match key:
			"relationship":
				# 修改关联成员的关系值
				if member_id != "":
					add_relationship(member_id, delta)
			"each_relationship":
				# 矛盾事件：对双方都生效
				for mid in conflict_members:
					add_relationship(mid, delta)
			"cohesion":
				ResourceManager.modify_core_resource("cohesion", delta)
			"creativity":
				ResourceManager.modify_core_resource("creativity", delta)
			"money":
				ResourceManager.modify_core_resource("money", delta)
			"reputation":
				ResourceManager.modify_core_resource("reputation", delta)
			"memory":
				ResourceManager.modify_core_resource("memory", delta)
			"recovery":
				ResourceManager.modify_core_resource("memory_recovery", delta)
			"mood":
				ResourceManager.modify_core_resource("mood", delta)
			_:
				# 检查是否是 "{member_id}_relationship" 格式
				if key.ends_with("_relationship"):
					var target_id = key.substr(0, key.length() - 13)
					add_relationship(target_id, delta)

	# 处理关键事件晋级
	if option.get("advance", false) and member_id != "":
		_advance_stage(member_id)

	# 处理锁0
	if option.get("lock_zero", false) and member_id != "":
		_lock_relationship(member_id)

	# 处理解锁调解
	if option.get("unlock_mediation", false):
		mediation_active = true
		print("[MemberEventManager] 调解能力已解锁！")

	# 处理通用解锁标志（unlock_fathers_relic, unlock_main_truth 等）
	for opt_key in option:
		if opt_key.begins_with("unlock_") and opt_key != "unlock_mediation":
			if option[opt_key] == true:
				var flag_name = opt_key.substr(7)  # 去掉 "unlock_" 前缀
				unlocked_flags[flag_name] = true
				print("[MemberEventManager] 解锁标志: ", flag_name)

	# 处理矛盾永久解决
	if option.get("permanently_resolved", false):
		# 在矛盾事件的调解结果中使用
		pass

## 应用矛盾事件的调解结果
func apply_mediation_result(conflict_data: Dictionary):
	var result = conflict_data.get("mediation_result", {})
	if result.is_empty():
		return
	var effects = result.get("effects", {})
	var member_a = conflict_data.get("member_a", "")
	var member_b = conflict_data.get("member_b", "")

	for key in effects:
		var delta = int(effects[key])
		match key:
			"each_relationship":
				add_relationship(member_a, delta)
				add_relationship(member_b, delta)
			"cohesion":
				ResourceManager.modify_core_resource("cohesion", delta)

	if result.get("permanently_resolved", false):
		var cid = conflict_data.get("id", "")
		resolved_conflicts[cid] = true
		print("[MemberEventManager] 矛盾已永久解决:", cid)

# ===================== 关系值管理 =====================

func get_relationship(member_id: String) -> int:
	return relationships.get(member_id, 0)

func set_relationship(member_id: String, value: int):
	if locked_members.has(member_id):
		print("[MemberEventManager] 成员", member_id, "关系已锁0，无法修改")
		return
	relationships[member_id] = clampi(value, 0, 100)
	EventBus.relationship_changed.emit(member_id, relationships[member_id])
	print("[MemberEventManager] 设置", member_id, "关系值:", relationships[member_id])

func add_relationship(member_id: String, delta: int):
	if locked_members.has(member_id):
		print("[MemberEventManager] 成员", member_id, "关系已锁0，无法修改")
		return
	var old_val = relationships.get(member_id, 0)
	var new_val = clampi(old_val + delta, 0, 100)
	relationships[member_id] = new_val
	EventBus.relationship_changed.emit(member_id, new_val)
	print("[MemberEventManager] ", member_id, " 关系值:", old_val, "→", new_val, " (", delta, ")")

func get_relationship_stage(member_id: String) -> int:
	return relationship_stages.get(member_id, 1)

func _advance_stage(member_id: String):
	var old_stage = relationship_stages.get(member_id, 1)
	if old_stage >= 3:
		return
	var new_stage = old_stage + 1
	relationship_stages[member_id] = new_stage
	# 标记关键事件完成
	var key_name = "key_%dto%d" % [old_stage, new_stage]
	if personal_events.has(member_id):
		var key_event = personal_events[member_id].get(key_name, {})
		if not key_event.is_empty():
			completed_key_events[key_event.get("id", "")] = true
	relationship_stage_changed.emit(member_id, new_stage)
	EventBus.character_stage_changed.emit(member_id, new_stage)
	print("[MemberEventManager] ", member_id, " 关系阶段:", old_stage, "→", new_stage)

func _lock_relationship(member_id: String):
	locked_members[member_id] = true
	relationships[member_id] = 0
	relationship_locked.emit(member_id)
	print("[MemberEventManager] ⚠ ", member_id, " 关系已锁0！")

# ===================== 调试/测试 =====================

## 强制设置关系阶段（测试用）
func force_set_stage(member_id: String, stage: int):
	relationship_stages[member_id] = clampi(stage, 1, 3)
	print("[MemberEventManager] 强制设置", member_id, "阶段:", stage)

## 重置所有数据（测试用）
func reset_all():
	completed_key_events.clear()
	completed_event_ids.clear()
	locked_members.clear()
	resolved_conflicts.clear()
	mediation_active = false
	_weekly_triggered.clear()
	last_triggered_events.clear()
	pending_midweek_events.clear()
	show_after_midweek_return = false
	recent_member_ids.clear()
	recent_event_ids.clear()
	for member_id in relationships:
		relationships[member_id] = 0
		relationship_stages[member_id] = 1
	print("[MemberEventManager] 所有数据已重置")

## 解锁关系锁0（测试用）
func unlock_relationship(member_id: String):
	locked_members.erase(member_id)
	print("[MemberEventManager] 解锁", member_id, "关系锁定")

## 获取成员名称
func get_member_display_name(member_id: String) -> String:
	var data = ResourceManager.get_member_data(member_id)
	return data.get("name", member_id)

## 获取所有成员状态摘要（测试用）
func get_all_status_summary() -> String:
	var lines: Array = []
	for member_id in relationships:
		var name = get_member_display_name(member_id)
		var rel = relationships[member_id]
		var stage = relationship_stages.get(member_id, 1)
		var locked = "🔒" if locked_members.has(member_id) else ""
		lines.append("%s(%s): 关系%d 阶段%d %s" % [name, member_id, rel, stage, locked])
	return "\n".join(lines)

## 直接触发指定成员的事件（测试用，绕过概率）
func force_trigger_member_event(member_id: String) -> Dictionary:
	_init_relationships()
	# 优先关键事件
	var event = _try_get_key_event(member_id)
	if not event.is_empty():
		event["_event_type"] = "key"
		event["_member_id"] = member_id
		return event
	# 随机阶段事件
	event = _try_get_stage_event(member_id)
	if not event.is_empty():
		event["_event_type"] = "personal"
		event["_member_id"] = member_id
		return event
	return {}

## 直接触发矛盾事件（测试用）
func force_trigger_conflict() -> Dictionary:
	var eligible = _get_eligible_conflicts()
	if eligible.size() > 0:
		var conflict = eligible[0].duplicate(true)
		conflict["_event_type"] = "conflict"
		return conflict
	# 即使不满足条件也强制返回第一个矛盾事件
	if conflict_events.size() > 0:
		var conflict = conflict_events[0].duplicate(true)
		conflict["_event_type"] = "conflict"
		conflict["_forced"] = true
		return conflict
	return {}
