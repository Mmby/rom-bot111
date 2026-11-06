---
name: 64bit-migration
type: project
scope: team
description: rom-bot 向 64 位客户端迁移、MicroMacro 升级到 2.x（1.9+，C++ 重写版）的活跃重构，方案已确认：完全切换 MicroMacro 2.x（64 位），只支持 64 位客户端，迁移在分支 feature/micromacro-2x-64bit 进行、master 保持不动...
created: "2026-11-05T00:32:41.374Z"
updated: "2026-11-06T01:24:12.407Z"
---
rom-bot 向 64 位客户端迁移、MicroMacro 升级到 2.x（1.9+，C++ 重写版）的活跃重构，方案已确认：完全切换 MicroMacro 2.x（64 位），只支持 64 位客户端，迁移在分支 feature/micromacro-2x-64bit 进行、master 保持不动。当前已完成 api_probe.lua 输出的报告与 docs/micromacro-2x-src/ 官方源码注册表的交叉核对，关键结论：报告用 probe() 判定的 "OK nil" 条目（如 loadstring、findFile、bit 相关）全是误报——probe 只读 _G 值而非真实调用，这些对象实际均不存在（Lua 5.4 环境）；exists() 判定的 MISSING/FOUND 可靠。兼容层 micromacro_compat.lua 待补的 P0 缺口：xml 库缺失且项目无 classes/xml.lua 替身（settings/database 依赖 xml.open，需移植纯 Lua XML 解析器，工作量最大）、filesystem 全局别名（getExecutionPath/fileExists 等）未导出、loadstring 需补 =load、mouseLClick/mouseRClick/mouseMClick 未补、setStartKey/setStopKey 等未补；P1 是 settings.lua 的 _G.key.J 应改 VK_J（2.x key 表只有 VK_J 无裸名）。纯 Lua 位运算兜底方向正确，但 defineBitFunction 的"优先使用已有 bit 库"分支永不命中。下一步：修 api_probe.lua（存在性检测改用 exists()，补 macro/system/time 表枚举，全覆盖 key 表），然后补兼容层 P0 缺口，再进入阶段 2 地址重扫验证。