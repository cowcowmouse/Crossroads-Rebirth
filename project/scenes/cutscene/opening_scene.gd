extends Control

@onready var cg = $CG
@onready var crash_light = $CrashLight
@onready var fade_rect = $FadeRect
@onready var name_label = $DialogueBox/VBox/NameLabel
@onready var dialogue_text = $DialogueBox/VBox/DialogueText
@onready var hint_label = $DialogueBox/VBox/HintLabel

@export var page_1_image: Texture2D
@export var page_2_image: Texture2D
@export var page_3_image: Texture2D
@export var page_4_image: Texture2D
@export var next_scene: PackedScene

var page_index := 0
var locked := false
var pages := []

func _ready():
	pages = [
		{
			"name": "旁白",
			"text": "那一夜，灯光像火一样落在我的肩上。",
			"image": page_1_image
		},
		{
			"name": "旁白",
			"text": "掌声、刹车声、碎裂声……最后全都混成了一片白光。",
			"image": page_2_image
		},
		{
			"name": "旁白",
			"text": "那就是我唯一记得的事情了。",
			"image": page_3_image
		},
		{
			"name": "Alexi",
			"text": "欢迎来到熔炉。现在，它只剩下我了。",
			"image": page_4_image
		}
	]

	fade_rect.color = Color(0, 0, 0, 1)
	crash_light.color = Color(1, 1, 1, 0.0)

	_show_page(0)

	var tw = create_tween()
	tw.tween_property(fade_rect, "color:a", 0.0, 0.6)

func _input(event):
	if locked:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_next_page()
	elif event.is_action_pressed("ui_accept"):
		_next_page()

func _show_page(index: int):
	var page = pages[index]
	name_label.text = page["name"]
	dialogue_text.text = page["text"]
	hint_label.text = "点击继续"
	cg.texture = page["image"]

	crash_light.color = Color(1, 1, 1, 0.0)

	if index == 1:
		var tw = create_tween()
		tw.tween_property(crash_light, "color:a", 0.20, 0.08)
		tw.tween_property(crash_light, "color:a", 0.10, 0.20)

func _next_page():
	locked = true

	var tw = create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, 0.25)
	await tw.finished

	page_index += 1

	if page_index >= pages.size():
		if next_scene:
			get_tree().change_scene_to_packed(next_scene)
		else:
			push_error("next_scene 没有指定")
		return

	_show_page(page_index)

	var tw2 = create_tween()
	tw2.tween_property(fade_rect, "color:a", 0.0, 0.25)
	await tw2.finished

	locked = false
