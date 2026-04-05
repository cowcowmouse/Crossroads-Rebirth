extends Node

# ==================== 资源相关信号 ====================
signal core_resource_changed(resource_name: String, new_value: int, delta: int)
signal weight_changed(weight_name: String, new_value: int, delta: int)
signal resource_warning(resource_name: String, value: int, severity: String)

# ==================== 成员相关信号 ====================
signal member_stat_changed(member_id: String, stat_name: String, new_value: int, delta: int)
signal member_dialogue_stage_changed(member_id: String, new_stage: int)
signal member_unlocked(member_id: String)

# ==================== 设施相关信号 ====================
signal facility_upgraded(facility_type: String, new_level: int)

# ==================== 事件相关信号 ====================
signal event_triggered(event_id: String)
signal event_option_chosen(event_id: String, option_index: int)
signal event_pool_determined(pool_name: String)  # ← 添加这个信号
signal event_effects_applied(event_data: Dictionary)  # ← 添加这个信号

# ==================== 小游戏相关信号 ====================
signal minigame_started(game_type: String, difficulty: String)
signal minigame_finished(score: int, rank: String)
signal minigame_skipped(game_type: String)

# ==================== 周结算相关信号 ====================
signal weekly_settlement_started(week: int)
signal weekly_settlement_finished(week: int)
signal action_points_exhausted()
signal action_point_changed(current: int, max: int)
signal action_point_depleted()

# ==================== 游戏流程相关信号 ====================
signal game_over(reason: String)
signal week_changed(week: int)
signal phase_changed(phase: String)
signal pre_week_start()
signal mid_week_start()
signal weekend_start()
signal week_end(week_num: int)

# ==================== UI相关信号 ====================
signal ui_refresh_requested(target: String)
signal element_highlight(element: Node, text: String)
signal highlight_cleared()
signal scene_opened(scene_name: String)
signal scene_closed()
