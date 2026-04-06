extends Node

var facility_data: Dictionary = {}

# 主设施类型：目前设定为酒吧
const MAIN_FACILITY_TYPE := "bar"

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

# 判断是否为主设施
func _is_main_facility(facility_type: String) -> bool:
	return facility_type == MAIN_FACILITY_TYPE

# 检查主设施等级限制
# 规则：
# - 酒吧为主设施
# - 其他设施目标等级不能超过酒吧当前“正式等级”
# - 不看待生效等级，只看当前实际等级
func _check_main_facility_limit(facility_type: String) -> Dictionary:
	var result := {
		"success": true,
		"reason": ""
	}

	# 主设施自己不受这个限制
	if _is_main_facility(facility_type):
		return result

	var current_level := ResourceManager.get_facility_level(facility_type)
	var target_level := current_level + 1
	var main_level := ResourceManager.get_facility_level(MAIN_FACILITY_TYPE)

	if target_level > main_level:
		# 改成短提示，避免 UI 溢出
		result["success"] = false
		result["reason"] = "需酒吧≥%d级\n当前：%d级" % [target_level, main_level]

	return result

func can_upgrade(facility_type: String) -> bool:
	if not facility_data.has(facility_type):
		return false

	# 维修中时不可升级
	if ResourceManager.is_facility_upgrading(facility_type):
		return false

	# 主设施等级限制
	var level_limit_check = _check_main_facility_limit(facility_type)
	if not level_limit_check["success"]:
		return false

	var cost = get_upgrade_cost(facility_type)
	if cost < 0:
		return false

	# 统一走 ResourceManager 的资金判断接口
	if not ResourceManager.can_afford(cost):
		return false

	if not ResourceManager.can_consume_action_points(1):
		return false

	return true

# 获取升级失败原因（给 Panel 显示用）
func get_upgrade_fail_reason(facility_type: String) -> String:
	if not facility_data.has(facility_type):
		return "设施不存在"

	# 维修中时不可重复升级
	if ResourceManager.is_facility_upgrading(facility_type):
		return "维修中"

	var data = facility_data[facility_type]
	var current_level: int = ResourceManager.get_facility_level(facility_type)
	var max_level: int = int(data["max_level"])

	if current_level >= max_level:
		return "已满级"

	# 主设施等级限制
	var level_limit_check = _check_main_facility_limit(facility_type)
	if not level_limit_check["success"]:
		return level_limit_check["reason"]

	var cost = int(data["costs"][current_level + 1])
	var current_money = ResourceManager.get_resource_value(Constants.RES_MONEY)

	# 资金不足时显示需要的资金数值
	if not ResourceManager.can_afford(cost):
		return "资金不足\n需要：%d" % cost

	if not ResourceManager.can_consume_action_points(1):
		return "行动点不足"

	return ""

func upgrade_facility(facility_type: String) -> Dictionary:
	var result := {
		"success": false,
		"reason": "",
		"new_level": -1
	}

	if not facility_data.has(facility_type):
		result["reason"] = "设施不存在"
		return result

	# 维修中时不可重复升级
	if ResourceManager.is_facility_upgrading(facility_type):
		result["reason"] = "维修中"
		return result

	var data = facility_data[facility_type]
	var current_level: int = ResourceManager.get_facility_level(facility_type)
	var max_level: int = int(data["max_level"])

	if current_level >= max_level:
		result["reason"] = "已满级"
		return result

	# 主设施等级限制
	var level_limit_check = _check_main_facility_limit(facility_type)
	if not level_limit_check["success"]:
		result["reason"] = level_limit_check["reason"]
		return result

	var cost = int(data["costs"][current_level + 1])

	# 统一走 ResourceManager 的资金判断接口
	if not ResourceManager.can_afford(cost):
		result["reason"] = "资金不足\n需要：%d" % cost
		return result

	if not ResourceManager.can_consume_action_points(1):
		result["reason"] = "行动点不足"
		return result

	# 扣钱
	if not ResourceManager.add_money(-cost):
		result["reason"] = "资金不足\n需要：%d" % cost
		return result

	# 扣行动点
	if not ResourceManager.consume_action_point(1):
		# 如果行动点扣除失败，把钱补回去
		ResourceManager.add_money(cost)
		result["reason"] = "行动点不足"
		return result

	# 不立即升级正式等级，而是写入待生效等级
	var next_level = current_level + 1
	ResourceManager.set_facility_pending_level(facility_type, next_level)
	ResourceManager.set_facility_upgrading(facility_type, true)


	# 刷新当前场景顶部UI
	ResourceManager.refresh_current_scene_topbar()

	result["success"] = true
	result["new_level"] = next_level
	return result

# ===================== 设施方向值加成 =====================

