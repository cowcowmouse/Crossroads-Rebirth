extends Node
class_name ActionPointController

const MAX_ACTION_POINT: int = 3
var current_ap: int = MAX_ACTION_POINT

func _ready():
	if EventBus.has_signal("weekly_settlement_finished"):
		EventBus.weekly_settlement_finished.connect(_on_weekly_settlement_finished)

func can_execute_action(cost: int = 1) -> bool:
	return current_ap >= cost

func consume_action_point(cost: int = 1) -> bool:
	if current_ap < cost:
		return false

	current_ap -= cost

	if EventBus.has_signal("ui_refresh_requested"):
		EventBus.ui_refresh_requested.emit("action_points")

	if current_ap <= 0 and EventBus.has_signal("action_points_exhausted"):
		EventBus.action_points_exhausted.emit()

	return true

func restore_action_point():
	current_ap = MAX_ACTION_POINT
	if EventBus.has_signal("ui_refresh_requested"):
		EventBus.ui_refresh_requested.emit("action_points")

func _on_weekly_settlement_finished(_week):
	restore_action_point()
