# 主场景控制器，实现UI联动、按钮交互、基础动效
extends Node2D

# 全局单例（强类型声明）
@onready var signal_bus: Node = SignalBus
@onready var constants: Node = Constants
@onready var resource_manager: Node = ResourceManager
@onready var action_point_controller: Node = ActionPointController
@onready var week_cycle_controller: Node = WeekCycleController

# ===================== UI节点绑定（新增记忆恢复度Label）=====================
# 顶部资源栏
@onready var MoneyLabel: Label = $UILayer/TopBar/MoneyLabel
@onready var ReputationLabel: Label = $UILayer/TopBar/ReputationLabel
@onready var CohesionLabel: Label = $UILayer/TopBar/CohesionLabel
@onready var CreativityLabel: Label = $UILayer/TopBar/CreativityLabel
@onready var MemoryLabel: Label = $UILayer/TopBar/MemoryLabel  # 新增记忆恢复度
@onready var ActionPointLabel: Label = $UILayer/TopBar/ActionPointLabel

# 资源说明弹窗（新增：需在场景中创建一个Panel容器+Label）
@onready var ResourceTipPanel: Panel = $UILayer/ResourceTipPanel
@onready var ResourceTipLabel: Label = $UILayer/ResourceTipPanel/TipLabel

# 功能按钮
@onready var FacilityBtn: Button = $UILayer/FunctionButtons/FacilityBtn
@onready var MemberBtn: Button = $UILayer/FunctionButtons/MemberBtn
@onready var RehabBtn: Button = $UILayer/FunctionButtons/RehabBtn
@onready var EnterMidWeekBtn: Button = $UILayer/FunctionButtons/EnterMidWeekBtn

# 成员头像
@onready var MemberAvatars: Node = $UILayer/MemberAvatars

# ===================== 生命周期 =====================
func _ready():
	# 依赖校验
	if not signal_bus or not constants or not resource_manager or not action_point_controller or not week_cycle_controller:
		push_error("全局单例加载失败！")
		return
	if not MoneyLabel or not ReputationLabel or not CohesionLabel or not CreativityLabel or not MemoryLabel or not ActionPointLabel:
		push_error("资源栏UI节点未找到！")
		return
	
	# 初始化UI
	_refresh_all_resource_ui()
	_refresh_action_point_ui(action_point_controller.current_ap, constants.MAX_ACTION_POINT)
	
	# 连接信号
	signal_bus.core_resource_changed.connect(_on_core_resource_changed)
	signal_bus.action_point_changed.connect(_refresh_action_point_ui)
	signal_bus.action_point_depleted.connect(_on_action_point_depleted)
	
	# 按钮绑定
	FacilityBtn.pressed.connect(_on_facility_btn_clicked)
	MemberBtn.pressed.connect(_on_member_btn_clicked)
	RehabBtn.pressed.connect(_on_rehab_btn_clicked)
	EnterMidWeekBtn.pressed.connect(_on_enter_mid_week_clicked)
	
	# 成员头像动效
	if MemberAvatars:
		for avatar in MemberAvatars.get_children():
			if avatar is TextureRect:
				avatar.mouse_entered.connect(func(): _on_avatar_hover(avatar))
				avatar.mouse_exited.connect(func(): _on_avatar_leave(avatar))
				avatar.gui_input.connect(func(event): _on_avatar_click(event, avatar))
	
	# ========== 新增：资源栏点击反馈绑定 ==========
	# 绑定点击事件
	MoneyLabel.gui_input.connect(func(event): _on_resource_label_click(event, constants.RES_MONEY))
	ReputationLabel.gui_input.connect(func(event): _on_resource_label_click(event, constants.RES_REPUTATION))
	CohesionLabel.gui_input.connect(func(event): _on_resource_label_click(event, constants.RES_COHESION))
	CreativityLabel.gui_input.connect(func(event): _on_resource_label_click(event, constants.RES_CREATIVITY))
	MemoryLabel.gui_input.connect(func(event): _on_resource_label_click(event, constants.RES_MEMORY))
	ActionPointLabel.gui_input.connect(func(event): _on_resource_label_click(event, "action_point"))
	
	# 初始化隐藏说明弹窗
	if ResourceTipPanel:
		ResourceTipPanel.visible = false
		# 点击弹窗外区域关闭
		ResourceTipPanel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_hide_resource_tip()
		)

# ===================== UI刷新核心方法（新增记忆恢复度）=====================
# 刷新所有核心资源UI
func _refresh_all_resource_ui():
	if not MoneyLabel or not ReputationLabel or not CohesionLabel or not CreativityLabel or not MemoryLabel:
		return
	if not resource_manager or not constants:
		return
	
	# 基础资源
	MoneyLabel.text = "资金：%d" % resource_manager.get_resource_value(constants.RES_MONEY)
	ReputationLabel.text = "声誉：%d" % resource_manager.get_resource_value(constants.RES_REPUTATION)
	CohesionLabel.text = "凝聚力：%d" % resource_manager.get_resource_value(constants.RES_COHESION)
	CreativityLabel.text = "创造力：%d" % resource_manager.get_resource_value(constants.RES_CREATIVITY)
	# 新增：记忆恢复度显示
	MemoryLabel.text = "记忆恢复：%d%%" % resource_manager.get_resource_value(constants.RES_MEMORY)

