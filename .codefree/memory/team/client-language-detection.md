---
name: client-language-detection
type: project
scope: team
description: 项目支持按游戏客户端语言自动加载翻译文件。settings.lua 与 bot.lua 的语言检测逻辑中，当 USE_CLIENT_LANGUAGE 为 true（默认值）时，若 bot.ClientLanguage 为 "ZH" 或 "CN" 则加载 chinese.lua。settings.lu...
created: "2026-11-04T01:27:08.599Z"
updated: "2026-11-04T02:30:47.691Z"
---
项目支持按游戏客户端语言自动加载翻译文件。settings.lua 与 bot.lua 的语言检测逻辑中，当 USE_CLIENT_LANGUAGE 为 true（默认值）时，若 bot.ClientLanguage 为 "ZH" 或 "CN" 则加载 chinese.lua。settings.lua 与 bot.lua 中共有三处语言映射逻辑（settings.lua 主加载、bot.lua 调试模式加载、settings.lua 注释掉的早期加载），均已添加中文映射。用户也可手动在 settings.xml 中设置 LANGUAGE="chinese" 启用中文。未翻译条目会自动用 english.lua 回填。language 目录下语言文件以 language = { [key] = "value" } 格式定义，系统先加载 english.lua 作为基础再加载目标语言覆盖。