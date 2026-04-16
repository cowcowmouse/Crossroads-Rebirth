extends Node

signal ending_triggered(ending_key: String)

enum EndingType {
	ART_PERFECT, ART_IMPERFECT, ART_SUCCESS, ART_REGRET,
	BUSINESS_PERFECT, BUSINESS_IMPERFECT, BUSINESS_SUCCESS, BUSINESS_REGRET,
	HUMAN_PERFECT, HUMAN_IMPERFECT, HUMAN_SUCCESS, HUMAN_REGRET,
	BAD_ENDING
}

func check_ending():
	var week = GameManager.get_current_week()
	var debt_weeks = ResourceManager.get_debt_weeks()
	
	# BE 检测：负债持续3周
	if debt_weeks >= 3:
		_trigger_ending("bad_ending")
		return
	
	# 正常结局检测：周数 >= 18
	if week >= 18:
		_trigger_normal_ending()

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

func _trigger_ending(ending_key: String):
	print("触发结局: ", ending_key)
	ending_triggered.emit(ending_key)
	
	# 显示结局面板
	var ending_scene = load("res://scenes/ui/EndingPanel.tscn")
	if ending_scene:
		var panel = ending_scene.instantiate()
		get_tree().current_scene.add_child(panel)
		panel.setup(ending_key)

func get_ending_description(ending_key: String) -> Dictionary:
	var endings = {
		"art_perfect": {
			"title": "艺术巅峰",
			"desc": "你的音乐震撼了世界，记忆也完全复苏。\n\n你们登上了最大的音乐节舞台，\n全场观众为你们的音乐欢呼。\n\n这才是真正的艺术，真正的自由。",
			"has_song": true,
			"bg": "res://art/endings/art_perfect.png"
		},
		"art_imperfect": {
			"title": "艺术遗憾",
			"desc": "虽然记忆复苏，但最后的演出并不完美。\n\n你们的音乐依然动人，\n只是缺少了那一点火花。\n\n也许下次会更好。",
			"has_song": false,
			"bg": "res://art/endings/art_imperfect.png"
		},
		"art_success": {
			"title": "艺术之路",
			"desc": "你们的音乐感动了很多人。\n\n虽然没有完全找回记忆，\n但你们找到了新的方向。\n\n音乐就是你们的家。",
			"has_song": false,
			"bg": "res://art/endings/art_success.png"
		},
		"art_regret": {
			"title": "艺术遗憾",
			"desc": "最后的演出失败了。\n\n你们的音乐没能打动观众，\n记忆也依然模糊。\n\n但至少，你们曾经努力过。",
			"has_song": false,
			"bg": "res://art/endings/art_regret.png"
		},
		"business_perfect": {
			"title": "商业帝国",
			"desc": "你们的乐队成为了商业传奇。\n\n专辑销量破纪录，巡演一票难求。\n\n记忆也完全复苏，\n你终于明白，商业和艺术可以共存。",
			"has_song": true,
			"bg": "res://art/endings/business_perfect.png"
		},
		"business_imperfect": {
			"title": "商业遗憾",
			"desc": "商业上取得了成功，但最后的演出并不完美。\n\n记忆虽然复苏，\n但总觉得少了些什么。\n\n也许商业不是全部。",
			"has_song": false,
			"bg": "res://art/endings/business_imperfect.png"
		},
		"business_success": {
			"title": "商业成功",
			"desc": "你们的乐队在商业上获得了成功。\n\n虽然没有完全找回记忆，\n但你们找到了生存之道。\n\n金钱不是一切，但也很重要。",
			"has_song": false,
			"bg": "res://art/endings/business_success.png"
		},
		"business_regret": {
			"title": "商业遗憾",
			"desc": "最后的演出失败了。\n\n商业上的成功无法弥补舞台上的失落。\n\n也许你们选错了路。",
			"has_song": false,
			"bg": "res://art/endings/business_regret.png"
		},
		"human_perfect": {
			"title": "羁绊永恒",
			"desc": "你们不仅是乐队，更是一家人。\n\n记忆完全复苏，\n你终于明白，\n最重要的是身边的人。",
			"has_song": true,
			"bg": "res://art/endings/human_perfect.png"
		},
		"human_imperfect": {
			"title": "羁绊遗憾",
			"desc": "你们的感情很深，但最后的演出不够完美。\n\n记忆虽然复苏，\n但总觉得对不起伙伴们。",
			"has_song": false,
			"bg": "res://art/endings/human_imperfect.png"
		},
		"human_success": {
			"title": "羁绊之路",
			"desc": "你们成为了彼此的家人。\n\n虽然没有完全找回记忆，\n但你们找到了比记忆更重要的东西。",
			"has_song": false,
			"bg": "res://art/endings/human_success.png"
		},
		"human_regret": {
			"title": "羁绊遗憾",
			"desc": "最后的演出失败了。\n\n但你们依然在一起。\n\n也许这就够了。",
			"has_song": false,
			"bg": "res://art/endings/human_regret.png"
		},
		"bad_ending": {
			"title": "落魄街头",
			"desc": "酒吧倒闭，乐队解散。\n\n你再次消失在夜色中，\n没有人知道你去了哪里。\n\n也许这就是命。",
			"has_song": false,
			"bg": "res://art/endings/bad_ending.png"
		}
	}
	
	return endings.get(ending_key, endings["bad_ending"])
