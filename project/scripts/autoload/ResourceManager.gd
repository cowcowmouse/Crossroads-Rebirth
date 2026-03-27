extends Node

@onready var event_bus = EventBus
@onready var constants: Node = Constants

# 只声明变量，不在顶层初始化
var core_resources: Dictionary = {}
var ai_weights: Dictionary = {}  # 空字典声明，不赋值
var members: Dictionary = {}
var action_points: int = 3
var facility_levels: Dictionary = {}
# 节点就绪后自动初始化（此时 constants 已赋值）
func _ready():
	init_new_game()

# 新游戏初始化
func init_new_game():
	# 初始化四类核心资源（严格对齐设计文档）
	core_resources = {
		constants.RES_MONEY: {"value": 5000, "min": 0, "max": 999999},
		constants.RES_REPUTATION: {"value": 10, "min": 0, "max": 100},
		constants.RES_COHESION: {"value": 60, "min": 0, "max": 100},
		constants.RES_CREATIVITY: {"value": 30, "min": 0, "max": 100},
		constants.RES_MEMORY: {"value": 0, "min": 0, "max": 100}
	}
	
	# 行动点初始化
	action_points = 3
		# 设施等级初始化
	facility_levels = {
		"stage": 1,
		"bar": 1,
		"lounge": 1,
		"rehearsal": 1
	}
	
	# AI权重初始化
	ai_weights = {
		constants.WEIGHT_ART: 0,
		constants.WEIGHT_BUSINESS: 0,
		constants.WEIGHT_HUMAN: 0
	}
	
	# 初始化初始成员数据
	_init_default_members()
	
	print("核心资源初始化完成")
	refresh_current_scene_topbar()

# 初始化默认成员
func _init_default_members():
	members = {
		constants.MEMBER_RIO: {
			"name": "里奥",
			"role": "鼓手",
			"unlocked": true,
			"relationship_progress": 0,
			"weekly_chat_count": 0,
			"morale": 60,
			"fatigue": 30,
			"health": 80,
			"skill": 50,
			"charm": 50
		},
		constants.MEMBER_KIRA: {
			"name": "凯拉",
			"role": "主唱",
			"unlocked": true,
			"relationship_progress": 0,
			"weekly_chat_count": 0,
			"morale": 60,
			"fatigue": 30,
			"health": 80,
			"skill": 50,
			"charm": 50
		},
		constants.MEMBER_MEI: {
			"name": "梅",
			"role": "贝斯手",
			"unlocked": true,
			"relationship_progress": 0,
			"weekly_chat_count": 0,
			"morale": 60,
			"fatigue": 30,
			"health": 80,
			"skill": 50,
			"charm": 50
		},
		constants.MEMBER_old_NAIL: {
			"name": "老钉子",
			"role": "酒吧守护者",
			"unlocked": true,
			"relationship_progress": 1,
			"weekly_chat_count": 0,
			"morale": 100,
			"fatigue": 0,
			"health": 100,
			"skill": 80,
			"charm": 60
		}
	}

# ===================== 核心资源通用接口 =====================

# 修改核心资源，返回是否成功
func modify_core_resource(resource_name: String, delta: int) -> bool:
	if not core_resources.has(resource_name):
		print("错误：不存在的资源", resource_name)
		return false
	
	var res_data = core_resources[resource_name]
	var old_value = int(res_data["value"])
	var new_value = clamp(old_value + delta, int(res_data["min"]), int(res_data["max"]))
	var actual_delta = new_value - old_value

	if actual_delta == 0:
		return false

	# 更新数值
	res_data["value"] = new_value
	core_resources[resource_name] = res_data
	
	# 发射信号通知UI刷新
	event_bus.core_resource_changed.emit(resource_name, new_value, actual_delta)
	
	# 检查资源边界事件
	_check_resource_boundary_event(resource_name, new_value)
	
	# 刷新当前场景顶部UI
	refresh_current_scene_topbar()
	
	print("资源变动：", resource_name, " ", actual_delta, "，当前值：", new_value)
	return true

# 获取资源当前值
func get_resource_value(resource_name: String) -> int:
	if core_resources.has(resource_name):
		return int(core_resources[resource_name]["value"])
	return -1

# ===================== 便捷资源操作方法 =====================

func add_money(amount: int) -> bool:
	return modify_core_resource(constants.RES_MONEY, amount)

