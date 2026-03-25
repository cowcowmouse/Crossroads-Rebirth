extends Node2D

@onready var reputation_label = $UILayer/TopBar/ReputationGroup/ReputationLabel
@onready var cohesion_label = $UILayer/TopBar/CohesionGroup/CohesionLabel
@onready var creativity_label = $UILayer/TopBar/CreativityGroup/CreativityLabel
@onready var memory_label = $UILayer/TopBar/MemoryGroup/MemoryLabel

func _ready():
	# 刷新顶部资源栏（资金、行动点 走 FacilityManager）
	FacilityManager._refresh_topbar()

	# 其余静态数值先手动显示
	if reputation_label:
		reputation_label.text = "声誉: 50"
	if cohesion_label:
		cohesion_label.text = "凝聚力: 30"
	if creativity_label:
		creativity_label.text = "创造力: 40"
	if memory_label:
		memory_label.text = "记忆恢复度: 20"

	# 查找返回按钮
	var back_btn = find_child("BackButton", true, false)

	if back_btn:
		print("找到返回按钮")
		if back_btn.has_signal("pressed"):
			if not back_btn.pressed.is_connected(_on_back_pressed):
				back_btn.pressed.connect(_on_back_pressed)
			print("返回按钮连接成功")
		else:
			print("返回按钮没有 pressed 信号")
	else:
		print("未找到返回按钮，请检查节点名称是否为 'BackButton'")

func _on_back_pressed():
	print("返回主场景")
	get_tree().change_scene_to_file("res://project/scenes/main/main.tscn")
