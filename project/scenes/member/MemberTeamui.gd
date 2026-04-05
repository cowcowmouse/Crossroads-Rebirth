extends Control

@onready var Btn_Toggle: Button = $Btn_Toggle
@onready var AvatarContainer: HBoxContainer = $AvatarContainer

func _ready():
	AvatarContainer.visible = false
	Btn_Toggle.pressed.connect(_toggle)

	for child in AvatarContainer.get_children():
		child.visible = false

func _toggle():
	AvatarContainer.visible = !AvatarContainer.visible

func show_member_avatar(member_id: String):
	var btn = AvatarContainer.get_node_or_null(member_id)
	if btn:
		btn.visible = true
