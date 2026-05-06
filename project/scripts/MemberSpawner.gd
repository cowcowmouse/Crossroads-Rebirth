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

	var candidates = []
	
	for member in member_manager.all_members.values():
		if member.unlocked:
			# 已招募的成员：可以在所有场景出现
			candidates.append(member)
		else:
			# 未招募的成员：只能在主场景出现
			if current_path == "res://project/scenes/main/main.tscn":
				candidates.append(member)

	if candidates.is_empty():
		return

	# 限制生成数量
	var max_to_spawn = mini(candidates.size(), spawn_points.size())
	max_to_spawn = mini(max_to_spawn, max_members_per_scene)
	
	candidates.shuffle()
	var to_spawn = candidates.slice(0, max_to_spawn)
	
	# 打乱生成点
	var points = spawn_points.duplicate()
	points.shuffle()
	
	for i in range(to_spawn.size()):
		if i >= points.size():
			break
		var point = points[i]
		_spawn_member(to_spawn[i], point.global_position)
		print("✅ 生成成员：", to_spawn[i].name, " (", "已招募" if to_spawn[i].unlocked else "未招募", ")")

func _spawn_member(member, pos: Vector2):
	var clickable_scene = preload("res://project/scenes/characters/ClickableMember.tscn")
	if not clickable_scene:
		return
	
	var member_instance = clickable_scene.instantiate()
	member_instance.setup(member.id, member.portrait)
	member_instance.global_position = pos
	member_instance.add_to_group("scene_member")
	get_tree().current_scene.add_child(member_instance)

#func _spawn_member(member, pos: Vector2):
	# 【修改】使用可点击版本
	#var clickable_scene = preload("res://project/scenes/characters/ClickableMember.tscn")
	#if not clickable_scene:
	#	push_warning("找不到 ClickableMember.tscn")
	#	return
	
	#var member_instance = clickable_scene.instantiate()
	
	# 调用 setup（传入ID 和 立绘路径）
	# 如果你的 CharacterBase 里立绘字段不是 portrait，请改成实际名称（常见是 portrait 或 portrait_path）
	member_instance.setup(member.id, member.portrait)
	
	member_instance.global_position = pos
	member_instance.add_to_group("scene_member")
	get_tree().current_scene.add_child(member_instance)
	
	print("✅ 已生成可点击成员：", member.name, " (", member.id, ")")

func clear_existing_members():
	for node in get_tree().get_nodes_in_group("scene_member"):
		if is_instance_valid(node):
			node.queue_free()
