extends Sprite2D

signal about_to_destroy

@export var fall_speed: float = 2.0

var init_y_pos: float = -360
var has_passed: bool = false
var pass_threshold: float = 300.0
var out_of_screen_threshold: float = 700.0  # 超出屏幕底部的位置

func _init():
	set_process(false)

func _process(delta):
	global_position += Vector2(0, fall_speed)
	
	# 检查是否超过判定线（未击中）
	if not has_passed and global_position.y > pass_threshold:
		has_passed = true
		# 发射信号通知 key_arrow 这个键已经错过
		about_to_destroy.emit()
		# 立即销毁
		queue_free()
		return
	
	# 检查是否超出屏幕底部（防止无限下落）
	if global_position.y > out_of_screen_threshold:
		if not has_passed:
			about_to_destroy.emit()
		queue_free()

func Setup(target_x: float, target_frame: int):
	global_position = Vector2(target_x, init_y_pos)
	frame = target_frame
	has_passed = false
	set_process(true)

func _on_destroy_timer_timeout():
	# 这个定时器可能不再需要，但保留作为备用
	if not has_passed:
		about_to_destroy.emit()
	queue_free()
