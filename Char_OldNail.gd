extends CharacterBody2D

@onready var timer: Timer = $Timer
@onready var btn_recruit: Button = $Btn_Recruit

func _ready():
	if timer:
		timer.timeout.connect(_on_timer_timeout)

func _input_event(viewport: Viewport, _event: InputEvent, _shape: int) -> void:
	if _event is InputEventMouseButton and _event.pressed:
		print("✅ 角色被点击！")
		var talk_system = get_node_or_null("/root/main_scene/TalkSystem")
		if talk_system:
			talk_system.show_simple_chat("old_nail")
		else:
			print("❌ 找不到 TalkSystem")

func _on_timer_timeout():
	if btn_recruit:
		btn_recruit.disabled = false

func _on_btn_recruit_pressed():
	if btn_recruit:
		btn_recruit.disabled = true
	if timer:
		timer.start()

	var talk_system = get_node_or_null("/root/main_scene/TalkSystem")
	if talk_system:
		talk_system._recruit_member()
