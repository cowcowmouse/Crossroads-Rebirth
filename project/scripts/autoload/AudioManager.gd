extends Node

var bgm_player: AudioStreamPlayer
var current_bgm: AudioStream

# ===================== UI点击音效 =====================
var ui_click_player: AudioStreamPlayer
var ui_click_stream: AudioStream

func _ready():
	# 创建背景音乐播放器
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)

	# 创建UI点击音效播放器
	ui_click_player = AudioStreamPlayer.new()
	add_child(ui_click_player)
	
	# 加载背景音乐
	var bgm_path = "res://project/audio/bgm/Bar.mp3"  # 替换为你的音乐路径
	if ResourceLoader.exists(bgm_path):
		current_bgm = load(bgm_path)
		bgm_player.stream = current_bgm
		bgm_player.finished.connect(_on_bgm_finished)
	else:
		print("背景音乐文件不存在: ", bgm_path)

	# 加载UI点击音效
	var ui_click_path = "res://project/audio/sfx/ui_click.wav"  # 替换为你的按钮音效路径
	if ResourceLoader.exists(ui_click_path):
		ui_click_stream = load(ui_click_path)
		ui_click_player.stream = ui_click_stream
	else:
		print("UI点击音效文件不存在: ", ui_click_path)
		
	# 加载保存的音量并播放
	_load_volume_and_play()

func _load_volume_and_play():
	var config = ConfigFile.new()
	var volume = 0.8
	if config.load("user://settings.cfg") == OK:
		volume = config.get_value("audio", "bgm_volume", 0.8)
	
	if bgm_player:
		bgm_player.volume_db = linear_to_db(volume)
		if current_bgm:
			bgm_player.play()
	
	# UI点击音效默认跟随BGM音量，但更轻一点
	_update_ui_click_volume(volume)

func _on_bgm_finished():
	# 循环播放
	bgm_player.play()

func set_bgm_volume(value: float):
	if bgm_player:
		bgm_player.volume_db = linear_to_db(value)
	
	# UI点击音效同步更新音量
	_update_ui_click_volume(value)

func _update_ui_click_volume(master_value: float):
	if ui_click_player:
		var ui_click_volume = clamp(master_value * 0.45, 0.0, 1.0)
		ui_click_player.volume_db = linear_to_db(ui_click_volume)

func linear_to_db(linear: float) -> float:
	if linear <= 0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)

# 播放UI点击音效
func play_ui_click():
	if not ui_click_player:
		return
	if ui_click_stream == null:
		return
	
	# 连续点击时允许重新触发
	if ui_click_player.playing:
		ui_click_player.stop()
	ui_click_player.play()

func play_bgm():
	if bgm_player and not bgm_player.playing:
		bgm_player.play()

func stop_bgm():
	if bgm_player and bgm_player.playing:
		bgm_player.stop()

func pause_bgm():
	if bgm_player and bgm_player.playing:
		bgm_player.stream_paused = true

func resume_bgm():
	if bgm_player and bgm_player.stream_paused:
		bgm_player.stream_paused = false
