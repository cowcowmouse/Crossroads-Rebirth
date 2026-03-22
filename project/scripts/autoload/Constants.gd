extends Node

# ==================== 核心资源ID ====================

const RES_MONEY: String = "money"
const RES_REPUTATION: String = "reputation"
const RES_COHESION: String = "cohesion"
const RES_CREATIVITY: String = "creativity"
const RES_MEMORY: String = "memory"

# ==================== AI权重ID ====================

const WEIGHT_ART: String = "art"
const WEIGHT_BUSINESS: String = "business"
const WEIGHT_HUMAN: String = "human"

# ==================== 游戏阶段ID ====================

const PHASE_EARLY: String = "early"
const PHASE_MID: String = "mid"
const PHASE_LATE: String = "late"

# ==================== 设施类型ID ====================

const FACILITY_STAGE: String = "stage"
const FACILITY_BAR: String = "bar"
const FACILITY_REHEARSAL: String = "rehearsal"
const FACILITY_LOUNGE: String = "lounge"

# ==================== 成员ID ====================

const MEMBER_RIO: String = "rio"
const MEMBER_KIRA: String = "kira"
const MEMBER_MEI: String = "mei"
const MEMBER_old_NAIL: String = "old_nail"

# ==================== 成员属性ID ====================

const MEMBER_MORALE: String = "morale"
const MEMBER_FATIGUE: String = "fatigue"
const MEMBER_HEALTH: String = "health"
const MEMBER_SKILL: String = "skill"
const MEMBER_CHARM: String = "charm"
const MEMBER_SOBERNESS: String = "soberness"      # 里奥专属
const MEMBER_POPULARITY: String = "popularity"    # 凯拉专属
const MEMBER_RELATIONSHIP_PROGRESS: String = "relationship_progress"
const MEMBER_WEEKLY_CHAT_COUNT: String = "weekly_chat_count"

# ==================== 事件相关ID ====================

const EVENT_TYPE_WEEKLY: String = "weekly"      # 周中核心事件
const EVENT_TYPE_MEMBER: String = "member"      # 成员专属事件
const EVENT_TYPE_PROTAGONIST: String = "protagonist"  # 主角恢复事件

# ==================== 小游戏类型ID ====================

const MINIGAME_REHAB: String = "rehabilitation"   # 康复训练
const MINIGAME_PERFORM: String = "performance"    # 商演
const MINIGAME_CREATE: String = "create"          # 创作

# ==================== 难度等级ID ====================

const DIFFICULTY_EASY: String = "easy"
const DIFFICULTY_NORMAL: String = "normal"
const DIFFICULTY_HARD: String = "hard"

# ==================== UI相关ID ====================

const UI_TARGET_RESOURCES: String = "resources"
const UI_TARGET_MEMBERS: String = "members"
const UI_TARGET_FACILITIES: String = "facilities"

# ==================== 游戏结束原因 ====================

const GAME_OVER_BANKRUPT: String = "bankrupt"        # 资金耗尽
const GAME_OVER_BAND_BROKEN: String = "band_broken"  # 成员解散
const GAME_OVER_COHESION_DANGER: String = "cohesion_danger"  # 凝聚力危机

# ==================== 资源警告等级 ====================

const WARNING_DANGER: String = "danger"
const WARNING_CRITICAL: String = "critical"
const WARNING_LOW: String = "low"

# ==================== 辅助方法 ====================

# 获取所有成员ID列表
static func get_all_member_ids() -> Array:
	return [MEMBER_RIO, MEMBER_KIRA, MEMBER_MEI, MEMBER_old_NAIL]

# 获取所有设施类型列表
static func get_all_facility_types() -> Array:
	return [FACILITY_STAGE, FACILITY_BAR, FACILITY_REHEARSAL, FACILITY_LOUNGE]

# 获取所有资源类型列表
static func get_all_resource_types() -> Array:
	return [RES_MONEY, RES_REPUTATION, RES_COHESION, RES_CREATIVITY, RES_MEMORY]

# 获取所有权重类型列表
static func get_all_weight_types() -> Array:
	return [WEIGHT_ART, WEIGHT_BUSINESS, WEIGHT_HUMAN]