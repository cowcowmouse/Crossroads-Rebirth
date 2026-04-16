extends Control

signal panel_closed

# 变量声明
var character_id: String = ""
var character_data: CharacterBase

@onready var avatar = $Avatar
@onready var name_label = $NameLabel
@onready var role_label = $RoleLabel
@onready var morale_bar = $StatsContainer/MoraleBar
@onready var morale_label = $StatsContainer/MoraleLabel
@onready var fatigue_bar = $StatsContainer/FatigueBar
@onready var fatigue_label = $StatsContainer/FatigueLabel
@onready var health_bar = $StatsContainer/HealthBar
@onready var health_label = $StatsContainer/HealthLabel
@onready var relationship_label = $RelationshipLabel
@onready var special_button = $SpecialButton
@onready var close_button = $CloseButton
@onready var Lbl_Relation: Label = $Lbl_Relation
@onready var Btn_Recruit: Button = $Btn_Recruit

func _ready():
	# 自动绑定招募按钮
	Btn_Recruit.pressed.connect(_on_recruit_pressed)
	
	close_button.pressed.connect(_on_close_pressed)
	special_button.pressed.connect(_on_special_pressed)

# 更新面板内容（TalkSystem 会调用它）
func update_info(name: String, relation: int, show_recruit: bool):
	Lbl_Relation.text = "关系度：%d" % relation
	Btn_Recruit.visible = show_recruit

# 点击招募 → 通知 TalkSystem
func _on_recruit_pressed():
	get_parent()._recruit_member()

func setup(char_id: String):
	character_id = char_id
	character_data = MemberData.get_character(char_id)
	
	if not character_data:
		queue_free()
		return
	
	# 设置基本信息
	name_label.text = character_data.name
	role_label.text = character_data.role
	
	# 设置头像
	if character_data.avatar:
		avatar.texture = character_data.avatar
	
	# 更新状态
	_update_stats()
	_update_relationship()
	
	# 设置特殊按钮
	_setup_special_button()

func _update_stats():
	var morale = ResourceManager.get_member_stat(character_id, "morale")
	var fatigue = ResourceManager.get_member_stat(character_id, "fatigue")
	var health = ResourceManager.get_member_stat(character_id, "health")
	
	morale_bar.value = morale
	morale_label.text = "心情: %d/100" % morale
	fatigue_bar.value = fatigue
	fatigue_label.text = "疲劳: %d/100" % fatigue
	health_bar.value = health
	health_label.text = "健康: %d/100" % health

func _update_relationship():
	var rel = character_data.relationship
	relationship_label.text = "关系度: %d/100" % rel

func _setup_special_button():
	var special = character_data.special_ability
	if special.is_empty():
		special_button.visible = false
		return
	
	special_button.text = special.get("name", "特殊功能")
	special_button.visible = true

func _on_special_pressed():
	var special = character_data.special_ability
	var effect = special.get("effect", {})
	
	# 检查资源
	var cost_money = effect.get("cost_money", 0)
	var cost_action = effect.get("cost_action", 0)
	
	if cost_money > 0 and ResourceManager.get_money() < cost_money:
		EventBus.show_notification.emit("资金不足")
		return
	
	if cost_action > 0 and ResourceManager.get_action_points() < cost_action:
		EventBus.show_notification.emit("行动点不足")
		return
	
	# 消耗资源
	if cost_money > 0:
		ResourceManager.add_money(-cost_money)
	if cost_action > 0:
		ResourceManager.consume_action_point()
	
	# 应用效果
	var target_stat = effect.get("target_stat", "")
	var delta = effect.get("delta", 0)
	if target_stat and delta != 0:
		ResourceManager.modify_member_stat(character_id, target_stat, delta)
	
	# 次要效果
	var secondary_stat = effect.get("secondary_stat", "")
	var secondary_delta = effect.get("secondary_delta", 0)
	if secondary_stat and secondary_delta != 0:
		ResourceManager.modify_member_stat(character_id, secondary_stat, secondary_delta)
	
	# 特殊效果处理
	var special_effect = effect.get("special_effect", "")
	if special_effect == "heal_all_members":
		ResourceManager.heal_all_members()
	elif special_effect == "resolve_conflict":
		ResourceManager.resolve_conflict()
	elif special_effect == "reveal_truth":
		ResourceManager.add_memory(5)
	
	EventBus.show_notification.emit(special.get("description", "使用成功"))
	_update_stats()

func _on_close_pressed():
	panel_closed.emit()
	queue_free()
