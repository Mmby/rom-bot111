--[[
	micromacro_compat.lua — MicroMacro 2.x 兼容层（64 位迁移核心）
	=================================================================
	目标：
		在 MicroMacro 2.x（64 位）运行时之上，恢复 1.05 时代项目依赖的
		全局函数签名，使 classes/、userfunctions/、工具脚本的调用点
		基本无需改动。同时将「指针宽度 4→8 字节」这一 64 位迁移的本质
		差异，集中在本文件一次性解决。

	适用范围：
		- 本文件面向 MicroMacro 2.x（1.9+ 系列，C++ 重写、支持 64 位进程）。
		- 若在 MicroMacro 1.05 下运行（无 _G.process 表），本文件自动 no-op，
		  不覆盖任何已有全局函数，便于迁移过渡期回溯对比。

	依据：
		- 官方 API 注册表（docs/micromacro-2x-src/src/*_lua.cpp）逐项核对：
		  process / keyboard / mouse / window / time / system / key / cli / macro。
		- 关键差异：2.x 进程 API 为 process.* 命名空间；内存读写统一走
		  process.read / process.write（类型字符串），指针链走 process.readPtr /
		  process.writePtr（自动按进程位数读取指针宽度，64 位即 8 字节）。
--]]

-- ===================================================================
-- 0. 运行环境判定：仅当 2.x（存在 process 表）且缺少 1.05 风格全局函数时启用。
-- ===================================================================
local isMm2x = (type(_G.process) == "table") and (type(_G.memoryReadInt) ~= "function");
if( not isMm2x ) then
	-- 1.05 或 2.x 已自带兼容函数：保持原样，本层不介入
	return;
end

local w = function(...)
	local t = { ... };
	for i = 1, select("#", ...) do t[i] = tostring(t[i]); end
	print("[compat]", table.concat(t, " "));
end

-- ===================================================================
-- 0.5 XML 兼容库：2.x 已移除 xml 模块（api_probe 报告证实），而
--     settings.xml / profiles/*.xml / waypoints/*.xml / database/*.xml
--     全链路依赖 xml.open()，此处加载纯 Lua 替代实现（classes/xml.lua）。
--     1.05 下本层已 no-op 返回，不会覆盖 MM 自带 xml。
-- ===================================================================
if( type(_G.xml) ~= "table" ) then
	-- 兼容「以 micromacro 目录为 CWD、用 rom/ 前缀启动」的情况
	local ok = false;
	for _, path in ipairs({ "classes/xml.lua", "rom/classes/xml.lua", "../rom/classes/xml.lua" }) do
		local ok1, err1 = pcall(dofile, path);
		if( ok1 and type(_G.xml) == "table" ) then
			ok = true;
			w("xml compat library loaded (" .. path .. ")");
			break;
		end
		ok = ok1;
	end
	if( not ok ) then
		w("WARNING: xml compat library load failed - settings/database/waypoint XML will not work");
	end
end

local proc = _G.process;

-- ===================================================================
-- 1. 内存读写（1.05 全局函数风格 -> process.* 命名空间）
--    官方签名：process.read(proc, "int"/"uint"/"float"/"double"/"byte"/"ubyte"/"string", address[, len])
--               process.write(proc, type, address, value[, len])
-- ===================================================================
local function bind(name, fn)
	if( type(fn) == "function" ) then return fn; end
	w("WARNING: process." .. name .. " missing, memory API degraded");
	return function() return nil; end;
end

local pr_read_int    = bind("read", proc.read);
local pr_read_uint   = bind("read", proc.read);
local pr_read_float  = bind("read", proc.read);
local pr_read_double = bind("read", proc.read);
local pr_read_byte   = bind("read", proc.read);
local pr_read_ubyte  = bind("read", proc.read);
local pr_read_string = bind("read", proc.read);
local pr_write       = bind("write", proc.write);

memoryReadInt    = function(procHandle, addr) return pr_read_int(procHandle, "int", addr); end;
memoryReadUInt   = function(procHandle, addr) return pr_read_uint(procHandle, "uint", addr); end;
memoryReadFloat  = function(procHandle, addr) return pr_read_float(procHandle, "float", addr); end;
memoryReadDouble = function(procHandle, addr) return pr_read_double(procHandle, "double", addr); end;
memoryReadByte   = function(procHandle, addr) return pr_read_byte(procHandle, "byte", addr); end;
memoryReadUByte  = function(procHandle, addr) return pr_read_ubyte(procHandle, "ubyte", addr); end;
-- 1.05 的 memoryReadString(proc, addr) 不带长度；官方 string 类型要求 length 参数，
-- 采用读取到 NUL 的安全上限（调用方如需精确长度可自行调整）。
memoryReadString = function(procHandle, addr, maxLen)
	if( type(maxLen) ~= "number" ) then maxLen = 256; end
	return pr_read_string(procHandle, "string", addr, maxLen);
end;

memoryWriteInt    = function(procHandle, addr, v) return pr_write(procHandle, "int", addr, v); end;
memoryWriteUInt   = function(procHandle, addr, v) return pr_write(procHandle, "uint", addr, v); end;
memoryWriteFloat  = function(procHandle, addr, v) return pr_write(procHandle, "float", addr, v); end;
memoryWriteDouble = function(procHandle, addr, v) return pr_write(procHandle, "double", addr, v); end;
memoryWriteByte   = function(procHandle, addr, v) return pr_write(procHandle, "byte", addr, v); end;
memoryWriteString = function(procHandle, addr, s)  return pr_write(procHandle, "string", addr, s); end;

-- 显式 64 位读取/写入原语（受控场景使用，例如 64 位金钱/大整数 id/指针）
memoryReadUInt64  = function(procHandle, addr) return pr_read_uint(procHandle, "uint64", addr); end;
memoryWriteUInt64 = function(procHandle, addr, v) return pr_write(procHandle, "uint64", addr, v); end;

-- ===================================================================
-- 2. 指针系列：官方 process.readPtr / writePtr
--    官方签名：process.readPtr(proc, type, address, offset(s))
--               process.writePtr(proc, type, address, offset(s), value)
--    offset 可为 number 或多层偏移表；官方按进程位数自动读取指针宽度
--    （64 位进程即 8 字节），这就是 64 位指针迁移的本质保证。
--    语义核对：官方循环 addr = *(addr) + off，与 1.05 的 *Ptr 系列一致。
-- ===================================================================
local pr_readPtr  = bind("readPtr", proc.readPtr);
local pr_writePtr = bind("writePtr", proc.writePtr);

-- 指针链读取：返回「最终指向的值」按目标类型读取。
-- 1.05 语义：memoryReadUIntPtr(proc, base, off) = 解引用 base 指针后 +off 再读值；
-- 官方 readPtr 中间层自动按进程位数读指针（64 位即 8 字节）。
-- 特别注意：64 位迁移下「指针字段」（玩家/对象/容器地址等）本身是 8 字节，
-- 因此 UIntPtr/IntPtr 最终层必须按 uint64/int64 读取，否则地址被截断为 4 字节。
function memoryReadUIntPtr(procHandle, base, offset)
	return pr_readPtr(procHandle, "uint64", base, offset);
end

function memoryReadIntPtr(procHandle, base, offset)
	return pr_readPtr(procHandle, "int64", base, offset);
end

function memoryReadFloatPtr(procHandle, base, offset)
	return pr_readPtr(procHandle, "float", base, offset);
end

function memoryReadDoublePtr(procHandle, base, offset)
	return pr_readPtr(procHandle, "double", base, offset);
end

function memoryReadBytePtr(procHandle, base, offset)
	return pr_readPtr(procHandle, "byte", base, offset);
end

-- memoryReadStringPtr：先沿指针链解引用到最终地址（64 位下指针 8 字节），再读字符串
function memoryReadStringPtr(procHandle, base, offset)
	local p = pr_readPtr(procHandle, "uint64", base, offset);
	if( p == nil or p == 0 ) then return nil; end
	return memoryReadString(procHandle, p);
end

-- 指针链写入：官方自动按进程位数解引用中间层；最终层与读取对称，用 8 字节类型
function memoryWriteIntPtr(procHandle, base, offset, v)
	return pr_writePtr(procHandle, "int64", base, offset, v);
end

function memoryWriteUIntPtr(procHandle, base, offset, v)
	return pr_writePtr(procHandle, "uint64", base, offset, v);
end

function memoryWriteFloatPtr(procHandle, base, offset, v)
	return pr_writePtr(procHandle, "float", base, offset, v);
end

function memoryWriteBytePtr(procHandle, base, offset, v)
	return pr_writePtr(procHandle, "byte", base, offset, v);
end

-- ===================================================================
-- 3. 进程 / 模块地址（官方 process 命名空间）
-- ===================================================================
local function ensureGlobal(name, fn)
	if( type(_G[name]) ~= "function" ) then
		_G[name] = fn;
	end
	return _G[name];
end

-- findByExe 官方仅返回「第一个匹配进程」的 pid（number 或 nil），
-- 而 1.05 的 findProcessByExeList 返回 pid 数组（functions.lua 用 #processList/pairs 迭代）。
-- 包装为数组语义：找到则 {pid}，未找到则 {}（nil 兼容 # 调用）。
ensureGlobal("findProcessByExeList", function(exe)
	local pid = proc.findByExe and proc.findByExe(exe);
	if( pid ) then
		return { pid };
	end
	return {};
end);

ensureGlobal("findProcessByWindow", function(hwnd)
	return proc.findByWindow(hwnd);
end);

ensureGlobal("openProcess", function(pid)
	return proc.open(pid);
end);

ensureGlobal("closeProcess", function(procHandle)
	if( type(proc.close) == "function" ) then
		return proc.close(procHandle);
	end
end);

-- getModuleAddress(procId, moduleName)：官方签名 (pid, modname)，模块名小写匹配
ensureGlobal("getModuleAddress", function(pid, modname)
	return proc.getModuleAddress(pid, modname);
end);

-- getBaseAddress/getProc 等由 functions.lua 基于上述原语实现，无需重复定义。

-- ===================================================================
-- 3.5 窗口 API（官方 window.* / process.getWindows）
--    官方签名：
--      window.find(title[, class]) -> hwnd|nil
--      window.findList(title[, class]) -> { {hwnd=,name=,class=}, ... }
--      window.getParent(hwnd) -> hwnd|nil
--      window.getTitle(hwnd) -> string|nil
--      window.setTitle(hwnd, title) -> boolean
--      window.getClassName(hwnd) -> string|nil
--      window.valid(hwnd) -> boolean
--      window.getRect(hwnd) -> x, y, w, h, showCmd   -- 注意：5 个返回值
--      window.setRect(hwnd, x, y, w, h)
--      window.show(hwnd, SW_*cmd) -> nil
--      window.saveScreenshot(hwnd, filename) -> nil
--      window.getAppHwnd() -> hwnd     -- MM 控制台窗口
--      window.getFocusHwnd() -> hwnd   -- 当前前台窗口
--      process.getWindows(pid) -> { {hwnd=,name=,class=}, ... }
--    1.05 差异：
--      - findWindowList / getWindowsFromProcess 返回「纯 hwnd 数组」，
--        2.x 返回「{hwnd=,name=,class=} 表数组」，此处统一转换回 hwnd 数组，
--        保证 functions.lua 的 #windowList / pairs 迭代逻辑不变。
--      - windowRect 官方多返回一个 showCmd，截断为 1.05 的四值语义。
--      - 1.05 的 getHwnd() 是 MM 控制台窗口句柄，对应官方 window.getAppHwnd()。
-- ===================================================================
local win = _G.window;
if( type(win) == "table" ) then
	-- 把 2.x 的 {hwnd=,name=,class=} 表数组转换为 1.05 风格的纯 hwnd 数组
	local function hwndArray(entries)
		local out = {};
		if( type(entries) == "table" ) then
			for i = 1, #entries do
				local e = entries[i];
				if( type(e) == "table" and e.hwnd ) then
					table.insert(out, e.hwnd);
				else
					table.insert(out, e);
				end
			end
		end
		return out;
	end

	ensureGlobal("findWindowList", function(title, cls)
		return hwndArray(win.findList(title, cls));
	end);
	ensureGlobal("findWindow", function(title, cls)
		return win.find(title, cls);
	end);
	ensureGlobal("getWindowsFromProcess", function(pid)
		if( type(proc.getWindows) == "function" ) then
			return hwndArray(proc.getWindows(pid));
		end
		return {};
	end);
	ensureGlobal("getWindowClassName", function(hwnd)
		return win.getClassName(hwnd);
	end);
	ensureGlobal("getWindowParent", function(hwnd)
		return win.getParent(hwnd);
	end);
	-- 截断官方第 5 个返回值 showCmd，保持 1.05 的 (x,y,w,h) 四值语义
	ensureGlobal("windowRect", function(hwnd)
		local x, y, w, h = win.getRect(hwnd);
		return x, y, w, h;
	end);
	ensureGlobal("windowValid", function(hwnd)
		return win.valid(hwnd);
	end);
	ensureGlobal("foregroundWindow", function()
		return win.getFocusHwnd();
	end);
	ensureGlobal("getForegroundWindow", function()
		return win.getFocusHwnd();
	end);
	ensureGlobal("getHwnd", function()
		return win.getAppHwnd();
	end);
	ensureGlobal("showWindow", function(hwnd, cmd)
		return win.show(hwnd, cmd);
	end);
	ensureGlobal("saveScreenshot", function(hwnd, filename)
		return win.saveScreenshot(hwnd, filename);
	end);
	ensureGlobal("setWindowTitle", function(hwnd, title)
		return win.setTitle(hwnd, title);
	end);
	ensureGlobal("setWindowName", function(hwnd, title)
		return win.setTitle(hwnd, title);
	end);
	ensureGlobal("getWindowTitle", function(hwnd)
		return win.getTitle(hwnd);
	end);

	-- createpath.lua 依赖的控制台尺寸 API：2.x 无直接对应，
	-- 用主窗口客户区宽高近似（仅辅助工具使用，不影响核心 bot 逻辑）。
	if( type(_G.getConsoleAttributes) ~= "function" and type(win.getClientRect) == "function" ) then
		getConsoleAttributes = function()
			local hwnd = win.getAppHwnd();
			if( hwnd ) then
				local x, y, w, h = win.getClientRect(hwnd);
				if( w and h ) then return w, h; end
			end
			return 80, 25; -- 控制台默认 80x25 兜底
		end;
		setConsoleAttributes = function() end; -- no-op：2.x 未提供设置接口
	end
else
	w("WARNING: window table missing");
end

-- ===================================================================
-- 3.7 filesystem 全局别名
--     1.05 的 getExecutionPath/fileExists/getDirectory/getOpenFileName/
--     fixSlashes/setExecutionPath 等是全局函数；2.x 全部移入 filesystem 表，
--     而 bot.lua/functions.lua/settings.lua/database.lua/工具脚本仍以
--     全局方式调用。此处统一导出（避免逐个调用点改写）。
-- ===================================================================
local fs = _G.filesystem;
if( type(fs) == "table" ) then
	local fsGlobals = {
		{ "getExecutionPath",  fs.getCWD },
		{ "setExecutionPath",  fs.setCWD },
		{ "fileExists",        fs.fileExists },
		{ "getDirectory",      fs.getDirectory },
		{ "directoryExists",   fs.directoryExists },
		{ "isDirectory",       fs.isDirectory },
		{ "fixSlashes",        fs.fixSlashes },
		{ "getOpenFileName",   fs.getOpenFileName },
		{ "getSaveFileName",   fs.getSaveFileName },
		{ "getFilePath",       fs.getFilePath },
		{ "getFileName",       fs.getFileName },
		{ "createDirectory",   fs.createDirectory },
	};
	for _, pair in ipairs(fsGlobals) do
		local gname, fn = pair[1], pair[2];
		if( type(_G[gname]) ~= "function" and type(fn) == "function" ) then
			_G[gname] = fn;
		end
	end
else
	w("WARNING: filesystem table missing - path/file globals unavailable");
end

-- ===================================================================
-- 4. 键盘 / 鼠标（官方 keyboard.* / mouse.* 命名空间）
--    官方签名：keyboard.press(vk [,async])、hold(vk)、release(vk)、getKeyName(vk)
--               mouse.press(vk [,async])、mouse.setPosition(x,y)、mouse.getPosition()
--    注意：2.x 无全局 keyboardPress/keyboardBufferClear，且 press 的第二参是 async(bool)，
--    与 1.05 的 keyboardPress(key, modifier) 不同——组合键由按键层自行处理。
-- ===================================================================
local kbd = _G.keyboard;
if( type(kbd) == "table" ) then
	-- 1.05 的 keyboardPress(key, modifier) 第二参是组合键（如 VK_SHIFT）；
	-- 官方 keyboard.press(vk, async) 第二参是布尔 async，语义不同，必须包装：
	-- 有 modifier 时先按住修饰键，再按主键，然后释放修饰键。
	keyboardPress = function(key, modifier)
		if( modifier ~= nil and type(modifier) == "number" and modifier ~= 0 and key ~= modifier ) then
			if( type(kbd.hold) == "function" ) then kbd.hold(modifier); end
			if( type(kbd.press) == "function" ) then kbd.press(key); end
			if( type(kbd.release) == "function" ) then kbd.release(modifier); end
		else
			if( type(kbd.press) == "function" ) then kbd.press(key); end
		end
	end;
	keyboardHold    = kbd.hold;
	keyboardRelease = kbd.release;
	if( type(_G.getKeyName) ~= "function" ) then
		getKeyName = kbd.getKeyName;
	end
	if( type(_G.keyPressed) ~= "function" ) then
		keyPressed = kbd.isDown;
	end
	-- keyPressedLocal：1.05 用于轮询「本地键盘」按键状态（functions.lua 选角色
	-- 用 keyPressedLocal(key.VK_UP/DOWN/RETURN)）；官方 keyboard.isDown 即等价。
	if( type(_G.keyPressedLocal) ~= "function" ) then
		keyPressedLocal = function(vk)
			return kbd.isDown(vk);
		end;
	end
	-- keyboardState：createpath.lua 依赖的全键盘状态表 {vk=bool}。
	-- 2.x 无一次性状态快照 API，遍历 key 表逐个 isDown 近似（低频辅助工具用）。
	-- 注意：2.x 的按键事件需 system.repollHid 刷新后再查询才准确。
	if( type(_G.keyboardState) ~= "function" ) then
		keyboardState = function()
			local st = {};
			local keyTab = _G.key;
			if( type(keyTab) == "table" ) then
				for _, vk in pairs(keyTab) do
					if( type(vk) == "number" ) then
						st[vk] = kbd.isDown(vk);
					end
				end
			end
			return st;
		end;
	end
	-- 2.x 按键缓冲模型与 1.05 不同：无键盘缓冲清理，no-op 占位
	keyboardBufferClear = function() end;
	keyboardSetDelay = function() end;
else
	-- [TODO-API] keyboard 表缺失
	w("WARNING: keyboard table missing");
end

local mse = _G.mouse;
if( type(mse) == "table" ) then
	-- 1.05 的 mouseClick(button) 以左键为主；官方无 click，用 press+release 组合
	-- 官方按键用 VK 码（VK_LBUTTON=1 / VK_RBUTTON=2 / VK_MBUTTON=4）
	mouseClick = function(button)
		local vk = button or 1;
		if( type(vk) == "string" ) then
			if( vk == "right" ) then vk = 2;
			elseif( vk == "middle" ) then vk = 4;
			else vk = 1; end
		end
		if( type(mse.press) == "function" ) then mse.press(vk); end
		if( type(mse.release) == "function" ) then mse.release(vk); end
	end;
	mouseSetPos = mse.setPosition;
	mouseGetPos = mse.getPosition;
	if( type(_G.mouseSet) ~= "function" and type(mse.setPosition) == "function" ) then
		mouseSet = mse.setPosition;
	end
	-- 1.05 内置全局 mouseLClick/mouseRClick/mouseMClick（2.x 已移除），
	-- 补充为 press+release 组合（VK 码：1 左键 / 2 右键 / 4 中键）。
	-- classes/player.lua target_NPC（3576-3580）与 CPlayer:mouseclick（3621-3626）依赖。
	if( type(_G.mouseLClick) ~= "function" ) then
		mouseLClick = function() mse.press(1); mse.release(1); end;
		mouseRClick = function() mse.press(2); mse.release(2); end;
		mouseMClick = function() mse.press(4); mse.release(4); end;
	end
else
	-- [TODO-API] mouse 表缺失
	w("WARNING: mouse table missing");
end

-- ===================================================================
-- 5. 时间 / 定时器 / 控制流
--    官方：time.getNow() / time.diff(t2,t1)（返回秒）
--    1.05 语义（关键单位换算）：
--      - getTime() 返回高精度单调时钟（时间戳）
--      - deltaTime(t2,t1) 返回毫秒差 —— 证据：
--        classes/skill.lua:790 计算秒时写 deltaTime(...) / 1000；
--        createpath.lua:802 以 > 500 做「每 500ms 一次」。
--    官方 time.diff 返回秒，因此 *1000 对齐毫秒语义。
-- ===================================================================
local tm = _G.time;
if( type(tm) == "table" ) then
	if( type(_G.getTime) ~= "function" and type(tm.getNow) == "function" ) then
		getTime = tm.getNow;
	end
	if( type(_G.deltaTime) ~= "function" and type(tm.diff) == "function" ) then
		-- 官方返回秒 -> 换算为 1.05 的毫秒语义
		deltaTime = function(t2, t1) return tm.diff(t2, t1) * 1000; end;
	end
else
	w("WARNING: time table missing");
end

-- ===================================================================
-- 5.2 开始/停止热键（1.05 全局 setStartKey/setStopKey/getStartKey/getStopKey）
--     2.x 无对应；模拟存值语义。bot.lua:123 启动即调用，
--     functions.lua pauseOnDeath、player.lua 睡眠唤起用 getStartKey()
--     配合 keyPressedLocal() 轮询。
-- ===================================================================
_G.startKey = nil;
_G.stopKey = nil;
if( type(_G.setStartKey) ~= "function" ) then
	setStartKey = function(k) _G.startKey = k; end;
	setStopKey  = function(k) _G.stopKey = k; end;
	getStartKey = function() return _G.startKey; end;
	getStopKey  = function() return _G.stopKey; end;
end

-- ===================================================================
-- 5.3 进程优先级（bot.lua:120 setPriority(priority.high)）
--     2.x 的 system.setPriority 接收字符串 "high"/"low"/"normal"，
--     1.05 传数字（priority.high=2 等，见 7 节 priority 兜底表），此处映射。
-- ===================================================================
local sysTab = _G.system;
if( type(_G.setPriority) ~= "function" ) then
	if( type(sysTab) == "table" and type(sysTab.setPriority) == "function" ) then
		local prioToStr = { ["0"] = "normal", ["1"] = "low", ["2"] = "high", ["3"] = "high" };
		setPriority = function(p)
			local s = prioToStr[tostring(p)] or "normal";
			return sysTab.setPriority(s);
		end;
	else
		setPriority = function() end; -- no-op 占位
	end
end
if( type(_G.getPriority) ~= "function" ) then
	getPriority = function() return nil; end; -- 2.x 无对应，占位
end

-- ===================================================================
-- 5.4 logMessage（1.05 写日志文件；2.x 为 log 表的 add，带时间戳）
--     bot.lua 91/107/188、settings.lua、classes/* 大量依赖。
-- ===================================================================
if( type(_G.logMessage) ~= "function" ) then
	local logTab = _G.log;
	if( type(logTab) == "table" and type(logTab.add) == "function" ) then
		logMessage = logTab.add;
	else
		logMessage = function(msg) print(tostring(msg)); end; -- 兜底：打印
	end
end

-- ===================================================================
-- 5.5 loadstring（Lua 5.4 已移除 loadstring；rom-bot 的 profile 事件 /
--     waypoint Action / 队伍代码加载全部依赖，等价替换为 load）
-- ===================================================================
if( type(_G.loadstring) ~= "function" and type(_G.load) == "function" ) then
	loadstring = function(chunk)
		return load(chunk);
	end;
end

-- ===================================================================
-- 5.6 key 裸键名别名（settings.lua:11 默认值用 _G.key.J 等无 VK_ 前缀形式；
--     2.x key 表只有 VK_* 名，补齐等价别名，不覆盖已有值）
-- ===================================================================
local keyTab = _G.key;
if( type(keyTab) == "table" ) then
	local plainNames = {};
	for i = 0, 9 do plainNames[#plainNames + 1] = tostring(i); end
	for c = string.byte("A"), string.byte("Z") do
		plainNames[#plainNames + 1] = string.char(c);
	end
	for _, nm in ipairs(plainNames) do
		if( keyTab[nm] == nil and type(keyTab["VK_" .. nm]) == "number" ) then
			keyTab[nm] = keyTab["VK_" .. nm];
		end
	end
end

-- 官方 system.rest(ms) 睡眠
local sys = _G.system;
if( type(sys) == "table" and type(sys.rest) == "function" ) then
	if( type(_G.yrest) ~= "function" ) then
		yrest = sys.rest;
	end
	if( type(_G.rest) ~= "function" ) then
		rest = sys.rest;
	end
elseif( type(_G.yrest) ~= "function" ) then
	w("WARNING: system.rest missing - yrest unavailable");
end

-- ===================================================================
-- 6. 位运算（1.05 为全局函数；2.x 无 bit/bit32，纯 Lua 兜底）
-- ===================================================================
local function trim32(n)
	return n % 4294967296;
end
local function luaBitAnd(a, b)
	a = trim32(a); b = trim32(b);
	local r = 0;
	for i = 0, 31 do
		if( a % 2 == 1 and b % 2 == 1 ) then r = r + 2 ^ i; end
		a = math.floor(a / 2); b = math.floor(b / 2);
	end
	return r;
end
local function luaBitOr(a, b)
	a = trim32(a); b = trim32(b);
	local r = 0;
	for i = 0, 31 do
		if( a % 2 == 1 or b % 2 == 1 ) then r = r + 2 ^ i; end
		a = math.floor(a / 2); b = math.floor(b / 2);
	end
	return r;
end
local function luaBitXor(a, b)
	a = trim32(a); b = trim32(b);
	local r = 0;
	for i = 0, 31 do
		if( (a % 2) ~= (b % 2) ) then r = r + 2 ^ i; end
		a = math.floor(a / 2); b = math.floor(b / 2);
	end
	return r;
end
local function luaBitNot(a)
	return luaBitXor(trim32(a), 0xFFFFFFFF);
end
local function luaBitLShift(a, n)
	a = trim32(a);
	return trim32(a * 2 ^ n);
end
local function luaBitRShift(a, n)
	a = trim32(a);
	return math.floor(a / 2 ^ n);
end

-- 优先使用已有的 bit 库/全局（若 2.x 提供），否则纯 Lua 兜底
local function defineBitFunction(globalName, impl)
	if( type(_G[globalName]) ~= "function" ) then
		_G[globalName] = impl;
	end
end
defineBitFunction("bitAnd",    luaBitAnd);
defineBitFunction("bitOr",     luaBitOr);
defineBitFunction("bitXor",    luaBitXor);
defineBitFunction("bitNot",    luaBitNot);
defineBitFunction("bitLShift", luaBitLShift);
defineBitFunction("bitRShift", luaBitRShift);

-- ===================================================================
-- 7. 常量表兜底（sw / priority / key / cli 若缺失给出最小定义）
-- ===================================================================
if( type(_G.sw) ~= "table" ) then
	-- 窗口显示状态常量（SW_*），与官方 window.show(hwnd, cmd) 第二参数对应
	sw = {
		hide = 0, normal = 1, show = 5, minimize = 6, restore = 9, maximize = 3,
	};
	_G.sw = sw;
end
if( type(_G.priority) ~= "table" ) then
	priority = { low = 1, normal = 0, high = 2, realtime = 3 }; -- 与 1.05 对齐的占位
	_G.priority = priority;
end

-- 颜色：1.05 的 cli.green 等是「颜色名->字符串」，配合 cprintf 使用；
-- 2.x 的 cli 为控制台函数表（setColor/getColor 等），颜色用数字属性。
-- 这里保留 cli 字符串常量表供 cprintf/print 类兼容；若 2.x 已带 cli 函数表，
-- 则合并（不覆盖函数）。
if( type(_G.cli) ~= "table" or not _G.cli.setColor ) then
	-- 纯字符串常量（1.05 风格）
	if( type(_G.cli) ~= "table" ) then
		cli = {
			green = "green", yellow = "yellow", red = "red", lightred = "lightred",
			lightblue = "lightblue", lightgray = "lightgray", turquoise = "turquoise",
			orange = "orange", white = "white", purple = "purple", darkgray = "darkgray",
		};
		_G.cli = cli;
	end
	-- 若 2.x cli 函数表存在（有 setColor 等），保持其函数，仅补颜色名常量
	local c2 = _G.cli;
	local colorNames = { "green", "yellow", "red", "lightred", "lightblue", "lightgray",
		"turquoise", "orange", "white", "purple", "darkgray" };
	for _, name in ipairs(colorNames) do
		if( type(c2[name]) ~= "string" and type(c2[name]) ~= "number" ) then
			c2[name] = name; -- 占位：以字符串形式传给 cprintf（见下）
		end
	end
	w("NOTE: cli 常量采用占位字符串；cprintf 若在 2.x 缺失将退化为 printf");
end

-- cprintf：1.05 的彩色打印（cli.green, fmt, ...）；2.x 无 cprintf 时退化为 printf
if( type(_G.cprintf) ~= "function" and type(_G.printf) == "function" ) then
	cprintf = function(color, fmt, ...)
		return _G.printf(fmt, ...);
	end;
end

-- key 常量表（VK_*）：2.x 自带完整 key 表（key.VK_*），这里仅做存在性检查
if( type(_G.key) ~= "table" ) then
	w("WARNING: key table missing");
end

-- ===================================================================
-- 8. 宏表 getVersion（2.x 中注册为 macro.getVersion，返回字符串）
--    1.05 的 getVersion() 返回数字（如 1.05）；bot.lua 校验依赖全局 getVersion。
-- ===================================================================
local macroTab = _G.macro;
if( type(macroTab) == "table" and type(macroTab.getVersion) == "function" ) then
	if( type(_G.getVersion) ~= "function" ) then
		-- 官方返回 "MAJOR.MINOR.BUILD"，此处解析为主版本数字（如 2.0.x -> 2.0）
		getVersion = function()
			local s = tostring(macroTab.getVersion());
			local major, minor = string.match(s, "^(%d+)%.(%d+)");
			if( major and minor ) then
				return tonumber(major) + tonumber(minor) / 100;
			end
			return tonumber(s) or 0;
		end;
	end
elseif( type(_G.getVersion) ~= "function" ) then
	w("WARNING: getVersion missing");
end

w("micromacro_compat.lua loaded (MicroMacro 2.x compatible layer active).");