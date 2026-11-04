-- ============================================================
-- gubao_onload.lua  副本开门机制
-- 流程：击杀精英怪 -> 安全拾取掉落卡片 -> /kcg 从系统消息获取9位密码
--       -> 与开门NPC逐层对话选择 0~9 -> 选完自动开门
-- 用法：由 gubao.xml 的 <onLoad> 通过 include() 加载
-- 依赖：ingamefunctions 事件插件（EventMonitor* 系列函数）
-- ============================================================

-- ========== 用户配置区（!!!!!! 请用 getid.lua 替换下面的模拟值 !!!!!!） ==========
local eliteId  = 1000001  -- 精英怪 ID（模拟值，待替换）
local cardId   = 2000001  -- 精英怪掉落卡片物品 ID（模拟值，待替换）
local npcName  = 3000001  -- 开门 NPC 的 ID 或名称（模拟值，待替换）
-- ==========================================================================

-- 强制开启拾取：player:loot() 依赖 LOOT 开关，不开则永不拾取
settings.profile.options.LOOT = true
settings.profile.options.LOOT_ALL = true

-- ------------------------------------------------------------------
-- 按 ID 精确查找附近可拾取的精英怪尸体（避免捡到别的小怪尸体）
-- 参考 bot.lua 中 getNearbyLoot 的写法，增加 Id == eliteId 过滤
-- ------------------------------------------------------------------
local function getEliteLoot()
    local objList = CObjectList()
    objList:update()
    local closest, closestDist = nil, 200
    for i, v in pairs(objList.Objects) do
        if v.Id and v.Id > 0 then
            local pawn = CPawn(v.Address)
            pawn:update()
            if pawn.Type == PT_MONSTER and pawn.Lootable and pawn.Id == eliteId then
                local d = distance(player.X, player.Z, player.Y, pawn.X, pawn.Z, pawn.Y)
                if d < closestDist then
                    closest, closestDist = pawn, d
                end
            end
        end
    end
    return closest
end

-- ------------------------------------------------------------------
-- 精确选择当前对话层中等于 digit 的数字选项
-- 注意：不用项目自带的 ChoiceOptionByName（它是子串匹配，会误选），
--       而是遍历 GetSpeakOption 取文本中独立出现的数字精确比对。
-- ------------------------------------------------------------------
local function choiceDigit(digit)
    if not RoMScript("SpeakFrame:IsVisible()") then
        return false
    end
    local counter = 1
    local option
    repeat
        option = RoMScript("GetSpeakOption("..counter..")")
        if option then
            local d = string.match(NormaliseString(option), "(%d)")
            if d == digit then
                RoMCode("ChoiceOption("..counter..");")
                yrest(1200)   -- 等待对话刷新到下一层
                return true
            end
        end
        counter = counter + 1
    until not option
    return false
end

-- ------------------------------------------------------------------
-- 击杀精英怪并安全拾取卡片
-- 1) 找到并击杀精英怪
-- 2) 清空附近正在攻击我们的怪，直到脱离战斗才去拾取
-- 3) 精确拾取精英怪尸体（按 ID）
-- 4) 循环直到卡片入包（120秒超时保护）
-- ------------------------------------------------------------------
function gubaoKillElite()
    local gotCard = false
    local fightDeadline = os.clock() + 120
    repeat
        if not player:target_Object(eliteId) then
            yrest(3000)
        end
        player:fight()

        -- 清空附近仇恨怪，直到安全（findEnemy 第1参 true = 只找正在攻击我们的）
        local safeDeadline = os.clock() + 60
        repeat
            player:updateBattling()
            if not player.Battling and not player:findEnemy(true, nil, evalTargetDefault) then
                break
            end
            player:fight()
            yrest(1000)
        until os.clock() > safeDeadline

        -- 安全后，精确拾取精英怪尸体
        local lootable = getEliteLoot()
        if lootable then
            player:target(lootable.Address)
            player:moveTo(CWaypoint(lootable.X, lootable.Z), true, false, 50)
            yrest(300)
            lootable:update()
            if lootable:exists() and lootable.Lootable then
                player:loot()
                yrest(300)
            end
        end

        inventory:update()
        if inventory:itemTotalCount(cardId) > 0 then
            gotCard = true
        end
    until gotCard or os.clock() > fightDeadline

    if not gotCard then
        error("卡片未在120秒内拾取到！请检查 eliteId / cardId 配置。")
    end
    cprintf(cli.green, "卡片拾取成功！\n")
end

-- ------------------------------------------------------------------
-- 执行 /kcg 并从系统消息（CHAT_MSG_SYSTEM）抓取 9 位纯数字密码
-- ------------------------------------------------------------------
local function getPassword()
    SlashCommand("/kcg")
    EventMonitorStop("kcgMsg")
    EventMonitorStart("kcgMsg", "CHAT_MSG_SYSTEM")

    local pwd
    local deadline = os.clock() + 10
    repeat
        local time, more, name, msg = EventMonitorCheck("kcgMsg", "4,1")
        if time and msg then
            pwd = string.match(msg, "(%d%d%d%d%d%d%d%d%d)")  -- 恰好9位数字
            if pwd then
                cprintf(cli.green, "密码: %s\n", pwd)
            end
        end
        yrest(500)
    until pwd or os.clock() > deadline
    EventMonitorStop("kcgMsg")

    if not pwd then
        error("未能从 /kcg 输出读取到9位密码！")
    end
    return pwd
end

-- ------------------------------------------------------------------
-- 与开门NPC逐层对话，按密码每一位依次选择 0~9 选项
-- 密码共9位，选完最后一位后 NPC 自动开门
-- ------------------------------------------------------------------
function gubaoOpenDoor()
    local pwd = getPassword()

    for i = 1, 9 do
        local digit = pwd:sub(i, i)
        -- 若对话未打开，先锁定开门 NPC
        if not RoMScript("SpeakFrame:IsVisible()") then
            repeat
                player:target_NPC(npcName)
                yrest(800)
            until RoMScript("SpeakFrame:IsVisible()")
        end
        cprintf(cli.yellow, "第 %d 层: 选择 %s\n", i, digit)
        if not choiceDigit(digit) then
            error(string.format("第 %d 层未找到选项 %s！", i, digit))
        end
    end

    cprintf(cli.green, "===== 开门完成！=====\n")
    yrest(3000)
end