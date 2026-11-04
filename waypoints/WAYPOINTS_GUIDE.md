# waypoints 目录说明

> 最后更新：2026-11-04

## 一、目录作用

`waypoints/` 是本 RomBot 项目存放**路径点（Waypoint）文件**的目录。路径点文件定义了机器人（Bot）在游戏《Runes of Magic》世界中行走的坐标路线，以及在到达特定坐标时执行的 Lua 动作（交互 NPC、交接任务、使用物品、战斗、切换路径等）。

### 文件格式

路径点文件为标准 XML，根节点为 `<waypoints>`，每个 `<waypoint>` 节点包含：

- `x` / `z`（可选 `y`）：游戏世界坐标
- `type` 属性：`RUN`（普通行走）、`TRAVEL`（旅行模式）、`NORMAL` 等，控制移动方式
- 节点内容：到达该点后执行的 Lua 代码段
- `<onLoad>` 标签：路径加载时执行一次的逻辑（常包含大量 Lua 自动化逻辑，此时路径本身可能只有极少数坐标点）

路径文件通过 `bot.lua` 加载执行，文件名由 Profile 中的 `WAYPOINTS` 配置指定，或启动时交互选择。配套的 `*_onload.lua` / `*_functions.lua` 文件通过 XML 中的 `include()` 或约定命名被引用。

## 二、文件清单与分类

共 **85 个文件**：根目录 23 个（20 个 XML + 3 个 Lua 辅助脚本），子目录 62 个。

### 1. 演示与教学示例（7 个，根目录）

| 文件 | 功能 |
|------|------|
| `demo.xml` / `demo1.xml` / `demo2.xml` / `demo3.xml` | 基础路径演示，展示坐标行走、`player:sleep()` 暂停、`loadPaths()` 路径切换 |
| `demo_return.xml` / `demo3_return.xml` | 返程路径演示，与主线路径配合演示 `RETURNPATH` 用法 |
| `demo_npc.xml` | NPC 交互演示：`target_NPC` 锁定 NPC、`mouseclickL` 模拟点击对话选项（配合商户 Dan 演示自动修理） |

### 2. 调试与命令行工具（3 个，根目录）

| 文件 | 功能 |
|------|------|
| `CommandLine.xml` | 在游戏内打开交互式 Lua 命令行，可直接输入并执行 Lua 语句（输入 `q` 退出），用于调试 |
| `objdump.xml` | 对象导出工具：自动遍历并转储场景内目标/怪物对象的详细信息（ID、属性等），供开发调试使用 |
| `nuk-test.xml` | 功能测试用的临时路径脚本 |

### 3. 挂机辅助脚本（3 个，根目录）

| 文件 | 功能 |
|------|------|
| `RBAssist.xml` | Rock5 挂机助手：支持 `trigger`（按键触发攻击）/ `auto`（自动攻击开关）/ `disabled`（只治疗增益不攻击）三种模式，含自动反击、自动喝药、宠物与技能管理、死亡复活等待 |
| `partyhealer.xml` | 队伍治疗专用脚本：持续调用 `PartyHeals()` 为全队补血、驱散、增益 |
| `partydps.xml` | 队伍输出专用脚本：循环调用 `PartyDPS()` 自动攻击目标，配合队长/治疗脚本使用 |

### 4. 练级与训练脚本（3 个，根目录）

| 文件 | 功能 |
|------|------|
| `WepTraining.xml` | 武器熟练度训练：自动攻击训练目标（训练塔、城门等固定物体）刷武器技能等级，自动施放增益技能、使用音乐道具、统计升级进度与剩余时间、自动修理装备 |
| `AndorTraining.xml` | Andor 训练场活动自动化：自动进入训练场玩法、按波次击杀模拟敌人、统计得分，结束后可自动换号（`relog` / `charlist`）、记录日志 |
| `AndorTraining_onload.lua` | `AndorTraining.xml` 的 onLoad 逻辑（Lua 辅助脚本） |
| `AndorTrainingprova.xml` | Andor 训练脚本的测试变体（"prova" 意为试用/测试版） |

