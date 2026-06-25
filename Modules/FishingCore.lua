--!strict
-- FishingCore.lua - Semua logika fishing (Instant, Legit, Blatant, UB, Amblatant)

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local FishingCore = {
    _loopTask = nil,
    _isRunning = false,
    _notifHooked = false,
}

-- PI untuk kalkulasi casting
local PI = math.pi
local CAST_MODE_LIST = { "Perfect", "Fast", "Random" }

-- ============================================
-- DEPENDENCIES (diisi oleh Loader)
-- ============================================
FishingCore._State = nil
FishingCore._Remote = nil
FishingCore._Utils = nil

function FishingCore:Init(State, Remote, Utils)
    self._State = State
    self._Remote = Remote
    self._Utils = Utils
end

-- ============================================
-- HELPERS
-- ============================================
local function getPowerAtTime(chargeTime: number, elapsed: number): number
    local speed = Random.new(chargeTime):NextInteger(4, 10)
    local angle = PI / 2 + elapsed * speed
    return (1 - math.sin(angle)) / 2
end

local function waitForPower(chargeTime: number, threshold: number)
    local deadline = chargeTime + 2.0
    while Workspace:GetServerTimeNow() < deadline do
        local elapsed = Workspace:GetServerTimeNow() - chargeTime
        local power = getPowerAtTime(chargeTime, elapsed)
        if power >= threshold then return elapsed, power end
        task.wait(0.001)
    end
    local elapsed = Workspace:GetServerTimeNow() - chargeTime
    return elapsed, getPowerAtTime(chargeTime, elapsed)
end

local function handleCastMode(t0: number): number
    local state = FishingCore._State
    local mode = state.UB.Settings.CastMode
    
    if mode == "Perfect" then
        local _, power = waitForPower(t0, 0.97)
        return power
    elseif mode == "Random" then
        local randomElapsed = math.random(0, 100) / 100 * (PI / 4)
        task.wait(randomElapsed)
        local elapsed = Workspace:GetServerTimeNow() - t0
        return getPowerAtTime(t0, elapsed)
    else -- Fast
        local elapsed = Workspace:GetServerTimeNow() - t0
        return getPowerAtTime(t0, elapsed)
    end
end

local function safeInvoke(remote, ...)
    if not remote then return end
    local args = { ... }
    task.spawn(function()
        pcall(function() remote:InvokeServer(unpack(args)) end)
    end)
end

local function safeFire(remote, ...)
    if not remote then return end
    task.spawn(function()
        pcall(function() remote:FireServer(...) end)
    end)
end

-- ============================================
-- HOOK NOTIFICATION DELAY (Untuk Instant Fishing V2)
-- ============================================
function FishingCore:_hookNotificationDelay()
    if self._notifHooked then return end
    
    local ok, controller = pcall(function()
        return require(game:GetService("ReplicatedStorage").Controllers.TextNotificationController)
    end)
    if not ok or not controller then return end
    
    local originalDeliver = controller.DeliverNotification
    controller.DeliverNotification = function(self, data, ...)
        if self._State.HookNotif and data then
            data.CustomDuration = 15
        end
        return originalDeliver(self, data, ...)
    end
    self._notifHooked = true
end

-- ============================================
-- INSTANT FISHING V2 (UB - Ultra Blatant)
-- ============================================
function FishingCore:startLoop()
    if self._isRunning then return end
    self._isRunning = true
    local state = self._State
    local remote = self._Remote
    
    local RF_Charge = remote.getRemote("ChargeFishingRod")
    local RF_StartMini = remote.getRemote("RequestFishingMinigameStarted")
    local RE_CatchDone = remote.getRemote("CatchFishCompleted")
    
    while state.UB.Active do
        local t0 = Workspace:GetServerTimeNow()
        safeInvoke(RF_Charge, nil, nil, t0, nil)
        local power = handleCastMode(t0)
        safeInvoke(RF_StartMini, 0, power, t0)
        task.wait(state.UB.Settings.CompleteDelay)
        task.wait(0.01)
        safeFire(RE_CatchDone)
        task.wait(state.UB.Settings.CancelDelay)
    end
    self._isRunning = false
end

function FishingCore:startUB()
    local state = self._State
    state.UB.Active = true
    state.UB.Stats.startTime = tick()
    self._hookNotificationDelay()
    state.HookNotif = true
    self._loopTask = task.spawn(function() self:startLoop() end)
end

function FishingCore:stopUB()
    local state = self._State
    state.UB.Active = false
    state.HookNotif = false
    if self._loopTask then
        pcall(task.cancel, self._loopTask)
        self._loopTask = nil
    end
    self._isRunning = false
end

-- ============================================
-- LEGIT AUTO FARM
-- ============================================
function FishingCore:legitFarmLoop()
    local state = self._State
    local remote = self._Remote
    local FishingController = require(game:GetService("ReplicatedStorage").Controllers.FishingController)
    local RE_FishDone = remote.getRemote("CatchFishCompleted")
    
    while state.AutoFarm and state.CurrentFishingMode == "Legit" do
        pcall(function()
            FishingController:RequestChargeFishingRod(Vector2.new(0, 0), true)
            task.wait(1)
            remote.fireServer("CatchFishCompleted", 1)
        end)
        task.wait(0.4 + math.random() * 0.3)
    end
