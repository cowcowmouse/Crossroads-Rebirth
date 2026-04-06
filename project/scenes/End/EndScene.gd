extends Control

func _ready():
	var end_label = $EndLabel
	if end_label:
		end_label.text = "游戏通关！\n你完成了18周的乐队经营之旅\n\n感谢游玩！"
	
	var restart_button = $RestartButton
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	
	var back_button = $BackButton
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _on_restart_pressed():
	print("重新开始游戏")
	
	# 重置游戏
	var game_manager = get_node("/root/GameManager")
	if game_manager:
		game_manager.reset_game()
	
	# 切换回主场景
	get_tree().change_scene_to_file("res://project/scenes/main/main.tscn")

func _on_back_pressed():
	# 返回主菜单（如果有）
	get_tree().change_scene_to_file("res://project/scenes/main/main.tscn")
