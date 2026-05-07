extends Node

var bgm_player: AudioStreamPlayer
var current_bgm: AudioStream
var bgm_locked := false

# 直接跑最终演出场景时，不自动播默认酒吧BGM
const FINAL_PERFORMANCE_SCENE_PATH := "res://project/scenes/minigame/final_performance.tscn"
const DEFAULT_BGM_PATH := "res://project/audio/bgm/Bar.mp3"
const UI_CLICK_PATH := "res://project/audio/sfx/ui_click.wav"

# ===================== UI点击音效 =====================
var ui_click_player: AudioStreamPlayer
var ui_click_stream: AudioStream


func _ready():
	# 创建背景音乐播放器
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	add_child(bgm_player)

	# 创建UI点击音效播放器
	ui_click_player = AudioStreamPlayer.new()
	ui_click_player.name = "UIClickPlayer"
	add_child(ui_click_player)

	# 连接循环回调
	bgm_player.finished.connect(_on_bgm_finished)

	# 预加载默认BGM
	if ResourceLoader.exists(DEFAULT_BGM_PATH):
		current_bgm = load(DEFAULT_BGM_PATH)
		bgm_player.stream = current_bgm
	else:
		print("背景音乐文件不存在: ", DEFAULT_BGM_PATH)

	# 预加载UI点击音效
	if ResourceLoader.exists(UI_CLICK_PATH):
		ui_click_stream = load(UI_CLICK_PATH)
		ui_click_player.stream = ui_click_stream
	else:
		print("UI点击音效文件不存在: ", UI_CLICK_PATH)

	# 先只加载音量，不立刻播
	_load_saved_volume()

	# 延后一帧判断当前场景，避免单独跑 final_performance 时先响默认BGM
	call_deferred("_deferred_boot_bgm")


func _deferred_boot_bgm():
	await get_tree().process_frame

	if _should_block_default_bgm():
		stop_bgm()
		return

	update_bgm()


func _should_block_default_bgm() -> bool:
	if bgm_locked:
		return true

	var current_scene = get_tree().current_scene
	if current_scene == null:
		return false

	var scene_path := ""
	if "scene_file_path" in current_scene:
		scene_path = current_scene.scene_file_path

	if scene_path == FINAL_PERFORMANCE_SCENE_PATH:
		return true

	if current_scene.name.to_lower().contains("finalperformance"):
		return true

	return false


func _load_saved_volume():
	var config = ConfigFile.new()
	var volume = 0.8

	if config.load("user://settings.cfg") == OK:
		volume = config.get_value("audio", "bgm_volume", 0.8)

	if bgm_player:
		bgm_player.volume_db = linear_to_db(volume)

	# UI点击音效默认跟随BGM音量，但更轻一点
	_update_ui_click_volume(volume)


func _on_bgm_finished():
	if bgm_locked:
		return
	if _should_block_default_bgm():
		return
	if bgm_player and current_bgm:
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


# 不传路径时播放当前 current_bgm
# 传路径时切换到新的BGM并播放
func play_bgm(bgm_path: String = ""):
	if bgm_locked:
		return

	if bgm_path != "":
		if not ResourceLoader.exists(bgm_path):
			print("背景音乐文件不存在: ", bgm_path)
			return
		current_bgm = load(bgm_path)
		bgm_player.stream = current_bgm
	elif current_bgm:
		bgm_player.stream = current_bgm
	else:
		return

	if bgm_player:
		bgm_player.stream_paused = false
		bgm_player.play()


func stop_bgm():
	if bgm_player:
		bgm_player.stream_paused = false
		bgm_player.stop()


func pause_bgm():
	if bgm_player and bgm_player.playing:
		bgm_player.stream_paused = true


func resume_bgm():
	if bgm_locked:
		return
	if bgm_player and bgm_player.stream_paused:
		bgm_player.stream_paused = false


func lock_bgm():
	bgm_locked = true
	stop_bgm()


func unlock_bgm(play_default_after_unlock: bool = false):
	bgm_locked = false
	if play_default_after_unlock:
		play_bgm()
# ===================== 按人情/商业/艺术切换背景音乐 =====================

func update_bgm():
	
	if bgm_locked:
		return
	
	var art = ResourceManager.get_art_weight()
	var business = ResourceManager.get_business_weight()
	var human = ResourceManager.get_human_weight()
	
	var bgm_path = "res://project/audio/bgm/Bar.mp3"  # 默认
	
	# 规则1：全部 ≤10 → 默认
	if art <= 10 and business <= 10 and human <= 10:
		bgm_path = "res://project/audio/bgm/Bar.mp3"
	
	# 规则2：三个数值完全相同 → 优先商业
	elif art == business and business == human:
		if business >= 50:
			bgm_path = "res://project/audio/bgm/Bar_commerce1.mp3"
		else:
			bgm_path = "res://project/audio/bgm/Bar_Commerce2.mp3"
	
	# 规则3：取数值最高的那个方向
	else:
		var max_value = maxi(art, maxi(business, human))
		
		if max_value == business:
			bgm_path = "res://project/audio/bgm/Bar_commerce1.mp3" if business >= 50 else "res://project/audio/bgm/Bar_Commerce2.mp3"
		elif max_value == human:
			bgm_path = "res://project/audio/bgm/Bar_emotion1.mp3" if human >= 50 else "res://project/audio/bgm/Bar_emotion2.mp3"
		elif max_value == art:
			bgm_path = "res://project/audio/bgm/Bar_art1.mp3" if art >= 50 else "res://project/audio/bgm/Bar_art2.mp3"
	
	# 切换并播放
	if ResourceLoader.exists(bgm_path):
		play_bgm(bgm_path)
		print("🎵 BGM已切换 → ", bgm_path.get_file(), " | 人情:", human, " 商业:", business, " 艺术:", art)
	else:
		push_warning("❌ BGM文件不存在: ", bgm_path)
