# MemberManager.gd
extends Node

# 所有成员资源：id → CharacterBase
var all_members: Dictionary = {}

func _ready():
	_load_all_members()

# 加载项目中所有的成员 .tres 文件
func _load_all_members():
	var paths = [
		"res://project/data/members/sebastian.tres",
		"res://project/data/members/lily.tres",
		"res://project/data/members/aya.tres",
		"res://project/data/members/duane.tres",
		"res://project/data/members/rio.tres",
		"res://project/data/members/finn.tres",
		"res://project/data/members/old_nail.tres",
		"res://project/data/members/mei.tres",
		"res://project/data/members/kira.tres",
		# 以后新增成员只需要在这里加路径即可
	]

	for path in paths:
		if ResourceLoader.exists(path):
			var member = load(path) as CharacterBase
			if member:
				all_members[member.id] = member
				print("已加载成员：", member.name, " (", member.id, ")")
		else:
			push_warning("成员文件不存在：", path)

# ====================== 设置默认招募状态 ======================
	# 加载完成后，强制设置默认招募状态
	for id in all_members.keys():
		var member = all_members[id]
		if id == "old_nail":
			member.unlocked = true
		else:
			member.unlocked = false
	
	print("已设置默认招募状态：只有 old_nail 已入队，其他成员未招募")

# 根据ID获取成员
func get_member(id: String) -> CharacterBase:
	return all_members.get(id)

# 获取所有已解锁成员
func get_unlocked_members() -> Array:
	var list = []
	for m in all_members.values():
		if m.unlocked:
			list.append(m)
	return list

# 招募成员（解锁）
func unlock_member(id: String):
	if all_members.has(id):
		all_members[id].unlocked = true
		print("成员已招募：", all_members[id].name)
		


# 判断是否可以招募
func can_recruit(member_id: String) -> bool:
	var member = all_members.get(member_id)
	if not member: return false

	var cost_money = member.unlock_condition.get("money", 0)
	var cost_reputation = member.unlock_condition.get("reputation", 0)

	return (
		ResourceManager.can_afford(cost_money) and
		ResourceManager.get_resource_value("reputation") >= cost_reputation
	)
	
	# 获取所有可招募的成员（未解锁的）
func get_recruitable_members() -> Array:
	var list = []
	for member in all_members.values():
		if not member.unlocked:
			list.append(member)
	return list
	
	
# ====================== 新增：踢出成员 ======================
func kick_member(id: String) -> bool:
	var member = all_members.get(id)
	if not member or not member.unlocked:
		print("无法踢出：成员不存在或未入队")
		return false
	
	# 执行踢出
	member.unlocked = false
	
	# 踢出时扣除声誉（可自行调整数值）
	var reputation_penalty = 15
	if ResourceManager and ResourceManager.has_method("add_reputation"):
		ResourceManager.add_reputation(-reputation_penalty)
	
	print(member.name, " 已被踢出队伍，声誉减少 ", reputation_penalty, " 点")
	return true