# 单个资源变动刷新UI
func _on_core_resource_changed(resource_name: String, new_value: int, delta: int):
	if not constants:
		return
	
	match resource_name:
		constants.RES_MONEY:
			if MoneyLabel:
				MoneyLabel.text = "资金：%d" % new_value
				_play_number_tween(MoneyLabel, delta)  # 强化动效
		constants.RES_REPUTATION:
			if ReputationLabel:
				ReputationLabel.text = "声誉：%d" % new_value
				_play_number_tween(ReputationLabel, delta)
		constants.RES_COHESION:
			if CohesionLabel:
				CohesionLabel.text = "凝聚力：%d" % new_value
				_play_number_tween(CohesionLabel, delta)
		constants.RES_CREATIVITY:
			if CreativityLabel:
				CreativityLabel.text = "创造力：%d" % new_value
				_play_number_tween(CreativityLabel, delta)
		constants.RES_MEMORY:
			if MemoryLabel:  # 新增：记忆恢复度动效
				MemoryLabel.text = "记忆恢复：%d%%" % new_value
				_play_number_tween(MemoryLabel, delta)

# 刷新行动点UI
func _refresh_action_point_ui(current: int, max: int):
	if not ActionPointLabel:
		return
	
	ActionPointLabel.text = "行动点：%d/%d" % [current, max]
	ActionPointLabel.modulate = Color(1,1,1) if current > 0 else Color(0.5,0.5,0.5)

# ===================== 新增：资源栏点击反馈核心逻辑 =====================
# 资源标签点击事件
func _on_resource_label_click(event: InputEvent, resource_type: String):
	# 只响应左键点击
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 显示对应资源的说明弹窗
		_show_resource_tip(resource_type)
		# 点击时播放小动效
		var label = _get_resource_label_by_type(resource_type)
		if label:
			var tween = create_tween()
			tween.tween_property(label, "scale", Vector2(1.1, 1.1), 0.1)
			tween.tween_property(label, "scale", Vector2(1, 1), 0.1)

# 获取资源类型对应的Label节点
func _get_resource_label_by_type(resource_type: String) -> Label:
	match resource_type:
		constants.RES_MONEY: return MoneyLabel
		constants.RES_REPUTATION: return ReputationLabel
		constants.RES_COHESION: return CohesionLabel
		constants.RES_CREATIVITY: return CreativityLabel
		constants.RES_MEMORY: return MemoryLabel
		"action_point": return ActionPointLabel
		_: return null

# 显示资源说明弹窗
func _show_resource_tip(resource_type: String):
	if not ResourceTipPanel or not ResourceTipLabel:
		return
	
	# 资源说明文本（可根据需求扩展）
	var tip_text = ""
	match resource_type:
		constants.RES_MONEY:
			tip_text = "资金\n- 来源：酒吧经营、演出收入\n- 消耗：升级设施、雇佣成员、康复训练\n- 不足时无法执行大部分操作"
		constants.RES_REPUTATION:
			tip_text = "声誉\n- 来源：完成演出、获得好评\n- 影响：解锁高级设施、吸引知名成员\n- 过低会导致客源减少"
		constants.RES_COHESION:
			tip_text = "凝聚力\n- 来源：和成员互动、团队活动\n- 影响：成员工作效率、演出效果\n- 过低会导致成员矛盾"
		constants.RES_CREATIVITY:
			tip_text = "创造力\n- 来源：创作、康复训练、灵感激发\n- 影响：演出质量、新曲创作\n- 越高演出收入越高"
		constants.RES_MEMORY:
			tip_text = "记忆恢复度\n- 来源：康复训练、休息\n- 影响：主角剧情解锁、特殊能力\n- 100%解锁完整记忆"
		"action_point":
			tip_text = "行动点\n- 每日重置为3点\n- 消耗：执行任何操作（设施升级、成员互动等）\n- 耗尽后自动进入周中阶段"
	
	# 设置弹窗文本
	ResourceTipLabel.text = tip_text
	# 显示弹窗并播放淡入动画
	ResourceTipPanel.visible = true
	ResourceTipPanel.modulate = Color(1,1,1,0)  # 初始透明
	var tween = create_tween()
	tween.tween_property(ResourceTipPanel, "modulate:a", 1.0, 0.2)
	# 弹窗位置跟随鼠标
	ResourceTipPanel.position = get_global_mouse_position() + Vector2(20, 20)