# 在设施“正式生效”时，按 JSON 配置给对应方向值加成
# 当前规则：
# - 只处理三个副设施：stage / rehearsal / lounge
# - bar（主设施）这一步不加方向值
# - 使用：
#   - weight_type（art / business / human）
#   - weight_gain[level]
func apply_facility_weight_gain_on_activation(facility_type: String, target_level: int) -> void:
	# 只让三个副设施生效方向值
	if facility_type == "bar":
		return

	if not facility_data.has(facility_type):
		return

	var data = facility_data[facility_type]

	# 必须同时存在这两个字段
	if not data.has("weight_type") or not data.has("weight_gain"):
		return

	var weight_type: String = str(data["weight_type"])
	var weight_gain_array = data["weight_gain"]

	# 防止数组越界
	if target_level < 0 or target_level >= weight_gain_array.size():
		return

	var gain = int(weight_gain_array[target_level])

	# 没有加成就直接跳过
	if gain <= 0:
		return

	match weight_type:
		"art":
			ResourceManager.modify_ai_weight(Constants.WEIGHT_ART, gain)
		"business":
			ResourceManager.modify_ai_weight(Constants.WEIGHT_BUSINESS, gain)
		"human":
			ResourceManager.modify_ai_weight(Constants.WEIGHT_HUMAN, gain)

	print("设施正式生效，方向值加成：", facility_type, " -> ", weight_type, " +", gain)

# ===================== 设施互动接口 =====================

# 获取设施互动说明（给面板显示用）
func get_facility_action_info(facility_type: String) -> Dictionary:
	var result := {
		"action_name": "",
		"cost_text": "",
		"reward_text": "",
		"enabled": false,
		"reason": ""
	}

	var check_result = ResourceManager.can_perform_facility_action(facility_type)

	match facility_type:
		"bar":
			var cohesion_cost = ResourceManager.get_bar_action_cohesion_cost()
			var creativity_cost = ResourceManager.get_bar_action_creativity_cost()
			var money_gain = ResourceManager.get_bar_action_money_gain()

			result["action_name"] = "营业推广"
			result["cost_text"] = "消耗：行动点1 / 凝聚力%d / 创造力%d" % [cohesion_cost, creativity_cost]
			result["reward_text"] = "收益：资金 +%d" % money_gain
			result["enabled"] = check_result["success"]
			result["reason"] = check_result["reason"]
			return result

		"stage":
			var stage_creativity_cost = ResourceManager.get_stage_action_creativity_cost()
			var stage_cohesion_cost = ResourceManager.get_stage_action_cohesion_cost()
			var stage_money_gain = ResourceManager.get_stage_action_money_gain()
			var stage_reputation_gain = ResourceManager.get_stage_action_reputation_gain()

			result["action_name"] = "安排演出"
			result["cost_text"] = "消耗：行动点1 / 创造力%d / 凝聚力%d" % [stage_creativity_cost, stage_cohesion_cost]
			result["reward_text"] = "收益：资金 +%d / 声誉 +%d" % [stage_money_gain, stage_reputation_gain]
			result["enabled"] = check_result["success"]
			result["reason"] = check_result["reason"]
			return result

		"rehearsal":
			var money_cost = ResourceManager.get_rehearsal_action_money_cost()
			var creativity_gain = ResourceManager.get_rehearsal_action_creativity_gain()

			result["action_name"] = "集中排练"
			result["cost_text"] = "消耗：行动点1 / 资金%d" % money_cost
			result["reward_text"] = "收益：创造力 +%d" % creativity_gain
			result["enabled"] = check_result["success"]
			result["reason"] = check_result["reason"]
			return result

		"lounge":
			var lounge_money_cost = ResourceManager.get_lounge_action_money_cost()
			var lounge_cohesion_gain = ResourceManager.get_lounge_action_cohesion_gain()
			var lounge_fatigue_recovery = ResourceManager.get_lounge_action_fatigue_recovery()

			result["action_name"] = "团队休整"
			result["cost_text"] = "消耗：行动点1 / 资金%d" % lounge_money_cost
			result["reward_text"] = "收益：凝聚力 +%d / 全员疲劳 -%d" % [lounge_cohesion_gain, lounge_fatigue_recovery]
			result["enabled"] = check_result["success"]
			result["reason"] = check_result["reason"]
			return result

		_:
			result["action_name"] = "未开放"
			result["cost_text"] = ""
			result["reward_text"] = ""
			result["enabled"] = false
			result["reason"] = "该设施互动尚未开放"
			return result

# 执行设施互动（给面板按钮调用）
func perform_facility_action(facility_type: String) -> Dictionary:
	return ResourceManager.perform_facility_action(facility_type)
