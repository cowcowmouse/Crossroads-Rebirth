extends Button

@export var facility_type: String = "stage"

@onready var repair_mask = get_node_or_null("RepairMask")

var normal_scale: Vector2
var pressed_scale := Vector2(0.94, 0.94)

func _ready():
	normal_scale = scale
	focus_mode = Control.FOCUS_NONE
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	mouse_exited.connect(_on_mouse_exited)
	refresh_repair_state()

func refresh_repair_state():
	var repairing = ResourceManager.is_facility_upgrading(facility_type)
	if repair_mask:
		repair_mask.visible = repairing

func _on_button_down():
	if ResourceManager.is_facility_upgrading(facility_type):
		return
	scale = Vector2(normal_scale.x * pressed_scale.x, normal_scale.y * pressed_scale.y)

func _on_button_up():
	scale = normal_scale

func _on_mouse_exited():
	scale = normal_scale

func _pressed():
	if ResourceManager.is_facility_upgrading(facility_type):
		return
	scale = normal_scale
	$"../FacilityPanel".open_panel(facility_type)