# 隐藏资源说明弹窗
func _hide_resource_tip():
	if not ResourceTipPanel:
		return
	
	# 播放淡出动画后隐藏
	var tween = create_tween()
	tween.tween_property(ResourceTipPanel, "modulate:a", 0.0, 0.2)
	await tween.finished
	ResourceTipPanel.visible = false

# ===================== 强化：数值变动动效（更明显）=====================
func _play_number_tween(label: Label, delta: int):
	if not label:
		return
	
	# 强化动效：颜色更鲜艳 + 缩放更大 + 时长更长
	label.modulate = Color(0.1, 0.9, 0.1) if delta > 0 else Color(0.9, 0.1, 0.1)
	# 缩放动画（比原来更大更久）
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)  # 缓动效果更自然
	tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.15)  # 更大的缩放
	tween.tween_property(label, "scale", Vector2(1, 1), 0.15)
	# 颜色渐变回白色（新增：平滑过渡）
	var color_tween = create_tween()
	color_tween.tween_property(label, "modulate", Color(1,1,1), 0.8)  # 更长的过渡时间

# ===================== 原有按钮交互逻辑（保留不变）=====================
func _on_facility_btn_clicked():
	if not action_point_controller or not resource_manager or not constants:
		return
	if not action_point_controller.can_execute_action(1):
		_show_warning("行动点不足，无法执行操作！")
		return
	if resource_manager.modify_core_resource(constants.RES_MONEY, -2000):
		action_point_controller.consume_action_point(1)
		resource_manager.modify_ai_weight(constants.WEIGHT_ART, 1)
		_show_tips("舞台升级成功！艺术权重+1")
	else:
		_show_warning("资金不足，升级失败！")

func _on_member_btn_clicked():
	if not action_point_controller or not resource_manager or not constants:
		return
	if not action_point_controller.can_execute_action(1):
		_show_warning("行动点不足，无法执行操作！")
		return
	if resource_manager.modify_core_resource(constants.RES_MONEY, -300):
		action_point_controller.consume_action_point(1)
		resource_manager.modify_core_resource(constants.RES_COHESION, 4)
		resource_manager.modify_ai_weight(constants.WEIGHT_HUMAN, 1)
		_show_tips("鼓励成员成功！凝聚力+4")
	else:
		_show_warning("资金不足，操作失败！")

func _on_rehab_btn_clicked():
	if not action_point_controller or not resource_manager or not constants:
		return
	if not action_point_controller.can_execute_action(1):
		_show_warning("行动点不足，无法执行操作！")
		return
	if resource_manager.modify_core_resource(constants.RES_MONEY, -800):
		action_point_controller.consume_action_point(1)
		resource_manager.modify_core_resource(constants.RES_CREATIVITY, 7)
		resource_manager.modify_core_resource(constants.RES_MEMORY, 3)
		resource_manager.modify_ai_weight(constants.WEIGHT_ART, 1)
		_show_tips("康复训练完成！创造力+7，记忆恢复度+3")
	else:
		_show_warning("资金不足，操作失败！")

func _on_enter_mid_week_clicked():
	if not week_cycle_controller:
		return
	week_cycle_controller.enter_mid_week()
	_show_tips("已进入周中事件阶段！")
	if FacilityBtn: FacilityBtn.disabled = true
	if MemberBtn: MemberBtn.disabled = true
	if RehabBtn: RehabBtn.disabled = true
	if EnterMidWeekBtn: EnterMidWeekBtn.disabled = true

func _on_action_point_depleted():
	if not week_cycle_controller:
		return
	_show_warning("行动点已耗尽，将自动进入周中阶段！")
	await get_tree().create_timer(1.5).timeout
	week_cycle_controller.enter_mid_week()
	if FacilityBtn: FacilityBtn.disabled = true
	if MemberBtn: MemberBtn.disabled = true
	if RehabBtn: RehabBtn.disabled = true
	if EnterMidWeekBtn: EnterMidWeekBtn.disabled = true

# ===================== 原有动效/工具方法（保留不变）=====================
func _on_avatar_hover(avatar: TextureRect):
	if not avatar:
		return
	var tween = create_tween()
	tween.tween_property(avatar, "scale", Vector2(1.15, 1.15), 0.2)

func _on_avatar_leave(avatar: TextureRect):
	if not avatar:
		return
	var tween = create_tween()
	tween.tween_property(avatar, "scale", Vector2(1, 1), 0.2)

func _on_avatar_click(event: InputEvent, avatar: TextureRect):
	if not avatar:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("点击了成员头像：", avatar.name)
		var tween = create_tween()
		tween.tween_property(avatar, "scale", Vector2(0.9, 0.9), 0.1)
		tween.tween_property(avatar, "scale", Vector2(1, 1), 0.1)
		_show_tips("打开" + avatar.name + "的对话界面（后续里程碑扩展）")

func _show_tips(text: String):
	print("提示：", text)

func _show_warning(text: String):
	print("警告：", text)
