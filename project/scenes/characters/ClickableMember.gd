extends Node2D

var member_id: String = ""

func _ready():
	print("✅ ClickableMember _ready 执行")

func setup(id: String, portrait_path: String):
	member_id = id
	print("✅ setup 被调用！成员ID = ", id)
	
	# 加载立绘
	var portrait_sprite = get_node_or_null("Portrait") as Sprite2D
	if portrait_sprite and ResourceLoader.exists(portrait_path):
		portrait_sprite.texture = load(portrait_path)
		portrait_sprite.scale = Vector2(0.4, 0.4)   # 控制人物大小
		print("✅ 立绘加载成功")
	else:
		print("❌ 立绘加载失败")

	# 强制设置碰撞体大小（关键修复！）
	var click_area = get_node_or_null("ClickArea") as Area2D
	var collision = get_node_or_null("ClickArea/CollisionShape2D") as CollisionShape2D
	if click_area and collision:
		click_area.input_pickable = true
		var shape = RectangleShape2D.new()
		shape.size = Vector2(80, 120)          # 碰撞体原始大小
		collision.shape = shape
		click_area.connect("input_event", _on_input_event)
		print("✅ ClickArea + 碰撞体已正确设置")
	else:
		print("❌ 找不到 ClickArea 或 CollisionShape2D！")

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("🎯 【点击成功！】成员ID = ", member_id)
		
		var dialogue_scene = preload("res://project/scenes/ui/DialoguePanel.tscn")
		if dialogue_scene:
			var panel = dialogue_scene.instantiate()
			get_tree().current_scene.add_child(panel)
			
			var lines = [
				member_id.to_upper() + "：嘿！你终于来啦！",
				"最近乐队怎么样？",
				"我最近在练习新歌……",
                "跟你聊天心情都变好了！"
			]
			panel.show_dialogue(member_id, "res://project/assets/character/fullbody/" + member_id + ".png", lines)	
