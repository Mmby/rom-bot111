# RoM-Bot 64 位客户端地址重定位清单

> 所属任务：rom-bot-64bit-migration 阶段 2（地址重定位）
> 前置条件：Windows + **64 位游戏客户端** + Cheat Engine（推荐 7.x）
> 方法：在 64 位客户端上重新扫描下列地址，结果回填 `addresses.lua`

## 0. 重扫方法论（重要）

1. **不要假设偏移不变**。64 位客户端编译出的结构体布局可能与 32 位差异较大，既有「绝对地址」又有「结构体字段偏移」都可能整体变化。
2. **区分两类条目**：
   - **静态绝对地址**（A 组）：`[EXE基址 + 偏移]` 或直接绝对地址，需要 Cheat Engine 值扫描重新定位；
   - **结构体字段偏移**（B 组）：挂在大结构上的字段偏移，需要「找到对应对象地址后逐字段验证」，通常与「根指针」一起重扫。
3. **指针宽度**：64 位客户端所有指针为 8 字节。`addresses.lua` 中原本按 4 字节读取的指针位置（`game_root.player.base` 等解引用点）实际读 8 字节——兼容层已统一处理读取宽度，只需重扫地址值本身。
4. **验证方式**：逐项用 `addrtest.lua`（已在兼容层支持下运行）验证读取值与游戏内行为一致（坐标、HP、名字、背包等）。
5. 更新 `settings.lua` 的 `CLIENT_EXE_START_ADDRESS`：64 位 PE 默认 0x140000000（以实际客户端 ET 头为准，若开 ASLR 则基址随机，脚本靠运行时模块基址获取，此项仅作参考）。

---

## A 组：静态绝对地址（需 CE 重扫）

> 当前值均为 32 位客户端镜像；64 位客户端下以真实进程内存中定位到的地址为准，建议统一记录为「相对模块基址的偏移」，以免受 ASLR 影响。

| # | 键路径（addresses.*） | 当前 32 位值 | 用途 | 类型 |
|---|---|---|---|---|
| A1 | game_root.base | 0x60FC0C | 游戏根结构指针（最重要） | 指针(8B) |
| A2 | game_time | 0x611268 | 游戏内时间 | int |
| A3 | in_game | 0x6792B8 | 是否在游戏中 | int |
| A4 | zone_id | 0x673EB0 | 区域 ID | int |
| A5 | movement_speed.base | 0x613B10 | 移动速度 | 指针+0x1498 |
| A6 | collecting.base | 0x67B9D0 | 采集状态 | 指针+0xC |
| A7 | channel.base | 0x67B7D8 | 频道 | 指针+0xE4 |
| A8 | class_info.base | 0x615EB0 | 职业信息大结构 | 指针+0x438 |
| A9 | currency.base | 0x631B38 | 货币 | 指针 |
| A10 | crafting.base | 0x611224 | 制造状态 | int |
| A11 | exp_table | 0x673F6C | 经验表 | 指针 |
| A12 | psi | 0x615E7C | PSI 值 | int |
| A13 | global_cooldown.base | 0x611278 | 全局冷却 | 指针+0x1A84 |
| A14 | actionbar.base | 0x67653C | 动作条 | 指针 |
| A15 | gold.base | 0x615EB0 | 金币（同级 class_info） | 指针+0x86BC |
| A16 | macro.base | 0x67D13C | 游戏内宏存储 | 指针(读后再+size) |
| A17 | hotkey.base | 0x67CFE8 | 热键栏 | 指针+0x28 |
| A18 | loading.base | 0x67D0F8 | 加载状态 | 指针+{0x18,0x1C} |
| A19 | cooldowns.base | 0x611270 | 技能冷却数组 | 指针+0x1A88 |
| A20 | skillbook.base | 0x67E520 | 技能书 | 指针+0x8 |
| A21 | itemset_skills.base | 0x621560 | 套装技能 | 指针 |
| A22 | memdatabase.base | 0x63DB24 | 物品内存数据库 | 指针+0xD4 |
| A23 | equipment.base | 0x6118EC | 装备 | 指针 |
| A24 | bank.base | 0x623C14 | 银行存储 | 指针 |
| A25 | bank.open.base | 0x662CDC | 银行开关 | 指针+0x10 |
| A26 | bank.guild.base | 0x665AA4 | 公会银行 | 指针 |
| A27 | inventory.base | 0x61F888 | 背包存储 | 指针 |
| A28 | inventory.rent.base | 0x615EB0 | 租用页（同 gold） | 指针+0x108CC |
| A29 | cursor.base | 0x67CFC4 | 鼠标悬停物品 | 指针+0x0 |
| A30 | object_list.base | 0x67EAC4 | 对象列表 | 指针数组 |
| A31 | object_list.size | 0x67EAC0 | 对象列表大小 | int |
| A32 | input_box.base | 0x67B7C8 | 输入框焦点 | 指针+{0xC,0x9A4} |
| A33 | text.base | 0x639A4C | 游戏文本缓存 | 指针+0x2A8/0x2AC |
| A34 | mouse.base | 0x639CB8 | 鼠标位置 | 指针+{0x3B4}/{0x3B8} |
| A35 | party.leader.base | 0x63B180 | 队长指针 | 指针 |
| A36 | party.member_list.base | 0x67E468 | 队员列表 | 指针+0x68 |
| A37 | party.icon_list.base | 0x67D1DC | 队伍图标 | 指针+0xC |
| A38 | newbie_eggpet.base | 0x63AE94 | 新手蛋宠 | 指针+0x7C |
| A39 | eggpet.base | 0x62E8B0 | 蛋宠槽位 | 指针 |
| A40 | castingBarPtr | 0xA6BBC8 | 施法条 | 指针+0xC |
| A41 | version.x64_start / x32_start | 0xAE0000 / 0x126000 | 版本字符串扫描区（64 位客户端用 x64_start 段） | 内存扫描 |
| A42 | questGroup_offset | 0x4F0 | 任务组偏移 | int（偏移） |

