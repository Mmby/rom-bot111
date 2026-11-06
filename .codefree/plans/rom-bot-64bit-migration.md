# RoM-Bot 64 位客户端重构开发计划

## 1. Context（背景与目标）

当前项目是 **RoM-Bot 4.1**，基于 **MicroMacro 1.05**（AutoIt 编译的 **32 位** 演示引擎），并通过 `bot.lua:4-8` 的版本校验强制锁定 1.05（`getVersion()/100 >= 1.06` 直接报错）。

**根本限制**：MicroMacro 1.05 是 32 位进程，无法可靠读取 64 位游戏客户端的内存（32 位地址空间无法容纳 64 位指针，跨位数 `ReadProcessMemory` 受限）。因此必须迁移到 **C++ 重写、支持 64 位进程的 MicroMacro 2.x（≥1.9 系列）**。

**目标**：将现有脚本体系整体迁移到 MicroMacro 2.x（64 位），使机器人能够附加并驱动 64 位游戏客户端；**完全放弃 32 位客户端与 1.05 兼容**（用户已确认）。

**核心工作量**分布在三个层面：
1. **运行时 API 迁移**：1.05 全局函数 → 2.x 命名空间化 API；
2. **指针宽度升级**：所有 4 字节指针解引用 → 8 字节（64 位指针），指针数组步进 `i*4` → `i*8`；
3. **地址全量重定位**：`addresses.lua` 及散落的静态地址全部基于 64 位客户端重新扫描（结构体布局可能变化，不仅是指针宽度）。

## 2. Recommended Approach（推荐方案）

采用 **「兼容层隔离 + 分层迁移」** 策略：不为每个调用点做机械替换，而是新建一个兼容层，在 MicroMacro 2.x API 之上恢复 1.05 风格的全局函数签名，使 `classes/`、`userfunctions/`、`devtools/`、工具脚本的调用点改动最小化，同时把「指针宽度」这一核心差异集中在兼容层内一次解决。

### 2.1 总体路线（6 个阶段）

```
阶段 0 环境准备与 API 盘点（Windows + 64 位客户端）
  ↓
阶段 1 兼容层与启动链路（能 attach、能读玩家）
  ↓
阶段 2 地址重定位（addresses.lua / 静态地址 / 宏通信地址）
  ↓
阶段 3 核心子系统迁移回归（对象→背包→战斗→任务→银行）
  ↓
阶段 4 用户功能、devtools、工具脚本迁移
  ↓
阶段 5 全量回归与文档收尾
```

### 2.2 阶段明细

#### 前置步骤：新建独立开发分支（用户明确要求，不污染当前分支）
- 当前仓库：`github.com/Mmby/rom-bot111`，当前分支：`master`。
- 先在 `master` 上打基线 tag（建议 `pre-64bit-migration`）作为可回退锚点。
- 从 `master` 新建开发分支，建议分支名 **`feature/micromacro-2x-64bit`**（确认执行时可按喜好调整命名）。
- 全部迁移改动（兼容层、地址重定位、子系统适配、文档、工具脚本）**只提交到该新分支**，`master` 保持不变。
- 分支创建完成后，后续每个阶段独立提交，验证通过再进入下一阶段，便于随时回退。

#### 阶段 0：环境准备与 API 盘点
- 在 Windows 环境安装 **MicroMacro 2.x 最新版（64 位）**；准备可用的 **64 位游戏客户端**。
- 编写 `api_probe.lua`（只读枚举脚本），输出 2.x 实际可用的 API 清单：
  - 内存：`memory.*`（readInt/readUInt/readFloat/readDouble/readByte/readBytes/readString/readPointer/write*）、`*Ptr` 系列是否存在；
  - 进程：`openProcess` 返回的 proc 对象字段（pid/handle/baseAddress）与模块基址获取方式；
  - 窗口：`findWindow`/`window.list()`/窗口类名与有效性判断；
  - 输入：`keyboard.*`、`mouse.*`；
  - 工具：`yrest`/`getTime`/`deltaTime`/`registerTimer`/`setPriority`/`getKeyName`/`findFile`/`include` 是否保留。
- 产出 **API 差异映射表（1.05 → 2.x）**，作为阶段 1 的施工图纸。以下为已知差异（以实际枚举结果为准）：

