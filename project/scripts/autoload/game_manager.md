# 游戏全局管理器，控制游戏生命周期
extends Node

@onready var resource_manager = ResourceManager
@onready var week_cycle_controller = WeekCycleController
@onready var action_point_controller = ActionPointController

# 游戏启动入口
func _ready():
	start_new_game()

# 启动新游戏
func start_new_game():
	print("===== Crossroads: Rebirth 新游戏启动 =====")
	# 初始化所有模块
	resource_manager.init_new_game()
	action_point_controller.init_new_game()
	week_cycle_controller.init_new_game()
