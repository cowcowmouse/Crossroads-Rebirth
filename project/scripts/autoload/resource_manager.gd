# 核心资源管理器，所有资源修改必须走这里，严格对齐设计文档数值
extends Node

@onready var signal_bus = SignalBus
@onready var constants: Node = Constants

# 只声明变量，不在顶层初始化（关键修复！）
var core_resources: Dictionary = {}
var ai_weights: Dictionary = {}  # 空字典声明，不赋值
var members: Dictionary = {}

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
	
	# AI权重初始化（移到这里，此时 constants 已就绪）
	ai_weights = {
		constants.WEIGHT_ART: 0,
		constants.WEIGHT_BUSINESS: 0,
		constants.WEIGHT_HUMAN: 0
	}
	
	# 初始化初始成员数据
	_init_default_members()
	
	print("核心资源初始化完成")

# 初始化默认成员
func _init_default_members():
	members = {
		constants.MEMBER_RIO: {
			"name": "里奥",
			"role": "鼓手",
			"soberness": 80,
			"unlocked": true,
			"relationship_progress": 0,
			"weekly_chat_count": 0,
			"morale": 60,
			"fatigue": 30,
			"health": 80
		},
		constants.MEMBER_KIRA: {
			"name": "凯拉",
			"role": "主唱",
			"popularity": 50,
			"unlocked": true,
			"relationship_progress": 0,
			"weekly_chat_count": 0,
			"morale": 60,
			"fatigue": 30,
			"health": 80
		},
		constants.MEMBER_MEI: {
			"name": "梅",
			"role": "贝斯手",
			"unlocked": true,
			"relationship_progress": 0,
			"weekly_chat_count": 0,
			"morale": 60,
			"fatigue": 30,
			"health": 80
		},
		constants.MEMBER_old_NAIL: {
			"name": "老钉子",
			"role": "酒吧守护者",
			"unlocked": true,
			"relationship_progress": 1,
			"weekly_chat_count": 0,
			"morale": 100,
			"fatigue": 0,
			"health": 100
		}
	}

# ===================== 核心资源通用接口（所有修改必须走这里）=====================
# 修改核心资源，返回是否成功
func modify_core_resource(resource_name: String, delta: int) -> bool:
	if not core_resources.has(resource_name):
		print("错误：不存在的资源", resource_name)
		return false
	var res_data = core_resources[resource_name]
	var new_value = clamp(res_data.value + delta, res_data.min, res_data.max)
	var actual_delta = new_value - res_data.value

	if actual_delta == 0:
		return false

	# 更新数值
	res_data.value = new_value
	# 发射信号通知UI刷新
	signal_bus.core_resource_changed.emit(resource_name, new_value, actual_delta)
	# 检查资源边界事件
	_check_resource_boundary_event(resource_name, new_value)

	print("资源变动：", resource_name, " ", actual_delta, "+d，当前值：", new_value)
	return true

# 获取资源当前值
func get_resource_value(resource_name: String) -> int:
	if core_resources.has(resource_name):
		return core_resources[resource_name].value
	return -1

# ===================== AI权重接口 =====================
func modify_ai_weight(weight_name: String, delta: int):
	if ai_weights.has(weight_name):
		ai_weights[weight_name] += delta
		print("权重变动：", weight_name, " ", delta, "+d，当前值：", ai_weights[weight_name])

# ===================== 成员数据接口 =====================
func get_member_data(member_id: String) -> Dictionary:
	if members.has(member_id):
		return members[member_id]
	return {}

# ===================== 内部边界检查 =====================
func _check_resource_boundary_event(resource_name: String, new_value: int):
	match resource_name:
		constants.RES_COHESION:
			if new_value < 30:
				print("警告：凝聚力低于30，进入危险状态！")
		constants.RES_MONEY:
			if new_value <= 0:
				print("警告：资金耗尽，触发破产判定！")
		constants.RES_CREATIVITY:
			if new_value < 10:
				print("警告：创造力过低，无法进行艺术操作！")
