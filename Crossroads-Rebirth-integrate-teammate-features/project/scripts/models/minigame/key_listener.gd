extends Sprite2D

@onready var falling_key = preload("res://project/scripts/models/minigame/falling_key.tscn")
@onready var score_text = preload("res://project/scripts/models/minigame/score_press_text.tscn")
@export var key_name: String = ""

var falling_key_queue = []
var is_processing_key: bool = false
var last_press_frame: int = 0  # 记录上次按下的帧数

# 判定阈值
var perfect_press_threshold: float = 30
var great_press_threshold: float = 50
var good_press_threshold: float = 60
var ok_press_threshold: float = 80

var perfect_press_score: float = 250
var great_press_score: float = 100
var good_press_score: float = 50
var ok_press_score: float = 20

func _ready():
	$GlowOverlay.frame = frame + 4
	Signals.CreateFallingKey.connect(CreateFallingKey)

func _process(delta):
	# 每帧清理无效队列
	_clean_invalid_queue()
	
	if Input.is_action_just_pressed(key_name):
		# 防止同一帧内多次触发
		var current_frame = Engine.get_process_frames()
		if current_frame == last_press_frame:
			return
		last_press_frame = current_frame
		
		Signals.KeyListenerPress.emit(key_name, frame)
		_handle_key_press()

func _handle_key_press():
	# 防止重复处理
	if is_processing_key:
		print("正在处理中，跳过")
		return
	is_processing_key = true
	
	# 清理队列
	_clean_invalid_queue()
	
	if falling_key_queue.size() == 0:
		# 空按，显示 MISS
		_show_score_text("MISS", Vector2(0, -20))
		Signals.ResetCombo.emit()
		is_processing_key = false
		return
	
	# 只处理队列中的第一个元素
	var key_to_pop = falling_key_queue.pop_front()
	
	if not is_instance_valid(key_to_pop):
		# 无效实例，尝试下一个
		is_processing_key = false
		_handle_key_press()
		return
	
	# 检查这个键是否已经错过了判定线
	if key_to_pop.has_passed:
		# 已经错过，显示 MISS 并继续处理下一个
		_show_score_text("MISS", Vector2(0, -20))
		Signals.ResetCombo.emit()
		is_processing_key = false
		_handle_key_press()
		return
	
	# 计算距离（相对于判定线）
	var distance_from_pass = abs(key_to_pop.pass_threshold - key_to_pop.global_position.y)
	
	# 播放动画
	$AnimationPlayer.stop()
	$AnimationPlayer.play("key_hit")
	
	# 计算得分和评级
	var press_score_text: String = ""
	var score_value: float = 0
	var should_increment_combo: bool = true
	
	if distance_from_pass < perfect_press_threshold:
		score_value = perfect_press_score
		press_score_text = "PERFECT"
	elif distance_from_pass < great_press_threshold:
		score_value = great_press_score
		press_score_text = "GREAT"
	elif distance_from_pass < good_press_threshold:
		score_value = good_press_score
		press_score_text = "GOOD"
	elif distance_from_pass < ok_press_threshold:
		score_value = ok_press_score
		press_score_text = "OK"
	else:
		press_score_text = "MISS"
		should_increment_combo = false
		Signals.ResetCombo.emit()
	
	# 增加分数
	if score_value > 0:
		Signals.IncrementScore.emit(score_value)
	
	# 增加连击
	if should_increment_combo:
		Signals.IncrementCombo.emit()
	
	# 删除这个 falling_key
	if is_instance_valid(key_to_pop):
		key_to_pop.queue_free()
	
	# 显示得分文本
	_show_score_text(press_score_text, Vector2(0, -20))
	
	
	is_processing_key = false

func _show_score_text(text: String, offset: Vector2):
	var st_inst = score_text.instantiate()
	get_tree().get_root().call_deferred("add_child", st_inst)
	st_inst.SetTextInfo(text)
	st_inst.global_position = global_position + offset

func _clean_invalid_queue():
	# 清理队列中已经无效的元素
	var i = 0
	while i < falling_key_queue.size():
		var key = falling_key_queue[i]
		if not is_instance_valid(key) or key.is_queued_for_deletion():
			falling_key_queue.remove_at(i)
		elif key.has_passed:
			# 已经超过判定线的，直接移除并显示 MISS
			falling_key_queue.remove_at(i)
			_show_score_text("MISS", Vector2(0, -20))
			Signals.ResetCombo.emit()
		else:
			i += 1

func CreateFallingKey(button_name: String):
	if button_name == key_name:
		var fk_inst = falling_key.instantiate()
		
		# 监听销毁信号
		fk_inst.about_to_destroy.connect(_on_falling_key_destroy.bind(fk_inst))
		
		get_tree().get_root().call_deferred("add_child", fk_inst)
		fk_inst.Setup(position.x, frame + 4)
		
		falling_key_queue.push_back(fk_inst)

func _on_falling_key_destroy(fk_inst):
	# 从队列中移除被销毁的实例
	var index = falling_key_queue.find(fk_inst)
	if index != -1:
		falling_key_queue.remove_at(index)

func _on_random_spawn_timer_timeout():
	$RandomSpawnTimer.wait_time = randf_range(0.4, 3)
	$RandomSpawnTimer.start()
