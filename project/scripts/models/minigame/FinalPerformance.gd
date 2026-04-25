extends Control

const NOTE_SCENE = preload("res://project/scenes/minigame/Note.tscn")

# 三条音轨现在改为“选择后的音乐风格层”，不是按键音效。
# 三个文件必须和 final_neoclassical.mp3 同长度、同起点、同 BPM。
const LANE_1_STEM_PATH = "res://project/audio/bgm/final_lane_1_rhythm_stem.mp3"
const LANE_2_STEM_PATH = "res://project/audio/bgm/final_lane_2_pick_stem.mp3"
const LANE_3_STEM_PATH = "res://project/audio/bgm/final_lane_3_harmonic_stem.mp3"

const STEM_MUTED_DB := -80.0

# 默认值只作为兜底。优先读取 final_performance_chart.json 里的 choice_points 配置。
const CHOICE_DEFAULT_RETURN_TIME := 95.0
const CHOICE_MAIN_DUCK_DB := -16.0
const CHOICE_FADE_IN := 1.00
const CHOICE_FADE_OUT := 1.80
const CHOICE_BUSINESS_STEM_VOLUME_DB := -1.0
const CHOICE_HUMAN_STEM_VOLUME_DB := -1.2
const CHOICE_ART_STEM_VOLUME_DB := -1.5

# 当前按键不再控制音乐层，只保留旧函数兼容。
const STEM_TAP_GATE_TIME := 0.30
const STEM_HOLD_FADE_IN := 0.045
const STEM_HOLD_FADE_OUT := 0.12

# 最终独奏增强参数。
const FINAL_SOLO_MAIN_DUCK_DB := -1.8
const FINAL_SOLO_STEM_VOLUME_DB := -6.0
const FINAL_SOLO_FADE_IN := 1.0
const FINAL_SOLO_FADE_OUT := 1.2
const FINAL_SOLO_MIN_INTENSITY := 0.78
const FINAL_SOLO_HIT_INTENSITY_GAIN := 0.075
const FINAL_SOLO_PERFECT_FLASH_ALPHA := 0.22
const FINAL_SOLO_GOOD_FLASH_ALPHA := 0.13

# 记忆闪回阶段背景图。按顺序播放。
const MEMORY_FLASH_BG_PATHS := [
	"res://project/assets/images/memory_events/s1_bg01.png",
	"res://project/assets/images/memory_events/s1_bg02.png",
	"res://project/assets/images/memory_events/s1_bg03.png",
	"res://project/assets/images/memory_events/s1_bg04.png",
	"res://project/assets/images/memory_events/s1_bg05.png",
	"res://project/assets/images/memory_events/s1_bg06.png",
	"res://project/assets/images/memory_events/s2_bg01.png",
	"res://project/assets/images/memory_events/s2_bg02.png",
	"res://project/assets/images/memory_events/s2_bg03.png",
	"res://project/assets/images/memory_events/s2_bg04.png",
	"res://project/assets/images/memory_events/s2_bg05.png",
	"res://project/assets/images/memory_events/s2_bg06.png",
	"res://project/assets/images/memory_events/s3_bg01.png",
	"res://project/assets/images/memory_events/s3_bg02.png",
	"res://project/assets/images/memory_events/s3_bg03.png",
	"res://project/assets/images/memory_events/s3_bg04.png"
]

# 记忆闪回背景只做氛围层，不能遮挡轨道。
const MEMORY_FLASH_BG_ALPHA := 0.90
const MEMORY_FLASH_DARK_ALPHA := 0.22
const MEMORY_FLASH_BLUR_SIZE := 3.4
const MEMORY_FLASH_DESATURATE := 0.38
const MEMORY_FLASH_BRIGHTNESS := 0.62

# 绘制层级：背景 < 记忆闪回氛围层 < 角色 < 音游轨道 < UI < FX。
const STAGE_BG_Z_INDEX := 0
const MEMORY_FLASH_Z_INDEX := 3
const CHARACTER_LAYER_Z_INDEX := 10
const NOTE_LAYER_Z_INDEX := 30
const UI_LAYER_Z_INDEX := 60
const FX_LAYER_Z_INDEX := 90

# 如果你的成功/失败结局场景路径不同，只改这里两行。
const SUCCESS_ENDING_SCENE_PATH = "res://project/scenes/ending/success_ending.tscn"
const FAILURE_ENDING_SCENE_PATH = "res://project/scenes/ending/failure_ending.tscn"

# 可选字体路径。存在就使用，不存在就使用 Godot 默认字体。
const UI_FONT_CANDIDATE_PATHS := [
	"res://project/assets/fonts/SourceHanSerifSC-Regular.otf",
	"res://project/assets/fonts/SourceHanSansSC-Regular.otf",
	"res://project/assets/font/SourceHanSerifSC-Regular.otf",
	"res://project/assets/font/SourceHanSansSC-Regular.otf",
	"res://project/assets/fonts/NotoSerifSC-Regular.otf",
	"res://project/assets/fonts/NotoSansSC-Regular.otf"
]

@onready var audio_player = $AudioPlayer
@onready var ui_root = $UI
@onready var note_layer = $NoteLayer
@onready var active_notes = $NoteLayer/ActiveNotes
@onready var choice_panel = $UI/ChoicePanel
@onready var combo_label = $UI/ComboLabel
@onready var tech_label = $UI/TechLabel
@onready var emotion_label = $UI/EmotionLabel
@onready var control_label = $UI/ControlLabel
@onready var segment_title = $UI/SegmentTitle

@onready var title_label = $UI/ChoicePanel/TitleLabel
@onready var art_button = $UI/ChoicePanel/ArtButton
@onready var human_button = $UI/ChoicePanel/HumanButton
@onready var business_button = $UI/ChoicePanel/BusinessButton
@onready var judge_line = $NoteLayer/JudgeLine
@onready var fx_layer = $FXLayer
@onready var flash_rect = $FXLayer/FlashRect
@onready var character_layer = $CharacterLayer
@onready var stage_bg = $StageBG

var lane_feedback_labels := {}
var lane_flash_rects := {}
var lane_feedback_tweens := {}

var base_lane_modulates := {}
var lane_color_tweens := {}

var chart_data := {}
var notes_data := []
var segments := []
var choice_points := []
var current_choice_point := {}
var current_choice_option := {}

var note_index := 0
var current_segment := -1
var current_choice_done := false
var choice_active := false
var performance_locked := false

var combo := 0
var tech_score := 0.0
var emotion_score := 0.0
var control_score := 0.0

var perfect_count := 0
var good_count := 0
var miss_count := 0
var last_result_info := {}

var expression_bias := "neutral"
var expression_theme_color := Color(1.0, 1.0, 1.0, 1.0)
var expression_theme_strength := 0.0

var held_lanes := {
	1: false,
	2: false,
	3: false
}

var base_stage_bg_position := Vector2.ZERO
var base_stage_bg_scale := Vector2.ONE
var base_stage_bg_modulate := Color(1, 1, 1, 1)
var base_character_scale := Vector2.ONE
var base_character_modulate := Color(1, 1, 1, 1)
var combo_label_base_position := Vector2.ZERO

var solo_breath_tween: Tween
var final_solo_glow_tween: Tween
var stage_hit_tween: Tween
var stage_offset_tween: Tween
var stage_scale_tween: Tween
var stage_color_tween: Tween
var character_tween: Tween

var lane_stem_streams := {}
var lane_stem_players := {}
var lane_stem_tweens := {}
var base_bgm_volume_db := 0.0
var bgm_duck_tween: Tween

var choice_music_active := false
var choice_music_returned := true
var choice_music_return_time := CHOICE_DEFAULT_RETURN_TIME
var active_choice_music_lane := 0
var choice_music_main_duck_db := CHOICE_MAIN_DUCK_DB
var choice_music_fade_in := CHOICE_FADE_IN
var choice_music_fade_out := CHOICE_FADE_OUT

var final_solo_active := false
var final_solo_stem_lane := 0
var final_solo_pulse_t := 0.0
var final_solo_glow_rect: ColorRect

var performance_intensity := 0.35
var intensity_overlay: ColorRect

var combo_wave_rect: ColorRect
var combo_wave_t := 0.0

var choice_backdrop: ColorRect
var choice_card_bg: Panel
var choice_panel_tween: Tween
var choice_audio_fade_tween: Tween
var choice_panel_base_position := Vector2.ZERO

var ending_fade_rect: ColorRect
var result_center_label: Label
var result_transition_tween: Tween

var progress_slider: HSlider
var progress_time_label: Label
var progress_dragging := false
var progress_slider_updating := false
var performance_duration := 177.5

var segment_transition_overlay: ColorRect
var segment_transition_label: Label
var segment_transition_tween: Tween

var memory_flash_layer: Control
var memory_flash_bg_rect: TextureRect
var memory_flash_dark_rect: ColorRect
var memory_flash_textures := []
var memory_flash_active := false
var memory_flash_index := -1
var memory_flash_start := 95.0
var memory_flash_end := 123.0
var memory_flash_restore_done := true
var memory_bg_tween: Tween

var ui_main_font: Font


func _ready():
	add_to_group("final_performance_root")
	randomize()
	base_bgm_volume_db = audio_player.volume_db

	_load_ui_font()
	_setup_render_order()
	_setup_interaction_audio()
	_setup_intensity_overlay()
	_setup_final_solo_glow()
	_setup_combo_wave()
	_setup_ending_overlay()
	_setup_segment_transition_fx()
	_setup_progress_slider()
	_setup_memory_flash_bg_layer()
	_load_memory_flash_backgrounds()

	base_stage_bg_position = stage_bg.position
	base_stage_bg_scale = stage_bg.scale
	base_stage_bg_modulate = stage_bg.modulate
	base_character_scale = character_layer.scale
	base_character_modulate = character_layer.modulate
	combo_label_base_position = combo_label.position

	_setup_choice_panel()
	_setup_result_skip_buttons()
	_setup_typography()
	_refresh_score_ui()

	_load_chart()
	_update_performance_duration()
	_apply_prebattle_bonus()
	_refresh_score_ui()

	_play_final_music()
	_setup_lane_feedback()
	_capture_base_lane_modulates()
	_apply_performance_intensity()


func _process(delta):
	var t: float = 0.0
	if audio_player != null and audio_player.stream != null:
		t = audio_player.get_playback_position()

	_update_progress_slider(t)
	_update_lane_feedback_positions()
	_update_combo_wave(delta)
	_update_memory_flash_slideshow(t)
	_update_final_solo_fx(delta)

	performance_intensity = move_toward(
		performance_intensity,
		_get_expression_intensity_idle_target(),
		delta * 0.10
	)
	_apply_performance_intensity()

	if choice_active or performance_locked:
		return

	_update_segment(t)
	_spawn_notes(t)
	_check_choice_point(t)
	_check_choice_music_return(t)

	if audio_player.stream != null and not audio_player.playing:
		_finish_performance()


func _setup_render_order():
	if stage_bg is CanvasItem:
		stage_bg.z_as_relative = false
		stage_bg.z_index = STAGE_BG_Z_INDEX

	if character_layer is CanvasItem:
		character_layer.z_as_relative = false
		character_layer.z_index = CHARACTER_LAYER_Z_INDEX

	if note_layer is CanvasItem:
		note_layer.z_as_relative = false
		note_layer.z_index = NOTE_LAYER_Z_INDEX

	if ui_root is CanvasItem:
		ui_root.z_as_relative = false
		ui_root.z_index = UI_LAYER_Z_INDEX

	if fx_layer is CanvasItem:
		fx_layer.z_as_relative = false
		fx_layer.z_index = FX_LAYER_Z_INDEX


