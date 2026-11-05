# RoM-Bot 64 位迁移进度跟踪（MicroMacro 1.05 → 2.x）

> 维护日期：2026-11-05
> 任务目标：将当前基于 MicroMacro 1.05（32 位）的 rom-bot 重构为支持 64 位客户端，运行时切换到 MicroMacro 2.x（1.9+，C++ 重写版）。
> 决策基线：**完全切换 MicroMacro 2.x（64 位），只支持 64 位客户端**，不做双版本兼容。

---

## 1. 仓库与版本管理

| 项 | 值 |
|---|---|
| 开发分支 | `feature/micromacro-2x-64bit`（所有迁移改动只进此分支） |
| 基线 tag | `pre-64bit-migration`（打在 master，可回滚对照） |
| master | 保持不动 |
| 官方源码参考 | `docs/micromacro-2x-src/`（147 文件，离线权威 API 依据） |
| 远端 | 分支与 tag 均已推送成功 |

提交历史（新 → 旧）：

| Commit | 阶段 | 内容 |
|---|---|---|
| `d2dbbc2` | 1 | 重构 `micromacro_compat.lua`：按官方源码全量重写，补齐窗口/键盘/进程 API |
| `dc82597` | 0 | 纳入 MicroMacro 2.x 官方源码到 `docs/micromacro-2x-src/` |
| `0e597db` | 2 | 地址重定位清单（`64BIT_ADDRESS_RELOCATION.md` 全量条目 + 决策项） |
| `138848b` | 1 | 工具脚本（addrtest/getid/getpos/createpath/mousepos）加载兼容层，支持 2.x 运行 |
| `16c1726` | 1 | 新增 `micromacro_compat.lua`；bot.lua 版本校验切 2.x；memoryReadRepeat 放宽 proc 类型 |
| `37bbdc2` | 0 | 新增 `api_probe.lua`（2.x API 盘点工具） |
| `7dc2eb1` | — | master 基线 tag `pre-64bit-migration` |

---

## 2. 六阶段路线总览

| 阶段 | 名称 | 状态 |
|---|---|---|
| 0 | 环境准备与 API 盘点 | ✅ 完成 |
| 1 | 兼容层与启动链路 | ✅ 完成（静态校验通过，待运行时验证） |
| 2 | 地址重定位 | 🟡 离线清单完成，**待 Windows + 64 位客户端重扫回填** |
| 3 | 核心子系统回归 | ⬜ 未开始（player/object/party/inventory/skill 等） |
| 4 | 用户功能与工具脚本 | ⬜ 未开始 |
| 5 | 全量回归与文档 | ⬜ 未开始 |

图例：✅ 完成　🟡 进行中/部分完成　⬜ 未开始

---

## 3. 阶段明细

### 阶段 0：环境准备与 API 盘点 ✅

- 交付 `api_probe.lua`：对所有 2.x 模块（process/window/keyboard/mouse/time/system/cli/key/macro）做存在性与类型盘点，输出 `api_probe_report.txt`。
- 克隆官方仓库并纳入 `docs/micromacro-2x-src/`（剔除 `.git`/`.DS_Store`），作为离线权威参考。

### 阶段 1：兼容层与启动链路 ✅（静态完成）

核心交付：`micromacro_compat.lua`（当前 HEAD 版本，约 440 行）。

**兼容层覆盖清单**

