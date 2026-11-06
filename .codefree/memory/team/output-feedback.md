---
name: output-feedback
type: feedback
scope: team
description: settings.lua 中 TARGET_FRIEND 等热键配置使用 _G.key.J 这类裸键名而非 VK_J，已确认 MicroMacro 2.x 的 key 表只有 VK_ 前缀名（无裸名 J，鼠标键为 VK_LMOUSE/RMOUSE/MMOUSE 而非 VK_LBUTTON 系列）。该...
created: "2026-11-04T07:32:31.799Z"
updated: "2026-11-06T06:35:06.462Z"
---
settings.lua 中 TARGET_FRIEND 等热键配置使用 _G.key.J 这类裸键名而非 VK_J，已确认 MicroMacro 2.x 的 key 表只有 VK_ 前缀名（无裸名 J，鼠标键为 VK_LMOUSE/RMOUSE/MMOUSE 而非 VK_LBUTTON 系列）。该问题已通过向兼容层 key 表补 A-Z/0-9 裸名别名解决，现有 _G.key.J 写法可用、settings.lua 无需改动；后续新写热键配置应优先使用 VK_ 前缀名。