func _load_ui_font():
	ui_main_font = null

	for path in UI_FONT_CANDIDATE_PATHS:
		if ResourceLoader.exists(path):
			ui_main_font = load(path) as Font
			if ui_main_font != null:
				print("最终演出 UI 字体加载：", path)
				return

	print("最终演出 UI 字体：使用 Godot 默认字体")


func _setup_typography():
	_apply_label_typography(segment_title, 28, Color(0.90, 0.84, 0.72, 1.0), 5)
	_apply_label_typography(combo_label, 22, Color(0.92, 0.90, 0.84, 1.0), 4)
	_apply_label_typography(tech_label, 16, Color(0.78, 0.82, 0.88, 1.0), 3)
	_apply_label_typography(emotion_label, 16, Color(0.86, 0.80, 0.72, 1.0), 3)
	_apply_label_typography(control_label, 16, Color(0.70, 0.84, 0.92, 1.0), 3)

	_apply_label_typography(title_label, 25, Color(0.92, 0.86, 0.74, 1.0), 5)
	_apply_button_typography(art_button, 19)
	_apply_button_typography(human_button, 19)
	_apply_button_typography(business_button, 19)

	if progress_time_label != null:
		_apply_label_typography(progress_time_label, 14, Color(0.76, 0.76, 0.72, 0.92), 3)

	if segment_transition_label != null:
		_apply_label_typography(segment_transition_label, 30, Color(0.90, 0.84, 0.72, 1.0), 7)

	if result_center_label != null:
		_apply_label_typography(result_center_label, 38, Color(0.92, 0.88, 0.80, 1.0), 7)


func _apply_label_typography(label: Label, font_size: int, font_color: Color, outline_size: int = 4):
	if label == null:
		return

	if ui_main_font != null:
		label.add_theme_font_override("font", ui_main_font)

	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.018, 0.015, 0.96))
	label.add_theme_constant_override("outline_size", outline_size)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)


func _apply_button_typography(button: Button, font_size: int):
	if button == null:
		return

	if ui_main_font != null:
		button.add_theme_font_override("font", ui_main_font)

	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(0.94, 0.90, 0.82, 1.0))
	button.add_theme_color_override("font_focus_color", Color(1.0, 0.94, 0.78, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.78, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.86, 0.78, 0.62, 1.0))
	button.add_theme_color_override("font_outline_color", Color(0.01, 0.01, 0.01, 0.92))
	button.add_theme_constant_override("outline_size", 3)


func _setup_choice_panel():
	choice_panel.visible = false
	choice_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	choice_panel.z_index = 40

	title_label.text = "这段要往哪种方向推？"
	art_button.text = "艺术表达 / 泛音层"
	human_button.text = "情感表达 / 拨弦层"
	business_button.text = "稳定控制 / 节奏层"

	title_label.process_mode = Node.PROCESS_MODE_ALWAYS
	art_button.process_mode = Node.PROCESS_MODE_ALWAYS
	human_button.process_mode = Node.PROCESS_MODE_ALWAYS
	business_button.process_mode = Node.PROCESS_MODE_ALWAYS

	art_button.mouse_filter = Control.MOUSE_FILTER_STOP
	human_button.mouse_filter = Control.MOUSE_FILTER_STOP
	business_button.mouse_filter = Control.MOUSE_FILTER_STOP

	art_button.disabled = false
	human_button.disabled = false
	business_button.disabled = false

	if not art_button.pressed.is_connected(_on_art_button_pressed):
		art_button.pressed.connect(_on_art_button_pressed)
	if not human_button.pressed.is_connected(_on_human_button_pressed):
		human_button.pressed.connect(_on_human_button_pressed)
	if not business_button.pressed.is_connected(_on_business_button_pressed):
		business_button.pressed.connect(_on_business_button_pressed)

	_setup_choice_backdrop()
	_setup_choice_card_background()
	_style_choice_panel()

	choice_panel_base_position = choice_panel.position
	choice_panel.pivot_offset = choice_panel.size * 0.5
	choice_panel.modulate = Color(1, 1, 1, 0)
	choice_panel.scale = Vector2(0.92, 0.92)
	choice_panel.position = choice_panel_base_position + Vector2(0, 28)


func _setup_choice_backdrop():
	choice_backdrop = ColorRect.new()
	choice_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	choice_backdrop.anchor_left = 0.0
	choice_backdrop.anchor_top = 0.0
	choice_backdrop.anchor_right = 1.0
	choice_backdrop.anchor_bottom = 1.0
	choice_backdrop.offset_left = 0.0
	choice_backdrop.offset_top = 0.0
	choice_backdrop.offset_right = 0.0
	choice_backdrop.offset_bottom = 0.0
	choice_backdrop.color = Color(0, 0, 0, 0.0)
	choice_backdrop.visible = false
	choice_backdrop.z_index = 14
	fx_layer.add_child(choice_backdrop)


func _setup_choice_card_background():
	choice_card_bg = Panel.new()
	choice_card_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	choice_card_bg.anchor_left = 0.0
	choice_card_bg.anchor_top = 0.0
	choice_card_bg.anchor_right = 1.0
	choice_card_bg.anchor_bottom = 1.0
	choice_card_bg.offset_left = -18.0
	choice_card_bg.offset_top = -18.0
	choice_card_bg.offset_right = 18.0
	choice_card_bg.offset_bottom = 18.0

	var panel_box := StyleBoxFlat.new()
	panel_box.bg_color = Color(0.055, 0.050, 0.047, 0.94)
	panel_box.border_color = Color(0.72, 0.56, 0.34, 0.42)
	panel_box.border_width_left = 2
	panel_box.border_width_top = 2
	panel_box.border_width_right = 2
	panel_box.border_width_bottom = 2
	panel_box.corner_radius_top_left = 18
	panel_box.corner_radius_top_right = 18
	panel_box.corner_radius_bottom_left = 18
	panel_box.corner_radius_bottom_right = 18
	panel_box.shadow_color = Color(0, 0, 0, 0.46)
	panel_box.shadow_size = 12
	choice_card_bg.add_theme_stylebox_override("panel", panel_box)

	choice_panel.add_child(choice_card_bg)
	choice_panel.move_child(choice_card_bg, 0)


func _style_choice_panel():
	_apply_label_typography(title_label, 25, Color(0.92, 0.86, 0.74, 1.0), 5)

	_style_choice_button(art_button, Color(0.30, 0.18, 0.075, 0.92), Color(0.90, 0.66, 0.30, 0.78))
	_style_choice_button(human_button, Color(0.26, 0.21, 0.17, 0.92), Color(0.88, 0.78, 0.62, 0.72))
	_style_choice_button(business_button, Color(0.075, 0.16, 0.22, 0.92), Color(0.46, 0.72, 0.86, 0.72))

	_apply_button_typography(art_button, 19)
	_apply_button_typography(human_button, 19)
	_apply_button_typography(business_button, 19)


func _style_choice_button(button: Button, fill_color: Color, border_color: Color):
	var normal_box := StyleBoxFlat.new()
	normal_box.bg_color = fill_color
	normal_box.border_color = border_color
	normal_box.border_width_left = 2
	normal_box.border_width_top = 2
	normal_box.border_width_right = 2
	normal_box.border_width_bottom = 2
	normal_box.corner_radius_top_left = 12
	normal_box.corner_radius_top_right = 12
	normal_box.corner_radius_bottom_left = 12
	normal_box.corner_radius_bottom_right = 12

	var hover_box := StyleBoxFlat.new()
	hover_box.bg_color = fill_color.lightened(0.08)
	hover_box.border_color = border_color.lightened(0.15)
	hover_box.border_width_left = 2
	hover_box.border_width_top = 2
	hover_box.border_width_right = 2
	hover_box.border_width_bottom = 2
	hover_box.corner_radius_top_left = 12
	hover_box.corner_radius_top_right = 12
	hover_box.corner_radius_bottom_left = 12
	hover_box.corner_radius_bottom_right = 12
	hover_box.shadow_color = Color(0, 0, 0, 0.30)
	hover_box.shadow_size = 5

	var pressed_box := StyleBoxFlat.new()
	pressed_box.bg_color = fill_color.darkened(0.10)
	pressed_box.border_color = border_color
	pressed_box.border_width_left = 2
	pressed_box.border_width_top = 2
	pressed_box.border_width_right = 2
	pressed_box.border_width_bottom = 2
	pressed_box.corner_radius_top_left = 12
	pressed_box.corner_radius_top_right = 12
	pressed_box.corner_radius_bottom_left = 12
	pressed_box.corner_radius_bottom_right = 12

	button.add_theme_stylebox_override("normal", normal_box)
	button.add_theme_stylebox_override("hover", hover_box)
	button.add_theme_stylebox_override("pressed", pressed_box)
	button.add_theme_stylebox_override("focus", hover_box)


func _show_choice_panel_animated():
	if choice_panel_tween and is_instance_valid(choice_panel_tween):
		choice_panel_tween.kill()

	choice_backdrop.visible = true
	choice_panel.visible = true
	choice_panel.modulate = Color(1, 1, 1, 0)
	choice_panel.scale = Vector2(0.92, 0.92)
	choice_panel.position = choice_panel_base_position + Vector2(0, 28)

	choice_panel_tween = create_tween()
	choice_panel_tween.parallel().tween_property(choice_backdrop, "color:a", 0.42, 0.18)
	choice_panel_tween.parallel().tween_property(choice_panel, "modulate:a", 1.0, 0.18)
	choice_panel_tween.parallel().tween_property(choice_panel, "scale", Vector2.ONE, 0.20)
	choice_panel_tween.parallel().tween_property(choice_panel, "position", choice_panel_base_position, 0.20)


func _hide_choice_panel_animated():
	if choice_panel_tween and is_instance_valid(choice_panel_tween):
		choice_panel_tween.kill()

	choice_panel_tween = create_tween()
	choice_panel_tween.parallel().tween_property(choice_backdrop, "color:a", 0.0, 0.14)
	choice_panel_tween.parallel().tween_property(choice_panel, "modulate:a", 0.0, 0.12)
	choice_panel_tween.parallel().tween_property(choice_panel, "scale", Vector2(0.96, 0.96), 0.12)
	choice_panel_tween.parallel().tween_property(choice_panel, "position", choice_panel_base_position + Vector2(0, 12), 0.12)
	choice_panel_tween.finished.connect(func():
		choice_backdrop.visible = false
		choice_panel.visible = false
	)


func _fade_pause_music():
	if audio_player == null or audio_player.stream == null:
		return

	if bgm_duck_tween and is_instance_valid(bgm_duck_tween):
		bgm_duck_tween.kill()
	if choice_audio_fade_tween and is_instance_valid(choice_audio_fade_tween):
		choice_audio_fade_tween.kill()

	var start_db: float = audio_player.volume_db
	choice_audio_fade_tween = create_tween()
	choice_audio_fade_tween.tween_property(audio_player, "volume_db", start_db - 18.0, 0.18)
	choice_audio_fade_tween.tween_callback(func():
		if audio_player:
			audio_player.stream_paused = true
			audio_player.volume_db = base_bgm_volume_db

		for lane_id in lane_stem_players.keys():
			var p := lane_stem_players[lane_id] as AudioStreamPlayer
			if p != null:
				p.stream_paused = true
				p.volume_db = STEM_MUTED_DB
	)


func _fade_resume_music():
	_resume_music_without_choice()


func _resume_music_without_choice():
	if audio_player == null or audio_player.stream == null:
		return

	if choice_audio_fade_tween and is_instance_valid(choice_audio_fade_tween):
		choice_audio_fade_tween.kill()

	audio_player.volume_db = base_bgm_volume_db - 14.0
	audio_player.stream_paused = false

	for lane_id in lane_stem_players.keys():
		var p := lane_stem_players[lane_id] as AudioStreamPlayer
		if p != null:
			p.stream_paused = false
			p.volume_db = STEM_MUTED_DB

	choice_audio_fade_tween = create_tween()
	choice_audio_fade_tween.tween_property(audio_player, "volume_db", base_bgm_volume_db, 0.24)


