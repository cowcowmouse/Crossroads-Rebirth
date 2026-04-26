extends Control

@onready var background = $Background
@onready var dark_overlay = $DarkOverlay
@onready var dialog_box = $DialogBox
@onready var text_label = $DialogBox/TextLabel
@onready var next_button = $DialogBox/NextButton
@onready var ending_name_panel = $EndingNamePanel

var current_dialogues: Array = []
var current_index: int = 0
var ending_key: String = ""

func _ready():
	next_button.pressed.connect(_on_next_pressed)
	ending_name_panel.visible = false

func setup(key: String):
	print("=== 结局对话框 setup 开始 ===")
	print("结局 key: ", key)
	
	ending_key = key
	
	var ending_manager = get_node("/root/EndingManager")
	if not ending_manager:
		print("错误: EndingManager 未找到")
		return
	
	var config = ending_manager.get_ending(key)
	print("获取到的配置: ", config)
	
	# 设置背景
	if config.get("has_bg", false) and config.get("bg", "") != "":
		var bg_path = config["bg"]
		if ResourceLoader.exists(bg_path):
			background.texture = load(bg_path)
			background.visible = true
	else:
		background.visible = false
	
	# 设置半透明遮罩
	if dark_overlay:
		dark_overlay.color = Color(0, 0, 0, 0.7)
	
	# 播放片尾曲
	if config.get("has_song", false):
		_play_ending_song()
	
	# 构建对话列表
	_build_dialogues(config)
	print("对话列表长度: ", current_dialogues.size())
	for i in range(current_dialogues.size()):
		print("  第", i, "句: ", current_dialogues[i])
	
	# 显示第一句
	_show_dialogue()

func _build_dialogues(config: Dictionary):
	current_dialogues = []
	
	var opening = config.get("opening", "")
	if opening != "":
		current_dialogues.append(opening)
	
	var middle_recovery = config.get("middle_recovery", "")
	if middle_recovery != "":
		current_dialogues.append(middle_recovery)
	
	var middle_result = config.get("middle_result", "")
	if middle_result != "":
		current_dialogues.append(middle_result)
	
	var closing = config.get("closing", "")
	if closing != "":
		current_dialogues.append(closing)

func _show_dialogue():
	print("显示对话: 索引 ", current_index, "/", current_dialogues.size())
	if current_index < current_dialogues.size():
		text_label.text = current_dialogues[current_index]
	else:
		print("对话结束，显示结局名称")
		_show_ending_name()

func _on_next_pressed():
	print("点击下一句")
	current_index += 1
	_show_dialogue()

func _show_ending_name():
	print("显示结局名称面板")
	var ending_manager = get_node("/root/EndingManager")
	if not ending_manager:
		print("错误: EndingManager 未找到")
		return
	
	var config = ending_manager.get_ending(ending_key)
	var title = config.get("title", "未知结局")
	print("结局标题: ", title)
	
	if ending_name_panel:
		ending_name_panel.visible = true
		if ending_name_panel.has_method("setup"):
			ending_name_panel.setup(title)
		else:
			print("警告: ending_name_panel 没有 setup 方法")
	
	if dialog_box:
		dialog_box.visible = false
	if next_button:
		next_button.visible = false

func _play_ending_song():
	var song_path = ""
	match ending_key.split("_")[0]:
		"art":
			song_path = "res://audio/ending/art_ending.ogg"
		"business":
			song_path = "res://audio/ending/business_ending.ogg"
		"human":
			song_path = "res://audio/ending/human_ending.ogg"
		_:
			return
	
	if ResourceLoader.exists(song_path):
		var audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
		audio_player.stream = load(song_path)
		audio_player.play()
