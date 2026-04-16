extends Node

@onready var background_rect: TextureRect = null

func _ready():
	# 延迟获取背景节点，确保场景已加载
	await get_tree().process_frame
	_find_background()

func _find_background():
	var scene = get_tree().current_scene
	if scene:
		background_rect = scene.get_node_or_null("UILayer/Background")

func update_background():
	if not background_rect:
		_find_background()
		if not background_rect:
			return
	
	var cohesion = ResourceManager.get_cohesion()
	var art = ResourceManager.get_art_weight()
	var business = ResourceManager.get_business_weight()
	
	# 计算背景索引 0-5
	var index = 0
	if cohesion > 70: index += 1
	if art > 50: index += 2
	if business > 50: index += 3
	
	var bg_path = "res://project/assets/images/Background/bg_%d.png" % index
	if ResourceLoader.exists(bg_path):
		background_rect.texture = load(bg_path)

func update_memory_filter(memory_value: int):
	var filter_rect = get_tree().current_scene.get_node_or_null("UILayer/FilterRect")
	if not filter_rect:
		return
	
	var stage = 0
	if memory_value >= 70:
		stage = 2
	elif memory_value >= 30:
		stage = 1
	
	var filter_path = "res://art/filters/filter_stage_%d.png" % stage
	if ResourceLoader.exists(filter_path):
		filter_rect.texture = load(filter_path)