func _resume_music_for_choice(choice_id: String):
	if audio_player == null or audio_player.stream == null:
		return

	if choice_audio_fade_tween and is_instance_valid(choice_audio_fade_tween):
		choice_audio_fade_tween.kill()

	audio_player.volume_db = base_bgm_volume_db - 14.0
	audio_player.stream_paused = false

	for lane_id in lane_stem_players.keys():
		var p := lane_stem_players[lane_id] as AudioStreamPlayer
		if p != null:
			p.stream_paused = false
			p.volume_db = STEM_MUTED_DB

	_start_choice_music_branch(choice_id)


func _start_choice_music_branch(choice_id: String):
	current_choice_option = _get_choice_option(choice_id)

	active_choice_music_lane = int(current_choice_option.get("stem_lane", _get_choice_music_lane(choice_id)))
	choice_music_returned = false
	choice_music_active = active_choice_music_lane != 0

	choice_music_return_time = float(current_choice_point.get("return_time", CHOICE_DEFAULT_RETURN_TIME))
	choice_music_main_duck_db = float(current_choice_point.get("main_duck_db", CHOICE_MAIN_DUCK_DB))
	choice_music_fade_in = float(current_choice_point.get("fade_in", CHOICE_FADE_IN))
	choice_music_fade_out = float(current_choice_point.get("fade_out", CHOICE_FADE_OUT))

	if not choice_music_active:
		_resume_music_without_choice()
		return

	_fade_bgm_to(base_bgm_volume_db + choice_music_main_duck_db, choice_music_fade_in)

	for lane_id in lane_stem_players.keys():
		var target_db := STEM_MUTED_DB
		if lane_id == active_choice_music_lane:
			target_db = _get_choice_music_target_volume(choice_id)
		_fade_choice_music_to(lane_id, target_db, choice_music_fade_in)

	_apply_choice_track_color(choice_id, choice_music_fade_in)


func _check_choice_music_return(t: float):
	if not choice_music_active:
		return
	if choice_music_returned:
		return
	if t >= choice_music_return_time:
		_return_to_main_music(choice_music_fade_out)


func _return_to_main_music(duration: float = CHOICE_FADE_OUT):
	choice_music_returned = true
	choice_music_active = false
	active_choice_music_lane = 0
	current_choice_option = {}

	_fade_all_choice_music_out(duration)
	_fade_bgm_to(base_bgm_volume_db, duration)
	_reset_choice_track_color(duration)


func _fade_bgm_to(target_db: float, duration: float):
	if audio_player == null:
		return

	if bgm_duck_tween and is_instance_valid(bgm_duck_tween):
		bgm_duck_tween.kill()

	bgm_duck_tween = create_tween()
	bgm_duck_tween.tween_property(audio_player, "volume_db", target_db, max(duration, 0.01))


func _fade_choice_music_to(lane_id: int, target_db: float, duration: float):
	if not lane_stem_players.has(lane_id):
		return

	if lane_stem_tweens.has(lane_id):
		var old_tween: Tween = lane_stem_tweens[lane_id]
		if is_instance_valid(old_tween):
			old_tween.kill()

	var p := lane_stem_players[lane_id] as AudioStreamPlayer
	if p == null:
		return

	var tween := create_tween()
	lane_stem_tweens[lane_id] = tween
	tween.tween_property(p, "volume_db", target_db, max(duration, 0.01))


func _fade_all_choice_music_out(duration: float = CHOICE_FADE_OUT):
	for lane_id in lane_stem_players.keys():
		_fade_choice_music_to(lane_id, STEM_MUTED_DB, duration)


func _get_choice_music_lane(choice_id: String) -> int:
	var option := _get_choice_option(choice_id)
	if option.has("stem_lane"):
		return int(option.get("stem_lane", 0))

	match choice_id:
		"business":
			return 1
		"human":
			return 2
		"art":
			return 3
	return 0


func _get_choice_music_target_volume(choice_id: String) -> float:
	var option := current_choice_option
	if option.is_empty() or str(option.get("id", "")) != choice_id:
		option = _get_choice_option(choice_id)

	if option.has("stem_volume_db"):
		return float(option.get("stem_volume_db", STEM_MUTED_DB))

	match choice_id:
		"business":
			return CHOICE_BUSINESS_STEM_VOLUME_DB
		"human":
			return CHOICE_HUMAN_STEM_VOLUME_DB
		"art":
			return CHOICE_ART_STEM_VOLUME_DB
	return STEM_MUTED_DB


func _get_choice_option(choice_id: String) -> Dictionary:
	var options: Variant = current_choice_point.get("options", [])
	if typeof(options) != TYPE_ARRAY:
		return {}

	for option in options:
		if typeof(option) != TYPE_DICTIONARY:
			continue
		if str(option.get("id", "")) == choice_id:
			return option

	return {}


func _apply_choice_point_texts(point: Dictionary):
	title_label.text = str(point.get("title", "这段要往哪种方向推？"))

	art_button.text = "艺术表达 / 泛音层"
	human_button.text = "情感表达 / 拨弦层"
	business_button.text = "稳定控制 / 节奏层"

	var options: Variant = point.get("options", [])
	if typeof(options) != TYPE_ARRAY:
		return

	for option in options:
		if typeof(option) != TYPE_DICTIONARY:
			continue

		var option_id: String = str(option.get("id", ""))
		var option_text: String = str(option.get("text", ""))
		if option_text == "":
			continue

		match option_id:
			"art":
				art_button.text = option_text
			"human":
				human_button.text = option_text
			"business":
				business_button.text = option_text


func _capture_base_lane_modulates():
	base_lane_modulates.clear()

	for lane_id in [1, 2, 3]:
		var lane_node := _get_lane_node(lane_id)
		if lane_node != null:
			base_lane_modulates[lane_id] = lane_node.modulate


func _apply_choice_track_color(choice_id: String, duration: float = CHOICE_FADE_IN):
	var option := current_choice_option
	if option.is_empty() or str(option.get("id", "")) != choice_id:
		option = _get_choice_option(choice_id)

	var fallback_color := _get_expression_heat_color()
	var target_color := _parse_choice_color(option.get("track_color", ""), fallback_color)

	for lane_id in [1, 2, 3]:
		var lane_node := _get_lane_node(lane_id)
		if lane_node == null:
			continue

		if lane_color_tweens.has(lane_id):
			var old_tween: Tween = lane_color_tweens[lane_id]
			if is_instance_valid(old_tween):
				old_tween.kill()

		var base_color: Color = base_lane_modulates.get(lane_id, Color(1, 1, 1, 1))
		var final_color := Color(target_color.r, target_color.g, target_color.b, base_color.a)

		var tween := create_tween()
		lane_color_tweens[lane_id] = tween
		tween.tween_property(lane_node, "modulate", final_color, max(duration, 0.01))


func _reset_choice_track_color(duration: float = CHOICE_FADE_OUT):
	for lane_id in [1, 2, 3]:
		var lane_node := _get_lane_node(lane_id)
		if lane_node == null:
			continue

		if lane_color_tweens.has(lane_id):
			var old_tween: Tween = lane_color_tweens[lane_id]
			if is_instance_valid(old_tween):
				old_tween.kill()

		var base_color: Color = base_lane_modulates.get(lane_id, Color(1, 1, 1, 1))

		var tween := create_tween()
		lane_color_tweens[lane_id] = tween
		tween.tween_property(lane_node, "modulate", base_color, max(duration, 0.01))


func _parse_choice_color(value, fallback: Color) -> Color:
	if typeof(value) == TYPE_STRING:
		var s := str(value)
		if s != "":
			return Color.html(s)

	return fallback


func _setup_progress_slider():
	progress_slider = HSlider.new()
	progress_slider.name = "PerformanceProgressSlider"
	progress_slider.anchor_left = 0.12
	progress_slider.anchor_right = 0.88
	progress_slider.anchor_top = 1.0
	progress_slider.anchor_bottom = 1.0
	progress_slider.offset_left = 0.0
	progress_slider.offset_right = 0.0
	progress_slider.offset_top = -42.0
	progress_slider.offset_bottom = -20.0
	progress_slider.min_value = 0.0
	progress_slider.max_value = performance_duration
	progress_slider.step = 0.05
	progress_slider.value = 0.0
	progress_slider.z_index = 70
	progress_slider.mouse_filter = Control.MOUSE_FILTER_STOP
	progress_slider.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_root.add_child(progress_slider)

	progress_time_label = Label.new()
	progress_time_label.name = "PerformanceProgressTimeLabel"
	progress_time_label.anchor_left = 0.88
	progress_time_label.anchor_right = 0.98
	progress_time_label.anchor_top = 1.0
	progress_time_label.anchor_bottom = 1.0
	progress_time_label.offset_left = 10.0
	progress_time_label.offset_right = 0.0
	progress_time_label.offset_top = -48.0
	progress_time_label.offset_bottom = -16.0
	progress_time_label.z_index = 70
	progress_time_label.text = "00:00 / 00:00"
	progress_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	progress_time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_time_label.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_root.add_child(progress_time_label)

	progress_slider.drag_started.connect(_on_progress_drag_started)
	progress_slider.drag_ended.connect(_on_progress_drag_ended)
	progress_slider.value_changed.connect(_on_progress_slider_value_changed)


func _update_performance_duration():
	performance_duration = 177.5

	if segments.size() > 0:
		for seg in segments:
			if typeof(seg) == TYPE_DICTIONARY:
				performance_duration = max(performance_duration, float(seg.get("end", performance_duration)))

	if audio_player != null and audio_player.stream != null:
		var length: float = audio_player.stream.get_length()
		if length > 0.0:
			performance_duration = max(performance_duration, length)

	if progress_slider != null:
		progress_slider.max_value = performance_duration

	_update_progress_time_label(0.0)


func _update_progress_slider(t: float):
	if progress_slider == null:
		return

	if progress_dragging:
		_update_progress_time_label(float(progress_slider.value))
		return

	progress_slider_updating = true
	progress_slider.value = clampf(t, 0.0, performance_duration)
	progress_slider_updating = false
	_update_progress_time_label(t)


func _on_progress_drag_started():
	progress_dragging = true


func _on_progress_drag_ended(value_changed: bool):
	progress_dragging = false
	_seek_performance_to(float(progress_slider.value))


func _on_progress_slider_value_changed(value: float):
	if progress_slider_updating:
		return

	_update_progress_time_label(value)

	if progress_dragging:
		return

	_seek_performance_to(value)


func _update_progress_time_label(t: float):
	if progress_time_label == null:
		return

	progress_time_label.text = "%s / %s" % [
		_format_time(t),
		_format_time(performance_duration)
	]


func _format_time(t: float) -> String:
	var total: int = int(max(t, 0.0))
	var minutes: int = int(total / 60)
	var seconds: int = total % 60
	return "%02d:%02d" % [minutes, seconds]


func _seek_performance_to(target_time: float):
	if audio_player == null or audio_player.stream == null:
		return

	var t: float = clampf(target_time, 0.0, performance_duration)

	_seek_all_music_to(t)
	_reset_notes_after_seek(t)
	_sync_choice_state_after_seek(t)
	_sync_memory_flash_after_seek(t)
	_sync_final_solo_after_seek(t)

	current_segment = -1
	_update_segment(t)
	_update_progress_slider(t)


func _seek_all_music_to(t: float):
	var audio_paused: bool = audio_player.stream_paused
	audio_player.seek(t)
	audio_player.stream_paused = audio_paused

	for lane_id in lane_stem_players.keys():
		var p := lane_stem_players[lane_id] as AudioStreamPlayer
		if p == null or p.stream == null:
			continue

		var was_paused: bool = p.stream_paused
		if p.playing or was_paused:
			p.seek(t)
		else:
			p.play(t)
		p.stream_paused = was_paused


