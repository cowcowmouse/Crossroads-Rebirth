extends Control

@export_group("UI 组件")
@export var charactor_name_text : Label
@export var text_box : Label
@export var left_avatar : TextureRect
@export var right_avatar : TextureRect 

@export_group("对话资源")
@export var main_dialogue : DialogueGroup
 
var dialogue_index := 0

func display_next_dialogue():
	var dialogue = main_dialogue.dialogue_list[dialogue_index]
	
	charactor_name_text.text = dialogue.charactor_name
	text_box.text = dialogue.content
	if dialogue.show_on_left:
		left_avatar.texture = dialogue.avatar
		right_avatar.texture = null
	else:
		left_avatar.texture = null
		right_avatar.texture = dialogue.avatar
		
		dialogue_index += 1
func _ready():
	display_next_dialogue()		
