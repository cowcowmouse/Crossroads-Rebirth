# MemberSpawner.gd
extends Node

@export var main_spawn_points: Array[Node2D] = []
@export var lounge_spawn_points: Array[Node2D] = []
@export var rehearsal_spawn_points: Array[Node2D] = []

# 每个成员生成时的随机偏移范围（防止重叠）
@export var random_offset_range := 60.0

func _ready():
	call_deferred("spawn_members")

func spawn_members():
	clear_existing_members()
	
	var current_path = get_tree().current_scene.scene_file_path
	var spawn_points: Array[Node2D] = []
	
	if current_path == "res://project/scenes/main/main.tscn":
		spawn_points = main_spawn_points
	elif current_path == "res://project/scenes/lounge/lounge_scene.tscn":
		spawn_points = lounge_spawn_points
	elif current_path == "res://project/scenes/rehearsal/rehearsal_scene.tscn":
		spawn_points = rehearsal_spawn_points
	else:
		return
	
	if spawn_points.is_empty():
		return
	
	# 获取符合条件的成员
	var candidates = []
	var all_members = MemberManager.all_members.values()
	
	for member in all_members:
		if not member.unlocked:
			if current_path != "res://project/scenes/main/main.tscn":
				continue  # 未入队只能在主场景
		candidates.append(member)
	
	# 限制生成数量 = 当前场景可用位置数
	var max_to_spawn = mini(candidates.size(), spawn_points.size())
	candidates.shuffle()
	var to_spawn = candidates.slice(0, max_to_spawn)
	
	# 生成
	for member in to_spawn:
		if spawn_points.size() > 0:
			var point = spawn_points[randi() % spawn_points.size()]
			var offset = Vector2(
				randf_range(-random_offset_range, random_offset_range),
				randf_range(-random_offset_range, random_offset_range)
			)
			_spawn_member(member, point.global_position + offset)

func _spawn_member(member: CharacterBase, pos: Vector2):
	var avatar_scene = preload("res://characters/MemberAvatar.tscn")
	if not avatar_scene:
		return
	
	var avatar = avatar_scene.instantiate()
	avatar.member_id = member.id
	
	# 先添加到场景树
	get_tree().current_scene.add_child(avatar)
	
	# 加强随机偏移（大幅减少重叠）
	var offset = Vector2(
		randf_range(-80, 80),
		randf_range(-80, 80)
	)
	avatar.global_position = pos + offset
	
	avatar.add_to_group("scene_member")
	
	print("生成成员：", member.id, " 位置：", avatar.global_position)

func clear_existing_members():
	for node in get_tree().get_nodes_in_group("scene_member"):
		if is_instance_valid(node):
			node.queue_free()
