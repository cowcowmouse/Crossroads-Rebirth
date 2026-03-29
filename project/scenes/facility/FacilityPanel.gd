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

	var current_level = int(info["level"])
	var pending_level = ResourceManager.get_facility_pending_level(current_facility_type)
	var is_repairing = ResourceManager.is_facility_upgrading(current_facility_type)

	if is_repairing and pending_level > current_level:
		level_label.text = "当前等级：%d → %d" % [current_level, pending_level]
	else:
		level_label.text = "当前等级：%d" % current_level

	var cost = facility_manager.get_upgrade_cost(current_facility_type)

	if is_repairing:
		cost_label.text = "维修中（下周生效）"
		upgrade_button.disabled = true
	elif cost < 0:
		cost_label.text = "已满级"
		upgrade_button.disabled = true
	else:
		cost_label.text = "升级费用：%d" % int(cost)
		upgrade_button.disabled = not facility_manager.can_upgrade(current_facility_type)

	print("升级按钮是否禁用 = ", upgrade_button.disabled)

func _on_upgrade_pressed():
	if ResourceManager.is_facility_upgrading(current_facility_type):
		return

	var result = facility_manager.upgrade_facility(current_facility_type)

	if result["success"]:
		# 标记该设施进入维修/升级中状态
		ResourceManager.set_facility_upgrading(current_facility_type, true)

		# 立刻刷新当前场景里的对应设施按钮，不用切场景
		_refresh_current_scene_facility_button()

		_refresh_panel()
		# 通知主场景消耗行动点
		var main_scene = get_tree().current_scene
		if main_scene and main_scene.has_method("on_facility_upgraded"):
			main_scene.on_facility_upgraded()
	else:
		cost_label.text = result["reason"]

func _refresh_current_scene_facility_button():
	var current_scene = get_tree().current_scene
	if not current_scene:
		return

	var button_path := ""

	match current_facility_type:
		"stage":
			button_path = "UILayer/StageButton"
		"bar":
			button_path = "UILayer/BarButton"
		"lounge":
			button_path = "UILayer/LoungeButton"
		"rehearsal":
			button_path = "UILayer/RehearsalButton"

	if button_path == "":
		return

	var facility_button = current_scene.get_node_or_null(button_path)
	if facility_button and facility_button.has_method("refresh_repair_state"):
		facility_button.refresh_repair_state()

func _on_close_pressed():
	visible = false

func close_panel():
	visible = false
