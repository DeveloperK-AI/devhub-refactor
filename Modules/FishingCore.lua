--!strict
-- FishingCore.lua - Semua logika fishing (Instant, Legit, Blatant, UB, Amblatant)
-- Version: 2.0.0

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PI = math.pi
local CAST_MODE_LIST = { "Perfect", "Fast", "Random" }

local FishingCore = {
    -- State
    _State = nil,
    _Remote = nil,
    _Utils = nil,
    
    -- Loop Handles
    _ubTask = nil,
    _legitTask = nil,
    _blatantTask = nil,
    _isUBRunning = false,
    _isLegitRunning = false,
    _isBlatantRunning = false,
    
    -- Notification Hook
    _notifHooked = false,
    
    -- Natural Hook
    _naturalHookInstalled = false,
    _naturalRainbowCount = 0,
    _naturalGoldenCount = 0,
    _naturalFishCount = 0,
    isCaught = false,
    
    -- Bobber
    _bobberState = {
        active = false,
        baits = {},
        cosmeticFolder = nil,
        connections = {},
    },
}

-- ============================================
-- DEPENDENCIES
-- ============================================
function FishingCore:Init(State, Remote, Utils)
    self._State = State
    self._Remote = Remote
    self._Utils = Utils
end

-- ============================================
-- PRIVATE HELPERS
-- ============================================
local function getPowerAtTime(chargeTime: number, elapsed: number): number
    local speed = Random.new(chargeTime):NextInteger(4, 10)
    local angle = PI / 2 + elapsed * speed
    return (1 - math.sin(angle)) / 2
end

local function waitForPower(chargeTime: number, threshold: number): (number, number)
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

local function handleCastMode(t0: number, mode: string): number
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

local function safeInvoke(remote, ...): boolean
    if not remote then return false end
    local args = { ... }
    local ok = pcall(function()
        remote:InvokeServer(unpack(args))
    end)
    return ok
end

local function safeFire(remote, ...): boolean
    if not remote then return false end
    local args = { ... }
    local ok = pcall(function()
        remote:FireServer(unpack(args))
    end)
    return ok
end

-- ============================================
-- NOTIFICATION HOOK
-- ============================================
function FishingCore:_hookNotificationDelay()
    if self._notifHooked then return end
    
    local ok, controller = pcall(function()
        return require(game:GetService("ReplicatedStorage").Controllers.TextNotificationController)
    end)
    if not ok or not controller then 
        warn("[FishingCore] TextNotificationController not found")
        return 
    end
    
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
-- ULTRA BLATANT (UB) - Instant Fishing V2
-- ============================================
function FishingCore:startUB()
    if self._isUBRunning then
        warn("[FishingCore] UB already running")
        return
    end
    
    local state = self._State
    state.UB.Active = true
    state.UB.Stats.startTime = tick()
    state.HookNotif = true
    self._hookNotificationDelay()
    self._isUBRunning = true
    
    self._ubTask = task.spawn(function()
        self:_ubLoop()
    end)
    print("[FishingCore] ✅ UB started")
end

function FishingCore:_ubLoop()
    local state = self._State
    local remote = self._Remote
    
    local RF_Charge = remote.getRemote("ChargeFishingRod")
    local RF_StartMini = remote.getRemote("RequestFishingMinigameStarted")
    local RE_CatchDone = remote.getRemote("CatchFishCompleted")
    
    while state.UB.Active do
        local t0 = Workspace:GetServerTimeNow()
        safeInvoke(RF_Charge, nil, nil, t0, nil)
        local power = handleCastMode(t0, state.UB.Settings.CastMode or "Fast")
        safeInvoke(RF_StartMini, 0, power, t0)
        task.wait(state.UB.Settings.CompleteDelay or 3.7)
        task.wait(0.01)
        safeFire(RE_CatchDone)
        task.wait(state.UB.Settings.CancelDelay or 0.2)
    end
    
    self._isUBRunning = false
    print("[FishingCore] UB loop stopped")
end

function FishingCore:stopUB()
    self._State.UB.Active = false
    self._State.HookNotif = false
    if self._ubTask then
        pcall(task.cancel, self._ubTask)
        self._ubTask = nil
    end
    self._isUBRunning = false
    print("[FishingCore] UB stopped")
end

function FishingCore:isUBRunning(): boolean
    return self._isUBRunning
end

-- ============================================
-- LEGIT AUTO FARM
-- ============================================
function FishingCore:startLegitFarm()
    if self._isLegitRunning then
        warn("[FishingCore] Legit farm already running")
        return
    end
    self._isLegitRunning = true
    self._legitTask = task.spawn(function()
        self:_legitLoop()
    end)
    print("[FishingCore] ✅ Legit farm started")
end

function FishingCore:_legitLoop()
    local state = self._State
    local remote = self._Remote
    
    local FishingController
    local ok = pcall(function()
        FishingController = require(game:GetService("ReplicatedStorage").Controllers.FishingController)
    end)
    if not ok then
        warn("[FishingCore] FishingController not found, cannot run legit farm")
        self._isLegitRunning = false
        return
    end
    
    local RE_FishDone = remote.getRemote("CatchFishCompleted")
    
    while state.AutoFarm and state.CurrentFishingMode == "Legit" do
        local success = pcall(function()
            FishingController:RequestChargeFishingRod(Vector2.new(0, 0), true)
            task.wait(1)
            safeFire(RE_FishDone, 1)
        end)
        if not success then
            warn("[FishingCore] Legit loop error, waiting...")
            task.wait(1)
        end
        task.wait(0.4 + math.random() * 0.3)
    end
    
    self._isLegitRunning = false
    print("[FishingCore] Legit farm stopped")
