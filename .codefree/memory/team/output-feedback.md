---
name: output-feedback
type: feedback
scope: team
description: 另外 settings.lua 里 `TARGET_FRIEND = {key = _G.key.J, modifier = nil}` —— 注意这里用的是 `_G.key.J` 而不是 `VK_J`！如果 2.x 的 key 表只有 VK_J 没有 J，那么 key.J 是 nil？settin...
created: "2026-11-04T07:32:31.799Z"
updated: "2026-11-06T02:12:13.511Z"
---
另外 settings.lua 里 `TARGET_FRIEND = {key = _G.key.J, modifier = nil}` —— 注意这里用的是 `_G.key.J` 而不是 `VK_J`！如果 2.x 的 key 表只有 VK_J 没有 J，那么 key.J 是 nil？settings.lua 是 1.05 时代代码，1.05 的 key 表是不是有 J？这需要看。但这是既有代码，2.x 迁移时设置文件会用默认值。这个点值得在报告中提示：key 表直接数字引用 key.J 需要在迁移时检查。