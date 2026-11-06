---
name: gubao-door-mechanism
type: project
scope: team
description: gubao 副本开门路径是当前进行中的活跃工作，机制与约束已确认。完整流程：先击杀精英怪并显式拾取其掉落的卡片，拾取必须安全第一——先用 fight 清完附近仍攻击角色的怪、确认脱离战斗后再按精英怪 ID 精确拾取其尸体，不能死亡立即拾取，也不能只依赖战斗自动拾取（脚本内需强制 settings.p...
created: "2026-11-04T07:47:04.804Z"
updated: "2026-11-04T07:47:04.804Z"
---
gubao 副本开门路径是当前进行中的活跃工作，机制与约束已确认。完整流程：先击杀精英怪并显式拾取其掉落的卡片，拾取必须安全第一——先用 fight 清完附近仍攻击角色的怪、确认脱离战斗后再按精英怪 ID 精确拾取其尸体，不能死亡立即拾取，也不能只依赖战斗自动拾取（脚本内需强制 settings.profile.options.LOOT 和 LOOT_ALL 为 true）；拾取到卡片后执行 /kcg，用 EventMonitor 监听 CHAT_MSG_SYSTEM 系统消息抓取 9 位数字密码；随后与开门 NPC 对话，对话一打开即直接显示 0~9 数字选项（无需先点菜单项），按密码每一位逐层用 GetSpeakOption 精确匹配数字选项选择，选完第 9 位自动开门。已生成 waypoints/gubao_onload.lua 和 waypoints/gubao.xml，路径 XML 通过 onLoad 内 include() 引入配套 onload.lua（与 survivalR5 同款写法）；其中精英怪、卡片、开门 NPC 三个 ID 目前是模拟占位（1000001/2000001/3000001），XML 坐标全为占位。下一步工作：用 getid.lua 采集真实 ID 替换三个占位值，用 createpath.lua 录制真实副本路径，并确认依赖 ingamefunctions 插件与 profile 的 MACRO 热键配置（SlashCommand 依赖它）。