| 类别 | 1.05 全局函数 | 2.x 官方 API | 处理方式 |
|---|---|---|---|
| 门禁 | — | `_G.process` 表 | 检测 process 表且无 `memoryReadInt` 才启用，1.05 下自动 no-op |
| 内存 | `memoryReadInt/UInt/Float/Double/Byte/UByte/String` | `process.read(proc, type, addr[, len])` | 全量绑定 |
| 内存写 | `memoryWrite*` | `process.write` | 全量绑定 |
| 指针读 | `memoryRead*Ptr`（5 种） | `process.readPtr` | 最终层按 `uint64/int64` 读 **8 字节**，防止 64 位地址截断 |
| 指针写 | `memoryWrite*Ptr`（4 种） | `process.writePtr` | 同上 |
| 进程 | `findProcessByExeList` | `process.findByExe` | 官方只返回单 pid → 包装为数组 `{pid}` 匹配 `#`/`pairs` 迭代 |
| 进程 | `findProcessByWindow` | `process.findByWindow` | 直接映射 |
| 进程 | `openProcess/closeProcess` | `process.open/close` | 直接映射 |
| 模块 | `getModuleAddress` | `process.getModuleAddress(pid, mod)` | 直接映射 |
| 窗口 | `findWindowList` | `window.findList` | 官方返回 `{hwnd,name,class}` 表数组 → 转纯 hwnd 数组 |
| 窗口 | `getWindowsFromProcess` | `process.getWindows(pid)` | 同上转换 |
| 窗口 | `findWindow` | `window.find` | 直接映射 |
| 窗口 | `getWindowClassName/Parent/Title` | `window.getClassName/getParent/getTitle` | 直接映射 |
| 窗口 | `windowRect` | `window.getRect` | 官方返回 5 值（含 showCmd）→ 截断为 4 值 |
| 窗口 | `getHwnd` | `window.getAppHwnd` | 直接映射 |
| 窗口 | `foregroundWindow/getForegroundWindow` | `window.getFocusHwnd` | 直接映射 |
| 窗口 | `showWindow` | `window.show(hwnd, SW_*)` | 直接映射（sw 表数值与 SW_* 一致） |
| 窗口 | `saveScreenshot` | `window.saveScreenshot` | 直接映射 |
| 窗口 | `setWindowName/setWindowTitle` | `window.setTitle` | 直接映射 |
| 窗口 | `getConsoleAttributes` | 无对应 | 以主窗口客户区宽高近似（仅 createpath 辅助工具用） |
| 键盘 | `keyboardPress(key, modifier)` | `keyboard.press(vk, async)` | 第二参语义冲突 → 包装 modifier 按住-按下-释放序列 |
| 键盘 | `keyPressed/keyPressedLocal` | `keyboard.isDown(vk)` | 直接映射 |
| 键盘 | `keyboardState` | `keyboard.isDown` 逐键 | 遍历 `_G.key` 表近似（无一次性状态快照） |
| 键盘 | `keyboardBufferClear/SetDelay` | 无对应 | no-op 占位 |
| 鼠标 | `mouseClick` | 无 `mouse.click` | `press+release` 组合，支持 "right"/"middle" 字符串 |
| 鼠标 | `mouseSetPos/mouseGetPos/mouseSet` | `mouse.setPosition/getPosition` | 直接映射 |
| 时间 | `getTime` | `time.getNow` | 直接映射 |
| 时间 | `deltaTime` | `time.diff`（返回秒） | **×1000 换算毫秒**（1.05 语义） |
| 睡眠 | `yrest/rest` | `system.rest(ms)` | 直接映射 |
| 位运算 | `bitAnd/Or/Xor/Not/LShift/RShift` | 无对应 | 纯 Lua 32 位兜底实现 |
| 常量 | `sw/priority/cli` | 2.x 已有 SW_* / key 表 | 缺失时最小表兜底，cli 颜色名占位 |
| 版本 | `getVersion()` | `macro.getVersion()`（字符串） | 解析 "MAJOR.MINOR.BUILD" 为数字 |

**bot.lua 启动链路**
- 版本校验优先解析 `_G.macro.getVersion`（2.x 字符串，要求 ≥1.9），1.x 全局数字兜底（≥1.06），避免字符串/数字运算崩溃。
- `memoryReadRepeat` 放宽 proc 类型校验（`userdata`/`table` 均接受）。

**校验情况**：compat + bot.lua 离线括号结构 + 必需函数存在性校验全部通过；尚未在真实 2.x 运行时验证。

### 阶段 2：地址重定位 🟡

- 离线部分完成：`64BIT_ADDRESS_RELOCATION.md` 已列出 A 组（静态绝对地址，36+ 条）与散落地址、宏通信、code_mod 决策项，含重扫方法论。
- **待办（需 Windows + 64 位游戏客户端 + Cheat Engine）**：
  1. 用 CE 对 A 组地址重扫，结果回填 `addresses.lua`；
  2. 确认 `CLIENT_EXE_START_ADDRESS`（64 位 PE 默认 0x140000000，若开 ASLR 则靠运行时模块基址）；
  3. 用 `addrtest.lua` 逐项验证。

#### 地址工具定位（addrtest vs addrupdate）

| 工具 | 类型 | 原理 | 64 位适配状态 |
|---|---|---|---|
| `addrtest.lua` | 验证 | 按 `addresses.lua` 现有地址读内存，输出各区块读取结果（坐标/HP/背包/对象等） | ✅ 加载 compat 层后中立可用，是阶段 2 验证留口 |
| `addrupdate.lua` | 自动更新 | 直接对客户端 exe 做**静态特征码扫描**，命中后提取新地址并回写 `addresses.lua`（自动备份） | ⚠️ 需要 64 位特征码重做（见下） |

#### addrupdate.lua 的 64 位适配决策（阶段 2 决策项）

**结论：框架可复用，特征码需整体重做。** 分层评估：

- **框架层（可复用，改动小）**：exe 二进制读取、`byteArrayToPattern`/`findPattern` 特征匹配引擎、回写 `addresses.lua`（含 `--[[{key}]]` 注释锚点与备份）、partners 连锁推导——均与位数无关。
- **内容层（必须人工重做）**：
  1. `updatables` 全部 30+ 条目为 32 位 x86 特征码（如 `8B 0D ?? ?? ?? ??`），64 位编译后指令编码整体变化（RIP 相对寻址），**必须用 CE「Find what accesses this address」/IDA 对 64 位客户端重新提取特征码**（本质是一次静态逆向）；
  2. `value_size = 4` 需支持 8 字节（64 位指针/立即数）；
  3. `CLIENT_EXE_START_ADDRESS` 上游默认值 0x400000 → 0x140000000（settings.lua:20）；
  4. `freeze_*`/`swimhack_codemod` 等代码注入点同样需重提；
  5. `mdbrute.exe` 外部依赖需确认 64 位版，没有则该路由降级。
