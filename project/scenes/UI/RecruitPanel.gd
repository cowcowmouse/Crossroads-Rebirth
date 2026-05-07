# RecruitPanel.gd
extends Panel

var current_member_id: String = ""
var current_member = null

@onready var title_label = $VBoxContainer/TitleLabel
@onready var info_label = $VBoxContainer/InfoLabel
@onready var recruit_button = $VBoxContainer/RecruitButton
@onready var kick_button = $VBoxContainer/KickButton
@onready var cancel_button = $VBoxContainer/CancelButton
@onready var result_label = $ResultLabel

# 踢出确认面板
@onready var kick_confirm_panel = $KickConfirmPanel
@onready var confirm_kick_btn = $KickConfirmPanel/HBoxContainer/ConfirmKickBtn
@onready var cancel_kick_btn = $KickConfirmPanel/HBoxContainer/CancelKickBtn

# 安全引用 MemberManager（Autoload）
@onready var member_manager = get_node_or_null("/root/MemberManager")

func _ready():
	result_label.visible = false
	kick_confirm_panel.visible = false
	
	# 按钮连接
	recruit_button.pressed.connect(_on_recruit_pressed)
	kick_button.pressed.connect(_on_kick_pressed)
	cancel_button.pressed.connect(queue_free)
	
	if confirm_kick_btn:
		confirm_kick_btn.pressed.connect(_confirm_kick)
	if cancel_kick_btn:
		cancel_kick_btn.pressed.connect(func(): kick_confirm_panel.visible = false)

func setup(member_id: String):
	current_member_id = member_id
	current_member = member_manager.get_member(member_id) if member_manager else null
	
	if not current_member:
		queue_free()
		return
	
	title_label.text = "招募 " + current_member.name
	
	# 正确获取招募费用
	var cost = current_member.join_cost if "join_cost" in current_member else 8000
	info_label.text = "所需资金：%d" % cost
	
	# 根据是否已入队显示不同按钮
	if current_member.unlocked:
		recruit_button.visible = false
		kick_button.visible = true
	else:
		recruit_button.visible = true
		kick_button.visible = false

func _on_recruit_pressed():
	if not current_member:
		return
	
	var cost = current_member.join_cost if "join_cost" in current_member else 8000
	
	if ResourceManager.can_afford(cost):
		ResourceManager.add_money(-cost)
		member_manager.unlock_member(current_member_id)
		
		# 招募成功增加声誉
		if ResourceManager.has_method("add_reputation"):
			ResourceManager.add_reputation(20)
		
		result_label.text = "招募成功！\n声誉 +20"
		result_label.modulate = Color.GREEN
		result_label.visible = true
		
		# 更新按钮状态
		recruit_button.visible = false
		kick_button.visible = true
		
		# 刷新总览界面
		var overview = get_tree().current_scene.get_node_or_null("TeamOverview")
		if overview and overview.has_method("refresh_all_slots"):
			overview.refresh_all_slots()
		
	else:
		result_label.text = "资金不足，无法招募！"
		result_label.modulate = Color.RED
		result_label.visible = true

func _on_kick_pressed():
	kick_confirm_panel.visible = true

func _confirm_kick():
	if not current_member:
		return
	
	# 执行踢出
	member_manager.kick_member(current_member_id)
	
	result_label.text = "已踢出成员\n声誉 -15"
	result_label.modulate = Color.RED
	result_label.visible = true
	
	kick_confirm_panel.visible = false
	kick_button.visible = false
	recruit_button.visible = true
	recruit_button.text = "重新招募"
	
	# 刷新总览界面
	var overview = get_tree().current_scene.get_node_or_null("TeamOverview")
	if overview and overview.has_method("refresh_all_slots"):
		overview.refresh_all_slots()
