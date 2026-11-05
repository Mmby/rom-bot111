--[[
	micro macro_compat.lua — MicroMacro 2.x 兼容层（64 位迁移核心）
	=================================================================
	目标：
		在 MicroMacro 2.x（64 位）运行时之上，恢复 1.05 时代项目依赖的
		全局函数签名，使 classes/、userfunctions/、工具脚本的调用点
		基本无需改动。同时将「指针宽度 4→8 字节」这一 64 位迁移的本质
		差异，集中在本文件一次性解决。

	适用范围：
		- 本文件面向 MicroMacro 2.x（含 1.9+ 系列，C++ 重写、支持 64 位进程）。
		- 若在 MicroMacro 1.05 下运行（无 _G.memory 表），本文件自动 no-op，
		  不覆盖任何已有全局函数，便于迁移过渡期回溯对比。

	状态说明：
		- 已按 MicroMacro 2.x 官方 API 方向实现的部分：内存读写、8 字节指针、
		  位运算、yrest/getTime/deltaTime 转发、键盘鼠标候选映射。
		- 标注 [TODO-API] 的部分依赖 api_probe.lua 的实测报告（Window/Process/
		  key 常量表等 2.x 具体命名），实测数据回来后再逐项补全。
--]]

-- ===================================================================
-- 0. 运行环境判定：仅当 2.x（存在 memory 表）且缺少 1.05 风格全局函数时启用。
--    若 2.x 原生已提供 memoryReadInt 等兼容函数，则本层不介入，避免重复定义。
-- ===================================================================
local isMm2x = (type(_G.memory) == "table") and (type(_G.memoryReadInt) ~= "function");
if( not isMm2x ) then
	-- 1.05 或 2.x 已自带兼容函数：保持原样，本层不介入
	return;
end

local mem = _G.memory;
local w = function(...)
	local t = { ... };
	for i = 1, select("#", ...) do t[i] = tostring(t[i]); end
	print("[compat]", table.concat(t, " "));
end

-- ===================================================================
-- 1. 8 字节指针读取原语（64 位迁移的本质工作）
--    64 位进程指针为 8 字节；1.05 的 *Ptr 系列均按 4 字节读取，必须替换。
-- ===================================================================
local readQWord;

if( type(mem.readUInt64) == "function" ) then
	readQWord = function(proc, addr) return mem.readUInt64(proc, addr); end;
elseif( type(mem.readPointer) == "function" ) then
	-- readPointer 按进程位数自动读取（64 位下即 8 字节）
	readQWord = function(proc, addr) return mem.readPointer(proc, addr); end;
