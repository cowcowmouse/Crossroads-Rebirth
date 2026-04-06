extends Node2D

# Set this constant before game start
const in_edit_mode: bool = false
var current_level_name = "RHYTHM_HELL"

# Time it takes for falling key to reach critical spot
var fk_fall_time: float = 2.2
var fk_output_arr = [[], [], [], []]

# ========== 结算面板相关 ==========
# 结算面板预制体，路径必须和你实际的文件位置一致
@onready var result_panel_scene = preload("res://project/scenes/minigame/ResultPanel.tscn")
var result_panel: Control
# 修正节点路径：从父节点GameLevel里找同级的GameUI节点
@onready var game_ui = get_parent().get_node("GameUI")

var level_info = {
	"RHYTHM_HELL" = {
		"fk_times": "[[2.52533321380615, 6.55733375549316, 10.5573337554932, 14.5040004730225, 14.6533325195313, 15.5493324279785, 15.6986663818359, 15.9333332061768, 16.0719993591309, 19.76266746521, 22.8666675567627, 27.2293327331543, 30.823998260498, 34.5786674499512, 34.7173316955566, 35.0159996032715, 35.282666015625, 35.4640014648437, 35.6453330993652, 35.9333351135254, 36.1466682434082, 36.2533348083496, 36.3706672668457, 40.4133346557617], [3.03733329772949, 7.0586669921875, 7.28266696929932, 11.5600002288818, 11.8053329467773, 14.9200008392334, 15.0479991912842, 15.282666015625, 15.5813339233398, 16.296000289917, 18.8026664733887, 19.9119995117188, 20.0826671600342, 23.2080009460449, 23.346667098999, 23.9226673126221, 24.3279998779297, 26.792000579834, 27.7200000762939, 28.1253326416016, 31.1759994506836, 31.858666229248, 34.8453338623047, 34.9839981079102, 35.1546676635742, 35.3999984741211, 35.5706680297852, 35.741333770752, 35.8693321228027, 36.0186660766602, 36.1359985351562, 36.2533348083496], [3.56000022888184, 7.54933338165283, 10.7919996261597, 11.0266664505005, 14.5040004730225, 14.6533325195313, 15.5600002288818, 15.7093341827393, 15.9333332061768, 16.0826671600342, 19.0373332977295, 19.1973331451416, 19.3893325805664, 20.274666595459, 20.4026668548584, 23.5493324279785, 23.7093341827393, 24.1146667480469, 27.0159996032715, 27.9333332061768, 31.5280006408691, 32.231999206543], [4.07199983596802, 8.06133346557617, 12.0613334655762, 26.5893333435059, 27.4639995574951]]",
		"music": load("res://project/audio/bgm/Rhythm Hell.wav")
	}
}

# Called when the node enters the scene tree for the first time.
func _ready():
	# 游戏启动就实例化结算面板，避免音乐结束时才创建出问题
	result_panel = result_panel_scene.instantiate()
	# 把结算面板加到根节点，保证层级最高
	get_tree().root.add_child(result_panel)
	
	$MusicPlayer.stream = level_info.get(current_level_name).get("music")
	$MusicPlayer.play()
	
	if in_edit_mode:
		Signals.KeyListenerPress.connect(KeyListenerPress)
	else:
		var fk_times = level_info.get(current_level_name).get("fk_times")
		var fk_times_arr = str_to_var(fk_times)
		
		var counter: int = 0
		for key in fk_times_arr:
			
			var button_name: String = ""
			match counter:
				0:
					button_name = "input_Left"
				1:
					button_name = "input_Down"
				2:
					button_name = "input_Up"
				3:
					button_name = "input_Right"
			
			for delay in key:
				SpawnFallingKey(button_name, delay)
			
			counter += 1

func KeyListenerPress(button_name: String, array_num: int):
	fk_output_arr[array_num].append($MusicPlayer.get_playback_position() - fk_fall_time)

func SpawnFallingKey(button_name: String, delay: float):
	await get_tree().create_timer(delay).timeout
	Signals.CreateFallingKey.emit(button_name)

# 音乐结束，弹出结算面板
func _on_music_player_finished():
	print(fk_output_arr)
	
	# ========== 空值检查，避免报错 ==========
	# 检查GameUI节点是否存在
	if not is_instance_valid(game_ui):
		print("错误：找不到GameUI节点！请检查节点名和路径是否正确")
		return
	# 检查结算面板是否存在
	if not is_instance_valid(result_panel):
		print("错误：结算面板实例化失败！请检查ResultPanel.tscn的路径")
		return
	
	# 获取最终得分和最高连击
	var final_score = game_ui.get_final_score()
	var max_combo = game_ui.get_max_combo()
	
	# 打印调试信息，方便排查问题
	print("最终得分：", final_score, " | 最高连击：", max_combo)
	
	# 显示结算面板
	result_panel.show_result(final_score, max_combo)
