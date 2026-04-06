extends Node

# ==================== 游戏整体配置 ====================

# 每周固定支出（租金+工资）
const WEEKLY_EXPENSE = 1500

# 阶段对应的支出倍率（前期减半）
const PHASE_EXPENSE_MULTIPLIER = {
	"early": 0.5,   # 前期支出减半，降低新手难度
	"mid": 1.0,     # 中期正常支出
	"late": 1.0     # 后期正常支出
}

# 阶段对应的周数范围
const PHASE_WEEKS = {
	"early": [1, 2, 3],
	"mid": [4, 5, 6, 7, 8, 9, 10, 11, 12],
	"late": [13, 14, 15, 16, 17, 18]
}

# ==================== 资源边界配置 ====================

const RESOURCE_BOUNDARIES = {
	"money": {
		"min": 0,
		"max": 999999,
		"initial": 5000,
		"warning": 0      # 资金为0时破产
	},
	"reputation": {
		"min": 0,
		"max": 100,
		"initial": 10,
		"thresholds": [30, 70],  # 30解锁区域级，70解锁全国级
		"warning": 0
	},
	"cohesion": {
		"min": 0,
		"max": 100,
		"initial": 60,
		"danger": 30,    # 低于30危险状态
		"warning": 30
	},
	"creativity": {
		"min": 0,
		"max": 100,
		"initial": 30,
		"warning": 10    # 低于10无法进行艺术操作
	},
	"memory": {
		"min": 0,
		"max": 100,
		"initial": 0,
		"threshold": 100  # 达到100解锁真结局
	}
}

# ==================== 行动点配置 ====================

const ACTION_POINTS = {
	"max_per_week": 3,      # 每周最大行动点
	"reset_on_new_week": true  # 每周重置
}

# ==================== 设施配置 ====================

# 设施类型常量
const FACILITY_TYPES = {
	"STAGE": "stage",           # 舞台
	"BAR": "bar",               # 酒吧
	"REHEARSAL": "rehearsal",   # 排练室
	"LOUNGE": "lounge"          # 休息室
}

# 设施升级成本（从1级升到下一级的成本，索引0为1级升2级）
const FACILITY_UPGRADE_COST = {
	"stage": [2000, 3000, 5000, 8000, 12000],
	"bar": [1800, 2800, 4500, 7000, 10000],
	"rehearsal": [2000, 3000, 5000, 8000, 12000],
	"lounge": [1800, 2800, 4500, 7000, 10000]
}

# 设施升级增益（每级增加的效果）
const FACILITY_EFFECTS = {
	"stage": {
		1: {"reputation_gain": 4, "fail_rate_reduce": 0.05, "high_rating_chance": 0.10},
		2: {"reputation_gain": 5, "fail_rate_reduce": 0.10, "high_rating_chance": 0.15},
		3: {"reputation_gain": 6, "fail_rate_reduce": 0.15, "high_rating_chance": 0.20},
		4: {"reputation_gain": 7, "fail_rate_reduce": 0.20, "high_rating_chance": 0.25},
		5: {"reputation_gain": 8, "fail_rate_reduce": 0.25, "high_rating_chance": 0.30}
	},
	"bar": {
		1: {"weekly_income": 1500, "extra_income_chance": 0.10, "extra_income_amount": 200},
		2: {"weekly_income": 2200, "extra_income_chance": 0.15, "extra_income_amount": 300},
		3: {"weekly_income": 3000, "extra_income_chance": 0.20, "extra_income_amount": 400},
		4: {"weekly_income": 4000, "extra_income_chance": 0.25, "extra_income_amount": 500},
		5: {"weekly_income": 5200, "extra_income_chance": 0.30, "extra_income_amount": 600}
	},
	"rehearsal": {
		1: {"creativity_cost_reduce": 2, "creation_progress_bonus": 0.05, "skill_gain_bonus": 0.05},
		2: {"creativity_cost_reduce": 4, "creation_progress_bonus": 0.10, "skill_gain_bonus": 0.10},
		3: {"creativity_cost_reduce": 6, "creation_progress_bonus": 0.15, "skill_gain_bonus": 0.15},
		4: {"creativity_cost_reduce": 8, "creation_progress_bonus": 0.20, "skill_gain_bonus": 0.20},
		5: {"creativity_cost_reduce": 10, "creation_progress_bonus": 0.25, "skill_gain_bonus": 0.25}
	},
	"lounge": {
		1: {"fatigue_recovery": 3, "morale_decay_reduce": 1, "cohesion_stable": 1},
		2: {"fatigue_recovery": 5, "morale_decay_reduce": 2, "cohesion_stable": 2},
		3: {"fatigue_recovery": 7, "morale_decay_reduce": 3, "cohesion_stable": 3},
		4: {"fatigue_recovery": 9, "morale_decay_reduce": 4, "cohesion_stable": 4},
		5: {"fatigue_recovery": 12, "morale_decay_reduce": 5, "cohesion_stable": 5}
	}
}