### 5. 游戏活动/事件脚本（5 个，根目录）

| 文件 | 功能 |
|------|------|
| `survivalR5.xml` + `survivalR5onload.lua` | **生存模式（Survival of the Fittest）活动**：自动清理小怪、按固定顺序挖掘 36 块宝藏瓷砖、丢炸弹、击杀守卫获取钥匙，带边缘防掉出坐标计算与得分控制；`onload.lua` 含全部核心函数（瓦片表构建、自定义战斗、换号策略） |
| `NalaMelody.xml` | **音乐节重复活动**：与 NPC Nala Melody 交互、操作音乐能量收集装置、收集能量点，可配置传送石使用数量 |
| `Lyliya.xml` | **Lyliya 家具活动**：围绕 NPC 自动拾取家具材料、移动物品到物品商店背包 |
| `elite Skill Heffner.xml` | **精英技能任务（Invaders from the Sea）**：自动完成入侵者任务链，收集任务物品与背包奖励 |
| `invaders_functions.lua` | 上述精英技能脚本的函数库：技能表、任务状态判断、任务链分流（`setupSubQuest`）等 |

### 6. 1-10 级拓荒者新手任务链（62 个，子目录）

三个子目录共同组成 1-10 级新角色的完整练级+任务自动化，按**打怪路线**与**任务路线**分离设计，通过 `loadPaths()` 相互衔接：

| 子目录 | 数量 | 功能 |
|--------|------|------|
| `1-10Pioneers/` | 17 | 打怪/练级路线（狼、熊、野猪、甲虫、蝙蝠、虫子等区域），含升级到等级后自动切换下一路线、返回补给 |
| `1-10PioneersQuests/` | 22 | 任务路线：在固定坐标与任务 NPC（Laif Cindai、Leighton、Mallor、Shamp、Reideen 等）交互，自动接取/提交任务、打开任务奖励礼包、穿戴装备 |
| `1-10PioneersQuests_Bear/` | 23 | 与 `1-10PioneersQuests/` 同构的**熊族路线变体**（覆盖不同出身/地图差异），含个别原始备份文件 |

子目录内文件命名规律：`l{N}t_{npc/区域}.xml` 表示"第 N 级、在 NPC X / 区域 Y 处的任务路线"；文件名带 `_return` 为原路返回路线；带 `-` 的如 `l7-8_boar.xml` 表示 7-8 级阶段路线。

## 三、工作机制

1. **加载**：bot 启动后读取 Profile 中 `WAYPOINTS` 指向的 XML（如 `demo.xml`）或列出本目录供选择
2. **onLoad**：若 XML 含 `<onLoad>` 标签则先执行其中的初始化 Lua 逻辑（配置选项、函数定义、初始状态检查）
3. **行走**：角色沿 `<waypoint>` 坐标依次移动（按 `type` 决定行走/旅行模式）
4. **执行动作**：到达每个坐标点后执行节点内嵌 Lua（交接任务、使用物品、战斗等）
5. **路径切换**：通过 `loadPaths("子目录/文件名")` 或返回路径（`RETURNPATH`）衔接下一阶段
6. **结束/换号**：带有换号功能的脚本（如 survival、AndorTraining）会在完成后按 `When_Finished` 配置结束脚本、切换账号或加载指定路径

## 四、使用建议

- **演示文件**（demo*）仅用于学习路径格式，实际挂机建议复制后修改坐标
- **活动脚本**（survivalR5、AndorTraining、NalaMelody 等）顶层都有 `-- User Options` 配置区，使用前需按自身情况调整（如背包格数限制、换号策略、目标得分）
- **1-10 级任务链**需与 `profiles/l1-10.xml` 配合，选择对应种族（人族 / 熊族）的 Quest 子目录
- **新增路径**可使用 `createpath.lua` 或游戏内录制（Numpad 快捷键）生成，保存到此目录
- 修改前建议先备份本目录；游戏更新后坐标可能失效，需用 `getpos.lua` 重新采集