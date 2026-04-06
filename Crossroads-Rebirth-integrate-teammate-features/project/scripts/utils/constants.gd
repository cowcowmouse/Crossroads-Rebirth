# 全局常量枚举，所有硬编码配置统一放在这里
extends Node

# 周循环阶段枚举（必须在脚本内正确定义）
enum WeekCycleStage {
	PRE_WEEK,    # 周前：经营规划阶段
	MID_WEEK,    # 周中：事件触发阶段
	WEEKEND,     # 周末：结算阶段
	WEEK_END     # 本周结束，等待进入下一周
}

# 核心资源名称常量
const RES_MONEY: String = "money"
const RES_REPUTATION: String = "reputation"
const RES_COHESION: String = "cohesion"
const RES_CREATIVITY: String = "creativity"
const RES_MEMORY: String = "memory_recovery"

# AI权重常量
const WEIGHT_ART: String = "art"
const WEIGHT_BUSINESS: String = "business"
const WEIGHT_HUMAN: String = "human"

# 成员ID常量
const MEMBER_RIO: String = "rio"
const MEMBER_KIRA: String = "kira"
const MEMBER_MEI: String = "mei"
const MEMBER_FINN: String = "finn"
const MEMBER_old_NAIL: String = "old_nail"

# 行动点配置
const MAX_ACTION_POINT: int = 3