- **时效性**：特征码绑定特定客户端编译版本；游戏小更新若该段代码未变仍可自动更新，大更新后需重新提取。
- **决策**：迁移主路径用 CE 重扫回填 `addresses.lua`（确定性优先）；addrupdate 适配作为**阶段 3/4 跑通后的增强项**，届时先人工提取 64 位特征码，再做脚本侧适配（8 字节读取、基址参数化、mdbrute 降级），改动量约数十行。

### 阶段 3-5：⬜ 未开始

- 阶段 3：核心子系统回归（player/object/party/inventory/skill/memdatabase 等内存读写在真实客户端上跑通）。
- 阶段 4：用户功能与工具脚本（createpath/getpos/getid/addrtest/mouspos + userfunctions/*），含 addrupdate 64 位适配（若用户启用）。
- 阶段 5：全量回归（bot 挂机全流程）+ 更新文档 + 合并策略确认。

---

## 4. 当前卡点与下一步行动

顺序执行：

1. **[P0] 回传 api_probe_report.txt**：Windows 下用 MicroMacro 2.x 运行 `api_probe.lua`，把生成的报告发回 → 对照核实兼容层对 `key.VK_*` 常量名、`[TODO-API]` 标注的缺失项，做最后一轮静态盘点。此步**不需要游戏客户端**，装了 2.x 即可跑。
2. **[P0] 64 位客户端地址重扫**：按 `64BIT_ADDRESS_RELOCATION.md` 方法论，A 组优先回填 `addresses.lua`。
3. **[P1] 核心子系统回归**：在真实环境跑 `addrtest.lua`/`getid.lua` 验证兼容层内存读写正确性，再逐子系统回归。
4. **[P2] 工具脚本 + 全量回归**。

---

## 5. 关键决策与风险备忘

### 关键 API 事实（已从官方源码核实）

- 2.x **无** `memory` 表与全局 `memoryReadInt`；进程内存 API 全在 `process` 表（`read/readPtr/write/writePtr` 用类型字符串）。
- `readPtr/writePtr` 支持数字或多层偏移表；中间层指针宽度**按进程位数自动读取**（64 位即 8 字节）；语义为逐层 `addr = *(addr) + off`。
- `getVersion` 注册为 `macro.getVersion`，返回字符串；全局不存在。
- `mouse` 无 `click`，需 `press+release`；按键用 VK 码（VK_LBUTTON=1/RBUTTON=2/MBUTTON=4）。
- `time.diff` 返回**秒**；1.05 的 `deltaTime` 返回**毫秒**（证据：skill.lua:790 用 `/1000` 换算秒），兼容层已 ×1000。
- `window.getRect` 返回 `x,y,w,h,showCmd` 五值；`findList`/`process.getWindows` 返回 `{hwnd,name,class}` 表数组（与 1.05 纯 hwnd 数组不同，已包装）。

### 遗留风险

| 风险 | 说明 | 缓解 |
|---|---|---|
| keyboardState 近似实现 | 2.x 无一次性键盘状态快照，compat 遍历 `key` 表逐个 `isDown` | 低频辅助工具可用；若 createpath 按键采集异常，循环内补 `system.repollHid()` |
| keyboardState 准确性依赖 HID 轮询 | 2.x 按键事件需 `system.repollHid()` 刷新后才准 | 见上 |
| `getConsoleAttributes` 近似 | 2.x 无控制台尺寸 API，用客户区宽高近似 | 仅影响 createpath 控制台尺寸恢复，不伤核心逻辑 |
| 地址偏移可能整体变化 | 64 位客户端结构体布局与 32 位可能差异较大 | 阶段 2 必须逐项重扫验证，不假设偏移不变 |
| addrupdate 特征码失配 | 其 `updatables` 全是 32 位 x86 特征码，64 位客户端下全部失效，且特征码绑定编译版本、大更新后会再失效 | 迁移期不依赖它（用 CE 重扫）；若启用自动更新，需先人工提取 64 位特征码并做好「失配即提示手工处理」的降级 |
| cli 颜色常量 | 2.x 的 cli 是控制台函数表（非颜色名字符串），compat 用占位字符串 | `cprintf` 在 2.x 缺失时已退化为 `printf` |

---

## 6. 关联文档

- `PROJECT_ANALYSIS.md` —— 项目功能架构分析（18 个子系统）。
- `64BIT_ADDRESS_RELOCATION.md` —— 阶段 2 地址重定位清单与方法论。
- `docs/micromacro-2x-src/` —— MicroMacro 2.x 官方源码（离线 API 权威参考）。
- `api_probe.lua` / `micromacro_compat.lua` —— 盘点工具与兼容层本体。