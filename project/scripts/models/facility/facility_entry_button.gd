extends Button

@export var facility_type: String = "stage"

func _pressed():
	$"../FacilityPanel".open_panel(facility_type)
