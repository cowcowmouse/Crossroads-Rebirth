extends Button

func _ready():
	pressed.connect(_on_button_pressed)
	
func _on_button_pressed():
	print("🔥 按钮点到了！准备启动对话: old_nail")
	Dialogic.start("old_nail")
