extends Sprite2D

@onready var resource_manager = get_node_or_null("/root/ResourceManager")

func _ready():
	add_to_group("bar_background")
	centered = true
	call_deferred("update_background")
	print("✅ BarBackground 初始化完成（新规则）")

func update_background():
	if not resource_manager:
		print("❌ BarBackground: 无法找到 ResourceManager")
		return
	
	var art = resource_manager.get_art_weight()
	var business = resource_manager.get_business_weight()
	var human = resource_manager.get_human_weight()
	
	var filename = "bar.jpg"  # 默认
	
	# 规则1：所有数值都在10以下 → 默认
	if art <= 10 and business <= 10 and human <= 10:
		filename = "bar.jpg"
	
	# 规则2：所有数值相同 → 优先商业
	elif art == business and business == human:
		if business >= 50:
			filename = "bar2.jpg"   # 高商业
		else:
			filename = "bar3.jpg"   # 低商业
	
	# 规则3：取数值最高的那个方向
	else:
		var max_value = maxi(art, maxi(business, human))
		
		if max_value == business:
			filename = "bar2.jpg" if business >= 50 else "bar3.jpg"
		elif max_value == human:
			filename = "bar4.jpg" if human >= 50 else "bar7.jpg"
		elif max_value == art:
			filename = "bar5.jpg" if art >= 50 else "bar6.jpg"
	
	var path = "res://project/scenes/main/" + filename
	
	if ResourceLoader.exists(path):
		texture = load(path)
		print("✅ 酒吧背景切换 → ", filename, 
			  " | 人情:", human, " 商业:", business, " 艺术:", art)
	else:
		push_warning("❌ 背景图片不存在: ", path)
