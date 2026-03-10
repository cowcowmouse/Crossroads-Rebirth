# 乐队成员数据模型，定义所有成员的通用属性+专属机制
extends Resource

class_name Member

# 基础信息
@export var member_id: String = ""
@export var name: String = ""
@export var role: String = ""
@export var unlocked: bool = false

# 通用状态属性
@export var morale: int = 60 # 士气 0-100
@export var fatigue: int = 30 # 疲劳度 0-100
@export var health: int = 80 # 健康值 0-100
@export var relationship_progress: int = 0 # 关系进度 0-99
@export var weekly_chat_count: int = 0 # 本周对话次数
@export var satisfaction: int = 80 # 满意度 0-100

# 成员专属机制属性，后续逐步添加
# 里奥专属
@export var soberness: int = 80 # 清醒度 0-100
# 凯拉专属
@export var popularity_index: int = 50 # 流行指数 0-100
@export var depth_index: int = 50 # 深度指数 0-100

# 重置每周计数（周结算时调用）
func reset_weekly_count():
    weekly_chat_count = 0

# 每日自然状态变化
func daily_natural_change():
    # 疲劳度自然增长
    fatigue = clamp(fatigue + 2, 0, 100)
    # 里奥清醒度自然下降
    if member_id == "rio" and unlocked:
        soberness = clamp(soberness - 10, 0, 100)
