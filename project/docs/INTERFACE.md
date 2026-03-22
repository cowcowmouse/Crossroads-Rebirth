# 乐队酒吧经营游戏 - 模块接口文档

> 最后更新：2026-03-22
> 所有模块开发前必须阅读本文档，严格按照接口调用。

---

## 一、全局单例（所有模块可直接调用）

### 1. Constants - 常量定义
**位置：** `scripts/autoload/Constants.gd`（已注册为自动加载）

存放所有字符串ID、枚举值、键名，避免硬编码和拼写错误。

#### 核心资源ID
| 常量 | 值 | 说明 |
|------|-----|------|
| `Constants.RES_MONEY` | "money" | 资金 |
| `Constants.RES_REPUTATION` | "reputation" | 声誉 |
| `Constants.RES_COHESION` | "cohesion" | 凝聚力 |
| `Constants.RES_CREATIVITY` | "creativity" | 创造力 |
| `Constants.RES_MEMORY` | "memory" | 记忆恢复度 |

#### AI权重ID
| 常量 | 值 | 说明 |
|------|-----|------|
| `Constants.WEIGHT_ART` | "art" | 艺术权重 |
| `Constants.WEIGHT_BUSINESS` | "business" | 商业权重 |
| `Constants.WEIGHT_HUMAN` | "human" | 人情权重 |

#### 游戏阶段ID
| 常量 | 值 | 说明 |
|------|-----|------|
| `Constants.PHASE_EARLY` | "early" | 前期（1-3周） |
| `Constants.PHASE_MID` | "mid" | 中期（4-12周） |
| `Constants.PHASE_LATE` | "late" | 后期（13-18周） |

#### 设施类型ID
| 常量 | 值 | 说明 |
|------|-----|------|
| `Constants.FACILITY_STAGE` | "stage" | 舞台 |
| `Constants.FACILITY_BAR` | "bar" | 酒吧 |
| `Constants.FACILITY_REHEARSAL` | "rehearsal" | 排练室 |
| `Constants.FACILITY_LOUNGE` | "lounge" | 休息室 |

#### 成员ID
| 常量 | 值 | 说明 |
|------|-----|------|
| `Constants.MEMBER_RIO` | "rio" | 里奥（鼓手） |
| `Constants.MEMBER_KIRA` | "kira" | 凯拉（主唱） |
| `Constants.MEMBER_MEI` | "mei" | 梅（贝斯手） |
| `Constants.MEMBER_old_NAIL` | "old_nail" | 老钉子（酒吧守护者） |

#### 成员属性ID
| 常量 | 值 | 说明 |
|------|-----|------|
| `Constants.MEMBER_MORALE` | "morale" | 士气 |
| `Constants.MEMBER_FATIGUE` | "fatigue" | 疲劳度 |
| `Constants.MEMBER_HEALTH` | "health" | 健康值 |
| `Constants.MEMBER_SKILL` | "skill" | 技巧 |
| `Constants.MEMBER_CHARM` | "charm" | 魅力 |
| `Constants.MEMBER_RELATIONSHIP_PROGRESS` | "relationship_progress" | 互动进度 |
| `Constants.MEMBER_WEEKLY_CHAT_COUNT` | "weekly_chat_count" | 周对话次数 |

#### 小游戏相关ID
| 常量 | 值 | 说明 |
|------|-----|------|
| `Constants.MINIGAME_REHAB` | "rehabilitation" | 康复训练 |
| `Constants.MINIGAME_PERFORM` | "performance" | 商演 |
| `Constants.DIFFICULTY_EASY` | "easy" | 简单难度 |
| `Constants.DIFFICULTY_NORMAL` | "normal" | 普通难度 |
| `Constants.DIFFICULTY_HARD` | "hard" | 困难难度 |

#### 游戏结束原因
| 常量 | 值 | 说明 |
|------|-----|------|
| `Constants.GAME_OVER_BANKRUPT` | "bankrupt" | 资金耗尽破产 |
| `Constants.GAME_OVER_BAND_BROKEN` | "band_broken" | 成员解散 |

#### 辅助方法
| 方法 | 返回值 | 说明 |
|------|--------|------|
| `Constants.get_all_member_ids()` | Array | 获取所有成员ID列表 |
| `Constants.get_all_facility_types()` | Array | 获取所有设施类型列表 |
| `Constants.get_all_resource_types()` | Array | 获取所有资源类型列表 |
| `Constants.get_all_weight_types()` | Array | 获取所有权重类型列表 |

