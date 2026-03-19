extends Node
# 资源变动信号 
signal core_resource_changed(resource_name: String, new_value: int, delta: int)
signal member_state_changed(member_id: String, attr_name: String, new_value: int)
signal facility_level_up(facility_id: String, new_level: int)
# 行动点信号
signal action_point_changed(current: int, max: int)
signal action_point_depleted()
# 周循环阶段信号
signal pre_week_start()
signal mid_week_start()
signal weekend_start()
signal week_end(week_num: int)
# 事件与游戏流程信号
signal event_triggered(event_id: String)
signal game_stage_changed(new_stage: String)
signal ending_unlocked(ending_id: String)
signal game_over(end_type: String)