| 1.05（现状） | 2.x（目标） | 说明 |
|---|---|---|
| `memoryReadInt/UInt/Float/Byte/String(proc, addr)` | `memory.readInt/readUInt/readFloat/readByte/readString(proc, addr)` | 命名空间化 |
| `memoryReadIntPtr/UIntPtr/BytePtr(proc, base, off)` | `memory.readUIntPtr` 或 `memory.readPointer(proc, addr)` 组合解引用 | **必须 8 字节读指针** |
| `memoryWriteInt/Float/Byte/String(proc, addr, v)` | `memory.writeInt/writeFloat/writeByte/writeString(...)` | 命名空间化 |
| `getModuleAddress(pid, exeName)` | proc 对象/模块 API | 基址获取方式可能变化 |
| `openProcess(pid)` | 返回 proc 对象（含 handle/pid/baseAddress） | 值语义变化 |
| `findProcessByExeList / findProcessByWindow` | `process.*` / 窗口对象 API | 进程枚举方式变化 |
| `findWindowList / getWindowClassName / windowRect / windowValid` | `window.*` / `findWindow` | 窗口 API 变化 |
| `keyboardPress/Hold/Release(key)` | `keyboard.keyPress/keyDown/keyUp(key)` | 命名空间化 |
| `mouseClick / mouseSetPos / mouseGetPos` | `mouse.click / mouse.setPosition / mouse.getPosition` | 命名空间化 |
| `yrest / getTime / deltaTime / registerTimer` | 保留或等价替代 | 以枚举结果为准 |

#### 阶段 1：兼容层与启动链路（行为里程碑：能启动并列出/附加角色）
- **修改版本校验**：`bot.lua:4-8` 改为校验 MicroMacro 2.x 必需版本，不再拒绝 ≥1.06。
- **新建 `micromacro_compat.lua`**（在 `bot.lua` 加载链最前部 `include`，位于 `addresses.lua` 之前）：
  - 为 2.x API 包装 1.05 风格全局函数：`memoryReadInt`、`memoryReadUInt`、`memoryReadFloat`、`memoryReadByte`、`memoryReadString`、`memoryWrite*`；
  - **核心**：重写 `memoryReadIntPtr/UIntPtr/BytePtr` 为 **8 字节指针读取**（`readPointer` 或 `readUInt64` + 偏移），并保留 `(proc, base, offset)` 签名；
  - 新增 64 位读取原语（如 `memoryReadUInt64`）供受控场景使用；
  - 适配进程/窗口 API：`getProc`、`getWin`、`findProcessByExeList`、`findProcessByWindow`、`openProcess`、`closeProcess`、`getModuleAddress`、`findWindowList`、`getWindowClassName`、`windowRect`、`windowValid`、`showWindow`、`saveScreenshot`；
  - 适配输入 API：`keyboardPress/Hold/Release`、`mouseClick` 等；
  - `qword.lua`（0x40000000 压缩浮点编解码）与位数无关，**原样保留**。
- **重构 `functions.lua` 的进程/内存基建**：`getProcId`/`getProc`/`getWin`/`getClientExeAddress`（:296-341、:2855-2872）改用兼容层实现；`memoryReadRepeat`（:70-130）中 `uintptr` 分支切换为 8 字节读取。
- **通过 `selectGame` 流程验证**：能列出 64 位客户端所有开着的角色窗口、读取角色名。

#### 阶段 2：地址重定位（64 位客户端，Cheat Engine）
> 这是工作量最大、最不可预估的部分，需要真实 64 位客户端环境逐项扫描，**无法静态推导**。

- **重扫 `addresses.lua`** 全部条目：
  - `game_root.*`（玩家/相机/输入/目标等指针链）、`object_list`、`game_time`、`in_game`、`zone_id`、`movement_speed`、`collecting`、`channel`、`class_info`、`currency`、`crafting`、`hotkey`、`gold`、`bank`、`inventory.rent`、`skillbook`、`item.*`、`text.*`、`loading`、`input_box`、`macro` 等；
  - 注意 **64 位客户端结构体字段偏移可能整体变化**，不能假设只改指针宽度；需要按 32 位行为对照逐字段验证。
