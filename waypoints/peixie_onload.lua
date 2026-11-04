-- ============================================================
-- peixie_onload.lua  第二副本：进门选难度 + 打怪路线
-- 流程：进入副本 -> 走一段路 -> 点击门 -> 对话框选择难度
--       -> 门消失 -> 正常路线打怪 -> 打 Boss
-- 用法：由 peixie.xml 的 <onLoad> 通过 include() 加载
-- ============================================================

-- ========== 用户配置区（!!!!!! 请用 getid.lua 替换下面的模拟值 !!!!!!） ==========
local doorId   = "GateDoor" -- 难度选择门：对象ID或名称（模拟值，待替换，按NPC处理）
local bossId   = 5000001    -- 最终 Boss 的 ID（模拟值，待替换）
-- 难度选项文字：按实际对话框显示的选项文本填写（如 "Normal" / "Hard" / "精英"）
local diffText = "Hard"
-- ==========================================================================

-- ------------------------------------------------------------------
-- 点击门：按 NPC 对话处理（target_NPC 内部含 走近 + target + 双击交互）
-- 循环直到难度选择对话框（SpeakFrame）弹出
-- ------------------------------------------------------------------
function peixieOpenDoor()
    repeat
        -- target_NPC 等价于"点门"：找到门对象 -> 走近 -> 交互弹框
        player:target_NPC(doorId)
        yrest(800)
    until RoMScript("SpeakFrame:IsVisible()")
    cprintf(cli.green, "门对话框已打开\n")
end

-- ------------------------------------------------------------------
-- 难度选择：按 NPC 对话处理——遍历 SpeakFrame 选项，
-- 精确匹配难度文字后 ChoiceOption 选择，选完门消失即可继续前进
-- ------------------------------------------------------------------
function peixieChooseDifficulty()
    -- 等待对话框出现
    local dlDeadline = os.clock() + 10
    repeat
        yrest(500)
    until RoMScript("SpeakFrame:IsVisible()") or os.clock() > dlDeadline
    if not RoMScript("SpeakFrame:IsVisible()") then
        error("难度选择对话框未出现！")
    end

    -- 遍历选项，精确匹配难度文字
    local counter = 1
    local option
    local found = false
    repeat
        option = RoMScript("GetSpeakOption("..counter..")")
        if option then
            local norm = NormaliseString(option)
            if string.find(norm, diffText, 1, true) then
                RoMCode("ChoiceOption("..counter..");")
                found = true
                cprintf(cli.green, "已选择难度: %s\n", diffText)
                break
            end
        end
        counter = counter + 1
    until not option

    if not found then
        error(string.format("对话框中未找到难度选项: %s", diffText))
    end

    -- 等待门消失（对话框关闭即可继续）
    local doorDeadline = os.clock() + 10
    repeat
        yrest(500)
        -- 对话框关闭即认为难度已确认、门即将消失
        if not RoMScript("SpeakFrame:IsVisible()") then break end
    until os.clock() > doorDeadline
    yrest(2000)   -- 额外等待门消失动画
    cprintf(cli.green, "门已消失，开始前进\n")
end

-- ------------------------------------------------------------------
-- 沿路线打怪清理（走到每个战斗点后调用战斗逻辑）
-- 正常路线打怪交给 waypoint 默认战斗（NORMAL 类型自动战斗），
-- 此函数仅用于需要强制清怪的节点或打最终 Boss
-- ------------------------------------------------------------------
function peixieFightBoss()
    local gotBoss = false
    local fightDeadline = os.clock() + 180
    repeat
        if not player:target_Object(bossId) then
            yrest(2000)
        end
        player:fight()
        yrest(500)
    until not player:hasTarget() or os.clock() > fightDeadline
    cprintf(cli.green, "Boss 战斗结束\n")
end