end

-- ============================================
-- BLATANT SKIP CYCLE (Fast Reel)
-- ============================================
function FishingCore:blatantSkipCycle()
    local state = self._State
    local remote = self._Remote
    local ChargeRod = remote.getRemote("ChargeFishingRod")
    local StartMini = remote.getRemote("RequestFishingMinigameStarted")
    local CatchFish = remote.getRemote("CatchFishCompleted")
    
    local speed = state.Amblatant and 0.07 or 0.07
    local loopDelay = state.Amblatant and 0.25 or 0.25
    
    while state.BlatantMode do
        local t = Workspace:GetServerTimeNow()
        pcall(function() ChargeRod:InvokeServer(t) end)
        task.wait(speed)
        pcall(function() StartMini:InvokeServer(-1, 1, t) end)
        task.wait(speed)
        pcall(function() CatchFish:InvokeServer(1) end)
        task.wait(loopDelay)
    end
end

-- ============================================
-- AMBLATANT NATURAL HOOK
-- ============================================
FishingCore._naturalHookInstalled = false
FishingCore._naturalRainbowCount = 0
FishingCore._naturalGoldenCount = 0
FishingCore._naturalFishCount = 0
FishingCore.isCaught = false

function FishingCore:installNaturalHook()
    if self._naturalHookInstalled then return end
    if type(hookfunction) ~= "function" then return end
    
    local Event
    pcall(function()
        Event = game:GetService("ReplicatedStorage").Packages._Index["ytrev_replion@2.0.0-rc.3"].replion.Remotes.Set
    end)
    if not Event or not Event.OnClientEvent then return end
    
    local conns = getconnections(Event.OnClientEvent) or {}
    for _, Connection in pairs(conns) do
        if Connection and Connection.Function then
            local old = hookfunction(Connection.Function, function(...)
                local Args = { ... }
                if type(Args[2]) == "table" then
                    local category = Args[2][1]
                    local subCategory = Args[2][2]
                    local state = self._State
                    
                    if state.Amblatant then
                        if category == "Modifiers" and subCategory == "Rainbow" then
                            self._naturalRainbowCount = self._naturalRainbowCount + 1
                            if self._naturalRainbowCount > 40 then self._naturalRainbowCount = 0 end
                            self.isCaught = true
                            old(Args[1], Args[2], self._naturalRainbowCount)
                            return
                        elseif category == "Modifiers" and subCategory == "Golden" then
                            self._naturalGoldenCount = self._naturalGoldenCount + 1
                            if self._naturalGoldenCount > 10 then self._naturalGoldenCount = 0 end
                            self.isCaught = true
                            old(Args[1], Args[2], self._naturalGoldenCount)
                            return
                        elseif category == "InventoryNotifications" and subCategory == "Fish" then
                            self._naturalFishCount = self._naturalFishCount + 1
                            self.isCaught = true
                            old(Args[1], Args[2], self._naturalFishCount)
                            return
                        end
                    end
                end
                return old(...)
            end)
        end
    end
    self._naturalHookInstalled = true
end

-- ============================================
-- INSTANT BOBBER OVERRIDE
-- ============================================
FishingCore._bobberState = {
    active = false,
    baits = {},
    cosmeticFolder = nil,
    connections = {},
}

function FishingCore:enableInstantBobber(enabled: boolean)
    local state = self._bobberState
    if enabled then
        state.active = true
        state.baits = {}
        
        local ok, folder = pcall(function() return Workspace:WaitForChild("CosmeticFolder", 5) end)
        if not ok then return end
        state.cosmeticFolder = folder
        
        local remote = self._Remote
        local BaitCast = remote.getRemote("BaitCastVisual")
        local BaitDestroyed = remote.getRemote("BaitDestroyed")
        
        if BaitCast then
            state.connections.cast = BaitCast.OnClientEvent:Connect(function(player, data)
                if not state.active or not player then return end
                if data and data.CastPosition then
                    state.baits[player.UserId] = { pivot = CFrame.new(data.CastPosition), expires = tick() + 1.5 }
                end
            end)
        end
        
        if BaitDestroyed then
            state.connections.destroy = BaitDestroyed.OnClientEvent:Connect(function(player)
                if not state.active or not player then return end
                state.baits[player.UserId] = nil
            end)
        end
        
        state.connections.render = RunService.RenderStepped:Connect(function()
            if not state.active then return end
            local folder = state.cosmeticFolder
            if not folder then return end
            for userId, entry in pairs(state.baits) do
                if tick() > entry.expires then
                    state.baits[userId] = nil
                else
                    local model = folder:FindFirstChild(tostring(userId))
                    if model and model.PivotTo then
                        model:PivotTo(entry.pivot)
                    end
                end
            end
        end)
    else
        state.active = false
        for _, conn in pairs(state.connections) do
            pcall(conn.Disconnect, conn)
        end
        state.connections = {}
    end
end

return FishingCore