func _reset_notes_after_seek(t: float):
	for child in active_notes.get_children():
		child.queue_free()

	note_index = 0
	while note_index < notes_data.size():
		var data: Variant = notes_data[note_index]
		if typeof(data) != TYPE_DICTIONARY:
			note_index += 1
			continue

		if float(data.get("time", 0.0)) >= t - 0.25:
			break

		note_index += 1


func _sync_choice_state_after_seek(t: float):
	current_choice_done = false

	if choice_points.size() == 0:
		return

	var point: Variant = choice_points[0]
	if typeof(point) != TYPE_DICTIONARY:
		return

	current_choice_point = point
	var choice_time: float = float(point.get("time", 0.0))
	var return_time: float = float(point.get("return_time", CHOICE_DEFAULT_RETURN_TIME))

	if t < choice_time:
		current_choice_done = false
		_return_to_main_music(0.05)
		return

	current_choice_done = true

	if expression_bias != "neutral" and t < return_time:
		_start_choice_music_branch(expression_bias)
	else:
		_return_to_main_music(0.05)


func _setup_segment_transition_fx():
	segment_transition_overlay = ColorRect.new()
	segment_transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	segment_transition_overlay.anchor_left = 0.0
	segment_transition_overlay.anchor_right = 1.0
	segment_transition_overlay.anchor_top = 0.0
	segment_transition_overlay.anchor_bottom = 0.0
	segment_transition_overlay.offset_left = 0.0
	segment_transition_overlay.offset_right = 0.0
	segment_transition_overlay.offset_top = 84.0
	segment_transition_overlay.offset_bottom = 150.0
	segment_transition_overlay.color = Color(0.025, 0.022, 0.020, 0.0)
	segment_transition_overlay.z_index = 60
	fx_layer.add_child(segment_transition_overlay)

	segment_transition_label = Label.new()
	segment_transition_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	segment_transition_label.anchor_left = 0.0
	segment_transition_label.anchor_right = 1.0
	segment_transition_label.anchor_top = 0.0
	segment_transition_label.anchor_bottom = 0.0
	segment_transition_label.offset_left = 0.0
	segment_transition_label.offset_right = 0.0
	segment_transition_label.offset_top = 84.0
	segment_transition_label.offset_bottom = 150.0
	segment_transition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	segment_transition_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	segment_transition_label.text = ""
	segment_transition_label.modulate = Color(1, 1, 1, 0)
	segment_transition_label.z_index = 61
	fx_layer.add_child(segment_transition_label)

	_apply_label_typography(segment_transition_label, 30, Color(0.90, 0.84, 0.72, 1.0), 7)


func _show_segment_transition(title: String, color: Color):
	if segment_transition_tween and is_instance_valid(segment_transition_tween):
		segment_transition_tween.kill()

	var text_color := Color(
		lerp(0.90, color.r, 0.32),
		lerp(0.84, color.g, 0.32),
		lerp(0.72, color.b, 0.32),
		1.0
	)

	segment_transition_label.text = title
	segment_transition_label.scale = Vector2(0.96, 0.96)
	segment_transition_label.modulate = Color(text_color.r, text_color.g, text_color.b, 0.0)
	segment_transition_overlay.color = Color(0.025, 0.022, 0.020, 0.0)

	segment_transition_tween = create_tween()
	segment_transition_tween.parallel().tween_property(segment_transition_overlay, "color:a", 0.54, 0.12)
	segment_transition_tween.parallel().tween_property(segment_transition_label, "modulate:a", 1.0, 0.12)
	segment_transition_tween.parallel().tween_property(segment_transition_label, "scale", Vector2(1.0, 1.0), 0.12)
	segment_transition_tween.tween_interval(1.00)
	segment_transition_tween.parallel().tween_property(segment_transition_overlay, "color:a", 0.0, 0.22)
	segment_transition_tween.parallel().tween_property(segment_transition_label, "modulate:a", 0.0, 0.22)
	segment_transition_tween.parallel().tween_property(segment_transition_label, "scale", Vector2(1.04, 1.04), 0.22)


func _setup_memory_flash_bg_layer():
	memory_flash_layer = Control.new()
	memory_flash_layer.name = "MemoryFlashLayer"
	memory_flash_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	memory_flash_layer.anchor_left = 0.0
	memory_flash_layer.anchor_top = 0.0
	memory_flash_layer.anchor_right = 1.0
	memory_flash_layer.anchor_bottom = 1.0
	memory_flash_layer.offset_left = 0.0
	memory_flash_layer.offset_top = 0.0
	memory_flash_layer.offset_right = 0.0
	memory_flash_layer.offset_bottom = 0.0
	memory_flash_layer.visible = false
	memory_flash_layer.modulate = Color(1, 1, 1, 1)
	memory_flash_layer.z_as_relative = false
	memory_flash_layer.z_index = MEMORY_FLASH_Z_INDEX

	var parent := stage_bg.get_parent()
	parent.add_child(memory_flash_layer)

	var target_index: int = min(stage_bg.get_index() + 1, parent.get_child_count() - 1)
	parent.move_child(memory_flash_layer, target_index)

	memory_flash_bg_rect = TextureRect.new()
	memory_flash_bg_rect.name = "MemoryFlashBlurredImage"
	memory_flash_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	memory_flash_bg_rect.anchor_left = 0.0
	memory_flash_bg_rect.anchor_top = 0.0
	memory_flash_bg_rect.anchor_right = 1.0
	memory_flash_bg_rect.anchor_bottom = 1.0
	memory_flash_bg_rect.offset_left = 0.0
	memory_flash_bg_rect.offset_top = 0.0
	memory_flash_bg_rect.offset_right = 0.0
	memory_flash_bg_rect.offset_bottom = 0.0
	memory_flash_bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	memory_flash_bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	memory_flash_bg_rect.modulate = Color(1, 1, 1, 0.0)
	memory_flash_bg_rect.material = _create_memory_flash_blur_material()
	memory_flash_layer.add_child(memory_flash_bg_rect)

	memory_flash_dark_rect = ColorRect.new()
	memory_flash_dark_rect.name = "MemoryFlashDarkVeil"
	memory_flash_dark_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	memory_flash_dark_rect.anchor_left = 0.0
	memory_flash_dark_rect.anchor_top = 0.0
	memory_flash_dark_rect.anchor_right = 1.0
	memory_flash_dark_rect.anchor_bottom = 1.0
	memory_flash_dark_rect.offset_left = 0.0
	memory_flash_dark_rect.offset_top = 0.0
	memory_flash_dark_rect.offset_right = 0.0
	memory_flash_dark_rect.offset_bottom = 0.0
	memory_flash_dark_rect.color = Color(0.03, 0.025, 0.02, 0.0)
	memory_flash_layer.add_child(memory_flash_dark_rect)

	if note_layer is CanvasItem:
		note_layer.z_as_relative = false
		note_layer.z_index = max(note_layer.z_index, NOTE_LAYER_Z_INDEX)

	if ui_root is CanvasItem:
		ui_root.z_as_relative = false
		ui_root.z_index = max(ui_root.z_index, UI_LAYER_Z_INDEX)

	if fx_layer is CanvasItem:
		fx_layer.z_as_relative = false
		fx_layer.z_index = max(fx_layer.z_index, FX_LAYER_Z_INDEX)


func _create_memory_flash_blur_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float blur_size = 3.4;
uniform float desaturate = 0.38;
uniform float brightness = 0.62;

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE * blur_size;

	vec4 c = vec4(0.0);
	c += texture(TEXTURE, UV + vec2(-px.x, -px.y)) * 0.0625;
	c += texture(TEXTURE, UV + vec2( 0.0,  -px.y)) * 0.1250;
	c += texture(TEXTURE, UV + vec2( px.x, -px.y)) * 0.0625;

	c += texture(TEXTURE, UV + vec2(-px.x, 0.0)) * 0.1250;
	c += texture(TEXTURE, UV) * 0.2500;
	c += texture(TEXTURE, UV + vec2( px.x, 0.0)) * 0.1250;

	c += texture(TEXTURE, UV + vec2(-px.x, px.y)) * 0.0625;
	c += texture(TEXTURE, UV + vec2( 0.0,  px.y)) * 0.1250;
	c += texture(TEXTURE, UV + vec2( px.x, px.y)) * 0.0625;

	float gray = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(c.rgb, vec3(gray), desaturate);
	c.rgb *= brightness;

	COLOR = c * COLOR;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("blur_size", MEMORY_FLASH_BLUR_SIZE)
	material.set_shader_parameter("desaturate", MEMORY_FLASH_DESATURATE)
	material.set_shader_parameter("brightness", MEMORY_FLASH_BRIGHTNESS)
	return material


func _load_memory_flash_backgrounds():
	memory_flash_textures.clear()

	for path in MEMORY_FLASH_BG_PATHS:
		if ResourceLoader.exists(path):
			var tex := load(path) as Texture2D
			if tex != null:
				memory_flash_textures.append(tex)
		else:
			push_warning("记忆闪回背景图不存在：%s" % path)

	print("记忆闪回背景图加载数量：", memory_flash_textures.size())


func _start_memory_flash_slideshow():
	memory_flash_active = true
	memory_flash_restore_done = false
	memory_flash_index = -1

	var bounds := _get_segment_bounds("memory_flash")
	memory_flash_start = float(bounds.get("start", 95.0))
	memory_flash_end = float(bounds.get("end", 123.0))

	if memory_flash_layer != null:
		memory_flash_layer.visible = true

	if memory_flash_bg_rect != null:
		memory_flash_bg_rect.visible = true
		memory_flash_bg_rect.modulate = Color(1, 1, 1, 0)

	if memory_flash_dark_rect != null:
		memory_flash_dark_rect.visible = true
		memory_flash_dark_rect.color = Color(0.03, 0.025, 0.02, 0.0)

	print("开始记忆闪回背景轮播：", memory_flash_start, " -> ", memory_flash_end)


func _update_memory_flash_slideshow(t: float):
	if not memory_flash_active:
		return

	if memory_flash_textures.size() == 0:
		return

	if t >= memory_flash_end:
		_finish_memory_flash_slideshow()
		return

	if t < memory_flash_start:
		return

	var duration: float = max(memory_flash_end - memory_flash_start, 0.1)
	var step: float = duration / float(memory_flash_textures.size())
	var index: int = int(floor((t - memory_flash_start) / step))
	index = clampi(index, 0, memory_flash_textures.size() - 1)

	if index != memory_flash_index:
		_set_memory_flash_background(index)


func _set_memory_flash_background(index: int):
	if index < 0 or index >= memory_flash_textures.size():
		return
	if memory_flash_bg_rect == null:
		return

	memory_flash_index = index
	memory_flash_bg_rect.texture = memory_flash_textures[index]

	if memory_flash_layer != null:
		memory_flash_layer.visible = true

	memory_flash_bg_rect.visible = true

	if memory_bg_tween and is_instance_valid(memory_bg_tween):
		memory_bg_tween.kill()

	memory_flash_bg_rect.modulate = Color(1, 1, 1, 0.0)

	if memory_flash_dark_rect != null:
		memory_flash_dark_rect.color = Color(0.03, 0.025, 0.02, 0.0)

	memory_bg_tween = create_tween()
	memory_bg_tween.parallel().tween_property(memory_flash_bg_rect, "modulate:a", MEMORY_FLASH_BG_ALPHA, 0.20)

	if memory_flash_dark_rect != null:
		memory_bg_tween.parallel().tween_property(memory_flash_dark_rect, "color:a", MEMORY_FLASH_DARK_ALPHA, 0.20)

	print("切换记忆闪回背景 index=", index)


