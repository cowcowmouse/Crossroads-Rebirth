extends Node2D

@onready var close_button = $CloseButton
@onready var test_button = $TestButton
var event_handler

func _ready():
	test_button.pressed.connect(_on_test_button_pressed)
	
	print("正在创建 EventHandler...")
	event_handler = load("res://project/scripts/models/events/event_handler.gd").new()
	add_child(event_handler)
	print("EventHandler 已创建")
	
	print("测试场景已启动")
	print("点击按钮触发随机事件")
	
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
		print("点击关闭按钮返回主场景")
		
func _on_test_button_pressed():
	print("=================================================")
	print("按钮被点击")
	print("=================================================")
	
	if event_handler:
		event_handler.trigger_random_event()
	else:
		print("错误: EventHandler 不存在")

func _on_close_button_pressed():
	print("关闭按钮被点击，直接返回主场景")
	get_tree().change_scene_to_file("res://project/scenes/main/main.tscn")
