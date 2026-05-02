# BackgroundManager.gd
extends Node

@onready var background_rect: TextureRect = null

# ====================== 阶段背景映射 ======================
var phase_backgrounds := {
	"early": {
		"main": "res://project/assets/background/early_main.png",      # 主场景
		"lounge": "res://project/assets/background/early_lounge.png",
		"rehearsal": "res://project/assets/background/early_rehearsal.png"
	},
	"mid": {
		"main": "res://project/assets/background/mid_main.png",
		"lounge": "res://project/assets/background/mid_lounge.png",
		"rehearsal": "res://project/assets/background/mid_rehearsal.png"
	},
	"late": {
		"main": "res://project/assets/background/late_main.png",
		"lounge": "res://project/assets/background/late_lounge.png",
		"rehearsal": "res://project/assets/background/late_rehearsal.png"
	}
}

func _ready():
	await get_tree().process_frame
	_find_background()
	
	# 监听阶段变化
	if EventBus and EventBus.has_signal("game_phase_changed"):
		EventBus.game_phase_changed.connect(_on_phase_changed)
	elif GameManager:
		GameManager.connect("phase_changed", _on_phase_changed)  # 如果你用的是 signal

func _find_background():
	var scene = get_tree().current_scene
	if scene:
		background_rect = scene.get_node_or_null("UILayer/Background")  # 根据你的实际路径调整

func _on_phase_changed(new_phase: String):
	print("阶段切换为：", new_phase, "，更新背景")
	update_background_by_phase(new_phase)

# ====================== 根据阶段切换背景 ======================
func update_background_by_phase(phase: String = ""):
	if phase == "":
		phase = GameManager.get_current_phase() if GameManager else "early"
	
	if not background_rect:
		_find_background()
		if not background_rect:
			return
	
	var current_scene_name = get_tree().current_scene.name.to_lower()
	var bg_type = "main"
	
	if "lounge" in current_scene_name:
		bg_type = "lounge"
	elif "rehearsal" in current_scene_name:
		bg_type = "rehearsal"
	
	var path = phase_backgrounds.get(phase, {}).get(bg_type, "")
	
	if path and ResourceLoader.exists(path):
		_fade_to_new_background(path)
	else:
		print("警告：阶段背景缺失 -> ", phase, " / ", bg_type)

func _fade_to_new_background(new_path: String):
	var tween = create_tween()
	tween.tween_property(background_rect, "modulate:a", 0.0, 0.8)
	tween.tween_callback(func():
		background_rect.texture = load(new_path)
	)
	tween.tween_property(background_rect, "modulate:a", 1.0, 0.8)
