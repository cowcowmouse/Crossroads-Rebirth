@tool
extends EditorScript

func _run():
	var characters = [
		{
			"id": "rio", "name": "里奥", "role": "鼓手", "personality": "酒精心魔",
			"morale": 60, "fatigue": 30, "health": 75, "skill": 70, "charm": 40,
			"special_stats": {"alcohol_level": 60, "performance_anxiety": 70},
			"join_income": {"money": 0, "cohesion": 5, "creativity": 0, "reputation": 0},
			"join_effect_text": "入队后凝聚力+5",
			"special_ability": {
				"name": "戒酒鼓励",
				"description": "消耗80资金，降低酒精度，提升心情",
				"icon_path": "",
				"effect": {
					"target_stat": "alcohol_level", "delta": -10,
					"cost_money": 80, "cost_action": 1,
					"secondary_stat": "morale", "secondary_delta": 5
				}
			},
			"resource_effects": {"cohesion": 0.5, "creativity": 0.3},
			"stage2_condition": {"relationship": 30},
			"stage3_condition": {"relationship": 60},
			"unlocked": true
		},
		{
			"id": "kira", "name": "凯拉", "role": "主唱", "personality": "流量vs真实",
			"morale": 65, "fatigue": 35, "health": 85, "skill": 75, "charm": 85,
			"special_stats": {"authenticity": 30, "popularity_pressure": 80},
			"join_income": {"money": 500, "cohesion": 3, "creativity": 0, "reputation": 10},
			"join_effect_text": "入队后资金+500，声誉+10",
			"special_ability": {
				"name": "真实表达",
				"description": "消耗50资金，提升真实度，降低人气压力",
				"icon_path": "",
				"effect": {
					"target_stat": "authenticity", "delta": 5,
					"cost_money": 50, "cost_action": 1,
					"secondary_stat": "popularity_pressure", "secondary_delta": -5
				}
			},
			"resource_effects": {"cohesion": 0.4, "reputation": 0.6},
			"stage2_condition": {"relationship": 30},
			"stage3_condition": {"relationship": 60},
			"unlocked": true
		},
		{
			"id": "mei", "name": "梅", "role": "贝斯手", "personality": "团队粘合剂",
			"morale": 75, "fatigue": 25, "health": 90, "skill": 65, "charm": 70,
			"special_stats": {"mediation_skill": 80},
			"join_income": {"money": 0, "cohesion": 8, "creativity": 0, "reputation": 0},
			"join_effect_text": "入队后凝聚力+8",
			"special_ability": {
				"name": "调解矛盾",
				"description": "消耗1行动点，尝试调解队内矛盾",
				"icon_path": "",
				"effect": {
					"target_stat": "mediation_skill", "delta": 0,
					"cost_money": 0, "cost_action": 1,
					"special_effect": "resolve_conflict"
				}
			},
			"resource_effects": {"cohesion": 0.8},
			"stage2_condition": {"relationship": 30},
			"stage3_condition": {"relationship": 60},
			"unlocked": true
		},
		{
			"id": "finn", "name": "芬恩", "role": "吉他手", "personality": "旧友宿敌",
			"morale": 55, "fatigue": 40, "health": 80, "skill": 95, "charm": 35,
			"special_stats": {"bitterness": 70, "teaching_willingness": 20},
			"join_income": {"money": 0, "cohesion": -5, "creativity": 10, "reputation": 0},
			"join_effect_text": "入队后创造力+10，凝聚力-5",
			"special_ability": {
				"name": "技术指导",
				"description": "消耗100资金，提升指定成员技巧",
				"icon_path": "",
				"effect": {
					"target_stat": "skill", "delta": 5,
					"cost_money": 100, "cost_action": 1,
					"target_member": "selected"
				}
			},
			"resource_effects": {"cohesion": -0.3, "skill_boost": 1.2},
			"stage2_condition": {"relationship": 30},
			"stage3_condition": {"relationship": 60, "event": "car_accident_reveal"},
			"unlock_condition": {"reputation": 50, "cohesion": 40},
			"unlocked": false
		},
		{
			"id": "sebastian", "name": "塞巴斯蒂安", "role": "投资人", "personality": "资本代理人",
			"morale": 50, "fatigue": 20, "health": 95, "skill": 60, "charm": 65,
			"special_stats": {"capital_purity": 90, "investment_amount": 0},
			"join_income": {"money": 5000, "cohesion": -10, "creativity": 0, "reputation": 20},
			"join_effect_text": "入队后资金+5000，声誉+20，凝聚力-10",
			"special_ability": {
				"name": "商业投资",
				"description": "消耗2000资金，获得额外收入",
				"icon_path": "",
				"effect": {
					"target_stat": "investment_amount", "delta": 2000,
					"cost_money": 2000, "cost_action": 1,
					"special_effect": "future_income"
				}
			},
			"resource_effects": {"money": 2.0, "cohesion": -0.5},
			"stage2_condition": {"relationship": 30, "investment": 10000},
			"stage3_condition": {"relationship": 60, "event": "true_partner"},
			"unlock_condition": {"reputation": 60, "money": 20000},
			"unlocked": false
		},
		{
			"id": "lily", "name": "莉莉", "role": "小提琴手", "personality": "古典叛逃",
			"morale": 60, "fatigue": 30, "health": 85, "skill": 85, "charm": 55,
			"special_stats": {"perfectionism": 85, "improvisation_freedom": 10},
			"join_income": {"money": 0, "cohesion": 3, "creativity": 8, "reputation": 0},
			"join_effect_text": "入队后创造力+8，凝聚力+3",
			"special_ability": {
				"name": "即兴训练",
				"description": "消耗1行动点，提升即兴自由度",
				"icon_path": "",
				"effect": {
					"target_stat": "improvisation_freedom", "delta": 5,
					"cost_money": 0, "cost_action": 1,
					"secondary_stat": "perfectionism", "secondary_delta": -3
				}
			},
			"resource_effects": {"creativity": 0.4, "cohesion": 0.2},
			"stage2_condition": {"relationship": 35},
			"stage3_condition": {"relationship": 65},
			"unlock_condition": {"reputation": 40, "creativity": 50},
			"unlocked": false
		},
		{
			"id": "aya", "name": "阿雅", "role": "音乐治疗师", "personality": "音乐治疗",
			"morale": 80, "fatigue": 20, "health": 90, "skill": 70, "charm": 75,
			"special_stats": {"community_service": 50, "healing_power": 60},
			"join_income": {"money": 0, "cohesion": 10, "creativity": 5, "reputation": 5},
			"join_effect_text": "入队后凝聚力+10，创造力+5，声誉+5",
			"special_ability": {
				"name": "音乐治疗",
				"description": "消耗1行动点，恢复全员心情",
				"icon_path": "",
				"effect": {
					"target_stat": "healing_power", "delta": 0,
					"cost_money": 0, "cost_action": 1,
					"special_effect": "heal_all_members"
				}
			},
			"resource_effects": {"cohesion": 0.7, "morale_boost": 5.0},
			"stage2_condition": {"relationship": 30},
			"stage3_condition": {"relationship": 60},
			"unlock_condition": {"reputation": 35, "event": "community_event"},
			"unlocked": false
		},
		{
			"id": "duane", "name": "杜安", "role": "电子鼓手", "personality": "数据与感性",
			"morale": 55, "fatigue": 25, "health": 90, "skill": 90, "charm": 30,
			"special_stats": {"precision_rate": 95, "chaos_tolerance": 20},
			"join_income": {"money": 0, "cohesion": -3, "creativity": -5, "reputation": 0, "precision": 10},
			"join_effect_text": "入队后技巧+10，凝聚力-3，创造力-5",
			"special_ability": {
				"name": "数据分析",
				"description": "消耗1行动点，分析演出数据，提升下次演出效果",
				"icon_path": "",
				"effect": {
					"target_stat": "precision_rate", "delta": 0,
					"cost_money": 0, "cost_action": 1,
					"special_effect": "performance_boost"
				}
			},
			"resource_effects": {"precision": 1.1, "creativity": -0.2},
			"stage2_condition": {"relationship": 30},
			"stage3_condition": {"relationship": 60},
			"unlock_condition": {"reputation": 45, "facility_level": {"rehearsal": 3}},
			"unlocked": false
		},
		{
			"id": "old_nail", "name": "老钉子", "role": "酒吧守护者", "personality": "守护者",
			"morale": 100, "fatigue": 10, "health": 85, "skill": 80, "charm": 70,
			"special_stats": {"protection_pledge": 100, "hidden_knowledge": 0},
			"join_income": {"money": 0, "cohesion": 5, "creativity": 0, "reputation": 0},
			"join_effect_text": "入队后凝聚力+5",
			"special_ability": {
				"name": "往事回忆",
				"description": "消耗1行动点，了解过去的真相",
				"icon_path": "",
				"effect": {
					"target_stat": "hidden_knowledge", "delta": 10,
					"cost_money": 0, "cost_action": 1,
					"special_effect": "reveal_truth"
				}
			},
			"resource_effects": {"stability": 0.9, "hidden_bonus": 1.0},
			"stage2_condition": {"relationship": 30},
			"stage3_condition": {"relationship": 60, "memory": 50},
			"unlocked": true
		}
	]
	
	for char in characters:
		var resource = CharacterBase.new()
		resource.id = char["id"]
		resource.name = char["name"]
		resource.role = char["role"]
		resource.personality = char["personality"]
		resource.unlocked = char.get("unlocked", true)
		
		# 基础状态
		resource.morale = char.get("morale", 60)
		resource.fatigue = char.get("fatigue", 30)
		resource.health = char.get("health", 80)
		resource.skill = char.get("skill", 50)
		resource.charm = char.get("charm", 50)
		
		# 特殊属性
		resource.special_stats = char.get("special_stats", {})
		
		# 互动进度
		resource.relationship = 0
		resource.interaction_count = 0
		resource.current_stage = 1
		
		# 解锁条件
		resource.stage2_condition = char.get("stage2_condition", {"relationship": 30})
		resource.stage3_condition = char.get("stage3_condition", {"relationship": 60})
		resource.unlock_condition = char.get("unlock_condition", {})
		
		# 入队收益
		resource.join_income = char.get("join_income", {"money": 0, "cohesion": 5, "creativity": 0, "reputation": 0})
		resource.join_effect_text = char.get("join_effect_text", "入队后凝聚力+5")
		
		# 特殊功能
		resource.special_ability = char.get("special_ability", {
			"name": "鼓励",
			"description": "消耗50资金，提升心情10点",
			"icon_path": "",
			"effect": {"target_stat": "morale", "delta": 10, "cost_money": 50, "cost_action": 1}
		})
		
		# 资源关联
		resource.resource_effects = char.get("resource_effects", {})
		
		# 事件标记
		resource.events_triggered = []
		
		var path = "res://project/data/members/%s.tres" % char["id"]
		ResourceSaver.save(resource, path)
		print("创建: ", path, " - ", char["name"])
	
	print("\n所有角色文件创建完成！共 ", characters.size(), " 个角色")
