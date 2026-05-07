extends Button

@export var facility_type: String = "stage"

@onready var repair_mask = get_node_or_null("RepairMask")
@onready var repair_label = get_node_or_null("RepairMask/Label")

var normal_scale: Vector2
var pressed_scale := Vector2(0.94, 0.94)

var _is_repairing_visual: bool = false
var _repair_tween: Tween = null

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	normal_scale = scale
	focus_mode = Control.FOCUS_NONE

	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

	# 初始化维修遮罩外观
	_setup_repair_overlay_style()

	# 初次进入场景时直接同步状态，不播放动画
	var repairing = ResourceManager.is_facility_upgrading(facility_type)
	_is_repairing_visual = repairing
	_apply_repair_visual_immediate(repairing)

func _setup_repair_overlay_style():
	if repair_mask:
		repair_mask.visible = false
		repair_mask.modulate = Color(1, 1, 1, 0)

		# 如果 RepairMask 是 ColorRect，顺手把遮罩改成暖棕半透明
		if repair_mask is ColorRect:
			repair_mask.color = Color(0.10, 0.06, 0.03, 0.55)

	if repair_label:
		repair_label.modulate = Color(1, 1, 1, 0)
		repair_label.scale = Vector2(0.92, 0.92)

		# 文字更柔和一点
		repair_label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.88, 1.0))
		repair_label.add_theme_color_override("font_outline_color", Color(0.16, 0.09, 0.04, 1.0))
		repair_label.add_theme_constant_override("outline_size", 2)

func refresh_repair_state():
	var repairing = ResourceManager.is_facility_upgrading(facility_type)

	# 状态没变化时，不重复播动画
	if repairing == _is_repairing_visual:
		return

	_is_repairing_visual = repairing

	if repairing:
		_play_repair_overlay_in()
	else:
		_play_repair_overlay_out()

func _apply_repair_visual_immediate(repairing: bool):
	if repairing:
		if repair_mask:
			repair_mask.visible = true
			repair_mask.modulate = Color(1, 1, 1, 1)

		if repair_label:
			repair_label.modulate = Color(1, 1, 1, 1)
			repair_label.scale = Vector2.ONE

		_set_outline_thickness(0.0)
	else:
		if repair_mask:
			repair_mask.visible = false
			repair_mask.modulate = Color(1, 1, 1, 0)

		if repair_label:
			repair_label.modulate = Color(1, 1, 1, 0)
			repair_label.scale = Vector2(0.92, 0.92)

func _play_repair_overlay_in():
	_kill_repair_tween()

	if repair_mask:
		repair_mask.visible = true
		repair_mask.modulate = Color(1, 1, 1, 0)

	if repair_label:
		repair_label.modulate = Color(1, 1, 1, 0)
		repair_label.scale = Vector2(0.92, 0.92)

	# 进入维修中时，关掉 hover 光圈
	_set_outline_thickness(0.0)

	_repair_tween = create_tween()
	_repair_tween.set_trans(Tween.TRANS_SINE)
	_repair_tween.set_ease(Tween.EASE_OUT)

	_repair_tween.set_parallel(true)

	if repair_mask:
		_repair_tween.tween_property(repair_mask, "modulate", Color(1, 1, 1, 1), 0.22)

	if repair_label:
		_repair_tween.tween_property(repair_label, "modulate", Color(1, 1, 1, 1), 0.18)
		_repair_tween.tween_property(repair_label, "scale", Vector2(1.03, 1.03), 0.16)

	_repair_tween.set_parallel(false)

	if repair_label:
		_repair_tween.tween_property(repair_label, "scale", Vector2(1.0, 1.0), 0.10)

func _play_repair_overlay_out():
	_kill_repair_tween()

	_repair_tween = create_tween()
	_repair_tween.set_trans(Tween.TRANS_SINE)
	_repair_tween.set_ease(Tween.EASE_IN_OUT)

	_repair_tween.set_parallel(true)

	if repair_label:
		_repair_tween.tween_property(repair_label, "modulate", Color(1, 1, 1, 0), 0.14)
		_repair_tween.tween_property(repair_label, "scale", Vector2(0.96, 0.96), 0.14)

	if repair_mask:
		_repair_tween.tween_property(repair_mask, "modulate", Color(1, 1, 1, 0), 0.20)

	await _repair_tween.finished

	if repair_mask:
		repair_mask.visible = false

	if repair_label:
		repair_label.scale = Vector2(0.92, 0.92)

func _kill_repair_tween():
	if _repair_tween and is_instance_valid(_repair_tween):
		_repair_tween.kill()
	_repair_tween = null

func _on_button_down():
	if ResourceManager.is_facility_upgrading(facility_type):
		return

	scale = Vector2(normal_scale.x * pressed_scale.x, normal_scale.y * pressed_scale.y)

func _on_button_up():
	scale = normal_scale

func _on_mouse_exited():
	_set_outline_thickness(0.0)
	scale = normal_scale

func _pressed():
	if ResourceManager.is_facility_upgrading(facility_type):
		return

	scale = normal_scale
	$"../FacilityPanel".open_panel(facility_type)

func _on_mouse_entered():
	if not ResourceManager.is_facility_upgrading(facility_type):
		_set_outline_thickness(20.0)

func _set_outline_thickness(value: float):
	if material:
		var t = create_tween()
		t.tween_property(material, "shader_parameter/line_thickness", value, 0.10)
