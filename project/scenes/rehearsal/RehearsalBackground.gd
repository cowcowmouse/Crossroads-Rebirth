# RehearsalBackground.gd
extends Sprite2D

@onready var resource_manager = get_node_or_null("/root/ResourceManager")

func _ready():
	add_to_group("rehearsal_background")   # 重要：让 ResourceManager 能找到
	centered = true
	call_deferred("update_background")

# 根据当前资源数值实时切换背景
func update_background():
	if not resource_manager:
		print("❌ ResourceManager 未找到")
		return

	var money = resource_manager.get_resource_value("money") if resource_manager.has_method("get_resource_value") else 0
	var cohesion = resource_manager.get_cohesion() if resource_manager.has_method("get_cohesion") else 0
	var creativity = resource_manager.get_creativity() if resource_manager.has_method("get_creativity") else 0

	var filename = "rehearsal.jpg"  # 默认

	# 按你指定的优先级判断（后面的条件会覆盖前面的）
	if cohesion <= 20:
		filename = "rehearsal6.jpg"
	elif cohesion >= 50:
		filename = "rehearsal7.jpg"

	if creativity <= 20:
		filename = "rehearsal2.jpg"
	elif creativity >= 50:
		filename = "rehearsal4.jpg"
		
	if money >= 10000:
		filename = "rehearsal5.jpg"
	elif money <= 1000:
		filename = "rehearsal3.jpg"

	var path = "res://project/scenes/rehearsal/images/" + filename

	if ResourceLoader.exists(path):
		texture = load(path)
		print("✅ 排练室背景已更新 → ", filename, " (资金:", money, " 凝聚力:", cohesion, " 创造力:", creativity, ")")
	else:
		print("❌ 找不到排练室背景图: ", path)
		# 兜底使用初始图
		var fallback = "res://project/scenes/rehearsal/images/rehearsal.jpg"
		if ResourceLoader.exists(fallback):
			texture = load(fallback)