---

### 2. GameConfig - 游戏配置
**位置：** `data/config/GameConfig.gd`（已注册为自动加载）

存放游戏数值配置（资源边界、成本、倍率等），方便后期平衡调整。

#### 资源边界配置
GameConfig.RESOURCE_BOUNDARIES = {
    "money": {"min": 0, "max": 999999, "initial": 5000},
    "reputation": {"min": 0, "max": 100, "initial": 10, "thresholds": [30, 70]},
    "cohesion": {"min": 0, "max": 100, "initial": 60, "danger": 30},
    "creativity": {"min": 0, "max": 100, "initial": 30, "warning": 10},
    "memory": {"min": 0, "max": 100, "initial": 0, "threshold": 100}
}


#### 行动点配置
GameConfig.ACTION_POINTS = {"max_per_week": 3}


#### 设施升级成本
GameConfig.get_upgrade_cost(facility_type, current_level) -> int


#### 设施升级效果
GameConfig.FACILITY_EFFECTS[facility_type][level] -> Dictionary


#### 阶段解锁内容
GameConfig.PHASE_UNLOCKS[phase] -> Dictionary


#### 辅助方法
| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `get_phase_by_week(week)` | week: int | String | 根据周数获取阶段 |
| `get_weekly_expense(phase)` | phase: String | int | 获取当前阶段每周支出 |
| `get_upgrade_cost(facility_type, level)` | facility_type, level | int | 获取升级成本 |
| `check_prerequisite(facility_type, level, levels)` | facility_type, level, levels | bool | 检查升级前置条件 |

---

### 3. EventBus - 事件总线（核心通信中枢）
**位置：** `scripts/autoload/EventBus.gd`

所有模块通过这里发射和监听信号，**严禁直接调用其他模块的方法**。

#### 资源相关信号
| 信号 | 参数 | 说明 | 发射者 |
|------|------|------|--------|
| `core_resource_changed` | (resource_name, new_value, delta) | 核心资源变化时发射 | ResourceManager |
| `weight_changed` | (weight_name, new_value, delta) | AI权重变化时发射 | ResourceManager |
| `resource_warning` | (resource_name, value, severity) | 资源边界警告 | ResourceManager |

#### 成员相关信号
| 信号 | 参数 | 说明 | 发射者 |
|------|------|------|--------|
| `member_stat_changed` | (member_id, stat_name, new_value, delta) | 成员状态变化 | ResourceManager |
| `member_dialogue_stage_changed` | (member_id, new_stage) | 对话阶段切换 | ResourceManager |
| `member_unlocked` | (member_id) | 新成员解锁 | ResourceManager |

#### 设施相关信号
| 信号 | 参数 | 说明 | 发射者 |
|------|------|------|--------|
| `facility_upgraded` | (facility_type, new_level) | 设施升级时发射 | B模块 |

#### 事件相关信号
| 信号 | 参数 | 说明 | 发射者 |
|------|------|------|--------|
| `event_triggered` | (event_id) | 事件触发时发射 | E模块 |
| `event_option_chosen` | (event_id, option_index) | 事件选项被选时发射 | E模块 |

#### 小游戏相关信号
| 信号 | 参数 | 说明 | 发射者 |
|------|------|------|--------|
| `minigame_started` | (game_type, difficulty) | 小游戏开始 | D模块 |
| `minigame_finished` | (game_type, star_rating, score) | 小游戏结束 | D模块 |
| `minigame_skipped` | (game_type) | 小游戏被跳过 | D模块 |

#### 周结算相关信号
| 信号 | 参数 | 说明 | 发射者 |
|------|------|------|--------|
| `weekly_settlement_started` | (week) | 周结算开始 | GameManager |
| `weekly_settlement_finished` | (week) | 周结算结束 | GameManager |
| `action_points_exhausted` | () | 行动点耗尽 | B模块 |

#### 游戏流程相关信号
| 信号 | 参数 | 说明 | 发射者 |
|------|------|------|--------|
| `game_over` | (reason) | 游戏结束 | GameManager |
| `week_changed` | (week) | 周数变化 | GameManager |
| `phase_changed` | (phase) | 阶段变化 | GameManager |

