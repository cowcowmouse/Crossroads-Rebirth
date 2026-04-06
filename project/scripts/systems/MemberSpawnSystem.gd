extends Node
class_name MemberSpawnSystem

# 每周出现概率（主角Alexi已移除，不会随机刷出来）
@export var member_spawn_prob: Dictionary = {
	"old_nail": 0.3,   # 30%概率出现
	"Keira": 0.4        # 40%概率出现
}

# 已经入队的角色（永远出现）
var joined_members: Array = []

# 本周可以互动的角色
var current_week_members: Array = []

func _ready():
	randomize()

# 每周刷新一次：生成本周可出现的角色
func generate_weekly_members() -> Array:
	current_week_members = []

	# 1. 入队角色 → 必定出现
	for member in joined_members:
		if member not in current_week_members:
			current_week_members.append(member)
			print("✅ 入队成员固定出现：", member)

	# 2. 未入队角色 → 按概率刷新
	for member in member_spawn_prob:
		if member in joined_members:
			continue
		
		var rand_val = randf()
		if rand_val < member_spawn_prob[member]:
			current_week_members.append(member)
			print("✅ 本周刷出：", member, " 随机值:", rand_val)
		else:
			print("❌ 本周未刷出：", member)

	# 去重
	var temp = []
	for m in current_week_members:
		if m not in temp:
			temp.append(m)
	current_week_members = temp

	print("---------------------------------")
	print("📋 本周可互动角色：", current_week_members)
	print("---------------------------------")
	return current_week_members

# 招募入队 → 加入永久列表
func add_joined_member(member_name: String):
	if member_name in member_spawn_prob and member_name not in joined_members:
		joined_members.append(member_name)
		if member_name not in current_week_members:
			current_week_members.append(member_name)
		print("✅ ", member_name, " 已入队，后续永久出现")

# 离队（可选）
func remove_joined_member(member_name: String):
	if member_name in joined_members:
		joined_members.erase(member_name)
		print("❌ ", member_name, " 已离队")

# 外部调用：这个角色本周是否出现
func is_member_show_this_week(member_name: String) -> bool:
	return member_name in current_week_members

# 外部调用：是否已经入队
func is_member_joined(member_name: String) -> bool:
	return member_name in joined_members
