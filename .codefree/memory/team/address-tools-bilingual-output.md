---
name: address-tools-bilingual-output
type: project
scope: team
description: 本工具项目（address 模式查找/更新相关 Lua 脚本）的控制台输出约定为双语：保留英文原文并在其后追加中文，枚举类名称采用“英文 (中文)”形式。已按此约定完成 addrtest.lua（约 90 处）与 addrupdate.lua（约 25 处）；addresses.lua 是纯地址数据...
created: "2026-11-05T08:40:04.280Z"
updated: "2026-11-05T08:40:04.280Z"
---
本工具项目（address 模式查找/更新相关 Lua 脚本）的控制台输出约定为双语：保留英文原文并在其后追加中文，枚举类名称采用“英文 (中文)”形式。已按此约定完成 addrtest.lua（约 90 处）与 addrupdate.lua（约 25 处）；addresses.lua 是纯地址数据表、无打印语句，不需要此改动。中文输出依赖控制台 UTF-8 编码，Windows GBK 代码页下可能乱码，属预期现象而非缺陷。