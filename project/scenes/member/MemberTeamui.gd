# MemberTeamui.gd
extends Control

@onready var Btn_Toggle: Button = $Btn_Toggle
@onready var AvatarContainer: HBoxContainer = $AvatarContainer

# 如果你做了自定义头像按钮预制体，可以在这里指定
@export var avatar_button_scene: PackedScene

# 引用 MemberManager（推荐使用 Autoload 方式）
@onready var member_manager = get_node_or_null("/root/MemberManager")

func _ready():
	AvatarContainer.visible = false
	Btn_Toggle.pressed.connect(_toggle)
	
	# 初始刷新
	refresh_team_ui()

func _toggle():
	AvatarContainer.visible = !AvatarContainer.visible

# 刷新显示所有已入队成员
func refresh_team_ui():
	# 清空旧按钮
	for child in AvatarContainer.get_children():
		child.queue_free()

	if not member_manager:
		push_error("MemberManager 未找到！请确认它已设为 Autoload")
		return

	var unlocked_members = member_manager.get_unlocked_members()

	for member in unlocked_members:
		var btn
		
		if avatar_button_scene:
			btn = avatar_button_scene.instantiate()
		else:
			# 临时方案：用普通 Button 显示名字前两个字
			btn = Button.new()
			btn.custom_minimum_size = Vector2(80, 80)
			btn.text = member.name.left(2)
		
		btn.tooltip_text = "%s\n%s" % [member.name, member.role]
		btn.pressed.connect(_on_member_clicked.bind(member.id))
		
		AvatarContainer.add_child(btn)

# 点击头像打开对话
func _on_member_clicked(member_id: String):
	print("点击了成员：", member_id)
	
	# 安全调用对话系统
	var talk_system = get_node_or_null("/root/MemberTalkSystem")  # 或你实际的对话系统路径
	if talk_system and talk_system.has_method("show_simple_chat"):
		talk_system.show_simple_chat(member_id)
	else:
		push_warning("对话系统未找到或方法不存在")