func add_reputation(amount: int) -> bool:
	return modify_core_resource(constants.RES_REPUTATION, amount)

func add_cohesion(amount: int) -> bool:
	return modify_core_resource(constants.RES_COHESION, amount)

func add_creativity(amount: int) -> bool:
	return modify_core_resource(constants.RES_CREATIVITY, amount)

func add_memory(amount: int) -> bool:
	return modify_core_resource(constants.RES_MEMORY, amount)

# ===================== 行动点接口 =====================

# 获取当前行动点
func get_action_points() -> int:
	return action_points

# 检查行动点是否足够
func can_consume_action_points(cost: int = 1) -> bool:
	return action_points >= cost

# 消耗行动点
func consume_action_point(cost: int = 1) -> bool:
	if action_points < cost:
		return false
	
	action_points -= cost
	
	# 刷新顶部UI
	refresh_current_scene_topbar()
	
	# 发射行动点耗尽信号
	if action_points <= 0 and event_bus.has_signal("action_points_exhausted"):
		event_bus.action_points_exhausted.emit()
	
	print("行动点消耗：", cost, "，当前剩余：", action_points)
	return true

# 恢复行动点（每周重置时调用）
func restore_action_points():
	action_points = 3
	refresh_current_scene_topbar()
	print("行动点已恢复为：", action_points)

# ===================== 顶部UI刷新 =====================

# 刷新当前场景顶部资源栏
func refresh_current_scene_topbar():
	var current_scene = get_tree().current_scene
	if not current_scene:
		return

	var money_label = current_scene.get_node_or_null("UILayer/TopBar/MoneyGroup/MoneyLabel")
	var reputation_label = current_scene.get_node_or_null("UILayer/TopBar/ReputationGroup/ReputationLabel")
	var cohesion_label = current_scene.get_node_or_null("UILayer/TopBar/CohesionGroup/CohesionLabel")
	var creativity_label = current_scene.get_node_or_null("UILayer/TopBar/CreativityGroup/CreativityLabel")
	var memory_label = current_scene.get_node_or_null("UILayer/TopBar/MemoryGroup/MemoryLabel")
	var action_point_label = current_scene.get_node_or_null("UILayer/TopBar/ActionPointGroup/ActionPointLabel")

	if money_label:
		money_label.text = "资金: %d" % get_resource_value(constants.RES_MONEY)

	if reputation_label:
		reputation_label.text = "声誉: %d" % get_resource_value(constants.RES_REPUTATION)

	if cohesion_label:
		cohesion_label.text = "凝聚力: %d" % get_resource_value(constants.RES_COHESION)

	if creativity_label:
		creativity_label.text = "创造力: %d" % get_resource_value(constants.RES_CREATIVITY)

	if memory_label:
		memory_label.text = "记忆恢复度: %d" % get_resource_value(constants.RES_MEMORY)

	if action_point_label:
		action_point_label.text = "行动点: %d/3" % action_points

# ===================== AI权重接口 =====================

func modify_ai_weight(weight_name: String, delta: int):
	if ai_weights.has(weight_name):
		ai_weights[weight_name] += delta
		event_bus.weight_changed.emit(weight_name, ai_weights[weight_name], delta)
		print("权重变动：", weight_name, " ", delta, "，当前值：", ai_weights[weight_name])

func get_ai_weight(weight_name: String) -> int:
	if ai_weights.has(weight_name):
		return ai_weights[weight_name]
	return 0

func get_all_weights() -> Dictionary:
	return ai_weights.duplicate()

# ===================== 成员数据接口 =====================

# 获取成员数据
func get_member_data(member_id: String) -> Dictionary:
	if members.has(member_id):
		return members[member_id].duplicate()
	return {}

# 获取所有已解锁成员
func get_unlocked_members() -> Array:
	var unlocked = []
	for member_id in members:
		if members[member_id].get("unlocked", false):
			unlocked.append(member_id)
	return unlocked

