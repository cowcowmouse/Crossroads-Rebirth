extends Node

# 这个脚本不需要写任何逻辑，只需要存在
# 所有模块通过它发射和监听信号

# 预定义信号（供其他模块参考）
signal action_points_exhausted()           # 行动点耗尽
signal facility_upgraded(facility_type, new_level)  # 设施升级
signal member_status_changed(member_id, stat_type, new_value)  # 成员状态变化
signal event_triggered(event_id)           # 事件触发
signal weekly_settlement_started()          # 周结算开始
signal weekly_settlement_finished()         # 周结算结束
signal game_over(reason)                    # 游戏结束