end

function FishingCore:stopLegitFarm()
    self._State.AutoFarm = false
    if self._legitTask then
        pcall(task.cancel, self._legitTask)
        self._legitTask = nil
    end
    self._isLegitRunning = false
    print("[FishingCore] Legit farm stopped")
end

function FishingCore:isLegitRunning(): boolean
    return self._isLegitRunning
end

-- ============================================
-- BLATANT SKIP CYCLE (Fast Reel)
-- ============================================
function FishingCore:startBlatant()
    if self._isBlatantRunning then
        warn("[FishingCore] Blatant already running")
        return
    end
    self._isBlatantRunning = true
    self._blatantTask = task.spawn(function()
        self:_blatantLoop()
    end)
    print("[FishingCore] ✅ Blatant started")
end

function FishingCore:_blatantLoop()
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
    
    self._isBlatantRunning = false
    print("[FishingCore] Blatant stopped")
end

function FishingCore:stopBlatant()
    self._State.BlatantMode = false
    if self._blatantTask then
        pcall(task.cancel, self._blatantTask)
        self._blatantTask = nil
    end
    self._isBlatantRunning = false
    print("[FishingCore] Blatant stopped")
end

function FishingCore:isBlatantRunning(): boolean
    return self._isBlatantRunning
end

-- ============================================
-- AMBLATANT NATURAL HOOK
-- ============================================
function FishingCore:installNaturalHook()
    if self._naturalHookInstalled then
        warn("[FishingCore] Natural hook already installed")
        return
    end
    if type(hookfunction) ~= "function" then
        warn("[FishingCore] hookfunction not available")
        return
    end
    
    local Event
    pcall(function()
        Event = game:GetService("ReplicatedStorage").Packages._Index["ytrev_replion@2.0.0-rc.3"].replion.Remotes.Set
    end)
    if not Event or not Event.OnClientEvent then
        warn("[FishingCore] Natural hook remote not found")
        return 
    end
    
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
    print("[FishingCore] ✅ Natural hook installed")
end

function FishingCore:uninstallNaturalHook()
    self._naturalHookInstalled = false
    self._naturalRainbowCount = 0
    self._naturalGoldenCount = 0
    self._naturalFishCount = 0
    self.isCaught = false
    print("[FishingCore] Natural hook uninstalled")
end

-- ============================================
-- INSTANT BOBBER
-- ============================================
function FishingCore:enableInstantBobber(enabled: boolean)
    local state = self._bobberState
    if enabled then
        if state.active then
            warn("[FishingCore] Instant bobber already enabled")
            return
        end
        state.active = true
        state.baits = {}
        
        local ok, folder = pcall(function() return Workspace:WaitForChild("CosmeticFolder", 5) end)
        if not ok or not folder then
            warn("[FishingCore] CosmeticFolder not found, cannot enable bobber")
            state.active = false
            return
        end
        state.cosmeticFolder = folder
        
        local remote = self._Remote
        local BaitCast = remote.getRemote("BaitCastVisual")
        local BaitDestroyed = remote.getRemote("BaitDestroyed")
        
        if BaitCast and BaitCast:IsA("RemoteEvent") then
            state.connections.cast = BaitCast.OnClientEvent:Connect(function(player, data)
                if not state.active or not player then return end
                if data and data.CastPosition then
                    state.baits[player.UserId] = { pivot = CFrame.new(data.CastPosition), expires = tick() + 1.5 }
                end
            end)
        end
        
        if BaitDestroyed and BaitDestroyed:IsA("RemoteEvent") then
            state.connections.destroy = BaitDestroyed.OnClientEvent:Connect(function(player)
                if not state.active or not player then return end
                state.baits[player.UserId] = nil
            end)
        end
        
        state.connections.render = RunService.RenderStepped:Connect(function()
            if not state.active then return end
            local folder = state.cosmeticFolder
            if not folder then return end
            local now = tick()
            for userId, entry in pairs(state.baits) do
                if now > entry.expires then
                    state.baits[userId] = nil
                else
                    local model = folder:FindFirstChild(tostring(userId))
                    if model and model.PivotTo then
                        model:PivotTo(entry.pivot)
                    end
                end
            end
        end)
        print("[FishingCore] ✅ Instant bobber enabled")
    else
        state.active = false
        state.baits = {}
        for _, conn in pairs(state.connections) do
            pcall(conn.Disconnect, conn)
        end
        state.connections = {}
        print("[FishingCore] Instant bobber disabled")
    end
end

function FishingCore:isBobberEnabled(): boolean
    return self._bobberState.active
end

-- ============================================
-- CLEANUP (Untuk destroy saat script berhenti)
-- ============================================
function FishingCore:cleanup()
    self:stopUB()
    self:stopLegitFarm()
    self:stopBlatant()
    self:enableInstantBobber(false)
    self:uninstallNaturalHook()
    print("[FishingCore] Cleanup complete")
end

return FishingCore
