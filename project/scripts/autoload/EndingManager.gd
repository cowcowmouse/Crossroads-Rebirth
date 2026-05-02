extends Node

signal ending_triggered(ending_key: String)
var is_ending_triggered: bool = false
var is_ending_processing: bool = false

signal final_performance_started()  # 新增：最终演出开始信号
signal final_performance_finished(success: bool)  # 新增：最终演出结束信号

var pending_performance_result: bool = false  # 存储小游戏结果

var endings = {
	# ==================== 艺术方向 ====================
	"art_perfect": {
		"title": "艺术巅峰",
		"opening": "你的音乐震撼了世界，艺术之魂在舞台上燃烧。",
		"middle_recovery": "记忆完全复苏，你终于明白——\n音乐不是逃避，而是你存在的证明。",
		"middle_result": "最后的演出大获成功！\n全场观众起立欢呼，泪水与掌声交织。",
		"closing": "你站在舞台中央，灯光照亮了你的脸。\n这一刻，你就是艺术本身。",
		"has_song": true,
		"has_bg": true,
		"bg": "res://project/assets/images/Background/art_perfect-001.png"
	},
	"art_imperfect": {
		"title": "艺术遗憾",
		"opening": "你的音乐震撼了世界，艺术之魂在舞台上燃烧。",
		"middle_recovery": "记忆完全复苏，你终于明白——\n音乐不是逃避，而是你存在的证明。",
		"middle_result": "但最后的演出并不完美...\n有些音符偏离了轨道，有些情感未能传达。",
		"closing": "也许这就是命运的安排。\n完美本就不存在，重要的是你曾站上舞台。",
		"has_song": false,
		"has_bg": true,
		"bg": ""
	},
	"art_success": {
		"title": "艺术之路",
		"opening": "你的音乐感动了很多人，艺术的种子在生根发芽。",
		"middle_recovery": "虽然记忆没有完全恢复，但你找到了新的方向。\n音乐不再是执念，而是陪伴。",
		"middle_result": "最后的演出获得成功！\n观众被你们的真诚打动。",
		"closing": "音乐就是你的家。\n无论记忆是否完整，你都不会再迷路。",
		"has_song": false,
		"has_bg": true,
		"bg": "res://project/assets/images/Background/art_success.png"
	},
	"art_regret": {
		"title": "艺术遗憾",
		"opening": "你的音乐感动了很多人，艺术的种子在生根发芽。",
		"middle_recovery": "虽然记忆没有完全恢复，但你找到了新的方向。\n音乐不再是执念，而是陪伴。",
		"middle_result": "但最后的演出失败了...\n舞台上的失误让你意识到还有很长的路要走。",
		"closing": "至少，你们曾经努力过。\n失败也是艺术的一部分。",
		"has_song": false,
		"has_bg": true,
		"bg": "res://project/assets/images/Background/art_regret-001.png"
	},
	
	# ==================== 商业方向 ====================
	"business_perfect": {
		"title": "商业帝国",
		"opening": "你们的乐队成为了商业传奇，每一首歌都是金曲。",
		"middle_recovery": "记忆完全复苏，你终于明白——\n商业和艺术可以共存，利益与梦想并不冲突。",
		"middle_result": "最后的演出大获成功！\n票房破纪录，媒体争相报道。",
		"closing": "你站在商业与艺术的巅峰。\n这就是你证明自己的方式。",
		"has_song": true,
		"has_bg": true,
		"bg": "res://project/assets/images/Background/business_perfect.png"
	},
	"business_imperfect": {
		"title": "商业遗憾",
		"opening": "你们的乐队成为了商业传奇，每一首歌都是金曲。",
		"middle_recovery": "记忆完全复苏，你终于明白——\n商业和艺术可以共存，利益与梦想并不冲突。",
		"middle_result": "但最后的演出并不完美...\n技术上的失误让这场演出留下遗憾。",
		"closing": "总觉得少了些什么。\n也许成功和完美不能兼得。",
		"has_song": false,
		"has_bg": true,
		"bg": "res://project/assets/images/Background/business_imperfect.png"
	},
	"business_success": {
		"title": "商业成功",
		"opening": "你们的乐队在商业上获得了成功，专辑销量节节攀升。",
		"middle_recovery": "虽然没有完全找回记忆，但你们找到了生存之道。\n商业给了你们继续做音乐的机会。",
		"middle_result": "最后的演出获得成功！\n粉丝的热情让你感动。",
		"closing": "金钱不是一切，但也很重要。\n你们找到了平衡。",
		"has_song": false,
		"has_bg": true,
		"bg": "res://project/assets/images/Background/business_success.png"
	},
	"business_regret": {
		"title": "商业遗憾",
		"opening": "你们的乐队在商业上获得了成功，专辑销量节节攀升。",
		"middle_recovery": "虽然没有完全找回记忆，但你们找到了生存之道。\n商业给了你们继续做音乐的机会。",
		"middle_result": "但最后的演出失败了...\n舞台上的失误让你怀疑自己的选择。",
		"closing": "也许你们选错了路。\n但至少，你们没有放弃。",
		"has_song": false,
		"has_bg": true,
		"bg": "res://project/assets/images/Background/business_regret-001.png"
	},
	
	# ==================== 人情方向 ====================
	"human_perfect": {
		"title": "羁绊永恒",
		"opening": "你们不仅是乐队，更是一家人，彼此扶持走到今天。",
		"middle_recovery": "记忆完全复苏，你终于明白——\n最重要的是身边的人，是那些从未离开的人。",
		"middle_result": "最后的演出大获成功！\n台上台下，心连心。",
		"closing": "这就是家的感觉。\n无论走到哪里，你们都不会孤单。",
		"has_song": true,
		"has_bg": true,
		"bg": "res://project/assets/images/Background/human_perfect-001.png"
	},
	"human_imperfect": {
		"title": "羁绊遗憾",
		"opening": "你们不仅是乐队，更是一家人，彼此扶持走到今天。",
		"middle_recovery": "记忆完全复苏，你终于明白——\n最重要的是身边的人，是那些从未离开的人。",
		"middle_result": "但最后的演出并不完美...\n有些情感没能完全传达。",
		"closing": "总觉得对不起伙伴们。\n但你们依然在一起。",
		"has_song": false,
		"has_bg": true,
		"bg": "res://project/assets/images/Background/human_imperfect-001.png"
	},
	"human_success": {
		"title": "羁绊之路",
		"opening": "你们成为了彼此的家人，每一个成员都不可或缺。",
		"middle_recovery": "虽然没有完全找回记忆，但你们找到了比记忆更重要的东西。\n是信任，是陪伴。",
		"middle_result": "最后的演出获得成功！\n你们的默契感动了所有人。",
		"closing": "你们永远在一起。\n这就是最珍贵的财富。",
		"has_song": false,
		"has_bg": true,
		"bg": "res://project/assets/images/Background/human_success-001.png"
	},
	"human_regret": {
		"title": "羁绊遗憾",
		"opening": "你们成为了彼此的家人，每一个成员都不可或缺。",
		"middle_recovery": "虽然没有完全找回记忆，但你们找到了比记忆更重要的东西。\n是信任，是陪伴。",
		"middle_result": "但最后的演出失败了...\n默契还是差了一点。",
		"closing": "但你们依然在一起。\n也许这就够了。",
		"has_song": false,
		"has_bg": true,
		"bg": "res://project/assets/images/Background/human_regret-001.png"
	},
	
	# ==================== 坏结局 ====================
	"bad_ending": {
		"title": "落魄街头",
		"opening": "酒吧倒闭了，乐队也散了。",
		"middle_recovery": "",
		"middle_result": "",
		"closing": "你再次消失在夜色中，\n没有人知道你去了哪里。\n也许这就是命。",
		"has_song": false,
		"has_bg": true,
		"bg": "res://project/assets/images/Background/bad_ending.png"
	}
}

