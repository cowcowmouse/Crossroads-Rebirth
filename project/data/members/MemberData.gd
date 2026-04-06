extends Node

# ==================== 角色ID常量 ====================
const CHAR_RIO = "rio"
const CHAR_KIRA = "kira"
const CHAR_MEI = "mei"
const CHAR_FINN = "finn"
const CHAR_SEBASTIAN = "sebastian"
const CHAR_LILY = "lily"
const CHAR_AYA = "aya"
const CHAR_DUANE = "duane"
const CHAR_OLD_NAIL = "old_nail"

# ==================== 角色完整数据 ====================
var characters = {
	CHAR_RIO: {
		"id": "rio",
		"name": "里奥",
		"role": "鼓手",
		"avatar": "res://assets/characters/rio.png",        # 完成图片后修改
		"personality": "酒精心魔",
		"unlocked": true,
		
		# 基础状态
		"morale": 60,
		"fatigue": 30,
		"health": 75,
		"skill": 70,
		"charm": 40,
		
		# 特殊属性
		"alcohol_level": 60,        # 酒精度（越高状态越差）
		"performance_anxiety": 70,   # 演出焦虑度
		
		# 互动进度
		"relationship": 0,           # 关系度 0-100
		"interaction_count": 0,      # 总互动次数
		
		# 事件标记
		"events_triggered": [],
		"current_stage": 1,          # 当前剧情阶段 1/2/3
		
		# 剧情解锁条件
		"stage2_condition": {"relationship": 30},
		"stage3_condition": {"relationship": 60},
		
		# 资源关联
		"resource_effects": {
			"cohesion": 0.5,      # 凝聚力影响系数
			"creativity": 0.3,    # 创造力影响系数
			"alcohol": -2.0       # 每周酒精自然增加
		}
	},
	
	CHAR_KIRA: {
		"id": "kira",
		"name": "凯拉",
		"role": "主唱",
		"avatar": "res://assets/characters/kira.png",        # 完成图片后修改
		"personality": "流量vs真实",
		"unlocked": true,
		
		"morale": 65,
		"fatigue": 35,
		"health": 85,
		"skill": 75,
		"charm": 85,
		
		# 特殊属性
		"authenticity": 30,          # 真实度（低=伪装，高=做自己）
		"popularity_pressure": 80,   # 人气压力
		
		"relationship": 0,
		"interaction_count": 0,
		"events_triggered": [],
		"current_stage": 1,
		"stage2_condition": {"relationship": 30},
		"stage3_condition": {"relationship": 60},
		
		"resource_effects": {
			"cohesion": 0.4,
			"reputation": 0.6,    # 声誉影响系数
			"popularity": -1.5    # 每周人气压力自然增加
		}
	},
	
	CHAR_MEI: {
		"id": "mei",
		"name": "梅",
		"role": "贝斯手",
		"avatar": "res://assets/characters/mei.png",        # 完成图片后修改
		"personality": "团队粘合剂",
		"unlocked": true,
		
		"morale": 75,
		"fatigue": 25,
		"health": 90,
		"skill": 65,
		"charm": 70,
		
		# 特殊属性
		"mediation_skill": 80,       # 调解能力（解决矛盾成功率）
		
		"relationship": 0,
		"interaction_count": 0,
		"events_triggered": [],
		"current_stage": 1,
		"stage2_condition": {"relationship": 30},
		"stage3_condition": {"relationship": 60},
		
		"resource_effects": {
			"cohesion": 0.8,         # 高凝聚力影响
			"stability": 0.5
		}
	},
	
	CHAR_FINN: {
		"id": "finn",
		"name": "芬恩",
		"role": "吉他手",
		"avatar": "res://assets/characters/finn.png",        # 完成图片后修改
		"personality": "旧友宿敌",
		"unlocked": false,  # 需要事件解锁
		
		"morale": 55,
		"fatigue": 40,
		"health": 80,
		"skill": 95,
		"charm": 35,
		
		# 特殊属性
		"bitterness": 70,            # 怨恨度
		"teaching_willingness": 20,  # 教导意愿
		
		"relationship": 0,
		"interaction_count": 0,
		"events_triggered": [],
		"current_stage": 1,
		"stage2_condition": {"relationship": 30},
		"stage3_condition": {"relationship": 60, "event": "car_accident_reveal"},
		
		"resource_effects": {
			"cohesion": -0.3,         # 负面影响凝聚力
			"skill_boost": 1.2        # 技术增益
		},
		
		"unlock_condition": {"reputation": 50, "cohesion": 40}
	},
	
	CHAR_SEBASTIAN: {
		"id": "sebastian",
		"name": "塞巴斯蒂安",
		"role": "投资人",
		"avatar": "res://assets/characters/sebastian.png",        # 完成图片后修改
		"personality": "资本代理人",
		"unlocked": false,
		
		"morale": 50,
		"fatigue": 20,
		"health": 95,
		"skill": 60,
		"charm": 65,
		
		# 特殊属性
		"capital_purity": 90,        # 资本纯度（越高越冷血）
		"investment_amount": 0,      # 已投资金额
		
		"relationship": 0,
		"interaction_count": 0,
		"events_triggered": [],
		"current_stage": 1,
		"stage2_condition": {"relationship": 30, "investment": 10000},
		"stage3_condition": {"relationship": 60, "event": "true_partner"},
		
		"resource_effects": {
			"money": 2.0,             # 资金增益
			"cohesion": -0.5          # 凝聚力惩罚
		},
		
		"unlock_condition": {"reputation": 60, "money": 20000}
	},
	
	CHAR_LILY: {
		"id": "lily",
		"name": "莉莉",
		"role": "小提琴手",
		"avatar": "res://assets/characters/lily.png",        # 完成图片后修改
		"personality": "古典叛逃",
		"unlocked": false,
		
		"morale": 60,
		"fatigue": 30,
		"health": 85,
		"skill": 85,
		"charm": 55,
		
		# 特殊属性
		"perfectionism": 85,         # 完美主义（越高越怕错）
		"improvisation_freedom": 10, # 即兴自由度
		
		"relationship": 0,
		"interaction_count": 0,
		"events_triggered": [],
		"current_stage": 1,
		"stage2_condition": {"relationship": 35},
		"stage3_condition": {"relationship": 65},
		
		"resource_effects": {
			"creativity": 0.4,
			"cohesion": 0.2
		},
		
		"unlock_condition": {"reputation": 40, "creativity": 50}
	},
	
	CHAR_AYA: {
		"id": "aya",
		"name": "阿雅",
		"role": "音乐治疗师",
		"avatar": "res://assets/characters/aya.png",        # 完成图片后修改
		"personality": "音乐治疗",
		"unlocked": false,
		
		"morale": 80,
		"fatigue": 20,
		"health": 90,
		"skill": 70,
		"charm": 75,
		
		# 特殊属性
		"community_service": 50,     # 社区服务值
		"healing_power": 60,         # 治愈能力
		
		"relationship": 0,
		"interaction_count": 0,
		"events_triggered": [],
		"current_stage": 1,
		"stage2_condition": {"relationship": 30},
		"stage3_condition": {"relationship": 60},
		
		"resource_effects": {
			"cohesion": 0.7,
			"morale_boost": 5.0       # 每周士气恢复
		},
		
		"unlock_condition": {"reputation": 35, "event": "community_event"}
	},
	
	CHAR_DUANE: {
		"id": "duane",
		"name": "杜安",
		"role": "电子鼓手",
		"avatar": "res://assets/characters/duane.png",        # 完成图片后修改
		"personality": "数据与感性",
		"unlocked": false,
		
		"morale": 55,
		"fatigue": 25,
		"health": 90,
		"skill": 90,
		"charm": 30,
		
		# 特殊属性
		"precision_rate": 95,        # 精确度
		"chaos_tolerance": 20,       # 混乱容忍度
		
		"relationship": 0,
		"interaction_count": 0,
		"events_triggered": [],
		"current_stage": 1,
		"stage2_condition": {"relationship": 30},
		"stage3_condition": {"relationship": 60},
		
		"resource_effects": {
			"precision": 1.1,
			"creativity": -0.2
		},
		
		"unlock_condition": {"reputation": 45, "facility_level": {"rehearsal": 3}}
	},
	
	CHAR_OLD_NAIL: {
		"id": "old_nail",
		"name": "老钉子",
		"role": "酒吧守护者",
		"avatar": "res://assets/characters/old_nail.png",        # 完成图片后修改
		"personality": "守护者",
		"unlocked": true,
		
		"morale": 100,
		"fatigue": 10,
		"health": 85,
		"skill": 80,
		"charm": 70,
		
		# 特殊属性
		"protection_pledge": 100,    # 守护承诺
		"hidden_knowledge": 0,       # 隐藏真相进度
		
		"relationship": 1,
		"interaction_count": 0,
		"events_triggered": [],
		"current_stage": 1,
		"stage2_condition": {"relationship": 30},
		"stage3_condition": {"relationship": 60, "memory": 50},
		
		"resource_effects": {
			"stability": 0.9,
			"hidden_bonus": 1.0
		}
	}
}

