--[[
	classes/xml.lua — MicroMacro 2.x 的纯 Lua XML 兼容库（64 位迁移补充）
	==================================================================
	背景：
		MicroMacro 1.05 内置 C++ 版 xml 库（xml.open / getElements / getAttribute /
		getValue / getName）；MicroMacro 2.x 已移除 xml 模块（api_probe 报告证实）。
		而 rom-bot 的 settings.xml / profiles/*.xml / waypoints/*.xml / database/*.xml
		全链路依赖 xml 解析。本文件提供功能等价的纯 Lua 实现，覆盖 rom-bot 全部使用面。

	支持的 API（与 1.05 语义对齐）：
		xml.open(filename)            -> 根元素对象 | nil（文件不存在或解析失败）
		元素对象方法：
			elem:getName()            -> 标签名
			elem:getAttribute(name)   -> 属性值字符串 | nil（缺失）
			elem:getValue()           -> 元素文本（CDATA 合并、首尾空白裁剪）| nil（无文本）
			elem:getElements()        -> 直接子元素数组（pairs 迭代）

	解析能力：
		- XML 声明（<?xml ...?>）与处理指令
		- 注释（<!-- -->）
		- CDATA 段（CDATA 内容原样保留，不做实体解码）
		- 自闭合标签（<tag attr="v"/>）
		- 单/双引号属性
		- 实体解码：&amp; &lt; &gt; &quot; &apos; 及数字实体 &#nn; / &#xhh;
		- 嵌套子元素与文本节点

	1.05 语义注意：
		- 缺失属性返回 nil（database.lua 用 v:getAttribute("x") or "" 兜底）
		- 无文本节点时 getValue() 返回 nil（waypointlist.lua 用 if( action ) 判断）
		- getValue() 裁剪首尾空白（CDATA 内联代码的缩进/换行不影响 loadstring）
--]]

-- ===================================================================
-- 实体解码表
-- ===================================================================
local xml = {};
local entities = {
	amp = "&", lt = "<", gt = ">", quot = '"', apos = "'",
};

-- 解码一段文本中的实体（含标准实体与数字实体）
local function decodeEntities(s)
	if( not s or s == "" ) then return s; end
	s = s:gsub("&(%a+);", function(name)
		return entities[name] or ("&" .. name .. ";");
	end);
	s = s:gsub("&#(%d+);", function(n)
		local c = tonumber(n);
		if( c and c >= 0 and c <= 0x10FFFF ) then
			return utf8 and utf8.char(c) or string.char(c);
		end
		return "&#" .. n .. ";";
	end);
	s = s:gsub("&#x([0-9a-fA-F]+);", function(h)
		local c = tonumber(h, 16);
		if( c and c >= 0 and c <= 0x10FFFF ) then
			return utf8 and utf8.char(c) or string.char(c);
		end
		return "&#x" .. h .. ";";
	end);
	return s;
end

-- ===================================================================
-- 元素对象
-- ===================================================================
local Element = {};
Element.__index = Element;

function Element:getName()
	return self.name;
end

function Element:getAttribute(name)
	return self.attrs and self.attrs[name] or nil;
end

function Element:getValue()
	if( not self.texts or #self.texts == 0 ) then return nil; end
	local s = table.concat(self.texts);
	s = s:gsub("^%s+", ""):gsub("%s+$", "");
	if( s == "" ) then return ""; end
	return s;
end

function Element:getElements()
	if( not self.children ) then self.children = {}; end
	return self.children;
end

-- ===================================================================
-- 递归下降解析器（字符串逐字符扫描，无模式匹配副作用）
-- ===================================================================
local Parser = {};

local function isNameChar(c)
	return c ~= nil
		and c ~= " " and c ~= "\t" and c ~= "\r" and c ~= "\n"
		and c ~= "/" and c ~= ">" and c ~= "=" and c ~= "<" and c ~= "'" and c ~= '"';
end

-- 跳过空白
local function skipWS(P)
	while P.pos <= P.len do
		local c = P.s:sub(P.pos, P.pos);
		if( c == " " or c == "\t" or c == "\r" or c == "\n" ) then
			P.pos = P.pos + 1;
		else
			break;
		end
	end
end

-- 跳过 XML 声明 / 处理指令 <?...?>
local function skipPI(P)
	if( P.s:sub(P.pos, P.pos + 1) ~= "<?" ) then return false; end
	local e = P.s:find("?>", P.pos + 2, true);
	if( e ) then
		P.pos = e + 2;
		return true;
	end
	return false;
end

-- 跳过注释 <!--...-->
local function skipComment(P)
	if( P.s:sub(P.pos, P.pos + 3) ~= "<!--" ) then return false; end
	local e = P.s:find("-->", P.pos + 4, true);
	if( e ) then
		P.pos = e + 3;
		return true;
	end
	return false;
end

-- 读取标签名（以空白、'/'、'>' 结尾）
local function readName(P)
	local start = P.pos;
	while P.pos <= P.len do
		local c = P.s:sub(P.pos, P.pos);
		if( not isNameChar(c) ) then break; end
		P.pos = P.pos + 1;
	end
	if( P.pos == start ) then return nil; end
	return P.s:sub(start, P.pos - 1);
end

-- 读取属性值（单引号或双引号包裹），返回解码后的字符串或 nil
local function readAttrValue(P)
	skipWS(P);
	local q = P.s:sub(P.pos, P.pos);
	if( q ~= '"' and q ~= "'" ) then return nil; end
	P.pos = P.pos + 1;
	local start = P.pos;
	while P.pos <= P.len do
		local c = P.s:sub(P.pos, P.pos);
		if( c == q ) then
			local v = P.s:sub(start, P.pos - 1);
			P.pos = P.pos + 1;
			return decodeEntities(v);
		end
		P.pos = P.pos + 1;
	end
	return nil; -- 未闭合：宽容处理
end

-- 解析属性列表，直到 '>' 或 '/>'。返回 attrs, selfClosing
local function parseAttributes(P)
	local attrs = {};
	local selfClosing = false;
	while P.pos <= P.len do
		skipWS(P);
		local c = P.s:sub(P.pos, P.pos);
		if( c == ">" ) then
			P.pos = P.pos + 1;
			break;
		elseif( c == "/" and P.s:sub(P.pos + 1, P.pos + 1) == ">" ) then
			P.pos = P.pos + 2;
			selfClosing = true;
			break;
		elseif( c == nil or c == "<" ) then
			break; -- 宽容：畸形输入
		end
		local key = readName(P);
		if( not key ) then break; end
		skipWS(P);
		if( P.s:sub(P.pos, P.pos) == "=" ) then
			P.pos = P.pos + 1;
			local v = readAttrValue(P);
			if( v ~= nil ) then
				attrs[key] = v;
			end
		else
			attrs[key] = "";
		end
	end
	return attrs, selfClosing;
end

-- 读取 CDATA 段内容（原样，不解码），返回文本或 nil
local function readCDATA(P)
	if( P.s:sub(P.pos, P.pos + 8) ~= "<![CDATA[" ) then return nil; end
	local e = P.s:find("]]>", P.pos + 9, true);
	if( not e ) then return nil; end
	local content = P.s:sub(P.pos + 9, e - 1);
	P.pos = e + 3;
	return content;
end

-- 解析一个元素（'<' 之后开始）。返回元素对象
local function parseElement(P)
	local name = readName(P);
	if( not name ) then return nil; end
	local attrs, selfClosing = parseAttributes(P);
	local elem = setmetatable({ name = name, attrs = attrs }, Element);
	if( selfClosing ) then
		return elem;
	end
	-- 解析内容：文本 / CDATA / 注释 / 子元素 / 结束标签
	local texts = {};
	local children = {};
	while P.pos <= P.len do
		local nextLt = P.s:find("<", P.pos);
		if( nextLt == nil ) then
			-- 没有更多标签：把剩余文本收尾（宽容：根未闭合）
			local rest = P.s:sub(P.pos);
			if( rest ~= "" ) then table.insert(texts, decodeEntities(rest)); end
			P.pos = P.len + 1;
			break;
		end
		if( nextLt > P.pos ) then
			table.insert(texts, decodeEntities(P.s:sub(P.pos, nextLt - 1)));
			P.pos = nextLt;
		end
		local seg = P.s:sub(P.pos);
		if( seg:sub(1, 4) == "<!--" ) then
			if( not skipComment(P) ) then break; end
		elseif( seg:sub(1, 9) == "<![CDATA[" ) then
			local cdata = readCDATA(P);
			if( cdata ) then
				table.insert(texts, cdata);
			else
				break;
			end
		elseif( seg:sub(1, 2) == "<?" ) then
			if( not skipPI(P) ) then break; end
		elseif( seg:sub(1, 2) == "</" ) then
			-- 结束标签：跳过 </name>
			local e = P.s:find(">", P.pos + 2, true);
			if( not e ) then break; end
			P.pos = e + 1;
			break;
		elseif( seg:sub(1, 1) == "<" ) then
			P.pos = P.pos + 1; -- 越过 '<'，进入子元素
			local child = parseElement(P);
			if( child ) then
				table.insert(children, child);
			else
				break;
			end
		else
			break;
		end
	end
	if( #texts > 0 ) then elem.texts = texts; end
	if( #children > 0 ) then elem.children = children; end
	return elem;
end

-- 解析整个文档，返回根元素对象（或 nil）
local function parseDocument(content)
	local P = setmetatable({ s = content, pos = 1, len = #content }, Parser);
	-- 跳过 UTF-8 BOM
	if( P.s:sub(1, 3) == "\239\187\191" ) then P.pos = 4; end
	-- 跳过序言：空白 / 声明 / 注释 / 处理指令
	local guard = 0;
	while P.pos <= P.len and guard < 64 do
		guard = guard + 1;
		skipWS(P);
		local seg = P.s:sub(P.pos);
		if( seg:sub(1, 2) == "<?" ) then
			if( not skipPI(P) ) then break; end
		elseif( seg:sub(1, 4) == "<!--" ) then
			if( not skipComment(P) ) then break; end
		else
			break;
		end
	end
	if( P.s:sub(P.pos, P.pos) ~= "<" ) then return nil; end
	P.pos = P.pos + 1;
	local root = parseElement(P);
	return root;
end

-- ===================================================================
-- xml.open(filename) -> 根元素对象 | nil
-- ===================================================================
function xml.open(filename)
	local f = io.open(filename, "rb");
	if( not f ) then return nil; end
	local content = f:read("*a");
	f:close();
	if( not content or content == "" ) then return nil; end
	return parseDocument(content);
end

-- 供内部测试/调试：直接解析字符串（工具脚本可选使用）
function xml.parseString(content)
	if( not content ) then return nil; end
	return parseDocument(content);
end

_G.xml = xml;