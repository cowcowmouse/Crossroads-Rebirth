extends Resource
class_name MemberKeira

# 基础关系数据
@export var relation: int = 0
@export var weekly_first_chat: bool = true
@export var join_team: bool = false
@export var chat_count: int = 0
@export var stage: int = 1

# 入队后每周效果
@export var weekly_effect: Dictionary = {
	"money": -40,
	"reputation": 15,
	"cohesion": 3
}

# 各阶段对话
@export var dialogs: Dictionary = {
	1: ["离我远点。", "你想干嘛？"],
	2: ["你来了，还行。", "今天状态不错。"],
	3: ["我相信你。", "我们一起做好。"]
}
