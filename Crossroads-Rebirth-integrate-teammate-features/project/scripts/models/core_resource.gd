# 核心资源数据模型，定义所有全局资源的结构
extends Resource

class_name CoreResource

# 资源基础属性
@export var name: String = ""
@export var value: int = 0
@export var min_value: int = 0
@export var max_value: int = 999999
@export var display_name: String = ""

# 修改资源值，自动限制边界，返回实际变动值
func modify_value(delta: int) -> int:
	var old_value := value
	value = clamp(value + delta, min_value, max_value)
	return value - old_value

# 获取当前值
func get_value() -> int:
	return value
