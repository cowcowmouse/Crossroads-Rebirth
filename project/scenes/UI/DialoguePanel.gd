extends Panel

var member_id: String = ""
var current_line: int = 0
var dialogue_lines: Array = []

@onready var portrait_rect: TextureRect = $PortraitRect
@onready var dialogue_text: RichTextLabel = $TextBox/DialogueText

func show_dialogue(id: String, portrait_path: String):
	member_id = id
	current_line = 0
	visible = true
	
	# 显示立绘
	if ResourceLoader.exists(portrait_path):
		portrait_rect.texture = load(portrait_path)
	
	# 检查本周是否还能对话
	if MemberManager and MemberManager.has_method("talk_to_member"):
		if not MemberManager.talk_to_member(id):
			dialogue_lines = ["需要休息一下，你先和别人玩吧~"]
			_show_current_line()
			return
	
	# 每个成员不同的对话池（可继续扩展）
	match id:
		"lily":
			dialogue_lines = [
				"嘿！你今天看起来精神不错嘛~",
				"我最近在写新歌，你要不要听听？",
				"下次一起去排练室吧？",
				"跟你聊天总是很开心呢！"
				
			]
		"kira":
			dialogue_lines = [
				"哦？你来找我啊……",
				"最近乐队氛围怎么样？",
				"我还在练习指法……有点累。",
                "谢谢你一直支持我。"
			]
		"old_nail":
			dialogue_lines = [
				"小子，来啦？",
				"酒吧今天客人不少啊。",
				"好好干，咱们乐队会越来越强的。",
                "有空一起喝一杯？"
			]
		_:
			dialogue_lines = [
				"你好啊！",
				"最近过得怎么样？",
				"很高兴见到你。"
			   
			]
	
	# 随机打乱顺序，让每次点击都不一样
	dialogue_lines.shuffle()
	_show_current_line()

func _show_current_line():
	if current_line < dialogue_lines.size():
		dialogue_text.text = dialogue_lines[current_line]
	else:
		_finish_dialogue()

func _input(event):
	if visible and event is InputEventMouseButton and event.pressed:
		current_line += 1
		_show_current_line()

func _finish_dialogue():
	visible = false
	queue_free()
