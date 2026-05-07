# Global.gd（或新建 MemberManager.gd 作为 Autoload 更好）
extends Node
var previous_scene_path: String = ""   # 记住上一个场景的路径
# 每个成员的数据结构
var members := {
	"old_nail": {"relation": 0, "weekly_first_chat": true, "joined": false, "total_chat": 0, "stage": 0},
	"keira":   {"relation": 0, "weekly_first_chat": true, "joined": false, "total_chat": 0, "stage": 0},
	# 继续添加其他7人： "mei", "rio", "member3" ... "member9"
}

const MAX_RELATION_STAGE = 3  # 0=陌生, 1=认识, 2=熟悉(招募选项), 3=入队

func get_member_data(id: String) -> Dictionary:
	return members.get(id, {})

func increase_relation(id: String, amount: int = 1) -> void:
	if not members.has(id): return
	var data = members[id]
	data.relation += amount
	data.total_chat += 1
	data.weekly_first_chat = false
	
	# 更新阶段
	data.stage = mini(data.relation / 2, MAX_RELATION_STAGE)  # 每2点升1阶段
	
	# 每周第一次对话额外加成
	if data.weekly_first_chat:
		data.relation += 1
	
	EventBus.member_relation_changed.emit(id, data.relation)

# 周开始时重置 weekly_first_chat
func reset_weekly_first_chat():
	for id in members:
		members[id].weekly_first_chat = true
