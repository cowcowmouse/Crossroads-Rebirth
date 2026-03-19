# 乐队酒吧经营游戏 - 模块接口文档

## 一、全局单例（所有模块可直接调用）

### ResourceManager - 资源管理
**可调用方法：**
- `get_fund()` -> int                    # 获取资金
- `add_fund(amount)` / `reduce_fund(amount)`
- `get_reputation()` / `add_reputation()` / `reduce_reputation()`
- `get_cohesion()` / `add_cohesion()` / `reduce_cohesion()`
- `get_creativity()` / `add_creativity()` / `reduce_creativity()`
- `add_art_weight(amount)`               # 加艺术权重
- `add_business_weight(amount)`           # 加商业权重
- `add_human_weight(amount)`               # 加人情权重

**发射信号：**
- `resource_changed(type, old, new)`      # UI模块监听更新显示

### GameManager - 流程控制
**可调用方法：**
- `get_current_week()` -> int             # 当前周数
- `get_current_phase()` -> string         # 当前阶段
- `next_week()`                           # 进入下一周

**发射信号：**
- `week_changed(week)`
- `phase_changed(phase)`

### EventBus - 事件总线
**预定义信号（供各模块发射/监听）：**
- `action_points_exhausted()`              # 行动点耗尽 -> 触发周中事件
- `facility_upgraded(type, level)`         # 设施升级 -> UI更新外观
- `member_status_changed(id, stat, val)`   # 成员状态变化 -> UI更新
- `event_triggered(id)`                     # 事件触发
- `weekly_settlement_started/finished()`    # 周结算生命周期
- `game_over(reason)`                       # 游戏结束

## 二、各模块职责与接口

### B模块（QZH）- 经营模块
**负责：** 设施管理界面、设施升级逻辑、行动点系统
**需要实现：**
- `FacilityManager.upgrade(type)` -> bool  # 升级设施（成功后发射facility_upgraded信号）
- 升级时调用：`ResourceManager.reduce_fund(cost)`、`EventBus.emit("facility_upgraded")`
- 行动点耗尽时发射：`EventBus.emit("action_points_exhausted")`

### C模块（CHP）- UI/人物交互
**负责：** 主场景UI、成员对话界面、成员状态管理
**需要实现：**
- `MemberManager.get_members()` -> Array   # 获取成员列表
- 成员状态变化时发射：`EventBus.emit("member_status_changed", id, stat, val)`
- UI监听：`ResourceManager.resource_changed`更新数值显示

### D模块（ZYY）- 小游戏
**负责：** 小游戏场景、星级结算
**需要实现：**
- 小游戏结束后调用：`ResourceManager.add_fund(奖励)`等

### E模块（LZX）- 事件系统
**负责：** 周中事件触发、事件对话框
**需要实现：**
- `EventManager.trigger_weekly_event()`    # 触发周中事件
- 监听：`EventBus.action_points_exhausted` 触发事件
- 选项点击后调用：`ResourceManager`相关方法修改资源
