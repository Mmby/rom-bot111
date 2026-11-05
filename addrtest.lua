include("micromacro_compat.lua");	-- 64 位迁移兼容层：必须在所有内存 API 模块之前加载
include('qword.lua');
include("addresses.lua");
include("database.lua");
include("functions.lua");
include("classes/player.lua");
include("classes/equipment.lua");
include("classes/inventory.lua");
include("classes/bank.lua");
include("classes/guildbank.lua");
include("classes/cursor.lua");
include("classes/camera.lua");
include("classes/waypoint.lua");
include("classes/waypointlist.lua");
include("classes/waypointlist_wander.lua");
include("classes/node.lua");
include("classes/object.lua");
include("classes/objectlist.lua");
include("classes/eggpet.lua");
include("classes/store.lua");
include("classes/party.lua");
include("classes/itemtypes.lua");
include("classes/pet.lua");
include("classes/memdatabase.lua");
include("classes/codemod.lua");
include("settings.lua");
include("macros.lua");

local logfile = io.open(getExecutionPath() .. '/addrtest-debug.txt', 'w')
function tee(...)
	log_debug(...)
	print(...)
end

function log_debug(...)
	for i,v in pairs(unpack2(...)) do
		local str = tostring(v):gsub("\\r", "");
		if( player ~= nil ) then
			-- Hide player's name from output
			str = str:gsub(player.Name, "<redacted>");
		end
		if( string.sub(str, -1) ~= "\n" ) then
			str = str .. ' '
		end

		logfile:write(str);
	end
	logfile:write("\n")
end

-- 打印内容中文翻译表：保持原有英文输出不变，同时追加中文翻译行
local zhTranslations = {};
for k,v in pairs{
	["State info"] = "状态信息",
	["Game version:"] = "游戏版本：",
	["Git revison:"] = "Git 修订版本：",
	["Player Info"] = "玩家信息",
	["Address:"] = "地址：",
	["Level:"] = "等级：",
	["Name:"] = "名字：",
	["Position:"] = "坐标：",
	["Class 1:"] = "职业1：",
	["Class 2:"] = "职业2：",
	["HP:"] = "生命值：",
	["MP:"] = "魔法值：",
	["MP2:"] = "魔法值2：",
	["Target:"] = "目标：",
	["Class Info"] = "职业信息",
	["Warrior:"] = "战士：",
	["Scout:"] = "斥候：",
	["Rogue:"] = "游侠：",
	["Mage:"] = "法师：",
	["Priest:"] = "牧师：",
	["Knight:"] = "骑士：",
	["Warden:"] = "守望者：",
	["Druid:"] = "德鲁伊：",
	["Warlock:"] = "术士：",
	["Champion:"] = "冠军：",
	["Player Buffs"] = "玩家增益状态",
	["Target Buffs"] = "目标增益状态",
	["Party"] = "队伍",
	["Craft Levels"] = "生活技能等级",
	["Blacksmithing:"] = "锻造：",
	["Carpentry:"] = "木工：",
	["Armorcrafting:"] = "制甲：",
	["Tailoring:"] = "裁缝：",
	["Cooking:"] = "烹饪：",
	["Alchemy:"] = "炼金：",
	["Mining:"] = "采矿：",
	["Woodcutting:"] = "伐木：",
	["Herbalism:"] = "草药：",
	["Game/Loading Check"] = "游戏/加载检查",
	["In-Game:"] = "游戏中：",
	["Loading:"] = "加载中：",
	["Casting"] = "施法",
	["Casting (Pawn):"] = "施法（通用单位）：",
	["Casting (Player):"] = "施法（玩家）：",
	["Harvesting:"] = "采集：",
	["Collecting Type"] = "采集类型：",
} do zhTranslations[k] = v; end

