# 全局UI管理器，统一管理所有弹窗、界面切换
extends Node
@onready var signal_bus = SignalBus

# 弹窗节点引用（在主场景中赋值）
var facility_panel: Control = null
var dialog_box: Control = null

# ===================== 生命周期 =====================
func _ready():
	# 绑定信号
	signal_bus.show_facility_panel.connect(_show_facility_panel)
	signal_bus.hide_facility_panel.connect(_hide_facility_panel)
	signal_bus.show_dialog_box.connect(_show_dialog_box)
	signal_bus.hide_dialog_box.connect(_hide_dialog_box)

# 注册主场景中的弹窗节点（主场景_ready时调用）
func register_popup_nodes(facility: Control, dialog: Control):
	facility_panel = facility
	dialog_box = dialog
	# 初始隐藏所有弹窗
	facility_panel.hide()
	dialog_box.hide()

# ===================== 设施管理面板 =====================
func _show_facility_panel():
	if facility_panel:
		facility_panel.show()
		facility_panel.modulate.a = 0
		facility_panel.tween().tween_property(facility_panel, "modulate:a", 1.0, 0.2)

func _hide_facility_panel():
	if facility_panel:
		var tween = create_tween()
		tween.tween_property(facility_panel, "modulate:a", 0.0, 0.2)
		tween.finished.connect(facility_panel.hide)

# ===================== 成员对话框 =====================
func _show_dialog_box(member_id: String):
	if dialog_box:
		dialog_box.show()
		dialog_box.modulate.a = 0
		dialog_box.tween().tween_property(dialog_box, "modulate:a", 1.0, 0.2)

func _hide_dialog_box():
	if dialog_box:
		var tween = create_tween()
		tween.tween_property(dialog_box, "modulate:a", 0.0, 0.2)
		tween.finished.connect(dialog_box.hide)
