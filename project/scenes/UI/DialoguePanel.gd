extends Panel

var member_id: String = ""
var current_line: int = 0
var dialogue_lines: Array = []

@onready var portrait_rect: TextureRect = $PortraitRect
@onready var dialogue_text: RichTextLabel = $TextBox/DialogueText

func show_dialogue(id: String, portrait_path: String):
	member_id = id
	current_line = 0
	visible = true
	
	# 显示立绘
	if ResourceLoader.exists(portrait_path):
		portrait_rect.texture = load(portrait_path)
	
	# 检查本周对话次数限制
	if MemberManager and MemberManager.has_method("talk_to_member"):
		if not MemberManager.talk_to_member(id):
			dialogue_lines = ["需要休息一下，你先和别人玩吧~"]
			_show_current_line()
			return
	
	# 获取当前关系度
	var relationship = 0
	var member = MemberManager.get_member(id) if MemberManager else null
	if member and "relationship_progress" in member:
		relationship = member.relationship_progress
	elif member and "relationship" in member:
		relationship = member.relationship
	
	# 根据关系度选择对话阶段
	if relationship < 30:
		# 陌生阶段（0~29）
		match id:
			"old_nail": dialogue_lines = ["小心身体。", "这家店，不能倒。", "…… 别学你父亲。"]
			"kira": dialogue_lines = ["你好呀～需要合影吗？", "网上的评论我都习惯了。", "工作而已，别太当真。"]
			"mei": dialogue_lines = ["你好，需要帮忙吗？", "音乐能让人平静。", "大家好好相处最重要。"]
			"finn": dialogue_lines = ["…… 你的手，废了。", "别在我面前装样子。", "你的琴里没有火。"]
			"sebastian": dialogue_lines = ["谈合作？先看价值。", "一切都有价格，包括你。", "我只投资能赢的项目。"]
			"lily": dialogue_lines = ["乐谱必须精准，不能错。", "古典音乐是我的全部。", "失控是错误，是失败。"]
			"aya": dialogue_lines = ["音乐能治愈人心。", "你听过小镇的声音吗？", "我们可以办一场义演。"]
			"duane": dialogue_lines = ["系统稳定。误差正常。", "音乐可以被计算、被优化。", "情绪是不稳定因素。"]
			"rio": dialogue_lines = ["有事吗？我在休息。", "别管我，我自己待着就好。", "打鼓？早就不碰了。"]
			_: dialogue_lines = ["你好。", "有什么事吗？"]
	
	elif relationship < 60:
		# 熟悉阶段（30~59）
		match id:
			"old_nail": dialogue_lines = ["我看着你长大。", "当年的事，我有苦衷。", "我答应过你爸，要护住你。"]
			"kira": dialogue_lines = ["镜头前的我，不是真的我。", "我想唱能打动人心的歌，不是口水歌。", "我怕一做自己，就没人喜欢我了。"]
			"mei": dialogue_lines = ["我教孩子是生活，和你们一起是梦想。", "团队不能散，我会护住大家。", "矛盾总会有的，但我们可以一起解决。"]
			"finn": dialogue_lines = ["我能教你技术，但教不会你灵魂。", "以前的你，眼里有光。现在只剩灰。", "那场车祸…… 算了，不提了。"]
			"sebastian": dialogue_lines = ["艺术很美好，但不能当饭吃。", "我可以帮你，但你要付出代价。", "我开始觉得…… 你有点特别。"]
			"lily": dialogue_lines = ["我想试试不按谱子演奏。", "自由…… 是什么感觉？", "我害怕，又有点期待。"]
			"aya": dialogue_lines = ["音乐不是商品，是连接。", "我能感觉到大家的痛苦与希望。", "你很温柔，我看得出来。"]
			"duane": dialogue_lines = ["一点点 “噪声”，似乎也可以接受。", "人性化…… 这变量很有趣。", "我想试试 “可控的失控”。"]
			"rio": dialogue_lines = ["我一拿起鼓棒，手就会抖…… 心里更慌。", "酒精能让我平静，但也在一点点吃掉我。", "我怕上台，更怕再也上不了台。"]
			_: dialogue_lines = ["我们好像越来越熟了。", "最近怎么样？"]
	
	else:
		# 信任阶段（60+）
		match id:
			"old_nail": dialogue_lines = ["你终于走出来了。", "我守住了承诺，守住了店，也守住了你。", "欢迎回家，Alexi。"]
			"kira": dialogue_lines = ["在你面前，我终于可以不用伪装。", "真正的凯拉，回来了。", "我们一起做能留在世界上的音乐。"]
			"mei": dialogue_lines = ["你们就是我的家人。", "有我在，没人会被丢下。", "音乐不是一个人的光芒，是一群人的温暖。"]
			"finn": dialogue_lines = ["你的火，回来了。", "我承认，我输给了你。", "从今以后，我们不是敌人，是同伴。"]
			"sebastian": dialogue_lines = ["也许有些东西，钱买不到。", "我投的不是酒吧，是你这个人。", "我们不是商人与工具，是伙伴。"]
			"lily": dialogue_lines = ["我终于学会失控，也学会了自由。", "音乐没有对错，只有真心。", "谢谢你们，让我成为完整的自己。"]
			"aya": dialogue_lines = ["这里就是所有人的家。", "我们用音乐守护彼此。", "这才是音乐真正的意义。"]
			"duane": dialogue_lines = ["我找到了属于我的噪声。", "逻辑之外，还有人心。", "你们是我最稳定的系统。"]
			"rio": dialogue_lines = ["是你让我敢再拿起鼓槌。谢谢你。", "我想活下去，不是混日子，是真正地活着。", "从今天起，我为自己、为乐队、为你，好好打鼓。"]
			_: dialogue_lines = ["谢谢你一直陪着我。", "我们是真正的伙伴了。"]
	
	# 每次点击都随机打乱顺序
	dialogue_lines.shuffle()
	_show_current_line()
func _show_current_line():
	if current_line < dialogue_lines.size():
		dialogue_text.text = dialogue_lines[current_line]
	else:
		_finish_dialogue()

func _input(event):
	if visible and event is InputEventMouseButton and event.pressed:
		current_line += 1
		_show_current_line()

func _finish_dialogue():
	# 对话结束 → 加关系度 +10
	if MemberManager and MemberManager.has_method("add_relationship_progress"):
		var new_progress = MemberManager.add_relationship_progress(member_id, 10)
		print("❤️ ", member_id, " 关系度 +10 → 当前 ", new_progress)
	else:
		print("⚠️ MemberManager.add_relationship_progress 方法不存在")

	visible = false
	queue_free()
