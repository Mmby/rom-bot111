---
name: 64bit-migration
type: project
scope: team
description: rom-bot 向 64 位客户端迁移、MicroMacro 升级到 2.x（1.9+，C++ 重写版）的活跃重构，方案已确认：完全切换 MicroMacro 2.x，只支持 64 位客户端，迁移在分支 feature/micromacro-2x-64bit 进行、master 保持不动。兼容层缺口...
created: "2026-11-05T00:32:41.374Z"
updated: "2026-11-06T06:30:39.215Z"
---
rom-bot 向 64 位客户端迁移、MicroMacro 升级到 2.x（1.9+，C++ 重写版）的活跃重构，方案已确认：完全切换 MicroMacro 2.x，只支持 64 位客户端，迁移在分支 feature/micromacro-2x-64bit 进行、master 保持不动。兼容层缺口修复已完成并提交到该分支：新增 classes/xml.lua 纯 Lua XML 解析器（compat 自动加载并有加载路径兜底）、filesystem 全局函数别名导出、loadstring→load、鼠标三键组合、热键 set/get 存值模拟、setPriority 数字→字符串映射、logMessage 映射、key 裸键名别名；api_probe.lua 已修复读值探测误报（改为 exists 判定）并补 macro/system/log/event 表与全局限量枚举。离线验证通过：自制 Lua 5.4 解释器跑 xml 功能测试 35/35、compat 模拟 2.x 环境加载测试 52/52。当前状态：等待用户在 Windows 实机验证，验证顺序为在 micromacro.exe 控制台输入 rom-bot111/bot（不带 .lua 后缀）启动全链路，compat 加载、settings.load()、database.load() 都在 attach 连接游戏前执行，先确认无 [compat] 警告，之后再做 64 位地址重扫（CLIENT_EXE_START_ADDRESS 改为 0x140000000）与核心子系统回归。最大遗留风险是纯 Lua XML 解析器尚未实机验证。