extends Button

@export var facility_type: String = "stage"
@export var panel_path: NodePath

var panel: Node = null

func _ready():
	if panel_path != NodePath():
		panel = get_node(panel_path)
	pressed.connect(_on_pressed)

func _on_pressed():
	if panel and panel.has_method("open_panel"):
		panel.open_panel(facility_type)
