extends Node

var money: int = 1000
var action_points: int = 3
var facility_data: Dictionary = {}



func _ready():
	print("FacilityManager 的 _ready 已执行")
	_load_facility_data()
	_refresh_topbar()

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

func _refresh_topbar():
	var current_scene = get_tree().current_scene
	if not current_scene:
		return

	var money_label = current_scene.get_node_or_null("UILayer/TopBar/MoneyGroup/MoneyLabel")
	var action_point_label = current_scene.get_node_or_null("UILayer/TopBar/ActionPointGroup/ActionPointLabel")

	if money_label:
		money_label.text = "资金: %d" % money

	if action_point_label:
		action_point_label.text = "行动点: %d/3" % action_points

func get_facility_info(facility_type: String) -> Dictionary:
	if not facility_data.has(facility_type):
		return {}
	return facility_data[facility_type]

func get_facility_level(facility_type: String) -> int:
	if not facility_data.has(facility_type):
		return -1
	return facility_data[facility_type]["level"]

func get_upgrade_cost(facility_type: String) -> int:
	if not facility_data.has(facility_type):
		return -1

	var data = facility_data[facility_type]
	var current_level: int = data["level"]
	var max_level: int = data["max_level"]

	if current_level >= max_level:
		return -1

	return data["costs"][current_level + 1]

func can_upgrade(facility_type: String) -> bool:
	if not facility_data.has(facility_type):
		return false

	var cost = get_upgrade_cost(facility_type)
	if cost < 0:
		return false

	if money < cost:
		return false

	if action_points <= 0:
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
	var current_level: int = data["level"]
	var max_level: int = data["max_level"]

	if current_level >= max_level:
		result["reason"] = "已满级"
		return result

	var cost = data["costs"][current_level + 1]

	if money < cost:
		result["reason"] = "资金不足"
		return result

	if action_points <= 0:
		result["reason"] = "行动点不足"
		return result

	money -= cost
	action_points -= 1
	data["level"] = current_level + 1
	facility_data[facility_type] = data

	_refresh_topbar()

	result["success"] = true
	result["new_level"] = data["level"]
	return result
