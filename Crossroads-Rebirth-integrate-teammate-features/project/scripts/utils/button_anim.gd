# 通用按钮动效脚本，hover放大、点击缩放
extends Button

var base_scale: Vector2 = Vector2(1,1)

func _ready():
	base_scale = scale
	# 连接按钮事件
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_leave)
	button_down.connect(_on_press)
	button_up.connect(_on_release)

func _on_hover():
	var tween = create_tween()
	tween.tween_property(self, "scale", base_scale * 1.05, 0.15)
	modulate = Color(1.1, 1.1, 1.1) # 高亮

func _on_leave():
	var tween = create_tween()
	tween.tween_property(self, "scale", base_scale, 0.15)
	modulate = Color(1, 1, 1) # 恢复原色

func _on_press():
	var tween = create_tween()
	tween.tween_property(self, "scale", base_scale * 0.95, 0.1)

func _on_release():
	var tween = create_tween()
	tween.tween_property(self, "scale", base_scale * 1.05, 0.1)
	await get_tree().create_timer(0.1).timeout
	tween.tween_property(self, "scale", base_scale, 0.1)
