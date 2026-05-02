# LoungeBackground.gd
extends Sprite2D

@onready var resource_manager = get_node_or_null("/root/ResourceManager")

func _ready():
	add_to_group("lounge_background")
	centered = true
	call_deferred("update_background")

# 核心：根据当前资源数值决定背景
func update_background():
	if not resource_manager:
		print("❌ ResourceManager 未找到")
		return

	var money = resource_manager.get_resource_value(Constants.RES_MONEY) if resource_manager.has_method("get_resource_value") else 0
	var cohesion = resource_manager.get_cohesion() if resource_manager.has_method("get_cohesion") else 0
	var creativity = resource_manager.get_creativity() if resource_manager.has_method("get_creativity") else 0

	var filename = "lounge.jpg"  # 默认

	# 按你指定的顺序判断（后面的条件会覆盖前面的）
	
	if cohesion <= 20:
		filename = "lounge6.jpg"
	elif cohesion >= 50:
		filename = "lounge2.jpg"

	if creativity <= 20:
		filename = "lounge7.jpg"
	elif creativity >= 50:
		filename = "lounge5.jpg"
		
	if money >= 10000:
		filename = "lounge3.jpg"
	elif money <= 1000:
		filename = "lounge4.jpg"

	var path = "res://project/scenes/lounge/images/" + filename

	if ResourceLoader.exists(path):
		texture = load(path)
		print("✅ 休息室背景已更新 → ", filename, " (资金:", money, " 凝聚力:", cohesion, " 创造力:", creativity, ")")
	else:
		print("❌ 找不到图片: ", path)