for k,v in pairs{
	["Equipment Info"] = "装备信息",
	["Ammo: "] = "弹药：",
	["Memdatabase"] = "内存数据库",
	["Attack skill address:"] = "攻击技能地址：",
	["Skill ID:"] = "技能ID：",
	["Skill Name:"] = "技能名：",
	["Texts"] = "游戏文本",
	["Inventory"] = "背包",
	["Item Shop Backpack"] = "商城背包",
	["Backpack(s)"] = "背包",
	["Item details"] = "物品详情",
	["Address"] = "地址",
	["ID"] = "ID",
	["Empty"] = "是否为空",
	["Location"] = "位置",
	["SlotNumber"] = "槽位号",
	["BagId"] = "背包ID",
	["Available"] = "是否可用",
	["Quality"] = "品质",
	["Color"] = "颜色",
	["BoundStatus"] = "绑定状态",
	["Bound"] = "已绑定",
	["InUse"] = "使用中",
	["CoolDownTime"] = "冷却时间",
	["ItemCount"] = "物品数量",
	["RequiredLvl"] = "需求等级",
	["Inventory rent"] = "背包租赁",
	["Bank"] = "银行",
	["Bank rent"] = "银行租赁",
	["Currency"] = "货币",
	["Currency name"] = "货币名称",
	["Amount"] = "数量",
	["Max Amount"] = "最大数量",
	["Phirus Shells:"] = "菲鲁斯贝壳：",
	["Energy of Justice:"] = "正义能量：",
	["Dreamland Pioneer:"] = "梦想先驱者：",
	["Peak Fragment:"] = "巅峰碎片：",
	["Stardust:"] = "星尘：",
	["Ancient Memento:"] = "古老纪念品：",
	["Proof of Myth:"] = "神话凭证：",
	["Mirror Shards:"] = "镜之碎片：",
	["Mirrorworld Tickets:"] = "镜界门票：",
	["Honor Points:"] = "荣誉点：",
	["Badges of the ...:"] = "徽章：",
	["Badge of the ...:"] = "徽章：",
	["Copper stomping ground:"] = "铜级演武场：",
	["Silver stomping ground:"] = "银级演武场：",
	["Object List"] = "对象列表",
	["Objects found:"] = "发现对象数：",
	["Cursor Item"] = "光标物品",
	["Cursor item ID:"] = "光标物品ID：",
	["Cursor item Bag ID:"] = "光标物品背包ID：",
	["Mount test"] = "坐骑测试",
	["Skills"] = "技能",
	["Code Mods"] = "代码修改",
	["Check Code In Memory"] = "检查内存中的代码",
	["Test if installable"] = "测试是否可安装",
} do zhTranslations[k] = v; end

