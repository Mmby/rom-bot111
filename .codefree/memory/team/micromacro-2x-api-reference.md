---
name: micromacro-2x-api-reference
type: reference
scope: team
description: "MicroMacro 2.x（1.9 以上，C++ 重写版）官方 API 参考的两个权威来源：官方 GitHub 仓库 https://github.com/SolarStrike-Software/micromacro 的 src/*_lua.cpp 是全部 API 模块注册表，最准确；官网文档 ..."
created: "2026-11-05T01:19:14.065Z"
updated: "2026-11-06T02:13:42.880Z"
---
MicroMacro 2.x（1.9 以上，C++ 重写版）官方 API 参考的两个权威来源：官方 GitHub 仓库 https://github.com/SolarStrike-Software/micromacro 的 src/*_lua.cpp 是全部 API 模块注册表，最准确；官网文档 https://documentation.solarstrike.net/micromacro 可供查阅。已经 api_probe 探测与本项目源码交叉确认的关键差异：2.x 运行于 Lua 5.4，无 loadstring、无 bit/bit32 库、无 xml 模块；key 表只有 VK_ 前缀常量（如 VK_J），没有裸名（如 J），鼠标键为 VK_LMOUSE/RMOUSE/MMOUSE；system 表含 setPriority 且参数是字符串（high/low/normal）；macro 表含 getVersion；log 表 log.add 输出带时间戳，对应 1.05 的 logMessage；time 表含 getNow/deltaTime/diff；memory 相关全局与 memory 表不复存在，内存读写走 process.read/write。

MicroMacro 2.x（1.9 以上，C++ 重写版）官方 API 参考的两个权威来源：官方 GitHub 仓库 https://github.com/SolarStrike-Software/micromacro%EF%BC%88src/*_lua.cpp 是全部 API 模块注册表，最准确），以及在线文档站 https://solarstrike.net/docs/micromacro%EF%BC%88%E6%A8%A1%E5%9D%97%E7%B4%A2%E5%BC%95%E5%AE%8C%E6%95%B4%E4%BD%86%E7%BD%91%E7%BB%9C%E4%B8%8D%E7%A8%B3%E5%AE%9A，建议保存本地副本）；项目已将官方仓库源码复制到 docs/micromacro-2x-src/ 作离线权威参考，兼容层与后续改造一律以此为准。按官方源码核对确认的 1.05 到 2.x 关键差异：无全局 memory 表与 memoryReadInt 等全局函数，进程/内存 API 全部在 process 表下以方法形式提供（read/write/readPtr/writePtr/getModuleAddress/findByExe/open 等）；process.readPtr 语义是 addr=*(addr)+off 循环且按进程位数自动取指针宽度，兼容层指针系列以此为基准并固定按 uint64 读最终层；process.findByExe 只返回单个 pid；window.findList 与 process.getWindows 返回 {hwnd,name,class} 表数组，window.getRect 返回 5 个值（含 showCmd），getAppHwnd/getFocusHwnd 对应旧 getHwnd/foregroundWindow；2.x 无全局 getVersion，版本号在 macro.getVersion 返回字符串；time.diff 返回秒而旧 deltaTime 返回毫秒（compat 需乘 1000 对齐）；keyboard.press 第二参是 async 而非组合键 modifier；mouse 无 click，须用 press+release 组合；system.rest 替代 yrest，system.repollHid 用于刷新 HID 缓冲避免按键状态陈旧。