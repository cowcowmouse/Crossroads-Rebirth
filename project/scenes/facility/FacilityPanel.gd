extends Panel

var current_facility_type: String = ""

@onready var title_label = $TitleLabel
@onready var level_label = $LevelLabel
@onready var cost_label = $CostLabel
@onready var upgrade_button = $UpgradeButton
@onready var close_button = $CloseButton
@onready var facility_manager = get_node("/root/FacilityManager")
@onready var resource_manager = get_node("/root/ResourceManager")
@onready var event_bus = get_node("/root/EventBus")

func _ready():
	visible = false
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# 可选：监听资源变化，刷新面板显示
	if event_bus:
		event_bus.core_resource_changed.connect(_on_resource_changed)

func open_panel(facility_type: String):
	current_facility_type = facility_type
	_refresh_panel()
	visible = true

func _refresh_panel():
	if not facility_manager or not resource_manager:
		print("管理器未就绪")
		return
	
	var info = facility_manager.get_facility_info(current_facility_type)
	if info.is_empty():
		title_label.text = "未知设施"
		level_label.text = "当前等级：-"
		cost_label.text = "升级费用：-"
		upgrade_button.disabled = true
		return

	title_label.text = str(info["name"])
	level_label.text = "当前等级：%d" % int(info["level"])

	var cost = facility_manager.get_upgrade_cost(current_facility_type)
	var current_money = resource_manager.get_resource_value("money")  # 使用字符串或 Constants
	
	if cost < 0:
		cost_label.text = "已满级"
		upgrade_button.disabled = true
	else:
		cost_label.text = "升级费用：%d" % int(cost)
		
		# 检查是否可升级（等级未满 + 资金足够 + 有行动点）
		var can_upgrade = facility_manager.can_upgrade(current_facility_type)
		var has_money = current_money >= cost
		var has_action_points = resource_manager.get_action_points() > 0
		
		upgrade_button.disabled = not (can_upgrade and has_money and has_action_points)
		
		# 显示提示信息
		if not can_upgrade:
			cost_label.text = "已达最高等级"
			cost_label.modulate = Color.YELLOW
		elif not has_money:
			cost_label.text = "资金不足！需要 %d" % cost
			cost_label.modulate = Color.RED
		elif not has_action_points:
			cost_label.text = "行动点不足！"
			cost_label.modulate = Color.RED
		else:
			cost_label.text = "升级费用：%d" % cost
			cost_label.modulate = Color.WHITE

func _on_upgrade_pressed():
	if not facility_manager or not resource_manager:
		return
	
	var cost = facility_manager.get_upgrade_cost(current_facility_type)
	var current_money = resource_manager.get_resource_value("money")
	
	# 多重检查
	if current_money < cost:
		cost_label.text = "资金不足！"
		cost_label.modulate = Color.RED
		return
	
	if not resource_manager.can_consume_action_points(1):
		cost_label.text = "行动点不足！"
		cost_label.modulate = Color.RED
		return
	
	# 执行升级
	var result = facility_manager.upgrade_facility(current_facility_type)

	if result["success"]:
		# 扣除资金和行动点
		resource_manager.modify_core_resource("money", -cost)
		resource_manager.consume_action_point(1)
		
		print("设施升级成功 - 类型: %s, 消耗资金: %d, 行动点: 1" % [current_facility_type, cost])
		
		_refresh_panel()
		
		# 通知主场景升级完成
		var main_scene = get_tree().current_scene
		if main_scene and main_scene.has_method("on_facility_upgraded"):
			main_scene.on_facility_upgraded()
		
		# 显示成功提示
		cost_label.text = "升级成功！"
		cost_label.modulate = Color.GREEN
		await get_tree().create_timer(1.0).timeout
		_refresh_panel()
	else:
		cost_label.text = result["reason"]
		cost_label.modulate = Color.RED

func _on_resource_changed(resource_name: String, new_value: int, delta: int):
	# 当资金变化时刷新面板显示
	if resource_name == "money" and visible:
		_refresh_panel()

func _on_close_pressed():
	visible = false
	
func close_panel():
	visible = false