---

## B 组：game_root 结构体字段偏移（需逐字段验证）

> `game_root.base`（A1）定位后，下列偏移为「根结构内部字段偏移」。64 位客户端下即使根结构地址相同，字段偏移也可能改变，需按「读取值合理性」逐项验证。

| # | 键路径（addresses.game_root.*） | 当前 32 位值 | 读取类型 |
|---|---|---|---|
| B1 | mouseover_object_ptr | 0x75C | 指针 |
| B2 | player_actual_speed | 0x790 | int |
| B3 | ping | 0x7C0 | int |
| B4 | input.movement | 0xAAC | byte |
| B5 | mounting | 0xAE4 | int |
| B6 | camera.base | 0x47C | 指针 |
| B7 | camera.distance | 0x2E8 | float |
| B8 | camera.x/y/z | 0x104/0x108/0x10C | float |
| B9 | camera.focus_x/y/z | 0x110/0x114/0x118 | float |
| B10 | camdistance | {0x454, 0x244} | 多层指针 |
| B11 | player.base | 0x5A8 | 指针 |
| B12 | combat_status | 0x74A | byte |
| B13 | pawn.id | 0x14 | int |
| B14 | pawn.type | 0x18 | int |
| B15 | pawn.name_ptr | 0x294 | 指针 |
| B16 | pawn.guid | 0x20 | int |
| B17 | pawn.x/y/z | 0x28/0x2C/0x30 | float |
| B18 | pawn.rotation_x/y/z | 0x34/0x38/0x3C | float |
| B19 | pawn.base_speed | 0x40 | float |
| B20 | pawn.speed | 0x1F0 | float |
| B21 | pawn.fading | 0x68 | int |
| B22 | pawn.harvesting | 0x164 | int |
| B23 | pawn.stance | 0x228 | int |
| B24 | pawn.cast_full_time | 0x260 | float |
| B25 | pawn.cast_time | 0x264 | float |
| B26 | pawn.cast_spell_id | 0x25C | int |
| B27 | pawn.target | 0x278 | 指针 |
| B28 | pawn.owner_ptr | 0x280 | 指针 |
| B29 | pawn.pet_ptr | 0x284 | 指针 |
| B30 | pawn.hp | 0x2D4 | int |
| B31 | pawn.previous_hp | 0x2DC | int |
| B32 | pawn.alive_flag | 0x2D7 | byte |
| B33 | pawn.max_hp | 0x2E4 | int |
| B34 | pawn.energy1/max_energy1 | 0x2E8/0x2EC | int |
| B35 | pawn.energy2/max_energy2 | 0x2F0/0x2F4 | int |
| B36 | pawn.class1 | 0x310 | int |
| B37 | pawn.level | 0x314 | int |
| B38 | pawn.class2 | 0x31C | int |
| B39 | pawn.level2 | 0x320 | int |
| B40 | pawn.race | 0x328 | int |
| B41 | pawn.lootable_flags | 0x3A0 | int |
| B42 | pawn.attackable_flags | 0x39C | int |
| B43 | pawn.mount_ptr | 0x7C | 指针 |
| B44 | pawn.swimming | 0xF0 + 0xB4 | 多层 |
| B45 | pawn.buffs.array_start/end | 0x26C/0x270 | 指针 |
| B46 | pawn.buffs.buff.* | size 0x54, time 0x30, id 0x20, level 0x44 | 结构 |

