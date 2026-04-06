extends Node2D
class_name MemberPanel
@onready var member_panel = get_node("MemberPanel")
@onready var member_team_ui = get_node("/root/main/MemberTeamUI")
@onready var Global = get_node_or_null("/root/Global")
@onready var MemberSpawn = get_node_or_null("/root/MemberSpawnSystem")

@onready var ui_simple_chat: Control = get_node_or_null("UI_SimpleChat")
@onready var lbl_chat_text: Label = get_node_or_null("UI_SimpleChat/Lbl_ChatText")
@onready var btn_view_info: Button = get_node_or_null("UI_SimpleChat/Btn_ViewInfo")
@onready var btn_start_event: Button = get_node_or_null("UI_SimpleChat/Btn_StartEvent")

@onready var ui_member_panel: Control = get_node_or_null("UI_MemberPanel")
@onready var lbl_relation: Label = get_node_or_null("UI_MemberPanel/Lbl_Relation")
@onready var btn_start_talk: Button = get_node_or_null("UI_MemberPanel/Btn_StartTalk")
@onready var btn_recruit: Button = get_node_or_null("UI_MemberPanel/Btn_Recruit")

var is_dialog_running: bool = false
var current_member: String = "old_nail"
var dialog_path_template: String = "res://addons/dialogic/characters/%s/stage_%d.dtl"

func _ready():
	_hide_all_panels()
	_bind_buttons()
	_bind_dialogic()
	_init_ui_state()

func _bind_buttons():
	if btn_view_info: btn_view_info.pressed.connect(_open_info_panel)
	if btn_start_event: btn_start_event.pressed.connect(_start_dialogic)
	if btn_start_talk: btn_start_talk.pressed.connect(_start_dialogic)
	if btn_recruit: btn_recruit.pressed.connect(_recruit_member)

func _bind_dialogic():
	if Dialogic:
		Dialogic.timeline_ended.connect(_on_dialog_finished)

func _init_ui_state():
	if btn_recruit:
		btn_recruit.visible = false

# ====================== 点击角色才会调用这里 ======================
func show_simple_chat(member_name: String = "old_nail"):
	current_member = member_name
	_hide_all_panels()

	if ui_simple_chat:
		ui_simple_chat.visible = true
		lbl_chat_text.text = _get_chat_text(member_name)

func _get_chat_text(member_name: String) -> String:
	var rel = get_member_relation(member_name)
	if rel < 30:
		return "嗯？有事吗？"
	elif rel < 60:
		return "哦，是你啊。"
	else:
		return "你来啦，随便坐。"

func _open_info_panel():
	_hide_all_panels()
	if ui_member_panel:
		ui_member_panel.visible = true
		_update_relation_display()

		if btn_recruit:
			var rel = get_member_relation(current_member)
			var joined = get_member_join_status(current_member)
			btn_recruit.visible = rel >= 30 && !joined

func _start_dialogic():
	if is_dialog_running: return
	if Global and Global.action_point < 1:
		print("⚠️ 行动点不足")
		return

	var relation = get_member_relation(current_member)
	var stage = 1
	if relation >= 30: stage = 2
	if relation >= 60: stage = 3

	var path = dialog_path_template % [current_member, stage]

	if get_member_weekly_first(current_member):
		set_member_relation(current_member, get_member_relation(current_member) + 10)
		set_member_weekly_first(current_member, false)

	if Global:
		Global.action_point -= 1

	_update_relation_display()
	_hide_all_panels()
	is_dialog_running = true

	if Dialogic:
		var t = load(path)
		if t:
			Dialogic.start(t)
		else:
			is_dialog_running = false

func _recruit_member() -> void:
	if not Global: return
	if Global.action_point < 3:
		print("⚠️ 招募需要 3 点行动点")
		return

	Global.action_point -= 3
	set_member_join_status(current_member, true)

	if btn_recruit:
		btn_recruit.visible = false

	if MemberSpawn:
		MemberSpawn.add_joined_member(current_member)

	print("✅ 招募成功：", current_member)
	var team_ui = get_node_or_null("../MemberTeamUI")
	if team_ui:
	   team_ui.show_member_avatar(current_member)

func _on_dialog_finished(_tl):
	is_dialog_running = false
	_hide_all_panels()

func _update_relation_display():
	if lbl_relation:
		lbl_relation.text = "关系度：%d" % get_member_relation(current_member)

func _hide_all_panels():
	if ui_simple_chat:
		ui_simple_chat.visible = false
	if ui_member_panel:
		ui_member_panel.visible = false

func _add_avatar_to_sidebar(member_name: String):
	var container = get_node_or_null("Sidebar/AvatarContainer")
	if container:
		var avatar = container.get_node_or_null(member_name)
		if avatar:
			avatar.visible = true

# ====================== 数据读写 ======================
func get_member_relation(member: String) -> int:
	if not Global: return 0
	match member:
		"old_nail": return Global.relation_old_nail
		"Keira": return Global.relation_Keira
		_: return 0

func set_member_relation(member: String, v: int):
	if not Global: return
	match member:
		"old_nail": Global.relation_old_nail = v
		"Keira": Global.relation_Keira = v

func get_member_weekly_first(member: String) -> bool:
	if not Global: return true
	match member:
		"old_nail": return Global.weekly_first_chat_old_nail
		"Keira": return Global.weekly_first_chat_Keira
		_: return true

func set_member_weekly_first(member: String, v: bool):
	if not Global: return
	match member:
		"old_nail": Global.weekly_first_chat_old_nail = v
		"Keira": Global.weekly_first_chat_Keira = v

func get_member_join_status(member: String) -> bool:
	if not Global: return false
	match member:
		"old_nail": return Global.join_team_old_nail
		"Keira": return Global.join_team_Keira
		_: return false

func set_member_join_status(member: String, v: bool):
	if not Global: return
	match member:
		"old_nail": Global.join_team_old_nail = v
		"Keira": Global.join_team_Keira = v

func get_member_chat_count(member: String) -> int:
	if not Global: return 0
	match member:
		"old_nail": return Global.total_chat_old_nail
		"Keira": return Global.total_chat_Keira
		_: return 0

func set_member_chat_count(member: String, v: int):
	if not Global: return
	match member:
		"old_nail": Global.total_chat_old_nail = v
		"Keira": Global.total_chat_Keira = v

func reset_weekly_chat_flag():
	set_member_weekly_first("old_nail", true)
	set_member_weekly_first("Keira", true)