#### UI相关信号
| 信号 | 参数 | 说明 | 发射者 |
|------|------|------|--------|
| `ui_refresh_requested` | (target) | UI刷新请求 | UIManager |
| `element_highlight` | (element, text) | 高亮UI元素 | UIManager |
| `highlight_cleared` | () | 清除高亮 | UIManager |
| `scene_opened` | (scene_name) | 子场景打开 | UIManager |
| `scene_closed` | () | 子场景关闭 | UIManager |

---

### 4. ResourceManager - 资源管理
**位置：** `scripts/autoload/ResourceManager.gd`

#### 核心资源操作
| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `add_money(amount)` | amount: int | bool | 增加资金（负数即减少） |
| `add_reputation(amount)` | amount: int | bool | 增加声誉 |
| `add_cohesion(amount)` | amount: int | bool | 增加凝聚力 |
| `add_creativity(amount)` | amount: int | bool | 增加创造力 |
| `add_memory(amount)` | amount: int | bool | 增加记忆恢复度 |
| `get_resource_value(resource_name)` | resource_name: String | int | 获取资源值 |
| `modify_core_resource(resource_name, delta)` | resource_name: String, delta: int | bool | 通用资源修改 |

**使用示例：**
# 使用 Constants 中的资源ID
ResourceManager.add_money(1000)
ResourceManager.add_reputation(5)
ResourceManager.add_cohesion(10)

#### AI权重操作
| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `modify_ai_weight(weight_name, delta)` | weight_name: String, delta: int | void | 修改AI权重 |
| `get_ai_weight(weight_name)` | weight_name: String | int | 获取权重值 |
| `get_all_weights()` | 无 | Dictionary | 获取所有权重 |

**使用示例：**
# 使用 Constants 中的权重ID
ResourceManager.modify_ai_weight(Constants.WEIGHT_ART, 1)
ResourceManager.modify_ai_weight(Constants.WEIGHT_BUSINESS, 2)

#### 成员数据操作
| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `get_member_data(member_id)` | member_id: String | Dictionary | 获取成员完整数据 |
| `get_unlocked_members()` | 无 | Array | 获取已解锁成员ID列表 |
| `modify_member_stat(member_id, stat_name, delta)` | member_id, stat_name, delta | bool | 修改成员属性 |
| `get_member_stat(member_id, stat_name)` | member_id, stat_name | int | 获取成员属性值 |
| `add_relationship_progress(member_id, delta)` | member_id, delta: int | int | 增加互动进度（默认+1） |
| `get_dialogue_stage(member_id)` | member_id: String | int | 获取对话阶段(1-3) |
| `apply_member_natural_change()` | 无 | void | 应用成员自然变化 |
| `reset_weekly_chat_counts()` | 无 | void | 重置周对话次数 |

**使用示例：**
# 使用 Constants 中的成员ID和属性ID
ResourceManager.modify_member_stat(Constants.MEMBER_RIO, Constants.MEMBER_MORALE, 5)
ResourceManager.modify_member_stat(Constants.MEMBER_KIRA, Constants.MEMBER_FATIGUE, -10)

# 增加互动进度
ResourceManager.add_relationship_progress(Constants.MEMBER_MEI)

# 获取对话阶段
var stage = ResourceManager.get_dialogue_stage(Constants.MEMBER_RIO)

---

### 5. GameManager - 流程控制
**位置：** `scripts/autoload/GameManager.gd`

| 方法 | 返回值 | 说明 |
|------|--------|------|
| `get_current_week()` | int | 获取当前周数（1-18） |
| `get_current_phase()` | String | 获取当前阶段（early/mid/late） |
| `next_week()` | void | 进入下一周 |
| `weekly_settlement()` | void | 执行周末结算 |

**使用示例：**
# 获取当前阶段
var phase = GameManager.get_current_phase()

# 根据阶段获取配置
var expense = GameConfig.get_weekly_expense(phase)

---

### 6. UIManager - UI管理
**位置：** `scripts/autoload/UIManager.gd`

#### 场景切换
| 方法 | 说明 |
|------|------|
| `show_main_scene()` | 显示主场景 |
| `show_sub_scene(scene_path)` | 显示子场景 |
| `close_sub_scene()` | 关闭当前子场景 |