- **重扫散落的全局静态地址**：`staticbase_char`、`staticGuildBankBase`、`guildBankOpenPtr`、`bankOpenPtr`（grep 定位全部定义处，大多在 `addresses.lua`/`functions.lua`）。
- **重扫宏通信地址**（`macros.lua`、`functions.lua` 的 `setupMacros`/`commandMacro`/`resultMacro`、`addresses.macro.*`）：`RoMScript/RoMCode` 依赖游戏内宏存储区。
- **更新 `settings.lua:20` `CLIENT_EXE_START_ADDRESS`**：32 位 PE 默认 `0x400000` → 64 位可执行默认 `0x140000000`，以实际客户端 ET 头与 ASLR 状态为准。
- **code_mod 处理**（`addresses.lua` 的 `freeze_target`/`freeze_mousepos`/`swimhack` 等 x86 机器码补丁）：64 位客户端下原地址与字节码全部失效。**决策项**：能用 RoMScript/内存写等价的改造替代；无法等价的**标记禁用**并在 readme 说明，避免隐性失效。
- **交付物**：`addrtest.lua`（项目已有地址校验工具）升级为按实数类型（32/64 位）验证，逐条跑通。

#### 阶段 3：核心子系统迁移与回归（按依赖顺序）
每个子系统迁移后立即用对应调试脚本验证（见 Verification）。

1. **对象体系**：`CObject`（:21-92 指针链、名字指针）、`CObjectList`（**`start + i*4` → `start + i*8`**，:22）、`CPawn`（:132-253 指针与字段）；
2. **玩家**：`CPlayer:update`（:138 `"uintptr"` 8 字节化）、目标读写（:665、:3098）、移动写入（:732）、相机（`CCamera` :27-98）;
3. **背包/金钱**：`CInventory`（:27、:45 金钱为 64 位数值，注意 gold 读取宽度变化）、`CItem`、`CCursor`、`CStore`、`CBank`；
4. **公会银行**：`CGuildbank`（:46 多层指针 `{0xC4, 0x0}`、:68 页链表步进）；
5. **战斗/技能/任务/商店/信使**：`CSkill`、任务、`memorytable.lua` 的 `GetIdName`/`GetItemAddress`（物品名/复数名指针）；
6. **宏通信**：`macros.lua`（:302 热键表步进 `0x4*` → `0x8*`）、`functions.lua` 的 `RoMScript`/`RoMCode`/`readMacro`/`writeToMacro`（:650-850）。

#### 阶段 4：用户功能、devtools、工具脚本迁移
- `userfunctions/`：`speedhack`（内存写速度）、`swimhack`（codemod 依赖，按阶段 2 决策处理）、`teleport`、`telefollow`、`30daymounts`、`countmobs`、`Fusion_Functions`、`Rock5s_Mail_Functions`、`objectdump`；
- `devtools/`：`d303Fix`、`UltimateMailMod`、`ingamefunctions`、`TooltipIds`（涉及内存/宏通信的逐一适配）；
- 工具脚本：`getid.lua`、`getpos.lua`、`createpath.lua`（:97、:630、:749、:802-819 指针读取）、`addrtest.lua`、`addrupdate.lua`、`mousepos.lua`；
- 便携启动脚本：检查 `startbot.bat`、`StartCommandLine.bat`、`createpath.bat` 引用的 micromacro 可执行文件路径/位数。

#### 阶段 5：全量回归与文档收尾
- 完整功能回归（见 Verification）；
- 更新 `readme.md`、`USAGE_GUIDE.md`、`PROJECT_ANALYSIS.md`（技术栈表述改为 MicroMacro 2.x / 64 位）；
- 本地 git 提交并备份基线（迁移前打 tag）。

## 3. Critical Files（关键文件）

