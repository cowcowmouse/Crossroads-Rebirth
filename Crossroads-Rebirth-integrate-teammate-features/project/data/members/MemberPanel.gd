extends Control


@onready var Lbl_Relation: Label = $Lbl_Relation
@onready var Btn_Recruit: Button = $Btn_Recruit

func _ready():
	visible = false

func set_relation(text: String):
	Lbl_Relation.text = text

func set_recruit_visible(vis: bool):
	Btn_Recruit.visible = vis
