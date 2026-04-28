# LoungeBackground.gd
extends Sprite2D

@onready var facility_manager = get_node_or_null("/root/FacilityManager")

func _ready():
	add_to_group("lounge_background")     # 让 FacilityManager 能找到
	call_deferred("update_background")

func update_background():
	if not facility_manager:
		print("❌ FacilityManager 未找到")
		return
	
	var level = facility_manager.get_facility_level("lounge")
	level = clamp(level, 1, 5)   # 你的等级从1开始
	
	# 根据你的命名规则生成文件名
	var filename = ""
	if level == 1:
		filename = "lounge.jpg"
	else:
		filename = "lounge%d.jpg" % level
	
	var path = "res://project/scenes/lounge/images/" + filename
	
	print("🔄 休息室尝试切换背景 → 等级 ", level, " 文件: ", filename)
	
	if ResourceLoader.exists(path):
		texture = load(path)
		print("✅ 休息室背景成功切换为第 ", level, " 级 (", filename, ")")
	else:
		print("❌ 找不到背景图: ", path)
		# 降级显示初始图作为兜底
		var fallback = "res://project/scenes/lounge/images/lounge.jpg"
		if ResourceLoader.exists(fallback):
			texture = load(fallback)
			print("⚠️ 使用初始 lounge.jpg 作为兜底")