# ===================== 获取角色数据 =====================
func get_character(char_id: String) -> Dictionary:
	if characters.has(char_id):
		return characters[char_id].duplicate(true)
	return {}

func get_unlocked_characters() -> Array:
	var unlocked = []
	for char_id in characters:
		if characters[char_id].get("unlocked", false):
			unlocked.append(char_id)
	return unlocked

# ===================== 角色关系操作 =====================
func add_relationship(char_id: String, delta: int) -> int:
	if not characters.has(char_id):
		return 0
	
	var old = characters[char_id]["relationship"]
	var new_val = clamp(old + delta, 0, 100)
	characters[char_id]["relationship"] = new_val
	
	# 检查阶段变化
	_check_stage_change(char_id)
	
	return new_val

func _check_stage_change(char_id: String):
	var char = characters[char_id]
	var rel = char["relationship"]
	var current_stage = char.get("current_stage", 1)
	var new_stage = current_stage
	
	if rel >= 60 and current_stage < 3:
		new_stage = 3
	elif rel >= 30 and current_stage < 2:
		new_stage = 2
	
	if new_stage != current_stage:
		char["current_stage"] = new_stage
		print(char["name"], " 进入剧情阶段 ", new_stage)

# ===================== 特殊属性操作 =====================
func modify_special_stat(char_id: String, stat: String, delta: int) -> int:
	if not characters.has(char_id):
		return 0
	
	var char = characters[char_id]
	if not char.has(stat):
		return 0
	
	var old = char[stat]
	var new_val = clamp(old + delta, 0, 100)
	char[stat] = new_val
	
	print(char["name"], " 的 ", stat, " 变化: ", old, " -> ", new_val)
	return new_val

# ===================== 每周自然变化 =====================
func apply_weekly_change(char_id: String):
	if not characters.has(char_id):
		return
	
	var char = characters[char_id]
	var effects = char.get("resource_effects", {})
	
	# 应用自然变化
	for resource in effects:
		var delta = effects[resource]
		match resource:
			"cohesion":
				ResourceManager.add_cohesion(delta)
			"creativity":
				ResourceManager.add_creativity(delta)
			"reputation":
				ResourceManager.add_reputation(delta)
			"alcohol":
				modify_special_stat(char_id, "alcohol_level", delta)
			"popularity":
				modify_special_stat(char_id, "popularity_pressure", delta)
			"morale_boost":
				modify_special_stat(char_id, "morale", delta)
