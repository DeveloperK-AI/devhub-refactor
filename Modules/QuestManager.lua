--!strict
-- QuestManager.lua - Logika Deep Sea, Element, Diamond, Temple Lever

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local QuestManager = {}

-- ============================================
-- DEPENDENCIES
-- ============================================
QuestManager._State = nil
QuestManager._Remote = nil
QuestManager._Utils = nil

function QuestManager:Init(State, Remote, Utils)
    self._State = State
    self._Remote = Remote
    self._Utils = Utils
end

-- ============================================
-- QUEST DATA HELPER (Baca UI Quest)
-- ============================================
local function getQuestData(questName: string)
    local gui = LocalPlayer:WaitForChild("PlayerGui")
    local questUI = gui:FindFirstChild("Quest")
    if not questUI then return nil end
    local list = questUI:FindFirstChild("List")
    if not list then return nil end
    local inside = list:FindFirstChild("Inside")
    if not inside then return nil end
    
    for _, child in pairs(inside:GetChildren()) do
        if child:IsA("Frame") and child.Name == "Quest" then
            local top = child:FindFirstChild("Top")
            if top then
                local header = top:FindFirstChild("TopFrame") and top.TopFrame:FindFirstChild("Header")
                if header and header.Text == questName then
                    local objectives = {}
                    local allDone = true
                    for i = 1, 10 do
                        local obj = child:FindFirstChild("Content") and child.Content:FindFirstChild("Objective" .. i)
                        if obj then
                            local check = obj:FindFirstChild("Content") and obj.Content:FindFirstChild("Check")
                            local completed = check and check:FindFirstChild("Vector") and check.Vector.Visible
                            local bar = obj:FindFirstChild("BarFrame")
                            local pct = 0
                            if bar then
                                local barFrame = bar:FindFirstChild("Bar")
                                local bg = bar:FindFirstChild("BG")
                                if barFrame and bg then
                                    pct = (barFrame.Size.X.Offset / bg.Size.X.Offset) * 100
                                end
                            end
                            table.insert(objectives, { completed = completed, percentage = pct })
                            if not completed then allDone = false end
                        end
                    end
                    return { name = header.Text, objectives = objectives, allCompleted = allDone }
                end
            end
        end
    end
    return nil
end

-- ============================================
-- TELEPORT BASED ON QUEST PROGRESS
-- ============================================
local function hasRod(uuid)
    return QuestManager._Utils.getRodUUID(uuid) ~= nil
end

function QuestManager:teleportBasedOnCondition()
    local state = self._State
    local utils = self._Utils
    local remote = self._Remote
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local startCFrame = CFrame.new(-544.096191, 16.055603, 116.168938)
    
    -- Deep Sea Quest
    if state.DeepSeaQuestMode then
        local data = getQuestData("Deep Sea Quest")
        local allDone = data and data.allCompleted
        if allDone or hasRod(169) then
            state.DeepSeaQuestMode = false
            hrp.CFrame = startCFrame
            return
        end
        local obj1 = data and data.objectives[1]
        local obj2 = data and data.objectives[2]
        local obj3 = data and data.objectives[3]
        if not (obj1 and obj1.completed) then
            hrp.CFrame = CFrame.new(-3600, -267, -1575) -- Treasure Room
        elseif not (obj2 and obj2.completed) or not (obj3 and obj3.completed) then
            hrp.CFrame = CFrame.new(-3729.25, -135.07, -885.64) -- Sisyphus
        end
        return
    end
    
    -- Element Quest
    if state.ElementQuestMode then
        local data = getQuestData("Element Quest")
        local allDone = data and data.allCompleted
        if allDone or hasRod(257) then
            state.ElementQuestMode = false
            hrp.CFrame = startCFrame
            return
        end
        local obj1 = data and data.objectives[1]
        if not (obj1 and obj1.completed) then
            hrp.CFrame = CFrame.new(2135.45, -91.20, -699.33) -- Cellar
        else
            hrp.CFrame = CFrame.new(1464.96, -22.37, -652.42) -- Temple
        end
        return
    end
    
    -- Diamond Quest
    if state.DiamondQuestMode then
        local data = getQuestData("Diamond Researcher")
        local allDone = data and data.allCompleted
        if allDone then
            state.DiamondQuestMode = false
            hrp.CFrame = startCFrame
            return
        end
        local obj2 = data and data.objectives[2]
        if not (obj2 and obj2.completed) then
            hrp.CFrame = CFrame.new(-3188.67749, 1.07282305, 2101.84595)
        else
            hrp.CFrame = CFrame.new(-2158.90967, 53.4871254, 3667.20703)
        end
        return
    end
    
    hrp.CFrame = startCFrame
end

-- ============================================
-- QUEST LOOPS (Dipanggil dari Loader)
-- ============================================
function QuestManager:startQuestLoops()
    task.spawn(function()
        while true do
            task.wait(3)
            local state = self._State
            if state.DeepSeaQuestMode or state.ElementQuestMode or state.DiamondQuestMode then
                self:teleportBasedOnCondition()
                -- Auto equp rod
                pcall(function()
                    local remote = self._Remote
                    remote.fireServer("UpdateAutoFishingState", true)
                    remote.fireServer("EquipToolFromHotbar", 1)
                end)
            end
        end
    end)
    
    -- Auto sell loop saat quest active
    task.spawn(function()
        while true do
            task.wait(5)
            local state = self._State
            if state.DeepSeaQuestMode or state.ElementQuestMode or state.DiamondQuestMode then
                pcall(function()
                    self._Remote.fireServer("SellAllItems")
                end)
            end
        end
    end)
end

return QuestManager