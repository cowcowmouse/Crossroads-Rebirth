extends CanvasLayer

# ===================== 配置 =====================
# 后续如果你要换成固定背景图，直接改这里
const TRANSITION_BG_PATH := "res://project/images/ui/week_transition_bg.png"

# ===================== 过场参数 =====================
const FADE_IN_DURATION := 0.50
const HOLD_DURATION := 0.08
const FADE_OUT_DURATION := 0.24
const MASK_ALPHA := 0.88

# ===================== 节点 =====================
var root_control: Control = null
var backdrop: TextureRect = null
var mask_rect: ColorRect = null

# ===================== 状态 =====================
var is_playing: bool = false

func _ready():
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui()

func _create_ui():
	# 整个过场真正显示内容的根节点
	root_control = Control.new()
	root_control.name = "RootControl"
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.visible = false
	add_child(root_control)

	# 通用背景图（可选）
	backdrop = TextureRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.visible = false
	backdrop.modulate = Color(1, 1, 1, 0)
	root_control.add_child(backdrop)

	# 整体黑幕
	mask_rect = ColorRect.new()
	mask_rect.name = "TransitionMask"
	mask_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	mask_rect.color = Color(0, 0, 0, 0.0)
	mask_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(mask_rect)

	_apply_background()

func _apply_background():
	if not backdrop:
		return

	if TRANSITION_BG_PATH != "" and ResourceLoader.exists(TRANSITION_BG_PATH):
		var texture = load(TRANSITION_BG_PATH)
		if texture:
			backdrop.texture = texture
			backdrop.visible = true
			return

	backdrop.texture = null
	backdrop.visible = false

# on_midpoint：黑幕盖满时执行真正的阶段切换 / 切场景
# on_finished：整个过场结束后执行
func play_transition(on_midpoint: Callable = Callable(), on_finished: Callable = Callable()):
	if is_playing:
		return

	is_playing = true
	_apply_background()

	root_control.visible = true
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP

	# 重置初始状态
	mask_rect.color = Color(0, 0, 0, 0.0)

	if backdrop and backdrop.visible:
		backdrop.modulate = Color(1, 1, 1, 0.0)

	# 先等一帧，确保这层真的显示出来
	await get_tree().process_frame

	# 渐变变暗
	var fade_in_tween = create_tween()
	fade_in_tween.set_trans(Tween.TRANS_SINE)
	fade_in_tween.set_ease(Tween.EASE_IN_OUT)
	fade_in_tween.tween_property(mask_rect, "color", Color(0, 0, 0, MASK_ALPHA), FADE_IN_DURATION)

	if backdrop and backdrop.visible:
		fade_in_tween.parallel().tween_property(backdrop, "modulate", Color(1, 1, 1, 1), FADE_IN_DURATION)

	await fade_in_tween.finished

	# 在全黑时执行真正切换
	if on_midpoint.is_valid():
		on_midpoint.call()

	# 留一帧给切场景 / 切阶段
	await get_tree().process_frame
	await get_tree().create_timer(HOLD_DURATION).timeout

	# 再淡出
	var fade_out_tween = create_tween()
	fade_out_tween.set_trans(Tween.TRANS_SINE)
	fade_out_tween.set_ease(Tween.EASE_IN_OUT)
	fade_out_tween.tween_property(mask_rect, "color", Color(0, 0, 0, 0.0), FADE_OUT_DURATION)

	if backdrop and backdrop.visible:
		fade_out_tween.parallel().tween_property(backdrop, "modulate", Color(1, 1, 1, 0.0), FADE_OUT_DURATION)

	await fade_out_tween.finished

	root_control.visible = false
	is_playing = false

	if on_finished.is_valid():
		on_finished.call()

func is_transition_playing() -> bool:
	return is_playing