# ==================== 结局判定 ====================
func check_ending():
	if is_ending_triggered or is_ending_processing:
		print("结局已在处理中，跳过")
		return
	
	var week = GameManager.get_current_week()
	var debt_weeks = ResourceManager.get_debt_weeks()
	var memory = ResourceManager.get_memory()
	
	print("=== 检查结局条件 ===")
	print("当前周数: ", week)
	print("负债周数: ", debt_weeks)
	print("记忆恢复度: ", memory)
	
	if debt_weeks >= 3:
		print("触发坏结局：负债持续 ", debt_weeks, " 周")
		_trigger_ending("bad_ending")
		return
	
	if week >= 30:
		is_ending_processing = true
		
		# 只判断记忆恢复度是否达到 100
		if memory >= 100:
			print("✅ 记忆恢复度达到 100，启动最终演出小游戏")
			_start_final_performance()
		else:
			print("❌ 记忆恢复度未达到 100，直接结算结局")
			_direct_ending_without_performance()
		return
	
	if debt_weeks >= 3:
		print("⚠️ 警告：已负债 ", debt_weeks, " 周，但当前周数 ", week)
		
func _trigger_normal_ending():
	var memory = ResourceManager.get_memory()
	var top_weight = _get_top_weight()
	var performance_success = true  # TODO: 接入最终演出小游戏结果
	
	var ending_key = ""
	
	if memory >= 100:
		if performance_success:
			ending_key = "%s_perfect" % top_weight
		else:
			ending_key = "%s_imperfect" % top_weight
	else:
		if performance_success:
			ending_key = "%s_success" % top_weight
		else:
			ending_key = "%s_regret" % top_weight
	
	_trigger_ending(ending_key)

