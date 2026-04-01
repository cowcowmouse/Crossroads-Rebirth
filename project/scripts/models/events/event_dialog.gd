extends Panel

signal option_selected(event_id: String, option_index: int, effects: Dictionary)

@onready var title_label = $TitleLabel
@onready var desc_label = $DescLabel
@onready var button_container = $ButtonContainer
@onready var result_panel = $ResultPanel
@onready var result_label = $ResultPanel/ResultLabel
@onready var close_button = $CloseButton

var current_event_id: String = ""
var current_options: Array = []

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	close_button.visible = false
	result_panel.visible = false
	hide()

func show_event(event_data: Dictionary):
	print("EventDialog: 显示事件")
	
	current_event_id = event_data.get("event_id", event_data.get("id", "unknown"))
	current_options = event_data.get("options", [])
	
	title_label.text = event_data.get("title", "事件")
	desc_label.text = event_data.get("description", event_data.get("dialog", ""))
	
	_setup_option_buttons()
	
	result_panel.visible = false
	close_button.visible = false
	button_container.visible = true
	
	show()

func _setup_option_buttons():
	var buttons = button_container.get_children()
	
	for btn in buttons:
		btn.visible = false
	
	for i in range(current_options.size()):
		if i < buttons.size():
			var btn = buttons[i]
			var option = current_options[i]
			
			btn.visible = true
			btn.text = option.get("text", "选项 " + str(i + 1))
			
			if option.get("unavailable", false):
				btn.disabled = true
			else:
				btn.disabled = false
			
			if btn.pressed.is_connected(_on_option_pressed):
				btn.pressed.disconnect(_on_option_pressed)
			btn.pressed.connect(_on_option_pressed.bind(i))

func _on_option_pressed(option_index: int):
	var option = current_options[option_index]
	
	if option.get("unavailable", false):
		return
	
	result_label.text = option.get("result_text", "你做出了选择")
	result_panel.visible = true
	button_container.visible = false
	close_button.visible = true
	
	option_selected.emit(
		current_event_id,
		option_index,
		option.get("effects", {})
	)

func _on_close_pressed():
	print("EventDialog: 关闭")
	hide()
