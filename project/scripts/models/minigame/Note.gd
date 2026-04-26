extends Control

var lane := 0
var hit_time := 0.0
var note_type := "tap"   # tap / hold / slide
var duration := 0.0
var judged := false
var holding_started := false

const TRAVEL_TIME := 2.0
const NOTE_WIDTH := 36.0
const HEAD_HEIGHT := 36.0
const RELEASE_HINT_LEAD := 0.18
const RELEASE_WINDOW := 0.18

@onready var body := $Body
@onready var head := $Head
@onready var release_hint := $ReleaseHint

var full_body_height := 0.0

func _ready():
	var root = get_tree().get_first_node_in_group("final_performance_root")
	if root == null:
		return

	var lane_node = _get_lane_node(root)
	var judge_line = root.get_node("NoteLayer/JudgeLine")
	if lane_node == null or judge_line == null:
		return

	var start_y = lane_node.global_position.y
	var judge_y = judge_line.global_position.y
	var speed = (judge_y - start_y) / TRAVEL_TIME

	if note_type == "hold":
		full_body_height = max(90.0, duration * speed)
		custom_minimum_size = Vector2(NOTE_WIDTH, full_body_height + HEAD_HEIGHT)
	else:
		full_body_height = 0.0
		custom_minimum_size = Vector2(NOTE_WIDTH, HEAD_HEIGHT)

	_apply_lane_color()

	release_hint.visible = false
	release_hint.text = "松手"
	release_hint.modulate = Color(1, 1, 1, 0.0)

func _process(_delta):
	var root = get_tree().get_first_node_in_group("final_performance_root")
	if root == null:
		return

	var audio_player = root.get_node("AudioPlayer")
	var now = audio_player.get_playback_position()

	var lane_node = _get_lane_node(root)
	var judge_line = root.get_node("NoteLayer/JudgeLine")
	if lane_node == null or judge_line == null:
		return

	var remain = hit_time - now
	var progress = 1.0 - remain / TRAVEL_TIME

	var lane_center_x_global = lane_node.global_position.x + lane_node.size.x * 0.5
	var start_y_global = lane_node.global_position.y
	var judge_y_global = judge_line.global_position.y
	var head_center_y_global = lerp(start_y_global, judge_y_global, progress)

	var parent_global = get_parent().global_position

	position.x = lane_center_x_global - parent_global.x - NOTE_WIDTH * 0.5

	# tap
	if note_type != "hold":
		position.y = head_center_y_global - parent_global.y - HEAD_HEIGHT * 0.5

		body.visible = false
		head.visible = true
		head.position = Vector2.ZERO
		head.size = Vector2(NOTE_WIDTH, HEAD_HEIGHT)

		if now > hit_time + 0.18 and not judged:
			judged = true
			root.register_hit(lane, "miss")
			queue_free()
		return

	# hold：还没按住
	if not holding_started:
		position.y = head_center_y_global - parent_global.y - full_body_height - HEAD_HEIGHT * 0.5

		body.visible = true
		head.visible = true

		body.position = Vector2(0, 0)
		body.size = Vector2(NOTE_WIDTH, full_body_height)

		head.position = Vector2(0, full_body_height)
		head.size = Vector2(NOTE_WIDTH, HEAD_HEIGHT)

		release_hint.visible = false

		if now > hit_time + 0.16 and not judged:
			judged = true
			root.register_hit(lane, "miss")
			queue_free()
		return

	# hold：已按住
	var held_ratio = clamp((now - hit_time) / max(duration, 0.001), 0.0, 1.0)
	var remaining_body_height = full_body_height * (1.0 - held_ratio)

	position.y = judge_y_global - parent_global.y - remaining_body_height

	body.visible = true
	head.visible = false

	body.position = Vector2(0, 0)
	body.size = Vector2(NOTE_WIDTH, remaining_body_height)

	if now >= hit_time + duration - RELEASE_HINT_LEAD:
		_update_release_hint(now)
	else:
		release_hint.visible = false

	# 尾部没过线前松手 -> MISS
	if now < hit_time + duration:
		if not root.is_lane_held(lane):
			judged = true
			root.register_hit(lane, "miss")
			queue_free()
		return

	# 尾部过线后：必须及时松手
	_update_release_hint(now)

	if not root.is_lane_held(lane):
		judged = true
		root.register_hit(lane, "perfect")
		queue_free()
		return

	if now > hit_time + duration + RELEASE_WINDOW:
		judged = true
		root.register_hit(lane, "miss")
		queue_free()
		return

func try_hit(input_lane: int) -> bool:
	if judged or input_lane != lane:
		return false

	var root = get_tree().get_first_node_in_group("final_performance_root")
	if root == null:
		return false

	var audio_player = root.get_node("AudioPlayer")
	var now = audio_player.get_playback_position()
	var diff = abs(now - hit_time)

	if note_type == "hold":
		if diff <= 0.16:
			holding_started = true
			if root.has_method("register_hold_start"):
				root.register_hold_start(lane)
			return true
		return false

	judged = true

	if diff <= 0.08:
		root.register_hit(lane, "perfect")
	elif diff <= 0.16:
		root.register_hit(lane, "good")
	else:
		root.register_hit(lane, "miss")

	queue_free()
	return true

func _apply_lane_color():
	var lane_color := Color.WHITE

	match lane:
		1:
			lane_color = Color(0.95, 0.45, 0.45, 1.0)
		2:
			lane_color = Color(0.95, 0.9, 0.45, 1.0)
		3:
			lane_color = Color(0.45, 0.8, 1.0, 1.0)

	body.color = lane_color
	head.color = lane_color
	release_hint.self_modulate = Color(1.0, 0.95, 0.7, 1.0)

func _update_release_hint(now: float):
	release_hint.visible = true

	var pulse = 0.5 + 0.5 * sin(now * 16.0)
	release_hint.modulate.a = 0.55 + 0.45 * pulse
	release_hint.scale = Vector2.ONE * (1.0 + 0.08 * pulse)
	release_hint.position = Vector2(0, -32)

func _get_lane_node(root: Node) -> Control:
	match lane:
		1:
			return root.get_node("NoteLayer/Lane1")
		2:
			return root.get_node("NoteLayer/Lane2")
		3:
			return root.get_node("NoteLayer/Lane3")
	return null

func is_holding_started() -> bool:
	return holding_started
