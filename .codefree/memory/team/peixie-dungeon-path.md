---
name: peixie-dungeon-path
type: project
scope: team
description: "第二个副本路径原名为 duer，用户已明确要求改名为 peixie，当前正在开发中。机制与 gubao 开门不同：进入副本后走一段路，点击门——用户明确确认点击门与选择难度均按 NPC 对话处理，用 player:target_NPC(doorId) 定位并自动走近双击交互，不再用 target_O..."
created: "2026-11-04T08:18:13.580Z"
updated: "2026-11-04T08:18:13.580Z"
---
第二个副本路径原名为 duer，用户已明确要求改名为 peixie，当前正在开发中。机制与 gubao 开门不同：进入副本后走一段路，点击门——用户明确确认点击门与选择难度均按 NPC 对话处理，用 player:target_NPC(doorId) 定位并自动走近双击交互，不再用 target_Object；弹出对话框直接显示难度选项，peixieChooseDifficulty 遍历 GetSpeakOption 精确匹配难度显示文字后 ChoiceOption 选择，选完难度门消失，进入正常路线自动打怪打 Boss（NORMAL 路径点默认行为），peixieFightBoss 锁定 Boss 持续战斗并带超时保护。已生成 waypoints/peixie_onload.lua 与 waypoints/peixie.xml（onLoad 用 include 挂载配套 lua），onload 内已实现 peixieOpenDoor/peixieChooseDifficulty/peixieFightBoss 三个函数（函数名与 include 路径均随改名从 duer 同步替换，无残留）；doorId（门 ID 或名称）、diffText（难度选项显示文字）、bossId 目前为模拟占位值，XML 坐标全为占位需用 createpath.lua 录制替换。下一步：用 getid.lua 采集门对象与 Boss 真实 ID，确认难度选项的实际显示文字（若为图标或编号则改用 ChoiceOption 序号选择），确认中间打怪路线是否需要周期性 player:rest 回血。