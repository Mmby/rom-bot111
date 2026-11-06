--[[
	api_probe.lua — MicroMacro 2.x API 盘点工具（64 位迁移阶段 0）
	=============================================================
	用途：
		在 Windows + MicroMacro 2.x（64 位）环境下运行本脚本，枚举运行时实际
		提供的 API，与 1.05 时代项目依赖的 API 逐项比对，生成差异报告文件
		api_probe_report.txt，作为 micromacro_compat.lua 兼容层的施工图纸。

	运行方式：
		1. 将本项目目录拷贝到 Windows（与 micromacro 相同或任意目录）；
		2. 启动 64 位 micromacro.exe，命令行/控制台执行：
		   dofile("<项目路径>/api_probe.lua")
		   或直接打开后运行本文件；
		3. 将生成的 api_probe_report.txt 回传，用于后续兼容层实现。

	注意：
		- 本脚本不附加任何游戏进程、不做任何内存读写，纯只读枚举；
		- 需要游戏客户端运行时的探测（如 openProcess 返回结构）单独标注，
		  可配合 addrtest.lua 在客户端启动后执行。
--]]

local report = {};          -- 收集报告行
local function w(...)        -- 写报告行（同时回显到控制台）
	local line = "";
	for i = 1, select("#", ...) do
		line = line .. tostring(select(i, ...)) .. "\t";
	end
	table.insert(report, line);
	print(line);
end

local function wsep(title)
	w("================================================================");
	w("== " .. title);
	w("================================================================");
end

-- 存在性探测包装：输出 name = <nil>/<type>/<type:value>
local function probe(name, func)
	local ok, ret = pcall(func);
	if ok then
		local t = type(ret);
		if t == "number" or t == "string" or t == "boolean" then
			w(name .. " = OK", t, tostring(ret));
		else
			w(name .. " = OK", t);
		end
		return ret;
	else
		w(name .. " = FAIL", tostring(ret));
		return nil;
	end
end

local function exists(name, val)
	if val ~= nil then
		w(name .. " = FOUND", type(val));
	else
		w(name .. " = MISSING");
	end
	return val;
end

wsep("MicroMacro 版本与 Lua 环境");
-- 注意：probe() 只适用于「真正调用函数」的探测；「读全局值」的探测
-- 必须用 exists()，否则全局不存在时会输出误导性的 "OK nil"。
probe("getVersion()", function() return getVersion(); end);
probe("_VERSION", function() return _VERSION; end);
exists("loadstring（Lua 5.4 已移除，改用 load）", _G.loadstring);
exists("load", _G.load);
exists("class", _G.class);
exists("include", _G.include);
exists("dofile", _G.dofile);
exists("findFile", _G.findFile);
probe("getExecutionPath()", function() return getExecutionPath(); end);
-- macro 表：2.x 的 getVersion/is64bit/is32bit/fireEvent 均注册于此
exists("macro（宏表）", _G.macro);
if( type(_G.macro) == "table" ) then
	w("macro 表全部成员：");
	for k, v in pairs(_G.macro) do
		w("  macro." .. tostring(k), type(v));
	end
end

wsep("位运算（1.05 为全局函数；2.x 无 bit/bit32 模块，Lua 5.4 也无内置 bit32）");
exists("bitAnd", _G.bitAnd);
exists("bitOr", _G.bitOr);
exists("bitXor", _G.bitXor);
exists("bitLShift", _G.bitLShift);
exists("bitRShift", _G.bitRShift);
exists("bitNot", _G.bitNot);
exists("bit 库", _G.bit);
exists("bit32 库", _G.bit32);

wsep("内存读写 API（全局函数式，1.05 风格）");
local memFunctions = {
	"memoryReadInt", "memoryReadUInt", "memoryReadFloat", "memoryReadDouble", "memoryReadByte", "memoryReadUByte",
	"memoryReadString", "memoryReadStringPtr", "memoryReadIntPtr", "memoryReadUIntPtr", "memoryReadBytePtr",
	"memoryReadRepeat", "memoryWriteInt", "memoryWriteUInt", "memoryWriteFloat", "memoryWriteDouble",
	"memoryWriteByte", "memoryWriteString", "memoryWriteIntPtr", "memoryWriteFloatPtr", "memoryWriteBytePtr",
	"memoryRead", "memoryWrite",
};
for _, name in ipairs(memFunctions) do
	exists(name, _G[name]);
