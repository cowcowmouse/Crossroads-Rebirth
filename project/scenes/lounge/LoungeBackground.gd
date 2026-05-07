extends Sprite2D

@onready var resource_manager = get_node_or_null("/root/ResourceManager")

func _ready():
	add_to_group("lounge_background")
	centered = true
	call_deferred("update_background")
	print("✅ LoungeBackground 初始化完成（新规则）")

func update_background():
	if not resource_manager:
		print("❌ LoungeBackground: 无法找到 ResourceManager")
		return
	
	var art = resource_manager.get_art_weight()
	var business = resource_manager.get_business_weight()
	var human = resource_manager.get_human_weight()
	
	var filename = "lounge.jpg"  # 默认
	
	# 规则1：所有数值都在10以下 → 默认
	if art <= 10 and business <= 10 and human <= 10:
		filename = "lounge.jpg"
	
	# 规则2：三个数值完全相同 → 优先商业
	elif art == business and business == human:
		if business >= 50:
			filename = "lounge3.jpg"   # 高商业
		else:
			filename = "lounge4.jpg"   # 低商业
	
	# 规则3：取数值最高的那个方向
	else:
		var max_value = maxi(art, maxi(business, human))
		
		if max_value == business:
			filename = "lounge3.jpg" if business >= 50 else "lounge4.jpg"
		elif max_value == human:
			filename = "lounge2.jpg" if human >= 50 else "lounge6.jpg"
		elif max_value == art:
			filename = "lounge5.jpg" if art >= 50 else "lounge7.jpg"
	
	var path = "res://project/scenes/lounge/images/" + filename   # ← 注意路径
	
	if ResourceLoader.exists(path):
		texture = load(path)
		print("✅ 休息室背景切换 → ", filename, 
			  " | 人情:", human, " 商业:", business, " 艺术:", art)
	else:
		push_warning("❌ 休息室背景图片不存在: ", path)
