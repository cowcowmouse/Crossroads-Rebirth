extends Panel

var current_facility_type: String = ""

@onready var title_label = $TitleLabel
@onready var level_label = $LevelLabel
@onready var cost_label = $CostLabel
@onready var upgrade_button = $UpgradeButton
@onready var close_button = $CloseButton
@onready var facility_manager = get_node("/root/FacilityManager")

func _ready():
	visible = false
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	close_button.pressed.connect(_on_close_pressed)

func open_panel(facility_type: String):
	current_facility_type = facility_type
	_refresh_panel()
	visible = true

func _refresh_panel():
	print("当前设施类型 = ", current_facility_type)

	var info = facility_manager.get_facility_info(current_facility_type)
	print("读取到的设施信息 = ", info)

	if info.is_empty():
		title_label.text = "未知设施"
		level_label.text = "当前等级：-"
		cost_label.text = "升级费用：-"
		upgrade_button.disabled = true
		return

	title_label.text = str(info["name"])
	level_label.text = "当前等级：%d" % int(info["level"])

	var cost = facility_manager.get_upgrade_cost(current_facility_type)
	if cost < 0:
		cost_label.text = "已满级"
		upgrade_button.disabled = true
	else:
		cost_label.text = "升级费用：%d" % int(cost)
		upgrade_button.disabled = not facility_manager.can_upgrade(current_facility_type)

	print("升级按钮是否禁用 = ", upgrade_button.disabled)

func _on_upgrade_pressed():
	var result = facility_manager.upgrade_facility(current_facility_type)

	if result["success"]:
		_refresh_panel()
		# 通知主场景消耗行动点
		var main_scene = get_tree().current_scene
		if main_scene and main_scene.has_method("on_facility_upgraded"):
			main_scene.on_facility_upgraded()
	else:
		cost_label.text = result["reason"]

func _on_close_pressed():
	visible = false
func close_panel():
	visible = false