end

wsep("内存读写 API（memory 表，2.x 命名空间化风格）");
local mem = _G.memory;
if type(mem) == "table" then
	for _, name in ipairs({
		"readInt", "readUInt", "readFloat", "readDouble", "readByte", "readUByte",
		"readString", "readStringPtr", "readIntPtr", "readUIntPtr", "readBytePtr",
		"readPointer", "readBytes", "readUInt64", "readInt64", "readQWord",
		"writeInt", "writeUInt", "writeFloat", "writeDouble", "writeByte", "writeUByte",
		"writeString", "writeIntPtr", "writeFloatPtr", "writeBytePtr", "writePointer", "writeBytes",
		"open", "close",
	}) do
		exists("memory." .. name, mem[name]);
	end
	-- 枚举 memory 表内所有键（含未列出的自定义/扩展 API）
	w("memory 表全部成员：");
	for k, v in pairs(mem) do
		w("  memory." .. tostring(k), type(v));
	end
else
	w("memory 全局对象类型 = " .. type(mem) .. "（非 table，按函数式 API 处理）");
end

wsep("进程 API");
local procFunctions = {
	"openProcess", "closeProcess", "getModuleAddress", "findProcessByExeList", "findProcessByWindow",
	"findProcessByName", "getProcessId", "getProcessHandle", "createProc", "getWinProcessList",
	"process", "getCurrentProcess", "getProc",
};
for _, name in ipairs(procFunctions) do
	exists(name, _G[name]);
end
if type(_G.process) == "table" then
	w("process 表全部成员：");
	for k, v in pairs(_G.process) do
		w("  process." .. tostring(k), type(v));
	end
end

wsep("窗口 API");
local winFunctions = {
	"findWindow", "findWindowList", "findWindowByTitle", "getWindowsFromProcess",
	"getWindowClassName", "getWindowParent", "windowRect", "windowValid", "windowList",
	"foregroundWindow", "getForegroundWindow", "getHwnd", "showWindow", "saveScreenshot",
	"activateWindow", "getWin", "window", "sendMouse", "setWindowTitle",
};
for _, name in ipairs(winFunctions) do
	exists(name, _G[name]);
end
if type(_G.window) == "table" then
	w("window 表全部成员：");
	for k, v in pairs(_G.window) do
		w("  window." .. tostring(k), type(v));
	end
end
exists("sw 常量表（sw.show 等）", _G.sw);
if type(_G.sw) == "table" then
	for k, v in pairs(_G.sw) do
		w("  sw." .. tostring(k), tostring(v));
	end
end

wsep("键盘 API");
local keyFunctions = {
	"keyboardPress", "keyboardHold", "keyboardRelease", "keyboardBufferClear",
	"keyboardSetDelay", "keyPressed", "getKeyName", "getStartKey", "getStopKey",
	"setStartKey", "setStopKey", "keyboard", "key",
};
for _, name in ipairs(keyFunctions) do
	exists(name, _G[name]);
end
if type(_G.keyboard) == "table" then
	w("keyboard 表全部成员：");
	for k, v in pairs(_G.keyboard) do
		w("  keyboard." .. tostring(k), type(v));
	end
end
exists("key 常量表（key.VK_XXX）", _G.key);
if type(_G.key) == "table" then
	local cnt = 0;
	for k, v in pairs(_G.key) do
		if cnt < 5 then w("  key." .. tostring(k), tostring(v)); end
		cnt = cnt + 1;
	end
	w("  key 表成员总数 = " .. cnt);
end

wsep("鼠标 API");
local mouseFunctions = {
	"mouseClick", "mouseSetPos", "mouseGetPos", "mouseSet", "mouseGet", "mouse",
};
for _, name in ipairs(mouseFunctions) do
	exists(name, _G[name]);
end
if type(_G.mouse) == "table" then
	w("mouse 表全部成员：");
	for k, v in pairs(_G.mouse) do
		w("  mouse." .. tostring(k), type(v));
	end
end

wsep("时间 / 定时器 / 控制流 API");
local timeFunctions = {
	"yrest", "rest", "getTime", "deltaTime", "getTimer", "registerTimer", "unregisterTimer",
	"secondsToTimer", "setPriority", "getPriority", "priority",
};
for _, name in ipairs(timeFunctions) do
	exists(name, _G[name]);