# 修改成员状态（士气/疲劳/健康等）
func modify_member_stat(member_id: String, stat_name: String, delta: int) -> bool:
	if not members.has(member_id):
		print("错误：不存在的成员", member_id)
		return false
	
	var member = members[member_id]
	if not member.has(stat_name):
		print("错误：成员", member_id, "没有属性", stat_name)
		return false
	
	var old_value = member[stat_name]
	var new_value = old_value + delta
	
	# 根据属性类型限制范围
	match stat_name:
		"morale", "fatigue", "health", "skill", "charm", "soberness", "popularity":
			new_value = clamp(new_value, 0, 100)
	
	member[stat_name] = new_value
	var actual_delta = new_value - old_value

	event_bus.member_stat_changed.emit(member_id, stat_name, new_value, actual_delta)
	print("成员", member_id, "属性", stat_name, "变化:", actual_delta, "，当前:", new_value)
	return true

# 获取成员特定属性值
func get_member_stat(member_id: String, stat_name: String) -> int:
	if members.has(member_id) and members[member_id].has(stat_name):
		return members[member_id][stat_name]
	return -1

# ===================== 互动进度管理 =====================

# 增加互动进度（对话次数）
func add_relationship_progress(member_id: String, delta: int = 1) -> int:
	if not members.has(member_id):
		return 0
	
	var member = members[member_id]
	var old_progress = member.get("relationship_progress", 0)
	var new_progress = old_progress + delta
	
	member["relationship_progress"] = new_progress
	
	# 检查是否进入下一对话阶段
	var old_stage = _get_dialogue_stage(old_progress)
	var new_stage = _get_dialogue_stage(new_progress)
	
	if new_stage > old_stage:
		print("成员", member_id, "对话进入第", new_stage, "阶段")
		event_bus.member_dialogue_stage_changed.emit(member_id, new_stage)
	
	return new_progress

# 获取对话阶段（0-5阶段1，6-11阶段2，12+阶段3）
func _get_dialogue_stage(progress: int) -> int:
	if progress >= 12:
		return 3
	elif progress >= 6:
		return 2
	else:
		return 1

# 获取当前对话阶段
func get_dialogue_stage(member_id: String) -> int:
	if members.has(member_id):
		var progress = members[member_id].get("relationship_progress", 0)
		return _get_dialogue_stage(progress)
	return 1

# 增加周对话次数
func add_weekly_chat_count(member_id: String):
	if members.has(member_id):
		members[member_id]["weekly_chat_count"] = members[member_id].get("weekly_chat_count", 0) + 1

# 重置所有成员的周对话次数（每周结算时调用）
func reset_weekly_chat_counts():
	for member_id in members:
		members[member_id]["weekly_chat_count"] = 0

# ===================== 成员状态自然变化 =====================

# 应用所有成员的自然状态变化（疲劳+、士气-）
func apply_member_natural_change():
	for member_id in members:
		var member = members[member_id]
		# 疲劳自然增加
		var fatigue_increase = 5
		modify_member_stat(member_id, "fatigue", fatigue_increase)
		
		# 士气自然下降（如果疲劳过高则下降更多）
		var morale_decrease = 2
		if member.get("fatigue", 0) > 80:
			morale_decrease = 5
		modify_member_stat(member_id, "morale", -morale_decrease)

# ===================== 内部边界检查 =====================

func _check_resource_boundary_event(resource_name: String, new_value: int):
	match resource_name:
		constants.RES_COHESION:
			if new_value < 30:
				print("警告：凝聚力低于30，进入危险状态！")
				event_bus.resource_warning.emit(resource_name, new_value, "danger")
		constants.RES_MONEY:
			if new_value <= 0:
				print("警告：资金耗尽，触发破产判定！")
				event_bus.resource_warning.emit(resource_name, new_value, "critical")
		constants.RES_CREATIVITY:
			if new_value < 10:
				print("警告：创造力过低，无法进行艺术操作！")
				event_bus.resource_warning.emit(resource_name, new_value, "low")

# ===================== 周结算相关 =====================

# 每周固定支出（租金+工资）
const WEEKLY_EXPENSE = 1500

# 执行每周扣款
func apply_weekly_expense() -> bool:
	return add_money(-WEEKLY_EXPENSE)

# 获取每周支出金额
func get_weekly_expense() -> int:
	return WEEKLY_EXPENSE
# ===================== 设施等级接口 =====================

# 获取设施等级
func get_facility_level(facility_type: String) -> int:
	if facility_levels.has(facility_type):
		return int(facility_levels[facility_type])
	return -1

# 设置设施等级
func set_facility_level(facility_type: String, level: int):
	facility_levels[facility_type] = level
	print("设施等级更新：", facility_type, " -> ", level)
