---
name: client-exe-config
type: project
scope: team
description: 项目将游戏客户端可执行文件名与默认基址统一管理在 settings.lua 的 options 表中：CLIENT_EXE_NAME（默认 "Client.exe"）与 CLIENT_EXE_START_ADDRESS（默认 0x400000）。functions.lua 中所有进程查找与模块地址获...
created: "2026-11-04T01:27:08.578Z"
updated: "2026-11-04T02:30:41.185Z"
---
项目将游戏客户端可执行文件名与默认基址统一管理在 settings.lua 的 options 表中：CLIENT_EXE_NAME（默认 "Client.exe"）与 CLIENT_EXE_START_ADDRESS（默认 0x400000）。functions.lua 中所有进程查找与模块地址获取均引用 settings.options.CLIENT_EXE_NAME，不再硬编码。addrupdate.lua 是可独立运行的脚本，未 include settings.lua，因此采用安全回退模式：(settings and settings.options and settings.options.CLIENT_EXE_NAME) or "Client.exe"，确保独立运行时仍正常工作。后续如需修改客户端可执行文件名，只需改 settings.lua 一处。

进程查找的另一匹配维度是窗口类名 "Radiant Arcana"（functions.lua 中的回退路径），这与 exe 文件名是两个独立匹配机制。任务管理器中显示的 "OFA Client" 是进程友好显示名，不是 exe 文件名，不能用于 findProcessByExeList 匹配；实际 exe 文件名需在任务管理器"详细信息"标签页确认。