function printHeader(name, padchar)
	local width = 79;
	local padchar = padchar or '=';
	local midpoint = math.ceil((width + #name)/2);
	local left = width - midpoint;
	local right = width - #name - left;

	tee(string.rep(padchar, left) .. name .. string.rep(padchar, right));

	-- 中文翻译：在标题下方追加一行相同格式的中文标题
	local zh = zhTranslations[name];
	if( zh ) then
		local zhMidpoint = math.ceil((width + #zh)/2);
		local zhLeft = width - zhMidpoint;
		local zhRight = width - #zh - zhLeft;
		tee(string.rep(padchar, zhLeft) .. zh .. string.rep(padchar, zhRight));
	end
end

function printLine(headWidth, header, ...)
	local rawHeader = tostring(header);
	header = sprintf("%" .. headWidth .. "s", header)
	tee(header, ...);

	-- 中文翻译：标签命中翻译表时，追加一行带相同数据的中文输出
	local zh = zhTranslations[rawHeader];
	if( zh ) then
		tee(sprintf("%" .. headWidth .. "s", zh), ...);
	end
end

function getClassName(classId)
	if( classId == nil ) then
		return "Nil";
	end

	if( classId == CLASS_NONE ) then
		return "none (无)";
	elseif( classId == CLASS_GM ) then
		return "GM (管理员)";
	elseif( classId == CLASS_WARRIOR ) then
		return "Warrior (战士)";
	elseif( classId == CLASS_SCOUT ) then
		return "Scout (斥候)"
	elseif( classId == CLASS_ROGUE ) then
		return "Rogue (游侠)";
	elseif( classId == CLASS_MAGE ) then
		return "Mage (法师)";
	elseif( classId == CLASS_PRIEST ) then
		return "Priest (牧师)"
	elseif( classId == CLASS_KNIGHT ) then
		return "Knight (骑士)";
	elseif( classId == CLASS_WARDEN ) then
		return "Warden (守望者)";
	elseif( classId == CLASS_DRUID ) then
		return "Druid (德鲁伊)";
	elseif( classId == CLASS_WARLOCK ) then
		return "Warlock (术士)";
	elseif( classId == CLASS_CHAMPION ) then
		return "Champion (冠军)";
	else
		return "Unknown class (未知职业) " .. classId;
	end
end

function getEquipSlotName(slotId)
	if( slotId == 0 ) then
		return "Head (头部)";
	elseif( slotId == 1 ) then
		return "Hands (手部)";
	elseif( slotId == 2 ) then
		return "Feet (脚部)";
	elseif( slotId == 3 ) then
		return "Upper body (上衣)";
	elseif( slotId == 4 ) then
		return "Lower body (下装)";
	elseif( slotId == 5 ) then
		return "Cape (披风)";
	elseif( slotId == 6 ) then
		return "Belt (腰带)";
	elseif( slotId == 7 ) then
		return "Shoulders (肩部)";
	elseif( slotId == 8 ) then
		return "Necklace (项链)";
	elseif( slotId == 9 ) then
		return "Ammo (弹药)";
	elseif( slotId == 10 ) then
		return "Ranged weapon (远程武器)";
	elseif( slotId == 11 ) then
		return "Ring 1 (戒指1)";
	elseif( slotId == 12 ) then
		return "Ring 2 (戒指2)";
	elseif( slotId == 13 ) then
		return "Earring 1 (耳环1)";
	elseif( slotId == 14 ) then
		return "earring 2 (耳环2)";
	elseif( slotId == 15 ) then
		return "Main hand (主手)";
	elseif( slotId == 16 ) then
		return "Offhand (副手)";
	elseif( slotId == 17 ) then
		return "Gathering tool (采集工具)";
	elseif( slotId == 18 ) then
		return "Amulet 1 (护符1)";
	elseif( slotId == 19 ) then
		return "Amulet 2 (护符2)";
	elseif( slotId == 20 ) then
		return "Amulet 3 (护符3)";
	elseif( slotId == 21 ) then
		return "Back/wings (背部/翅膀)";
	else
		return "Unknown slot (未知槽位) " .. (slotId or 'nil');
	end
end

local colWidth = 20;


printHeader("State info")
printLine(colWidth, "Game version:", getGameVersion());
printLine(colWidth, "Git revison:", getCurrentRevision());
tee("");

printHeader("Player Info");
player = CPlayer.new();
printLine(colWidth, "Address:", sprintf("0x%X", player.Address));
printLine(colWidth, "Level:", memoryReadInt(getProc(), player.Address + addresses.game_root.pawn.level));
printLine(colWidth, "Name:", player.Name);
printLine(colWidth, "Position:", sprintf("(%d, %d, %d)", player.X, player.Y, player.Z))
--print(sprintf("%" .. colWidth .. "s", "Name:"), player.Name);
printLine(colWidth, "Class 1:", getClassName(player.Class1) .. " lvl " .. player.Level);
printLine(colWidth, "Class 2:", getClassName(player.Class2) .. " lvl " .. player.Level2);
printLine(colWidth, "HP:", player.HP .. "/" .. player.MaxHP);
printLine(colWidth, "MP:", player.MP .. "/" .. player.MaxMP);
printLine(colWidth, "MP2:", player.MP2 .. "/" .. player.MaxMP2);
printLine(colWidth, "Target:", sprintf('0x%X', player.TargetPtr or 0) .. ' (' .. (player:getTarget().Id or 0) .. ')');
tee("");

printHeader("Class Info");
local classInfoBase = memoryReadUInt(getProc(), getBaseAddress(addresses.class_info.base)) + addresses.class_info.offset;
printLine(colWidth, "Warrior:", memoryReadInt(getProc(), classInfoBase + (addresses.class_info.size * (CLASS_WARRIOR - 1) + addresses.class_info.level)) or 'failed to read');
printLine(colWidth, "Scout:", memoryReadInt(getProc(), classInfoBase + (addresses.class_info.size * (CLASS_SCOUT - 1) + addresses.class_info.level)) or 'failed to read');
printLine(colWidth, "Rogue:", memoryReadInt(getProc(), classInfoBase + (addresses.class_info.size * (CLASS_ROGUE - 1) + addresses.class_info.level)) or 'failed to read');
printLine(colWidth, "Mage:", memoryReadInt(getProc(), classInfoBase + (addresses.class_info.size * (CLASS_MAGE - 1) + addresses.class_info.level)) or 'failed to read');
printLine(colWidth, "Priest:", memoryReadInt(getProc(), classInfoBase + (addresses.class_info.size * (CLASS_PRIEST - 1) + addresses.class_info.level)) or 'failed to read');
printLine(colWidth, "Knight:", memoryReadInt(getProc(), classInfoBase + (addresses.class_info.size * (CLASS_KNIGHT - 1) + addresses.class_info.level)) or 'failed to read');
printLine(colWidth, "Warden:", memoryReadInt(getProc(), classInfoBase + (addresses.class_info.size * (CLASS_WARDEN - 1) + addresses.class_info.level)) or 'failed to read');
printLine(colWidth, "Druid:", memoryReadInt(getProc(), classInfoBase + (addresses.class_info.size * (CLASS_DRUID - 1) + addresses.class_info.level)) or 'failed to read');
printLine(colWidth, "Warlock:", memoryReadInt(getProc(), classInfoBase + (addresses.class_info.size * (CLASS_WARLOCK - 1) + addresses.class_info.level)) or 'failed to read');
printLine(colWidth, "Champion:", memoryReadInt(getProc(), classInfoBase + (addresses.class_info.size * (CLASS_CHAMPION - 1) + addresses.class_info.level)) or 'failed to read');
tee("");

printHeader("Player Buffs");
player:updateBuffs()
if #player.Buffs == 0 then
	tee("No buffs")
	tee("无增益状态")
else
	for i,v in pairs(player.Buffs) do
		tee(i, v.Id, v.Name)
	end
end
tee("");

if( player.TargetPtr ~= nil and player.TargetPtr ~= 0 ) then
	printHeader("Target Buffs");
	if #player.Buffs == 0 then
		tee("No buffs")
		tee("无增益状态")
	else
		local target = player:getTarget()
		target:updateBuffs()
		for i,v in pairs(target.Buffs) do
			tee(i, v.Id, v.Name)
		end
	end
	tee("");
end

printHeader("Party");
for i = 1,6 do
	pcheck = GetPartyMemberAddress(i)
	if pcheck then
		member = CPawn(pcheck.Address)
		printLine(colWidth, member.Id, member.Name);
	end
end
tee("")

printHeader("Craft Levels");
local colWidth = 20;
printLine(colWidth, "Blacksmithing:", player:getCraftLevel(CRAFT_BLACKSMITHING));
printLine(colWidth, "Carpentry:", player:getCraftLevel(CRAFT_CARPENTRY));
printLine(colWidth, "Armorcrafting:", player:getCraftLevel(CRAFT_ARMORCRAFTING));
printLine(colWidth, "Tailoring:", player:getCraftLevel(CRAFT_TAILORING));
printLine(colWidth, "Cooking:", player:getCraftLevel(CRAFT_COOKING));
printLine(colWidth, "Alchemy:", player:getCraftLevel(CRAFT_ALCHEMY));
printLine(colWidth, "Mining:", player:getCraftLevel(CRAFT_MINING));
printLine(colWidth, "Woodcutting:", player:getCraftLevel(CRAFT_WOODCUTTING));
printLine(colWidth, "Herbalism:", player:getCraftLevel(CRAFT_HERBALISM));
tee("");


printHeader("Game/Loading Check");
printLine(colWidth, "In-Game:", isInGame())
printLine(colWidth, "Loading:", isLoading())
tee("")

printHeader("Casting")
CPawn.updateCasting(player)
printLine(colWidth, "Casting (Pawn):", player.Casting);
player:updateCasting()
printLine(colWidth, "Casting (Player):", player.Casting);
printLine(colWidth, "Harvesting:", player.Harvesting);
printLine(colWidth, "Collecting Type", player:getCollectingType());
tee("")


printHeader("Equipment Info");
equipment = CEquipment();

for i = 0,#equipment.BagSlot do
	local item = equipment.BagSlot[i];
	printLine(colWidth, getEquipSlotName(i), sprintf("0x%X\tID: %6d\tName: %s\tDura: %s/%s", item.Address, item.Id, item.Name, item.Durability, item.MaxDurability));
end
tee("")
printLine(colWidth, "Ammo: ", equipment.BagSlot[9].ItemCount)

tee("");
printHeader("Memdatabase");
attackId = 540000
attackAddress = GetItemAddress(attackId)
printLine(colWidth, "Attack skill address:", sprintf("0x%X", attackAddress or 0));
if( attackAddress ~= nil and attackAddress > 0 ) then
	skill = CItem()
	skill.Address = attackAddress
	skill:update()
	printLine(colWidth, "Skill ID:", skill.Id, "Expecting " .. attackId);
	printLine(colWidth, "Skill Name:", skill.Name);
end

tee("");
printHeader("Texts");
local expectations = {
	['AC_INSTRUCTION_01'] = 'AC command (Zone 81)',
	['AC_INSTRUCTION_02'] = 'Set season',
	['ZONE955_JOLIN_S1'] = 'Only I can sing on my stage!'
}
for i,key in pairs({'AC_INSTRUCTION_01', 'AC_INSTRUCTION_02', 'ZONE955_JOLIN_S1'}) do
	printLine(colWidth, key, sprintf("%-25s", getTEXT(key) or 'not found'), sprintf("%-25s", expectations[key]));
end

tee("\nLoading data for additional testing...");
tee("正在加载数据以进行附加测试...");
attach(getWin(player.Name));
include("/language/english.lua")
database.load();
settings.loadProfile("Default")

inventory = CInventory();
inventory:update()

tee("\n")
printHeader("Inventory");
tee("")
printHeader("Item Shop Backpack", ' ');
found = 0
for i = 0,49 do
	v = inventory.BagSlot[i]
	if( v and not v.Empty ) then
		printLine(colWidth, i, sprintf("ID: %-8d Count: %-5d %s", v.Id or 0, v.ItemCount or 0, v.Name));
		found = found + 1
	end
end
if( found == 0 ) then
	tee("No items were found in this inventory")
	tee("该背包中没有找到物品")
end

tee("\n")
printHeader("Backpack(s)", ' ');
found = 0;
local foundItem = nil;
for i = 60,239 do
	v = inventory.BagSlot[i]
	if( v and not v.Empty ) then
		if( foundItem == nil and v.Id == 200663) then
			-- We'll dump more details on this item later
			foundItem = v;
		end
		printLine(colWidth, i, sprintf("ID: %-8d Bound: %d Count: %-5d 0x%X  %s", v.Id or 0, v.Bound and 1 or 0, v.ItemCount or 0, v.Address, v.Name or ""));
		found = found + 1
	end
end
if( found == 0 ) then
	tee("No items were found in this inventory")
	tee("该背包中没有找到物品")
end

if( foundItem ) then
	tee("\n")
	printHeader("Item details", ' ');

	printLine(colWidth, 'Address', sprintf("0x%X", foundItem.Address));
	printLine(colWidth, 'ID', foundItem.Id);
	printLine(colWidth, 'Name', foundItem.Name);
	printLine(colWidth, 'Empty', foundItem.Empty);
	printLine(colWidth, 'Location', foundItem.Location);
	printLine(colWidth, 'SlotNumber', foundItem.SlotNumber);
	printLine(colWidth, 'BagId', foundItem.BagId);
	printLine(colWidth, 'Available', foundItem.Available);
	printLine(colWidth, 'Quality', foundItem.Quality);
	printLine(colWidth, 'Color', sprintf("0x%X", foundItem.Color));
	printLine(colWidth, 'BoundStatus', foundItem.BoundStatus);
	printLine(colWidth, 'Bound', foundItem.Bound);
	printLine(colWidth, 'InUse', foundItem.InUse);
	printLine(colWidth, 'CoolDownTime', foundItem.CoolDownTime);
	printLine(colWidth, 'ItemCount', foundItem.ItemCount);
	printLine(colWidth, 'RequiredLvl', foundItem.RequiredLvl);
end

tee("")
printHeader("Inventory rent", ' ')
for page = 3,6 do -- Pages 1 & 2 are free; always unlocked
	local tested = CInventoryItem.isPageAvailable(nil, page)
	printLine(colWidth, sprintf("Page %d", page), tested)
	printLine(colWidth, sprintf("第 %d 页", page), tested)
end


tee("\n")
printHeader("Bank", ' ');
bank = CBank()
found = 0
for i,v in pairs(bank.BagSlot) do
	if( v and not v.Empty ) then
		printLine(colWidth, i, sprintf("ID: %-8d Addr: 0x%x Count: %-5d %s", v.Id or 0, v.Address or 0, v.ItemCount or 0, v.Name));
		found = found + 1
	end
end
if( found == 0 ) then
	tee("No items were found in the bank")
	tee("银行中没有找到物品")
end

tee("")
printHeader("Bank rent", ' ')
for page = 2,5 do -- Page 1 is free; always unlocked
	local tested = CBankItem.isPageAvailable(nil, page)
	printLine(colWidth, sprintf("Page %d", page), tested)
	printLine(colWidth, sprintf("第 %d 页", page), tested)
end

tee("\n")
printHeader("Currency");

printLine(30, "Currency name", "Amount", "Max Amount")
printLine(30, "-------------", "------", "----------")
printLine(30, "Phirus Shells:", getCurrency("shell"));
printLine(30, "Energy of Justice:", getCurrency("eoj"))
printLine(30, "Dreamland Pioneer:", getCurrency("dreamland"))
printLine(30, "Peak Fragment:", getCurrency("peak_fragment"))
printLine(30, "Stardust:", getCurrency("stardust"))

printLine(30, "Ancient Memento:", getCurrency("mem"))
printLine(30, "Proof of Myth:", getCurrency("proof"))
printLine(30, "Mirror Shards:", getCurrency("mirror_shard"))
printLine(30, "Mirrorworld Tickets:", getCurrency("mirrorworld_ticket"))

printLine(30, "Honor Points:", getCurrency("honor"))
printLine(30, "Badges of the ...:", getCurrency("bott"))
printLine(30, "Badge of the ...:", getCurrency("botw"))
printLine(30, "Copper stomping ground:", getCurrency("copper_stomping_ground"))
printLine(30, "Silver stomping ground:", getCurrency("silver_stomping_ground"))


tee("")
printHeader("Object List");
local olist = CObjectList();
olist:update()
local displayCount = math.min(10, #olist.Objects)
printLine(colWidth, "Objects found:", #olist.Objects);
printLine(colWidth, sprintf("Top %d items", displayCount));
printLine(colWidth, sprintf("前 %d 个项目", displayCount));
for i = 1, displayCount do
	v = olist.Objects[i];
	local lootable = memoryReadRepeat("byte", getProc(), v.Address + addresses.game_root.pawn.lootable_flags) or -1;
	printLine(colWidth, i, sprintf("ID: %-8d Address: 0x%08x Type: %d Name: %s, Lootable: %d", v.Id or 0, v.Address or 0, v.Type or -1, v.Name or "", lootable));
end


tee("")
printHeader("Cursor Item");
local cursor = CCursor();
cursor:update()
printLine(colWidth, "Cursor item ID:", cursor.ItemId or '<invalid>');
printLine(colWidth, "Cursor item Bag ID:", cursor.ItemBagId or '<invalid>');


tee("")
printHeader("Mount test");
local mount, mountMethod = player:getMount();
if( mount ~= nil ) then
	tee("Mounting...");
	tee("正在骑乘坐骑...");
	player:mount()
	local start = os.time();
	repeat
		yrest(500);
		player:updateCasting()
		if( os.time() - start > 5 ) then
			player.Casting = false;
			tee("Took too long.")
			tee("耗时过长。")
		end
	until player.Casting == false

	tee("Dismounting...");
	tee("正在下马...");
	player:mount(true)
else
	tee("Could not find mount for player; skipping mount test.")
	tee("未找到玩家的坐骑，跳过坐骑测试。")
end

tee("");
printHeader("Skills");
settings.loadSkillSet(player.Class1)

getResourceName = function (skill)
	if skill.Mana > 0 then
		return "Mana";
	end

	if skill.Rage > 0 then
		return "Rage";
	end

	if skill.Energy > 0 then
		return "Energy";
	end

	if skill.Focus > 0 then
		return "Focus";
	end

	if skill.Nature > 0 then
		return "Nature";
	end

	if skill.Psi > 0 then
		return "Psi";
	end
end

tee("\n")
printf(" %-8s %-26s %-6s %-4s %-12s %-10s\n", "ID", "Name", "Level", "As", "Resource", "Hotkey");
printf(" %-8s %-26s %-6s %-4s %-12s %-10s\n", "ID", "名称", "等级", "副职", "资源", "快捷键");
for i,v in pairs(settings.profile.skills) do
	local resource = getResourceName(v)
	local amount = v[resource] or 0
	local resourceDesc = '---';
	if resource then
		resourceDesc = sprintf("%d %s", amount, resource or '--')
	end
	printf(" %-8d %-26s %-6d %-4d %-12s %-10s\n", v.Id, v.Name, v.Level, v.aslevel, resourceDesc, v.hotkey);
end

tee("")
printHeader("Code Mods");
printHeader("Check Code In Memory", ' ');
local installableCodemods = {}
for i,v in pairs(addresses.code_mod) do
	local codemod = CCodeMod(v.base,
		v.original_code,
		v.replace_code
	);

	if( codemod:checkModified() == false ) then
		cprintf_ex("%s|green|[+]|white| %s looks good\n", string.rep(" ", 12), i);
		cprintf_ex("%s|green|[+]|white| %s 状态正常\n", string.rep(" ", 12), i);
		log_debug(sprintf("%s looks good", i))
		installableCodemods[i] = codemod;
	else
		cprintf_ex("%s|red|[x]|white| %s appears malformed/modified\n", string.rep(" ", 12), i);
		cprintf_ex("%s|red|[x]|white| %s 异常/已被修改\n", string.rep(" ", 12), i);
		log_debug(sprintf("%s appears malformed/modified", i))
	end
end

tee("");
printHeader("Test if installable", ' ');
for i,codemod in pairs(installableCodemods) do
	local success = codemod:safeInstall();
	if( success ) then
		yrest(1000);
		success = codemod:safeUninstall();
		yrest(200);
	end

	if( success ) then
		cprintf_ex("%s|green|[+]|white| %s OK!\n", string.rep(" ", 12), i);
		cprintf_ex("%s|green|[+]|white| %s 测试通过!\n", string.rep(" ", 12), i);
		log_debug(sprintf("%s OK!", i))
	else
		cprintf_ex("%s|red|[x]|white| Failed\n", string.rep(" ", 12), i);
		cprintf_ex("%s|red|[x]|white| 失败\n", string.rep(" ", 12), i);
		log_debug(sprintf("%s Failed", i))
	end
end
