extends Control

@onready var Lbl_Relation: Label = $Lbl_Relation
@onready var Btn_Recruit: Button = $Btn_Recruit

func _ready():
	# 自动绑定招募按钮
	Btn_Recruit.pressed.connect(_on_recruit_pressed)

# 更新面板内容（TalkSystem 会调用它）
func update_info(name: String, relation: int, show_recruit: bool):
	Lbl_Relation.text = "关系度：%d" % relation
	Btn_Recruit.visible = show_recruit

# 点击招募 → 通知 TalkSystem
func _on_recruit_pressed():
	get_parent()._recruit_member()