end
-- time 表：2.x 的时间 API 命名空间（getNow/deltaTime/diff）
if( type(_G.time) == "table" ) then
	w("time 表全部成员：");
	for k, v in pairs(_G.time) do
		w("  time." .. tostring(k), type(v));
	end
end
if( type(_G.priority) == "table" ) then
	w("priority 常量表：");
	for k, v in pairs(_G.priority) do
		w("  priority." .. tostring(k), tostring(v));
	end
end

wsep("日志 / 输出 / 文件工具 API");
local miscFunctions = {
	"printf", "sprintf", "cprintf", "cli", "logMessage", "showWarnings", "warning",
	"getDirectory", "fileExists", "getConsoleAttributes", "setExecutionPath",
	"getLastWarning", "setUtf8", "getUtf8",
};
for _, name in ipairs(miscFunctions) do
	exists(name, _G[name]);
end
if type(_G.cli) == "table" then
	w("cli 颜色表成员：");
	for k, v in pairs(_G.cli) do
		w("  cli." .. tostring(k), type(v));
	end
end

wsep("系统 / 日志 / 事件库（兼容层依赖 system.rest / log.add / event 表）");
exists("system", _G.system);
if( type(_G.system) == "table" ) then
	w("system 表全部成员：");
	for k, v in pairs(_G.system) do
		w("  system." .. tostring(k), type(v));
	end
end
exists("log", _G.log);
if( type(_G.log) == "table" ) then
	w("log 表全部成员：");
	for k, v in pairs(_G.log) do
		w("  log." .. tostring(k), type(v));
	end
end
exists("event", _G.event);
if( type(_G.event) == "table" ) then
	w("event 表全部成员：");
	for k, v in pairs(_G.event) do
		w("  event." .. tostring(k), type(v));
	end
end

wsep("XML / 其它库");
for _, name in ipairs({ "xml", "image", "timer", "memory", "settings", "pair", "filesystem", "fs" }) do
	exists(name, _G[name]);
end
if type(_G.xml) == "table" then
	w("xml 表全部成员：");
	for k, v in pairs(_G.xml) do
		w("  xml." .. tostring(k), type(v));
	end
end
if type(_G.filesystem) == "table" then
	w("filesystem 表全部成员：");
	for k, v in pairs(_G.filesystem) do
		w("  filesystem." .. tostring(k), type(v));
	end
end

wsep("全局限量枚举（名称含关键子串的函数/表）");
local keywords = { "memory", "window", "process", "key", "mouse", "yrest", "time", "timer", "prio", "screenshot", "version", "macro", "system", "log", "event", "xml", "filesystem", "cli" };
for gname, gval in pairs(_G) do
	local gn = tostring(gname);
	for _, kw in ipairs(keywords) do
		if string.find(string.lower(gn), kw) ~= nil then
			w("[GLOBAL]", gn, type(gval));
			break;
		end
	end
end

wsep("附加说明（需游戏客户端运行时的探测项）");
w("1. openProcess(pid) 的返回结构：待客户端运行时用 addrtest.lua 探测", "proc.pid / proc.handle / proc.baseAddress / proc:getModuleAddress() 等");
w("2. 2.x 中 createProc 需要管理员权限：详见官方文档");
w("3. 上述 memory.*Ptr 各函数如 2.x 缺失，兼容层用 memory.readPointer/writePointer 组合实现");

-- 报告输出目录：1.05 有全局 getExecutionPath()；2.x 若缺失则退回当前工作目录
-- （MicroMacro 启动脚本时会把工作目录切到脚本所在目录）
local function reportDir()
	if type(getExecutionPath) == "function" then
		return getExecutionPath();
	end
	return ".";
end

-- 写报告文件（UTF-8，便于 IDE 查看）
local outFile = io.open(reportDir() .. "/api_probe_report.txt", "w");
if outFile then
	for _, line in ipairs(report) do
		outFile:write(line, "\n");
	end
	outFile:close();
	print("\n报告已写入: " .. reportDir() .. "/api_probe_report.txt");
else
	print("\n警告：无法写入报告文件（请确认当前目录可写）。");
end