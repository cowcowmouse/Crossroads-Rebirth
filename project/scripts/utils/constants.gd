# 全局常量与枚举定义
extends Node

# 周循环阶段枚举
enum WeekCycleStage {
    PRE_WEEK,    # 周前：经营规划阶段
    MID_WEEK,    # 周中：事件触发阶段
    WEEKEND,     # 周末：结算阶段
    WEEK_END     # 本周结束，等待进入下一周
}

# 游戏阶段枚举
enum GameStage {
    STAGE_1_EMBER,    # 第一幕：余烬（1-3周）
    STAGE_2_QUENCH,   # 第二幕：淬火（4-12周）
    STAGE_3_REBIRTH   # 第三幕：重生（13-18周）
}

# 核心资源名常量
const RES_MONEY: String = "money"
const RES_REPUTATION: String = "reputation"
const RES_COHESION: String = "cohesion"
const RES_CREATIVITY: String = "creativity"
const RES_MEMORY: String = "memory_recovery"

# 行动点常量
const MAX_ACTION_POINT: int = 3

# 成员ID常量（Pre用初始成员）
const MEMBER_RIO: String = "rio"
const MEMBER_KIRA: String = "kira"
const MEMBER_MEI: String = "mei"
const MEMBER_FINN: String = "finn"
