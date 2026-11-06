---
name: custom-macro-skill-config
type: project
scope: team
description: 项目中调用游戏内技能有两条路径：hotkey="MACRO" 通过 RoMCode("UseSkill(tab,num)") 调用游戏 API（需技能在 database/skills.xml 中有 id），hotkey="VK_X" 通过模拟按键触发（需技能已放在游戏快捷栏对应键位）。
created: "2026-11-04T02:30:41.204Z"
updated: "2026-11-04T02:30:41.204Z"
---
项目中调用游戏内技能有两条路径：hotkey="MACRO" 通过 RoMCode("UseSkill(tab,num)") 调用游戏 API（需技能在 database/skills.xml 中有 id），hotkey="VK_X" 通过模拟按键触发（需技能已放在游戏快捷栏对应键位）。

游戏内自定义宏（巨集）不在 skills.xml 数据库中、无技能 id，无法用 MACRO 方式调用。推荐的配置方案：在 database/skills.xml 中添加一条自定义条目（id="0" range="0" type="buff" casttime="0" cooldown="0" target="self"），然后在 profile 中用 hotkey="VK_X" 指向游戏内宏所绑定的快捷键。settings.lua 中有校验：id 为 0 时不能用 MACRO，但用具体按键允许。若只需在特定路径点触发而非战斗循环，也可在 waypoint 文件的 Lua 代码块中直接用 keyboardPress 或 RoMCode("UseAction(slot)") 调用。