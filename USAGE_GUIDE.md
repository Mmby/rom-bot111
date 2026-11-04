# RoM-Bot 使用指南

> **项目**：RoM-Bot — Runes of Magic 游戏自动化机器人  
> **版本**：4.1  
> **许可**：MIT License  
> **适用人群**：有一定技术基础、愿意深入配置代码的玩家  
> **运行环境**：Windows + MicroMacro 脚本引擎 + Runes of Magic 游戏客户端

---

## 目录

- [1. 环境准备](#1-环境准备)
- [2. 安装步骤](#2-安装步骤)
- [3. 配置角色 Profile](#3-配置角色-profile)
- [4. 创建路径文件](#4-创建路径文件)
- [5. 启动机器人](#5-启动机器人)
- [6. 运行时操作](#6-运行时操作)
- [7. Profile 配置详解](#7-profile-配置详解)
- [8. 技能配置详解](#8-技能配置详解)
- [9. 事件回调详解](#9-事件回调详解)
- [10. 路径文件详解](#10-路径文件详解)
- [11. 游戏内插件安装](#11-游戏内插件安装)
- [12. 辅助工具使用](#12-辅助工具使用)
- [13. 用户自定义函数](#13-用户自定义函数)
- [14. 更新与维护](#14-更新与维护)
- [15. 常见问题排查](#15-常见问题排查)

---

## 1. 环境准备

### 1.1 必需软件

| 软件 | 说明 | 下载地址 |
|------|------|----------|
| **MicroMacro** | 脚本引擎，机器人的运行宿主 | [solarstrike.net](https://solarstrike.net/project/micromacro) |
| **Runes of Magic** | 游戏客户端 | Gameforge 官方 |
| **Git**（可选） | 用于代码更新 | [git-scm.com](https://git-scm.com) |

### 1.2 MicroMacro 版本要求

- 机器人要求 MicroMacro 版本 **≤ 1.05**
- 启动时会自动校验，版本不兼容会报错退出

### 1.3 游戏客户端要求

- 需要 64 位或 32 位的 Runes of Magic 客户端（均支持）
- 机器人通过内存读取与游戏交互，需要以**窗口模式**运行游戏
- 建议分辨率 1280×720 或更高

---

## 2. 安装步骤

### 步骤 1：安装 MicroMacro

下载并解压 MicroMacro 到任意目录，例如：

```
C:\MicroMacro\
├── micromacro.exe
├── scripts\          ← 机器人脚本放在这里
└── ...
```

### 步骤 2：放置 RoM-Bot 脚本

将 RoM-Bot 项目文件解压（或 git clone）到 MicroMacro 的 `scripts` 目录下：

```
C:\MicroMacro\scripts\rom-bot\
├── bot.lua            ← 主入口
├── settings.lua
├── settings.xml       ← 全局设置
├── functions.lua
├── classes\
├── database\
├── waypoints\
├── profiles\
├── ...
└── readme.md
```

> **验证**：确认存在 `scripts/rom-bot/readme.md` 即表示路径正确。

### 步骤 3：安装游戏内插件

将 `scripts/rom-bot/devtools/` 目录下的文件夹复制到游戏的 AddOns 目录：

```
<游戏安装目录>\interface\addons\
├── ingamefunctions\     ← 必需！事件监控、tooltip 读取、任务状态
├── UltimateMailMod\      ← 可选，邮件批量发送
├── TooltipIds\           ← 可选，显示对象 ID（辅助开发）
└── #d303Fix\             ← 可选，修复游戏时间/截图问题
```

> **注意**：如果 `interface` 或 `addons` 目录不存在，需手动创建。  
> 示例完整路径：`C:\Program Files (x86)\GameforgeClient\Games\RunesOfMagic\interface\addons\`

### 步骤 4：首次启动测试

1. 启动 Runes of Magic 游戏，登录角色
2. 打开 MicroMacro（`micromacro.exe`）
3. 在 MicroMacro 控制台输入：

```
rom-bot/bot
```

如果一切正常，机器人会启动并提示选择路径文件。此时说明环境配置成功。

---

## 3. 配置角色 Profile

### 3.1 创建 Profile 文件

1. 进入 `profiles/` 目录
2. 复制 `Default.xml`，以你的角色名命名

```
profiles/
├── Default.xml      ← 模板（不要直接修改）
└── Bob.xml          ← 你的角色配置（角色名 "Bob"）
```

> **命名规则**：Profile 文件名必须与角色名一致（大小写不敏感，机器人会自动匹配）。  
> 如果角色名含特殊字符，参考 `convertProfileName()` 的转换规则。

### 3.2 最简配置示例

以下是一个法师角色的最小化配置：

```xml
<?xml version="1.0" encoding="utf-8"?>
<profile>
    <options>
        <option name="HP_LOW"              value="85" />
        <option name="MP_LOW_POTION"       value="50" />
        <option name="HP_LOW_POTION"       value="50" />
        <option name="COMBAT_TYPE"         value="ranged" />
        <option name="COMBAT_DISTANCE"     value="200" />
        <option name="LOOT"                value="true" />
        <option name="WAYPOINTS"           value="demo.xml" />
        <option name="PATH_TYPE"           value="waypoints" />
        <option name="RES_AFTER_DEATH"     value="true" />
        <option name="MAX_DEATHS"          value="10" />
    </options>

    <hotkeys>
        <hotkey name="MACRO" key="VK_0" />
    </hotkeys>

    <skills_mage>
        <skill name="MAGE_FIREBALL"    hotkey="MACRO" priority="90" />
        <skill name="MAGE_LIGHTNING"   hotkey="MACRO" priority="80" />
        <skill name="MAGE_FLAME"       hotkey="MACRO" priority="70" />
    </skills_mage>
</profile>
```

### 3.3 关键配置项速查

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `WAYPOINTS` | `""` | 路径文件名，留空则启动时交互选择 |
| `PATH_TYPE` | `waypoints` | 路径模式：`waypoints`（路径点）或 `wander`（漫游） |
| `WANDER_RADIUS` | `500` | 漫游模式下的活动半径 |
| `COMBAT_TYPE` | `""` | 战斗类型：`melee`（近战）/ `ranged`（远程）/ 留空自动判断 |
| `COMBAT_DISTANCE` | `200` | 开始使用技能的距离 |
| `LOOT` | `true` | 是否拾取战利品 |
| `HP_LOW` | `85` | HP 低于此百分比时治疗 |
| `HP_REST` | `15` | HP 低于此百分比时休息恢复 |
| `MP_REST` | `15` | MP 低于此百分比时休息恢复 |
| `MAX_DEATHS` | `10` | 最大死亡次数，超过后自动登出 |
| `RES_AFTER_DEATH` | `true` | 死亡后是否自动复活 |
| `LOGOUT_WHEN_STUCK` | `true` | 卡住时是否登出 |
| `ANTI_KS` | `true` | 防止抢杀（不攻击已被他人攻击的怪） |

> **完整配置项**：参见 `profiles/Default.xml` 中的注释，或上一节 `PROJECT_ANALYSIS.md` 第 3.15 节。

---

## 4. 创建路径文件

路径文件定义机器人在游戏中行走的路线。有两种方式创建：

### 4.1 使用路径录制工具（推荐）

1. 确保 MicroMacro 和游戏都已启动
2. 在 MicroMacro 控制台输入：

```
rom-bot/createpath
```

或直接运行批处理：

```bat
scripts\rom-bot\createpath.bat
```

3. 在游戏中走到你想要的路径起点
4. 使用小键盘快捷键录制路径点：

| 按键 | 功能 |
|------|------|
| **NUMPAD 1** | 添加普通移动路径点 |
| **NUMPAD 2** | 添加采集路径点 |
| **NUMPAD 3** | 保存路径文件（提示输入文件名） |
| **NUMPAD 4** | 添加商人/NPC 交互点 |
| **NUMPAD 5** | 添加 NPC 对话点 |
| **NUMPAD 6** | 按名称接受/完成任务 |
| **NUMPAD 7** | 鼠标点击记录 |
| **NUMPAD 8** | 重置路径 |
| **NUMPAD 9** | 重启录制 |
| **NUMPAD 0** | 添加 Lua 代码注释 |
| **NUMPAD .** | 记录目标对象 |
| **NUMPAD /** | 改变路径点类型 |
| **NUMPAD +** | 切换飞行模式 |

5. 按 **NUMPAD 3** 保存，输入文件名（如 `MyGrindingRoute`），文件将保存到 `waypoints/MyGrindingRoute.xml`

### 4.2 手动编写路径文件

路径文件是 XML 格式，存放在 `waypoints/` 目录：

```xml
<waypoints>
    <!-- # 1 --><waypoint x="-4056" z="-8290">player:sleep();</waypoint>
    <!-- # 2 --><waypoint x="-3777" z="-8488"></waypoint>
    <!-- # 3 --><waypoint x="-3699" z="-8674" type="TRAVEL">player:merchant();</waypoint>
    <!-- # 4 --><waypoint x="-3796" z="-8523"></waypoint>
</waypoints>
```

**字段说明**：

| 字段 | 说明 |
|------|------|
| `x`, `z` | 游戏坐标（Y 坐标自动从内存读取，无需指定） |
| `type` | 路径点类型：留空=普通战斗点，`TRAVEL`=途经点（不在此战斗） |
| 标签内容 | 到达该点时执行的 Lua 代码 |

**常用路径点代码示例**：

```lua
-- 休息等待
player:sleep();

-- 与商人交互（自动修理和出售）
player:merchant();

-- 加载另一条路径
loadPaths("MyNextRoute");

-- 打印信息
print("到达检查点");

-- 检查库存并决定是否回城
if inventory:itemTotalCount(12345) > 10 then
    loadPaths("ReturnToTown");
end
```

### 4.3 使用漫游模式

如果不想创建路径文件，可以使用漫游模式：

1. 在 Profile 中设置：
```xml
<option name="PATH_TYPE" value="wander" />
<option name="WANDER_RADIUS" value="500" />
```

2. 机器人会在角色当前位置周围 500 单位半径内随机游走并攻击怪物

---

## 5. 启动机器人

### 5.1 方式一：通过 MicroMacro 控制台

1. 启动游戏并登录角色
2. 打开 MicroMacro
3. 输入命令：

```
rom-bot/bot
```

### 5.2 方式二：通过批处理文件

```bat
:: 方式 A：标准启动（交互选择路径）
scripts\rom-bot\startbot.bat

:: 方式 B：命令行模式（使用 Profile 中配置的路径）
scripts\rom-bot\StartCommandLine.bat
```

### 5.3 方式三：带参数启动

在 MicroMacro 控制台中可以附加参数：

```
rom-bot/bot debug              :: 调试模式，输出详细信息
rom-bot/bot profile:Bob        :: 强制使用指定 Profile
rom-bot/bot path:demo          :: 强制使用指定路径文件
rom-bot/bot retpath:demo_return :: 强制使用指定返回路径
rom-bot/bot character:Bob      :: 附加到指定角色窗口（多开时）
rom-bot/bot update             :: 执行更新
```

参数可以组合使用：

```
rom-bot/bot debug profile:Bob path:MyRoute
```

### 5.4 启动流程

机器人启动后会依次执行：

```
1. 版本检查 → 2. 加载数据库 → 3. 附加游戏窗口 → 4. 加载 Profile
→ 5. 选择/加载路径文件 → 6. 初始化游戏对象 → 7. 开始主循环
```

如果 `WAYPOINTS` 配置为空，启动时会列出 `waypoints/` 目录下所有可用文件供你选择。

---

## 6. 运行时操作

### 6.1 热键控制

| 热键 | 默认按键 | 功能 |
|------|----------|------|
| **START_BOT** | `DELETE` | 启动/暂停机器人主循环 |
| **STOP_BOT** | `END` | 停止机器人并退出 |

> 热键可在 `settings.xml` 中修改。

### 6.2 游戏内设置要求

机器人启动时会**自动**强制开启以下游戏选项：

- **Click to Move**（点击移动）— 允许机器人通过点击地面移动
- **Self Cast**（自我施法）— 允许对自身施放技能

### 6.3 MACRO 热键

Profile 中必须配置 `MACRO` 热键，这是机器人与游戏通信的核心机制：

```xml
<hotkeys>
    <hotkey name="MACRO" key="VK_0" />
</hotkeys>
```

> **说明**：机器人会在游戏内创建专用的命令宏和结果宏，通过 `VK_0` 触发执行。`VK_0` 对应游戏快捷栏第 0 槽位。**不要将此键绑定到其他功能**。

### 6.4 运行时状态显示

机器人运行时，MicroMacro 窗口标题会显示实时信息：

```
[RoM-Bot] Lv.15 Mage | EXP: 12.3k/min | Next: 45m | Deaths: 0
```

---

## 7. Profile 配置详解

### 7.1 战斗相关

```xml
<!-- 战斗类型 -->
<option name="COMBAT_TYPE"          value="" />       <!-- 留空=自动, melee, ranged -->
<option name="COMBAT_RANGED_PULL"   value="true" />   <!-- 近战职业是否用远程技能拉怪 -->
<option name="COMBAT_DISTANCE"      value="200" />     <!-- 开始施放技能的距离 -->
<option name="MAX_FIGHT_TIME"       value="10" />      <!-- 单次战斗超时（秒），超时放弃 -->
<option name="DOT_PERCENT"          value="90" />      <!-- 目标HP低于此百分比才施放 DoT -->

<!-- 目标选择 -->
<option name="ANTI_KS"              value="true" />    <!-- 不抢杀 -->
<option name="AUTO_TARGET"          value="true" />    <!-- 自动选怪 -->
<option name="MAX_TARGET_DIST"      value="225" />     <!-- 最大选怪距离 -->
<option name="TARGET_LEVELDIF_ABOVE" value="3" />      <!-- 只打高于自己 3 级以内的怪 -->
<option name="TARGET_LEVELDIF_BELOW" value="10" />     <!-- 只打低于自己 10 级以内的怪 -->
<option name="AUTO_ELITE_FACTOR"    value="5" />       <!-- 精英怪判定倍数 -->
```

### 7.2 生存相关

```xml
<!-- 药水使用 -->
<option name="HP_LOW"               value="85" />      <!-- HP% 低于此值使用治疗技能 -->
<option name="HP_LOW_POTION"        value="50" />      <!-- HP% 低于此值使用药水 -->
<option name="MP_LOW_POTION"        value="50" />      <!-- MP% 低于此值使用药水 -->
<option name="USE_HP_POTION"        value="best" />    <!-- best=选最佳药水, minstack=选最小堆叠 -->
<option name="USE_MANA_POTION"      value="best" />
<option name="POTION_COOLDOWN"      value="15" />      <!-- 药水冷却时间（秒） -->

<!-- 休息恢复 -->
<option name="HP_REST"              value="15" />      <!-- HP% 低于此值原地休息 -->
<option name="MP_REST"              value="15" />      <!-- MP% 低于此值原地休息 -->
```

### 7.3 拾取相关

```xml
<option name="LOOT"                 value="true" />    <!-- 是否拾取 -->
<option name="LOOT_ALL"             value="false" />   <!-- 战斗后拾取附近所有尸体 -->
<option name="LOOT_IN_COMBAT"       value="true" />    <!-- 战斗中拾取 -->
<option name="LOOT_DISTANCE"        value="100" />     <!-- 拾取距离 -->
<option name="LOOT_TIME"            value="1500" />    <!-- 拾取超时（毫秒） -->
```

### 7.4 采集相关

```xml
<option name="HARVEST_DISTANCE"     value="120" />     <!-- 采集距离 -->
<option name="HARVEST_WOOD"         value="true" />    <!-- 采集木材 -->
<option name="HARVEST_HERB"         value="true" />    <!-- 采集草药 -->
<option name="HARVEST_ORE"          value="true" />    <!-- 采集矿石 -->
```

### 7.5 自动出售

```xml
<option name="INV_AUTOSELL_ENABLE"  value="false" />   <!-- 启用自动出售 -->
<option name="INV_AUTOSELL_FROMSLOT" value="1" />      <!-- 起始槽位 -->
<option name="INV_AUTOSELL_TOSLOT"  value="60" />      <!-- 结束槽位 -->
<option name="INV_AUTOSELL_QUALITY" value="white,green" /> <!-- 出售品质：white,green,blue,purple -->
```

> 自动出售需配合路径点中的 `player:merchant()` 调用。

### 7.6 购物相关

```xml
<option name="HEALING_POTION"       value="99" />      <!-- 保持治疗药水数量 -->
<option name="MANA_POTION"          value="99" />      <!-- 保持法力药水数量 -->
<option name="ARROW_QUIVER"         value="0" />       <!-- 保持箭矢数量（0=不买） -->
<option name="THROWN_BAG"           value="2" />       <!-- 保持投掷武器数量 -->
<option name="POISON"               value="30" />      <!-- 保持毒药数量 -->
<option name="RELOAD_AMMUNITION"    value="false" />   <!-- 弹药补充：false/arrow/thrown -->
```

### 7.7 宠物蛋相关

```xml
<option name="EGGPET_ENABLE_CRAFT"  value="false" />   <!-- 启用蛋宠采集制作 -->
<option name="EGGPET_CRAFT_SLOT"    value="1" />       <!-- 采集蛋宠槽位（1-6） -->
<option name="EGGPET_ENABLE_ASSIST" value="false" />   <!-- 启用蛋宠辅助攻击 -->
<option name="EGGPET_ASSIST_SLOT"   value="1" />       <!-- 辅助蛋宠槽位 -->
<option name="EGGPET_CRAFT_RATIO"   value="1:1:1" />   <!-- 采矿:伐木:草药比例 -->
```

### 7.8 队伍相关

```xml
<option name="PARTY"                value="false" />   <!-- 启用队伍模式 -->
<option name="PARTY_ICONS"          value="false" />   <!-- 队长在目标上标记 I 图标 -->
<option name="ICON_FIGHT"           value="false" />   <!-- 只攻击有 I 图标的怪 -->
<option name="PARTY_FOLLOW_NAME"    value="" />        <!-- 跟随的队友名 -->
<option name="HEAL_FIGHT"           value="false" />   <!-- 治疗者是否也参与攻击 -->
<option name="PARTYLEADER_WAIT"     value="false" />   <!-- 普通机器人等待队友 -->
```

### 7.9 登出与卡住

```xml
<option name="LOGOUT_TIME"          value="0" />       <!-- 运行多少分钟后登出（0=不限制） -->
<option name="LOGOUT_SHUTDOWN"      value="false" />   <!-- 登出后是否关闭游戏 -->
<option name="LOGOUT_WHEN_STUCK"    value="true" />    <!-- 卡住时登出 -->
<option name="CLOSE_WHEN_STUCK"     value="true" />    <!-- 卡住时关闭机器人 -->
<option name="MAX_UNSTICK_TRIALS"   value="10" />      <!-- 最大脱困尝试次数 -->
<option name="RES_AFTER_DEATH"      value="true" />    <!-- 死亡后自动复活 -->
<option name="MAX_DEATHS"           value="10" />      <!-- 最大死亡次数 -->
<option name="WAIT_TIME_AFTER_RES"  value="8000" />    <!-- 复活后等待时间（毫秒） -->
```

---

## 8. 技能配置详解

### 8.1 技能配置格式

在 Profile 中，按职业配置技能。机器人会根据角色当前主职业自动选择对应技能组。

```xml
<skills_mage>
    <skill name="MAGE_FIREBALL"
           hotkey="MACRO"
           priority="90"
           hpper=""
           manaper=""
           cooldown=""
           inbattle="true"
           pullonly="false"
           maxuse=""
           rebuffcut=""
           reqbuff=""
           nobuff=""
           autouse="true"
           mobcount=""
           minrange="" />
</skills_mage>
```

### 8.2 技能属性说明

| 属性 | 说明 | 示例 |
|------|------|------|
| `name` | 技能名称（参见 `database/skills.xml`） | `MAGE_FIREBALL` |
| `hotkey` | 触发方式：`MACRO`（通过宏系统）或 `VK_1`~`VK_0`（直接按键） | `MACRO` |
| `priority` | 优先级（数值越大越优先，100+ 通常为治疗/Buff） | `90` |
| `hpper` | 目标/自身 HP% 条件（≤此值才施放） | `50` 表示 HP≤50% 时使用 |
| `manaper` | MP% 条件 | `30` |
| `inbattle` | 是否仅在战斗中使用 | `true`/`false` |
| `pullonly` | 是否仅用于拉怪（战斗开始前） | `true` |
| `maxuse` | 单次战斗最多使用次数 | `3` |
| `rebuffcut` | Buff 剩余时间少于 N 秒时重新施放 | `10` |
| `reqbuff` | 需要目标/自身有指定 Buff 才施放 | `BUFF_NAME` |
| `nobuff` | 需要目标/自身没有指定 Buff 才施放 | `BUFF_NAME` |
| `autouse` | 是否自动使用（false 则仅手动调用） | `true` |
| `mobcount` | 周围怪物数 ≥ N 时才施放（AOE 技能） | `3` |
| `minrange` | 最小施放距离 | `150` |

### 8.3 职业技能标签

每个职业有独立的技能标签：

| 职业 | 标签 | 示例技能名前缀 |
|------|------|----------------|
| 战士 | `<skills_warrior>` | `WARRIOR_` |
| 斥候 | `<skills_scout>` | `SCOUT_` |
| 盗贼 | `<skills_rogue>` | `ROGUE_` |
| 法师 | `<skills_mage>` | `MAGE_` |
| 牧师 | `<skills_priest>` | `PRIEST_` |
| 骑士 | `<skills_knight>` | `KNIGHT_` |
| 守卫 | `<skills_warden>` | `WARDEN_` |
| 德鲁伊 | `<skills_druid>` | `DRUID_` |
| 巫士 | `<skills_warlock>` | `WARLOCK_` |
| 冠军 | `<skills_champion>` | `CHAMPION_` |

> **通用技能**：所有职业共享的技能可以放在对应职业标签中，也可以在多职业标签中重复定义。  
> **技能名称**：完整列表参见 `database/skills.xml`。

### 8.4 优先级建议

| 优先级范围 | 用途 | 示例 |
|------------|------|------|
| 100-120 | 紧急治疗/Buff | 紧急治疗、群体Buff |
| 90-100 | 主攻击技能 | 火球术、斩击 |
| 70-90 | 次要攻击技能 | 闪电、穿刺 |
| 30-70 | 辅助/Buff 技能 | 能量涌动、狂暴 |
| 10-30 | 特殊技能 | 潜行、逃跑 |

---

## 9. 事件回调详解

在 Profile XML 中，可以定义 Lua 代码块作为事件回调，实现自定义逻辑。

### 9.1 可用事件

| 事件 | 触发时机 | 可用变量 |
|------|----------|----------|
| `onLoad` | Profile 加载完成后 | 可修改所有 settings.profile.options |
| `onDeath` | 玩家死亡时 | — |
| `onLevelup` | 角色升级时 | — |
| `onLeaveCombat` | 离开战斗时 | — |
| `onPreSkillCast` | 施法前（返回 false 可阻止施法） | `_arg1` = 技能名 |
| `onSkillCast` | 施法后 | `_arg1` = 技能名 |
| `onHarvest` | 采集前（返回 false 可跳过） | `arg1` = 采集物对象 |
| `onUnstickFailure` | 脱困失败时 | — |
| `preCodeOnElite` | 遭遇精英怪前 | `_arg1` = 怪物对象 |

### 9.2 配置示例

```xml
<profile>
    <!-- ... 其他配置 ... -->

    <!-- 加载后自动切换到德语 -->
    <onLoad>
        settings.options.LANGUAGE = "deutsch"
    </onLoad>

    <!-- 死亡时记录日志 -->
    <onDeath>
        print("角色死亡！时间：" .. os.time())
        logToFile("logs/deaths.log", "Death at " .. os.date())
    </onDeath>

    <!-- 升级时自动学习技能 -->
    <onLevelup>
        print("恭喜升级到 " .. player.Level .. " 级！")
        levelupSkills1To10()
    </onLevelup>

    <!-- 施法前检查 -->
    <onPreSkillCast>
        if _arg1 == "MAGE_FIREBALL" and player.MP &lt; 50 then
            print("MP 不足，跳过火球术")
            return false
        end
    </onPreSkillCast>

    <!-- 离开战斗后自动使用 Buff -->
    <onLeaveCombat>
        player:checkSkills(ONLY_FRIENDLY)
    </onLeaveCombat>
</profile>
```

> **注意**：XML 中的 Lua 代码需要转义 `<`、`>`、`&` 等字符（使用 `&lt;`、`&gt;`、`&amp;`）。

---

## 10. 路径文件详解

### 10.1 文件格式

```xml
<waypoints>
    <!-- # 1 --><waypoint x="100" z="200">player:sleep();</waypoint>
    <!-- # 2 --><waypoint x="150" z="250"></waypoint>
    <!-- # 3 --><waypoint x="200" z="300" type="TRAVEL"></waypoint>
</waypoints>
```

### 10.2 路径点类型

| 类型 | 说明 |
|------|------|
| 普通（留空） | 到达后执行代码，在该点附近战斗 |
| `TRAVEL` | 仅经过，不在该点停留战斗 |
| `RUN` | 奔跑通过 |

### 10.3 路径点动作代码

每个路径点的标签内容是到达该点时执行的 Lua 代码：

```xml
<!-- 示例：复杂的路径点动作 -->
<waypoint x="100" z="200">
    -- 检查背包是否满了
    if inventory:freeSlotCount() < 5 then
        -- 背包满了，去回城出售
        loadPaths("ReturnToTown");
    else
        -- 继续打怪
        player:sleep();
    end
</waypoint>
```

### 10.4 返回路径

可以为路径指定一个"返回路径"，用于满背包后回城、死亡后返回等场景：

```xml
<!-- Profile 配置 -->
<option name="WAYPOINTS"   value="GrindingRoute" />
<option name="RETURNPATH"  value="GrindingRoute_return" />
```

在路径点代码中触发返回：

```xml
<waypoint x="100" z="200">
    if inventory:freeSlotCount() < 3 then
        player.Returning = true  -- 切换到返回路径
    end
</waypoint>
```

### 10.5 onLoad 事件

路径文件支持 `onLoad` 事件，在路径加载时执行：

```xml
<waypoints>
    <onLoad>
        print("开始执行 GrindingRoute 路径")
        -- 初始化自定义变量
        myKillCount = 0
    </onLoad>

    <!-- # 1 --><waypoint x="100" z="200"></waypoint>
    <!-- # 2 --><waypoint x="150" z="250">
        myKillCount = myKillCount + 1
        print("已击杀 " .. myKillCount .. " 次")
    </waypoint>
</waypoints>
```

> **注意**：onLoad 代码需要写在单独的 `.lua` 文件中（如 `waypoints/MyRoute_onload.lua`），然后在 XML 中引用。具体格式参见 `waypoints/AndorTraining_onload.lua` 示例。

---

## 11. 游戏内插件安装

### 11.1 ingamefunctions（必需）

**功能**：提供机器人与游戏交互的核心 API（tooltip 读取、任务状态查询、事件监控）。

**安装**：将 `devtools/ingamefunctions/` 复制到游戏 AddOns 目录。

**验证**：机器人启动时会检查插件版本（要求 ≥ 11），未安装或版本过低会报错。

### 11.2 UltimateMailMod（可选）

**功能**：替代游戏原生邮件系统，支持批量发送物品。

**安装**：将 `devtools/UltimateMailMod/` 复制到游戏 AddOns 目录。

**使用**：配合 `userfunctions/addon_Rock5s_Mail_Functions.lua` 实现自动发邮件。

### 11.3 TooltipIds（可选）

**功能**：在游戏 tooltip 中显示对象 ID，辅助开发。

**安装**：将 `devtools/TooltipIds/` 复制到游戏 AddOns 目录。

### 11.4 #d303Fix（可选）

**功能**：修复游戏时间同步和截图问题。

**安装**：将 `devtools/#d303Fix/` 复制到游戏 AddOns 目录（`#` 前缀确保优先加载）。

---

## 12. 辅助工具使用

### 12.1 获取角色坐标

```bat
:: 运行后持续显示当前角色 XYZ 坐标
scripts\rom-bot\Get_Player_Position.bat
```

或在 MicroMacro 中输入：`rom-bot/getpos`

### 12.2 获取对象 ID

```bat
:: 运行后持续显示目标对象/鼠标悬停对象的地址和 ID
scripts\rom-bot\Get_Object_Id.bat
```

或在 MicroMacro 中输入：`rom-bot/getid`

### 12.3 获取鼠标位置

在 MicroMacro 中输入：`rom-bot/mousepos`

### 12.4 地址诊断工具

在 MicroMacro 中输入：`rom-bot/addrtest`

系统性测试所有内存地址是否正确，输出诊断报告到 `addrtest-debug.txt`。

### 12.5 地址更新工具

当游戏更新后地址失效时使用：

在 MicroMacro 中输入：`rom-bot/addrupdate`

> **注意**：此工具仍在开发中，使用风险自负。

---

## 13. 用户自定义函数

### 13.1 创建自定义函数

在 `userfunctions/` 目录下创建文件，命名格式为 `userfunction_名称.lua` 或 `addon_名称.lua`：

```lua
-- userfunctions/my_custom_function.lua

-- 自定义函数：每 10 次战斗后回城
myBattleCount = 0

function checkBattleCount()
    myBattleCount = myBattleCount + 1
    if myBattleCount >= 10 then
        print("已战斗 10 次，准备回城")
        player.Returning = true
        myBattleCount = 0
    end
end
```

### 13.2 内置用户函数

项目已包含以下用户函数，可直接使用：

| 文件 | 功能 | 关键函数 |
|------|------|----------|
| `userfunction_30daymounts.lua` | 自动合成 30 天坐骑 | `doMount()` |
| `userfunction_countmobs.lua` | 怪物/玩家计数 | `CountMobs()`, `CountPlayers()` |
| `userfunction_Fusion_Functions.lua` | 融合石制作 | `Fusion_NumberToBuy()`, `Fusion_Config()` |
| `userfunction_speedhack.lua` | 速度修改 | `speed(50)` |
| `userfunction_swimhack.lua` | 游泳/飞行 | `fly()`, `flyoff()` |
| `userfunction_teleport.lua` | 传送功能 | `teleport(x,z,y)`, `teleportToWP(index)` |
| `userfunction_telefollow.lua` | 传送到目标 | `telefollow(dist, address)` |
| `userfunction_objectdump.lua` | 对象内存转储 | `objectDump(object, filename)` |
| `addon_Rock5s_Mail_Functions.lua` | 邮件功能扩展 | `markToSend()`, `findMailbox()` |

### 13.3 在路径点中调用

```xml
<waypoint x="100" z="200">
    -- 调用自定义函数
    checkBattleCount()

    -- 调用内置函数
    CountMobs(true, 200)  -- 计数 200 范围内的攻击性怪物
    doMount()             -- 检查并使用坐骑
</waypoint>
```

---

## 14. 更新与维护

### 14.1 使用更新器（最简单）

运行项目根目录下的 `rombot_updater.exe`，自动更新所有文件。

### 14.2 Git 更新

如果安装了 Git，在 MicroMacro 中输入：

```
rom-bot/gitupdate
```

或使用 `-f` 强制更新：

```
rom-bot/gitupdate -f
```

Git 更新会自动备份当前文件，然后从 GitHub 拉取最新代码。

### 14.3 手动更新

1. 下载最新 [ZIP 包](https://github.com/SolarStrike-Software/rom-bot/archive/refs/heads/master.zip)
2. 解压后覆盖现有文件（**覆盖所有文件**）

> **注意**：手动更新前建议备份你的 `profiles/`、`waypoints/` 和 `userfunctions/` 目录。

### 14.4 游戏更新后

游戏更新后内存地址可能失效，需要：

1. 尝试运行 `rom-bot/addrupdate` 自动更新地址
2. 或等待项目发布对应新版本的更新
3. 检查 `devtools/ingamefunctions/` 插件是否需要更新

---

## 15. 常见问题排查

### 15.1 机器人无法附加到游戏

**现象**：`attach(getWin())` 失败

**排查**：
1. 确认游戏已启动且角色已登录
2. 确认以窗口模式运行游戏
3. 尝试使用 `character:角色名` 参数指定窗口
4. 多开时确保选择了正确的窗口

### 15.2 ingamefunctions 版本错误

**现象**：`ingamefunctions version too old` 或 `igf addon not found`

**解决**：
1. 确认已将 `devtools/ingamefunctions/` 复制到游戏 AddOns 目录
2. 重启游戏客户端
3. 在游戏内检查插件是否被启用

### 15.3 MACRO 热键错误

**现象**：`MACRO hotkey not defined` 或宏测试失败

**解决**：
1. 确认 Profile 中定义了 `<hotkey name="MACRO" key="VK_0" />`
2. 确认游戏快捷栏第 0 槽位没有被占用
3. 机器人会在游戏内自动创建宏，确保有足够的宏槽位（最多 49 个）

### 15.4 路径文件无法加载

**现象**：`Error loading waypoints`

**排查**：
1. 确认 XML 格式正确（可用浏览器打开验证）
2. 确认文件在 `waypoints/` 目录下
3. 确认文件名与 Profile 中的 `WAYPOINTS` 配置一致
4. 检查坐标值是否为有效数字

### 15.5 角色卡住不动

**现象**：角色反复尝试移动但无法到达路径点

**排查**：
1. 检查路径点坐标是否可达（没有障碍物）
2. 增大 `MAX_UNSTICK_TRIALS` 值
3. 检查 `LOGOUT_WHEN_STUCK` 配置
4. 使用 `createpath` 工具重新录制路径

### 15.6 技能不施放

**现象**：角色在战斗中不使用技能

**排查**：
1. 确认技能名与 `database/skills.xml` 中的名称完全匹配
2. 确认技能对应的职业标签正确（如法师技能在 `<skills_mage>` 中）
3. 检查 `priority` 值是否合理
4. 检查 `hpper`/`inbattle` 等条件是否过于严格
5. 开启调试模式（`rom-bot/bot debug`）查看技能可用性

### 15.7 不拾取物品

**现象**：击杀怪物后不拾取

**排查**：
1. 确认 `LOOT` 设置为 `true`
2. 确认 `LOOT_DISTANCE` 足够大
3. 检查背包是否已满
4. 检查 `LOOT_IGNORE_LIST` 是否排除了该物品

### 15.8 开启调试模式

在 MicroMacro 中以 debug 模式启动：

```
rom-bot/bot debug
```

调试模式会输出详细信息：
- 玩家/目标状态
- 技能可用性检查
- 路径点导航
- 拾取/采集日志
- 自动出售日志

也可以在 Profile 中开启特定调试选项：

```xml
<option name="DEBUG_INV"      value="true" />  <!-- 背包调试 -->
<option name="DEBUG_LOOT"     value="true" />  <!-- 拾取调试 -->
<option name="DEBUG_TARGET"   value="true" />  <!-- 目标调试 -->
<option name="DEBUG_HARVEST"  value="true" />  <!-- 采集调试 -->
<option name="DEBUG_WAYPOINT" value="true" />  <!-- 路径调试 -->
<option name="DEBUG_AUTOSELL" value="true" />  <!-- 出售调试 -->
```

---

## 附录：全局设置文件 (settings.xml)

`settings.xml` 位于项目根目录，定义全局设置（非角色特定）：

```xml
<settings>
    <hotkeys>
        <hotkey description="MOVE_FORWARD"  key="VK_W"     modifier="" />
        <hotkey description="MOVE_BACKWARD" key="VK_S"     modifier="" />
        <hotkey description="ROTATE_LEFT"   key="VK_Q"     modifier="" />
        <hotkey description="ROTATE_RIGHT"  key="VK_E"     modifier="" />
        <hotkey description="STRAFF_LEFT"   key="VK_A"     modifier="" />
        <hotkey description="STRAFF_RIGHT"  key="VK_D"     modifier="" />
        <hotkey description="JUMP"          key="VK_SPACE" modifier="" />
        <hotkey description="TARGET"        key="VK_TAB"   modifier="" />
        <hotkey description="TARGET_FRIEND" key="VK_J"     modifier="" />
    </hotkeys>

    <options>
        <option name="LANGUAGE"            value="english" />  <!-- english|deutsch|french|russian|polish|portuguese -->
        <option name="USE_CLIENT_LANGUAGE" value="true" />     <!-- 自动使用客户端语言 -->
        <option name="DEBUGGING"           value="false" />
        <option name="ROMDATA_PATH"        value="" />         <!-- 游戏数据路径，留空自动检测 -->
    </options>
</settings>
```

> **热键说明**：全局热键对应游戏内的移动/选目标按键，需与游戏设置一致。机器人也会自动读取游戏的 `bindings.txt` 文件来获取键位。如果自动检测失败，手动设置 `ROMDATA_PATH` 为游戏安装目录的完整路径。

---

## 快速开始清单

```
□ 1. 安装 MicroMacro
□ 2. 将 rom-bot 脚本放到 micromacro/scripts/rom-bot/
□ 3. 将 devtools/ 下的插件复制到游戏 interface/addons/
□ 4. 复制 profiles/Default.xml 为 profiles/你的角色名.xml
□ 5. 编辑你的 Profile：设置技能、战斗参数、路径
□ 6. 创建路径文件（用 createpath 工具或手写 XML）
□ 7. 启动游戏，登录角色
□ 8. 打开 MicroMacro，输入 rom-bot/bot
□ 9. 按 DELETE 启动机器人，按 END 停止
```
