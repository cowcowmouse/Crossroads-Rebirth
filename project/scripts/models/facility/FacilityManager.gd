extends Node

var facility_data: Dictionary = {}

func _ready():
	print("FacilityManager 的 _ready 已执行")
	_load_facility_data()
	ResourceManager.refresh_current_scene_topbar()

func _load_facility_data():
	var path = "res://project/data/facilities/facilities.json"
	print("准备读取路径：", path)

	if not FileAccess.file_exists(path):
		push_error("找不到设施配置文件: " + path)
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	print("读取到的原始文本：", text)

	var json = JSON.new()
	var err = json.parse(text)
	print("JSON 解析结果 err =", err)

	if err != OK:
		push_error("facilities.json 解析失败")
		return

	facility_data = json.data
	print("设施数据已加载：", facility_data)

func get_facility_info(facility_type: String) -> Dictionary:
	if not facility_data.has(facility_type):
		return {}

	var data = facility_data[facility_type].duplicate()
	data["level"] = ResourceManager.get_facility_level(facility_type)
	return data

func get_facility_level(facility_type: String) -> int:
	return ResourceManager.get_facility_level(facility_type)

func get_upgrade_cost(facility_type: String) -> int:
	if not facility_data.has(facility_type):
		return -1

	var data = facility_data[facility_type]
	var current_level: int = ResourceManager.get_facility_level(facility_type)
	var max_level: int = int(data["max_level"])

	if current_level >= max_level:
		return -1

	return int(data["costs"][current_level + 1])

func can_upgrade(facility_type: String) -> bool:
	if not facility_data.has(facility_type):
		return false

	var cost = get_upgrade_cost(facility_type)
	if cost < 0:
		return false

	if ResourceManager.get_resource_value(Constants.RES_MONEY) < cost:
		return false

	if not ResourceManager.can_consume_action_points(1):
		return false

	return true

func upgrade_facility(facility_type: String) -> Dictionary:
	var result := {
		"success": false,
		"reason": "",
		"new_level": -1
	}

	if not facility_data.has(facility_type):
		result["reason"] = "设施不存在"
		return result

	var data = facility_data[facility_type]
	var current_level: int = ResourceManager.get_facility_level(facility_type)
	var max_level: int = int(data["max_level"])

	if current_level >= max_level:
		result["reason"] = "已满级"
		return result

	var cost = int(data["costs"][current_level + 1])

	if ResourceManager.get_resource_value(Constants.RES_MONEY) < cost:
		result["reason"] = "资金不足"
		return result

	if not ResourceManager.can_consume_action_points(1):
		result["reason"] = "行动点不足"
		return result

	# 扣钱
	if not ResourceManager.add_money(-cost):
		result["reason"] = "资金不足"
		return result

	# 扣行动点
	if not ResourceManager.consume_action_point(1):
		ResourceManager.add_money(cost)
		result["reason"] = "行动点不足"
		return result

	# 升级设施等级（统一写回 ResourceManager）
	var next_level = current_level + 1
	ResourceManager.set_facility_level(facility_type, next_level)

	# 刷新当前场景顶部UI
	ResourceManager.refresh_current_scene_topbar()

	result["success"] = true
	result["new_level"] = next_level
	return result
