extends Node

# 角色ID常量
const CHAR_RIO = "rio"
const CHAR_KIRA = "kira"
const CHAR_MEI = "mei"
const CHAR_FINN = "finn"
const CHAR_SEBASTIAN = "sebastian"
const CHAR_LILY = "lily"
const CHAR_AYA = "aya"
const CHAR_DUANE = "duane"
const CHAR_OLD_NAIL = "old_nail"

var characters_cache: Dictionary = {}

func _ready():
	_load_all_characters()

func _load_all_characters():
	var character_ids = [
		CHAR_RIO, CHAR_KIRA, CHAR_MEI, CHAR_FINN,
		CHAR_SEBASTIAN, CHAR_LILY, CHAR_AYA, CHAR_DUANE, CHAR_OLD_NAIL
	]
	
	for char_id in character_ids:
		var path = "res://project/data/members/%s.tres" % char_id
		if ResourceLoader.exists(path):
			characters_cache[char_id] = load(path)
			print("加载角色: ", char_id)
		else:
			print("警告: 找不到 ", path)

func get_character(char_id: String) -> CharacterBase:
	return characters_cache.get(char_id, null)

func get_character_dict(char_id: String) -> Dictionary:
	var char = get_character(char_id)
	if not char:
		return {}
	
	return {
		"id": char.id,
		"name": char.name,
		"role": char.role,
		"personality": char.personality,
		"unlocked": char.unlocked,
		"morale": char.morale,
		"fatigue": char.fatigue,
		"health": char.health,
		"skill": char.skill,
		"charm": char.charm,
		"special_stats": char.special_stats,
		"relationship": char.relationship,
		"interaction_count": char.interaction_count,
		"current_stage": char.current_stage,
		"join_income": char.join_income,
		"join_effect_text": char.join_effect_text,
		"special_ability": char.special_ability,
		"resource_effects": char.resource_effects
	}

func get_unlocked_characters() -> Array:
	var unlocked = []
	for char_id in characters_cache:
		if characters_cache[char_id].unlocked:
			unlocked.append(char_id)
	return unlocked

func add_relationship(char_id: String, delta: int) -> int:
	var char = get_character(char_id)
	if not char:
		return 0
	
	var old = char.relationship
	var new_val = clamp(old + delta, 0, 100)
	char.relationship = new_val
	
	# 保存修改
	ResourceSaver.save(char)
	
	# 检查阶段变化
	_check_stage_change(char)
	
	return new_val

func _check_stage_change(char: CharacterBase):
	var rel = char.relationship
	var current_stage = char.current_stage
	var new_stage = current_stage
	
	if rel >= 60 and current_stage < 3:
		new_stage = 3
	elif rel >= 30 and current_stage < 2:
		new_stage = 2
	
	if new_stage != current_stage:
		char.current_stage = new_stage
		ResourceSaver.save(char)
		print(char.name, " 进入剧情阶段 ", new_stage)

func modify_special_stat(char_id: String, stat: String, delta: int) -> int:
	var char = get_character(char_id)
	if not char:
		return 0
	
	if not char.special_stats.has(stat):
		return 0
	
	var old = char.special_stats[stat]
	var new_val = clamp(old + delta, 0, 100)
	char.special_stats[stat] = new_val
	
	ResourceSaver.save(char)
	print(char.name, " 的 ", stat, " 变化: ", old, " -> ", new_val)
	return new_val
