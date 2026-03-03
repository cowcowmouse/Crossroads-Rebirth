extends Node
@onready var signal_bus = SignalBus

# 核心资源数据结构，从配置文件加载
var core_resources: Dictionary = {}
# 成员/设施/权重数据
var members: Dictionary = {}
var facilities: Dictionary = {}
var ai_weights: Dictionary = {"art": 0, "business": 0, "human": 0}

# 初始化新游戏
func init_new_game():
    var config = load("res://configs/balance/core_resource_balance.tres")
    # 初始化四类核心资源（严格对齐文档）
    core_resources = {
        "money": {"value": config.initial_money, "min": 0, "max": 999999},
        "reputation": {"value": config.initial_reputation, "min": 0, "max": 100},
        "cohesion": {"value": config.initial_cohesion, "min": 0, "max": 100},
        "creativity": {"value": config.initial_creativity, "min": 0, "max": 100}
    }
    _init_facilities()
    _init_members()
    ai_weights = {"art": 0, "business": 0, "human": 0}

# 通用资源修改接口，所有资源修改必须走这里
func modify_core_resource(resource_name: String, delta: int) -> bool:
    if not core_resources.has(resource_name):
        print(f"错误：不存在的资源{resource_name}")
        return false
    var res_data = core_resources[resource_name]
    var new_value = clamp(res_data.value + delta, res_data.min, res_data.max)
    var actual_delta = new_value - res_data.value
    res_data.value = new_value
    # 通知UI刷新
    signal_bus.core_resource_changed.emit(resource_name, new_value, actual_delta)
    # 触发边界事件（如凝聚力低于30警告）
    _check_resource_boundary_event(resource_name, new_value)
    return true

# 获取资源当前值
func get_core_resource_value(resource_name: String) -> int:
    return core_resources[resource_name].value if core_resources.has(resource_name) else -1

# AI权重修改接口
func modify_ai_weight(weight_name: String, delta: int):
    if ai_weights.has(weight_name):
        ai_weights[weight_name] += delta