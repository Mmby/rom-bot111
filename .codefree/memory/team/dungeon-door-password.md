---
name: dungeon-door-password
type: project
scope: team
description: "gubao 副本自动开门脚本正在开发中，已确认机制与流程：开门卡片由精英怪掉落且必须显式拾取（getNearbyLoot + player:loot，LOOT/LOOT_ALL=true，附 120 秒超时防死循环）；执行 /kcg 后系统消息（CHAT_MSG_SYSTEM）输出 9 位纯数字密码..."
created: "2026-11-04T07:05:29.107Z"
updated: "2026-11-04T07:50:05.169Z"
---
gubao 副本自动开门脚本正在开发中，已确认机制与流程：开门卡片由精英怪掉落且必须显式拾取（getNearbyLoot + player:loot，LOOT/LOOT_ALL=true，附 120 秒超时防死循环）；执行 /kcg 后系统消息（CHAT_MSG_SYSTEM）输出 9 位纯数字密码；打开开门 NPC 对话直接展示 0~9 选项（无需先点菜单项），密码每一位对应一层对话选项，逐层点选，选完最后一位自动开门；选项必须精确匹配数字（ChoiceOptionByName 是子串匹配易误选，改用 GetSpeakOption 遍历选项取数字比对）。

当前状态：完整方案与模板代码已产出（拟放与路径同名的 _onload.lua），已生成 waypoints/gubao_onload.lua（击杀精英怪→清场安全后按 ID 拾取卡片→/kcg 抓 9 位密码→逐层精确匹配选项点选）与 waypoints/gubao.xml（onLoad 用 include 挂载配套 lua，含调用点位骨架，坐标暂为占位）。gubao_onload.lua 顶部 eliteId/cardId/npcName 目前是模拟占位值（1000001/2000001/3000001）。

下一步：用户用 getid.lua 获取真实精英怪、卡片、NPC 的 ID 替换占位，并用 createpath.lua 录制真实副本路径（开门逻辑不需要录进路径，只在对应 waypoint 调用即可）；待用户提供副本路径文件名与三个 ID 后落地为可用文件。