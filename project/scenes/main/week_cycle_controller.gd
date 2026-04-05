extends Node
class_name WeekCycleController

# ====================== 全局单例 ======================
@onready var Global = get_node_or_null("/root/Global")
@onready var CharacterSpawn = get_node_or_null("/root/CharacterSpawn")
@onready var TalkSystem = get_node_or_null("/root/TalkSystem")

# ====================== UI（下周按钮） ======================
@onready var btn_next_week: Button = get_node_or_null("Btn_NextWeek")
@onready var lbl_week_info: Label = get_node_or_null("Lbl_WeekInfo")  # 显示当前周数

# ====================== 配置 ======================
@export var reset_action_point: int = 10  # 每周重置行动点数量

# ====================== 初始化 ======================
func _ready():
	# 绑定下周按钮
	if btn_next_week:
		btn_next_week.pressed.connect(next_week)
	# 初始化周数显示
	_update_week_info()
	# 生成第一周角色
	if CharacterSpawn:
		CharacterSpawn.generate_weekly_characters()
		# 更新角色按钮显隐
		if TalkSystem:
			TalkSystem._update_character_buttons_visibility()

# ====================== 核心：进入下周 ======================
func next_week():
	if not Global or not CharacterSpawn or not TalkSystem: return
	
	# 1. 周数+1
	Global.current_week += 1
	print("🗓️ 进入第%d周" % Global.current_week)
	
	# 2. 重置行动点
	Global.action_point = reset_action_point
	print("✅ 行动点重置为：%d" % reset_action_point)
	
	# 3. 重置TalkSystem首次聊天标记
	TalkSystem.reset_weekly_chat_flag()
	
	# 4. 重新生成本周角色列表
	CharacterSpawn.generate_weekly_characters()
	
	# 5. 更新角色按钮显隐（关键：刷新按钮）
	TalkSystem._update_character_buttons_visibility()
	
	# 6. 更新周数显示
	_update_week_info()
	
	print("✅ 第%d周初始化完成！" % Global.current_week)

# ====================== 工具函数 ======================
func _update_week_info():
	if lbl_week_info and Global:
		lbl_week_info.text = "当前周数：第%d周 | 行动点：%d" % [Global.current_week, Global.action_point]