#### 对话框
| 方法 | 说明 |
|------|------|
| `show_dialog(text, options, callback)` | 显示通用对话框 |
| `show_member_dialogue(member_id)` | 显示成员对话界面 |
| `show_event_dialog(event_id)` | 显示事件对话框 |
| `show_minigame(game_type, difficulty)` | 显示小游戏 |
| `show_settlement_panel(week_data)` | 显示周结算面板 |
| `close_dialog()` | 关闭当前对话框 |

#### 提示与弹窗
| 方法 | 说明 |
|------|------|
| `show_tooltip(text, position)` | 显示浮动提示（2秒自动消失） |
| `show_notification(text, duration)` | 显示通知 |
| `show_confirm_dialog(text, on_confirm, on_cancel)` | 显示确认对话框 |

#### UI刷新
| 方法 | 说明 |
|------|------|
| `update_resource_display()` | 刷新资源显示 |
| `update_member_display()` | 刷新成员显示 |
| `update_facility_display()` | 刷新设施显示 |

#### 新手引导
| 方法 | 说明 |
|------|------|
| `highlight_element(element_path, text)` | 高亮UI元素 |
| `clear_highlight()` | 清除高亮 |

**使用示例：**
# 使用 Constants 中的成员ID
UIManager.show_member_dialogue(Constants.MEMBER_RIO)

# 使用 Constants 中的小游戏类型和难度
UIManager.show_minigame(Constants.MINIGAME_REHAB, Constants.DIFFICULTY_NORMAL)


---

## 二、各模块职责与信号调用关系

### B模块（QZH）- 经营模块（设施+行动点）
**路径：** `scenes/facility/` + `scripts/modules/facility/`

**负责：**
- 四类设施升级逻辑（舞台/酒吧/排练室/休息室）
- 行动点系统（上限3点，每周重置）
- 设施管理界面

**需要实现：**
# FacilityManager.gd
func upgrade_facility(facility_type: String) -> bool:
    # 1. 检查资金和行动点
    var cost = GameConfig.get_upgrade_cost(facility_type, current_level)
    if ResourceManager.get_resource_value(Constants.RES_MONEY) < cost:
        return false
    
    # 2. 调用 ResourceManager
    ResourceManager.add_money(-cost)
    
    # 3. 发射信号（使用 Constants 中的设施类型）
    EventBus.facility_upgraded.emit(facility_type, new_level)

**监听的信号：**
- `weekly_settlement_finished` - 周结算结束，重置行动点

---

### C模块（CHP）- 成员/UI模块
**路径：** `scenes/member/` + `scripts/modules/member/`

**负责：**
- 主场景UI布局
- 成员头像显示与点击交互
- 成员对话系统（三阶段）
- 招募系统

**需要实现：**
# MemberManager.gd
func talk_to_member(member_id: String):
    # 使用 Constants 中的成员ID和属性
    ResourceManager.add_relationship_progress(member_id, 1)
    ResourceManager.add_weekly_chat_count(member_id)
    var stage = ResourceManager.get_dialogue_stage(member_id)
    # 显示对应阶段的对话

func member_operation(member_id: String, operation: String):
    # 成员管理操作
    ResourceManager.modify_member_stat(member_id, Constants.MEMBER_FATIGUE, -10)
    ResourceManager.add_money(-200)


**监听的信号：**
- `core_resource_changed` - 更新资源显示
- `member_stat_changed` - 更新成员状态显示
- `member_dialogue_stage_changed` - 更新对话文本

---

### D模块（ZYY）- 小游戏模块
**路径：** `scenes/minigame/` + `scripts/modules/minigame/`

**负责：**
- 小游戏场景（康复训练/商演等）
- 按键判定逻辑
- 星级计算（0-2星）
- 跳过功能

**需要实现：**
# MiniGameManager.gd
func start_game(game_type: String, difficulty: String):
    EventBus.minigame_started.emit(game_type, difficulty)

func on_game_finished(score: float):
    var star_rating = calculate_stars(score)
    # 发放奖励（使用 Constants 中的星级）
    ResourceManager.add_money(reward)
    EventBus.minigame_finished.emit(game_type, star_rating, score)

func skip_game():
    ResourceManager.add_money(-penalty)
    EventBus.minigame_skipped.emit(game_type)

