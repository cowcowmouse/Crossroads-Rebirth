extends Control

@onready var name_label = $Panel/NameLabel
@onready var quit_button = $Panel/QuitButton

func _ready():
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func setup(title: String):
	print("设置结局名称: ", title)
	if name_label:
		name_label.text = "达成结局 " + title

func _on_quit_pressed():
	print("退出游戏")
	get_tree().quit()
