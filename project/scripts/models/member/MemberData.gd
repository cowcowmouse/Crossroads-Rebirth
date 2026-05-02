# MemberData.gd
@tool
class_name MemberData
extends Resource

# ==================== 基础信息 ====================
@export var id: String = "rio"
@export var name: String = "里奥"
@export var role: String = "鼓手"
@export var portrait: Texture2D               # 用于入队UI、对话立绘
@export var idle_animation: SpriteFrames      # 待机逐帧动画

# ==================== 状态 ====================
@export var unlocked: bool = false
@export var is_recruited: bool = false
@export var relationship: int = 0             # 0~100，决定阶段

@export var current_stage: int = 1            # 1,2,3 阶段

# ==================== 属性 ====================
@export var morale: int = 60
@export var fatigue: int = 30
@export var health: int = 80
@export var skill: int = 50
@export var charm: int = 50

# 特殊属性（可扩展）
@export var special_stats: Dictionary = {
	"soberness": 70,
	"popularity": 40
}

# ==================== 互动与招募 ====================
@export var interaction_count_this_week: int = 0
@export var join_cost: int = 5000                     # 招募所需资金
@export var join_effect_text: String = "提升全队声誉收益 +15%"

# 特殊能力（入队后生效）
@export var special_ability: String = ""              # 描述
@export var special_ability_id: String = ""           # 用于代码识别，如 "kira_reputation_boost"

# ==================== 方法 ====================

# 获取当前关系阶段 (1,2,3)
func get_relationship_stage() -> int:
	if relationship >= 60:
		return 3
	elif relationship >= 30:
		return 2
	else:
		return 1

# 增加关系值（每周第一次对话调用）
func add_relationship(delta: int = 1) -> void:
	var old_stage = get_relationship_stage()
	relationship = clamp(relationship + delta, 0, 100)
	var new_stage = get_relationship_stage()
	
	if new_stage > old_stage:
		print(name, " 关系提升至阶段 ", new_stage)
	
	# 保存修改
	ResourceSaver.save(self)

# 每周重置互动次数
func reset_weekly_interaction():
	interaction_count_this_week = 0

# 是否可以招募（阶段2及以上）
func can_recruit() -> bool:
	return get_relationship_stage() >= 2 and not is_recruited