| 文件 | 改动性质 |
|---|---|
| `bot.lua` | 版本校验（:4-8）、include 链加入兼容层、main/selectGame 流程适配 |
| `micromacro_compat.lua` | **新增**：兼容层核心（内存/指针宽度/进程/窗口/输入） |
| `api_probe.lua` | **新增**：2.x API 盘点工具 |
| `functions.lua` | 进程/窗口/内存基建（:59-130 memoryReadRepeat、:290-341、:2855-2872）、RoMScript 宏通信（:650-850） |
| `addresses.lua` | 全量地址重扫与 code_mod 处理 |
| `settings.lua` | `CLIENT_EXE_START_ADDRESS`（:20）等配置 |
| `classes/objectlist.lua` | 指针数组步进 `i*4` → `i*8`（:22） |
| `classes/pawn.lua`, `classes/object.lua`, `classes/player.lua`, `classes/camera.lua` | 指针链/字段读取宽度（`"uintptr"` 8 字节化、`*Ptr` 语义） |
| `classes/inventory.lua`, `classes/item.lua`, `classes/bank.lua`, `classes/guildbank.lua`, `classes/store.lua`, `classes/cursor.lua` | 指针读取与金钱（64 位数值） |
| `classes/macros.lua` | 热键表步进（:305）、宏通信地址 |
| `classes/memorytable.lua`, `classes/memdatabase.lua` | 物品名/数据库指针链 |
| `classes/codemod.lua` | 与 code_mod 决策联动（若禁用则随之停用） |
| `userfunctions/*.lua`, `devtools/**` | 逐一适配（speedhack/swimhack/teleport/d303Fix/UMM/igf 等） |
| `getid.lua`, `getpos.lua`, `createpath.lua`, `addrtest.lua`, `addrupdate.lua`, `mousepos.lua` | 工具脚本指针与 API 适配 |

## 4. Existing Reuse（可复用资产）

- **`functions.lua`**:`getProc()`/`getWin()`/`getBaseAddress()` 的全局缓存机制（:290-341、:2855-2872）——保留对外语义，仅替换内部实现；
- **`functions.lua`**:`memoryReadRepeat`（:70）——作为内存读取的统一入口，改造 `uintptr` 分支即可辐射大量调用点；
- **`settings.lua`** 的 `CLIENT_EXE_NAME`/`CLIENT_EXE_START_ADDRESS` 统一管理（:19-20）——迁移后仍走此配置；
- **`qword.lua`** —— 游戏内压缩浮点编解码，与指针位数无关，原样保留；
- **`addresses.lua`** 的「模块基址 + 结构偏移」分层结构（`game_root.base` 等）——保留结构，仅更新数值并标注数据来源（64 位客户端版本）；
- **`addrtest.lua`/`addrupdate.lua`** 地址校验/更新工具模式——升级为 32/64 位实数类型双模式验证；
- **现有 `.bat` 工具与多语言框架（`language/*.lua`）** —— 无需改动或仅文案调整。

## 5. Verification（验证方案）

> 说明：MicroMacro 与游戏客户端均为 Windows 程序，当前开发机为 macOS，**运行与验证必须在 Windows + 64 位客户端环境**执行。

1. **API 盘点**：运行 `api_probe.lua`，输出 2.x API 清单与 1.05→2.x 映射表核对无误；
2. **地址验证**：`addrtest.lua` 逐条验证 `addresses.lua` 全部条目（含指针链多级解引用）读取正确、数值范围合理；
3. **附加与角色选择**：启动 `bot.lua`，能列出 64 位客户端所有角色窗口，正确显示角色名与语言；
4. **子系统冒烟**（每迁移一个子系统后）：角色面板数据（HP/MP/坐标/等级/职业→用 `getpos.lua`/`getid.lua` 核验）、对象列表数量、背包/金钱、银行存取、公会银行翻页；
5. **功能回归**：路径行走（跑通一个现有 waypoint）、自动战斗与拾取、药水、采集、任务对话、复活流程、RoMScript 宏通信；
6. **扩展回归**：`userfunctions`（speedhack/teleport/countmobs 等）、`devtools`（UMM、d303Fix）实机可用的功能点；
7. **稳定性**：连续挂机 ≥2 小时无内存读取错误、无崩溃（对照 1.05 基线行为）；
8. **文档对账**：readme/USAGE_GUIDE/PROJECT_ANALYSIS 描述与实际行为一致。

## 6. 风险与注意事项

- **地址重定位工作量不可预估**：64 位客户端结构体布局可能整体变化，需逐字段对照验证；这是本计划最大的时间变量；
- **code_mod（机器码补丁）无法直接迁移**：需功能替代或禁用，向用户明确决策；
- **2.x API 细节以实测为准**：本计划中的 API 映射为已知方向，阶段 0 枚举后若与预期不符，兼容层按实测调整（兼容层设计正是为此兜底）；
- **宏通信（RoMScript）依赖游戏内宏存储地址**：宏地址重扫失败会导致 `RoMScript`/`RoMCode`/SlashCommand 全链路失效，优先级提前验证；
- **建议迁移前先打 git tag 基线**，每个阶段独立提交，便于回退。