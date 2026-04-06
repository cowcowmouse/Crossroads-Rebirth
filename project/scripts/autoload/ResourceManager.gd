extends Node

@onready var event_bus = EventBus
@onready var constants: Node = Constants

# 只声明变量，不在顶层初始化
var core_resources: Dictionary = {}
var ai_weights: Dictionary = {}  # 空字典声明，不赋值

# 本周方向值变化记录（用于周结算面板显示）
var weekly_weight_changes: Dictionary = {}

var members: Dictionary = {}
var action_points: int = 3
var facility_levels: Dictionary = {}

# 行动点上限（统一由 ResourceManager 管理）
const MAX_ACTION_POINTS: int = 3

# 设施是否处于升级/维修中
var facility_upgrading: Dictionary = {}

# 设施待生效等级（升级延迟到下周生效）
var facility_pending_levels: Dictionary = {}

# 连续负债周数（用于失败判定）
var debt_weeks: int = 0

# 每周固定支出（租金+工资）
const WEEKLY_EXPENSE = 1500

# 节点就绪后自动初始化（此时 constants 已赋值）
func _ready():
	init_new_game()

# 新游戏初始化
func init_new_game():
	# 本周方向值变化初始化
	weekly_weight_changes = {
		constants.WEIGHT_ART: 0,
		constants.WEIGHT_BUSINESS: 0,
		constants.WEIGHT_HUMAN: 0
	}

	# 初始化四类核心资源（严格对齐设计文档）
	# 注意：资金最小值改为负数，允许出现负债状态
	core_resources = {
		constants.RES_MONEY: {"value": 5000, "min": -999999, "max": 999999},
		constants.RES_REPUTATION: {"value": 10, "min": 0, "max": 100},
		constants.RES_COHESION: {"value": 60, "min": 0, "max": 100},
		constants.RES_CREATIVITY: {"value": 30, "min": 0, "max": 100},
		constants.RES_MEMORY: {"value": 0, "min": 0, "max": 100}
	}
	
	# 行动点初始化
	action_points = MAX_ACTION_POINTS
	
	# 连续负债周数初始化
	debt_weeks = 0
	
	# 设施等级初始化
	facility_levels = {
		"stage": 1,
		"bar": 1,
		"lounge": 1,
		"rehearsal": 1
	}
	
	# 设施升级状态初始化（默认都不在维修中）
	facility_upgrading = {
		"stage": false,
		"bar": false,
		"lounge": false,
		"rehearsal": false
	}
	
	# 设施待生效等级初始化（0 表示没有待生效升级）
	facility_pending_levels = {
		"stage": 0,
		"bar": 0,
		"lounge": 0,
		"rehearsal": 0
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

# ===================== 康复训练接口 =====================

# 检查是否可以执行康复训练
func can_do_rehab_training() -> Dictionary:
	var result := {
		"success": true,
		"reason": ""
	}

	if not can_consume_action_points(1):
		result["success"] = false
		result["reason"] = "行动点不足"
		return result

	# 记忆恢复度满了就不给继续练
	if get_resource_value(constants.RES_MEMORY) >= 100:
		result["success"] = false
		result["reason"] = "记忆恢复度已满"
		return result

	return result


# 执行一次占位版康复训练
# 当前先写成：消耗1行动点，记忆恢复度+5
# 后续接小游戏时，把 add_memory(5) 改成按小游戏结果结算
func perform_rehab_training() -> Dictionary:
	var result := {
		"success": false,
		"reason": "",
		"changes": {}
	}

	var check_result = can_do_rehab_training()
	if not check_result["success"]:
		result["reason"] = check_result["reason"]
		return result

	# 先扣行动点
	if not consume_action_point(1):
		result["reason"] = "行动点不足"
		return result

	var memory_gain := 5

	# 再加记忆恢复度
	if not add_memory(memory_gain):
		# 理论上这里基本不会失败；失败则把行动点补回去
		action_points += 1
		refresh_current_scene_topbar()
		result["reason"] = "记忆恢复度增加失败"
		return result

	result["success"] = true
	result["changes"] = {
		"memory": memory_gain,
		"action_point": -1
	}

	print("康复训练执行成功：行动点-1 记忆恢复度+", memory_gain)
	return result
# ===================== 资金状态接口 =====================

# 是否有足够资金支付指定金额
func can_afford(cost: int) -> bool:
	return get_resource_value(constants.RES_MONEY) >= cost

# 当前是否处于负债状态
func is_in_debt() -> bool:
	return get_resource_value(constants.RES_MONEY) < 0

# 获取连续负债周数
func get_debt_weeks() -> int:
	return debt_weeks

# 在每周结算后更新负债状态
# 规则：
# - 资金 < 0 时，连续负债周数 +1
# - 资金 >= 0 时，连续负债周数清零
func update_debt_status_after_settlement():
	if is_in_debt():
		debt_weeks += 1
		print("连续负债周数：", debt_weeks)
	else:
		if debt_weeks > 0:
			print("已脱离负债状态，连续负债周数清零")
		debt_weeks = 0

# 是否应触发负债失败
# 当前规则：负债持续 1 周即失败
func should_trigger_debt_game_over() -> bool:
	return debt_weeks >= 1

# ===================== 行动点接口 =====================

# 获取当前行动点
func get_action_points() -> int:
	return action_points

# 获取行动点上限
func get_max_action_points() -> int:
	return MAX_ACTION_POINTS

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
	action_points = MAX_ACTION_POINTS
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
		# 资金现在允许显示负数
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
		action_point_label.text = "行动点: %d/%d" % [action_points, MAX_ACTION_POINTS]

# ===================== AI权重接口 =====================

func modify_ai_weight(weight_name: String, delta: int):
	if ai_weights.has(weight_name):
		ai_weights[weight_name] += delta
		
		# 记录本周方向值变化，供周结算面板显示
		if weekly_weight_changes.has(weight_name):
			weekly_weight_changes[weight_name] += delta
		
		event_bus.weight_changed.emit(weight_name, ai_weights[weight_name], delta)
		print("权重变动：", weight_name, " ", delta, "，当前值：", ai_weights[weight_name])

func get_ai_weight(weight_name: String) -> int:
	if ai_weights.has(weight_name):
		return ai_weights[weight_name]
	return 0

func get_all_weights() -> Dictionary:
	return ai_weights.duplicate()

# 获取本周方向值变化记录
func get_weekly_weight_changes() -> Dictionary:
	return weekly_weight_changes.duplicate()

# 重置本周方向值变化记录
func reset_weekly_weight_changes():
	weekly_weight_changes = {
		constants.WEIGHT_ART: 0,
		constants.WEIGHT_BUSINESS: 0,
		constants.WEIGHT_HUMAN: 0
	}
	print("本周方向值变化记录已重置")

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
			# 资金改为允许负数，这里只保留负债警告，不直接锁死
			if new_value < 0:
				print("警告：资金为负，进入负债状态！")
				event_bus.resource_warning.emit(resource_name, new_value, "debt")
		constants.RES_CREATIVITY:
			if new_value < 10:
				print("警告：创造力过低，无法进行艺术操作！")
				event_bus.resource_warning.emit(resource_name, new_value, "low")

# ===================== 周结算相关 =====================

# 执行每周扣款
func apply_weekly_expense() -> bool:
	return add_money(-WEEKLY_EXPENSE)

# 获取每周支出金额
func get_weekly_expense() -> int:
	return WEEKLY_EXPENSE

# ===================== 酒吧基础收入接口 =====================

# 获取酒吧每周基础收入
# 只按“正式等级”结算，不看待生效等级
# 这样可以和“升级下周生效”的逻辑保持一致
func get_bar_base_income() -> int:
	var bar_level = clamp(get_facility_level("bar"), 1, 5)

	match bar_level:
		1:
			return 800
		2:
			return 1300
		3:
			return 2000
		4:
			return 2900
		5:
			return 4200

	return 800

# 应用酒吧每周基础收入
# 返回本次实际结算的收入，方便周结算面板或日志打印
func apply_bar_base_income() -> int:
	var income = get_bar_base_income()
	add_money(income)
	print("酒吧基础收入结算：等级=", get_facility_level("bar"), " 收入=", income)
	return income

# ===================== 舞台效果接口 =====================

# 获取舞台声誉加成倍率
# 返回值示例：
# 1.0 = 无加成
# 1.15 = +15%
# 1.30 = +30%
func get_stage_reputation_multiplier() -> float:
	var stage_level = clamp(get_facility_level("stage"), 1, 5)

	match stage_level:
		1:
			return 1.0
		2:
			return 1.15
		3:
			return 1.30
		4:
			return 1.50
		5:
			return 1.75

	return 1.0

# 根据舞台等级，计算加成后的声誉收益
func calculate_stage_reputation_gain(base_reputation_gain: int) -> int:
	var multiplier = get_stage_reputation_multiplier()
	return int(round(base_reputation_gain * multiplier))

func debug_print_stage_bonus():
	print("当前舞台等级：", get_facility_level("stage"))
	print("当前舞台声誉倍率：", get_stage_reputation_multiplier())
	print("基础声誉10 -> 实际声誉：", calculate_stage_reputation_gain(10))

# ===================== 排练室效果接口 =====================

# 获取排练室对创造力消耗的减免比例
# 返回值示例：
# 0.0 = 无减免
# 0.1 = -10%
# 0.2 = -20%
func get_rehearsal_creativity_discount() -> float:
	var rehearsal_level = clamp(get_facility_level("rehearsal"), 1, 5)

	match rehearsal_level:
		1:
			return 0.0
		2:
			return 0.10
		3:
			return 0.20
		4:
			return 0.30
		5:
			return 0.45

	return 0.0

# 根据排练室等级，计算折扣后的创造力消耗
# 至少消耗 1 点，避免出现 0 消耗
func calculate_rehearsal_creativity_cost(base_cost: int) -> int:
	var discount = get_rehearsal_creativity_discount()
	var final_cost = int(round(base_cost * (1.0 - discount)))
	return max(1, final_cost)

# ===================== 休息室效果接口 =====================

# 获取休息室每周结算时提供的凝聚力恢复值
func get_lounge_cohesion_bonus() -> int:
	var lounge_level = clamp(get_facility_level("lounge"), 1, 5)

	match lounge_level:
		1:
			return 0
		2:
			return 3
		3:
			return 6
		4:
			return 10
		5:
			return 15

	return 0

# 获取休息室每周结算时提供的成员疲劳恢复值
func get_lounge_fatigue_recovery() -> int:
	var lounge_level = clamp(get_facility_level("lounge"), 1, 5)

	match lounge_level:
		1:
			return 0
		2:
			return 4
		3:
			return 8
		4:
			return 12
		5:
			return 18

	return 0

# 应用休息室在周结算时的恢复效果
# 1. 给全体成员降低疲劳
# 2. 给核心资源增加凝聚力
func apply_lounge_weekly_bonus():
	var fatigue_recovery = get_lounge_fatigue_recovery()
	var cohesion_bonus = get_lounge_cohesion_bonus()

	# 恢复全体成员疲劳
	if fatigue_recovery > 0:
		for member_id in members.keys():
			modify_member_stat(member_id, "fatigue", -fatigue_recovery)

	# 恢复凝聚力
	if cohesion_bonus > 0:
		add_cohesion(cohesion_bonus)

	print("休息室周结算加成：疲劳恢复=", fatigue_recovery, " 凝聚力+", cohesion_bonus)

# ===================== 设施互动接口 =====================

# 获取设施互动是否可执行
# 已实现：
# - 酒吧：营业推广
# - 舞台：安排演出
# - 排练室：集中排练
# - 休息室：团队休整
func can_perform_facility_action(facility_type: String) -> Dictionary:
	var result := {
		"success": true,
		"reason": ""
	}

	# 设施维修中不可互动
	if is_facility_upgrading(facility_type):
		result["success"] = false
		result["reason"] = "设施维修中"
		return result

	# 所有设施互动统一先检查行动点
	if not can_consume_action_points(1):
		result["success"] = false
		result["reason"] = "行动点不足"
		return result

	match facility_type:
		"bar":
			var bar_cohesion_cost = get_bar_action_cohesion_cost()
			var bar_creativity_cost = get_bar_action_creativity_cost()

			if get_resource_value(constants.RES_COHESION) < bar_cohesion_cost:
				result["success"] = false
				result["reason"] = "凝聚力不足\n需要：%d" % bar_cohesion_cost
				return result

			if get_resource_value(constants.RES_CREATIVITY) < bar_creativity_cost:
				result["success"] = false
				result["reason"] = "创造力不足\n需要：%d" % bar_creativity_cost
				return result

		"stage":
			var stage_creativity_cost = get_stage_action_creativity_cost()
			var stage_cohesion_cost = get_stage_action_cohesion_cost()

			if get_resource_value(constants.RES_CREATIVITY) < stage_creativity_cost:
				result["success"] = false
				result["reason"] = "创造力不足\n需要：%d" % stage_creativity_cost
				return result

			if get_resource_value(constants.RES_COHESION) < stage_cohesion_cost:
				result["success"] = false
				result["reason"] = "凝聚力不足\n需要：%d" % stage_cohesion_cost
				return result

		"rehearsal":
			var rehearsal_money_cost = get_rehearsal_action_money_cost()
			if not can_afford(rehearsal_money_cost):
				result["success"] = false
				result["reason"] = "资金不足\n需要：%d" % rehearsal_money_cost
				return result

		"lounge":
			var lounge_money_cost = get_lounge_action_money_cost()
			if not can_afford(lounge_money_cost):
				result["success"] = false
				result["reason"] = "资金不足\n需要：%d" % lounge_money_cost
				return result

		_:
			result["success"] = false
			result["reason"] = "该设施互动尚未开放"
			return result

	return result


# 执行设施互动
# 返回格式：
# {
#   "success": true/false,
#   "reason": "",
#   "changes": {
#       "money": -120,
#       "creativity": +4
#   }
# }
func perform_facility_action(facility_type: String) -> Dictionary:
	var result := {
		"success": false,
		"reason": "",
		"changes": {}
	}

	var check_result = can_perform_facility_action(facility_type)
	if not check_result["success"]:
		result["reason"] = check_result["reason"]
		return result

	match facility_type:
		"bar":
			var bar_cohesion_cost = get_bar_action_cohesion_cost()
			var bar_creativity_cost = get_bar_action_creativity_cost()
			var bar_money_gain = get_bar_action_money_gain()

			# 先扣资源，再扣行动点，最后发收益
			add_cohesion(-bar_cohesion_cost)
			add_creativity(-bar_creativity_cost)

			if not consume_action_point(1):
				add_cohesion(bar_cohesion_cost)
				add_creativity(bar_creativity_cost)
				result["reason"] = "行动点不足"
				return result

			add_money(bar_money_gain)

			result["success"] = true
			result["changes"] = {
				"cohesion": -bar_cohesion_cost,
				"creativity": -bar_creativity_cost,
				"money": bar_money_gain
			}

			print("设施互动执行成功：酒吧 -> 营业推广，凝聚力", -bar_cohesion_cost, " 创造力", -bar_creativity_cost, " 资金+", bar_money_gain)
			return result

		"stage":
			var stage_creativity_cost = get_stage_action_creativity_cost()
			var stage_cohesion_cost = get_stage_action_cohesion_cost()
			var stage_money_gain = get_stage_action_money_gain()
			var stage_reputation_gain = get_stage_action_reputation_gain()

			add_creativity(-stage_creativity_cost)
			add_cohesion(-stage_cohesion_cost)

			if not consume_action_point(1):
				add_creativity(stage_creativity_cost)
				add_cohesion(stage_cohesion_cost)
				result["reason"] = "行动点不足"
				return result

			add_money(stage_money_gain)
			add_reputation(stage_reputation_gain)

			result["success"] = true
			result["changes"] = {
				"creativity": -stage_creativity_cost,
				"cohesion": -stage_cohesion_cost,
				"money": stage_money_gain,
				"reputation": stage_reputation_gain
			}

			print("设施互动执行成功：舞台 -> 安排演出，创造力", -stage_creativity_cost, " 凝聚力", -stage_cohesion_cost, " 资金+", stage_money_gain, " 声誉+", stage_reputation_gain)
			return result

		"rehearsal":
			var rehearsal_money_cost = get_rehearsal_action_money_cost()
			var rehearsal_creativity_gain = get_rehearsal_action_creativity_gain()

			# 先扣钱
			if not add_money(-rehearsal_money_cost):
				result["reason"] = "资金不足\n需要：%d" % rehearsal_money_cost
				return result

			# 再扣行动点
			if not consume_action_point(1):
				# 如果行动点扣除失败，把钱补回去
				add_money(rehearsal_money_cost)
				result["reason"] = "行动点不足"
				return result

			# 最后加创造力
			add_creativity(rehearsal_creativity_gain)

			result["success"] = true
			result["changes"] = {
				"money": -rehearsal_money_cost,
				"creativity": rehearsal_creativity_gain
			}

			print("设施互动执行成功：排练室 -> 集中排练，资金", -rehearsal_money_cost, " 创造力+", rehearsal_creativity_gain)
			return result

		"lounge":
			var lounge_money_cost = get_lounge_action_money_cost()
			var lounge_cohesion_gain = get_lounge_action_cohesion_gain()
			var lounge_fatigue_recovery = get_lounge_action_fatigue_recovery()

			if not add_money(-lounge_money_cost):
				result["reason"] = "资金不足\n需要：%d" % lounge_money_cost
				return result

			if not consume_action_point(1):
				add_money(lounge_money_cost)
				result["reason"] = "行动点不足"
				return result

			add_cohesion(lounge_cohesion_gain)

			for member_id in members.keys():
				modify_member_stat(member_id, "fatigue", -lounge_fatigue_recovery)

			result["success"] = true
			result["changes"] = {
				"money": -lounge_money_cost,
				"cohesion": lounge_cohesion_gain,
				"fatigue_recovery": lounge_fatigue_recovery
			}

			print("设施互动执行成功：休息室 -> 团队休整，资金", -lounge_money_cost, " 凝聚力+", lounge_cohesion_gain, " 全员疲劳-", lounge_fatigue_recovery)
			return result

		_:
			result["reason"] = "该设施互动尚未开放"
			return result


# ===================== 酒吧互动数值接口 =====================

# 获取酒吧互动：凝聚力消耗
func get_bar_action_cohesion_cost() -> int:
	return 2

# 获取酒吧互动：创造力消耗
func get_bar_action_creativity_cost() -> int:
	return 1

# 获取酒吧互动：资金收益
func get_bar_action_money_gain() -> int:
	var level = clamp(get_facility_level("bar"), 1, 5)

	match level:
		1:
			return 250
		2:
			return 400
		3:
			return 600
		4:
			return 850
		5:
			return 1200

	return 250


# ===================== 舞台互动数值接口 =====================

# 获取舞台互动：创造力消耗
func get_stage_action_creativity_cost() -> int:
	return 5

# 获取舞台互动：凝聚力消耗
func get_stage_action_cohesion_cost() -> int:
	return 1

# 获取舞台互动：资金收益
func get_stage_action_money_gain() -> int:
	var level = clamp(get_facility_level("stage"), 1, 5)

	match level:
		1:
			return 200
		2:
			return 350
		3:
			return 550
		4:
			return 800
		5:
			return 1100

	return 200

# 获取舞台互动：声誉收益
func get_stage_action_reputation_gain() -> int:
	var level = clamp(get_facility_level("stage"), 1, 5)

	match level:
		1:
			return 2
		2:
			return 3
		3:
			return 5
		4:
			return 7
		5:
			return 10

	return 2


# ===================== 排练室互动数值接口 =====================

# 获取排练室互动：资金消耗
func get_rehearsal_action_money_cost() -> int:
	var level = clamp(get_facility_level("rehearsal"), 1, 5)

	match level:
		1:
			return 120
		2:
			return 180
		3:
			return 260
		4:
			return 360
		5:
			return 500

	return 120

# 获取排练室互动：创造力收益
func get_rehearsal_action_creativity_gain() -> int:
	var level = clamp(get_facility_level("rehearsal"), 1, 5)

	match level:
		1:
			return 4
		2:
			return 7
		3:
			return 11
		4:
			return 16
		5:
			return 22

	return 4


# ===================== 休息室互动数值接口 =====================

# 获取休息室互动：资金消耗
func get_lounge_action_money_cost() -> int:
	var level = clamp(get_facility_level("lounge"), 1, 5)

	match level:
		1:
			return 100
		2:
			return 150
		3:
			return 220
		4:
			return 320
		5:
			return 450

	return 100

# 获取休息室互动：凝聚力收益
func get_lounge_action_cohesion_gain() -> int:
	var level = clamp(get_facility_level("lounge"), 1, 5)

	match level:
		1:
			return 3
		2:
			return 5
		3:
			return 8
		4:
			return 11
		5:
			return 15

	return 3

# 获取休息室互动：全员疲劳恢复
func get_lounge_action_fatigue_recovery() -> int:
	var level = clamp(get_facility_level("lounge"), 1, 5)

	match level:
		1:
			return 1
		2:
			return 2
		3:
			return 3
		4:
			return 5
		5:
			return 7

	return 1

# ===================== 设施效果调试接口 =====================

# 打印当前所有设施效果，方便调试
func debug_print_facility_effects():
	print("===== 当前设施效果调试信息 =====")
	print("酒吧等级：", get_facility_level("bar"), " -> 每周收入：", get_bar_base_income())
	print("舞台等级：", get_facility_level("stage"), " -> 声誉倍率：", get_stage_reputation_multiplier())
	print("排练室等级：", get_facility_level("rehearsal"), " -> 创造力减免：", get_rehearsal_creativity_discount())
	print("休息室等级：", get_facility_level("lounge"), " -> 疲劳恢复：", get_lounge_fatigue_recovery(), " / 凝聚力恢复：", get_lounge_cohesion_bonus())
	print("============================")

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

# ===================== 设施维修状态接口 =====================

# 获取设施是否处于升级/维修中
func is_facility_upgrading(facility_type: String) -> bool:
	return facility_upgrading.get(facility_type, false)

# 设置设施升级/维修状态
func set_facility_upgrading(facility_type: String, value: bool) -> void:
	facility_upgrading[facility_type] = value
	print("设施维修状态更新：", facility_type, " -> ", value)

# ===================== 设施待生效等级接口 =====================

# 获取设施待生效等级
func get_facility_pending_level(facility_type: String) -> int:
	if facility_pending_levels.has(facility_type):
		return int(facility_pending_levels[facility_type])
	return 0

# 设置设施待生效等级
func set_facility_pending_level(facility_type: String, level: int):
	facility_pending_levels[facility_type] = level
	print("设施待生效等级更新：", facility_type, " -> ", level)

# 在下一周开始时应用所有待生效升级
func apply_pending_facility_upgrades():
	for facility_type in facility_pending_levels.keys():
		var pending_level = int(facility_pending_levels[facility_type])
		if pending_level > 0:
			# 1. 正式写入设施等级
			set_facility_level(facility_type, pending_level)

			# 2. 在设施正式生效时，应用对应方向值加成
			# 只对副设施生效，具体逻辑由 FacilityManager 内部控制
			if FacilityManager and FacilityManager.has_method("apply_facility_weight_gain_on_activation"):
				FacilityManager.apply_facility_weight_gain_on_activation(facility_type, pending_level)

			# 3. 清除待生效状态与维修状态
			set_facility_pending_level(facility_type, 0)
			set_facility_upgrading(facility_type, false)

			print("设施升级正式生效：", facility_type, " -> ", pending_level)

# ===================== 人物系统接口 =====================

var character_data: Node = null

func _init_character_system():
	character_data = load("res://project/data/members/MemberData.gd").new()
	add_child(character_data)

func get_character(char_id: String) -> Dictionary:
	if character_data:
		return character_data.get_character(char_id)
	return {}

func get_all_characters() -> Array:
	if character_data:
		var list = []
		for char_id in character_data.characters:
			list.append(character_data.characters[char_id])
		return list
	return []

func add_relationship(char_id: String, delta: int):
	if character_data:
		var new_rel = character_data.add_relationship(char_id, delta)
		# 发射信号更新UI
		EventBus.relationship_changed.emit(char_id, new_rel)
		return new_rel
	return 0

func get_relationship(char_id: String) -> int:
	if character_data and character_data.characters.has(char_id):
		return character_data.characters[char_id]["relationship"]
	return 0

func get_character_stage(char_id: String) -> int:
	if character_data and character_data.characters.has(char_id):
		return character_data.characters[char_id].get("current_stage", 1)
	return 1
