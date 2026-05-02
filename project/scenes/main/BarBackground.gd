extends Sprite2D

@onready var resource_manager = get_node_or_null("/root/ResourceManager")

func _ready():
	# 加入组，供 ResourceManager 调用
	add_to_group("bar_background")
	
	# 确保居中显示（根据你的场景需要可自行调整）
	centered = true
	
	# 延迟一帧刷新，确保 ResourceManager 已就绪
	call_deferred("update_background")

func update_background():
	if not resource_manager:
		push_warning("BarBackground: 无法找到 ResourceManager")
		return
	
	var money = resource_manager.get_money()
	var cohesion = resource_manager.get_cohesion()
	var creativity = resource_manager.get_creativity()
	
	var filename = "bar.jpg"  # 默认背景
	
	# 严格按照你指定的优先级判断
	if cohesion <= 20:
		filename = "bar7.jpg"
	elif cohesion >= 50:
		filename = "bar.jpg"
	
	if creativity <= 20:
		filename = "bar6.jpg"
	elif creativity >= 50:
		filename = "bar5.jpg"
		
	if money >= 10000:
		filename = "bar2.jpg"
	elif money <= 1000:
		filename = "bar3.jpg"
	
	var path = "res://project/scenes/main/" + filename
	
	# 安全加载图片
	if ResourceLoader.exists(path):
		texture = load(path)
		print("✅ 主场景背景已切换为：", filename)
	else:
		push_error("❌ 主场景背景图片不存在：", path)