elseif( type(mem.readBytes) == "function" ) then
	-- 兜底：readBytes 组合小端 8 字节（返回表或字符串均处理）
	readQWord = function(proc, addr)
		local bytes = mem.readBytes(proc, addr, 8);
		if( type(bytes) == "table" ) then
			local v = 0;
			for i = 1, 8 do
				v = v + ((bytes[i] or 0) * 2 ^ ((i - 1) * 8));
			end
			return v;
		elseif( type(bytes) == "string" and #bytes >= 8 ) then
			local v = 0;
			for i = 1, 8 do
				v = v + (string.byte(bytes, i) * 2 ^ ((i - 1) * 8));
			end
			return v;
		end
		return nil;
	end;
else
	w("WARNING: no 64-bit pointer read primitive available (need readUInt64/readPointer/readBytes)");
	readQWord = function() return nil; end;
end

-- ===================================================================
-- 2. 内存读写（1.05 全局函数风格 -> memory.* 命名空间）
-- ===================================================================
local function bind(f)
	if( type(f) == "function" ) then return f; end
	return nil;
end

memoryReadInt       = bind(mem.readInt) or function(proc, addr) return mem.readInt(proc, addr); end;
memoryReadUInt      = bind(mem.readUInt) or function(proc, addr) return mem.readUInt(proc, addr); end;
memoryReadFloat     = bind(mem.readFloat) or function(proc, addr) return mem.readFloat(proc, addr); end;
memoryReadDouble    = bind(mem.readDouble) or function(proc, addr) return mem.readDouble(proc, addr); end;
memoryReadByte      = bind(mem.readByte) or function(proc, addr) return mem.readByte(proc, addr); end;
memoryReadUByte     = bind(mem.readUByte) or memoryReadByte;
memoryReadString    = bind(mem.readString) or function(proc, addr) return mem.readString(proc, addr); end;
memoryWriteInt      = bind(mem.writeInt) or function(proc, addr, v) return mem.writeInt(proc, addr, v); end;
memoryWriteUInt     = bind(mem.writeUInt) or memoryWriteInt;
memoryWriteFloat    = bind(mem.writeFloat) or function(proc, addr, v) return mem.writeFloat(proc, addr, v); end;
memoryWriteDouble   = bind(mem.writeDouble) or memoryWriteFloat;
memoryWriteByte     = bind(mem.writeByte) or function(proc, addr, v) return mem.writeByte(proc, addr, v); end;
memoryWriteString   = bind(mem.writeString) or function(proc, addr, s) return mem.writeString(proc, addr, s); end;

-- ---- 指针系列：1.05 签名为 (proc, base, offset)，64 位下指针 8 字节 ----
-- 支持多层偏移表：offset = number 时读取 base+offset 处指针；
--                 offset = {a, b, c} 时依次解引用（如公会银行 {0xC4, 0x0}）。
local function resolvePtr(proc, base, offset)
	if( type(offset) == "table" ) then
		local addr = base;
		for _, off in ipairs(offset) do
			addr = readQWord(proc, addr + off);
			if( addr == nil or addr == 0 ) then return nil; end
		end
		return addr;
	end
	return readQWord(proc, base + (offset or 0));
end

function memoryReadUIntPtr(proc, base, offset)
	return resolvePtr(proc, base, offset);
end

function memoryReadIntPtr(proc, base, offset)
	return resolvePtr(proc, base, offset);
end

function memoryReadBytePtr(proc, base, offset)
	if( type(offset) == "table" ) then
		local addr = base;
		for i, off in ipairs(offset) do
			if( i == #offset ) then
				return memoryReadByte(proc, addr + off);
			end
			addr = readQWord(proc, addr + off);
			if( addr == nil or addr == 0 ) then return nil; end
		end
		return nil;
	end
	return memoryReadByte(proc, base + (offset or 0));
end

-- memoryReadStringPtr：先按指针解引用（支持多层偏移），再读字符串
function memoryReadStringPtr(proc, addr, offset)
	local p = resolvePtr(proc, addr, offset);
	if( p == nil or p == 0 ) then return nil; end
	return memoryReadString(proc, p);
end

function memoryWriteIntPtr(proc, base, offset, v)
	if( type(offset) == "table" ) then
		local addr = base;
		for i, off in ipairs(offset) do
			if( i == #offset ) then
				return memoryWriteUInt(proc, addr + off, v);
			end
			addr = readQWord(proc, addr + off);
			if( addr == nil or addr == 0 ) then return nil; end
		end
		return nil;
	end
	return memoryWriteUInt(proc, base + (offset or 0), v);
end

function memoryWriteFloatPtr(proc, base, offset, v)
	if( type(offset) == "table" ) then
		local addr = base;
		for i, off in ipairs(offset) do
			if( i == #offset ) then
				return memoryWriteFloat(proc, addr + off, v);
			end
			addr = readQWord(proc, addr + off);
			if( addr == nil or addr == 0 ) then return nil; end
		end
		return nil;
	end
	return memoryWriteFloat(proc, base + (offset or 0), v);
end

function memoryWriteBytePtr(proc, base, offset, v)
	if( type(offset) == "table" ) then
		local addr = base;
		for i, off in ipairs(offset) do
			if( i == #offset ) then
				return memoryWriteByte(proc, addr + off, v);
			end
			addr = readQWord(proc, addr + off);
			if( addr == nil or addr == 0 ) then return nil; end
		end
		return nil;
	end
	return memoryWriteByte(proc, base + (offset or 0), v);
end

-- 显式 64 位读取原语（受控场景使用，例如 64 位金钱/大整数 id）
memoryReadUInt64 = bind(mem.readUInt64);

-- ===================================================================
-- 3. 位运算（1.05 为全局函数；2.x 可能为 bit / bit32 库，缺失时纯 Lua 兜底）
-- ===================================================================
local function defineBitFunction(globalName, candidates)
	for _, cand in ipairs(candidates) do
		if( type(cand) == "function" ) then
			_G[globalName] = cand;
			return true;
		end
	end
	return false;
end

-- 纯 Lua 32 位位运算兜底（结果保持 32 位无符号语义）
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
local function luaBitLShift(a, n)
	a = trim32(a);
	return trim32(a * 2 ^ n);
end
local function luaBitRShift(a, n)
	a = trim32(a);
	return math.floor(a / 2 ^ n);
end

-- bit 库优先，其次 bit32，最后纯 Lua
local bitlib = _G.bit;
if( not defineBitFunction("bitAnd", { bitlib and bitlib.band, _G.bit32 and _G.bit32.band }) ) then
	bitAnd = luaBitAnd; _G.bitAnd = luaBitAnd;
end
if( not defineBitFunction("bitOr", { bitlib and bitlib.bor, _G.bit32 and _G.bit32.bor }) ) then
	bitOr = luaBitOr; _G.bitOr = luaBitOr;
end
if( not defineBitFunction("bitXor", { bitlib and bitlib.bxor, _G.bit32 and _G.bit32.bxor }) ) then
	bitXor = luaBitXor; _G.bitXor = luaBitXor;
end
if( not defineBitFunction("bitLShift", { bitlib and bitlib.lshift, _G.bit32 and _G.bit32.lshift }) ) then
	bitLShift = luaBitLShift; _G.bitLShift = luaBitLShift;
end
if( not defineBitFunction("bitRShift", { bitlib and bitlib.rshift, _G.bit32 and _G.bit32.rshift }) ) then
	bitRShift = luaBitRShift; _G.bitRShift = luaBitRShift;
end
if( not defineBitFunction("bitNot", { bitlib and bitlib.bnot, _G.bit32 and _G.bit32.bnot }) ) then
	function bitNot(a) return luaBitXor(trim32(a), 0xFFFFFFFF); end
	_G.bitNot = bitNot;
end

-- ===================================================================
-- 4. 时间 / 控制流（2.x 保留同名接口则直接复用）
-- ===================================================================
if( type(_G.yrest) ~= "function" ) then
	-- [TODO-API] 若 2.x 改名，依据 api_probe 报告修正
	w("WARNING: yrest missing");
end
if( type(_G.rest) ~= "function" ) then
	rest = _G.yrest;
end
if( type(_G.getTime) ~= "function" or type(_G.deltaTime) ~= "function" ) then
	w("WARNING: getTime/deltaTime missing");
end
if( type(_G.registerTimer) ~= "function" ) then
	w("WARNING: registerTimer missing");
end

-- ===================================================================
-- 5. 键盘 / 鼠标（2.x 为 keyboard.* / mouse.* 命名空间，做候选映射）
-- ===================================================================
local kbd = _G.keyboard;
if( type(kbd) == "table" ) then
	keyboardPress    = kbd.keyPress or kbd.press or keyboardPress;
	keyboardHold     = kbd.keyDown or kbd.keyHold or keyboardHold;
	keyboardRelease  = kbd.keyUp or kbd.keyRelease or keyboardRelease;
	keyboardBufferClear = kbd.keyBufferClear or kbd.bufferClear or keyboardBufferClear;
	keyboardSetDelay = kbd.setDelay or keyboardSetDelay;
	if( type(_G.keyPressed) ~= "function" ) then
		keyPressed = kbd.isPressed or kbd.keyPressed;
	end
	if( type(_G.getKeyName) ~= "function" ) then
		getKeyName = kbd.getKeyName or kbd.keyName;
	end
else
	-- [TODO-API] keyboard 表缺失：以 api_probe 报告为准补充
	w("WARNING: keyboard table missing");
end

local mse = _G.mouse;
if( type(mse) == "table" ) then
	mouseClick  = mse.click or mouseClick;
	mouseSetPos = mse.setPosition or mse.setPos or mouseSetPos;
	mouseGetPos = mse.getPosition or mse.getPos or mouseGetPos;
	if( type(_G.mouseSet) ~= "function" ) then
		mouseSet = mouseSetPos;
	end
else
	-- [TODO-API] mouse 表缺失
	w("WARNING: mouse table missing");
end

-- ===================================================================
-- 6. 进程 / 窗口（2.x 以对象/命名空间 API 为主，探测式适配）
--    [TODO-API] 以下各项请依据 api_probe.lua 实测报告逐条复核。
-- ===================================================================
local function ensureGlobal(name, fn)
	if( type(_G[name]) ~= "function" and type(fn) == "function" ) then
		_G[name] = fn;
	end
	return _G[name];
end

-- openProcess/closeProcess：2.x 若保留同名全局，直接使用
-- （返回 proc 对象，memory.* 函数可直接接受）

-- getModuleAddress(pid, moduleName) -> 模块基址（64 位地址）
if( type(_G.getModuleAddress) ~= "function" ) then
	ensureGlobal("getModuleAddress", function(pid, moduleName)
		local proc = _G.openProcess and _G.openProcess(pid);
		if( not proc ) then return nil; end
		if( type(proc.getModuleAddress) == "function" ) then
			return proc:getModuleAddress(moduleName);
		end
		if( type(proc.getBaseAddress) == "function" ) then
			return proc:getBaseAddress();
		end
		if( proc.baseAddress ~= nil ) then
			return proc.baseAddress;
		end
		return nil;
	end);
end

-- yrest 等保留检查由前面完成；窗口相关在此探测并给出提示
local winApiMissing = { "findWindowList", "findProcessByExeList", "findProcessByWindow",
	"getWindowsFromProcess", "getWindowClassName", "getWindowParent", "windowRect",
	"windowValid", "foregroundWindow", "showWindow", "saveScreenshot", "getHwnd" };
for _, name in ipairs(winApiMissing) do
	if( type(_G[name]) ~= "function" ) then
		w("WARNING [TODO-API]: " .. name .. " missing, will adapt after api_probe report");
	end
end

-- ===================================================================
-- 7. 常量表兜底（sw / priority / key / cli 若缺失给出最小定义）
-- ===================================================================
if( type(_G.sw) ~= "table" ) then
	-- 窗口显示状态常量（SW_*）
	sw = {
		hide = 0, normal = 1, show = 5, minimize = 6, restore = 9, maximize = 3,
	};
	_G.sw = sw;
end
if( type(_G.priority) ~= "table" ) then
	priority = { low = -1, normal = 0, high = 1, realtime = 2 };
	_G.priority = priority;
end
if( type(_G.cli) ~= "table" ) then
	cli = {
		green = "green", yellow = "yellow", red = "red", lightred = "lightred",
		lightblue = "lightblue", lightgray = "lightgray", turquoise = "turquoise",
		orange = "orange", white = "white", purple = "purple", darkgray = "darkgray",
	};
	_G.cli = cli;
end
-- key 常量表（VK_*）：2.x 通常自带；缺失时为常用键兜底，完整表以实测为准
if( type(_G.key) ~= "table" ) then
	w("WARNING: key table missing - applying minimal VK fallback [TODO-API]");
	local kt = {};
	local function add(name, vk) kt[name] = vk; end
	add("VK_ESCAPE", 0x1B); add("VK_RETURN", 0x0D); add("VK_SPACE", 0x20);
	add("VK_LSHIFT", 0xA0); add("VK_RSHIFT", 0xA1); add("VK_LCONTROL", 0xA2); add("VK_RCONTROL", 0xA3);
	add("VK_END", 0x23); add("VK_HOME", 0x24); add("VK_INSERT", 0x2D); add("VK_DELETE", 0x2E);
	add("VK_TAB", 0x09); add("VK_CAPITAL", 0x14);
	for i = 0, 9 do add("VK_" .. i, 0x30 + i); end
	for i = 0, 25 do add("VK_" .. string.char(string.byte("A") + i), 0x41 + i); end
	for i = 1, 12 do add("VK_F" .. i, 0x6F + i); end
	add("VK_UP", 0x26); add("VK_DOWN", 0x28); add("VK_LEFT", 0x25); add("VK_RIGHT", 0x27);
	key = kt; _G.key = kt;
end

w("micromacro_compat.lua loaded (MicroMacro 2.x compatible layer active).");