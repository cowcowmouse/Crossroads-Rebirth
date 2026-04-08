extends Node

var bgm_player: AudioStreamPlayer
var current_bgm: AudioStream

func _ready():
	# 创建背景音乐播放器
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	
	# 加载背景音乐
	var bgm_path = "res://project/audio/bgm/Bar.mp3"  # 替换为你的音乐路径
	if ResourceLoader.exists(bgm_path):
		current_bgm = load(bgm_path)
		bgm_player.stream = current_bgm
		bgm_player.finished.connect(_on_bgm_finished)
		
		# 加载保存的音量并播放
		_load_volume_and_play()
	else:
		print("背景音乐文件不存在: ", bgm_path)

func _load_volume_and_play():
	var config = ConfigFile.new()
	var volume = 0.8
	if config.load("user://settings.cfg") == OK:
		volume = config.get_value("audio", "bgm_volume", 0.8)
	
	bgm_player.volume_db = linear_to_db(volume)
	bgm_player.play()

func _on_bgm_finished():
	# 循环播放
	bgm_player.play()

func set_bgm_volume(value: float):
	if bgm_player:
		bgm_player.volume_db = linear_to_db(value)

func linear_to_db(linear: float) -> float:
	if linear <= 0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)

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