> 其它子结构（macro/hotkey/skillbook/item/eggpet 等字段偏移）同理：先定位父结构地址，再验证字段。`item.*`、`skillbook.*`、`eggpet.*` 等字段偏移见 addresses.lua 原文。

---

## C 组：宏通信地址（RoMScript 依赖）

- `addresses.macro.base`（A16）：`macros.lua` 中 `memoryReadUInt(getProc(), getBaseAddress(macro.base))` 读一层指针得 `macro_address`，再按 `macro.size = 0x508`、`content = 0x118` 读写宏内容。
- **64 位注意**：读 `macro_address` 的指针须为 8 字节（兼容层已统一）；`macro.base` 值本身需重扫。
- `addresses.macro.size/id/icon/name/content` 偏移需验证。
- 若宏通信地址失效，`RoMScript/RoMCode/SlashCommand/sendMacro` 全链路失效——**建议在阶段 3 优先验证**。

---

## D 组：散落静态地址（grep 发现被使用但 addresses.lua 未定义）

> 以下键在代码中被引用但 **addresses.lua 中未定义**（当前值为 nil）。64 位重扫时需确认：这些是历史遗留的失效引用，还是定义遗漏。若为功能需要，应补定义并重扫。

| 键 | 使用位置 | 用途 |
|---|---|---|
| addresses.staticGuildBankBase | classes/guildbank.lua:46,90,139、guildbankitem.lua:18 | 公会银行根指针 |
| addresses.guildBankOpen_offset | （同上） | 公会银行开关偏移 |
| addresses.bankOpenPtr | classes/item.lua:350 | 银行开关指针 |
| addresses.bankOpen_offset | classes/item.lua:350 | 银行开关偏移 |
| addresses.staticbase_char | bot.lua:258（调试）、functions.lua 多处注释 | 角色根指针（已被 game_root 取代） |
| addresses.mousePtr_offset | bot.lua:258（调试） | 鼠标悬停对象指针 |
| addresses.inputbox_base | waypoints/AndorTraining_onload.lua:407,409 | 输入框焦点 |

---

## E 组：code_mod（x86 机器码补丁，64 位决策项）

`addresses.lua::code_mod` 含 4 个补丁，均为 32 位 x86 机器码（地址 + 字节串）：

| 名称 | 32 位地址 | 作用 |
|---|---|---|
| freeze_target | 0x4A24F1 | 目标冻结 |
| freeze_mousepos | 0x231C34 | 鼠标位置冻结 |
| freeze_clicktocast_mouseoffscreen | 0x231454 | 点击施法防离窗 |
| swimhack | 0x4DED2 | 游泳修改 |

64 位客户端下：
- 地址与机器码全部失效，**不可直接迁移**；
- 处置建议（三选一）：(1) 用 RoMScript/内存写等价的替代方案重实现；(2) 在 64 位客户端上重新逆向定位对应功能点并生成 x86-64 补丁；(3) 默认禁用并在 readme/USAGE_GUIDE 说明。
- 默认建议先走 (3) 禁用，保证主流程可用，后续按需补 (1)/(2)。

---

## 执行建议流程（Windows 环境）

1. 启动 64 位客户端并进入游戏；
2. 用 Cheat Engine 附加客户端进程，`settings.options.CLIENT_EXE_NAME`（当前 "Client.exe"）对应的模块基址记为 `MODBASE`；
3. 按 A 组逐项：CE「内存查看」跳转至 `MODBASE + 当前偏移`，结合游戏内行为（角色坐标/名字/背包等）验证读取值是否合理；确认后**记录为新的相对偏移**（替换 addresses.lua 数值；若实际基址非 0x140000000 或出现 ASLR，保持「相对偏移」而非绝对地址的用法）；
4. B 组：先定位根结构，再逐字段验证；
5. 运行 `addrtest.lua`（已加载兼容层）逐条验证，修正无效项；
6. 处理 D 组（补定义或删除引用）与 E 组（决策）；
7. 更新 `settings.lua::CLIENT_EXE_START_ADDRESS`；
8. 每完成一批在分支上提交并记录改动说明。