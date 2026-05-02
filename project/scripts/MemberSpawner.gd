# MemberSpawner.gd
extends Node

@export var main_spawn_points: Array[Node2D] = []
@export var lounge_spawn_points: Array[Node2D] = []
@export var rehearsal_spawn_points: Array[Node2D] = []

# 每个场景最多生成的成员数量
@export var max_members_per_scene := 5

# 正确引用 MemberManager（Autoload）
@onready var member_manager = get_node_or_null("/root/MemberManager")

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
	
	if spawn_points.is_empty() or not member_manager:
		return
	
	# 获取符合条件的成员
	var candidates = []
	var all_members = member_manager.all_members.values()
	
	for member in all_members:
		if not member.unlocked:
			if current_path != "res://project/scenes/main/main.tscn":
				continue  # 未入队只能在主场景
		candidates.append(member)
	
	# 限制数量
		# 限制生成数量 = 当前场景可用位置数 和 max_members_per_scene
	var max_to_spawn = mini(candidates.size(), spawn_points.size())
	max_to_spawn = mini(max_to_spawn, max_members_per_scene)
	
	candidates.shuffle()
	var to_spawn = candidates.slice(0, max_to_spawn)
	
	for member in to_spawn:
		if spawn_points.size() > 0:
			var point = spawn_points[randi() % spawn_points.size()]
			var offset = Vector2(
				randf_range(-60, 60),
				randf_range(-60, 60)
			)
			_spawn_member(member, point.global_position + offset)

func _spawn_member(member, pos: Vector2):
	var avatar_scene = preload("res://characters/MemberAvatar.tscn")
	if not avatar_scene:
		return
	
	var avatar = avatar_scene.instantiate()
	avatar.member_id = member.id
	avatar.global_position = pos
	avatar.add_to_group("scene_member")
	
	get_tree().current_scene.add_child(avatar)

func clear_existing_members():
	for node in get_tree().get_nodes_in_group("scene_member"):
		if is_instance_valid(node):
			node.queue_free()
