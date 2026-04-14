@tool
extends PanelContainer


enum Modes {EDIT, ADD}

var mode := Modes.EDIT
var item: TreeItem = null


func _ready() -> void:
	if get_parent() is SubViewport:
		return
	hide()
	%Character.resource_icon = load("res://addons/dialogic/Editor/Images/Resources/character.svg")
	%Character.suggestions_func = get_character_suggestions

	%WholeWords.icon = get_theme_icon("FontItem", "EditorIcons")
	%MatchCase.icon = get_theme_icon("MatchCase", "EditorIcons")

func _on_add_pressed() -> void:
	if visible:
		if mode == Modes.ADD:
			hide()
			return
		elif mode == Modes.EDIT:
			save()

	%AddButton.text = "Add"
	mode = Modes.ADD
	show()
	%Type.selected = 0
	_on_type_item_selected(0)
	%Where.selected = 2
	_on_where_item_selected(2)
	%Old.text = ""
	%New.text = ""


func open_existing(_item:TreeItem, info:Dictionary):
	mode = Modes.EDIT
	item = _item
	show()
	%AddButton.text = "Update"
	%Type.selected = info.type
	_on_type_item_selected(info.type)
	if !info.character_names.is_empty():
		%Where.selected = 1
		%Character.set_value(info.character_names[0])
	else:
		%Where.selected = 0
	_on_where_item_selected(%Where.selected)

	%Old.text = info.what
	%New.text = info.forwhat

	%MatchCase.button_pressed = info.case_sensitive
	%WholeWords.button_pressed = info.whole_words

func _on_type_item_selected(index:int) -> void:
	match index:
		0:
			%Where.select(0)
			%Where.set_item_disabled(0, false)
			%Where.set_item_disabled(1, false)
			%Where.set_item_disabled(2, true)
		1:
			%Where.select(0)
			%Where.set_item_disabled(0, false)
			%Where.set_item_disabled(1, false)
			%Where.set_item_disabled(2, true)
		2:
			%Where.select(1)
			%Where.set_item_disabled(0, true)
			%Where.set_item_disabled(1, false)
			%Where.set_item_disabled(2, true)
		3,4:
			%Where.select(0)
			%Where.set_item_disabled(0, false)
			%Where.set_item_disabled(1, true)
			%Where.set_item_disabled(2, true)
	%PureTextFlags.visible = index == 0
	_on_where_item_selected(%Where.selected)


func _on_where_item_selected(index:int) -> void:
	%Character.visible = index == 1


func get_character_suggestions(search_text:String) -> Dictionary:
	var suggestions := {}

	#override the previous _character_directory with the meta, specifically for searching otherwise new nodes wont work
	var _character_directory := DialogicResourceUtil.get_character_directory()

	var icon := load("res://addons/dialogic/Editor/Images/Resources/character.svg")
	suggestions['(No one)'] = {'value':null, 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}

	for resource in _character_directory.keys():
		suggestions[resource] = {
				'value' 	: resource,
				'tooltip' 	: _character_directory[resource],
				'icon' 		: icon.duplicate()}
	return suggestions


func save() -> void:
	if %Old.text.is_empty() or %New.text.is_empty():
		return
	if %Where.selected == 1 and %Character.current_value == null:
		return

	var previous := {}
	if mode == Modes.EDIT:
		previous = item.get_metadata(0)
		item.get_parent()
		item.free()

	var ref_manager := find_parent('ReferenceManager')
	var character_names := []
	if %Character.current_value != null:
		character_names = [%Character.current_value]
	ref_manager.add_ref_change(%Old.text, %New.text, %Type.selected, %Where.selected, character_names, %WholeWords.button_pressed, %MatchCase.button_pressed, previous)
	hide()

# 在 ResourceManager.gd 中添加或替换这个函数

# ==================== 声誉阶段系统（周末小游戏规模） ====================
const REPUTATION_STAGES = {
	"small":  {"min": 0,   "max": 39,  "name": "小型表演", "scale": 0.6, "desc": "小型酒吧驻唱，观众不多，但很亲切。"},
	"medium": {"min": 40,  "max": 79,  "name": "中型表演", "scale": 1.0, "desc": "中型场地演出，观众明显增多，氛围热烈。"},
	"large":  {"min": 80,  "max": 999, "name": "大型表演", "scale": 1.5, "desc": "大型舞台表演，观众爆满，影响力显著提升！"}
}

func get_reputation_stage() -> Dictionary:
	# 注意：这里用你项目中实际获取声誉的方式
	var rep = get_resource_value("reputation")   # ← 如果这个也不行，告诉我你实际用什么函数
	
	for stage_name in REPUTATION_STAGES:
		var stage = REPUTATION_STAGES[stage_name]
		if rep >= stage.min and rep <= stage.max:
			return stage
	
	return REPUTATION_STAGES["small"]
