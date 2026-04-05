extends Resource
class_name MemberOldNail

# 基础关系数据
@export var relation: int = 0
@export var weekly_first_chat: bool = true
@export var join_team: bool = false
@export var chat_count: int = 0
@export var stage: int = 1

# 入队后每周效果（资源影响）
@export var weekly_effect: Dictionary = {
	"money": -30,
	"reputation": 10,
	"cohesion": 2
}

# 各阶段对话
@export var dialogs: Dictionary = {
	1: ["你谁啊？", "别来烦我。"],
	2: ["哦，是你啊。", "还挺准时的。"],
	3: ["有你在，放心。", "一起加油吧。"]
}
