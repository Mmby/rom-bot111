# RoM-Bot 项目功能分析报告

> **项目名称**：RoM-Bot  
> **版本**：4.1  
> **项目性质**：Runes of Magic 游戏自动化机器人  
> **技术栈**：Lua + C++（MicroMacro 宿主引擎）  
> **运行平台**：Windows（通过 MicroMacro 脚本引擎附加到游戏进程）  
> **项目地址**：[SolarStrike-Software/rom-bot](https://github.com/SolarStrike-Software/rom-bot)

---

## 目录

- [1. 项目概述](#1-项目概述)
- [2. 整体架构](#2-整体架构)
- [3. 核心子系统功能详解](#3-核心子系统功能详解)
  - [3.1 主控调度系统](#31-主控调度系统)
  - [3.2 战斗系统](#32-战斗系统)
  - [3.3 移动与路径系统](#33-移动与路径系统)
  - [3.4 拾取与采集系统](#34-拾取与采集系统)
  - [3.5 物品与背包系统](#35-物品与背包系统)
  - [3.6 技能系统](#36-技能系统)
  - [3.7 宠物系统](#37-宠物系统)
  - [3.8 队伍系统](#38-队伍系统)
  - [3.9 死亡与复活系统](#39-死亡与复活系统)
  - [3.10 脱困系统](#310-脱困系统)
  - [3.11 NPC 交互与商店系统](#311-npc-交互与商店系统)
  - [3.12 任务系统](#312-任务系统)
  - [3.13 休息与睡眠系统](#313-休息与睡眠系统)
  - [3.14 事件与回调系统](#314-事件与回调系统)
  - [3.15 配置系统](#315-配置系统)
  - [3.16 内存与地址系统](#316-内存与地址系统)
  - [3.17 游戏通信系统](#317-游戏通信系统)
  - [3.18 多语言国际化系统](#318-多语言国际化系统)
  - [3.19 更新与维护系统](#319-更新与维护系统)
- [4. 用户扩展功能](#4-用户扩展功能)
- [5. 开发工具](#5-开发工具)
- [6. 数据库与静态资源](#6-数据库与静态资源)
- [7. 类继承关系](#7-类继承关系)
- [8. 文件目录结构总览](#8-文件目录结构总览)

---

## 1. 项目概述

RoM-Bot 是一个基于 **内存读取/写入** 的 Runes of Magic 游戏自动化机器人。它通过 MicroMacro 脚本引擎附加到游戏进程，直接读取游戏内存获取状态，并通过模拟键盘操作和写入游戏内宏来执行自动化行为。

### 核心能力

| 能力 | 说明 |
|------|------|
| 自动打怪 | 按路径行走，自动寻找并攻击怪物，支持近战/远程/混合战斗模式 |
| 自动拾取 | 战斗后自动拾取战利品，支持黑名单过滤 |
| 自动采集 | 自动采集矿石/木材/草药，支持扫描式搜索 |
| 路径行走 | 支持预定义路径点、漫游模式、返回路径、路径反转 |
| 自动技能 | 按职业配置技能优先级，自动施放技能和 Buff |
| 自动药水 | HP/MP 低于阈值时自动使用药水 |
| 自动复活 | 死亡后自动复活，支持死亡次数限制和自动登出 |
| 自动脱困 | 卡住时自动尝试脱困，超限后触发回调或登出 |
| 组队模式 | 支持队伍跟随、治疗、图标攻击、聊天监控 |
| 宠物管理 | 蛋宠召唤/收回/喂食/采集、战斗宠物攻击、仙女 Buff |
| NPC 交互 | 自动修理装备、出售物品、购买消耗品 |
| 任务辅助 | 按名称接受/完成任务，支持批量操作 |
| 多语言支持 | 英语、德语、法语、波兰语、葡萄牙语、俄语 |
| 用户扩展 | 通过 userfunctions 和 profile 事件回调扩展功能 |

---

## 2. 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                    MicroMacro 脚本引擎                        │
│  (宿主环境，提供进程附加、内存读写、键盘模拟、协程调度)          │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                    bot.lua (主入口/主循环)                     │
│  版本检查 → 加载依赖 → 初始化对象 → 路径选择 → 主循环          │
└─────────────────────────┬───────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
┌─────────▼─────┐ ┌───────▼───────┐ ┌─────▼─────────┐
│  基础设施层     │ │   类库层       │ │   配置层       │
│                │ │  (classes/)    │ │               │
│ addresses.lua  │ │                │ │ settings.lua  │
│ functions.lua  │ │ player.lua     │ │ macros.lua    │
│ database.lua   │ │ pawn.lua       │ │ profiles/     │
│ qword.lua      │ │ skill.lua      │ │ settings.xml  │
│                │ │ inventory.lua  │ │               │
│                │ │ waypointlist   │ │               │
│                │ │ ... (28个类)   │ │               │
└────────────────┘ └────────────────┘ └───────────────┘
          │               │               │
          └───────────────┼───────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
┌─────────▼─────┐ ┌───────▼───────┐ ┌─────▼─────────┐
│  数据层        │ │   扩展层       │ │   工具层       │
│                │ │               │ │               │
│ database/      │ │ userfunctions/│ │ devtools/     │
│  skills.xml    │ │  (9个脚本)    │ │  (游戏内插件)  │
│  nodes.xml     │ │               │ │               │
│  consumables   │ │ waypoints/    │ │ createpath    │
│  giftbags      │ │  (82个路径)   │ │ getid/getpos  │
│  mounts.lua    │ │               │ │ addrtest      │
└────────────────┘ └───────────────┘ └───────────────┘
```

### 游戏通信机制

```
机器人 (Lua)                          游戏客户端 (Client.exe)
    │                                          │
    │  1. writeToMacro(命令宏, Lua代码)          │
    │ ────────────────────────────────────────► │
    │                                          │
    │  2. keyboardPress(MACRO快捷键)             │
    │ ────────────────────────────────────────► │ 游戏执行宏中的 Lua 代码
    │                                          │
    │  3. readMacro(结果宏)                      │
    │ ◄──────────────────────────────────────── │ 游戏将结果写入结果宏
    │                                          │
    │  4. 解析返回值                             │
```

---

## 3. 核心子系统功能详解

### 3.1 主控调度系统

**入口文件**：`bot.lua`（1227 行）

主控系统是整个机器人的调度中枢，负责初始化所有子系统并运行主循环。

#### 初始化流程

1. **版本兼容性检查**：校验 MicroMacro 版本 ≤ 1.05
2. **加载依赖库**：依次加载 28 个类文件、配置文件、宏系统
3. **加载用户扩展**：扫描 `userfunctions/` 目录加载 `addon_*.lua` 和 `userfunction_*.lua`
4. **全局设置初始化**：加载 `settings.xml`，设置热键，检查 Git 更新
5. **命令行参数解析**：支持 `debug`、`profile:名`、`path:名`、`retpath:名`、`character:名`
6. **游戏附加**：`attach(getWin())` 附加到游戏窗口，缓存游戏文本
7. **核心对象实例化**：创建 `player`、`equipment`、`inventory`、`bank`、`guildbank`、`cursor`、`camera`、`store` 等全局对象
8. **Profile 加载**：根据角色名加载对应的 XML 配置文件
9. **路径选择**：交互式或自动选择 waypoint 文件
10. **路径定位**：找到最近路径点作为起始位置

#### 主循环（状态机）

每轮循环按以下顺序执行：

| 步骤 | 功能 | 条件 |
|------|------|------|
| 1 | 执行路径 onLoad 事件 | 路径有 DoOnload 标志 |
| 2 | 空路径检查 | waypoints 模式 |
| 3 | 掉线检查 | 不在游戏中则 flush 内存数据库 |
| 4 | 地址/登出检查 | `player:checkAddress()`、`player:logoutCheck()` |
| 5 | 死亡处理 | `player:updateAlive()`，死亡则调用 `resurrect()` |
| 6 | 弹药补充 | 根据 `RELOAD_AMMUNITION` 配置 |
| 7 | 睡眠模式 | `Sleeping` 标志为真且无战斗 |
| 8 | 定时库存更新 | 按 `INV_UPDATE_INTERVAL` 间隔 |
| 9 | 升级检测 | 等级提升触发 `onLevelup` 事件 |
| 10 | 休息恢复 | HP/MP 低于阈值 |
| 11 | 战斗检测 | 有 aggro 则 `findEnemy()` + `target()` |
| 12 | 战斗执行 | `player:fight()`，含路点跳过判定 |
| 13 | 移动导航 | 无目标时 `player:moveTo(wp)` |
| 14 | 脱困处理 | 移动失败时触发 unstick 流程 |
| 15 | 让出协程 | `coroutine.yield()` |

#### 关键函数

| 函数 | 行号 | 功能 |
|------|------|------|
| `main()` | 119-1103 | 主函数，初始化 + 主循环 |
| `resurrect()` | 1105-1226 | 复活处理：截图、onDeath 事件、自动复活、死亡计数、虚弱等待 |
| `list_waypoint_files()` | 337-589 | 交互式列出并选择路径文件 |
| `checkClientCrash()` | 707-716 | 定时检测游戏客户端崩溃（每 2 秒） |

---

### 3.2 战斗系统

**核心文件**：`classes/player.lua`（~4163 行）、`classes/skill.lua`（812 行）

战斗系统是机器人最复杂的子系统，负责目标选择、技能施放、战斗策略执行。

#### 功能清单

| 功能 | 实现函数 | 说明 |
|------|---------|------|
| 寻敌 | `player:findEnemy()` | 扫描周围怪物，按距离/等级/精英状态筛选 |
| 选目标 | `player:target()` | 选中目标并验证 |
| 战斗执行 | `player:fight()` | 主战斗循环，含 pull 阶段和近战/远程切换 |
| 技能施放 | `player:cast()` | 单技能施放，含面向、距离检查、GCD 处理 |
| 技能检查 | `player:checkSkills()` | 遍历技能列表，按优先级施放可用技能 |
| 技能队列 | `player:queueSkill()` / `flushSkillQueue()` | 支持技能排队执行 |
| 仇恨检测 | `player:check_aggro_before_cast()` | 施法前检测是否有仇恨 |
| 战斗中断 | `player:breakFight()` | 中断当前战斗 |
| 等待仇恨 | `player:waitForAggro()` | 等待怪物产生仇恨 |
| 面向目标 | `player:aimAt()` | 调整面向方向对准目标 |
| Click-to-Cast | `player:clickToCast()` | 通过点击施法 |
| 药水使用 | `player:checkPotions()` | HP/MP 低时自动使用药水 |
| 防抢杀 | `ANTI_KS` 选项 | 不攻击已被其他玩家攻击的怪物 |
| 精英怪检测 | `AUTO_ELITE_FACTOR` | HP 超过玩家 × 倍数视为精英，不主动攻击 |
| 等级过滤 | `TARGET_LEVELDIF_BELOW/ABOVE` | 只攻击指定等级差范围内的怪物 |
| 战斗超时 | `MAX_FIGHT_TIME` | 单次战斗超时后放弃 |
| 无伤害检测 | `MAX_SKILLUSE_NODMG` | 连续无伤害施法超限后放弃 |

#### 战斗配置项

| 配置 | 默认值 | 说明 |
|------|--------|------|
| `COMBAT_TYPE` | "melee" | 战斗类型：melee/ranged |
| `COMBAT_DISTANCE` | 200 | 战斗距离 |
| `COMBAT_RANGED_PULL` | true | 近战职业用远程技能拉怪 |
| `MAX_FIGHT_TIME` | 10 | 单次战斗最大时间（秒） |
| `ANTI_KS` | true | 防止抢杀 |
| `AUTO_TARGET` | true | 自动选怪 |
| `AUTO_ELITE_FACTOR` | 5 | 精英怪判定倍数 |
| `MAX_TARGET_DIST` | 250 | 最大选怪距离 |
| `DOT_PERCENT` | 90 | DoT 施放血量百分比 |
| `QUICK_TURN` | false | 快速转向 |

---

### 3.3 移动与路径系统

**核心文件**：`classes/waypointlist.lua`（458 行）、`classes/waypoint.lua`（35 行）、`classes/waypointlist_wander.lua`（35 行）

#### 功能清单

| 功能 | 实现函数 | 说明 |
|------|---------|------|
| 路径加载 | `CWaypointList:load(filename)` | 从 XML 文件加载路径点 |
| 路径推进 | `CWaypointList:advance()` | 前进到下一路径点 |
| 路径后退 | `CWaypointList:backward()` | 后退到上一路径点 |
| 获取下一路点 | `CWaypointList:getNextWaypoint()` | 获取下一路径点（含偏差随机化） |
| 方向控制 | `CWaypointList:setDirection()` / `reverse()` | 设置行走方向 / 反转路径 |
| 最近路点查找 | `CWaypointList:getNearestWaypoint()` | 查找距离最近的路径点 |
| 标签查找 | `CWaypointList:findWaypointTag(tag)` | 按标签查找路径点 |
| 路点类型强制 | `CWaypointList:setForcedWaypointType()` | 强制设置路径点类型 |
| 移动执行 | `player:moveTo(wp)` | 移动到指定路径点 |
| 范围移动 | `player:moveInRange()` | 移动到指定范围内 |
| 面向调整 | `player:faceDirection()` / `turnDirection()` | 调整角色面向 |
| 等待停止 | `player:waitTillStopMoving()` | 等待角色停止移动 |
| 坐骑管理 | `player:mount()` / `dismount()` / `getMount()` | 上/下坐骑 |
| 路点跳过 | bot.lua 主循环 | 战斗中通过向量角度判定跳过已越过路点 |
| 返回路径 | `__RPL` | 独立的返回路径列表 |
| 漫游模式 | `CWaypointListWander` | 在原点周围随机生成路径点 |
| Resume 恢复 | `__WPL:updateResume()` | 记录和恢复中断位置 |

#### 路径点类型

| 类型 | 说明 |
|------|------|
| `NORMAL` | 普通路径点，到达后执行 Action 并继续 |
| `TRAVEL` | 旅行路径点，不在此点附近战斗，快速通过 |
| `RUN` | 奔跑路径点 |

#### 路径配置项

| 配置 | 默认值 | 说明 |
|------|--------|------|
| `WAYPOINTS` | "demo.xml" | 路径点文件 |
| `RETURNPATH` | nil | 返程路径文件 |
| `PATH_TYPE` | "waypoints" | 路径类型：waypoints/wander |
| `WANDER_RADIUS` | 500 | 漫游半径 |
| `WAYPOINT_DEVIATION` | 0 | 路径点偏差（随机偏移） |
| `WAYPOINTS_REVERSE` | false | 反向走路径点 |
| `WAYPOINT_PASS` | 100 | 战斗中跳过路径点的距离 |
| `WAYPOINT_PASS_DEGR` | 90 | 跳过路径点的角度阈值 |

---

### 3.4 拾取与采集系统

**核心文件**：`classes/player.lua`

#### 拾取功能

| 功能 | 实现函数 | 说明 |
|------|---------|------|
| 单体拾取 | `player:loot()` | 拾取指定目标 |
| 批量拾取 | `player:lootAll()` | 拾取附近所有可拾取目标 |
| 附近拾取物查找 | `player:getNearbyLoot()` | 查找附近可拾取的尸体 |
| 拾取评估 | `evalTargetLootable()` | 评估目标是否可拾取 |
| 战斗中拾取 | `LOOT_IN_COMBAT` | 允许战斗中拾取 |
| 印记拾取 | `LOOT_SIGILS` | 拾取印记 |
| 忽略列表 | `LOOT_IGNORE_LIST` | 不拾取的物品列表 |
| 特殊区域强制拾取 | zoneId 369 | 神秘地堡区域强制拾取 |

#### 采集功能

| 功能 | 实现函数 | 说明 |
|------|---------|------|
| 采集执行 | `player:harvest()` | 采集矿石/木材/草药 |
| 采集类型获取 | `player:getCollectingType()` | 获取当前采集类型 |
| 扫描式搜索 | `HARVEST_SCAN_*` | 通过鼠标扫描搜索采集节点 |
| 采集回调 | `onHarvest` 事件 | 采集前触发，返回 false 可跳过 |

#### 采集配置项

| 配置 | 默认值 | 说明 |
|------|--------|------|
| `HARVEST_DISTANCE` | 120 | 采集距离 |
| `HARVEST_WOOD` | true | 采集木材 |
| `HARVEST_HERB` | true | 采集草药 |
| `HARVEST_ORE` | true | 采集矿石 |
| `HARVEST_SCAN_WIDTH` | 5 | 扫描宽度 |
| `HARVEST_SCAN_HEIGHT` | 5 | 扫描高度 |
| `HARVEST_SCAN_STEPSIZE` | 60 | 扫描步长 |
| `HARVEST_TIME` | 45 | 采集超时时间 |

---

### 3.5 物品与背包系统

**核心文件**：`classes/inventory.lua`（1004 行）、`classes/item.lua`（663 行）、`classes/bank.lua`、`classes/equipment.lua`、`classes/guildbank.lua`、`classes/store.lua`、`classes/cursor.lua`

#### 功能清单

| 功能 | 实现类/函数 | 说明 |
|------|------------|------|
| 背包管理 | `CInventory` | 管理 240 个背包槽位，支持分批更新 |
| 物品查找 | `CInventory:findItem()` | 按名称/ID/模式查找物品 |
| 物品计数 | `CInventory:itemTotalCount()` | 统计物品总数 |
| 物品使用 | `CInventory:useItem()` | 使用指定物品 |
| 消耗品选择 | `CInventory:bestAvailableConsumable()` | 选择最佳消耗品 |
| 弹药补充 | `CInventory:reloadAmmunition()` | 补充箭/投掷武器 |
| 银行管理 | `CBank` | 管理 300 个银行槽位 |
| 公会银行 | `CGuildbank` | 管理公会银行（动态分页） |
| 装备管理 | `CEquipment` | 管理 22 个装备槽位 |
| 装备耐久 | `CEquipment:getDurability()` | 获取装备耐久度 |
| 商店管理 | `CStore` | NPC 商店购买、消耗品补充 |
| 光标管理 | `CCursor` | 追踪和管理光标持有的物品 |
| 物品移动 | `CItem:moveTo(bag)` | 在背包/银行/装备/公会银行间移动物品 |
| 物品类型 | `LoadItemTypes()` | 加载物品类型层级表 |
| 自动出售 | `INV_AUTOSELL_*` | 按品质自动出售物品 |
| 物品 Tooltip | `CItem:getGameTooltip()` | 读取物品 Tooltip 信息 |

#### 物品类继承关系

```
CItem (基类)
  ├── CInventoryItem  (背包物品)
  ├── CBankItem       (银行物品)
  ├── CEquipmentItem  (装备物品)
  └── CGuildbankItem  (公会银行物品)
```

---

### 3.6 技能系统

**核心文件**：`classes/skill.lua`（812 行）、`database/skills.xml`、`settings.lua`

#### 功能清单

| 功能 | 实现函数 | 说明 |
|------|---------|------|
| 技能数据库 | `database/skills.xml` | 全职业技能静态数据 |
| 技能加载 | `settings.loadSkillSet()` | 按职业组装技能列表并排序 |
| 技能可用性检查 | `CSkill:canUse()` | 综合检查：冷却、等级、能量、HP/MP%、Buff 需求、目标状态 |
| 技能施放 | `CSkill:use()` | 执行技能释放（面向、距离、施法等待、GCD） |
| 技能更新 | `settings.updateSkillsAvailability()` | 从游戏内存读取技能书数据更新可用性 |
| 技能队列 | `player:queueSkill()` | 技能排队执行 |
| 技能优先级 | `priority` 属性 | 按优先级排序施放 |
| Buff 条件 | `reqbuff` / `nobuff` | 需要/不能有指定 Buff 时才施放 |
| HP 阈值 | `hpper` | 目标 HP 百分比低于阈值才施放 |
| 冷却管理 | `getRemainingCooldown()` | 计算剩余冷却时间 |
| 远程技能检测 | `settings.loadSkillSet()` | 自动检测是否有远程技能 |
| 战斗类型推断 | `settings.loadSkillSet()` | 根据职业推断默认战斗类型 |
| 技能属性 Override | profile XML | 支持覆盖 priority/hpper/cooldown/inbattle/pullonly/maxuse 等 |

#### 技能资源类型常量

| 常量 | 值 | 说明 |
|------|-----|------|
| `SKILLUSES_MANA` | 2 | 法力 |
| `SKILLUSES_RAGE` | 5 | 怒气 |
| `SKILLUSES_FOCUS` | 6 | 专注 |
| `SKILLUSES_ENERGY` | 7 | 能量 |
| `SKILLUSES_ITEM` | 9 | 物品 |
| `SKILLUSES_ARROW` | 14 | 箭矢 |

#### 支持的职业

Warrior（战士）、Scout（侦察者）、Rogue（盗贼）、Mage（法师）、Priest（牧师）、Knight（骑士）、Warden（守卫）、Druid（德鲁伊）、Warlock（术士）、Champion（勇士）

---

### 3.7 宠物系统

**核心文件**：`classes/eggpet.lua`（623 行）、`classes/pet.lua`（223 行）

#### 蛋宠功能

| 功能 | 实现函数 | 说明 |
|------|---------|------|
| 属性读取 | `CEggPet:update()` | 读取等级、经验、忠诚度、饱食度、属性 |
| 喂食 | `CEggPet:feed()` | 喂食宠物（支持 "all"） |
| 召唤/收回 | `CEggPet:Summon()` / `Return()` | 召唤/收回蛋宠 |
| 采集制作 | `CEggPet:craft()` | 蛋宠采集制作（含工具管理） |
| 辅助攻击 | `EGGPET_ENABLE_ASSIST` | 蛋宠辅助攻击 |
| 采集模式 | `EGGPET_ENABLE_CRAFT` | 蛋宠自动采集 |
| 采集比例 | `EGGPET_CRAFT_RATIO` | 采集比例配置（如 1:1:1） |

#### 战斗宠物功能

| 功能 | 实现函数 | 说明 |
|------|---------|------|
| 宠物更新 | `petupdate()` | 更新宠物地址和对象 |
| 宠物攻击 | `petstartcombat()` | 让宠物开始攻击 |
| 自动攻击设置 | `setpetautoattacks()` | 设置宠物自动攻击技能 |
| 仙女管理 | `checkfairy()` | 按职业召唤仙女并管理 Buff |

---

### 3.8 队伍系统

**核心文件**：`classes/party.lua`（617 行）

#### 功能清单

| 功能 | 实现函数 | 说明 |
|------|---------|------|
| 组队主循环 | `Party(heal)` | 组队模式核心（治疗/战斗） |
| 队伍治疗 | `_heal()` | 自动治疗队伍成员 |
| 图标攻击 | `icontarget()` | 查找带 I 图标的怪物并攻击 |
| 队长跟随 | `getNameFollow()` | 跟随指定玩家 |
| 坐骑同步 | `Mount()` | 跟随队长坐骑状态 |
| 队伍检查 | `checkparty()` | 检查队伍成员距离 |
| 聊天监控 | `checkEventParty()` / `eventParty()` | 监控队伍/密语聊天 |
| 发送消息 | `sendPartyChat()` | 发送队伍/密语消息 |
| 获取目标 | `getTarget(name)` | 获取指定玩家的目标 |
| 队长等待 | `PARTYLEADER_WAIT` | 队长等待成员跟上 |

---

### 3.9 死亡与复活系统

**核心文件**：`bot.lua`（resurrect 函数）

#### 功能清单

| 功能 | 实现函数 | 说明 |
|------|---------|------|
| 死亡检测 | `player:updateAlive()` | 检测玩家是否死亡 |
| 复活处理 | `resurrect()` | 释放按键、截图、触发 onDeath |
| 自动复活 | `UseSelfRevive` / `BrithRevive` | 尝试自我复活/回城复活 |
| 死亡计数 | `MAX_DEATHS` | 超过最大死亡次数则登出 |
| 虚弱等待 | `WAIT_TIME_AFTER_RES` | 复活后等待虚弱 debuff 消失 |
| 返回路径选择 | resurrect 内部 | 复活后选择返回路径或普通路径 |
| PK 死亡 | `PK_COUNTS_AS_DEATH` | 被 PK 算作死亡 |
| 死亡截图 | resurrect 内部 | 死亡时自动截图保存 |

---

### 3.10 脱困系统

**核心文件**：`bot.lua`（主循环）、`classes/player.lua`

#### 功能清单

| 功能 | 实现函数 | 说明 |
|------|---------|------|
| 脱困执行 | `player:unstick()` | 尝试脱困（跳跃、转向、后退等） |
| 距离失败计数 | `distBreakCount` | 连续距离失败 >3 次触发脱困 |
| 卡住检测 | `WF_STUCK` | 移动返回卡住状态 |
| 回退 | `WF_PULLBACK` | 回退到之前路点 |
| 脱困计数 | `player.Unstick_counter` | 超过 `MAX_UNSTICK_TRIALS` 触发失败 |
| 脱困失败 | `onUnstickFailure` 事件 | 超限后触发回调 |
| 失败登出 | `LOGOUT_WHEN_STUCK` | 卡住时自动登出 |
| 成功重置 | 路点成功 >3 | 连续成功 3 次重置脱困计数 |

---

### 3.11 NPC 交互与商店系统

**核心文件**：`classes/player.lua`、`classes/store.lua`

#### 功能清单

| 功能 | 实现函数 | 说明 |
|------|---------|------|
| NPC 选中 | `player:target_NPC()` | 选中指定 NPC |
| 对象选中 | `player:target_Object()` | 选中指定游戏对象 |
| 打开商店 | `player:openStore()` | 打开 NPC 商店 |
| 自动修理出售 | `player:merchant()` | 自动修理装备 + 出售物品 |
| 购买物品 | `CStore:buyItem()` | 按名称/ID/索引购买 |
| 购买消耗品 | `CStore:buyConsumable()` | 自动购买最佳消耗品 |
| NPC 扫描 | `player:scan_for_NPC()` | 扫描附近 NPC |
| 生产技能等级 | `player:getCraftLevel()` | 获取生产技能等级 |
| 弹药补充 | `inventory:reloadAmmunition()` | 自动补充弹药 |

---

### 3.12 任务系统

**核心文件**：`functions.lua`

#### 功能清单

| 功能 | 实现函数 | 说明 |
|------|---------|------|
| 按名称接受任务 | `AcceptQuestByName()` | 接受指定名称的任务 |
| 按名称完成任务 | `CompleteQuestByName()` | 完成指定名称的任务 |
| 批量接受 | `AcceptAllQuests()` | 接受所有可用任务 |
| 批量完成 | `CompleteAllQuests()` | 完成所有可完成任务 |
| 取消任务 | `CancelQuest()` | 取消指定任务 |
| 任务状态查询 | `getQuestStatus()` | 查询任务当前状态 |
| 选项选择 | `ChoiceOptionByName()` | 按名称选择任务选项 |
| 任务 ID 扫描 | `createpath.lua: scanQuestIds()` | 对比任务日志变化识别任务 ID |

---

### 3.13 休息与睡眠系统

**核心文件**：`classes/player.lua`

#### 功能清单

| 功能 | 实现函数 | 说明 |
|------|---------|------|
| 休息恢复 | `player:rest()` | HP/MP 低于阈值时坐下休息 |
| 随机休息 | `player:restrnd()` | 随机化休息行为 |
| 睡眠模式 | `player:sleep()` | 睡眠但仍反击 |
| HP 休息阈值 | `HP_REST` | HP 低于此值休息 |
| MP 休息阈值 | `MP_REST` | MP 低于此值休息 |
| 药水使用 | `player:checkPotions()` | HP/MP 低时使用药水 |
| 药水冷却 | `POTION_COOLDOWN` | 药水冷却时间 |
| 最佳药水选择 | `USE_HP_POTION` / `USE_MANA_POTION` | best/minstack 策略 |

---

### 3.14 事件与回调系统

**核心文件**：`settings.lua`、`bot.lua`

#### Profile 事件回调

| 事件名 | 触发时机 | 用途 |
|--------|---------|------|
| `onLoad` | Profile 加载完成后 | 初始化自定义设置 |
| `onDeath` | 玩家死亡时 | 自定义死亡处理 |
| `onLevelup` | 升级时 | 升级后自定义行为 |
| `onLeaveCombat` | 离开战斗时 | 战斗后自定义处理 |
| `onPreSkillCast` | 施法前 | 可中断施法（返回值控制） |
| `onSkillCast` | 施法后 | 施法后自定义处理 |
| `onHarvest` | 采集时 | 采集前自定义判断（返回 false 跳过） |
| `onUnstickFailure` | 脱困失败时 | 卡住失败自定义处理 |
| `preCodeOnElite` | 遭遇精英怪前 | 精英怪应对策略 |

#### 路径点 Action

每个路径点可携带 Lua 代码，到达时通过 `loadstring` 编译执行。

#### 路径 onLoad 事件

路径文件可定义 `onLoad` 脚本，在路径加载时执行。

#### 定时器

| 定时器 | 间隔 | 功能 |
|--------|------|------|
| `checkClientCrash` | 2 秒 | 检测游戏客户端崩溃 |
| `collectgarbage` | 60 秒 | Lua 垃圾回收 |
| `timedSetWindowName` | 定时 | 更新窗口标题（经验率等） |

#### 游戏事件监控

通过 `igf_events` 游戏内插件实现，支持 `EventMonitorStart/Stop/Pause/Resume/Check`。

---

### 3.15 配置系统

**核心文件**：`settings.lua`（1399 行）、`settings.xml`、`profiles/*.xml`

#### 配置层次

```
settings_default (Lua 默认值)
    ↓ table.copy
settings (运行时全局配置) ← settings.xml 覆盖
    ↓
settings.profile (角色配置) ← profiles/<name>.xml 覆盖
    ↓
settings.profile.skills (技能列表) ← settings.loadSkillSet() 合并+排序
    ↓
settings.profile.skills[*].Available ← settings.updateSkillsAvailability() 从内存更新
```

#### 全局配置（settings.xml）

| 类别 | 配置项 |
|------|--------|
| 热键 | MOVE_FORWARD/BACKWARD、ROTATE_LEFT/RIGHT、STRAFF_LEFT/RIGHT、JUMP、TARGET、START_BOT、STOP_BOT 等 |
| 全局选项 | LANGUAGE、USE_CLIENT_LANGUAGE、DEBUGGING、MELEE_DISTANCE、TARGET_FRAME 等 |

#### Profile 配置（profiles/*.xml）

| 类别 | 主要配置项 |
|------|-----------|
| 战斗 | COMBAT_TYPE、COMBAT_DISTANCE、MAX_FIGHT_TIME、ANTI_KS、AUTO_TARGET、AUTO_ELITE_FACTOR |
| 生存 | HP_LOW、HP_REST、MP_REST、USE_HP_POTION、USE_MANA_POTION、POTION_COOLDOWN |
| 路径 | WAYPOINTS、RETURNPATH、PATH_TYPE、WANDER_RADIUS、WAYPOINTS_REVERSE |
| 拾取 | LOOT、LOOT_ALL、LOOT_IN_COMBAT、LOOT_DISTANCE、LOOT_SIGILS |
| 采集 | HARVEST_DISTANCE、HARVEST_WOOD/HERB/ORE |
| 背包 | INV_UPDATE_INTERVAL、INV_AUTOSELL_ENABLE/FROMSLOT/TOSLOT/QUALITY |
| 购物 | HEALING_POTION、MANA_POTION、ARROW_QUIVER、THROWN_BAG、RELOAD_AMMUNITION |
| 蛋宠 | EGGPET_ENABLE_CRAFT/ASSIST、EGGPET_CRAFT_RATIO |
| 登出 | LOGOUT_TIME、LOGOUT_SHUTDOWN、LOGOUT_WHEN_STUCK、MAX_UNSTICK_TRIALS |
| 死亡 | RES_AFTER_DEATH、MAX_DEATHS、WAIT_TIME_AFTER_RES |
| 组队 | PARTY、PARTY_ICONS、PARTY_INSTANCE、ICON_FIGHT、PARTY_FOLLOW_NAME |
| 技能 | 10 个职业的技能配置（name + hotkey + priority + 条件参数） |
| 事件 | onLoad、onDeath、onLevelup、onLeaveCombat、onPreSkillCast、onSkillCast、onHarvest、onUnstickFailure、preCodeOnElite |
| 名单 | friends（友方列表）、mobs（怪物白名单） |

#### 游戏键位加载

自动从游戏 `bindings.txt` 读取键位绑定，支持 12 种语言的文档路径探测。

---

### 3.16 内存与地址系统

**核心文件**：`addresses.lua`（392 行）、`classes/memdatabase.lua`（244 行）、`classes/codemod.lua`（92 行）

#### 功能清单

| 功能 | 实现文件/函数 | 说明 |
|------|-------------|------|
| 内存地址定义 | `addresses.lua` | 定义所有游戏内存偏移量（玩家、相机、物品、技能等） |
| 内存读取 | `functions.lua: memoryReadRepeat()` | 核心内存读取函数，支持多种数据类型，失败自动重试 |
| 进程附加 | `functions.lua: getWin()` / `getProc()` | 获取游戏窗口和进程句柄 |
| 基址计算 | `functions.lua: getBaseAddress()` | 动态计算 Client.exe 模块基址 |
| 内存数据库 | `CMemDatabase` | 物品 ID → 内存地址映射，支持分支预测缓存 |
| 物品地址查询 | `GetItemAddress(id)` | 获取物品 ID 对应的内存地址 |
| 物品名称查询 | `GetIdName(itemId)` | 带缓存的物品名称查询 |
| 代码修改 | `CCodeMod` | 通过写入游戏内存替换指令字节实现 hack |
| 地址验证 | `addrtest.lua` | 系统性测试所有内存地址是否正确 |
| 地址更新 | `addrupdate.lua` | 游戏更新后自动扫描重新定位地址 |
| 掉线数据保存 | `MemDatabase:flush()` | 掉线时清空缓存 |

#### 地址覆盖范围

- 游戏全局状态（game_time、in_game、zone_id、loading）
- 玩家/怪物/NPC 属性（坐标、HP/MP、等级、职业、Buff、目标、坐骑、游泳等）
- 相机（位置、焦点、距离）
- 输入控制
- 宏系统（名称、图标、内容、ID）
- 快捷键列表
- 技能/技能书/冷却
- 物品/装备/背包/银行/光标
- 游戏对象列表
- 队伍信息
- 宠物蛋系统
- 代码修改补丁（freeze_target、freeze_mousepos、swimhack）

---

### 3.17 游戏通信系统

**核心文件**：`macros.lua`（250+ 行）、`functions.lua`

#### 通信机制

机器人通过"命令宏 → 触发执行 → 结果宏"的方式与游戏通信：

1. `writeToMacro(命令宏, Lua代码)` — 写入命令宏内容
2. `keyboardPress(MACRO快捷键)` — 触发游戏执行宏
3. `readMacro(结果宏)` — 读取游戏写入的结果
4. 解析返回值

#### 功能清单

| 功能 | 实现函数 | 说明 |
|------|---------|------|
| 宏设置 | `setupMacros()` | 创建/查找命令宏和结果宏，绑定快捷键 |
| 写入宏 | `writeToMacro()` | 直接写内存修改宏内容 |
| 读取宏 | `readMacro()` | 逐字节读取宏内容 |
| 查找宏 | `searchForMacro()` / `findMacroByName()` | 搜索游戏内宏 |
| 执行游戏脚本 | `RoMScript()` | 通过宏执行游戏内 Lua 脚本 |
| 执行游戏代码 | `RoMCode()` | 执行代码并返回值 |
| 斜杠命令 | `SlashCommand()` | 执行游戏斜杠命令 |
| 快捷栏管理 | `setActionKeyToMacro()` / `setActionKeyToId()` | 设置快捷栏槽位 |
| 长消息分片 | RoMScript 内部 | 超过 254 字符自动分片发送 |

#### 限制

- 宏最大长度：255 字符
- 通信是同步互斥的（一次只能执行一个宏命令）

---

### 3.18 多语言国际化系统

**核心文件**：`language/` 目录（6 种语言）

| 语言 | 文件 | 说明 |
|------|------|------|
| 英语 | `english.lua` | 基准语言，240+ 条消息 |
| 德语 | `deutsch.lua` | 完整翻译 |
| 法语 | `french.lua` | 完整翻译 |
| 波兰语 | `polish.lua` | 完整翻译 |
| 葡萄牙语 | `portuguese.lua` | 完整翻译 |
| 俄语 | `russian.lua` | 使用 OEM 编码（Code page 866） |

#### 加载策略

1. 先加载 `english.lua` 填充所有语言键
2. 再加载用户指定语言覆盖
3. `USE_CLIENT_LANGUAGE=true` 时自动检测游戏客户端语言并切换

#### 编码转换

| 函数 | 说明 |
|------|------|
| `utf82oem_russian()` / `oem2utf8_russian()` | 俄语 OEM ↔ UTF-8 转换 |
| `convert_utf8_ascii()` | UTF-8 → ASCII 通用转换 |
| `utf8ToAscii_umlauts()` / `asciiToUtf8_umlauts()` | 德语变音符号转换 |

---

### 3.19 更新与维护系统

**核心文件**：`update.lua`、`gitupdate.lua`、`svnupdate.lua`、`rombot_updater.exe`

| 功能 | 实现文件 | 说明 |
|------|---------|------|
| 自动更新工具 | `rombot_updater.exe` + `update.lua` | 一键更新所有文件 |
| Git 更新 | `gitupdate.lua` | 通过 Git 从 GitHub 仓库更新，支持备份、分支切换 |
| SVN 更新 | `svnupdate.lua` | 已废弃，自动转至 gitupdate |
| 启动时检查 | `bot.lua` | 每 10 分钟检查一次 Git 更新可用性 |
| 地址更新 | `addrupdate.lua` | 游戏更新后自动扫描重新定位内存地址 |

---

## 4. 用户扩展功能

### 4.1 userfunctions/ 目录

`bot.lua` 启动时自动扫描此目录，加载 `addon_*.lua` 和 `userfunction_*.lua` 文件。

| 文件 | 功能 | 作者 |
|------|------|------|
| `addon_Rock5s_Mail_Functions.lua` | 邮件功能扩展：设置发送槽位范围、查找邮箱、标记待发送物品、切换 UMM 标签页 | Rock5 |
| `userfunction_30daymounts.lua` | 30 天坐骑自动合成与上马：检查材料 → 合成 → 使用 | Noobbotter |
| `userfunction_countmobs.lua` | 怪物/玩家计数：`CountMobs()` 计算周围怪物，`CountPlayers()` 计算周围玩家 | Rock5 |
| `userfunction_Fusion_Functions.lua` | 融合石制作自动化：计算购买数量、修改融合配置 | Rock5 |
| `userfunction_objectdump.lua` | 对象内存转储：将对象地址开始的 4096 字节以十六进制转储到文件 | - |
| `userfunction_speedhack.lua` | 速度修改：修改玩家和坐骑的基础移动速度（默认 +19%） | Tsutomu 等 |
| `userfunction_swimhack.lua` | 游泳/飞行 hack：通过代码补丁修改游泳状态实现飞行 | - |
| `userfunction_telefollow.lua` | 传送到目标：计算方向距离后传送并面向目标 | - |
| `userfunction_teleport.lua` | 传送功能：支持绝对/相对坐标传送，超距分步传送防检测 | Rock5 |

### 4.2 Profile 事件回调

用户可在 Profile XML 中定义 Lua 代码块作为事件回调（详见 [3.14 事件与回调系统](#314-事件与回调系统)）。

### 4.3 路径点 Action

每个路径点可携带 Lua 代码，到达时自动执行。用户可在路径点中编写任意自定义逻辑。

---

## 5. 开发工具

### 5.1 路径录制工具

**文件**：`createpath.lua`

交互式创建 waypoint XML 文件，支持小键盘快捷键操作：

| 快捷键 | 功能 |
|--------|------|
| NUMPAD1 | 添加移动路径点 |
| NUMPAD2 | 添加采集路径点 |
| NUMPAD3 | 保存路径文件 |
| NUMPAD4 | 添加商人路径点 |
| NUMPAD5 | 添加 NPC 对话路径点 |
| NUMPAD6 | 按名称接受/完成任务 |
| NUMPAD7 | 添加鼠标点击路径点 |
| NUMPAD8 | 重置路径 |
| NUMPAD9 | 重启录制 |
| NUMPAD0 | 添加代码注释 |
| DECIMAL | 添加目标对象路径点 |
| DIVIDE | 改变路径点类型 |
| ADD | 切换飞行模式 |

### 5.2 调试工具

| 工具 | 文件 | 功能 |
|------|------|------|
| 对象 ID 显示 | `getid.lua` | 实时显示玩家/目标/鼠标悬停对象的地址和 ID |
| 位置显示 | `getpos.lua` | 实时显示玩家 XYZ 坐标 |
| 鼠标位置 | `mousepos.lua` | 显示鼠标相对游戏窗口的坐标 |
| 地址测试 | `addrtest.lua` | 系统性测试所有内存地址，输出诊断报告 |
| 地址更新 | `addrupdate.lua` | 游戏更新后自动扫描重新定位地址 |
| 对象转储 | `userfunction_objectdump.lua` | 将对象内存以十六进制转储到文件 |

### 5.3 游戏内插件（devtools/）

需安装到游戏 `Interface/AddOns/` 目录：

| 插件 | 功能 | 与机器人的关系 |
|------|------|---------------|
| **ingamefunctions** | 提供游戏内 Lua 函数：Tooltip 读取、物品链接解析、背包数据、任务状态查询、事件监控 | **必需插件**（版本 ≥ 11） |
| **UltimateMailMod** | 终极邮箱系统：批量发送物品、收件人管理、收件箱查看 | 邮件功能依赖（可选） |
| **TooltipIds** | 在游戏 Tooltip 中显示对象 ID（单位/物品/技能/Buff/称号/商城/商店/公会/任务） | 辅助开发（可选） |
| **#d303Fix** | 修复游戏时间同步和截图功能 | 辅助修复（可选） |

### 5.4 批处理脚本

| 脚本 | 功能 |
|------|------|
| `startbot.bat` | 启动机器人 |
| `StartCommandLine.bat` | 命令行启动 |
| `createpath.bat` | 启动路径录制 |
| `fixaddresses.bat` | 修复地址 |
| `Get_Object_Id.bat` | 获取对象 ID |
| `Get_Player_Position.bat` | 获取玩家位置 |

---

## 6. 数据库与静态资源

### 6.1 数据库文件（database/）

| 文件 | 格式 | 内容 | 用途 |
|------|------|------|------|
| `skills.xml` | XML | 全职业技能数据（10 职业 + 精英技能），含 range/casttime/cooldown/type/target/buff 条件 | 技能系统核心数据 |
| `nodes.xml` | XML | 资源点数据（矿石/木材/草药 + 稀有节点） | 采集系统 |
| `consumables.xml` | XML | 消耗品数据（治疗/法力药水 + 弹药），含 type/level/potency | 药水系统 |
| `giftbags.xml` | XML | 礼包数据（1-25+ 级，含种族包/装备包/坐骑） | 新角色自动开包 |
| `utf8_ascii.xml` | XML | UTF-8 → ASCII 字符映射表 | 编码转换 |
| `mounts.lua` | Lua | 100+ 种坐骑 ID 列表 | 坐骑识别 |

### 6.2 路径文件（waypoints/）

共 82 个 XML 文件 + 3 个 Lua 辅助文件：

| 类别 | 数量 | 说明 |
|------|------|------|
| 演示路径 | 6 | demo.xml 等基础示例 |
| 训练场景 | 4 | AndorTraining、WepTraining 等 |
| 副本/生存 | 2 | survivalR5、RBAssist |
| 组队路径 | 2 | partydps、partyhealer |
| 1-10 级拓荒者 | 16 | 1-10Pioneers/ 目录 |
| 1-10 级拓荒者含任务 | 22 | 1-10PioneersQuests/ 目录 |
| 1-10 级拓荒者含任务（熊变体） | 22 | 1-10PioneersQuests_Bear/ 目录 |
| 其他/测试 | 8 | 各种测试和角色路径 |

### 6.3 Profile 模板（profiles/）

| 文件 | 说明 |
|------|------|
| `Default.xml` | 默认配置模板（292 行），包含完整配置选项和全职业技能 |
| `l1-10.xml` | 1-10 级新角色配置 |

### 6.4 缓存目录（cache/）

| 文件 | 说明 |
|------|------|
| `texts.lua` | 缓存游戏内文本字符串 |
| `updatecheck.txt` | 上次更新检查时间 |
| `branch_predictions.lua` | 内存数据库分支预测缓存 |
| `itemtypestable.lua` | 物品类型表缓存 |

---

## 7. 类继承关系

```
CPawn (pawn.lua) — 游戏角色实体基类
  └── CPlayer (player.lua) — 玩家角色控制类

CItem (item.lua) — 物品基类
  ├── CInventoryItem (inventoryitem.lua) — 背包物品
  ├── CBankItem (bankitem.lua) — 银行物品
  ├── CEquipmentItem (equipmentitem.lua) — 装备物品
  └── CGuildbankItem (guildbankitem.lua) — 公会银行物品

CWaypointList (waypointlist.lua) — 路径点列表
  └── CWaypointListWander (waypointlist_wander.lua) — 漫游模式路径

独立类:
  CWaypoint     — 路径点数据
  CNode         — 采集节点数据
  CSkill        — 技能数据与使用逻辑
  CInventory    — 背包管理器
  CBank         — 银行管理器
  CEquipment    — 装备管理器
  CGuildbank    — 公会银行管理器
  CStore        — 商店管理器
  CCursor       — 光标物品管理器
  CCamera       — 游戏相机控制
  CCodeMod      — 游戏代码修改/补丁
  CMemDatabase  — 游戏内存数据库
  CEggPet       — 蛋宠管理
  CObject       — 游戏对象（轻量版）
  CObjectList   — 游戏对象列表

函数模块（非类）:
  pet.lua       — 战斗宠物管理
  party.lua     — 队伍系统
  itemtypes.lua — 物品类型表
  memorytable.lua — ID→名称映射缓存
```

---

## 8. 文件目录结构总览

```
rom-bot-master/
├── bot.lua                    # 主入口/主循环（1227 行）
├── settings.lua               # 配置定义与加载（1399 行）
├── functions.lua              # 通用函数库（3183 行，最大文件）
├── addresses.lua              # 内存地址定义表（392 行）
├── database.lua               # 数据库加载器（276 行）
├── macros.lua                 # 宏系统管理（250+ 行）
├── qword.lua                  # 64 位数值编码/解码（86 行）
├── update.lua                 # 自动更新（33 行）
├── gitupdate.lua              # Git 更新（100+ 行）
├── svnupdate.lua              # SVN 更新（已废弃，4 行）
├── addrtest.lua               # 地址验证诊断（250+ 行）
├── addrupdate.lua             # 地址自动更新（200+ 行）
├── createpath.lua             # 路径录制工具（200+ 行）
├── getid.lua                  # 对象 ID 显示（59 行）
├── getpos.lua                 # 位置显示（49 行）
├── mousepos.lua               # 鼠标位置显示（16 行）
├── settings.xml               # 全局配置文件
├── license.txt                # 许可证
├── readme.md                  # 项目说明
├── rombot_updater.exe         # 自动更新工具
│
├── classes/                   # OOP 类定义（28 个文件）
│   ├── player.lua             # CPlayer（~4163 行，核心）
│   ├── pawn.lua               # CPawn（1084 行，基类）
│   ├── skill.lua              # CSkill（812 行）
│   ├── inventory.lua          # CInventory（1004 行）
│   ├── item.lua               # CItem（663 行）
│   ├── eggpet.lua             # CEggPet（623 行）
│   ├── party.lua              # 队伍系统（617 行）
│   ├── waypointlist.lua       # CWaypointList（458 行）
│   ├── pet.lua                # 战斗宠物（223 行）
│   ├── memdatabase.lua        # CMemDatabase（244 行）
│   ├── store.lua              # CStore（169 行）
│   ├── inventoryitem.lua      # CInventoryItem（159 行）
│   ├── itemtypes.lua          # 物品类型（160 行）
│   ├── guildbank.lua          # CGuildbank（183 行）
│   ├── camera.lua             # CCamera（104 行）
│   ├── bank.lua               # CBank（105 行）
│   ├── equipment.lua          # CEquipment（98 行）
│   ├── object.lua             # CObject（93 行）
│   ├── codemod.lua            # CCodeMod（92 行）
│   ├── cursor.lua             # CCursor（85 行）
│   ├── guildbankitem.lua      # CGuildbankItem（62 行）
│   ├── equipmentitem.lua      # CEquipmentItem（65 行）
│   ├── bankitem.lua           # CBankItem（70 行）
│   ├── waypointlist_wander.lua # CWaypointListWander（35 行）
│   ├── waypoint.lua           # CWaypoint（35 行）
│   ├── objectlist.lua         # CObjectList（35 行）
│   ├── node.lua               # CNode（18 行）
│   └── memorytable.lua        # ID→名称映射（95 行）
│
├── userfunctions/             # 用户自定义功能（9 个脚本）
│   ├── addon_Rock5s_Mail_Functions.lua
│   ├── userfunction_30daymounts.lua
│   ├── userfunction_countmobs.lua
│   ├── userfunction_Fusion_Functions.lua
│   ├── userfunction_objectdump.lua
│   ├── userfunction_speedhack.lua
│   ├── userfunction_swimhack.lua
│   ├── userfunction_telefollow.lua
│   └── userfunction_teleport.lua
│
├── waypoints/                 # 路径文件（82 XML + 3 Lua）
│   ├── *.xml                  # 各类路径文件
│   ├── 1-10Pioneers/          # 1-10 级拓荒者路径
│   ├── 1-10PioneersQuests/    # 含任务的拓荒者路径
│   ├── 1-10PioneersQuests_Bear/ # 熊变体
│   ├── AndorTraining_onload.lua
│   ├── survivalR5onload.lua
│   └── invaders_functions.lua
│
├── devtools/                  # 游戏内插件
│   ├── ingamefunctions/       # 游戏内函数插件（必需）
│   ├── UltimateMailMod/       # 终极邮箱插件（可选）
│   ├── TooltipIds/            # ID 显示插件（可选）
│   └── #d303Fix/              # 时间修复插件（可选）
│
├── database/                  # 静态数据
│   ├── skills.xml             # 技能数据库
│   ├── nodes.xml              # 资源点数据库
│   ├── consumables.xml        # 消耗品数据库
│   ├── giftbags.xml           # 礼包数据库
│   ├── utf8_ascii.xml         # 编码映射表
│   └── mounts.lua             # 坐骑 ID 列表
│
├── language/                  # 多语言支持
│   ├── english.lua            # 英语（基准）
│   ├── deutsch.lua            # 德语
│   ├── french.lua             # 法语
│   ├── polish.lua             # 波兰语
│   ├── portuguese.lua         # 葡萄牙语
│   └── russian.lua            # 俄语
│
├── profiles/                  # 角色配置模板
│   ├── Default.xml            # 默认模板
│   └── l1-10.xml              # 1-10 级配置
│
├── bin/                       # 二进制工具
│   └── mdbrute.exe            # 内存数据库暴力工具
│
├── cache/                     # 运行时缓存
├── logs/                      # 运行时日志
├── objdump/                   # 对象内存转储
└── *.bat                      # 批处理启动脚本
```

---

## 总结

RoM-Bot 是一个功能完备的 Runes of Magic 游戏自动化机器人，涵盖 **19 个核心子系统**，从战斗、移动、拾取到队伍、宠物、任务，几乎覆盖了游戏的所有日常操作。项目采用 Lua 面向对象设计，通过内存读取获取游戏状态，通过宏系统执行游戏内操作，具有高度的可配置性和可扩展性。用户可通过 Profile XML 配置行为参数、通过事件回调自定义逻辑、通过 userfunctions 目录扩展功能、通过路径文件定义行走路线，形成完整的自动化游戏体验。
