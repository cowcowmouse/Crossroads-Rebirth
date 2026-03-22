extends Node2D

func _ready():
	print("=== 测试资源系统 ===")
	print("初始资金: ", ResourceManager.get_fund())
	
	ResourceManager.resource_changed.connect(_on_resource_changed)
	
	# 测试加钱
	ResourceManager.add_money(1000)
	print("加1000后: ", ResourceManager.get_fund())
	
	# 测试扣钱
	ResourceManager.add_money(-500)
	print("扣500后: ", ResourceManager.get_fund())
	
	# 测试周数
	print("当前周数: ", GameManager.get_current_week())
	
func _on_resource_changed(resource_name: String, new_value: int, delta: int):
	print("[信号] ", resource_name, ": 变化", delta, "，当前值: ", new_value)

func _process(delta):
	if Input.is_key_pressed(KEY_SPACE):
		GameManager.next_week()
		print("进入第", GameManager.get_current_week(), "周")
