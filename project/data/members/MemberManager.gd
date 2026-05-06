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
				if not "favor" in member:
					member.favor = 0
				if not "weekly_talk_count" in member:
					member.weekly_talk_count = 0
			
				print("   └─ 好感度初始化为 0")
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
	# 【新增】增加好感度（对话每次调用这个）
func add_favor(member_id: String, amount: int = 1):
	if all_members.has(member_id):
		all_members[member_id].favor += amount
		print("✅ ", all_members[member_id].name, " 好感度 +", amount, " → ", all_members[member_id].favor)


# 增加关系进度（每次对话 +5）
func add_relationship_progress(member_id: String, delta: int = 10) -> int:
	if not all_members.has(member_id):
		return 0
	
	var member = all_members[member_id]
	
	# Resource 类型必须用这种安全写法
	var old_progress = 0
	if "relationship_progress" in member:
		old_progress = member.relationship_progress
	
	var new_progress = old_progress + delta
	member.relationship_progress = new_progress
	
	print("📈 ", member.name, " 关系度 +", delta, " → ", new_progress)
	
	return new_progress

# 【修改】现在招募条件改为：好感度 >= 10
func can_recruit(member_id: String) -> bool:
	var member = all_members.get(member_id)
	if not member:
		return false
	# 新条件：好感度达到10才可以招募（不再看 unlock_condition 的钱和声誉）
	return member.favor >= 10
	
	# 增加对话次数并返回是否还能对话
func talk_to_member(member_id: String) -> bool:
	if not all_members.has(member_id):
		return false
	
	var member = all_members[member_id]
	if member.weekly_talk_count >= 5:
		return false  # 已达上限
	
	member.weekly_talk_count += 1
	print("📢 ", member.name, " 本周对话次数：", member.weekly_talk_count, "/5")
	return true

# 新一周重置所有对话次数（在 ResourceManager 新周开始时调用）
func reset_weekly_talk_counts():
	for member in all_members.values():
		member.weekly_talk_count = 0
	print("🔄 已重置所有成员本周对话次数")
