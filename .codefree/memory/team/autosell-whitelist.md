---
name: autosell-whitelist
type: project
scope: team
description: "活跃需求：用户想要一个卖背包物品的插件或功能，带白名单保护指定物品不被卖出。已确认 rom-bot 已有可复用实现：inventory 类的 autoSell 在 player:merchant 打开商店后触发，settings 的 INV_AUTOSELL_IGNORE 保护名单按名称子串匹配、按..."
created: "2026-11-05T09:27:50.965Z"
updated: "2026-11-05T09:27:50.965Z"
---
活跃需求：用户想要一个卖背包物品的插件或功能，带白名单保护指定物品不被卖出。已确认 rom-bot 已有可复用实现：inventory 类的 autoSell 在 player:merchant 打开商店后触发，settings 的 INV_AUTOSELL_IGNORE 保护名单按名称子串匹配、按物品 ID 精确匹配（_item.Id == tonumber(条目)），可与 TooltipIds 联动，用游戏内查到的物品 ID 填入名单。当前状态：已向用户摆出现成 autoSell 配置与独立插件两条路线，等待用户确认选择；若选现成路线则配置 INV_AUTOSELL_ENABLE 与 INV_AUTOSELL_IGNORE 并接到跑图脚本即可，无需写新代码。