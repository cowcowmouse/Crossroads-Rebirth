extends Panel

var current_facility_type: String = ""

@onready var title_label = $TitleLabel
@onready var level_label = $LevelLabel
@onready var cost_label = $CostLabel
@onready var upgrade_button = $UpgradeButton
@onready var close_button = $CloseButton
@onready var facility_manager = get_node("/root/FacilityManager")
@onready var resource_manager = get_node("/root/ResourceManager")
@onready var event_bus = get_node("/root/EventBus")  # 添加 EventBus 引用

func _ready():
	visible = false
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# 让提示文字支持自动换行，避免长句直接溢出
	cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# 修改：通过 EventBus 监听资源变化
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
		cost_label.modulate = Color.WHITE
		upgrade_button.disabled = true
		return

	title_label.text = str(info["name"])

	var current_level = int(info["level"])
	var pending_level = ResourceManager.get_facility_pending_level(current_facility_type)
	var is_repairing = ResourceManager.is_facility_upgrading(current_facility_type)
	var cost = facility_manager.get_upgrade_cost(current_facility_type)

	if is_repairing and pending_level > current_level:
		level_label.text = "当前等级：%d → %d" % [current_level, pending_level]
	else:
		level_label.text = "当前等级：%d" % current_level

	if is_repairing:
		cost_label.text = "维修中（下周生效）"
		cost_label.modulate = Color.YELLOW
		upgrade_button.disabled = true
	elif cost < 0:
		cost_label.text = "已满级"
		cost_label.modulate = Color.YELLOW
		upgrade_button.disabled = true
	else:
		# 检查是否可升级（等级未满 + 资金足够 + 有行动点 + 主设施等级限制）
		var can_upgrade = facility_manager.can_upgrade(current_facility_type)
		upgrade_button.disabled = not can_upgrade
		
		# 显示提示信息
		if not can_upgrade:
			var fail_reason = ""
			
			# 优先使用 FacilityManager 返回的精确失败原因
			if facility_manager.has_method("get_upgrade_fail_reason"):
				fail_reason = facility_manager.get_upgrade_fail_reason(current_facility_type)
			
			if fail_reason == "":
				fail_reason = "当前不可升级"
			
			cost_label.text = fail_reason
			cost_label.modulate = Color.RED
		else:
			cost_label.text = "升级费用：%d" % cost
			cost_label.modulate = Color.WHITE

func _on_upgrade_pressed():
	if not facility_manager or not resource_manager:
		return

	# 维修中时禁止重复点击
	if ResourceManager.is_facility_upgrading(current_facility_type):
		cost_label.text = "维修中（下周生效）"
		cost_label.modulate = Color.YELLOW
		return
	
	# 执行升级
	var result = facility_manager.upgrade_facility(current_facility_type)

	if result["success"]:
		print("设施升级成功 - 类型: %s" % current_facility_type)

		# 立刻刷新当前场景里的对应设施按钮，不用切场景
		_refresh_current_scene_facility_button()
		
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
		# 升级失败时显示短提示
		cost_label.text = str(result["reason"])
		cost_label.modulate = Color.RED
		upgrade_button.disabled = true

func _on_resource_changed(resource_name: String, new_value: int, delta: int):
	# 当资金变化时刷新面板显示
	if resource_name == "money" and visible:
		_refresh_panel()

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
