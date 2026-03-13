extends Node2D

# ===================== 箭头节点绑定 =====================
@onready var arrow_left = get_node_or_null("ArrowLeft")
@onready var arrow_right = get_node_or_null("ArrowRight")

func _ready():
	print("当前脚本附加的节点：", self.name)
	print("所有子节点：")
	for child in get_children():
		print("  - ", child.name)
	
	# 如果没找到，尝试用find_child再找一次
	if not arrow_left:
		arrow_left = find_child("ArrowLeft", true, false)
	if not arrow_right:
		arrow_right = find_child("ArrowRight", true, false)
	
	# ===== 连接箭头按钮 =====
	print("\n===== 连接按钮 =====")
	
	# 左箭头
	if arrow_left:
		print("左箭头找到，类型：", arrow_left.get_class())
		if arrow_left.has_signal("pressed"):
			arrow_left.pressed.connect(_on_arrow_left_pressed)
			print("左箭头连接成功")
		elif arrow_left.has_signal("gui_input"):
			arrow_left.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_on_arrow_left_pressed()
			)
			print("左箭头连接成功")
	else:
		print("左箭头未找到")
	
	# 右箭头
	if arrow_right:
		print("右箭头找到，类型：", arrow_right.get_class())
		if arrow_right.has_signal("pressed"):
			arrow_right.pressed.connect(_on_arrow_right_pressed)
			print("右箭头连接成功")
		elif arrow_right.has_signal("gui_input"):
			arrow_right.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_on_arrow_right_pressed()
			)
			print("右箭头连接成功")
	else:
		print("右箭头未找到")
	
	print("====================\n")

func _on_arrow_left_pressed():
	print("左箭头被点击")
	get_tree().change_scene_to_file("res://project/scenes/lounge/lounge_scene.tscn")

func _on_arrow_right_pressed():
	print("右箭头被点击")
	get_tree().change_scene_to_file("res://project/scenes/rehearsal/rehearsal_scene.tscn")