func _finish_memory_flash_slideshow():
	if memory_flash_restore_done:
		return

	memory_flash_restore_done = true
	memory_flash_active = false
	memory_flash_index = -1

	if memory_flash_bg_rect == null:
		return

	if memory_bg_tween and is_instance_valid(memory_bg_tween):
		memory_bg_tween.kill()

	memory_bg_tween = create_tween()
	memory_bg_tween.parallel().tween_property(memory_flash_bg_rect, "modulate:a", 0.0, 0.20)

	if memory_flash_dark_rect != null:
		memory_bg_tween.parallel().tween_property(memory_flash_dark_rect, "color:a", 0.0, 0.20)

	memory_bg_tween.finished.connect(func():
		if memory_flash_bg_rect != null:
			memory_flash_bg_rect.visible = false
			memory_flash_bg_rect.texture = null

		if memory_flash_dark_rect != null:
			memory_flash_dark_rect.visible = false

		if memory_flash_layer != null:
			memory_flash_layer.visible = false
	)

	print("结束记忆闪回背景轮播，切回原背景")


func _sync_memory_flash_after_seek(t: float):
	var bounds := _get_segment_bounds("memory_flash")
	memory_flash_start = float(bounds.get("start", 95.0))
	memory_flash_end = float(bounds.get("end", 123.0))

	if t >= memory_flash_start and t < memory_flash_end:
		_start_memory_flash_slideshow()
		_update_memory_flash_slideshow(t)
	else:
		_finish_memory_flash_slideshow()


func _get_segment_bounds(segment_id: String) -> Dictionary:
	for seg in segments:
		if typeof(seg) != TYPE_DICTIONARY:
			continue
		if str(seg.get("id", "")) == segment_id:
			return {
				"start": float(seg.get("start", 0.0)),
				"end": float(seg.get("end", 0.0))
			}

	return {}


func _setup_final_solo_glow():
	final_solo_glow_rect = ColorRect.new()
	final_solo_glow_rect.name = "FinalSoloGlow"
	final_solo_glow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	final_solo_glow_rect.anchor_left = 0.0
	final_solo_glow_rect.anchor_top = 0.0
	final_solo_glow_rect.anchor_right = 1.0
	final_solo_glow_rect.anchor_bottom = 1.0
	final_solo_glow_rect.offset_left = 0.0
	final_solo_glow_rect.offset_top = 0.0
	final_solo_glow_rect.offset_right = 0.0
	final_solo_glow_rect.offset_bottom = 0.0
	final_solo_glow_rect.color = Color(1.0, 0.74, 0.28, 0.0)
	final_solo_glow_rect.visible = false
	final_solo_glow_rect.z_index = 7
	fx_layer.add_child(final_solo_glow_rect)


func _start_final_solo_state():
	if final_solo_active:
		return

	final_solo_active = true
	final_solo_pulse_t = 0.0
	performance_intensity = max(performance_intensity, FINAL_SOLO_MIN_INTENSITY)

	final_solo_stem_lane = _get_choice_music_lane(expression_bias)
	if final_solo_stem_lane == 0:
		final_solo_stem_lane = 2

	# 只保留音乐层增强，不加画面滤镜。
	_fade_bgm_to(base_bgm_volume_db + FINAL_SOLO_MAIN_DUCK_DB, FINAL_SOLO_FADE_IN)

	for lane_id in lane_stem_players.keys():
		var target_db := STEM_MUTED_DB
		if lane_id == final_solo_stem_lane:
			target_db = FINAL_SOLO_STEM_VOLUME_DB
		_fade_choice_music_to(lane_id, target_db, FINAL_SOLO_FADE_IN)

	# 只做轻微镜头/角色呼吸，不做染色。
	_tween_stage_scale(base_stage_bg_scale * 1.025, 0.50)
	character_layer.modulate = base_character_modulate


func _stop_final_solo_state():
	if not final_solo_active:
		return

	final_solo_active = false
	final_solo_stem_lane = 0

	if final_solo_glow_tween and is_instance_valid(final_solo_glow_tween):
		final_solo_glow_tween.kill()

	if final_solo_glow_rect != null:
		final_solo_glow_tween = create_tween()
		final_solo_glow_tween.tween_property(final_solo_glow_rect, "color:a", 0.0, 0.28)
		final_solo_glow_tween.finished.connect(func():
			if final_solo_glow_rect != null:
				final_solo_glow_rect.visible = false
		)

	_fade_all_choice_music_out(FINAL_SOLO_FADE_OUT)
	_fade_bgm_to(base_bgm_volume_db, FINAL_SOLO_FADE_OUT)

	_tween_stage_scale(base_stage_bg_scale, 0.40)
	_tween_stage_offset(Vector2.ZERO, 0.40)
	_tween_character_layer(base_character_modulate, base_character_scale, 0.40)


func _update_final_solo_fx(delta: float):
	if not final_solo_active:
		return

	final_solo_pulse_t += delta

	var pulse: float = 0.5 + 0.5 * sin(final_solo_pulse_t * 5.2)
	var heat: Color = _get_expression_heat_color()

	if final_solo_glow_rect != null and final_solo_glow_rect.visible:
		final_solo_glow_rect.color = Color(
			heat.r,
			heat.g,
			heat.b,
			0.055 + 0.075 * pulse
		)

	var stage_scale_target := base_stage_bg_scale * (1.035 + pulse * 0.018)
	stage_bg.scale = stage_bg.scale.lerp(stage_scale_target, delta * 2.8)

	var char_scale_target := base_character_scale * (1.025 + pulse * 0.030)
	character_layer.scale = character_layer.scale.lerp(char_scale_target, delta * 3.2)

	if combo_wave_rect != null:
		combo_wave_rect.color.a = max(combo_wave_rect.color.a, 0.16 + 0.10 * pulse)


func _trigger_final_solo_hit_fx(lane_id: int, result: String):
	if not final_solo_active:
		return

	match result:
		"perfect":
			performance_intensity = clampf(performance_intensity + FINAL_SOLO_HIT_INTENSITY_GAIN, 0.0, 1.0)
			_pulse_stage_hit(1.15)
			_pulse_judge_line(Color(1.0, 0.88, 0.25, 1.0), 1.15)

		"good":
			performance_intensity = clampf(performance_intensity + FINAL_SOLO_HIT_INTENSITY_GAIN * 0.55, 0.0, 1.0)
			_pulse_stage_hit(0.85)
			_pulse_judge_line(Color(0.45, 0.85, 1.0, 1.0), 0.95)

		"miss":
			performance_intensity = clampf(performance_intensity - 0.10, 0.0, 1.0)
			_pulse_stage_hit(0.35)


func _sync_final_solo_after_seek(t: float):
	var bounds := _get_segment_bounds("final_solo")
	if bounds.is_empty():
		_stop_final_solo_state()
		return

	var start_time := float(bounds.get("start", 123.0))
	var end_time := float(bounds.get("end", 170.0))

	if t >= start_time and t < end_time:
		_start_final_solo_state()
	else:
		_stop_final_solo_state()


func _setup_combo_wave():
	combo_wave_rect = ColorRect.new()
	combo_wave_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_wave_rect.color = Color(1.0, 1.0, 1.0, 0.0)
	combo_wave_rect.size = Vector2(0, 8)
	combo_wave_rect.z_index = 16
	fx_layer.add_child(combo_wave_rect)