# 设施升级前置条件
const FACILITY_PREREQUISITES = {
	# 舞台：需要排练室等级条件
	"stage": {3: {"rehearsal": 2}, 4: {"rehearsal": 3}, 5: {"rehearsal": 4}},
	# 酒吧：需要舞台等级条件
	"bar": {3: {"stage": 2}, 4: {"stage": 3}, 5: {"stage": 4}},
	# 排练室：需要休息室等级条件
	"rehearsal": {3: {"lounge": 2}, 4: {"lounge": 3}, 5: {"lounge": 4}},
	# 休息室：需要酒吧等级条件
	"lounge": {3: {"bar": 2}, 4: {"bar": 3}, 5: {"bar": 4}}
}

# ==================== 成员自然变化配置 ====================

# 每周自然变化（不管理时的变化）
const MEMBER_NATURAL_CHANGE = {
	"fatigue_increase": 5,           # 每周疲劳增加
	"morale_decrease": 2,            # 每周士气下降
	"fatigue_high_threshold": 80,    # 疲劳过高阈值
	"morale_decrease_high": 5        # 疲劳过高时额外士气下降
}

# ==================== 权重配置 ====================

# 权重增减规则
const WEIGHT_CHANGES = {
	"facility_upgrade": 1,   # 设施升级权重+1
	"member_operation": 1,   # 成员管理权重+1
	"creation_operation": 1, # 创作/康复权重+1
	"event_choice": 2        # 事件抉择权重+2
}

# 权重倾向判定阈值
const WEIGHT_TENDENCY = {
	"art_threshold": 10,      # 艺术权重>=10倾向艺术结局
	"business_threshold": 10, # 商业权重>=10倾向商业结局
	"human_threshold": 10     # 人情权重>=10倾向羁绊结局
}

# ==================== 阶段解锁内容 ====================

const PHASE_UNLOCKS = {
	"early": {
		"facility_max_level": 2,      # 设施最高2级
		"max_members": 3,              # 最多3名成员
		"event_pool": "early",         # 前期事件池
		"show_weight": true            # 显示权重数值
	},
	"mid": {
		"facility_max_level": 4,
		"max_members": 6,
		"event_pool": "mid",
		"show_weight": false           # 隐藏权重数值
	},
	"late": {
		"facility_max_level": 5,
		"max_members": 7,
		"event_pool": "late",
		"show_weight": "tendency"      # 仅显示倾向
	}
}

# ==================== 游戏结局配置 ====================

const ENDINGS = {
	"art_ending": {
		"name": "艺术之路",
		"condition": {"art_weight": 10, "creativity": 80},
		"description": "乐队成为传奇艺术家，作品流传后世"
	},
	"business_ending": {
		"name": "商业帝国",
		"condition": {"business_weight": 10, "money": 100000},
		"description": "酒吧成为全国连锁品牌，乐队商业价值登顶"
	},
	"bond_ending": {
		"name": "羁绊永恒",
		"condition": {"human_weight": 10, "cohesion": 90},
		"description": "成员成为一生挚友，酒吧成为音乐人的精神家园"
	},
	"true_ending": {
		"name": "记忆重现",
		"condition": {"memory": 100, "cohesion": 80, "art_weight": 8},
		"description": "主角完全康复，乐队重登巅峰舞台"
	},
	"bankrupt_ending": {
		"name": "破产落幕",
		"condition": {"money": 0},
		"description": "酒吧倒闭，乐队解散"
	},
	"broken_ending": {
		"name": "分崩离析",
		"condition": {"cohesion": 0},
		"description": "成员矛盾激化，乐队解散"
	}
}

# ==================== 辅助方法 ====================

# 根据周数获取阶段
static func get_phase_by_week(week: int) -> String:
	if week <= 3:
		return "early"
	elif week <= 12:
		return "mid"
	else:
		return "late"

# 获取当前阶段的支出
static func get_weekly_expense(phase: String) -> int:
	return WEEKLY_EXPENSE * PHASE_EXPENSE_MULTIPLIER[phase]

# 获取设施升级成本
static func get_upgrade_cost(facility_type: String, current_level: int) -> int:
	var costs = FACILITY_UPGRADE_COST[facility_type]
	if current_level <= costs.size():
		return costs[current_level - 1]
	return 999999  # 已满级

# 检查升级前置条件
static func check_prerequisite(facility_type: String, target_level: int, current_levels: Dictionary) -> bool:
	if FACILITY_PREREQUISITES.has(facility_type):
		var prereqs = FACILITY_PREREQUISITES[facility_type]
		if prereqs.has(target_level):
			for req_type: String in prereqs[target_level]:
				var req_level: int = prereqs[target_level][req_type]
				if current_levels.get(req_type, 0) < req_level:
					return false
	return true
