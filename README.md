# 《Crossroads: Rebirth》- 十字路口的重生

🎸 一款乐队经营叙事游戏，融合经营策略、角色养成与多线叙事。

## 🎮 游戏简介
玩家将扮演失忆的乐队主唱 Alexi，在 18 周内经营酒吧、招募成员、恢复记忆，最终决定乐队的命运走向。

## ✨ 核心特性
- **三幕式叙事**：余烬→淬火→重生，记忆恢复度决定剧情深度
- **行动点系统**：每周 3 点行动点，策略分配经营决策
- **AI 权重体系**：艺术/商业/人情三维度，影响剧情分支
- **多结局系统**：基于记忆恢复度、AI 权重、关键事件判定
- **成员养成**：9 名可招募成员，独立的个人线剧情

## 🛠️ 技术栈
- **引擎**：Godot 4.5.1 LTS
- **语言**：GDScript 2.0
- **版本控制**：Git + GitHub
- **项目管理**：Scrum (2周Sprint)

# 乐队酒吧经营游戏

## 项目结构
project/
├── assets/ # 美术资源（角色/UI/CG）
├── audio/ # 音频文件（BGM/音效）
├── scenes/ # 场景文件
│ ├── main/ # 主场景
│ ├── cutscene/ # 过场动画
│ ├── lounge/ # 副场景1—休息室
│ ├── rehearsal/ # 副场景2—排练室
│ ├── facility/ # 设施模块（B负责）
│ ├── member/ # 成员模块（C负责）
│ ├── minigame/ # 小游戏模块（D负责）
│ ├── event/ # 事件模块（E负责）
│ └── shared/ # 共享组件
├── scripts/ # 脚本文件
│ ├── autoload/ # 全局单例（A负责）
│ ├── modules/ # 功能模块
│ │ ├── facility/ # 设施模块（B）
│ │ ├── member/ # 成员模块（C）
│ │ └── minigame/ # 小游戏模块（D）    
│ │ └── event/ # 事件模块（E）
│ └── utils/ # 工具脚本
├── data/ # 配置文件
│ ├── config/ # 游戏配置 (A)
│ ├── facilities/ # 设施数据（B）
│ ├── members/ # 成员数据（C）
│ └── minigame/ # 小游戏数据（D）
│ └── events/ # 事件数据 （E）
└── docs/ # 文档
└── Tests/ # 测试
	├── Resources/
	└── Unit/

## 分工
- **A（LXZ）**：`scripts/autoload/` - 全局单例、流程控制
- **B（QZH）**：`scenes/facility/` + `scripts/modules/facility/` - 设施模块
- **C（CHP）**：`scenes/member/` + `scripts/modules/member/` - 成员/UI模块
- **D（ZYY）**：`scenes/event/MiniGame.tscn` - 小游戏模块
- **E（LZX）**：`scenes/event/` + `scripts/modules/event/` - 事件模块
## 接口文档
详见 `docs/INTERFACE.md`
