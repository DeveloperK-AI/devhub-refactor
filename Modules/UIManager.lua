--!strict
-- UIManager.lua - Membangun UI menggunakan devLib dan menghubungkan ke State

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local UIManager = {}

-- ============================================
-- DEPENDENCIES
-- ============================================
UIManager._State = nil
UIManager._Remote = nil
UIManager._Utils = nil
UIManager._Fishing = nil
UIManager._Quest = nil
UIManager._Auto = nil

function UIManager:Init(State, Remote, Utils, Fishing, Quest, Auto)
    self._State = State
    self._Remote = Remote
    self._Utils = Utils
    self._Fishing = Fishing
    self._Quest = Quest
    self._Auto = Auto
end

-- ============================================
-- BUILD UI
-- ============================================
function UIManager:Build()
    -- Load devLib UI Library
    local devLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/DeveloperK-AI/devhub-refactor/main/Libs/libdev.lua"))()
    
    local Window = devLib:CreateWindow({
        Name = "devHub Professional",
        Intro = true,
    })
    
    -- Simpan referensi ke Window untuk notifikasi
    _G.Core.UI = Window
    
    -- ==========================================
    -- TAB: MAIN (Fishing)
    -- ==========================================
    local MainTab = Window:CreateTab({ Name = "Main", Icon = "rod" })
    
    MainTab:CreateSection({ Name = "Fishing Mode" })
    MainTab:CreateDropdown({
        Name = "Mode",
        Items = { "Legit", "Instant" },
        Default = self._State.CurrentFishingMode,
        Callback = function(val)
            self._State.CurrentFishingMode = val
        end
    })
    
    MainTab:CreateToggle({
        Name = "Auto Farm",
        Default = self._State.AutoFarm,
        Callback = function(state)
            self._State.AutoFarm = state
            if state then
                if self._State.CurrentFishingMode == "Instant" then
                    self._Fishing:startUB()
                else
                    task.spawn(function() self._Fishing:legitFarmLoop() end)
                end
            else
                self._Fishing:stopUB()
                self._Remote.fireServer("UpdateAutoFishingState", false)
            end
        end
    })
    
    MainTab:CreateToggle({
        Name = "Auto Rod",
        Default = self._State.AutoRod,
        Callback = function(state)
            self._State.AutoRod = state
            if state then
                self._Remote.fireServer("EquipToolFromHotbar", 1)
            end
        end
    })
    
    MainTab:CreateSection({ Name = "Instant Fishing V2" })
    MainTab:CreateToggle({
        Name = "Enable Instant Fishing V2",
        Default = self._State.InstantFishingV2Active,
        Callback = function(state)
            self._State.InstantFishingV2Active = state
            if state then
                self._Fishing:startUB()
            else
                self._Fishing:stopUB()
            end
        end
    })
    
    MainTab:CreateInput({
        Name = "Complete Delay",
        Default = tostring(self._State.UB.Settings.CompleteDelay),
        Callback = function(val)
            local n = tonumber(val)
            if n and n > 0 then
                self._State.UB.Settings.CompleteDelay = n
            end
        end
    })
    
    MainTab:CreateSection({ Name = "Blatant V1" })
    MainTab:CreateToggle({
        Name = "Fast Reel",
        Default = self._State.BlatantMode,
        Callback = function(state)
            self._State.BlatantMode = state
            if state then
                task.spawn(function() self._Fishing:blatantSkipCycle() end)
            end
        end
    })
    
    MainTab:CreateSection({ Name = "Amblatant" })
    MainTab:CreateToggle({
        Name = "Amblatant YTTA",
        Default = self._State.Amblatant,
        Callback = function(state)
            self._State.Amblatant = state
            if state then
                self._Fishing:installNaturalHook()
                -- Hook remotes untuk saved data
                local remote = self._Remote
                remote.hookClientEvent("FishCaught", function(...)
                    self._State.SavedData.FishCaught = { ... }
                end)
                remote.hookClientEvent("CaughtFishVisual", function(...)
                    self._State.SavedData.CaughtVisual = { ... }
                end)
                remote.hookClientEvent("ObtainedNewFishNotification", function(...)
                    self._State.SavedData.FishNotif = { ... }
                end)
                self._Fishing:startUB()
            else
                self._Fishing:stopUB()
            end
        end
    })
    
    MainTab:CreateToggle({
        Name = "Instant Bobber",
        Default = false,
        Callback = function(state)
            self._Fishing:enableInstantBobber(state)
        end
    })
    
    -- ==========================================
    -- TAB: QUEST
    -- ==========================================
    local QuestTab = Window:CreateTab({ Name = "Quest", Icon = "scroll" })
    
    QuestTab:CreateParagraph({
        Title = "Deep Sea Quest",
        Content = "Status: Loading...",
        RichText = true
    })
    QuestTab:CreateToggle({
        Name = "Auto Deep Sea Quest",
        Default = self._State.DeepSeaQuestMode,
        Callback = function(state)
            self._State.DeepSeaQuestMode = state
            self._State.AutoDeepSeaQuest = state
            if state then
                self._Remote.fireServer("UpdateAutoFishingState", true)
            end
        end
    })
    
    QuestTab:CreateParagraph({
        Title = "Element Quest",
        Content = "Status: Loading...",
        RichText = true
    })
    QuestTab:CreateToggle({
        Name = "Auto Element Quest",
        Default = self._State.ElementQuestMode,
        Callback = function(state)
            self._State.ElementQuestMode = state
            self._State.AutoElementQuest = state
            if state then
                self._Remote.fireServer("UpdateAutoFishingState", true)
            end
        end
    })
    
    QuestTab:CreateParagraph({
        Title = "Diamond Researcher",
        Content = "Status: Loading...",
        RichText = true
    })
    QuestTab:CreateToggle({
        Name = "Auto Diamond Quest",
        Default = self._State.DiamondQuestMode,
        Callback = function(state)
            self._State.DiamondQuestMode = state
            self._State.AutoDiamondQuest = state
            if state then
                self._Remote.fireServer("UpdateAutoFishingState", true)
            end
        end
    })
    
    -- ==========================================
    -- TAB: AUTO
    -- ==========================================
    local AutoTab = Window:CreateTab({ Name = "Auto", Icon = "loop" })
    
    AutoTab:CreateSection({ Name = "Sell" })
    AutoTab:CreateToggle({
        Name = "Auto Sell",
        Default = self._State.AutoSell,
        Callback = function(state)
            if state then
                self._Auto:startAutoSell("Sell Delay", 2)
            else
                self._Auto:stopAutoSell()
            end
        end
    })
    
    AutoTab:CreateSection({ Name = "Enchant" })
    AutoTab:CreateDropdown({
        Name = "Stone Type",
        Items = { "Enchant Stones", "Evolved Enchant Stone" },
        Default = "Enchant Stones",
        Callback = function(val)
            self._State.SelectedStoneType = val
        end
    })
    AutoTab:CreateToggle({
        Name = "Auto Enchant",
        Default = self._State.AutoEnchant,
        Callback = function(state)
            if state then
                self._Auto:startAutoEnchant()
            else
                self._Auto:stopAutoEnchant()
            end
        end
    })
    
    AutoTab:CreateSection({ Name = "Totem" })
    AutoTab:CreateDropdown({
        Name = "Select Totem",
        Items = { "Luck Totem", "Shiny Totem", "Mutation Totem" },
        Default = "Luck Totem",
        Callback = function(val)
            self._State.SelectedTotem = val
        end
    })
    AutoTab:CreateToggle({
        Name = "Auto Totem",
        Default = self._State.AutoBuyTotem,
        Callback = function(state)
            if state then
                self._Auto:startAutoTotem(self._State.SelectedTotem or "Luck Totem")
            else
                self._Auto:stopAutoTotem()
            end
        end
    })
    
    AutoTab:CreateSection({ Name = "Crystal" })
    AutoTab:CreateToggle({
        Name = "Auto Use Cave Crystal",
        Default = false,
        Callback = function(state)
            self._State.AutoCrystal = state
            if state then
                task.spawn(function()
                    while self._State.AutoCrystal do
                        self._Remote.fireServer("ConsumeCaveCrystal")
                        task.wait(10)
                    end
                end)
            end
        end
    })
    
    AutoTab:CreateSection({ Name = "Event" })
    AutoTab:CreateToggle({
        Name = "Auto Lochnes Event",
        Default = self._State.AutoLochnesEvent,
        Callback = function(state)
            self._State.AutoLochnesEvent = state
            if state then
                task.spawn(function()
                    while self._State.AutoLochnesEvent do
                        pcall(function()
                            local label = workspace["!!! DEPENDENCIES"]["Event Tracker"].Main.Gui.Content.Items.Countdown.Label
                            local text = label.Text
                            local seconds = tonumber(text:match("(%d+)")) or 0
                            if seconds <= 10 then
                                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    hrp.CFrame = CFrame.new(6091.53711, -585.924316, 4643.58789)
                                    self._Remote.fireServer("ChargeFishingRod", nil, nil, Workspace:GetServerTimeNow(), nil)
                                    task.wait(0.5)
                                    self._Remote.fireServer("CatchFishCompleted", 1)
                                end
                            end
                        end)
                        task.wait(1)
                    end
                end)
            end
        end
    })
    
    -- ==========================================
    -- TAB: PLAYER
    -- ==========================================
    local PlayerTab = Window:CreateTab({ Name = "Player", Icon = "user" })
    PlayerTab:CreateInput({
        Name = "Walk Speed",
        Default = "18",
        Callback = function(val)
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = tonumber(val) or 18 end
        end
    })
    PlayerTab:CreateToggle({
        Name = "Infinite Jump",
        Default = self._State.InfiniteJump,
        Callback = function(state)
            self._State.InfiniteJump = state
            if state then
                game:GetService("UserInputService").JumpRequest:Connect(function()
                    if self._State.InfiniteJump then
                        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                    end
                end)
            end
        end
    })
    PlayerTab:CreateToggle({
        Name = "Noclip",
        Default = self._State.Noclip,
        Callback = function(state)
            self._State.Noclip = state
            task.spawn(function()
                while self._State.Noclip do
                    task.wait(0.1)
                    local char = LocalPlayer.Character
                    if char then
                        for _, part in pairs(char:GetDescendants()) do
                            if part:IsA("BasePart") then part.CanCollide = false end
                        end
                    end
                end
            end)
        end
    })
    
    -- ==========================================
    -- TAB: SETTINGS
    -- ==========================================
    local SettingsTab = Window:CreateTab({ Name = "Settings", Icon = "settings" })
    SettingsTab:CreateToggle({
        Name = "Anti AFK",
        Default = self._State.AntiAFK,
        Callback = function(state)
            self._State.AntiAFK = state
            local gc = getconnections or get_signal_cons
            if gc then
                for _, conn in pairs(gc(LocalPlayer.Idled)) do
                    if state then conn:Disable() else conn:Enable() end
                end
            end
        end
    })
    SettingsTab:CreateToggle({
        Name = "Anti Staff",
        Default = self._State.AntiStaffEnabled,
        Callback = function(state)
            self._State.AntiStaffEnabled = state
            if state then
                task.spawn(function()
                    while self._State.AntiStaffEnabled do
                        for _, p in pairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer then
                                local role = p:GetRoleInGroup(35102746)
                                if role ~= "Guest" and role ~= "Member" then
                                    self._Utils.serverHop("Staff detected: " .. p.Name, true)
                                    break
                                end
                            end
                        end
                        task.wait(5)
                    end
                end)
            end
        end
    })
    SettingsTab:CreateToggle({
        Name = "FPS Booster",
        Default = false,
        Callback = function(state)
            if state then
                self._Utils.FPSBooster.Enable()
            else
                self._Utils.FPSBooster.Disable()
            end
        end
    })
    SettingsTab:CreateToggle({
        Name = "Walk on Water",
        Default = false,
        Callback = function(state)
            if state then
                self._Utils.WalkOnWater.Start()
            else
                self._Utils.WalkOnWater.Stop()
            end
        end
    })
    
    -- ==========================================
    -- TAB: TELEPORT
    -- ==========================================
    local TeleportTab = Window:CreateTab({ Name = "Teleport", Icon = "gps" })
    local locations = {
        "Fisherman Island", "Crater Island", "Tropical Grove", "Coral Refs",
        "Ancient Jungle", "Sacred Temple", "Kohana", "Volcano"
    }
    TeleportTab:CreateDropdown({
        Name = "Location",
        Items = locations,
        Default = locations[1],
        Callback = function(val)
            self._selectedLocation = val
        end
    })
    TeleportTab:CreateButton({
        Name = "Teleport",
        Callback = function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local posMap = {
                    ["Fisherman Island"] = Vector3.new(74.03, 9.53, 2705.23),
                    ["Crater Island"] = Vector3.new(998.03, 2.86, 5151.17),
                    ["Tropical Grove"] = Vector3.new(-2152.61, 2.32, 3671.72),
                    ["Coral Refs"] = Vector3.new(-3181.39, 2.52, 2104.35),
                    ["Ancient Jungle"] = Vector3.new(1275.10, 3.91, -334.75),
                    ["Sacred Temple"] = Vector3.new(1451.41, -22.13, -635.65),
                    ["Kohana"] = Vector3.new(-661.68, 3.05, 714.14),
                    ["Volcano"] = Vector3.new(-541.52, 17.32, 121.67),
                }
                local pos = posMap[self._selectedLocation]
                if pos then hrp.CFrame = CFrame.new(pos) end
            end
        end
    })
    
    -- ==========================================
    -- TAB: CONFIG
    -- ==========================================
    local ConfigTab = Window:CreateTab({ Name = "Config", Icon = "settings" })
    ConfigTab:CreateButton({
        Name = "Save Config (JSON)",
        Callback = function()
            Window:SaveConfig("devHubConfigs", "default")
            Window:Notify({ Title = "Config", Content = "Saved!", Duration = 2 })
        end
    })
    ConfigTab:CreateButton({
        Name = "Load Config (JSON)",
        Callback = function()
            Window:LoadConfig("devHubConfigs", "default")
            Window:Notify({ Title = "Config", Content = "Loaded!", Duration = 2 })
        end
    })
end

return UIManager