---

### E模块（LZX）- 事件模块
**路径：** `scenes/event/` + `scripts/modules/event/`

**负责：**
- 周中事件触发机制
- 事件对话框界面
- 事件池管理（前期/中期/后期）
- 人物专属事件

**需要实现：**
# EventManager.gd
func _ready():
    EventBus.action_points_exhausted.connect(_on_action_points_exhausted)

func _on_action_points_exhausted():
    trigger_weekly_event()

func trigger_weekly_event():
    var event = get_random_event()
    EventBus.event_triggered.emit(event.id)
    UIManager.show_event_dialog(event.id)

func on_event_option_selected(event_id: String, option_index: int):
    # 应用事件效果
    ResourceManager.add_money(event.effects.money)
    ResourceManager.add_cohesion(event.effects.cohesion)
    # 事件抉择权重+2（使用 Constants 中的权重ID）
    ResourceManager.modify_ai_weight(Constants.WEIGHT_ART, 2)
    EventBus.event_option_chosen.emit(event_id, option_index)

---

## 三、数据流向图

┌─────────────────────────────────────────────────────────────────┐
│                        用户操作                                  │
└─────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ↓                       ↓                       ↓
┌───────────────┐       ┌───────────────┐       ┌───────────────┐
│   B模块       │       │   C模块       │       │   D/E模块     │
│ 设施/行动点   │       │ 成员/UI       │       │ 事件/小游戏   │
└───────────────┘       └───────────────┘       └───────────────┘
        │                       │                       │
        └───────────────────────┼───────────────────────┘
                                ↓
                    ┌───────────────────────┐
                    │   ResourceManager     │
                    │   修改核心资源/成员    │
                    └───────────────────────┘
                                │
                                ↓
                    ┌───────────────────────┐
                    │      EventBus         │
                    │   发射资源变化信号     │
                    └───────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ↓                       ↓                       ↓
┌───────────────┐       ┌───────────────┐       ┌───────────────┐
│   UI模块      │       │  GameManager  │       │   其他模块    │
│  刷新显示     │       │  检查游戏状态  │       │   响应变化    │
└───────────────┘       └───────────────┘       └───────────────┘

---

## 四、模块调用规则

| 调用方 | 可调用 | 不可直接调用 |
|--------|--------|--------------|
| B模块(设施) | ResourceManager, GameManager, UIManager, Constants, GameConfig | C/D/E模块的任何方法 |
| C模块(成员) | ResourceManager, GameManager, UIManager, Constants, GameConfig | B/D/E模块的任何方法 |
| D模块(小游戏) | ResourceManager, UIManager, Constants, GameConfig | B/C/E模块的任何方法 |
| E模块(事件) | ResourceManager, GameManager, UIManager, Constants, GameConfig | B/C/D模块的任何方法 |

**核心原则：所有跨模块通信必须通过 EventBus 信号，禁止直接调用其他模块的方法。**

---

## 五、常用代码片段

### UI监听资源变化
func _ready():
    EventBus.core_resource_changed.connect(_on_resource_changed)

func _on_resource_changed(resource_name: String, new_value: int, delta: int):
    match resource_name:
        Constants.RES_MONEY:
            $MoneyLabel.text = str(new_value)

### 成员状态变化监听
func _ready():
    EventBus.member_stat_changed.connect(_on_member_stat_changed)

func _on_member_stat_changed(member_id: String, stat_name: String, new_value: int, delta: int):
    if member_id == Constants.MEMBER_RIO and stat_name == Constants.MEMBER_FATIGUE:
        $RioFatigueBar.value = new_value

### 获取配置值
# 获取资源初始值
var initial_money = GameConfig.RESOURCE_BOUNDARIES.money.initial

# 获取每周支出
var expense = GameConfig.get_weekly_expense(GameManager.get_current_phase())

# 获取设施升级成本
var cost = GameConfig.get_upgrade_cost(Constants.FACILITY_STAGE, current_level)

### 发射信号示例
# 设施升级后
EventBus.facility_upgraded.emit(Constants.FACILITY_STAGE, 2)

# 游戏结束
EventBus.game_over.emit(Constants.GAME_OVER_BANKRUPT)

---

**所有模块开发前必须阅读本文档，严格按照接口调用。如有疑问，联系主程（A模块）。**