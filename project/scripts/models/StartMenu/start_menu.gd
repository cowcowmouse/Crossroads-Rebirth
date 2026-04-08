extends Control

@onready var start_button = $StartButton
@onready var settings_button = $SettingsButton
@onready var quit_button = $QuitButton
@onready var settings_panel = $SettingsPanel
@onready var volume_slider = $SettingsPanel/VolumeSlider
@onready var close_button = $SettingsPanel/CloseButton

func _ready():
	# 连接按钮信号
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	close_button.pressed.connect(_on_close_settings_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	
	# 初始隐藏设置面板
	settings_panel.visible = false
	
	# 加载保存的音量设置
	_load_volume_setting()

func _on_start_pressed():
	print("开始游戏")
	get_tree().change_scene_to_file("res://project/scenes/cutscene/opening_scene.tscn")

func _on_settings_pressed():
	print("打开设置面板")
	settings_panel.visible = true

func _on_close_settings_pressed():
	print("关闭设置面板")
	settings_panel.visible = false

func _on_quit_pressed():
	print("退出游戏")
	get_tree().quit()

func _on_volume_changed(value: float):
	print("音量变化: ", value)
	AudioManager.set_bgm_volume(value)
	_save_volume_setting(value)

func _save_volume_setting(value: float):
	var config = ConfigFile.new()
	config.set_value("audio", "bgm_volume", value)
	config.save("user://settings.cfg")

func _load_volume_setting():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var volume = config.get_value("audio", "bgm_volume", 0.8)
		volume_slider.value = volume
		AudioManager.set_bgm_volume(volume)
	else:
		volume_slider.value = 0.8
		AudioManager.set_bgm_volume(0.8)
