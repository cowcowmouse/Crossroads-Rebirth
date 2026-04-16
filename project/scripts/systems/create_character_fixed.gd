@tool
extends EditorScript

func _run():
	var ids = ["rio", "kira", "mei", "finn", "sebastian", "lily", "aya", "duane", "old_nail"]
	var personality_map = {
		"rio": "酒精心魔",
		"kira": "流量vs真实",
		"mei": "团队粘合剂",
		"finn": "旧友宿敌",
		"sebastian": "资本代理人",
		"lily": "古典叛逃",
		"aya": "音乐治疗",
		"duane": "数据与感性",
		"old_nail": "守护者"
	}
	
	for id in ids:
		var path = "res://project/data/members/%s.tres" % id
		if ResourceLoader.exists(path):
			var char = load(path)
			if char.personality == "" or char.personality == null:
				char.personality = personality_map.get(id, "")
				ResourceSaver.save(char)
				print("修复: ", id, " -> ", char.personality)
			else:
				print("跳过: ", id, " 已有 personality: ", char.personality)
		else:
			print("警告: 找不到 ", path)
	
	print("修复完成！")
