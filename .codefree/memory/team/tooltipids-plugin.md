---
name: tooltipids-plugin
type: project
scope: team
description: TooltipIds 游戏内插件（devtools/TooltipIds/，Rock5 版 1.0b3，Runewaker 帧框架）已完成分析：鼠标悬停 Tooltip 时显示 Unit/Item/Skill/Buff/Title/Mall/Store/Guild/Quest 九类 ID，每类有独立...
created: "2026-11-05T09:23:11.355Z"
updated: "2026-11-05T09:27:50.958Z"
---
TooltipIds 游戏内插件（devtools/TooltipIds/，Rock5 版 1.0b3，Runewaker 帧框架）已完成分析：鼠标悬停 Tooltip 时显示 Unit/Item/Skill/Buff/Title/Mall/Store/Guild/Quest 九类 ID，每类有独立开关，设置经 SaveVariables 持久化；启动后按区间扫描 ID 建 IdTable/NameTable。对外 API GetNameIds/GetIdName 是全局函数而非 TooltipIds 表的方法，其他游戏内插件可直接全局调用，但需处理扫描未完成时返回含 "Still scanning..." 占位表的情况。该插件定位为后续其他游戏内插件的 ID 来源：当前用户实际要做的是一个卖背包物品插件（白名单保护，见 autosell-whitelist 话题），用 TooltipIds 查到物品 ID 后填入白名单。