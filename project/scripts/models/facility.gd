# 设施数据模型，定义酒吧设施的结构与属性
extends Resource

class_name Facility

# 基础信息
@export var facility_id: String = ""
@export var name: String = ""
@export var display_name: String = ""

# 等级属性
@export var current_level: int = 1
@export var max_level: int = 5
@export var base_upgrade_cost: int = 2000
@export var cost_multiplier: float = 1.5 # 每级成本递增倍率

# 增益属性
@export var income_bonus: float = 0.0 # 收入加成
@export var reputation_bonus: float = 0.0 # 声誉加成
@export var cohesion_bonus: float = 0.0 # 凝聚力加成
@export var practice_efficiency_bonus: float = 0.0 # 练习效率加成
@export var fatigue_reduction: float = 0.0 # 疲劳度降低

# 获取当前等级的升级成本
func get_upgrade_cost() -> int:
    if current_level >= max_level:
        return 0
    return int(base_upgrade_cost * pow(cost_multiplier, current_level - 1))

# 升级设施，返回是否成功
func upgrade() -> bool:
    if current_level >= max_level:
        return false
    current_level += 1
    return true

# 检查是否可升级
func can_upgrade() -> bool:
    return current_level < max_level
