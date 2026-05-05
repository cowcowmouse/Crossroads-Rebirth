extends Panel

var member_id: String = ""
var dialogue_lines: Array = []
var current_line: int = 0

@onready var portrait_rect: TextureRect = $PortraitRect
@onready var dialogue_text: RichTextLabel = $TextBox/DialogueText

func _ready():
	# 强制全屏 + 置顶 + 可见背景
	anchor_left = 0
	anchor_top = 0
	anchor_right = 1
	anchor_bottom = 1
	size = get_viewport_rect().size
	z_index = 2000
	
	# 给 Panel 添加半透明黑色背景（关键！）
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.85)  # 黑色半透明
	add_theme_stylebox_override("panel", style)
	
	print("✅ DialoguePanel 已强制全屏 + 背景显示")

func show_dialogue(id: String, portrait_path: String, lines: Array):
	member_id = id
	dialogue_lines = lines
	current_line = 0
	visible = true
	
	# 显示立绘
	if ResourceLoader.exists(portrait_path):
		portrait_rect.texture = load(portrait_path)
	
	_show_current_line()

func _show_current_line():
	if current_line < dialogue_lines.size():
		dialogue_text.text = dialogue_lines[current_line]
	else:
		_finish_dialogue()

# 点击任意位置下一句
func _input(event):
	if visible and event is InputEventMouseButton and event.pressed:
		current_line += 1
		_show_current_line()

func _finish_dialogue():
	if MemberManager and MemberManager.has_method("add_favor"):
		MemberManager.add_favor(member_id)
		print("❤️ 对话结束，好感度 +1")
	
	visible = false
	queue_free()