func _get_top_weight() -> String:
	var art = ResourceManager.get_art_weight()
	var business = ResourceManager.get_business_weight()
	var human = ResourceManager.get_human_weight()
	
	if art >= business and art >= human:
		return "art"
	elif business >= art and business >= human:
		return "business"
	else:
		return "human"

# ==================== 触发结局 ====================
func _trigger_ending(ending_key: String):
	if is_ending_triggered:
		print("结局已触发，跳过")
		return
	
	is_ending_triggered = true
	print("触发结局: ", ending_key)
	ending_triggered.emit(ending_key)
	
	# 延迟一帧再切换场景，避免与当前流程冲突
	await get_tree().process_frame
	
	var ending_scene_path = "res://project/scenes/End/EndingDialog.tscn"
	var tree = get_tree()
	if not tree:
		return
	
	tree.change_scene_to_file(ending_scene_path)
	
	await tree.process_frame
	var current_scene = tree.current_scene
	if current_scene and current_scene.has_method("setup"):
		current_scene.setup(ending_key)
	
	is_ending_processing = false

func trigger_bad_ending():
	print("触发坏结局")
	_trigger_ending("bad_ending")

# ==================== 获取结局数据 ====================
func get_ending(ending_key: String) -> Dictionary:
	return endings.get(ending_key, endings["bad_ending"])

# 获取方向值的大小
func _get_weight_value(weight_type: String) -> int:
	match weight_type:
		"art":
			return ResourceManager.get_art_weight()
		"business":
			return ResourceManager.get_business_weight()
		"human":
			return ResourceManager.get_human_weight()
	return 0

# 启动最终演出小游戏
func _start_final_performance():
	print("启动最终演出小游戏")
	final_performance_started.emit()
	
	# 切换小游戏场景
	var minigame_path = "res://project/scenes/minigame/final_performance.tscn"
	var tree = get_tree()
	if not tree:
		return
	
	tree.change_scene_to_file(minigame_path)

# 小游戏结束后调用（由小游戏场景调用）
func on_final_performance_finished(success: bool):
	print("最终演出结束，成功: ", success)
	pending_performance_result = success
	final_performance_finished.emit(success)
	
	# 回到主场景
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file("res://project/scenes/main/main.tscn")
		await tree.process_frame
	
	# 根据小游戏结果结算结局
	_finalize_ending_with_performance()
	
func _direct_ending_without_performance():
	var memory = ResourceManager.get_memory()
	var top_weight = _get_top_weight()
	
	var ending_key = ""
	
	# 记忆不满，走成功/遗憾（无演出，视为失败）
	if memory >= 100:
		# 这个分支实际上不会进来，但保留作为安全
		ending_key = "%s_imperfect" % top_weight
	else:
		# 记忆不满，按方向值走成功/遗憾结局
		ending_key = "%s_regret" % top_weight
	
	print("无演出结局: ", ending_key)
	_trigger_ending(ending_key)

# 根据小游戏结果结算结局
func _finalize_ending_with_performance():
	var memory = ResourceManager.get_memory()
	var top_weight = _get_top_weight()
	var performance_success = pending_performance_result
	
	var ending_key = ""
	
	if memory >= 100:
		if performance_success:
			ending_key = "%s_perfect" % top_weight
		else:
			ending_key = "%s_imperfect" % top_weight
	else:
		if performance_success:
			ending_key = "%s_success" % top_weight
		else:
			ending_key = "%s_regret" % top_weight
	
	_trigger_ending(ending_key)
