# RehearsalBackground.gd
extends Sprite2D

@onready var facility_manager = get_node_or_null("/root/FacilityManager")

func _ready():
	add_to_group("rehearsal_background")   # 重要：让 FacilityManager 能找到
	centered = true
	call_deferred("update_background")

func update_background():
	if not facility_manager:
		print("❌ FacilityManager 未找到")
		return
	
	var level = facility_manager.get_facility_level("rehearsal")
	level = clamp(level, 1, 5)
	
	var filename = "rehearsal.jpg" if level == 1 else "rehearsal%d.jpg" % level
	var path = "res://project/scenes/rehearsal/images/" + filename
	
	print("🔄 排练室尝试切换背景 → 等级 ", level, " 文件: ", filename)
	
	if ResourceLoader.exists(path):
		texture = load(path)
		print("✅ 排练室背景成功切换为第 ", level, " 级 (", filename, ")")
	else:
		print("❌ 找不到图片: ", path)
		# 兜底显示初始图
		var fallback = "res://project/scenes/rehearsal/images/rehearsal.jpg"
		if ResourceLoader.exists(fallback):
			texture = load(fallback)
