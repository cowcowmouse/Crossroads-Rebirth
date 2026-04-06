extends CanvasLayer

@onready var dark_overlay = $DarkOverlay
@onready var highlight_mask = $HighlightMask
@onready var guide_text = $GuideText
@onready var guide_label = $GuideText/Label

func _ready():
	# 设置鼠标过滤
	dark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guide_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 设置透明度
	dark_overlay.color = Color(0, 0, 0, 0.5)
	
	# 初始隐藏
	hide_all()
	print("✅ TutorialLayer 就绪")

func highlight_button(button_group: String, text: String):
	print("🎯 高亮按钮组: ", button_group)
	
	# 找到左箭头（这里直接用名称查找，不用分组）
	var left_arrow = get_tree().current_scene.find_child("ArrowLeft", true, false)
	if not left_arrow:
		print("❌ 找不到左箭头")
		return
	
	# 显示遮罩
	show()
	dark_overlay.visible = true
	highlight_mask.visible = true
	guide_text.visible = true
	guide_label.text = text
	
	# 更新高亮位置（固定位置）
	var material = highlight_mask.material as ShaderMaterial
	if material:
		material.set_shader_parameter("highlight_center", Vector2(0.08, 0.5))
		material.set_shader_parameter("highlight_radius", 0.08)
		material.set_shader_parameter("smoothness", 0.02)
		print("✅ 高亮位置已设置")
	
	# 左箭头闪烁
	start_blinking(left_arrow)
	
	# 禁用右箭头
	var right_arrow = get_tree().current_scene.find_child("ArrowRight", true, false)
	if right_arrow:
		right_arrow.disabled = true
		right_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		print("✅ 右箭头已禁用")
	
	print("✅ 引导已显示，等待点击左箭头")

func start_blinking(button):
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(button, "modulate", Color(1.5, 1.5, 1.5, 1), 0.3)
	tween.tween_property(button, "modulate", Color(1, 1, 1, 1), 0.3)

func hide_all():
	dark_overlay.visible = false
	highlight_mask.visible = false
	guide_text.visible = false
	hide()
