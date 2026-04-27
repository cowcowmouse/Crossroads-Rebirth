# MemberAvatar.gd
extends Area2D

@export var member_id: String = ""

@onready var sprite = $Sprite2D   # 新增：引用子节点 Sprite2D

func _ready():
	if member_id == "":
		return
	
	# 加载全身图片
	var path = "res://project/assets/character/fullbody/%s.jpg" % member_id
	
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
		print("已加载图片：", member_id)
	else:
		print("缺少图片: ", path)
	
	# 让它可以点击
	input_pickable = true
	
	# 添加碰撞形状（防止穿模 + 可点击）
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(80, 160)        # 根据你的图片大小调整
	collision.shape = shape
	add_child(collision)
	
func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("点击了已入队成员：", member_id)
		# 后面可以在这里调用对话系统
