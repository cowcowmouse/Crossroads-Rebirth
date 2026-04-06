extends Node2D

# 绑定按钮（名字必须是Button，是GameLevel的直接子节点）
@onready var jump_button: Button = $Button

func _ready():
	# 绑定按钮点击
	if is_instance_valid(jump_button):
		jump_button.pressed.connect(_on_jump_pressed)
	else:
		print("错误：找不到Button节点！")

func _on_jump_pressed():
	# 【修复：强制获取树实例，避免空值，F5运行也稳定】
	var tree = get_tree()
	if not is_instance_valid(tree):
		print("错误：无法获取游戏树！")
		return

	# 场景路径必须和你文件系统完全一致！
	var result_path = "res://project/scenes/minigame/ResultPanel.tscn"
	# 延迟0.1秒跳转，确保主场景加载完成，避免画面被挡住
	await tree.create_timer(0.1).timeout
	tree.change_scene_to_file(result_path)
