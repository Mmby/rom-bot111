---
name: 64bit-migration
type: project
scope: team
description: rom-bot 向 64 位客户端迁移并完全切换 MicroMacro 2.x（C++ 重写版）的活跃重构，迁移在 feature/micromacro-2x-64bit 分支进行、master 保持不动。api_probe.lua 报告已与 docs/micromacro-2x-src/ 源码注册...
created: "2026-11-05T00:32:41.374Z"
updated: "2026-11-06T06:35:06.450Z"
---
rom-bot 向 64 位客户端迁移并完全切换 MicroMacro 2.x（C++ 重写版）的活跃重构，迁移在 feature/micromacro-2x-64bit 分支进行、master 保持不动。api_probe.lua 报告已与 docs/micromacro-2x-src/ 源码注册表交叉核对并修复：原 probe() 用读值式闭包判存在性，缺失全局返回 nil 也会 pcall 成功，全部 'OK nil' 条目都是误报（Lua 5.4 下 loadstring、bit/bit32 库确实不存在），exists() 的 MISSING/FOUND 判定可靠；探针已改为 exists() 判定并补充 macro/system/log/event 表枚举。兼容层缺口已全部补齐并提交：新建 classes/xml.lua 纯 Lua XML 解析器（支持 CDATA、实体、自闭合、嵌套、单双引号属性），覆盖 settings.xml 与 database 各 XML 的 xml.open 调用；filesystem 全局别名导出；loadstring=load；mouseLClick/RClick/MClick；setStartKey/setStopKey/getStartKey/getStopKey 存值模拟；setPriority 数字转字符串映射；logMessage 映射 log.add；key 表补 A-Z/0-9 裸名别名。已确认的 2.x API 事实：Lua 5.4、key 表仅 VK_ 前缀名（鼠标键为 VK_LMOUSE/RMOUSE/MMOUSE）、system 表 9 成员、time 表 getNow/deltaTime/diff、log 表 log.add 带时间戳；compat 的 defineBitFunction 优先使用已有 bit 库的分支永不命中。本地验证全部通过（luac 语法、xml 功能测试 35/35、compat 模拟 2.x 环境加载 52/52），改动已提交。开发在 macOS 离线进行，实机验证由用户在 Windows 完成、尚未开始。下一步：Windows 实机先跑新 api_probe.lua 回传报告，再在 micromacro.exe 控制台运行 rom-bot111/bot（脚本名不带 .lua）验证启动链路——兼容层与 settings/database 的 XML 解析都在连接游戏前执行，纯 Lua 解析问题会提前暴露，同时确认无 [compat] 警告；通过后进入 64 位地址重扫（CLIENT_EXE_START_ADDRESS 改 0x140000000）及 addrtest/getid 子系统回归。