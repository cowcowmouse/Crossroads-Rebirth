extends Node

@onready var signal_bus = SignalBus

var core_resources: Dictionary = {}

func init_new_game():
    core_resources = {
        "money": {"value": 5000, "min": 0, "max": 999999},
        "reputation": {"value": 20, "min": 0, "max": 100},
        "cohesion": {"value": 50, "min": 0, "max": 100},
        "creativity": {"value": 30, "min": 0, "max": 100},
        "memory_recovery": {"value": 0, "min": 0, "max": 100}
    }

func modify_core_resource(resource_name: String, delta: int) -> bool:
    if not core_resources.has(resource_name):
        print("错误：不存在的资源" + resource_name)
        return false
    
    var res_data = core_resources[resource_name]
    var new_value = clamp(res_data.value + delta, res_data.min, res_data.max)
    var actual_delta = new_value - res_data.value
    
    res_data.value = new_value
    signal_bus.core_resource_changed.emit(resource_name, new_value, actual_delta)
    return true

func get_core_resource_value(resource_name: String) -> int:
    return core_resources[resource_name].value if core_resources.has(resource_name) else -1