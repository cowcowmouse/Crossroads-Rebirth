# MembersDatabase.gd （Autoload）
extends Node

var characters: Dictionary = {}

func _ready():
	load_all_characters()

func load_all_characters():
	var ids = ["rio", "kira", "mei", "finn", "sebastian", "lily", "aya", "duane", "old_nail"]
	for id in ids:
		var path = "res://project/data/members/%s.tres" % id
		if ResourceLoader.exists(path):
			characters[id] = load(path)
			print("加载角色: ", id)
		else:
			print("警告: 找不到角色文件 ", path)

func get_character(id: String) -> Resource:
	return characters.get(id)

func get_all_recruited() -> Array:
	var list: Array = []
	for char in characters.values():
		if char.is_recruited:
			list.append(char)
	return list

# ==================== 新增：关系系统 ====================

# 增加关系值（推荐在对话结束后调用）
func add_relationship(char_id: String, delta: int = 1) -> int:
	var char = get_character(char_id)
	if not char:
		print("错误: 找不到角色 ", char_id)
		return 0
	
	# 每周第一次对话才增加（防止刷关系）
	if char.interaction_count_this_week >= 1:
		print(char.name, " 本周已经对话过，不再增加关系值")
		return char.relationship
	
	var old_rel = char.relationship
	char.relationship = clamp(old_rel + delta, 0, 100)
	char.interaction_count_this_week += 1
	
	# 检查阶段变化
	var old_stage = char.get_relationship_stage() if char.has_method("get_relationship_stage") else 1
	var new_stage = char.get_relationship_stage() if char.has_method("get_relationship_stage") else 1
	
	if new_stage > old_stage:
		print(char.name, " 关系提升！进入阶段 ", new_stage)
	
	ResourceSaver.save(char)
	print(char.name, " 关系值: ", old_rel, " → ", char.relationship)
	return char.relationship

# 每周重置（在 WeekCycleManager 或新周开始时调用）
func reset_all_weekly_interactions():
	for char in characters.values():
		if "interaction_count_this_week" in char:
			char.interaction_count_this_week = 0
			ResourceSaver.save(char)
	print("已重置所有角色本周互动次数")

# 招募
func recruit_member(id: String) -> bool:
	var char = get_character(id)
	if char and char.has_method("can_recruit") and char.can_recruit():
		char.is_recruited = true
		ResourceSaver.save(char)
		print(char.name, " 已成功入队！")
		activate_special_effect(id)
		return true
	return false

func activate_special_effect(id: String):
	match id:
		"kira":
			print("【凯拉入队】全局声誉收益 +15%")
		"rio":
			print("【里奥入队】每周疲劳恢复增强")
		"mei":
			print("【梅入队】特殊效果激活")
		_:
			print("成员 ", id, " 入队（暂无特殊效果）")
