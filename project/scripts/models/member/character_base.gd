extends Resource
class_name CharacterBase

# ==================== 基础信息 ====================

@export var id: String = ""
@export var name: String = ""
@export var role: String = ""
@export var avatar: Texture2D
@export var personality: String = ""
@export var unlocked: bool = true
@export var favor: int = 0
@export var portrait: String = ""   
@export var weekly_talk_count: int = 0  
# ==================== 基础状态 ====================
@export var morale: int = 60      # 心情
@export var fatigue: int = 30     # 疲劳
@export var health: int = 80      # 健康
@export var skill: int = 50       # 技巧
@export var charm: int = 50       # 魅力

# ==================== 特殊属性（每个角色不同）====================
@export var special_stats: Dictionary = {}

# ==================== 互动进度 ====================
@export var relationship: int = 0           # 关系度 0-100
@export var interaction_count: int = 0      # 总互动次数
@export var current_stage: int = 1          # 当前剧情阶段 1/2/3

# ==================== 解锁条件 ====================
@export var stage2_condition: Dictionary = {"relationship": 30}
@export var stage3_condition: Dictionary = {"relationship": 60}
@export var unlock_condition: Dictionary = {}

# ==================== 入队收益 ====================
@export var join_income: Dictionary = {
	"money": 0,
	"cohesion": 5,
	"creativity": 0,
	"reputation": 0
}
@export var join_effect_text: String = "入队后凝聚力+5"

# ==================== 特殊功能 ====================
@export var special_ability: Dictionary = {
	"name": "鼓励",
	"description": "消耗50资金，提升心情10点",
	"icon_path": "",
	"effect": {
		"target_stat": "morale",
		"delta": 10,
		"cost_money": 50,
		"cost_action": 1
	}
}

# ==================== 资源关联 ====================
@export var resource_effects: Dictionary = {}
@export var join_cost: int = 100
# ==================== 事件标记 ====================
@export var events_triggered: Array = []