func _update_combo_wave(delta):
	combo_wave_t += delta
	var combo_ratio: float = clampf(float(combo) / 45.0, 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(combo_wave_t * 9.0)

	if final_solo_active:
		combo_ratio = clampf(combo_ratio + 0.22, 0.0, 1.0)
		pulse = 0.45 + 0.55 * sin(combo_wave_t * 12.0)

	var target_width: float = lerp(46.0, 420.0, combo_ratio)
	var target_height: float = lerp(4.0, 22.0, combo_ratio)

	combo_wave_rect.size.x = lerp(combo_wave_rect.size.x, target_width, delta * 12.0)
	combo_wave_rect.size.y = lerp(combo_wave_rect.size.y, target_height, delta * 12.0)

	var center_x: float = judge_line.global_position.x + judge_line.size.x * 0.5
	var float_offset: float = lerp(0.0, 10.0, combo_ratio) * pulse
	combo_wave_rect.global_position = Vector2(
		center_x - combo_wave_rect.size.x * 0.5,
		judge_line.global_position.y - 26.0 - combo_wave_rect.size.y - float_offset
	)

	var heat: Color = _get_expression_heat_color()
	if final_solo_active:
		combo_wave_rect.color = Color(heat.r, heat.g, heat.b, lerp(0.16, 0.42, combo_ratio))
	else:
		combo_wave_rect.color = Color(1.0, 1.0, 1.0, lerp(0.0, 0.28, combo_ratio))

	combo_label.scale = Vector2.ONE * lerp(1.0, 1.20 if final_solo_active else 1.16, combo_ratio)
	combo_label.position = combo_label_base_position + Vector2(0, -lerp(0.0, 8.0, combo_ratio) * pulse)
	combo_label.modulate = Color(0.92, 0.94, 0.98, 1.0)


func _setup_result_skip_buttons():
	var success_button = _create_result_skip_button(
		"直达成功结局",
		Vector2(-236, 24),
		Callable(self, "_on_skip_success_pressed")
	)
	var failure_button = _create_result_skip_button(
		"直达失败结局",
		Vector2(-236, 70),
		Callable(self, "_on_skip_failure_pressed")
	)

	ui_root.add_child(success_button)
	ui_root.add_child(failure_button)


func _create_result_skip_button(text_value: String, top_right_offset: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.anchor_top = 0.0
	button.anchor_bottom = 0.0
	button.offset_left = top_right_offset.x
	button.offset_top = top_right_offset.y
	button.offset_right = top_right_offset.x + 212.0
	button.offset_bottom = top_right_offset.y + 36.0
	button.custom_minimum_size = Vector2(212, 36)
	button.focus_mode = Control.FOCUS_NONE
	button.z_index = 35
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(callback)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.075, 0.07, 0.84)
	style.border_color = Color(0.72, 0.56, 0.34, 0.24)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10

	var hover := style.duplicate()
	hover.bg_color = Color(0.13, 0.12, 0.11, 0.90)

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	_apply_button_typography(button, 15)

	return button


func _setup_ending_overlay():
	ending_fade_rect = ColorRect.new()
	ending_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_fade_rect.anchor_left = 0.0
	ending_fade_rect.anchor_top = 0.0
	ending_fade_rect.anchor_right = 1.0
	ending_fade_rect.anchor_bottom = 1.0
	ending_fade_rect.offset_left = 0.0
	ending_fade_rect.offset_top = 0.0
	ending_fade_rect.offset_right = 0.0
	ending_fade_rect.offset_bottom = 0.0
	ending_fade_rect.color = Color(0, 0, 0, 0.0)
	ending_fade_rect.visible = false
	ending_fade_rect.z_index = 80
	fx_layer.add_child(ending_fade_rect)

	result_center_label = Label.new()
	result_center_label.anchor_left = 0.5
	result_center_label.anchor_top = 0.5
	result_center_label.anchor_right = 0.5
	result_center_label.anchor_bottom = 0.5
	result_center_label.offset_left = -340
	result_center_label.offset_top = -80
	result_center_label.offset_right = 340
	result_center_label.offset_bottom = 80
	result_center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_center_label.visible = false
	result_center_label.z_index = 81
	fx_layer.add_child(result_center_label)

	_apply_label_typography(result_center_label, 38, Color(0.92, 0.88, 0.80, 1.0), 7)


func _setup_lane_feedback():
	for lane_id in [1, 2, 3]:
		var lane_node = _get_lane_node(lane_id)
		if lane_node == null:
			continue

		var label := Label.new()
		label.text = ""
		label.visible = false
		label.z_index = 30
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_label_typography(label, 24, Color(0.92, 0.88, 0.78, 1.0), 6)
		add_child(label)
		lane_feedback_labels[lane_id] = label

		var flash := ColorRect.new()
		flash.color = Color(1, 1, 1, 0)
		flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flash.z_index = 15
		add_child(flash)
		lane_flash_rects[lane_id] = flash

	_update_lane_feedback_positions()


func _update_lane_feedback_positions():
	for lane_id in [1, 2, 3]:
		var lane_node = _get_lane_node(lane_id)
		if lane_node == null:
			continue

		var center_x: float = lane_node.global_position.x + lane_node.size.x * 0.5
		var judge_y: float = judge_line.global_position.y

		if lane_feedback_labels.has(lane_id):
			var label: Label = lane_feedback_labels[lane_id]
			label.global_position = Vector2(center_x - 52, judge_y - 72)

		if lane_flash_rects.has(lane_id):
			var flash: ColorRect = lane_flash_rects[lane_id]
			flash.global_position = Vector2(lane_node.global_position.x, judge_y - 14)
			flash.size = Vector2(lane_node.size.x, 28)


func _get_lane_node(lane_id: int) -> Control:
	match lane_id:
		1:
			return $NoteLayer/Lane1
		2:
			return $NoteLayer/Lane2
		3:
			return $NoteLayer/Lane3
	return null


func _load_chart():
	var path := "res://project/data/minigame/final_performance_chart.json"

	if not FileAccess.file_exists(path):
		push_error("找不到 chart 文件：%s" % path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("final_performance_chart.json 解析失败")
		return

	chart_data = parsed
	notes_data = chart_data.get("notes", [])
	segments = chart_data.get("segments", [])
	choice_points = chart_data.get("choice_points", [])


func _play_final_music():
	var audio_path: String = str(chart_data.get("audio_path", ""))

	if audio_path == "":
		push_error("final_performance_chart.json 里没有 audio_path")
		return

	if not ResourceLoader.exists(audio_path):
		push_error("音频路径不存在：%s" % audio_path)
		return

	audio_player.stop()
	audio_player.stream = load(audio_path)
	audio_player.volume_db = base_bgm_volume_db
	audio_player.stream_paused = false
	audio_player.play()
	_play_interactive_stems()
	_update_performance_duration()


func _play_interactive_stems():
	for lane_id in lane_stem_players.keys():
		var p := lane_stem_players[lane_id] as AudioStreamPlayer
		if p == null:
			continue

		p.stop()
		p.volume_db = STEM_MUTED_DB
		p.stream_paused = false
		p.play(0.0)


func _setup_interaction_audio():
	var audio_bus := _get_interaction_audio_bus()

	lane_stem_streams = {
		1: _load_interaction_stream(LANE_1_STEM_PATH),
		2: _load_interaction_stream(LANE_2_STEM_PATH),
		3: _load_interaction_stream(LANE_3_STEM_PATH)
	}

	for lane_id in [1, 2, 3]:
		var stem_stream := lane_stem_streams.get(lane_id, null) as AudioStream
		if stem_stream == null:
			push_warning("Lane %d 互动分轨未加载，选择后不会产生音乐联动。" % lane_id)
			continue

		var stem_player := AudioStreamPlayer.new()
		stem_player.name = "Lane%dChoiceMusicStem" % lane_id
		stem_player.stream = stem_stream
		stem_player.bus = audio_bus
		stem_player.volume_db = STEM_MUTED_DB
		stem_player.max_polyphony = 1
		add_child(stem_player)

		lane_stem_players[lane_id] = stem_player


func _load_interaction_stream(path: String):
	if not ResourceLoader.exists(path):
		push_warning("最终演出选择音乐层不存在：%s" % path)
		return null
	return load(path)


func _get_interaction_audio_bus() -> String:
	if audio_player != null and audio_player.bus != "" and AudioServer.get_bus_index(audio_player.bus) != -1:
		return audio_player.bus
	if AudioServer.get_bus_index("Performance") != -1:
		return "Performance"
	if AudioServer.get_bus_index("Music") != -1:
		return "Music"
	return "Master"


func _setup_intensity_overlay():
	intensity_overlay = ColorRect.new()
	intensity_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intensity_overlay.anchor_left = 0.0
	intensity_overlay.anchor_top = 0.0
	intensity_overlay.anchor_right = 1.0
	intensity_overlay.anchor_bottom = 1.0
	intensity_overlay.offset_left = 0.0
	intensity_overlay.offset_top = 0.0
	intensity_overlay.offset_right = 0.0
	intensity_overlay.offset_bottom = 0.0
	intensity_overlay.color = Color(1, 1, 1, 0)
	intensity_overlay.z_index = 6
	fx_layer.add_child(intensity_overlay)


func _get_expression_volume_bias() -> float:
	match expression_bias:
		"art":
			return 0.8
		"human":
			return 0.2
		"business":
			return -0.6
	return 0.0


func _get_stem_tap_peak_volume(lane_id: int, result: String) -> float:
	var peak := -2.0

	match lane_id:
		1:
			peak = -1.0
		2:
			peak = -2.0
		3:
			peak = -3.8

	match result:
		"perfect":
			return peak + _get_expression_volume_bias()
		"good":
			return peak - 1.0 + _get_expression_volume_bias()

	return peak - 2.5 + _get_expression_volume_bias()


func _get_stem_hold_target_volume(lane_id: int) -> float:
	var target := -4.0

	match lane_id:
		1:
			target = -2.8
		2:
			target = -4.0
		3:
			target = -5.5

	return target + _get_expression_volume_bias()


func _get_expression_intensity_idle_target() -> float:
	if final_solo_active:
		return FINAL_SOLO_MIN_INTENSITY

	match expression_bias:
		"art":
			return 0.70
		"human":
			return 0.58
		"business":
			return 0.42
	return 0.35


func _get_expression_intensity_gain_scale() -> float:
	var solo_bonus := 1.0
	if final_solo_active:
		solo_bonus = 1.22

	match expression_bias:
		"art":
			return 1.50 * solo_bonus
		"human":
			return 1.15 * solo_bonus
		"business":
			return 0.80 * solo_bonus
	return 1.0 * solo_bonus


func _get_expression_intensity_loss_scale() -> float:
	if final_solo_active:
		return 0.72

	match expression_bias:
		"art":
			return 1.20
		"human":
			return 0.90
		"business":
			return 0.65
	return 1.0


func _get_expression_heat_color() -> Color:
	return expression_theme_color


func _apply_expression_choice_theme(choice_id: String):
	match choice_id:
		"art":
			expression_theme_color = Color(1.0, 0.76, 0.28, 1.0)
			expression_theme_strength = 1.30
			performance_intensity = max(performance_intensity, 0.82)
			_tween_stage_bg(Color(1.0, 0.82, 0.42, 1.0), 0.24)
			_tween_stage_scale(base_stage_bg_scale * 1.07, 0.24)
			_tween_stage_offset(Vector2(12, -12), 0.24)
			_tween_character_layer(Color(1.0, 0.92, 0.78, 1.0), base_character_scale * 1.05, 0.24)
			_pulse_segment_title(Color(1.0, 0.84, 0.34, 1.0), Vector2(1.18, 1.18))
			_flash_screen(Color(1.0, 0.78, 0.22), 0.30, 0.04, 0.22)

		"human":
			expression_theme_color = Color(1.0, 0.94, 0.84, 1.0)
			expression_theme_strength = 1.05
			performance_intensity = max(performance_intensity, 0.68)
			_tween_stage_bg(Color(1.0, 0.95, 0.88, 1.0), 0.24)
			_tween_stage_scale(base_stage_bg_scale * 1.035, 0.24)
			_tween_stage_offset(Vector2(0, -4), 0.24)
			_tween_character_layer(Color(1.0, 0.98, 0.94, 1.0), base_character_scale * 1.03, 0.24)
			_pulse_segment_title(Color(1.0, 0.97, 0.92, 1.0), Vector2(1.12, 1.12))
			_flash_screen(Color(1.0, 0.96, 0.90), 0.24, 0.04, 0.20)

		"business":
			expression_theme_color = Color(0.58, 0.84, 1.0, 1.0)
			expression_theme_strength = 0.95
			performance_intensity = max(performance_intensity, 0.52)
			_tween_stage_bg(Color(0.72, 0.88, 1.0, 1.0), 0.24)
			_tween_stage_scale(base_stage_bg_scale * 1.015, 0.24)
			_tween_stage_offset(Vector2(-10, 0), 0.24)
			_tween_character_layer(Color(0.88, 0.96, 1.0, 1.0), base_character_scale * 1.01, 0.24)
			_pulse_segment_title(Color(0.74, 0.91, 1.0, 1.0), Vector2(1.12, 1.12))
			_flash_screen(Color(0.58, 0.84, 1.0), 0.24, 0.04, 0.20)

		_:
			expression_theme_color = Color(1.0, 1.0, 1.0, 1.0)
			expression_theme_strength = 0.0

	_apply_performance_intensity()


func _update_performance_intensity(delta_value: float):
	performance_intensity = clampf(performance_intensity + delta_value, 0.0, 1.0)
	print("performance_intensity -> ", performance_intensity)
	_apply_performance_intensity()


func _apply_performance_intensity():
	var t: float = performance_intensity
	var heat: Color = _get_expression_heat_color()
	var overlay_alpha: float = clampf(expression_theme_strength * 0.12 + lerp(0.0, 0.36, t), 0.0, 0.48)

	if final_solo_active:
		overlay_alpha = clampf(overlay_alpha + 0.08, 0.0, 0.50)

	note_layer.modulate = Color(1, 1, 1, 1)

	segment_title.modulate = Color(
		lerp(1.0, heat.r, t * 0.85),
		lerp(1.0, heat.g, t * 0.85),
		lerp(1.0, heat.b, t * 0.85),
		1.0
	)

	if intensity_overlay:
		if final_solo_active:
			intensity_overlay.color = Color(1, 1, 1, 0)
		else:
			intensity_overlay.color = Color(
				heat.r,
				heat.g,
				heat.b,
				overlay_alpha
			)


func _play_interaction_note(lane_id: int, result: String):
	return


func _pulse_lane_stem(lane_id: int, result: String):
	if not lane_stem_players.has(lane_id):
		return

	var p := lane_stem_players[lane_id] as AudioStreamPlayer
	if p == null:
		return

	if lane_stem_tweens.has(lane_id):
		var old_tween: Tween = lane_stem_tweens[lane_id]
		if is_instance_valid(old_tween):
			old_tween.kill()

	var peak_volume: float = _get_stem_tap_peak_volume(lane_id, result)
	peak_volume += lerp(-0.4, 0.6, float(performance_intensity))

	var tween := create_tween()
	lane_stem_tweens[lane_id] = tween
	tween.tween_property(p, "volume_db", peak_volume, 0.025)
	tween.tween_property(p, "volume_db", STEM_MUTED_DB, STEM_TAP_GATE_TIME)


func _start_hold_interaction_note(lane_id: int):
	if not lane_stem_players.has(lane_id):
		return

	if lane_stem_tweens.has(lane_id):
		var old_tween: Tween = lane_stem_tweens[lane_id]
		if is_instance_valid(old_tween):
			old_tween.kill()

	var p := lane_stem_players[lane_id] as AudioStreamPlayer
	if p == null:
		return

	var target_volume: float = _get_stem_hold_target_volume(lane_id)
	target_volume += lerp(-0.6, 0.8, float(performance_intensity))

	var tween := create_tween()
	lane_stem_tweens[lane_id] = tween
	tween.tween_property(p, "volume_db", target_volume, STEM_HOLD_FADE_IN)


func _stop_hold_interaction_note(lane_id: int):
	if not lane_stem_players.has(lane_id):
		return

	if lane_stem_tweens.has(lane_id):
		var old_tween: Tween = lane_stem_tweens[lane_id]
		if is_instance_valid(old_tween):
			old_tween.kill()

	var p := lane_stem_players[lane_id] as AudioStreamPlayer
	if p == null:
		return

	var tween := create_tween()
	lane_stem_tweens[lane_id] = tween
	tween.tween_property(p, "volume_db", STEM_MUTED_DB, STEM_HOLD_FADE_OUT)


func _stop_all_hold_interaction_notes():
	for lane_id in lane_stem_players.keys():
		_stop_hold_interaction_note(lane_id)


func _stop_all_tap_interaction_notes():
	for lane_id in lane_stem_players.keys():
		if lane_stem_tweens.has(lane_id):
			var old_tween: Tween = lane_stem_tweens[lane_id]
			if is_instance_valid(old_tween):
				old_tween.kill()

		var p := lane_stem_players[lane_id] as AudioStreamPlayer
		if p != null:
			p.volume_db = STEM_MUTED_DB


func _stop_all_interaction_notes():
	_stop_all_tap_interaction_notes()
	_stop_all_hold_interaction_notes()


func _duck_bgm(amount_delta: float = -0.8, down_time: float = 0.015, up_time: float = 0.10):
	if audio_player == null:
		return

	if bgm_duck_tween and is_instance_valid(bgm_duck_tween):
		bgm_duck_tween.kill()

	bgm_duck_tween = create_tween()
	bgm_duck_tween.tween_property(audio_player, "volume_db", base_bgm_volume_db + amount_delta, down_time)
	bgm_duck_tween.tween_property(audio_player, "volume_db", base_bgm_volume_db, up_time)


func _spawn_notes(current_time: float):
	while note_index < notes_data.size():
		var data_v: Variant = notes_data[note_index]
		if typeof(data_v) != TYPE_DICTIONARY:
			note_index += 1
			continue

		var data: Dictionary = data_v
		if float(data.get("time", 0.0)) - current_time >= 2.0:
			break

		var note = NOTE_SCENE.instantiate()
		note.lane = int(data.get("lane", 1))
		note.hit_time = float(data.get("time", 0.0))
		note.note_type = str(data.get("type", "tap"))
		note.duration = float(data.get("duration", 0.0))
		active_notes.add_child(note)
		note_index += 1


func _update_segment(t: float):
	for i in range(segments.size()):
		var seg_v: Variant = segments[i]
		if typeof(seg_v) != TYPE_DICTIONARY:
			continue

		var seg: Dictionary = seg_v
		if t >= float(seg.get("start", 0.0)) and t < float(seg.get("end", 0.0)) and current_segment != i:
			current_segment = i
			segment_title.text = str(seg.get("title", ""))
			_on_segment_changed(str(seg.get("id", "")))
			break


func _check_choice_point(t: float):
	if current_choice_done:
		return

	for point in choice_points:
		if typeof(point) != TYPE_DICTIONARY:
			continue

		if abs(t - float(point.get("time", 0.0))) < 0.15:
			current_choice_point = point
			_show_expression_choice()
			current_choice_done = true
			break


func _show_expression_choice():
	choice_active = true
	_stop_all_interaction_notes()
	_apply_choice_point_texts(current_choice_point)
	_show_choice_panel_animated()
	_fade_pause_music()
	_flash_screen(Color(0.0, 0.0, 0.0), 0.16, 0.04, 0.18)

	art_button.grab_focus()


func on_choice_selected(choice_id: String):
	expression_bias = choice_id
	_apply_expression_choice_theme(choice_id)

	match choice_id:
		"art":
			emotion_score += 8
			_show_lane_feedback(1, "ART", Color(1.0, 0.84, 0.30, 1.0))
			_show_lane_feedback(2, "ART", Color(1.0, 0.84, 0.30, 1.0))
			_show_lane_feedback(3, "ART", Color(1.0, 0.84, 0.30, 1.0))

		"human":
			emotion_score += 10
			control_score += 2
			_show_lane_feedback(1, "HUMAN", Color(1.0, 0.96, 0.90, 1.0))
			_show_lane_feedback(2, "HUMAN", Color(1.0, 0.96, 0.90, 1.0))
			_show_lane_feedback(3, "HUMAN", Color(1.0, 0.96, 0.90, 1.0))

		"business":
			control_score += 10
			_show_lane_feedback(1, "CTRL", Color(0.64, 0.88, 1.0, 1.0))
			_show_lane_feedback(2, "CTRL", Color(0.64, 0.88, 1.0, 1.0))
			_show_lane_feedback(3, "CTRL", Color(0.64, 0.88, 1.0, 1.0))

	_refresh_score_ui()
	_hide_choice_panel_animated()
	choice_active = false
	_resume_music_for_choice(choice_id)


func _on_art_button_pressed():
	on_choice_selected("art")


func _on_human_button_pressed():
	on_choice_selected("human")


func _on_business_button_pressed():
	on_choice_selected("business")


func _on_skip_success_pressed():
	_play_result_transition("success", true)


func _on_skip_failure_pressed():
	_play_result_transition("failure", true)


func _kill_tween(ref: Tween):
	if ref and is_instance_valid(ref):
		ref.kill()


func _tween_stage_bg(target_color: Color, duration: float = 0.35):
	_kill_tween(stage_color_tween)
	stage_color_tween = create_tween()
	stage_color_tween.tween_property(stage_bg, "modulate", target_color, duration)


func _pulse_segment_title(text_color: Color, scale_to: Vector2 = Vector2(1.08, 1.08)):
	segment_title.modulate = text_color
	segment_title.scale = scale_to

	var tween = create_tween()
	tween.tween_property(segment_title, "scale", Vector2.ONE, 0.18)


func _flash_screen(color: Color, peak_alpha: float = 0.45, in_time: float = 0.06, out_time: float = 0.22):
	flash_rect.color = Color(color.r, color.g, color.b, 0.0)
	flash_rect.visible = true

	var tween = create_tween()
	tween.tween_property(flash_rect, "color:a", peak_alpha, in_time)
	tween.tween_property(flash_rect, "color:a", 0.0, out_time)

func _clear_visual_filters_for_final_solo():
	# 关闭全屏强度滤镜。
	if intensity_overlay != null:
		intensity_overlay.color = Color(1, 1, 1, 0)

	# 关闭普通闪白层。
	if flash_rect != null:
		flash_rect.color = Color(1, 1, 1, 0)
		flash_rect.visible = false

	# 恢复舞台背景原始颜色，不做染色。
	if stage_color_tween and is_instance_valid(stage_color_tween):
		stage_color_tween.kill()
	stage_bg.modulate = base_stage_bg_modulate

	# 恢复角色层原始颜色，只保留呼吸缩放。
	if character_tween and is_instance_valid(character_tween):
		character_tween.kill()
	character_layer.modulate = base_character_modulate

	# 如果之前加过最终独奏 glow 层，也关掉。
	if "final_solo_glow_rect" in self:
		if final_solo_glow_rect != null:
			final_solo_glow_rect.visible = false
			final_solo_glow_rect.color = Color(1, 1, 1, 0)
			

func _set_title_text(title: String):
	segment_title.text = title


func _tween_character_layer(target_modulate: Color, target_scale: Vector2, duration: float = 0.35):
	_kill_tween(character_tween)
	character_tween = create_tween()
	character_tween.parallel().tween_property(character_layer, "modulate", target_modulate, duration)
	character_tween.parallel().tween_property(character_layer, "scale", target_scale, duration)


func _tween_stage_offset(target_offset: Vector2, duration: float = 0.35):
	_kill_tween(stage_offset_tween)
	stage_offset_tween = create_tween()
	stage_offset_tween.tween_property(stage_bg, "position", base_stage_bg_position + target_offset, duration)


func _tween_stage_scale(target_scale: Vector2, duration: float = 0.35):
	_kill_tween(stage_scale_tween)
	stage_scale_tween = create_tween()
	stage_scale_tween.tween_property(stage_bg, "scale", target_scale, duration)


func _pulse_judge_line(hit_color: Color, strength: float = 1.0):
	if judge_line == null:
		return

	var base_modulate := Color(1, 1, 1, 1)
	var base_scale := Vector2.ONE
	var peak_scale := Vector2(1.0 + 0.04 * strength, 1.0 + 0.12 * strength)

	var tween = create_tween()
	tween.parallel().tween_property(judge_line, "modulate", hit_color, 0.05)
	tween.parallel().tween_property(judge_line, "scale", peak_scale, 0.05)
	tween.tween_interval(0.03)
	tween.parallel().tween_property(judge_line, "modulate", base_modulate, 0.10)
	tween.parallel().tween_property(judge_line, "scale", base_scale, 0.10)


func _pulse_stage_hit(strength: float = 1.0):
	_kill_tween(stage_hit_tween)
	var current_scale: Vector2 = stage_bg.scale
	var bump: float = 1.010 + strength * 0.010
	stage_hit_tween = create_tween()
	stage_hit_tween.tween_property(stage_bg, "scale", current_scale * bump, 0.05)
	stage_hit_tween.tween_property(stage_bg, "scale", current_scale, 0.10)


func _stop_solo_breath():
	if solo_breath_tween and is_instance_valid(solo_breath_tween):
		solo_breath_tween.kill()
	solo_breath_tween = null
	character_layer.scale = base_character_scale


func _start_solo_breath():
	_stop_solo_breath()
	_stop_all_interaction_notes()
	solo_breath_tween = create_tween()
	solo_breath_tween.set_loops()
	solo_breath_tween.tween_property(character_layer, "scale", base_character_scale * 1.045, 0.42)
	solo_breath_tween.tween_property(character_layer, "scale", base_character_scale * 1.01, 0.42)


func _apply_segment_stage(target_color: Color, target_offset: Vector2, target_scale: Vector2, duration: float = 0.35):
	_tween_stage_bg(target_color, duration)
	_tween_stage_offset(target_offset, duration)
	_tween_stage_scale(target_scale, duration)


func _on_segment_changed(segment_id: String):
	if segment_id != "final_solo":
		_stop_solo_breath()
		_stop_final_solo_state()

	print("segment changed -> ", segment_id)

	match segment_id:
		"intro":
			_set_title_text("走上舞台")
			_show_segment_transition("走上舞台", Color(0.86, 0.88, 1.0, 1.0))
			_tween_stage_bg(Color(0.35, 0.35, 0.45, 1.0), 0.30)
			_flash_screen(Color(0.2, 0.2, 0.3), 0.18, 0.05, 0.20)

		"main_phrase":
			_finish_memory_flash_slideshow()
			_set_title_text("找回稳定")
			_show_segment_transition("找回稳定", Color(0.90, 0.92, 1.0, 1.0))
			_tween_stage_bg(Color(0.75, 0.75, 0.82, 1.0), 0.30)
			_flash_screen(Color(1.0, 1.0, 1.0), 0.10, 0.03, 0.12)

		"expression":
			_set_title_text("演出表达")
			_show_segment_transition("演出表达", Color(1.0, 0.82, 0.42, 1.0))
			_tween_stage_bg(Color(1.0, 0.88, 0.62, 1.0), 0.30)
			_flash_screen(Color(1.0, 0.85, 0.45), 0.18, 0.04, 0.16)

		"band_response":
			_set_title_text("乐队联动")
			_show_segment_transition("乐队联动", Color(0.70, 0.90, 1.0, 1.0))
			emotion_score += _calc_band_bonus()
			_refresh_score_ui()
			_tween_stage_bg(Color(0.72, 0.88, 1.0, 1.0), 0.30)
			_flash_screen(Color(0.7, 0.9, 1.0), 0.18, 0.04, 0.16)

		"memory_flash":
			_return_to_main_music(choice_music_fade_out)
			_set_title_text("记忆闪回")
			_show_segment_transition("记忆闪回", Color(1.0, 1.0, 1.0, 1.0))
			_start_memory_flash_slideshow()
			_tween_stage_bg(Color(1.0, 1.0, 1.0, 1.0), 0.12)
			_flash_screen(Color(1.0, 1.0, 1.0), 0.35, 0.04, 0.22)

		"final_solo":
			_finish_memory_flash_slideshow()
			_set_title_text("最终独奏")
			_show_segment_transition("最终独奏", Color(1.0, 0.92, 0.35, 1.0))

			# 最终独奏阶段不再加滤镜、不再闪白、不再给舞台染色。
			_clear_visual_filters_for_final_solo()

			_start_solo_breath()
			if has_method("_start_final_solo_state"):
				_start_final_solo_state()

		"ending_hold":
			_finish_memory_flash_slideshow()
			_stop_final_solo_state()
			_return_to_main_music(0.8)
			_set_title_text("收束落幕")
			_show_segment_transition("收束落幕", Color(0.86, 0.86, 0.92, 1.0))
			_tween_stage_bg(Color(0.18, 0.18, 0.22, 1.0), 0.40)
			_flash_screen(Color(0.0, 0.0, 0.0), 0.20, 0.06, 0.20)


func _get_core_value(key: String) -> float:
	if ResourceManager == null:
		return 0.0

	if ResourceManager.has_method("get_core_resource_value"):
		return float(ResourceManager.get_core_resource_value(key))

	if ResourceManager.has_method("get_resource_value"):
		return float(ResourceManager.get_resource_value(key))

	var core_resources: Variant = ResourceManager.get("core_resources")
	if typeof(core_resources) == TYPE_DICTIONARY and core_resources.has(key):
		var item: Variant = core_resources[key]
		if typeof(item) == TYPE_DICTIONARY:
			return float(item.get("value", 0))
		return float(item)

	return 0.0


func _member_unlocked(member_id: String) -> bool:
	if ResourceManager == null:
		return false

	var members: Variant = ResourceManager.get("members")
	if typeof(members) != TYPE_DICTIONARY:
		return false
	if not members.has(member_id):
		return false

	var member: Variant = members[member_id]
	if typeof(member) == TYPE_DICTIONARY:
		return bool(member.get("unlocked", false))

	return false


func _apply_prebattle_bonus():
	var mem: float = _get_core_value("memory_recovery")
	var cohesion: float = _get_core_value("cohesion")
	var creativity: float = _get_core_value("creativity")

	tech_score += mem * 0.1
	emotion_score += cohesion * 0.05
	control_score += creativity * 0.05


func _calc_band_bonus() -> float:
	var bonus := 0.0

	if _member_unlocked("rio"):
		bonus += 5.0
	if _member_unlocked("kira"):
		bonus += 5.0
	if _member_unlocked("mei"):
		bonus += 5.0
	if _member_unlocked("finn"):
		bonus += 5.0

	return bonus


func register_hit(lane_id: int, result: String):
	match result:
		"perfect":
			perfect_count += 1
			_update_performance_intensity(0.16 * _get_expression_intensity_gain_scale())
			combo += 1
			tech_score += 2
			control_score += 1.5
			_show_lane_feedback(lane_id, "PERFECT", Color(1.0, 0.9, 0.3, 1.0))
			_pulse_judge_line(Color(1.0, 0.88, 0.25, 1.0), 1.15)

		"good":
			good_count += 1
			_update_performance_intensity(0.08 * _get_expression_intensity_gain_scale())
			combo += 1
			tech_score += 1
			control_score += 1
			_show_lane_feedback(lane_id, "GOOD", Color(0.4, 0.9, 1.0, 1.0))
			_pulse_judge_line(Color(0.45, 0.85, 1.0, 1.0), 0.85)

		"miss":
			miss_count += 1
			_update_performance_intensity(-0.22 * _get_expression_intensity_loss_scale())
			combo = 0
			control_score -= 1
			_show_lane_feedback(lane_id, "MISS", Color(0.85, 0.85, 0.85, 1.0))
			_pulse_judge_line(Color(0.75, 0.75, 0.75, 1.0), 0.55)

	if current_segment >= 0 and str(segments[current_segment].get("id", "")) == "final_solo":
		emotion_score += 0.7
		_trigger_final_solo_hit_fx(lane_id, result)

	_refresh_score_ui()


func register_hold_start(lane_id: int):
	_update_performance_intensity(0.06 * _get_expression_intensity_gain_scale())
	_show_lane_feedback(lane_id, "HOLD", Color(1.0, 1.0, 1.0, 1.0))

	if final_solo_active:
		_trigger_final_solo_hit_fx(lane_id, "good")


func _show_lane_feedback(lane_id: int, text: String, color: Color):
	if not lane_feedback_labels.has(lane_id):
		return
	if not lane_flash_rects.has(lane_id):
		return

	if lane_feedback_tweens.has(lane_id):
		var old_tween: Tween = lane_feedback_tweens[lane_id]
		if is_instance_valid(old_tween):
			old_tween.kill()

	_update_lane_feedback_positions()

	var label: Label = lane_feedback_labels[lane_id]
	var flash: ColorRect = lane_flash_rects[lane_id]

	label.text = text
	label.visible = true
	label.modulate = Color(color.r, color.g, color.b, 1.0)
	label.scale = Vector2(1.15, 1.15)

	if final_solo_active:
		label.scale = Vector2(1.28, 1.28)

	var base_pos: Vector2 = label.global_position
	flash.color = Color(color.r, color.g, color.b, 0.38 if not final_solo_active else 0.55)

	var tween = create_tween()
	lane_feedback_tweens[lane_id] = tween

	tween.parallel().tween_property(label, "scale", Vector2(1.0, 1.0), 0.10)
	tween.parallel().tween_property(label, "global_position", base_pos + Vector2(0, -22 if final_solo_active else -18), 0.18)
	tween.tween_interval(0.05)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.18)
	tween.parallel().tween_property(flash, "color:a", 0.0, 0.16)
	tween.finished.connect(func():
		label.visible = false
		_update_lane_feedback_positions()
	)


func _refresh_score_ui():
	combo_label.text = "Combo: %d" % combo
	tech_label.text = "技术 %.0f" % tech_score
	emotion_label.text = "感染 %.0f" % emotion_score
	control_label.text = "控制 %.0f" % control_score


func _evaluate_performance_result() -> Dictionary:
	var judged: int = perfect_count + good_count + miss_count
	var total_chart_notes: int = maxi(notes_data.size(), 1)
	var completion: float = clampf(float(judged) / float(total_chart_notes), 0.0, 1.0)

	var accuracy := 0.0
	if judged > 0:
		accuracy = (float(perfect_count) + float(good_count) * 0.72) / float(judged)

	var core_total: float = tech_score + emotion_score + control_score
	var combo_bonus: float = min(combo, 60) * 0.35
	var performance_value: float = core_total + accuracy * 24.0 + completion * 12.0 + combo_bonus

	var success: bool = accuracy >= 0.58 and control_score >= 10.0 and performance_value >= 62.0
	var result_type := "success" if success else "failure"

	return {
		"result_type": result_type,
		"judged": judged,
		"completion": completion,
		"accuracy": accuracy,
		"core_total": core_total,
		"combo_bonus": combo_bonus,
		"performance_value": performance_value
	}


func _finish_performance():
	if performance_locked:
		return

	_stop_solo_breath()
	_stop_final_solo_state()
	_stop_all_interaction_notes()
	_finish_memory_flash_slideshow()

	last_result_info = _evaluate_performance_result()
	print("最终演出结果：", {
		"tech": tech_score,
		"emotion": emotion_score,
		"control": control_score,
		"expression_bias": expression_bias,
		"judgment": last_result_info
	})

	_play_result_transition(str(last_result_info.get("result_type", "failure")), false)


func _play_result_transition(result_type: String, forced_skip: bool):
	if performance_locked:
		return

	performance_locked = true
	choice_active = true
	_stop_all_interaction_notes()
	_stop_solo_breath()
	_stop_final_solo_state()
	_finish_memory_flash_slideshow()

	if choice_audio_fade_tween and is_instance_valid(choice_audio_fade_tween):
		choice_audio_fade_tween.kill()
	if bgm_duck_tween and is_instance_valid(bgm_duck_tween):
		bgm_duck_tween.kill()
	if result_transition_tween and is_instance_valid(result_transition_tween):
		result_transition_tween.kill()

	ending_fade_rect.visible = true
	result_center_label.visible = false
	ending_fade_rect.color = Color(0, 0, 0, 0.0)

	result_transition_tween = create_tween()

	if audio_player and audio_player.stream != null and (audio_player.playing or audio_player.stream_paused == false):
		result_transition_tween.parallel().tween_property(audio_player, "volume_db", base_bgm_volume_db - 26.0, 0.36)

	for lane_id in lane_stem_players.keys():
		var p := lane_stem_players[lane_id] as AudioStreamPlayer
		if p != null:
			result_transition_tween.parallel().tween_property(p, "volume_db", STEM_MUTED_DB, 0.36)

	result_transition_tween.parallel().tween_property(ending_fade_rect, "color:a", 1.0, 0.55)
	result_transition_tween.parallel().tween_property(stage_bg, "modulate", Color(0.05, 0.05, 0.05, 1.0), 0.55)

	result_transition_tween.finished.connect(func():
		if audio_player:
			audio_player.stop()
			audio_player.volume_db = base_bgm_volume_db

		for lane_id in lane_stem_players.keys():
			var p := lane_stem_players[lane_id] as AudioStreamPlayer
			if p != null:
				p.stop()
				p.volume_db = STEM_MUTED_DB

		_open_result_ending(result_type, forced_skip)
	)


func _open_result_ending(result_type: String, forced_skip: bool):
	var scene_path := SUCCESS_ENDING_SCENE_PATH if result_type == "success" else FAILURE_ENDING_SCENE_PATH

	if FileAccess.file_exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
		return

	var title_text := "演出成功" if result_type == "success" else "演出失败"
	var desc_text := "观众被你重新点燃。"
	if result_type == "failure":
		desc_text = "这场演出没能撑到最后。"

	if forced_skip:
		desc_text = "已直接跳转到%s结局占位页。" % ("成功" if result_type == "success" else "失败")

	result_center_label.text = "%s\n\n%s" % [title_text, desc_text]
	result_center_label.visible = true


func _unhandled_input(event):
	if choice_active or performance_locked:
		return

	if event.is_action_pressed("lane_1"):
		held_lanes[1] = true
		_try_hit_lane(1)
	elif event.is_action_released("lane_1"):
		held_lanes[1] = false

	if event.is_action_pressed("lane_2"):
		held_lanes[2] = true
		_try_hit_lane(2)
	elif event.is_action_released("lane_2"):
		held_lanes[2] = false

	if event.is_action_pressed("lane_3"):
		held_lanes[3] = true
		_try_hit_lane(3)
	elif event.is_action_released("lane_3"):
		held_lanes[3] = false


func _try_hit_lane(lane_id: int):
	var now: float = audio_player.get_playback_position()
	var best_note = null
	var best_diff := 99999.0

	for note in active_notes.get_children():
		if note.lane != lane_id:
			continue

		if note.has_method("is_holding_started") and note.is_holding_started():
			continue

		var offset: float = note.hit_time - now
		if offset < -0.18 or offset > 0.16:
			continue

		var diff: float = abs(offset)
		if diff < best_diff:
			best_diff = diff
			best_note = note

	if best_note != null:
		best_note.try_hit(lane_id)


func is_lane_held(lane_id: int) -> bool:
	return held_lanes.get(lane_id, false)
