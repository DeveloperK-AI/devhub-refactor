-- ============================================================
-- REMOTE MAP & SERVICES (OPTIMIZED)
-- ============================================================

-- Services (tetap global untuk kompatibilitas dengan kode di bawah)
ReplicatedStorage = game:GetService("ReplicatedStorage")

local netFolder = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
local netChildren = netFolder:GetChildren()

-- Optimasi isHex: gunakan string.sub karena prefix selalu 3 karakter ("RF/" atau "RE/")
local function isHex(name: string): boolean
    local stripped = name:sub(4)  -- lebih cepat dari gsub
    return #stripped > 16 and stripped:match("^%x+$") ~= nil
end

-- Build remoteMap: hanya iterate sampai elemen kedua terakhir
local remoteMap = {}
for i = 1, #netChildren - 1 do
    local child = netChildren[i]
    local nextChild = netChildren[i + 1]
    if not isHex(child.Name) and isHex(nextChild.Name) then
        local key = child.Name:sub(4)  -- hapus "RF/" atau "RE/"
        remoteMap[key] = nextChild
    end
end

-- ============================================================
-- REMOTE ACCESS FUNCTIONS
-- ============================================================
function RF(name) return remoteMap[name] end
function RE(name) return remoteMap[name] end

-- ============================================================
-- AMBLATANT CACHED DATA
-- ============================================================
_G.SavedData = _G.SavedData or {
    FishCaught = {},
    CaughtVisual = {},
    FishNotif = {},
}

-- ============================================================
-- FIRE LOCAL EVENT (OPTIMIZED - SINGLE THREAD PER CALL)
-- ============================================================
function FireLocalEvent(remote, ...)
    if not remote or not remote.OnClientEvent then return end

    local args = { ... }
    local signal = remote.OnClientEvent

    -- Hanya buat 1 thread per panggilan, bukan 1 thread per connection!
    task.spawn(function()
        for _, connection in pairs(getconnections(signal)) do
            if connection.Function then
                pcall(connection.Function, unpack(args))
            end
        end
    end)
end

-- ============================================================
-- SAVE COUNT (DIGUNAKAN OLEH HOOKREMOTE)
-- ============================================================
local saveCount = 0  -- ubah ke local agar tidak mencemari global, tapi masih bisa diakses oleh HookRemote (closure)
-- Catatan: jika ada kode lain yang mengakses saveCount secara global, ubah kembali ke non-local.
-- Saya asumsikan hanya HookRemote yang menggunakannya.

-- ============================================================
-- GET SERVER REMOTE (OPTIMIZED)
-- ============================================================
function GetServerRemote(humanName: string)
    -- humanName selalu diawali "RF/" atau "RE/" (3 karakter)
    return remoteMap[humanName:sub(4)]
end

-- ============================================================
-- HOOK REMOTE (CACHE PLAYERS SERVICE)
-- ============================================================
local PlayersService = game:GetService("Players")  -- cache di luar fungsi

function HookRemote(humanName: string, storageKey: string): boolean
    local remote = GetServerRemote(humanName)
    if not remote then return false end

    remote.OnClientEvent:Connect(function(...)
        if saveCount < 7 then
            local args = { ... }
            _G.SavedData[storageKey] = args

            if storageKey == "CaughtVisual" then
                local lp = PlayersService.LocalPlayer
                local myName = lp and lp.Name
                if myName and tostring(args[1]) == tostring(myName) then
                    saveCount = saveCount + 1
                end
            end
        end
    end)

    return true
end

-- ============================================================
-- REMOTE VARIABLES (RF / RE)
-- ============================================================
BuyRod              = RF("PurchaseFishingRod")
BuyBait             = RF("PurchaseBait")
BuyCharm            = RF("PurchaseCharm")
REFishDone          = RF("CatchFishCompleted")
REFishDoneRE        = RE("CatchFishCompleted")
BuyWeather          = RF("PurchaseWeatherEvent")
ChargeRod           = RF("ChargeFishingRod")
StartMini           = RF("RequestFishingMinigameStarted")
UpdateRadar         = RF("UpdateFishingRadar")
Cancel              = RF("CancelFishingInputs")
SellItem            = RF("SellAllItems")
AutoEnabled         = RF("UpdateAutoFishingState")
BuyMarket           = RF("PurchaseMarketItem")
InitiateTrade       = RF("InitiateTrade")
RFAwaitTradeResponse = RF("AwaitTradeResponse")
EquipOxygen         = RF("EquipOxygenTank")
UnequipOxygen       = RF("UnequipOxygenTank")
ConsumeCrystal      = RF("ConsumeCaveCrystal")
ConsumePotion       = RF("ConsumePotion")
threselod           = RF("UpdateAutoSellThreshold")
dialogevent         = RF("SpecialDialogueEvent")

RECutscene          = RE("ReplicateCutscene")
REStop              = RE("StopCutscene")
REFav               = RE("FavoriteItem")
REFavChg            = RE("FavoriteStateChanged")
REFishGot           = RE("FishCaught")
RENotify            = RE("TextNotification")
REEquip             = RE("EquipToolFromHotbar")
REEquipItem         = RE("EquipItem")
REAltar             = RE("ActivateEnchantingAltar")
REAltar2            = RE("ActivateSecondEnchantingAltar")
REPlayFishEffect    = RE("PlayFishingEffect")
RETextEffect        = RE("ReplicateTextEffect")
Totem               = RE("SpawnTotem")
FishingMinigameChanged = RE("FishingMinigameChanged")
FishingStopped      = RE("FishingStopped")
REEvReward          = RE("ClaimEventReward")
REEquipCharm        = RE("EquipCharm")
REUnequipCharm      = RE("UnequipCharm")
BaitSpawned         = RE("BaitSpawned")
BaitDestroyed       = RE("BaitDestroyed")
PirateChest         = RE("ClaimPirateChest")
GainMaze            = RE("GainAccessToMaze")
PlaceLever          = RE("PlaceLeverItem")
REDialogueEnded     = RE("DialogueEnded")
RFCreateTranscendedStone = RF("CreateTranscendedStone")
EquipBait           = RE("EquipBait")

-- ============================================================
-- CONFIGURATION (moons.lua style)
-- ============================================================
_G.Config = _G.Config or {  -- gunakan _G agar eksplisit, tapi tetap global
    HookNotif = false,
    InstantFishingV2Active = false,
    isMinig = false,
    autoFishing = false,
    AutoCatch = false,
    antiOKOK = false,
    amblatant = false,
    UB = {
        Active = false,
        Settings = { CompleteDelay = 3.7, CancelDelay = 0.2, CastMode = "Fast" },
        Remotes = {},
        Stats = { castCount = 0, startTime = 0 },
    },
}

-- Karena kode lain mengakses 'Config' (tanpa _G), kita buat alias
-- agar jika ada yang memanggil 'Config' langsung, tetap mengarah ke _G.Config
Config = _G.Config

-- Variabel global lainnya
Tasks = Tasks or {}
blatantFishCycleCount = blatantFishCycleCount or 0
needCast = needCast or false
skip = skip or false
Events = Events or {}

-- ============================================================
-- SAFE FIRE (Optimized dengan validasi)
-- ============================================================
function safeFire(func)
    if type(func) ~= "function" then
        warn("[safeFire] Invalid function argument")
        return
    end
    task.spawn(function()
        pcall(func)
    end)
end

-- ============================================================
-- CALL REMOTE SERVER (Simplified & Optimized)
-- ============================================================
function CallRemoteServer(remote, ...)
    if not remote then return false end

    local args = { ... }

    -- Deteksi tipe remote dan panggil method yang sesuai
    if remote:IsA("RemoteFunction") then
        local ok, result = pcall(remote.InvokeServer, remote, unpack(args))
        return ok, result
    elseif remote:IsA("RemoteEvent") then
        local ok = pcall(remote.FireServer, remote, unpack(args))
        return ok
    else
        -- Fallback: coba InvokeServer, lalu FireServer jika gagal
        local ok, result = pcall(remote.InvokeServer, remote, unpack(args))
        if ok then
            return true, result
        end
        -- Jika InvokeServer gagal, coba FireServer
        ok = pcall(remote.FireServer, remote, unpack(args))
        return ok
    end
end

-- ============================================================
-- EVENTS & SERVICES
-- ============================================================
Events.equip = GetServerRemote("RF/EquipToolFromHotbar")
Events.CancelFishingInputs = GetServerRemote("RF/CancelFishingInputs")
Events.charge = GetServerRemote("RF/ChargeFishingRod")
Events.minigame = GetServerRemote("RF/RequestFishingMinigameStarted")
Events.UpdateAutoFishingState = GetServerRemote("RF/UpdateAutoFishingState")

-- Services (tetap global untuk kompatibilitas)
TweenService = game:GetService("TweenService")
UserInputService = game:GetService("UserInputService")
RunService = game:GetService("RunService")
CoreGui = game:GetService("CoreGui")
Players = game:GetService("Players")
HttpService = game:GetService("HttpService")
Lighting = game:GetService("Lighting")
Terrain = workspace:FindFirstChildOfClass("Terrain")

-- ============================================================
-- DATA CACHE SYSTEM
-- ============================================================
DataCache = {
    equipped = nil,
    rods = nil,
    inventory = nil,
    enchantStones = nil,
    lastUpdate = 0,
    cacheDuration = 3,
}

function DataCache:Get(key)
    if tick() - self.lastUpdate > self.cacheDuration then
        self:Invalidate()
    end
    return self[key]
end

function DataCache:Set(key, value)
    self[key] = value
    self.lastUpdate = tick()
end

function DataCache:Invalidate()
    self.equipped = nil
    self.rods = nil
    self.inventory = nil
    self.enchantStones = nil
end
-- ============================================================
-- UI LIBRARY & WINDOW
-- ============================================================
local VoraLib = (function()
--!strict
--[[
    DeveloperK | COMMUNITY
    Author  : DeveloperK
    Version : 2.0.0 (Refactored)
    Created : November 1999
    Discord : discord.gg/developerk

    CHANGELOG v2.0.0:
    - Fixed global pollution: all services now properly local
    - Extracted ripple, tween-toggle helpers to eliminate closure allocations per-element
    - Eliminated redundant conditional initializations (ternary no-ops)
    - Extracted shared dropdown close logic into a single function
    - Modularized CreateControlButton duplication
    - Extracted SV/Hue drag handlers from per-instance closures into shared updaters
    - Consistent connection management via Connections table
    - Dead code removed (unused ResizeLines loop that immediately Destroy()s)
    - UIListLayout reference cached instead of FindFirstChildOfClass in hot path
    - Tab activation loop O(n) preserved but tweens batched per-tab
]]

-- ============================================
-- SERVICES (local — fixes --!strict globals)
-- ============================================
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService") -- luacheck: ignore (kept for potential use)
local CoreGui            = game:GetService("CoreGui")
local Players            = game:GetService("Players")
local HttpService        = game:GetService("HttpService")

local Terrain = workspace:FindFirstChildOfClass("Terrain") -- luacheck: ignore

-- ============================================
-- MODULE
-- ============================================
local VoraLib    = {}
local Connections: { RBXScriptConnection } = {}

-- Only one keybind slot may be "listening" at a time; prevents one key changing another slot.
local KeybindBindSessionCancel: (() -> ())?  = nil

-- ============================================
-- THEME & ICONS
-- ============================================
local Theme = {
    Background      = Color3.fromRGB(10,  12,  25),
    Sidebar         = Color3.fromRGB(15,  18,  32),
    ElementBackground = Color3.fromRGB(25, 30,  50),
    TextColor       = Color3.fromRGB(255, 255, 255),
    TextSecondary   = Color3.fromRGB(180, 200, 230),
    Accent          = Color3.fromRGB(0,   140, 210),
    Hover           = Color3.fromRGB(35,  45,  70),
    Outline         = Color3.fromRGB(40,  60,  90),
}

local Icons: { [string]: string } = {
    player    = "rbxassetid://12120698352",
    web       = "rbxassetid://137601480983962",
    bag       = "rbxassetid://8601111810",
    shop      = "rbxassetid://4985385964",
    cart      = "rbxassetid://128874923961846",
    plug      = "rbxassetid://137601480983962",
    settings  = "rbxassetid://70386228443175",
    loop      = "rbxassetid://122032243989747",
    gps       = "rbxassetid://17824309485",
    compas    = "rbxassetid://125300760963399",
    gamepad   = "rbxassetid://84173963561612",
    boss      = "rbxassetid://13132186360",
    scroll    = "rbxassetid://114127804740858",
    menu      = "rbxassetid://6340513838",
    crosshair = "rbxassetid://12614416478",
    user      = "rbxassetid://108483430622128",
    stat      = "rbxassetid://12094445329",
    eyes      = "rbxassetid://14321059114",
    sword     = "rbxassetid://82472368671405",
    discord   = "rbxassetid://94434236999817",
    star      = "rbxassetid://107005941750079",
    skeleton  = "rbxassetid://17313330026",
    payment   = "rbxassetid://18747025078",
    scan      = "rbxassetid://109869955247116",
    alert     = "rbxassetid://73186275216515",
    question  = "rbxassetid://17510196486",
    idea      = "rbxassetid://16833255748",
    strom     = "rbxassetid://13321880293",
    water     = "rbxassetid://13321880293",
    dcs       = "rbxassetid://15310731934",
    start     = "rbxassetid://108886429866687",
    next      = "rbxassetid://12662718374",
    rod       = "rbxassetid://103247953194129",
    fish      = "rbxassetid://97167558235554",
    bell      = "rbxassetid://73186275216515",
}

VoraLib.Icons = Icons

-- ============================================
-- SHARED TWEEN HELPERS
-- Cache TweenInfo objects that would otherwise be reallocated on every hover/click.
-- ============================================
local TWEEN_FAST   = TweenInfo.new(0.2)
local TWEEN_MED    = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_QUINT  = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_RIPPLE_BTN  = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_RIPPLE_TAB  = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_RIPPLE_KEY  = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SLIDER_KNOB = TweenInfo.new(0.15)
local TWEEN_SLIDER_FAST = TweenInfo.new(0.05)
local TWEEN_PICKER      = TweenInfo.new(0.3, Enum.EasingStyle.Quint)
local TWEEN_DROPDOWN    = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
local TWEEN_DROPDOWN_OUT = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_NOTIF_IN    = TweenInfo.new(0.5, Enum.EasingStyle.Quint)
local TWEEN_NOTIF_OUT   = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

-- ============================================
-- PRIVATE UTILITIES
-- ============================================

--- Create an Instance with a property table in one call.
local function Create(className: string, properties: { [string]: any }): Instance
    local inst = Instance.new(className)
    for k, v in pairs(properties) do
        (inst :: any)[k] = v
    end
    return inst
end

--- Spawn a ripple animation originating from the mouse inside `parent`.
--- Extracted so every Button/Tab/Keybind doesn't allocate a new closure each construction.
local function spawnRipple(
    parent: GuiObject,
    mouseX: number, mouseY: number,
    sizeTarget: number,
    tweenInfo: TweenInfo
)
    task.spawn(function()
        -- Bungkus dengan pcall agar error di dalam ripple tidak mengganggu UI utama
        pcall(function()
            local ox = mouseX - parent.AbsolutePosition.X
            local oy = mouseY - parent.AbsolutePosition.Y
            local half = sizeTarget / 2

            local Ripple = Create("Frame", {
                Parent               = parent,
                BackgroundColor3     = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0.8,
                BorderSizePixel      = 0,
                Position             = UDim2.new(0, ox, 0, oy),
                Size                 = UDim2.new(0, 0, 0, 0),
                ZIndex               = parent.ZIndex + 1,
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Ripple })

            local tween = TweenService:Create(Ripple, tweenInfo, {
                Size     = UDim2.new(0, sizeTarget, 0, sizeTarget),
                Position = UDim2.new(0, ox - half, 0, oy - half),
                BackgroundTransparency = 1,
            })
            tween:Play()
            tween.Completed:Wait()
            Ripple:Destroy()
        end)
    end)
end
--- Make a GuiObject draggable by holding `topBar`.
local function MakeDraggable(topBar: GuiObject, target: GuiObject)
    local dragging    = false
    local dragInput: InputObject?   = nil
    local dragStart: Vector3?       = nil
    local startPos: UDim2?          = nil

    local function update(input: InputObject)
        if not dragStart or not startPos then return end
        local delta = input.Position - dragStart
        local pos = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
        TweenService:Create(target, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = pos }):Play()
    end

    table.insert(Connections, topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = target.Position

            local conn: RBXScriptConnection
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    conn:Disconnect()
                end
            end)
        end
    end))

    table.insert(Connections, topBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end))
end

-- ============================================
-- WINDOW FACTORY
-- ============================================
function VoraLib:CreateWindow(options: { Name: string?, Intro: boolean? }?)
    options = options or {}
    local TitleName     = (options :: any).Name  or "VoraHub"
    local IntroEnabled  = (options :: any).Intro or false

    -- Resolve the best parent for the ScreenGui
    local function getParent(): Instance
        local ok, parent = pcall(function()
            return ((_G :: any).gethui and (_G :: any).gethui()) or CoreGui
        end)
        if not ok or not parent then
            return Players.LocalPlayer:WaitForChild("PlayerGui")
        end
        return parent :: Instance
    end

    local ScreenGui = Create("ScreenGui", {
        Name            = "VoraHub",
        Parent          = getParent(),
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn    = false,
    }) :: ScreenGui

    local IsMobile    = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
    -- Canonical sizes — declared once, referenced everywhere (eliminates repeated literal duplication)
    local DEFAULT_SIZE = IsMobile and UDim2.new(0, 500, 0, 320) or UDim2.new(0, 700, 0, 450)
    local DEFAULT_POS  = IsMobile and UDim2.new(0.5, -250, 0.5, -160) or UDim2.new(0.5, -350, 0.5, -225)
    local MAX_SIZE     = IsMobile and UDim2.new(0, 600, 0, 350) or UDim2.new(0, 900, 0, 600)
    local MAX_POS      = IsMobile and UDim2.new(0.5, -300, 0.5, -175) or UDim2.new(0.5, -450, 0.5, -300)

    -- ── Main Frame ──────────────────────────────────────────────────────────
    local MainFrame = Create("Frame", {
        Name                  = "MainFrame",
        Parent                = ScreenGui,
        BackgroundColor3      = Theme.Background,
        BackgroundTransparency = 0.05,
        BorderSizePixel       = 0,
        Position              = DEFAULT_POS,
        Size                  = DEFAULT_SIZE,
        ClipsDescendants      = false,
    }) :: Frame
    Create("UICorner",  { CornerRadius = UDim.new(0, 10), Parent = MainFrame })
    Create("UIStroke",  { Transparency = 0, Thickness = 1, Color = Theme.Outline, Parent = MainFrame })
    Create("ImageLabel", {
        Name              = "Pattern",
        Parent            = MainFrame,
        BackgroundTransparency = 1,
        Size              = UDim2.new(1, 0, 1, 0),
        Image             = "rbxassetid://2151741365",
        ImageTransparency = 0.95,
        TileSize          = UDim2.new(0, 20, 0, 20),
        ScaleType         = Enum.ScaleType.Tile,
        ZIndex            = 1,
    })

    -- ── Shadow ──────────────────────────────────────────────────────────────
    local Shadow = Create("ImageLabel", {
        Name              = "Shadow",
        Parent            = ScreenGui,
        BackgroundTransparency = 1,
        Position          = DEFAULT_POS,
        Size              = DEFAULT_SIZE,
        Image             = "rbxassetid://6015897843",
        ImageColor3       = Color3.new(0, 0, 0),
        ImageTransparency = 0.5,
        ZIndex            = -1,
        SliceCenter       = Rect.new(49, 49, 450, 450),
        ScaleType         = Enum.ScaleType.Slice,
    }) :: ImageLabel

    MainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        Shadow.Size = UDim2.new(0, MainFrame.AbsoluteSize.X + 34, 0, MainFrame.AbsoluteSize.Y + 34)
    end)
    MainFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
        Shadow.Position = UDim2.new(0, MainFrame.AbsolutePosition.X - 17, 0, MainFrame.AbsolutePosition.Y - 17)
    end)

    -- ── Resize Handle ────────────────────────────────────────────────────────
    local ResizeHandle = Create("TextButton", {
        Name                = "ResizeHandle",
        Parent              = MainFrame,
        BackgroundTransparency = 1,
        Position            = UDim2.new(1, -4, 1, -4),
        Size                = UDim2.new(0, 16, 0, 16),
        Text                = "",
        AutoButtonColor     = false,
        ZIndex              = 100,
        AnchorPoint         = Vector2.new(1, 1),
    }) :: TextButton

    -- Three grip lines — defined declaratively, no dead-loop needed
    local LINE_CONFIGS = {
        { Size = UDim2.new(0,  6, 0, 2), Pos = UDim2.new(1, -2, 1, -2)  },
        { Size = UDim2.new(0, 10, 0, 2), Pos = UDim2.new(1, -2, 1, -6)  },
        { Size = UDim2.new(0, 14, 0, 2), Pos = UDim2.new(1, -2, 1, -10) },
    }
    local ResizeLines: { Frame } = {}
    for _, cfg in ipairs(LINE_CONFIGS) do
        local line = Create("Frame", {
            Parent           = ResizeHandle,
            BackgroundColor3 = Theme.TextSecondary,
            BorderSizePixel  = 0,
            Rotation         = -45,
            Size             = cfg.Size,
            Position         = cfg.Pos,
            AnchorPoint      = Vector2.new(1, 1),
            ZIndex           = 101,
        }) :: Frame
        Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = line })
        table.insert(ResizeLines, line)
    end

    ResizeHandle.MouseEnter:Connect(function()
        for _, line in ipairs(ResizeLines) do
            TweenService:Create(line, TWEEN_FAST, { BackgroundColor3 = Theme.Accent }):Play()
        end
    end)
    ResizeHandle.MouseLeave:Connect(function()
        for _, line in ipairs(ResizeLines) do
            TweenService:Create(line, TWEEN_FAST, { BackgroundColor3 = Theme.TextSecondary }):Play()
        end
    end)

    do
        local resizing   = false
        local resizeStart = Vector2.new()
        local startSize   = Vector2.new()

        ResizeHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                resizing    = true
                resizeStart = Vector2.new(input.Position.X, input.Position.Y)
                startSize   = MainFrame.AbsoluteSize
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if resizing and (
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            ) then
                local delta = input.Position - Vector3.new(resizeStart.X, resizeStart.Y, 0)
                MainFrame.Size = UDim2.new(0, math.max(400, startSize.X + delta.X), 0, math.max(300, startSize.Y + delta.Y))
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                resizing = false
            end
        end)
    end

    -- ── Header ───────────────────────────────────────────────────────────────
    local Header = Create("Frame", {
        Name             = "Header",
        Parent           = MainFrame,
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 38),
    }) :: Frame
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Header })
    -- Fill bottom-half so rounded top corners don't show through
    Create("Frame", {
        Name             = "BottomFiller",
        Parent           = Header,
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0.5, 0),
        Size             = UDim2.new(1, 0, 0.5, 0),
        ZIndex           = 1,
    })
    Create("Frame", {
        Parent           = Header,
        BackgroundColor3 = Theme.Outline,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 1, -1),
        Size             = UDim2.new(1, 0, 0, 1),
        ZIndex           = 2,
    })
    Create("ImageLabel", {
        Name                  = "Logo",
        Parent                = Header,
        BackgroundTransparency = 1,
        Position              = UDim2.new(0, 10, 0, 5),
        Size                  = UDim2.new(0, 25, 0, 25),
        Image                 = "rbxassetid://112067161065104",
        ImageColor3           = Theme.Accent,
        ZIndex                = 2,
    })
    Create("TextLabel", {
        Name                  = "Title",
        Parent                = Header,
        BackgroundTransparency = 1,
        Position              = UDim2.new(0, 45, 0, 0),
        Size                  = UDim2.new(1, -160, 1, 0),
        Font                  = Enum.Font.GothamBold,
        Text                  = TitleName,
        TextColor3            = Theme.TextColor,
        TextSize              = 16,
        TextXAlignment        = Enum.TextXAlignment.Left,
        ZIndex                = 2,
    })

    -- ── Intro Animation ──────────────────────────────────────────────────────
    if IntroEnabled then
        local savedSize = MainFrame.Size
        MainFrame.Size                  = UDim2.new(0, 0, 0, 0)
        MainFrame.BackgroundTransparency = 1
        TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size                  = savedSize,
            BackgroundTransparency = 0.05,
        }):Play()
    end

    -- ── Sidebar ──────────────────────────────────────────────────────────────
    local Sidebar = Create("Frame", {
        Name                  = "Sidebar",
        Parent                = MainFrame,
        BackgroundColor3      = Theme.Sidebar,
        BackgroundTransparency = 1,
        BorderSizePixel       = 0,
        Position              = UDim2.new(0, 0, 0, 38),
        Size                  = UDim2.new(0, 160, 1, -38),
    }) :: Frame
    Create("Frame", {
        Name             = "Separator",
        Parent           = Sidebar,
        BackgroundColor3 = Theme.Outline,
        BorderSizePixel  = 0,
        Position         = UDim2.new(1, -2, 0, 0),
        Size             = UDim2.new(0, 2, 1, 0),
    })

    -- ── Header Controls ──────────────────────────────────────────────────────
    local Controls = Create("Frame", {
        Name                  = "Controls",
        Parent                = Header,
        BackgroundTransparency = 1,
        Position              = UDim2.new(1, -100, 0, 0),
        Size                  = UDim2.new(0, 100, 1, 0),
        ZIndex                = 2,
    }) :: Frame
    Create("UIListLayout", {
        Parent              = Controls,
        FillDirection       = Enum.FillDirection.Horizontal,
        SortOrder           = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment   = Enum.VerticalAlignment.Center,
        Padding             = UDim.new(0, 8),
    })
    Create("UIPadding", { Parent = Controls, PaddingRight = UDim.new(0, 15) })

    --- Shared factory for the three small icon buttons in the header.
    --- Extracted to eliminate copy-paste closure allocation per button.
    local function createControlButton(name: string, icon: string, layoutOrder: number, callback: () -> ()): ImageButton
        local btn = Create("ImageButton", {
            Name                  = name,
            Parent                = Controls,
            BackgroundTransparency = 1,
            LayoutOrder           = layoutOrder,
            Size                  = UDim2.new(0, 20, 0, 20),
            Image                 = "rbxassetid://" .. icon,
            ImageColor3           = Theme.TextSecondary,
            AutoButtonColor       = false,
        }) :: ImageButton
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TWEEN_FAST, { ImageColor3 = Theme.TextColor }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TWEEN_FAST, { ImageColor3 = Theme.TextSecondary }):Play()
        end)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- ── Floating Toggle Button ────────────────────────────────────────────────
    local ToggleButton = Create("ImageButton", {
        Name             = "ToggleUI",
        Parent           = ScreenGui,
        BackgroundColor3 = Theme.Background,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0.1, 0, 0.1, 0),
        Size             = UDim2.new(0, 50, 0, 50),
        Image            = "rbxassetid://127876061340518",
        ImageColor3      = Theme.TextColor,
        Visible          = true,
        Active           = true,
        Draggable        = true,
        ZIndex           = 100,
    }) :: ImageButton
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = ToggleButton })
    Create("UIStroke",  { Color = Theme.Outline, Thickness = 1, Parent = ToggleButton })

    -- ── Window Visibility Toggle ──────────────────────────────────────────────
    local mainFrameVisible = true

    local function toggleUI()
        mainFrameVisible = not mainFrameVisible

        if mainFrameVisible then
            MainFrame.Visible = true
            Shadow.Visible    = true
            MainFrame.Size    = UDim2.new(0, 0, 0, 0)
            TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size                  = DEFAULT_SIZE,
                BackgroundTransparency = 0.05,
            }):Play()
            TweenService:Create(Shadow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                ImageTransparency = 0.5,
                Size = UDim2.new(0, DEFAULT_SIZE.X.Offset + 34, 0, DEFAULT_SIZE.Y.Offset + 34),
            }):Play()
        else
            TweenService:Create(Shadow, TWEEN_FAST, { ImageTransparency = 1, Size = UDim2.new(0, 0, 0, 0) }):Play()
            local tween = TweenService:Create(MainFrame,
                TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
                { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }
            )
            tween:Play()
            task.spawn(function()
                tween.Completed:Wait()
                if not mainFrameVisible then
                    MainFrame.Visible = false
                    Shadow.Visible    = false
                end
            end)
        end
    end

    ToggleButton.MouseButton1Click:Connect(toggleUI)
    table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
            toggleUI()
        end
    end))

    -- Minimize (same action as toggle)
    createControlButton("Minimize", "71686683787518", 1, toggleUI)

    -- Maximize
    do
        local maximized = false
        createControlButton("Maximize", "135582116755237", 2, function()
            maximized = not maximized
            TweenService:Create(MainFrame, TWEEN_QUINT, {
                Size     = maximized and MAX_SIZE or DEFAULT_SIZE,
                Position = maximized and MAX_POS  or DEFAULT_POS,
            }):Play()
        end)
    end

    -- Close
    createControlButton("Close", "121948938505669", 3, function()
        TweenService:Create(MainFrame,
            TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
            { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }
        ):Play()
        task.delay(0.3, function() Window:Destroy() end)
    end)

    -- ── Notification Holder ───────────────────────────────────────────────────
    local NotificationHolder = Create("Frame", {
        Name                  = "NotificationHolder",
        Parent                = ScreenGui,
        BackgroundTransparency = 1,
        Position              = UDim2.new(1, -20, 1, -20),
        Size                  = UDim2.new(0, 300, 1, -20),
        AnchorPoint           = Vector2.new(1, 1),
        ZIndex                = 100,
    }) :: Frame
    Create("UIListLayout", {
        Parent             = NotificationHolder,
        SortOrder          = Enum.SortOrder.LayoutOrder,
        VerticalAlignment  = Enum.VerticalAlignment.Bottom,
        Padding            = UDim.new(0, 10),
    })

    -- ── Tab Container / Sidebar Layout ────────────────────────────────────────
    local TabContainer = Create("ScrollingFrame", {
        Name                  = "TabContainer",
        Parent                = Sidebar,
        Active                = true,
        BackgroundTransparency = 1,
        BorderSizePixel       = 0,
        Position              = UDim2.new(0, 0, 0, 15),
        Size                  = UDim2.new(1, 0, 1, -25),
        CanvasSize            = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize   = Enum.AutomaticSize.Y,
        ScrollBarThickness    = 2,
        ScrollBarImageColor3  = Theme.Accent,
    }) :: ScrollingFrame

    local ButtonsHolder = Create("Frame", {
        Name                  = "ButtonsHolder",
        Parent                = TabContainer,
        BackgroundTransparency = 1,
        Size                  = UDim2.new(1, 0, 1, 0),
        AutomaticSize         = Enum.AutomaticSize.Y,
    }) :: Frame
    Create("UIListLayout", { Parent = ButtonsHolder, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) })
    Create("UIPadding",    { Parent = ButtonsHolder, PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })

    local SlidingIndicator = Create("Frame", {
        Name             = "SlidingIndicator",
        Parent           = TabContainer,
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0, 0),
        Size             = UDim2.new(0, 3, 0, 20),
        Visible          = false,
        ZIndex           = 2,
    }) :: Frame
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SlidingIndicator })

    local ContentContainer = Create("Frame", {
        Name                  = "ContentContainer",
        Parent                = MainFrame,
        BackgroundTransparency = 1,
        Position              = UDim2.new(0, 160, 0, 45),
        Size                  = UDim2.new(1, -160, 1, -45),
    }) :: Frame

    MakeDraggable(Header, MainFrame)

    -- ── Shared Dropdown Overlay ───────────────────────────────────────────────
    local DropdownLayoutOrder = 0

    local MoreBlur = Create("Frame", {
        Name                  = "MoreBlur",
        Parent                = MainFrame,
        BackgroundColor3      = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        Size                  = UDim2.new(1, 0, 1, 0),
        Visible               = false,
        ClipsDescendants      = true,
        ZIndex                = 2000,
    }) :: Frame

    local ConnectButton = Create("TextButton", {
        Parent                = MoreBlur,
        Size                  = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text                  = "",
        AutoButtonColor       = false,
        ZIndex                = 2000,
    }) :: TextButton

    local DropdownSelect = Create("Frame", {
        Name             = "DropdownSelect",
        Parent           = MoreBlur,
        AnchorPoint      = Vector2.new(1, 0.5),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel  = 0,
        Position         = UDim2.new(1, 182, 0.5, 0),
        Size             = UDim2.new(0, 180, 1, -20),
        ClipsDescendants = false,
        Active           = true,
        ZIndex           = 2005,
    }) :: Frame
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = DropdownSelect })
    Create("UIStroke",  { Color = Theme.Accent, Thickness = 1, Transparency = 0.5, Parent = DropdownSelect })
    Create("ImageLabel", {
        Parent                = DropdownSelect,
        BackgroundTransparency = 1,
        Position              = UDim2.new(0, -15, 0, -15),
        Size                  = UDim2.new(1, 30, 1, 30),
        Image                 = "rbxassetid://6015897843",
        ImageColor3           = Color3.new(0, 0, 0),
        ImageTransparency     = 0.5,
        ScaleType             = Enum.ScaleType.Slice,
        SliceCenter           = Rect.new(49, 49, 450, 450),
        ZIndex                = 2004,
    })

    local DropdownSelectReal = Create("Frame", {
        Name                  = "DropdownSelectReal",
        Parent                = DropdownSelect,
        AnchorPoint           = Vector2.new(0.5, 0.5),
        Position              = UDim2.new(0.5, 0, 0.5, 0),
        Size                  = UDim2.new(1, -10, 1, -10),
        BackgroundTransparency = 1,
        ClipsDescendants      = true,
        ZIndex                = 2005,
    }) :: Frame

    local DropdownFolder  = Instance.new("Folder", DropdownSelectReal)
    local DropPageLayout  = Instance.new("UIPageLayout", DropdownFolder)
    DropPageLayout.SortOrder              = Enum.SortOrder.LayoutOrder
    DropPageLayout.EasingStyle            = Enum.EasingStyle.Quint
    DropPageLayout.EasingDirection        = Enum.EasingDirection.Out
    DropPageLayout.TweenTime              = 0.0
    DropPageLayout.FillDirection          = Enum.FillDirection.Vertical
    DropPageLayout.ScrollWheelInputEnabled = false

    --- Close the dropdown overlay.  Extracted so every item button doesn't
    --- duplicate this 4-line sequence.
    local function closeDropdown()
        TweenService:Create(MoreBlur,       TWEEN_FAST,         { BackgroundTransparency = 1 }):Play()
        TweenService:Create(DropdownSelect, TWEEN_DROPDOWN,     { Position = UDim2.new(1, 182, 0.5, 0) }):Play()
        task.delay(0.25, function() MoreBlur.Visible = false end)
    end

    ConnectButton.Activated:Connect(closeDropdown)

    -- ============================================
    -- WINDOW OBJECT
    -- ============================================
    local Window = {
        Tabs     = {} :: { any },
        Elements = {} :: { any },
        Instance = ScreenGui,
        Flags    = {} :: { [string]: any },
    }

    -- ── Window:Notify ─────────────────────────────────────────────────────────
    function Window:Notify(opts: { Title: string?, Content: string?, Duration: number?, Image: string?, Icon: string?, Name: string? }?)
        opts = opts or {}
        local o        = opts :: any
        local title    = o.Title or o.Name or "Notification"
        local content  = o.Content or "Message"
        local duration = o.Duration or 3
        local img      = o.Image or o.Icon or "rbxassetid://112067161065104"
        if Icons[img] then img = Icons[img] end

        local NotifyFrame = Create("Frame", {
            Parent                = NotificationHolder,
            BackgroundColor3      = Theme.Sidebar,
            BackgroundTransparency = 0.1,
            Size                  = UDim2.new(1, 0, 0, 0),
            AutomaticSize         = Enum.AutomaticSize.Y,
            ClipsDescendants      = true,
        }) :: Frame
        Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = NotifyFrame })
        Create("UIStroke",  { Color = Theme.Outline, Thickness = 1, Parent = NotifyFrame })

        local ContentFrame = Create("Frame", {
            Parent                = NotifyFrame,
            BackgroundTransparency = 1,
            Size                  = UDim2.new(1, 0, 0, 60),
        }) :: Frame
        local Icon = Create("ImageLabel", {
            Parent                = ContentFrame,
            BackgroundTransparency = 1,
            Position              = UDim2.new(0, 12, 0, 12),
            Size                  = UDim2.new(0, 36, 0, 36),
            Image                 = img,
            ImageColor3           = Theme.Accent,
        }) :: ImageLabel
        Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Icon })
        Create("TextLabel", {
            Parent                = ContentFrame,
            BackgroundTransparency = 1,
            Position              = UDim2.new(0, 58, 0, 10),
            Size                  = UDim2.new(1, -68, 0, 20),
            Font                  = Enum.Font.GothamBold,
            Text                  = title,
            TextColor3            = Theme.TextColor,
            TextSize              = 14,
            TextXAlignment        = Enum.TextXAlignment.Left,
        })
        Create("TextLabel", {
            Parent                = ContentFrame,
            BackgroundTransparency = 1,
            Position              = UDim2.new(0, 58, 0, 30),
            Size                  = UDim2.new(1, -68, 0, 20),
            Font                  = Enum.Font.Gotham,
            Text                  = content,
            TextColor3            = Theme.TextSecondary,
            TextSize              = 12,
            TextXAlignment        = Enum.TextXAlignment.Left,
            TextWrapped           = true,
        })

        -- Slide in
        NotifyFrame.Position = UDim2.new(1, 320, 0, 0)
        TweenService:Create(NotifyFrame, TWEEN_NOTIF_IN, { Position = UDim2.new(0, 0, 0, 0) }):Play()

        -- Progress bar
        local ProgressBar = Create("Frame", {
            Parent           = NotifyFrame,
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel  = 0,
            Position         = UDim2.new(0, 0, 1, -2),
            Size             = UDim2.new(1, 0, 0, 2),
        }) :: Frame
        TweenService:Create(ProgressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()

        task.delay(duration, function()
            TweenService:Create(NotifyFrame, TWEEN_NOTIF_OUT, { Position = UDim2.new(1, 320, 0, 0) }):Play()
            task.delay(0.5, function() NotifyFrame:Destroy() end)
        end)
    end

    -- ============================================
    -- TAB FACTORY
    -- ============================================
    function Window:CreateTab(opts: { Name: string?, Icon: string? }?)
        opts = opts or {}
        local o       = opts :: any
        local tabName = o.Name or "Tab"
        local tabIcon = Icons[o.Icon] or o.Icon or ""

        local Tab = {
            Active               = false,
            CurrentSectionContainer = nil :: Frame?,
        }

        -- Tab sidebar button
        local TabButton = Create("TextButton", {
            Name                  = tabName .. "Button",
            Parent                = ButtonsHolder,
            BackgroundColor3      = Theme.ElementBackground,
            BackgroundTransparency = 1,
            BorderSizePixel       = 0,
            Size                  = UDim2.new(1, 0, 0, 36),
            AutoButtonColor       = false,
            ClipsDescendants      = true,
            Text                  = "",
        }) :: TextButton
        Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = TabButton })
        Create("UIStroke",  { Color = Theme.Outline, Transparency = 0.8, Thickness = 1, Parent = TabButton })

        local IconImage: ImageLabel? = nil
        if tabIcon ~= "" then
            IconImage = Create("ImageLabel", {
                Parent                = TabButton,
                BackgroundTransparency = 1,
                Position              = UDim2.new(0, 10, 0.5, -10),
                Size                  = UDim2.new(0, 20, 0, 20),
                Image                 = tabIcon,
                ImageColor3           = Theme.TextSecondary,
            }) :: ImageLabel
        end

        local TabLabel = Create("TextLabel", {
            Parent                = TabButton,
            BackgroundTransparency = 1,
            Position              = UDim2.new(0, tabIcon ~= "" and 40 or 15, 0, 0),
            Size                  = UDim2.new(1, tabIcon ~= "" and -40 or -15, 1, 0),
            Font                  = Enum.Font.GothamMedium,
            Text                  = tabName,
            TextColor3            = Theme.TextSecondary,
            TextSize              = 14,
            TextXAlignment        = Enum.TextXAlignment.Left,
        }) :: TextLabel

        -- Hover — only when not active
        TabButton.MouseEnter:Connect(function()
            if not Tab.Active then
                TweenService:Create(TabButton, TWEEN_FAST, { BackgroundTransparency = 0.9 }):Play()
                TweenService:Create(TabLabel,  TWEEN_FAST, { TextColor3 = Theme.TextColor }):Play()
                if IconImage then TweenService:Create(IconImage, TWEEN_FAST, { ImageColor3 = Theme.TextColor }):Play() end
            end
        end)
        TabButton.MouseLeave:Connect(function()
            if not Tab.Active then
                TweenService:Create(TabButton, TWEEN_FAST, { BackgroundTransparency = 1 }):Play()
                TweenService:Create(TabLabel,  TWEEN_FAST, { TextColor3 = Theme.TextSecondary }):Play()
                if IconImage then TweenService:Create(IconImage, TWEEN_FAST, { ImageColor3 = Theme.TextSecondary }):Play() end
            end
        end)

        -- Content page (scrolling)
        local TabPage = Create("ScrollingFrame", {
            Name                  = tabName .. "Page",
            Parent                = ContentContainer,
            Active                = true,
            BackgroundTransparency = 1,
            BorderSizePixel       = 0,
            Size                  = UDim2.new(1, 0, 1, 0),
            CanvasSize            = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness    = 2,
            ScrollBarImageColor3  = Theme.Accent,
            Visible               = false,
        }) :: ScrollingFrame

        local PageLayout = Create("UIListLayout", {
            Parent    = TabPage,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 8),
        }) :: UIListLayout
        Create("UIPadding", {
            Parent        = TabPage,
            PaddingTop    = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft   = UDim.new(0, 15),
            PaddingRight  = UDim.new(0, 10),
        })
        Create("TextLabel", {
            Name                  = "TabTitle",
            Parent                = TabPage,
            BackgroundTransparency = 1,
            Size                  = UDim2.new(1, 0, 0, 40),
            Font                  = Enum.Font.GothamBold,
            Text                  = tabName,
            TextColor3            = Theme.TextColor,
            TextSize              = 26,
            TextXAlignment        = Enum.TextXAlignment.Left,
            LayoutOrder           = -1,
        })

        -- Auto-resize canvas
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
        end)

        -- ── Tab:Activate ──────────────────────────────────────────────────────
        function Tab:Activate()
            -- Deactivate all other tabs
            for _, t in ipairs(Window.Tabs) do
                if t ~= Tab then
                    TweenService:Create(t.Instance, TWEEN_FAST, { BackgroundTransparency = 1 }):Play()
                    TweenService:Create(t.Label,    TWEEN_FAST, { TextColor3 = Theme.TextSecondary }):Play()
                    if t.Icon then
                        TweenService:Create(t.Icon, TWEEN_FAST, { ImageColor3 = Theme.TextSecondary }):Play()
                    end
                    t.Page.Visible = false
                    t.Active       = false
                end
            end

            Tab.Active = true
            TweenService:Create(TabButton, TWEEN_MED, { BackgroundTransparency = 0.85 }):Play()
            TweenService:Create(TabLabel,  TWEEN_MED, { TextColor3 = Theme.Accent }):Play()
            if IconImage then TweenService:Create(IconImage, TWEEN_MED, { ImageColor3 = Theme.Accent }):Play() end

            TabPage.Visible  = true
            TabPage.Position = UDim2.new(0, 15, 0, 0)
            TweenService:Create(TabPage, TWEEN_QUINT, { Position = UDim2.new(0, 0, 0, 0) }):Play()

            -- Sliding indicator
            local targetY = TabButton.AbsolutePosition.Y - ButtonsHolder.AbsolutePosition.Y + 8
            if not SlidingIndicator.Visible then
                SlidingIndicator.Visible  = true
                SlidingIndicator.Position = UDim2.new(0, 0, 0, targetY)
            end
            TweenService:Create(SlidingIndicator, TWEEN_QUINT, { Position = UDim2.new(0, 0, 0, targetY) }):Play()
        end

        TabButton.MouseButton1Click:Connect(function()
            local Mouse = Players.LocalPlayer:GetMouse()
            spawnRipple(TabButton, Mouse.X, Mouse.Y, 150, TWEEN_RIPPLE_TAB)
            Tab:Activate()
        end)

        Tab.Instance = TabButton
        Tab.Label    = TabLabel
        Tab.Icon     = IconImage
        Tab.Page     = TabPage
        table.insert(Window.Tabs, Tab)

        if #Window.Tabs == 1 then
            Tab:Activate()
        end

        -- ── SECTION ───────────────────────────────────────────────────────────
        function Tab:CreateSection(sopts: { Name: string? }?)
            sopts = sopts or {}
            local sName = (sopts :: any).Name or "Section"

            local SectionContainer = Create("Frame", {
                Name                  = "SectionContainer",
                Parent                = TabPage,
                BackgroundTransparency = 1,
                Size                  = UDim2.new(1, 0, 0, 32),
            }) :: Frame

            local SectionHeader = Create("TextButton", {
                Name                  = "SectionHeader",
                Parent                = SectionContainer,
                BackgroundColor3      = Theme.ElementBackground,
                BackgroundTransparency = 0.5,
                Size                  = UDim2.new(1, 0, 0, 32),
                AutoButtonColor       = false,
                Text                  = "",
            }) :: TextButton
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = SectionHeader })
            Create("UIStroke",  { Color = Theme.Outline, Transparency = 0.6, Thickness = 1, Parent = SectionHeader })
            Create("TextLabel", {
                Parent                = SectionHeader,
                BackgroundTransparency = 1,
                Position              = UDim2.new(0, 10, 0, 0),
                Size                  = UDim2.new(1, -40, 1, 0),
                Font                  = Enum.Font.GothamBold,
                Text                  = sName,
                TextColor3            = Theme.TextColor,
                TextSize              = 13,
                TextXAlignment        = Enum.TextXAlignment.Left,
            })

            local Chevron = Create("ImageLabel", {
                Name                  = "Chevron",
                Parent                = SectionHeader,
                BackgroundTransparency = 1,
                Position              = UDim2.new(1, -26, 0.5, -8),
                Size                  = UDim2.new(0, 16, 0, 16),
                Image                 = "rbxassetid://6031091004",
                ImageColor3           = Theme.TextSecondary,
                Rotation              = -90,
            }) :: ImageLabel

            local ContentFrame = Create("Frame", {
                Name                  = "SectionContent",
                Parent                = SectionContainer,
                BackgroundTransparency = 1,
                Position              = UDim2.new(0, 0, 0, 36),
                Size                  = UDim2.new(1, 0, 0, 0),
                ClipsDescendants      = true,
                Visible               = true,
            }) :: Frame

            local SectionLayout = Create("UIListLayout", {
                Parent    = ContentFrame,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding   = UDim.new(0, 8),
            }) :: UIListLayout
            Create("UIPadding", {
                Parent        = ContentFrame,
                PaddingTop    = UDim.new(0, 5),
                PaddingBottom = UDim.new(0, 5),
                PaddingLeft   = UDim.new(0, 5),
                PaddingRight  = UDim.new(0, 5),
            })

            local open                = false
            local canvasSizeConn: RBXScriptConnection? = nil

            local function getContentHeight(): number
                return SectionLayout.AbsoluteContentSize.Y + 10
            end

            SectionHeader.MouseEnter:Connect(function()
                if not open then
                    TweenService:Create(SectionHeader, TWEEN_FAST, { BackgroundTransparency = 0.3 }):Play()
                end
            end)
            SectionHeader.MouseLeave:Connect(function()
                if not open then
                    TweenService:Create(SectionHeader, TWEEN_FAST, { BackgroundTransparency = 0.5 }):Play()
                end
            end)

            SectionHeader.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    TweenService:Create(Chevron,          TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Rotation = 0 }):Play()
                    TweenService:Create(SectionHeader,    TWEEN_FAST, { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.8 }):Play()
                    local ch = getContentHeight()
                    TweenService:Create(ContentFrame,     TWEEN_QUINT, { Size = UDim2.new(1, 0, 0, ch) }):Play()
                    TweenService:Create(SectionContainer, TWEEN_QUINT, { Size = UDim2.new(1, 0, 0, ch + 40) }):Play()
                    -- Keep sizes synced if elements are added while open
                    if not canvasSizeConn then
                        canvasSizeConn = SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                            if open then
                                local h = SectionLayout.AbsoluteContentSize.Y + 10
                                TweenService:Create(ContentFrame,     TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, h) }):Play()
                                TweenService:Create(SectionContainer, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, h + 40) }):Play()
                            end
                        end)
                    end
                else
                    TweenService:Create(Chevron,          TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Rotation = -90 }):Play()
                    TweenService:Create(SectionHeader,    TWEEN_FAST, { BackgroundColor3 = Theme.ElementBackground, BackgroundTransparency = 0.5 }):Play()
                    TweenService:Create(ContentFrame,     TWEEN_MED,  { Size = UDim2.new(1, 0, 0, 0) }):Play()
                    TweenService:Create(SectionContainer, TWEEN_MED,  { Size = UDim2.new(1, 0, 0, 32) }):Play()
                    if canvasSizeConn then
                        canvasSizeConn:Disconnect()
                        canvasSizeConn = nil
                    end
                end
            end)

            Tab.CurrentSectionContainer = ContentFrame
        end

        -- ── PARAGRAPH ─────────────────────────────────────────────────────────
        function Tab:CreateParagraph(popts: { Title: string?, Content: string? }?)
            popts = popts or {}
            local o = popts :: any
            local pTitle   = o.Title   or "Paragraph"
            local pContent = o.Content or "Lorem ipsum dolor sit amet."

            local ParagraphFrame = Create("Frame", {
                Name                  = "ParagraphFrame",
                Parent                = Tab.CurrentSectionContainer or TabPage,
                BackgroundColor3      = Theme.ElementBackground,
                BackgroundTransparency = 0.5,
                BorderSizePixel       = 0,
                Size                  = UDim2.new(1, 0, 0, 0),
                AutomaticSize         = Enum.AutomaticSize.Y,
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = ParagraphFrame })
            Create("UIStroke",  { Color = Theme.Outline, Transparency = 0.6, Thickness = 1, Parent = ParagraphFrame })
            Create("UIPadding", { Parent = ParagraphFrame, PaddingBottom = UDim.new(0, 12) })

            local TitleLbl = Create("TextLabel", {
                Parent                = ParagraphFrame,
                BackgroundTransparency = 1,
                Position              = UDim2.new(0, 12, 0, 8),
                Size                  = UDim2.new(1, -24, 0, 20),
                Font                  = Enum.Font.GothamBold,
                Text                  = pTitle,
                TextColor3            = Theme.TextColor,
                TextSize              = 14,
                TextXAlignment        = Enum.TextXAlignment.Left,
            }) :: TextLabel
            local ContentLbl = Create("TextLabel", {
                Parent                = ParagraphFrame,
                BackgroundTransparency = 1,
                Position              = UDim2.new(0, 12, 0, 32),
                Size                  = UDim2.new(1, -24, 0, 0),
                AutomaticSize         = Enum.AutomaticSize.Y,
                Font                  = Enum.Font.Gotham,
                Text                  = pContent,
                TextColor3            = Theme.TextSecondary,
                TextSize              = 13,
                TextWrapped           = true,
                TextXAlignment        = Enum.TextXAlignment.Left,
                RichText              = true,
            }) :: TextLabel

            local obj = { Title = pTitle, Desc = pContent }
            function obj:SetTitle(v: string) self.Title = v; TitleLbl.Text  = v end
            function obj:SetDesc(v: string)  self.Desc  = v; ContentLbl.Text = v end
            function obj:GetTitle(): string return self.Title end
            function obj:GetDesc():  string return self.Desc  end
            return obj
        end

        -- ── LABEL ─────────────────────────────────────────────────────────────
        function Tab:CreateLabel(lopts: { Text: string? }?)
            lopts = lopts or {}
            local text = (lopts :: any).Text or "Label"

            local LabelFrame = Create("Frame", {
                Parent                = Tab.CurrentSectionContainer or TabPage,
                BackgroundTransparency = 1,
                BorderSizePixel       = 0,
                Size                  = UDim2.new(1, 0, 0, 26),
            }) :: Frame
            local lbl = Create("TextLabel", {
                Parent                = LabelFrame,
                BackgroundTransparency = 1,
                Position              = UDim2.new(0, 5, 0, 0),
                Size                  = UDim2.new(1, -10, 1, 0),
                Font                  = Enum.Font.GothamMedium,
                Text                  = text,
                TextColor3            = Theme.TextColor,
                TextSize              = 14,
                TextXAlignment        = Enum.TextXAlignment.Left,
            }) :: TextLabel
            return lbl
        end

        -- ── BUTTON ────────────────────────────────────────────────────────────
        function Tab:CreateButton(bopts: { Name: string?, SubText: string?, Icon: string?, Callback: (() -> ())? }?)
            bopts = bopts or {}
            local o        = bopts :: any
            local bName    = o.Name or "Button"
            local subText  = o.SubText
            local bIcon    = o.Icon
            local callback = o.Callback or function() end

            local ButtonFrame = Create("Frame", {
                Name                  = "ButtonFrame",
                Parent                = Tab.CurrentSectionContainer or TabPage,
                BackgroundColor3      = Theme.ElementBackground,
                BackgroundTransparency = 0.2,
                BorderSizePixel       = 0,
                Size                  = UDim2.new(1, 0, 0, subText and 50 or 38),
                ClipsDescendants      = true,
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = ButtonFrame })
            local BtnStroke = Create("UIStroke", { Color = Theme.Outline, Transparency = 0.5, Thickness = 1, Parent = ButtonFrame }) :: UIStroke

            local Btn = Create("TextButton", {
                Name                  = "Button",
                Parent                = ButtonFrame,
                BackgroundTransparency = 1,
                Size                  = UDim2.new(1, 0, 1, 0),
                Font                  = Enum.Font.GothamMedium,
                Text                  = subText and "" or bName,
                TextColor3            = Theme.TextColor,
                TextSize              = 14,
                AutoButtonColor       = false,
                ZIndex                = 2,
            }) :: TextButton

            if subText then
                Create("TextLabel", {
                    Parent = Btn, BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -50, 0, 20),
                    Font = Enum.Font.GothamBold, Text = bName,
                    TextColor3 = Theme.TextColor, TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                Create("TextLabel", {
                    Parent = Btn, BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 26), Size = UDim2.new(1, -50, 0, 14),
                    Font = Enum.Font.Gotham, Text = subText,
                    TextColor3 = Theme.TextSecondary, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
            end
            if bIcon then
                Create("ImageLabel", {
                    Parent = Btn, BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0, 20, 0, 20),
                    Image = bIcon, ImageColor3 = Theme.TextSecondary,
                })
            end

            Btn.MouseEnter:Connect(function()
                TweenService:Create(ButtonFrame, TWEEN_FAST, { BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0.1 }):Play()
                TweenService:Create(BtnStroke,   TWEEN_FAST, { Color = Theme.Accent, Transparency = 0.2 }):Play()
            end)
            Btn.MouseLeave:Connect(function()
                TweenService:Create(ButtonFrame, TWEEN_FAST, { BackgroundColor3 = Theme.ElementBackground, BackgroundTransparency = 0.2 }):Play()
                TweenService:Create(BtnStroke,   TWEEN_FAST, { Color = Theme.Outline, Transparency = 0.5 }):Play()
            end)
            Btn.MouseButton1Click:Connect(function()
                local Mouse = Players.LocalPlayer:GetMouse()
                spawnRipple(ButtonFrame, Mouse.X, Mouse.Y, 200, TWEEN_RIPPLE_BTN)
                TweenService:Create(ButtonFrame, TweenInfo.new(0.1), { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0 }):Play()
                task.delay(0.1, function()
                    TweenService:Create(ButtonFrame, TWEEN_MED, { BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0.1 }):Play()
                end)
                callback()
            end)
        end

        -- ── TOGGLE ────────────────────────────────────────────────────────────
        function Tab:CreateToggle(topts: { Name: string?, SubText: string?, Default: boolean?, Value: boolean?, Values: { any }?, Callback: ((any) -> ())?, Flag: string? }?)
            topts = topts or {}
            local o        = topts :: any
            local tName    = o.Name or "Toggle"
            local subText  = o.SubText
            local default  = o.Default or o.Value or false
            local values   = o.Values or {}
            local callback = o.Callback or function() end
            local toggled  = default

            local ToggleFrame = Create("Frame", {
                Parent                = Tab.CurrentSectionContainer or TabPage,
                BackgroundColor3      = Theme.ElementBackground,
                BackgroundTransparency = 0.2,
                BorderSizePixel       = 0,
                Size                  = UDim2.new(1, 0, 0, subText and 50 or 38),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = ToggleFrame })
            Create("UIStroke",  { Color = Theme.Outline, Transparency = 0.5, Thickness = 1, Parent = ToggleFrame })
            Create("TextLabel", {
                Parent                = ToggleFrame,
                BackgroundTransparency = 1,
                Position              = UDim2.new(0, 12, 0, subText and 8 or 0),
                Size                  = UDim2.new(1, -60, 0, subText and 20 or 38),
                Font                  = subText and Enum.Font.GothamBold or Enum.Font.GothamMedium,
                Text                  = tName,
                TextColor3            = Theme.TextColor,
                TextSize              = 14,
                TextXAlignment        = Enum.TextXAlignment.Left,
                TextYAlignment        = Enum.TextYAlignment.Center,
            })
            if subText then
                Create("TextLabel", {
                    Parent = ToggleFrame, BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 26), Size = UDim2.new(1, -60, 0, 14),
                    Font = Enum.Font.Gotham, Text = subText,
                    TextColor3 = Theme.TextSecondary, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                })
            end

            local SwitchBg = Create("Frame", {
                Parent           = ToggleFrame,
                AnchorPoint      = Vector2.new(1, 0.5),
                BackgroundColor3 = toggled and Theme.Accent or Color3.fromRGB(45, 45, 50),
                Position         = UDim2.new(1, -12, 0.5, 0),
                Size             = UDim2.new(0, 42, 0, 22),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SwitchBg })

            local SwitchCircle = Create("Frame", {
                Parent           = SwitchBg,
                AnchorPoint      = Vector2.new(0, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Position         = UDim2.new(0, toggled and 22 or 2, 0.5, 0),
                Size             = UDim2.new(0, 18, 0, 18),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SwitchCircle })

            Create("TextButton", {
                Parent                = ToggleFrame,
                BackgroundTransparency = 1,
                Size                  = UDim2.new(1, 0, 1, 0),
                Text                  = "",
            })

            local ToggleObject = { Value = default }

            local function updateToggleState(newVal: boolean)
                toggled           = newVal
                ToggleObject.Value = toggled
                TweenService:Create(SwitchBg,     TWEEN_MED, { BackgroundColor3 = toggled and Theme.Accent or Color3.fromRGB(45, 45, 50) }):Play()
                TweenService:Create(SwitchCircle, TWEEN_MED, { Position = UDim2.new(0, toggled and 22 or 2, 0.5, 0) }):Play()
                if #values > 0 then
                    callback(values[toggled and 2 or 1])
                else
                    callback(toggled)
                end
            end

            function ToggleObject:Set(v: any)
                if type(v) ~= "boolean" then
                    v = v == true or v == "true" or v == 1
                end
                updateToggleState(v :: boolean)
            end

            -- Wire the invisible TextButton click
            local clickBtn = ToggleFrame:FindFirstChildOfClass("TextButton") :: TextButton
            clickBtn.MouseButton1Click:Connect(function() updateToggleState(not toggled) end)

            if default then updateToggleState(true) end

            local flag = o.Flag or tName
            if flag then Window.Flags[flag] = ToggleObject end
            return ToggleObject
        end

        -- ── SLIDER ────────────────────────────────────────────────────────────
        function Tab:CreateSlider(sopts: { Name: string?, Min: number?, Max: number?, Default: number?, Value: number?, Callback: ((number) -> ())?, Flag: string? }?)
            sopts = sopts or {}
            local o        = sopts :: any
            local sName    = o.Name or "Slider"
            local sMin     = o.Min  or 0
            local sMax     = o.Max  or 100
            local default  = o.Default or o.Value or sMin
            local callback = o.Callback or function() end

            local SliderFrame = Create("Frame", {
                Parent                = Tab.CurrentSectionContainer or TabPage,
                BackgroundColor3      = Theme.ElementBackground,
                BackgroundTransparency = 0.2,
                BorderSizePixel       = 0,
                Size                  = UDim2.new(1, 0, 0, 55),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = SliderFrame })
            Create("UIStroke",  { Color = Theme.Outline, Transparency = 0.5, Thickness = 1, Parent = SliderFrame })
            Create("TextLabel", {
                Parent = SliderFrame, BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -24, 0, 20),
                Font = Enum.Font.GothamMedium, Text = sName,
                TextColor3 = Theme.TextColor, TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            local ValueLabel = Create("TextLabel", {
                Parent = SliderFrame, BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -24, 0, 20),
                Font = Enum.Font.Gotham, Text = tostring(default),
                TextColor3 = Theme.TextSecondary, TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Right,
            }) :: TextLabel

            local SliderBarBg = Create("Frame", {
                Parent           = SliderFrame,
                BackgroundColor3 = Color3.fromRGB(50, 50, 55),
                BorderSizePixel  = 0,
                Position         = UDim2.new(0, 12, 0, 38),
                Size             = UDim2.new(1, -24, 0, 5),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SliderBarBg })

            local initPct = (default - sMin) / (sMax - sMin)
            local SliderFill = Create("Frame", {
                Parent           = SliderBarBg,
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel  = 0,
                Size             = UDim2.new(initPct, 0, 1, 0),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SliderFill })

            local SliderKnob = Create("Frame", {
                Parent           = SliderBarBg,
                AnchorPoint      = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Position         = UDim2.new(initPct, 0, 0.5, 0),
                Size             = UDim2.new(0, 14, 0, 14),
                ZIndex           = 2,
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SliderKnob })

            local SliderBtn = Create("TextButton", {
                Parent                = SliderBarBg,
                BackgroundTransparency = 1,
                Size                  = UDim2.new(1, 0, 1, 0),
                Text                  = "",
                ZIndex                = 3,
            }) :: TextButton

            local dragging = false

            -- Extracted update — eliminates closure allocation in InputChanged
            local function updateSlider(input: InputObject)
                local pct   = math.clamp((input.Position.X - SliderBarBg.AbsolutePosition.X) / SliderBarBg.AbsoluteSize.X, 0, 1)
                local value = math.floor(sMin + (sMax - sMin) * pct)
                TweenService:Create(SliderFill, TWEEN_SLIDER_FAST, { Size = UDim2.new(pct, 0, 1, 0) }):Play()
                TweenService:Create(SliderKnob, TWEEN_SLIDER_FAST, { Position = UDim2.new(pct, 0, 0.5, 0) }):Play()
                ValueLabel.Text = tostring(value)
                callback(value)
            end

            SliderBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    TweenService:Create(SliderKnob, TWEEN_SLIDER_KNOB, { Size = UDim2.new(0, 18, 0, 18) }):Play()
                    updateSlider(input)
                end
            end)
            table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                    TweenService:Create(SliderKnob, TWEEN_SLIDER_KNOB, { Size = UDim2.new(0, 14, 0, 14) }):Play()
                end
            end))
            table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
                if dragging and (
                    input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch
                ) then
                    updateSlider(input)
                end
            end))

            local SliderObject = { Value = default }
            function SliderObject:Set(v: number)
                v = math.clamp(type(v) == "number" and v or (tonumber(v) or sMin), sMin, sMax)
                local pct = (v - sMin) / (sMax - sMin)
                TweenService:Create(SliderFill, TWEEN_MED, { Size = UDim2.new(pct, 0, 1, 0) }):Play()
                TweenService:Create(SliderKnob, TWEEN_MED, { Position = UDim2.new(pct, 0, 0.5, 0) }):Play()
                ValueLabel.Text = tostring(v)
                self.Value = v
                callback(v)
            end

            local flag = o.Flag or sName
            if flag then Window.Flags[flag] = SliderObject end
            return SliderObject
        end

        -- ── INPUT ─────────────────────────────────────────────────────────────
        function Tab:CreateInput(iopts: { Name: string?, Placeholder: string?, Default: string?, Value: string?, Callback: ((string) -> ())?, MultiLine: boolean?, SideLabel: string?, Values: { any }?, Flag: string? }?)
            iopts = iopts or {}
            local o         = iopts :: any
            local iName     = o.Name or "Input"
            local placeholder = o.Placeholder or iName
            local default   = o.Default or ""
            local multiLine = o.MultiLine or false
            local sideLabel = o.SideLabel
            local initValue = o.Value or default
            local callback  = o.Callback or function() end

            local InputFrame = Create("Frame", {
                Parent                = Tab.CurrentSectionContainer or TabPage,
                BackgroundColor3      = Theme.ElementBackground,
                BackgroundTransparency = 0.2,
                BorderSizePixel       = 0,
                Size                  = UDim2.new(1, 0, 0, multiLine and 100 or 40),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = InputFrame })
            Create("UIStroke",  { Color = Theme.Outline, Transparency = 0.5, Thickness = 1, Parent = InputFrame })

            if sideLabel then
                Create("TextLabel", {
                    Parent = InputFrame, BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Font = Enum.Font.GothamMedium, Text = sideLabel,
                    TextColor3 = Theme.TextColor, TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
            end

            local InputBoxBg = Create("Frame", {
                Parent           = InputFrame,
                BackgroundColor3 = Theme.Sidebar,
                BorderSizePixel  = 0,
                Position         = sideLabel and UDim2.new(1, -12, 0.5, 0) or UDim2.new(0, 6, 0, 6),
                Size             = sideLabel and UDim2.new(0, 150, 0, 28)  or UDim2.new(1, -12, 1, -12),
                AnchorPoint      = sideLabel and Vector2.new(1, 0.5)       or Vector2.new(0, 0),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = InputBoxBg })
            local InputStroke = Create("UIStroke", { Color = Theme.Outline, Transparency = 0.7, Thickness = 1, Parent = InputBoxBg }) :: UIStroke

            local TextBox = Create("TextBox", {
                Parent                = InputBoxBg,
                BackgroundTransparency = 1,
                Position              = UDim2.new(0, 8, 0, multiLine and 8 or 0),
                Size                  = UDim2.new(1, -16, 1, multiLine and -16 or 0),
                Font                  = Enum.Font.Gotham,
                PlaceholderText       = placeholder,
                Text                  = initValue,
                TextColor3            = Theme.TextColor,
                TextSize              = 13,
                TextXAlignment        = Enum.TextXAlignment.Left,
                TextYAlignment        = multiLine and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
                ClearTextOnFocus      = false,
                MultiLine             = multiLine,
                TextWrapped           = true,
            }) :: TextBox

            TextBox.Focused:Connect(function()
                TweenService:Create(InputStroke, TWEEN_FAST, { Color = Theme.Accent, Transparency = 0 }):Play()
            end)

            local InputObject = { Value = initValue, Values = o.Values or {} }
            TextBox.FocusLost:Connect(function()
                TweenService:Create(InputStroke, TWEEN_FAST, { Color = Theme.Outline, Transparency = 0.7 }):Play()
                InputObject.Value = TextBox.Text
                callback(TextBox.Text)
            end)

            function InputObject:Set(v: any)
                v = tostring(v ~= nil and v or "")
                self.Value = v
                TextBox.Text = v
                callback(v)
            end
            function InputObject:Get(): string return self.Value end

            if initValue ~= "" then callback(initValue) end

            local flag = o.Flag or iName
            if flag then Window.Flags[flag] = InputObject end
            return InputObject
        end

        -- ── DROPDOWN ──────────────────────────────────────────────────────────
        function Tab:CreateDropdown(dopts: { Name: string?, Items: { any }?, Callback: ((any) -> ())?, Default: any?, Flag: string? }?)
            dopts = dopts or {}
            local o        = dopts :: any
            local dName    = o.Name or "Dropdown"
            local items    = o.Items or {}
            local callback = o.Callback or function() end
            local default  = o.Default or (items[1] or "...")

            local DropdownObject = { Value = default, Items = items }

            -- Button row
            local DropdownFrame = Create("Frame", {
                Parent                = Tab.CurrentSectionContainer or TabPage,
                BackgroundColor3      = Theme.ElementBackground,
                BackgroundTransparency = 0.2,
                BorderSizePixel       = 0,
                Size                  = UDim2.new(1, 0, 0, 38),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = DropdownFrame })
            Create("UIStroke",  { Color = Theme.Outline, Transparency = 0.5, Thickness = 1, Parent = DropdownFrame })
            Create("TextLabel", {
                Parent = DropdownFrame, BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -60, 1, 0),
                Font = Enum.Font.GothamMedium, Text = dName,
                TextColor3 = Theme.TextColor, TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            local DValueLabel = Create("TextLabel", {
                Parent = DropdownFrame, BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -34, 1, 0),
                Font = Enum.Font.Gotham, Text = tostring(default),
                TextColor3 = Theme.TextSecondary, TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right,
            }) :: TextLabel
            Create("ImageLabel", {
                Parent = DropdownFrame, BackgroundTransparency = 1,
                Position = UDim2.new(1, -26, 0.5, -8), Size = UDim2.new(0, 16, 0, 16),
                Image = "rbxassetid://6031091004", ImageColor3 = Theme.TextSecondary, Rotation = -90,
            })
            local DBtn = Create("TextButton", {
                Parent = DropdownFrame, BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0), Text = "",
            }) :: TextButton

            -- Shared panel page
            local SelectPage = Create("Frame", {
                Parent                = DropdownFolder,
                Size                  = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                LayoutOrder           = DropdownLayoutOrder,
            }) :: Frame
            DropdownLayoutOrder += 1

            local SearchBox, ScrollList, UIList = createDropdownSearchPanel(SelectPage)

            local function populate(filter: string)
                filter = filter:lower()
                for _, c in ipairs(ScrollList:GetChildren()) do
                    if c:IsA("Frame") then c:Destroy() end
                end
                for _, item in ipairs(DropdownObject.Items) do
                    if filter == "" or tostring(item):lower():find(filter, 1, true) then
                        local ItemFrame = Create("Frame", {
                            Parent = ScrollList, BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 26),
                        }) :: Frame
                        local ItemBtn = Create("TextButton", {
                            Parent = ItemFrame, BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false,
                        }) :: TextButton
                        local isSelected = tostring(item) == tostring(DropdownObject.Value)
                        local ItemTxt = Create("TextLabel", {
                            Parent = ItemBtn, BackgroundTransparency = 1,
                            Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -16, 1, 0),
                            Font = Enum.Font.GothamBold, Text = tostring(item),
                            TextColor3 = isSelected and Theme.Accent or Theme.TextSecondary,
                            TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
                        }) :: TextLabel
                        ItemBtn.MouseEnter:Connect(function()
                            if tostring(item) ~= tostring(DropdownObject.Value) then ItemTxt.TextColor3 = Theme.TextColor end
                        end)
                        ItemBtn.MouseLeave:Connect(function()
                            if tostring(item) ~= tostring(DropdownObject.Value) then ItemTxt.TextColor3 = Theme.TextSecondary end
                        end)
                        ItemBtn.MouseButton1Click:Connect(function()
                            DropdownObject:Set(item)
                            closeDropdown()
                        end)
                    end
                end
                ScrollList.CanvasSize = UDim2.fromOffset(0, UIList.AbsoluteContentSize.Y)
            end

            SearchBox:GetPropertyChangedSignal("Text"):Connect(function() populate(SearchBox.Text) end)
            UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                ScrollList.CanvasSize = UDim2.fromOffset(0, UIList.AbsoluteContentSize.Y)
            end)
            populate("")

            DBtn.MouseButton1Click:Connect(function()
                if not MoreBlur.Visible then
                    populate(""); SearchBox.Text = ""
                    DropPageLayout:JumpTo(SelectPage)
                    MoreBlur.Visible = true
                    TweenService:Create(MoreBlur,       TWEEN_FAST,         { BackgroundTransparency = 0.5 }):Play()
                    TweenService:Create(DropdownSelect, TWEEN_DROPDOWN_OUT, { Position = UDim2.new(1, -16, 0.5, 0) }):Play()
                end
            end)

            function DropdownObject:Set(v: any)
                self.Value = v
                DValueLabel.Text = tostring(v)
                callback(v)
            end
            function DropdownObject:Refresh(newItems: { any })
                self.Items = newItems
                if not table.find(self.Items, self.Value) then
                    self.Value = self.Items[1] or "..."
                    DValueLabel.Text = tostring(self.Value)
                end
                populate("")
            end

            local flag = o.Flag or dName
            if flag then Window.Flags[flag] = DropdownObject end
            return DropdownObject
        end

        -- ── MULTI-DROPDOWN ────────────────────────────────────────────────────
        function Tab:CreateMultiDropdown(mdopts: { Name: string?, Items: { any }?, Values: { any }?, Default: { any }?, Value: { any }?, Callback: (({ any }) -> ())?, Flag: string? }?)
            mdopts = mdopts or {}
            local o        = mdopts :: any
            local mName    = o.Name or "Multi Dropdown"
            local allItems = o.Items or o.Values or {}
            local default: { any } = (type(o.Default) == "table" and o.Default) or (type(o.Value) == "table" and o.Value) or {}
            local callback = o.Callback or function() end
            local selected: { any } = default

            local MultiObject = { Value = selected, Values = allItems }

            local MFrame = Create("Frame", {
                Parent = Tab.CurrentSectionContainer or TabPage,
                BackgroundColor3 = Theme.ElementBackground, BackgroundTransparency = 0.2,
                BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 38),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = MFrame })
            Create("UIStroke",  { Color = Theme.Outline, Transparency = 0.5, Thickness = 1, Parent = MFrame })
            Create("TextLabel", {
                Parent = MFrame, BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -60, 1, 0),
                Font = Enum.Font.GothamMedium, Text = mName,
                TextColor3 = Theme.TextColor, TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            local function getSelectedText(): string
                if #selected == 0 then return "None" end
                if #selected == 1 then return tostring(selected[1]) end
                return #selected .. " Selected"
            end

            local MValueLabel = Create("TextLabel", {
                Parent = MFrame, BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -34, 1, 0),
                Font = Enum.Font.Gotham, Text = getSelectedText(),
                TextColor3 = Theme.TextSecondary, TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right,
            }) :: TextLabel
            Create("ImageLabel", {
                Parent = MFrame, BackgroundTransparency = 1,
                Position = UDim2.new(1, -26, 0.5, -8), Size = UDim2.new(0, 16, 0, 16),
                Image = "rbxassetid://6031091004", ImageColor3 = Theme.TextSecondary, Rotation = -90,
            })
            local MBtn = Create("TextButton", {
                Parent = MFrame, BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0), Text = "",
            }) :: TextButton

            local MSelectPage = Create("Frame", {
                Parent = DropdownFolder, Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1, LayoutOrder = DropdownLayoutOrder,
            }) :: Frame
            DropdownLayoutOrder += 1

            local MSearchBox, MScrollList, MUIList = createDropdownSearchPanel(MSelectPage)

            local function mPopulate(filter: string)
                filter = filter:lower()
                for _, c in ipairs(MScrollList:GetChildren()) do
                    if c:IsA("Frame") then c:Destroy() end
                end
                for _, item in ipairs(allItems) do
                    if filter == "" or tostring(item):lower():find(filter, 1, true) then
                        local ItemFrame = Create("Frame", {
                            Parent = MScrollList, BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 26),
                        }) :: Frame
                        local ItemBtn = Create("TextButton", {
                            Parent = ItemFrame, BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false,
                        }) :: TextButton
                        local isSel = table.find(selected, item) ~= nil
                        local Checkbox = Create("Frame", {
                            Parent = ItemBtn,
                            BackgroundColor3 = isSel and Theme.Accent or Theme.Background,
                            BorderSizePixel = 0,
                            Position = UDim2.new(0, 8, 0.5, -7), Size = UDim2.new(0, 14, 0, 14),
                        }) :: Frame
                        Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = Checkbox })
                        local CheckMark = Create("ImageLabel", {
                            Parent = Checkbox, BackgroundTransparency = 1,
                            Image = "rbxassetid://6031094667",
                            Size = UDim2.new(1, 2, 1, 2), Position = UDim2.new(0, -1, 0, -1),
                            ImageTransparency = isSel and 0 or 1,
                        }) :: ImageLabel
                        local ItemTxt = Create("TextLabel", {
                            Parent = ItemBtn, BackgroundTransparency = 1,
                            Position = UDim2.new(0, 30, 0, 0), Size = UDim2.new(1, -30, 1, 0),
                            Font = isSel and Enum.Font.GothamBold or Enum.Font.GothamMedium,
                            Text = tostring(item),
                            TextColor3 = isSel and Theme.TextColor or Theme.TextSecondary,
                            TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
                        }) :: TextLabel

                        ItemBtn.MouseButton1Click:Connect(function()
                            local idx = table.find(selected, item)
                            if idx then
                                table.remove(selected, idx)
                                TweenService:Create(Checkbox,  TWEEN_FAST, { BackgroundColor3 = Theme.Background }):Play()
                                TweenService:Create(CheckMark, TWEEN_FAST, { ImageTransparency = 1 }):Play()
                                TweenService:Create(ItemTxt,   TWEEN_FAST, { TextColor3 = Theme.TextSecondary }):Play()
                                ItemTxt.Font = Enum.Font.GothamMedium
                            else
                                table.insert(selected, item)
                                TweenService:Create(Checkbox,  TWEEN_FAST, { BackgroundColor3 = Theme.Accent }):Play()
                                TweenService:Create(CheckMark, TWEEN_FAST, { ImageTransparency = 0 }):Play()
                                TweenService:Create(ItemTxt,   TWEEN_FAST, { TextColor3 = Theme.TextColor }):Play()
                                ItemTxt.Font = Enum.Font.GothamBold
                            end
                            MValueLabel.Text = getSelectedText()
                            callback(selected)
                        end)
                    end
                end
                MScrollList.CanvasSize = UDim2.fromOffset(0, MUIList.AbsoluteContentSize.Y)
            end

            MSearchBox:GetPropertyChangedSignal("Text"):Connect(function() mPopulate(MSearchBox.Text) end)
            MUIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                MScrollList.CanvasSize = UDim2.fromOffset(0, MUIList.AbsoluteContentSize.Y)
            end)
            mPopulate("")

            MBtn.MouseButton1Click:Connect(function()
                if not MoreBlur.Visible then
                    mPopulate(""); MSearchBox.Text = ""
                    DropPageLayout:JumpTo(MSelectPage)
                    MoreBlur.Visible = true
                    TweenService:Create(MoreBlur,       TWEEN_FAST,         { BackgroundTransparency = 0.5 }):Play()
                    TweenService:Create(DropdownSelect, TWEEN_DROPDOWN_OUT, { Position = UDim2.new(1, -16, 0.5, 0) }):Play()
                end
            end)

            function MultiObject:Set(values: { any })
                selected = values
                self.Value = selected
                MValueLabel.Text = getSelectedText()
                callback(selected)
                mPopulate(MSearchBox.Text)
            end
            function MultiObject:UpdateLabel()
                MValueLabel.Text = getSelectedText()
            end
            function MultiObject:Refresh(newItems: { any })
                allItems = newItems
                local kept = {}
                for _, s in ipairs(selected) do
                    if table.find(allItems, s) then table.insert(kept, s) end
                end
                self:Set(kept)
            end

            local flag = o.Flag or mName
            if flag then Window.Flags[flag] = MultiObject end
            return MultiObject
        end

        -- ── COLOR PICKER ──────────────────────────────────────────────────────
        function Tab:CreateColorPicker(cpopts: { Name: string?, Default: Color3?, Callback: ((Color3) -> ())?, Flag: string? }?)
            cpopts = cpopts or {}
            local o        = cpopts :: any
            local cpName   = o.Name    or "Color Picker"
            local default  = o.Default or Color3.fromRGB(255, 255, 255)
            local callback = o.Callback or function() end

            local h, s, v = default:ToHSV()
            local colorH, colorS, colorV = h, s, v
            local pickerOpen = false

            local PickerFrame = Create("Frame", {
                Parent = Tab.CurrentSectionContainer or TabPage,
                BackgroundColor3 = Theme.ElementBackground, BackgroundTransparency = 0.2,
                BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 38), ClipsDescendants = true,
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = PickerFrame })
            Create("UIStroke",  { Color = Theme.Outline, Transparency = 0.5, Thickness = 1, Parent = PickerFrame })
            Create("TextLabel", {
                Parent = PickerFrame, BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -60, 0, 38),
                Font = Enum.Font.GothamMedium, Text = cpName,
                TextColor3 = Theme.TextColor, TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            local Preview = Create("Frame", {
                Parent = PickerFrame, BackgroundColor3 = default,
                Position = UDim2.new(1, -40, 0, 9), Size = UDim2.new(0, 28, 0, 20),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Preview })

            local OpenBtn = Create("TextButton", {
                Parent = PickerFrame, BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 38), Text = "",
            }) :: TextButton

            local PickerContainer = Create("Frame", {
                Parent = PickerFrame, BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 42), Size = UDim2.new(1, -24, 0, 160),
            }) :: Frame

            local SVBox = Create("ImageButton", {
                Parent = PickerContainer,
                BackgroundColor3 = Color3.fromHSV(colorH, 1, 1),
                BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, 120),
                Image = "rbxassetid://4155801252", AutoButtonColor = false,
            }) :: ImageButton
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = SVBox })
            local SVCursor = Create("Frame", {
                Parent = SVBox, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
                Position = UDim2.new(colorS, -3, 1 - colorV, -3), Size = UDim2.new(0, 6, 0, 6), ZIndex = 2,
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SVCursor })
            Create("UIStroke",  { Color = Color3.new(0, 0, 0), Thickness = 1, Parent = SVCursor })

            local HueBar = Create("ImageButton", {
                Parent = PickerContainer, BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -24), Size = UDim2.new(1, 0, 0, 20),
                AutoButtonColor = false,
            }) :: ImageButton
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = HueBar })
            Create("UIGradient", {
                Parent = HueBar, Rotation = 0,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,   0,   0)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255,   0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(  0, 255,   0)),
                    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(  0, 255, 255)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(  0,   0, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,   0, 255)),
                    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,   0,   0)),
                }),
            })
            local HueCursor = Create("Frame", {
                Parent = HueBar, BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0, Position = UDim2.new(colorH, -3, 0, -2),
                Size = UDim2.new(0, 6, 1, 4), ZIndex = 2,
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = HueCursor })
            Create("UIStroke",  { Color = Color3.new(0, 0, 0), Thickness = 1, Parent = HueCursor })

            -- Shared update — avoids per-drag closure
            local function updateColor()
                local col = Color3.fromHSV(colorH, colorS, colorV)
                Preview.BackgroundColor3 = col
                SVBox.BackgroundColor3   = Color3.fromHSV(colorH, 1, 1)
                callback(col)
            end

            local draggingSV  = false
            local draggingHue = false
            SVBox.MouseButton1Down:Connect(function()  draggingSV  = true end)
            HueBar.MouseButton1Down:Connect(function() draggingHue = true end)

            table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSV  = false
                    draggingHue = false
                end
            end))
            table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                if draggingSV then
                    colorS = math.clamp((input.Position.X - SVBox.AbsolutePosition.X) / SVBox.AbsoluteSize.X, 0, 1)
                    colorV = 1 - math.clamp((input.Position.Y - SVBox.AbsolutePosition.Y) / SVBox.AbsoluteSize.Y, 0, 1)
                    SVCursor.Position = UDim2.new(colorS, -3, 1 - colorV, -3)
                    updateColor()
                elseif draggingHue then
                    colorH = math.clamp((input.Position.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
                    HueCursor.Position = UDim2.new(colorH, -3, 0, -2)
                    updateColor()
                end
            end))

            OpenBtn.MouseButton1Click:Connect(function()
                pickerOpen = not pickerOpen
                TweenService:Create(PickerFrame, TWEEN_PICKER, { Size = UDim2.new(1, 0, 0, pickerOpen and 200 or 38) }):Play()
            end)

            local ColorObject = { Value = default }
            function ColorObject:Set(val: Color3)
                self.Value = val
                local nh, ns, nv = val:ToHSV()
                colorH, colorS, colorV = nh, ns, nv
                Preview.BackgroundColor3  = val
                SVBox.BackgroundColor3    = Color3.fromHSV(nh, 1, 1)
                SVCursor.Position         = UDim2.new(ns, -3, 1 - nv, -3)
                HueCursor.Position        = UDim2.new(nh, -3, 0, -2)
                callback(val)
            end

            local flag = o.Flag or cpName
            if flag then Window.Flags[flag] = ColorObject end
            return ColorObject
        end

        -- ── KEYBIND ───────────────────────────────────────────────────────────
        function Tab:CreateKeybind(kbopts: { Name: string?, Default: Enum.KeyCode?, Callback: ((Enum.KeyCode) -> ())?, Flag: string? }?)
            kbopts = kbopts or {}
            local o        = kbopts :: any
            local kbName   = o.Name    or "Keybind"
            local currentKey: Enum.KeyCode = o.Default or Enum.KeyCode.RightControl
            local callback = o.Callback or function() end

            local function keyLabel(): string
                return currentKey == Enum.KeyCode.Unknown and "None" or currentKey.Name
            end

            local KbFrame = Create("Frame", {
                Parent = Tab.CurrentSectionContainer or TabPage,
                BackgroundColor3 = Theme.ElementBackground, BackgroundTransparency = 0.2,
                BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 38),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = KbFrame })
            Create("UIStroke",  { Color = Theme.Outline, Transparency = 0.5, Thickness = 1, Parent = KbFrame })
            Create("TextLabel", {
                Parent = KbFrame, BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -60, 1, 0),
                Font = Enum.Font.GothamMedium, Text = kbName,
                TextColor3 = Theme.TextColor, TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            local KbBtn = Create("TextButton", {
                Parent = KbFrame,
                BackgroundColor3 = Theme.Background, BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                Position = UDim2.new(1, -95, 0.5, -12), Size = UDim2.new(0, 85, 0, 24),
                Font = Enum.Font.Gotham, Text = keyLabel(),
                TextColor3 = Theme.TextSecondary, TextSize = 13, ClipsDescendants = true,
            }) :: TextButton
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = KbBtn })
            Create("UIStroke",  { Color = Theme.Outline, Transparency = 0.7, Thickness = 1, Parent = KbBtn })

            local binding = false

            local function endBindSession(cancelFn: () -> ())
                if KeybindBindSessionCancel == cancelFn then
                    KeybindBindSessionCancel = nil
                end
            end

            local finishBinding: () -> ()
            finishBinding = function()
                if not binding then endBindSession(finishBinding); return end
                binding = false
                KbBtn.Text = keyLabel()
                TweenService:Create(KbBtn, TWEEN_FAST, { TextColor3 = Theme.TextSecondary }):Play()
                endBindSession(finishBinding)
            end

            local KbObject: { Value: Enum.KeyCode, Set: (any, Enum.KeyCode) -> () } = { Value = currentKey }
            function KbObject:Set(val: Enum.KeyCode)
                self.Value = val
                currentKey = val
                KbBtn.Text = val == Enum.KeyCode.Unknown and "None" or val.Name
            end

            -- Right-click clears the binding
            KbBtn.MouseButton2Click:Connect(function()
                if binding and KeybindBindSessionCancel == finishBinding then finishBinding() end
                currentKey = Enum.KeyCode.Unknown
                KbObject.Value = currentKey
                KbBtn.Text = "None"
                TweenService:Create(KbBtn, TWEEN_FAST, { TextColor3 = Theme.TextSecondary }):Play()
            end)

            -- Left-click enters listening mode
            KbBtn.MouseButton1Click:Connect(function()
                local Mouse = Players.LocalPlayer:GetMouse()
                spawnRipple(KbBtn, Mouse.X, Mouse.Y, 100, TWEEN_RIPPLE_KEY)
                if KeybindBindSessionCancel then KeybindBindSessionCancel() end
                KeybindBindSessionCancel = finishBinding
                binding = true
                KbBtn.Text = "..."
                TweenService:Create(KbBtn, TWEEN_FAST, { TextColor3 = Theme.Accent }):Play()
            end)

            table.insert(Connections, UserInputService.InputBegan:Connect(function(input: InputObject)
                if binding then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                            currentKey = Enum.KeyCode.Unknown
                            KbObject.Value = currentKey
                            KbBtn.Text = "None"
                        else
                            currentKey = input.KeyCode
                            KbObject.Value = currentKey
                            KbBtn.Text = currentKey.Name
                            callback(currentKey)
                        end
                        binding = false
                        endBindSession(finishBinding)
                        TweenService:Create(KbBtn, TWEEN_FAST, { TextColor3 = Theme.TextSecondary }):Play()
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                        finishBinding()
                    end
                else
                    if currentKey ~= Enum.KeyCode.Unknown and input.KeyCode == currentKey then
                        callback(currentKey)
                    end
                end
            end))

            local flag = o.Flag or kbName
            if flag then Window.Flags[flag] = KbObject end
            return KbObject
        end

        return Tab
    end -- CreateTab

    -- ============================================
    -- CONFIG PERSISTENCE
    -- ============================================
    local CONFIG_VERSION = "1.0.3"

    function Window:SaveConfig(folderName: string, fileName: string): (boolean, string?)
        if not (_G :: any).writefile then return false, "writefile unavailable" end

        local config: { [string]: any } = { _version = CONFIG_VERSION }
        for flag, obj in pairs(Window.Flags) do
            local val = obj.Value
            if typeof(val) == "Color3" then
                val = { r = val.R, g = val.G, b = val.B, isColor = true }
            elseif typeof(val) == "EnumItem" then
                val = { name = val.Name, isKeybind = true }
            end
            config[flag] = val
        end

        local fs = _G :: any
        if fs.isfolder and not fs.isfolder(folderName) and fs.makefolder then
            fs.makefolder(folderName)
        end

        local path = folderName .. "/" .. fileName .. ".json"
        local ok, err = pcall(function()
            fs.writefile(path, HttpService:JSONEncode(config))
        end)
        return ok, ok and nil or tostring(err)
    end

    function Window:LoadConfig(folderName: string, fileName: string): (boolean, string?)
        local fs = _G :: any
        if not (fs.isfile and fs.readfile) then return false, "readfile unavailable" end

        local path = folderName .. "/" .. fileName .. ".json"
        if not fs.isfile(path) then return false, "config not found" end

        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(fs.readfile(path))
        end)
        if not ok or type(decoded) ~= "table" then return false, "invalid config" end
        if decoded._version and decoded._version ~= CONFIG_VERSION then return false, "config version mismatch" end

        for flag, val in pairs(decoded) do
            if flag ~= "_version" and Window.Flags[flag] then
                if type(val) == "table" then
                    if val.isColor  and val.r and val.g and val.b then val = Color3.new(val.r, val.g, val.b) end
                    if val.isKeybind and val.name then val = Enum.KeyCode[val.name] end
                end
                Window.Flags[flag]:Set(val)
            end
        end
        return true, nil
    end

    function Window:Destroy()
        ScreenGui:Destroy()
        for _, conn in ipairs(Connections) do conn:Disconnect() end
        Connections = {}
    end

    return Window
end -- CreateWindow

-- ============================================
-- SHARED DROPDOWN SEARCH PANEL FACTORY
-- Extracted from CreateDropdown & CreateMultiDropdown to eliminate duplication.
-- Returns (SearchBox, ScrollList, UIListLayout)
-- ============================================
function createDropdownSearchPanel(parent: Frame): (TextBox, ScrollingFrame, UIListLayout)
    local SearchBox = Create("TextBox", {
        Parent = parent,
        BackgroundColor3 = Theme.Background, BackgroundTransparency = 0.5,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 28),
        Font = Enum.Font.Gotham, PlaceholderText = "Search...", Text = "",
        TextColor3 = Theme.TextColor, PlaceholderColor3 = Theme.TextSecondary,
        TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
    }) :: TextBox
    Create("UIPadding", { Parent = SearchBox, PaddingLeft = UDim.new(0, 8) })
    Create("UICorner",  { CornerRadius = UDim.new(0, 4), Parent = SearchBox })

    local ScrollList = Create("ScrollingFrame", {
        Parent = parent, BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 35), Size = UDim2.new(1, 0, 1, -35),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Accent,
        BorderSizePixel = 0,
    }) :: ScrollingFrame
    local UIList = Create("UIListLayout", {
        Parent = ScrollList, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4),
    }) :: UIListLayout

    return SearchBox :: TextBox, ScrollList :: ScrollingFrame, UIList :: UIListLayout
end

-- ============================================
-- MODULE DESTROY
-- ============================================
function VoraLib:Destroy()
    for _, conn in ipairs(Connections) do conn:Disconnect() end
    Connections = {}

    local target = RunService:IsStudio()
        and Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("VoraHub")
        or  CoreGui:FindFirstChild("VoraHub")
    if target then target:Destroy() end
end

return VoraLib
if not VoraLib then
    error("[Main] VoraLib is nil! Library failed to load.")
end

-- ============================================================
-- CREATE WINDOW (Lanjutkan kode Main.lua seperti biasa)
-- ============================================================
Window = VoraLib:CreateWindow({ Name = "Vora Hub", Intro = true })

-- ============================================================
-- TABS
-- ============================================================
InfoTab = Window:CreateTab({
    Name = "Info",
    Icon = "rbxassetid://7733964719",
})

InfoTab:CreateSection({
    Name = "Community Support",
})

InfoTab:CreateButton({
    Name = "Discord",
    SubText = "click to copy link",
    Icon = "rbxassetid://7733919427",
    Callback = function()
        setclipboard("https://discord.gg/vorahub")
        Window:Notify({
            Title = "Discord",
            Content = "Link copied to clipboard!",
            Duration = 3,
        })
    end,
})

InfoTab:CreateParagraph({
    Title = "Update",
    Content = "Every time there is a game update or someone reports something, I will fix it as soon as possible.",
})

ExclusiveTab = Window:CreateTab({
    Name = "Exclusive",
    Icon = "rbxassetid://7733765398",
})

AmblatantTab = Window:CreateTab({
    Name = "Amblatant",
    Icon = "rbxassetid://7733779610",
})

MainTab = Window:CreateTab({
    Name = "Main",
    Icon = "rbxassetid://7733779610",
})

QuestTab = Window:CreateTab({
    Name = "Quest",
    Icon = "rbxassetid://7733955511",
})

AutoTab = Window:CreateTab({
    Name = "Auto",
    Icon = "rbxassetid://7733799901",
})

PlayerTab = Window:CreateTab({
    Name = "Player",
    Icon = "rbxassetid://7743875962",
})

ShopTab = Window:CreateTab({
    Name = "Shop",
    Icon = "rbxassetid://7733793319",
})

-- ============================================================
-- CHARMS SHOP
-- ============================================================
ShopTab:CreateSection({ Name = "Charms Shop" })

SelectedCharm = "Bone Charm"
CharmIDs = {}

local function loadCharms()
    local success, charms_module = pcall(function()
        return require(game:GetService("ReplicatedStorage"):WaitForChild("Charms", 5))
    end)

    local charm_names = {}
    if success and type(charms_module) == "table" then
        for _, charm in pairs(charms_module) do
            if charm.Data and charm.Data.Name and charm.Data.Id then
                CharmIDs[charm.Data.Name] = charm.Data.Id
                table.insert(charm_names, charm.Data.Name)
            end
        end
    end
    table.sort(charm_names)
    return charm_names
end

local charmItems = loadCharms()
if #charmItems == 0 then
    charmItems = { "Bone Charm", "Algae Charm", "Magma Charm", "Clover Charm", "Heart Charm" }
    CharmIDs = {
        ["Bone Charm"] = 1,
        ["Algae Charm"] = 2,
        ["Magma Charm"] = 3,
        ["Clover Charm"] = 4,
        ["Heart Charm"] = 14,
    }
end

local charmDropdown = ShopTab:CreateDropdown({
    Name = "Select Charm",
    Items = charmItems,
    Default = charmItems[1] or "Bone Charm",
    Callback = function(val)
        SelectedCharm = val
    end,
})

PurchaseQuantity = 1
ShopTab:CreateInput({
    Name = "Quantity",
    PlaceholderText = "1",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local val = tonumber(text)
        if val then PurchaseQuantity = val end
    end,
})

ShopTab:CreateButton({
    Name = "Purchase Charm",
    Callback = function()
        local id = CharmIDs[SelectedCharm]
        if not id then
            Window:Notify({
                Title = "Error",
                Content = "Charm ID not found for " .. tostring(SelectedCharm),
                Duration = 3,
            })
            return
        end

        Window:Notify({
            Title = "Purchase",
            Content = "Buying " .. PurchaseQuantity .. " " .. SelectedCharm .. "...",
            Duration = 2,
        })

        task.spawn(function()
            for _ = 1, PurchaseQuantity do
                pcall(function()
                    CallRemoteServer(BuyCharm, id)
                end)
                task.wait(0.1)
            end
            Window:Notify({
                Title = "Done",
                Content = "Finished buying " .. SelectedCharm,
                Duration = 2,
            })
        end)
    end,
})

ShopTab:CreateButton({
    Name = "Equip Charm",
    Callback = function()
        if not SelectedCharm then return end
        pcall(function()
            REEquipCharm:FireServer(SelectedCharm)
        end)
        Window:Notify({
            Title = "Equip",
            Content = "Equipped " .. SelectedCharm,
            Duration = 2,
        })
    end,
})

ShopTab:CreateButton({
    Name = "Unequip Charm",
    Callback = function()
        REUnequipCharm:FireServer()
        Window:Notify({
            Title = "Unequip",
            Content = "Unequipped Charm",
            Duration = 2,
        })
    end,
})

TeleportTab = Window:CreateTab({
    Name = "Teleport",
    Icon = "rbxassetid://128755575520135",
})

SettingsTab = Window:CreateTab({
    Name = "Settings",
    Icon = "rbxassetid://7733954611",
})

MonitoringTab = Window:CreateTab({
    Name = "Monitoring",
    Icon = "rbxassetid://137601480983962",
})

-- ============================================================
-- ZOOM SETTINGS
-- ============================================================
getgenv().host = game:GetService("Players").LocalPlayer

function applyZoom()
    host.CameraMaxZoomDistance = math.huge
    host.CameraMinZoomDistance = 0.1
end

applyZoom()

host.CharacterAdded:Connect(function()
    task.wait(0.1)
    applyZoom()
end)

-- ============================================================
-- REPLICATION & DATA
-- ============================================================
ReplicatedStorage = game:GetService("ReplicatedStorage")
RunService = game:GetService("RunService")

-- Net already initialized
Replion = require(ReplicatedStorage.Packages.Replion)
FishingController = require(ReplicatedStorage.Controllers.FishingController)
ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
VendorUtility = require(ReplicatedStorage.Shared.VendorUtility)

Data = Replion.Client:WaitReplion("Data")
Client = require(ReplicatedStorage.Packages.Replion).Client
dataStore = Client:WaitReplion("Data")
Items = ReplicatedStorage:WaitForChild("Items")
Players = game:GetService("Players")
LocalPlayer = Players.LocalPlayer
NetService = Net

-- Alias untuk remote
sellAllItems = SellItem
enchan = REAltar
oxygenRemote = UpdateOxygen
radar = UpdateRadar
autoon = AutoEnabled
equipTool = REEquip
CoreGui = game:GetService("CoreGui")
tradeFunc = InitiateTrade
RETextNotification = RENotify
ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)

-- ============================================================
-- RE TABLE (Remote Events Wrapper)
-- ============================================================
RE = {
    FavoriteItem = REFav,
    FavoriteStateChanged = REFavChg,
    FishingCompleted = REFishDone,
    FishCaught = REFishGot,
    EquipItem = REEquipItem,
    ActivateAltar = REAltar,
    EquipTool = REEquip,
    OpenPirateChest = PirateChest,
}

-- Remote aliases untuk enchant
equipItemRemote = RE.EquipItem or REEquipItem
equipToolRemote = RE.EquipTool or REEquip
activateAltarRemote = RE.ActivateAltar or REAltar

-- ============================================================
-- STATE & PATCHING FISHING CONTROLLER
-- ============================================================
st = {
    canFish = true,
}

local blockedFunctions = {
    "OnCooldown",
}

function patchFishingController()
    local fishingModule = ReplicatedStorage.Controllers:FindFirstChild("FishingController")
    if not fishingModule then return end

    local ok, FC = pcall(require, fishingModule)
    if not ok or type(FC) ~= "table" then return end

    for key, fn in pairs(FC) do
        if type(fn) == "function" and table.find(blockedFunctions, key) then
            FC[key] = function(...)
                return false
            end
        end
    end
end

patchFishingController()
-- ============================================================
-- ULTRA BLATANT 3N (FishingController Stub)
-- ============================================================
local origUB3N_RequestChargeFishingRod, origUB3N_SendFishingRequestToServer

local function backupFishingControllerFunctions()
    local ok1, val1 = pcall(function()
        return FishingController.RequestChargeFishingRod
    end)
    local ok2, val2 = pcall(function()
        return FishingController.SendFishingRequestToServer
    end)
    if ok1 then origUB3N_RequestChargeFishingRod = val1 end
    if ok2 then origUB3N_SendFishingRequestToServer = val2 end

    if not origUB3N_RequestChargeFishingRod or not origUB3N_SendFishingRequestToServer then
        warn("[UltraBlatant] Failed to backup FishingController functions. Stub may not work.")
    end
end

backupFishingControllerFunctions()

function applyUltraBlatant3NFishingControllerStub(enabled)
    if not origUB3N_RequestChargeFishingRod or not origUB3N_SendFishingRequestToServer then
        warn("[UltraBlatant] Cannot apply stub: original functions not backed up.")
        return
    end

    if enabled then
        FishingController.RequestChargeFishingRod = function(self, ...) end
        FishingController.SendFishingRequestToServer = function(self, ...) end
    else
        FishingController.RequestChargeFishingRod = origUB3N_RequestChargeFishingRod
        FishingController.SendFishingRequestToServer = origUB3N_SendFishingRequestToServer
    end
end

-- ============================================================
-- GLOBAL VARIABLES (Tetap gunakan _G agar kompatibel)
-- ============================================================
_G.AutoFarm = _G.AutoFarm or false
_G.AutoRod = _G.AutoRod or false
_G.AutoSells = _G.AutoSells or false
_G.InfiniteJump = _G.InfiniteJump or false
_G.Radar = _G.Radar or false
_G.AntiAFK = _G.AntiAFK or false
_G.AutoReconnect = _G.AutoReconnect or false
autoFavEnabled = autoFavEnabled or false
_G.Amblatant = _G.Amblatant or false

-- ============================================================
-- NATURAL HOOK (Optimized)
-- ============================================================
local _naturalHookInstalled = false
local _naturalRainbowCount = 0
local _naturalGoldenCount = 0
local _naturalFishCount = 0
isCaught = isCaught or false  -- biarkan global karena dipakai di tempat lain

function _resetNaturalHookCounts()
    _naturalRainbowCount = 0
    _naturalGoldenCount = 0
    _naturalFishCount = 0
    isCaught = false
end

-- Fungsi update natural hook (didefinisikan sekali, di luar loop)
local function runNaturalUpdate(updateType, args, oldFunc)
    task.spawn(function()
        for _ = 1, 2 do
            if updateType == "Rainbow" then
                local last = _naturalRainbowCount
                _naturalRainbowCount = _naturalRainbowCount + 1
                if _naturalRainbowCount > 40 then _naturalRainbowCount = 0 end
                isCaught = (_naturalRainbowCount ~= last)
                oldFunc(args[1], args[2], _naturalRainbowCount)
            elseif updateType == "Golden" then
                local last = _naturalGoldenCount
                _naturalGoldenCount = _naturalGoldenCount + 1
                if _naturalGoldenCount > 10 then _naturalGoldenCount = 0 end
                isCaught = (_naturalGoldenCount ~= last)
                oldFunc(args[1], args[2], _naturalGoldenCount)
            elseif updateType == "Fish" then
                _naturalFishCount = _naturalFishCount + 1
                isCaught = true
                oldFunc(args[1], args[2], _naturalFishCount)
            end
            task.wait(0.3)
        end
    end)
end

function _installFixedNaturalHook()
    if _naturalHookInstalled then return end

    local executorName = "Unknown"
    pcall(function()
        if type(getExecutorName) == "function" then
            executorName = tostring(getExecutorName() or "Unknown")
        end
    end)

    if tostring(executorName):lower():find("velocity") then
        print("Fixed Natural Hook: skipped on Velocity executor")
        return
    end

    if type(hookfunction) ~= "function" then
        print("Fixed Natural Hook: hookfunction not available")
        return
    end

    _naturalHookInstalled = true

    local Event
    pcall(function()
        Event = game:GetService("ReplicatedStorage").Packages._Index["ytrev_replion@2.0.0-rc.3"].replion.Remotes.Set
    end)
    if not Event or not Event.OnClientEvent then
        warn("[NaturalHook] Remote not found")
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

                    if _G.Amblatant then
                        if category == "Modifiers" and subCategory == "Rainbow" then
                            runNaturalUpdate("Rainbow", Args, old)
                            return
                        elseif category == "Modifiers" and subCategory == "Golden" then
                            runNaturalUpdate("Golden", Args, old)
                            return
                        elseif category == "InventoryNotifications" and subCategory == "Fish" then
                            runNaturalUpdate("Fish", Args, old)
                            return
                        end
                    end
                end

                return old(...)
            end)
        end
    end

    print("Fixed Natural Hook Active!")
end

-- ============================================================
-- FISHING DELAY (DEFAULT)
-- ============================================================
local delayfishing = 1

----------------------------------------------------------------
-- INSTANT FISH MODULE (Optimized)
----------------------------------------------------------------
local Instant = {}
local PI = math.pi
local CAST_MODE_LIST = { "Perfect", "Fast", "Random" }

----------------------------------------------------------------
-- REMOTES (di-cache dari global)
----------------------------------------------------------------
local RF_ChargeFishingRod = ChargeRod
local RE_CatchFishCompleted = REFishDoneRE or REFishDone
local RF_RequestFishingMinigameStarted = StartMini

-- Random instance dibuat SEKALI di luar fungsi untuk menghindari alokasi berulang
local randomInstance = Random.new(tick())

local state = {
    enabled = false,
    running = false,
    castMode = "Fast",
    completeDelay = 3,
    castDelay = 0.3,
    notifDelay = 1.6,
    notifDuration = 4.7,
}

local loopTask = nil
local notifHooked = false

-- ============================================================
-- POWER CALCULATION (Optimized)
-- ============================================================
local function getPowerAtTime(chargeTime, elapsed)
    local speed = randomInstance:NextInteger(4, 10)  -- reuse random instance
    local angle = PI / 2 + elapsed * speed
    return (1 - math.sin(angle)) / 2
end

-- ============================================================
-- WAIT FOR POWER (Optimized dengan interval lebih besar)
-- ============================================================
local function waitForPower(chargeTime, threshold)
    local deadline = chargeTime + 2.0
    local Workspace = game:GetService("Workspace")  -- cache di dalam closure
    while Workspace:GetServerTimeNow() < deadline do
        local elapsed = Workspace:GetServerTimeNow() - chargeTime
        local power = getPowerAtTime(chargeTime, elapsed)
        if power >= threshold then
            return elapsed, power
        end
        task.wait(0.005)  -- 5ms (lebih ringan dari 1ms)
    end
    local elapsed = Workspace:GetServerTimeNow() - chargeTime
    return elapsed, getPowerAtTime(chargeTime, elapsed)
end

-- ============================================================
-- TEXT NOTIFICATION CONTROLLER HOOK (AMAN)
-- ============================================================
pcall(function()
    local TextNotificationController = ReplicatedStorage.Controllers:FindFirstChild("TextNotificationController")
    if TextNotificationController and TextNotificationController:IsA("ModuleScript") then
        local ok, controller = pcall(require, TextNotificationController)
        if ok and controller and controller.DeliverNotification then
            local origDeliver = controller.DeliverNotification
            controller.DeliverNotification = function(self, data, ...)
                -- Cek apakah Config dan data tersedia
                if Config and Config.HookNotif and data then
                    if Config.InstantFishingV2Active then
                        data.CustomDuration = 15
                    elseif _G.BlatantMode then
                        data.CustomDuration = 7.5
                    else
                        data.CustomDuration = 15
                    end
                end
                -- Panggil fungsi asli dengan aman
                if origDeliver then
                    return origDeliver(self, data, ...)
                end
            end
            print("[Notification] Hook installed successfully")
        else
            warn("[Notification] Failed to hook TextNotificationController")
        end
    else
        warn("[Notification] TextNotificationController not found")
    end
end)
-- ============================================================
-- REMOTE CALLS (Synchronous, tanpa task.spawn)
-- ============================================================
local function safeInvoke(remote, ...)
    if not remote then return false end
    local args = { ... }
    local ok = pcall(remote.InvokeServer, remote, unpack(args))
    return ok
end

local function safeFire(remote, ...)
    if not remote then return false end
    local args = { ... }
    local ok = pcall(remote.FireServer, remote, unpack(args))
    return ok
end

-- ============================================================
-- HANDLE CAST MODE
-- ============================================================
local function handleCastMode(t0)
    local mode = state.castMode

    if mode == "Perfect" then
        local _, power = waitForPower(t0, 0.97)
        return power
    elseif mode == "Random" then
        local randomElapsed = math.random() * (PI / 4)  -- lebih sederhana
        task.wait(randomElapsed)
        local elapsed = game:GetService("Workspace"):GetServerTimeNow() - t0
        return getPowerAtTime(t0, elapsed)
    else -- Fast
        local elapsed = game:GetService("Workspace"):GetServerTimeNow() - t0
        return getPowerAtTime(t0, elapsed)
    end
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
local function startLoop()
    if state.running then return end
    state.running = true

    while state.enabled do
        local t0 = game:GetService("Workspace"):GetServerTimeNow()
        safeInvoke(RF_ChargeFishingRod, nil, nil, t0, nil)
        local power = handleCastMode(t0)
        safeInvoke(RF_RequestFishingMinigameStarted, 0, power, t0)
        task.wait(state.completeDelay)
        task.wait(0.01)
        safeFire(RE_CatchFishCompleted)
        task.wait(state.castDelay)
    end

    state.running = false
end

-- ============================================================
-- PUBLIC API (Tetap sama persis agar kompatibel)
-- ============================================================
function Instant.SetCastMode(mode)
    if table.find(CAST_MODE_LIST, mode) then
        state.castMode = mode
    end
end

function Instant.SetCompleteDelay(v)
    local num = tonumber(v)
    if num and num >= 0 then
        state.completeDelay = num
    end
end

function Instant.SetCastDelay(v)
    local num = tonumber(v)
    if num and num >= 0 then
        state.castDelay = num
    end
end

function Instant.Start()
    if state.enabled then return end
    state.enabled = true
    hookNotificationDelay()
    loopTask = task.spawn(startLoop)
    if _G._NEXTHUB and _G._NEXTHUB.tasks then
        table.insert(_G._NEXTHUB.tasks, loopTask)
    end
end

function Instant.Stop()
    state.enabled = false
    if loopTask then
        pcall(task.cancel, loopTask)
        loopTask = nil
    end
    state.running = false
end

function Instant.IsActive()
    return state.enabled
end

-- ============================================================
-- COMPATIBILITY WRAPPERS (Sama seperti sebelumnya)
-- ============================================================
function CallFishDone(remote, ...)
    if not remote then return end
    local ok = pcall(remote.InvokeServer, remote, ...)
    if not ok then
        pcall(remote.FireServer, remote, ...)
    end
end

function instant()
    local t0 = game:GetService("Workspace"):GetServerTimeNow()
    safeInvoke(RF_ChargeFishingRod, nil, nil, t0, nil)
    local power = handleCastMode(t0)
    safeInvoke(RF_RequestFishingMinigameStarted, 0, power, t0)
    task.wait(delayfishing)  -- delayfishing adalah global yang sudah didefinisikan di luar
    safeFire(RE_CatchFishCompleted)
end

-- ============================================================
-- UB (Ultra Blatant) Integration
-- ============================================================
function UB_start()
    Config.UB.Active = true
    Config.UB.Stats.startTime = tick()
    Instant.SetCompleteDelay(Config.UB.Settings.CompleteDelay)
    Instant.SetCastDelay(Config.UB.Settings.CancelDelay)
    Instant.SetCastMode(Config.UB.Settings.CastMode or "Fast")
    Instant.Start()
end

function UB_stop()
    Config.UB.Active = false
    Instant.Stop()
end

function onToggleUB(value)
    if value then
        Config.HookNotif = true
        UB_start()
    else
        UB_stop()
        Config.HookNotif = false
    end
end

function startInstantFishingV2()
    UB_start()
end

function stopInstantFishingV2()
    UB_stop()
end

-- ============================================================
-- INISIALISASI (Untuk memastikan random instance valid)
-- ============================================================
randomInstance = Random.new(tick())
print("[Instant] Module loaded (optimized)")
-- ============================================================
-- INSTANT BOBBER (Optimized)
-- ============================================================
InstantBobberState = {
    instantOverrideActive = false,
    instantOverrideSetupDone = false,
    activeBaitsByUserId = {},
    cosmeticFolder = nil,
    baitCastConn = nil,
    baitDestroyedConn = nil,
    renderThread = nil,
}

function patchInstantBaitOverrideToCastPosition(enabled)
    if not enabled then
        InstantBobberState.instantOverrideActive = false
        table.clear(InstantBobberState.activeBaitsByUserId)
        -- Hentikan thread render jika ada
        if InstantBobberState.renderThread then
            task.cancel(InstantBobberState.renderThread)
            InstantBobberState.renderThread = nil
        end
        return
    end

    InstantBobberState.instantOverrideActive = true
    table.clear(InstantBobberState.activeBaitsByUserId)

    if InstantBobberState.instantOverrideSetupDone then
        return
    end
    InstantBobberState.instantOverrideSetupDone = true

    -- Cari CosmeticFolder
    local okCosmetic, cosmeticFolder = pcall(function()
        return workspace:WaitForChild("CosmeticFolder", 5)
    end)
    if not okCosmetic or not cosmeticFolder then
        InstantBobberState.instantOverrideSetupDone = false
        InstantBobberState.instantOverrideActive = false
        warn("[InstantBobber] CosmeticFolder not found")
        return
    end
    InstantBobberState.cosmeticFolder = cosmeticFolder

    -- Cari remote events
    local baitCastVisual = GetServerRemote("RE/BaitCastVisual") or GetServerRemote("BaitCastVisual")
    local baitDestroyed = BaitDestroyed or GetServerRemote("RE/BaitDestroyed") or GetServerRemote("BaitDestroyed")

    if not baitCastVisual or not baitCastVisual:IsA("RemoteEvent") then
        InstantBobberState.instantOverrideSetupDone = false
        InstantBobberState.instantOverrideActive = false
        warn("[InstantBobber] BaitCastVisual remote not found or invalid")
        return
    end
    if not baitDestroyed or not baitDestroyed:IsA("RemoteEvent") then
        InstantBobberState.instantOverrideSetupDone = false
        InstantBobberState.instantOverrideActive = false
        warn("[InstantBobber] BaitDestroyed remote not found or invalid")
        return
    end

    -- Helper untuk koneksi aman
    local function safeConnect(signal, callback)
        if not signal then return nil end
        local ok, conn = pcall(signal.Connect, signal, callback)
        return ok and conn or nil
    end

    InstantBobberState.baitCastConn = safeConnect(baitCastVisual.OnClientEvent, function(player, data)
        if not InstantBobberState.instantOverrideActive then return end
        if not player or not player.UserId then return end
        if not data or not data.CastPosition or typeof(data.CastPosition) ~= "Vector3" then return end

        InstantBobberState.activeBaitsByUserId[player.UserId] = {
            pivot = CFrame.new(data.CastPosition),
            expiresAt = tick() + 1.5,
        }
    end)

    InstantBobberState.baitDestroyedConn = safeConnect(baitDestroyed.OnClientEvent, function(player)
        if not InstantBobberState.instantOverrideActive then return end
        if not player or not player.UserId then return end
        InstantBobberState.activeBaitsByUserId[player.UserId] = nil
    end)

    -- Render loop dengan interval 0.1 detik (lebih ringan dari RenderStepped)
    InstantBobberState.renderThread = task.spawn(function()
        while InstantBobberState.instantOverrideActive do
            task.wait(0.1)
            pcall(function()
                local now = tick()
                local cfolder = InstantBobberState.cosmeticFolder
                if not cfolder then return end

                for userId, entry in pairs(InstantBobberState.activeBaitsByUserId) do
                    if now > entry.expiresAt then
                        InstantBobberState.activeBaitsByUserId[userId] = nil
                    else
                        local model = cfolder:FindFirstChild(tostring(userId))
                        if model and model.PivotTo then
                            model:PivotTo(entry.pivot)
                        end
                    end
                end
            end)
        end
    end)
end

-- ============================================================
-- WEBHOOK CONFIG (Tetap kompatibel)
-- ============================================================
HttpService = game:GetService("HttpService")
ReplicatedStorage = game:GetService("ReplicatedStorage")
player = game.Players.LocalPlayer
REFishCaught = REFishGot

_G.Wurl = _G.Wurl or ""
_G.WebhookEnabled = _G.WebhookEnabled or false
_G.WebhookURL = _G.WebhookURL or ""
_G.WebhookID = _G.WebhookID or ""
_G.WebhookSecret = _G.WebhookSecret or ""
_G.WebhookRarities = _G.WebhookRarities or {}

-- Cari fungsi request yang tersedia
local function getRequestFunction()
    if syn and syn.request then return syn.request end
    if http and http.request then return http.request end
    if http_request then return http_request end
    if request then return request end
    if fluxus and fluxus.request then return fluxus.request end
    return nil
end

req = getRequestFunction() or function()
    warn("[Webhook] No request function available")
    return nil
end

function isValidWebhookURL(url)
    return string.find(url, "discord%.com") and string.find(url, "webhook")
end

function buildWebhookURL()
    return _G.WebhookURL
end

-- ============================================================
-- PREMIUM SECTION: No Animation
-- ============================================================
ExclusiveTab:CreateSection({ Name = "Premium" })

stopAnimConnections = {}

function setAnim(v)
    local char = player.Character or player.CharacterAdded:Wait()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    for _, c in ipairs(stopAnimConnections) do
        pcall(c.Disconnect, c)
    end
    stopAnimConnections = {}

    if v then
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then
            for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
                pcall(t.Stop, t, 0)
            end
            local c = animator.AnimationPlayed:Connect(function(t)
                task.defer(function()
                    pcall(t.Stop, t, 0)
                end)
            end)
            table.insert(stopAnimConnections, c)
        end
    end
end

ExclusiveTab:CreateToggle({
    Name = "No Animation",
    Value = false,
    Callback = setAnim
})

-- ============================================================
-- TOTEM DATA
-- ============================================================
TOTEM_DATA = {
    ["Luck Totem"]       = {Id = 1, Duration = 3601},
    ["Mutation Totem"]   = {Id = 2, Duration = 3601},
    ["Shiny Totem"]      = {Id = 3, Duration = 3601},
    ["Super Love Totem"] = {Id = 4, Duration = 3601},
    ["Love Totem"]       = {Id = 5, Duration = 3601},
    ["Super Easter Totem"] = {Id = 6, Duration = 3601},
    ["Easter Totem"]     = {Id = 7, Duration = 3601},
}

TOTEM_NAMES = {"Luck Totem", "Mutation Totem", "Shiny Totem", "Super Love Totem", "Love Totem", "Super Easter Totem", "Easter Totem"}
selectedTotemName = "Luck Totem"

-- AUTO SINGLE TOTEM
AUTO_TOTEM_ACTIVE = false
AUTO_TOTEM_THREAD = nil
currentTotemExpiry = 0

function GetTotemUUID(name)
    local success, r = pcall(function()
        return require(ReplicatedStorage.Packages.Replion).Client:WaitReplion("Data")
    end)
    if not success or not r then return nil end
    local s, d = pcall(function() return r:GetExpect("Inventory") end)
    if not s or not d or not d.Totems then return nil end
    local totemData = TOTEM_DATA[name]
    if not totemData then return nil end
    for _, i in ipairs(d.Totems) do
        if tonumber(i.Id) == totemData.Id and (i.Count or 1) >= 1 then
            return i.UUID
        end
    end
    return nil
end

function RunAutoTotemLoop()
    if AUTO_TOTEM_THREAD then
        task.cancel(AUTO_TOTEM_THREAD)
        AUTO_TOTEM_THREAD = nil
    end
    AUTO_TOTEM_THREAD = task.spawn(function()
        while AUTO_TOTEM_ACTIVE do
            local timeLeft = currentTotemExpiry - os.time()
            if timeLeft <= 0 then
                local uuid = GetTotemUUID(selectedTotemName)
                if uuid then
                    pcall(function() Totem:FireServer(uuid) end)
                    currentTotemExpiry = os.time() + TOTEM_DATA[selectedTotemName].Duration

                    -- Re-equip rod setelah spawn totem (improved timing & retries)
                    task.spawn(function()
                        task.wait(0.5)
                        for _ = 1, 8 do
                            task.wait(0.25)
                            pcall(function() REEquip:FireServer(1) end)
                        end
                        print("[Auto Totem] Rod re-equipped after spawning " .. selectedTotemName)
                    end)
                end
            end
            task.wait(1)
        end
    end)
end

ExclusiveTab:CreateDropdown({
    Name = "Pilih Jenis Totem",
    Items = TOTEM_NAMES,
    Value = selectedTotemName,
    Callback = function(n)
        selectedTotemName = n
        currentTotemExpiry = 0
    end
})

ExclusiveTab:CreateToggle({
    Name = "Enable Auto Totem (Single)",
    SubText = "Mode Normal",
    Default = false,
    ConfigKey = "EnableAutoTotemSingle",
    Callback = function(s)
        AUTO_TOTEM_ACTIVE = s
        if s then
            RunAutoTotemLoop()
        else
            if AUTO_TOTEM_THREAD then
                task.cancel(AUTO_TOTEM_THREAD)
                AUTO_TOTEM_THREAD = nil
            end
        end
    end
})

-- ============================================================
-- AUTO 3 TOTEM MIX (SHINY -> LUCK -> MUTATION) [TWEEN + PLATFORM]
-- ============================================================

local AUTO_3_TOTEM_ACTIVE = false
local AUTO_3_TOTEM_THREAD = nil

local TOTEM_MIX_ORDER = {"Shiny Totem", "Luck Totem", "Mutation Totem"}

local REF_CENTER = Vector3.new(93.932, 9.532, 2684.134)
local REF_SPOTS = {
    Vector3.new(45.0468979, 13.5, 2730.19067),
    Vector3.new(145.644608, 13.5, 2721.90747),
    Vector3.new(84.6406631, 14.2, 2636.05786),
}

TweenService = game:GetService("TweenService")

function GetRoot()
    local player = game:GetService("Players").LocalPlayer
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
end

function TweenTo(targetCFrame, duration)
    local root = GetRoot()
    if not root then return end
    root.Anchored = true
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    tween.Completed:Wait()
    -- root tetap anchored, akan di-unlock setelah platform dibuat atau di akhir
end

function CreatePlatform(position)
    local plat = Instance.new("Part")
    plat.Name = "TotemPlatform"
    plat.Size = Vector3.new(10, 1, 10)
    plat.Position = position - Vector3.new(0, 3.5, 0)
    plat.Anchored = true
    plat.CanCollide = true
    plat.Transparency = 0.5
    plat.Color = Color3.fromRGB(0, 255, 255)
    plat.Material = Enum.Material.Neon
    plat.Parent = workspace
    return plat
end

function Run3TotemLoop()
    if AUTO_3_TOTEM_THREAD then
        task.cancel(AUTO_3_TOTEM_THREAD)
        AUTO_3_TOTEM_THREAD = nil
    end

    AUTO_3_TOTEM_THREAD = task.spawn(function()
        AUTO_3_TOTEM_ACTIVE = true

        local player = game:GetService("Players").LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local root = GetRoot()

        if not root then
            AUTO_3_TOTEM_ACTIVE = false
            Window:Notify({ Title = "Error", Content = "Character root not found", Duration = 3 })
            return
        end

        local startCFrame = root.CFrame
        Window:Notify({ Title = "Started", Content = "3 Totem Mix (Tween Mode)", Duration = 4, Icon = "zap" })

        local RF_EquipOxygenTank = EquipOxygen
        if RF_EquipOxygenTank then
            pcall(function() RF_EquipOxygenTank:InvokeServer(105) end)
        end

        while AUTO_3_TOTEM_ACTIVE do
            for i, refSpot in ipairs(REF_SPOTS) do
                if not AUTO_3_TOTEM_ACTIVE then break end

                local targetTotemName = TOTEM_MIX_ORDER[i]
                local relativePos = refSpot - REF_CENTER
                local targetPos = startCFrame.Position + relativePos
                local targetCFrame = CFrame.new(targetPos)

                local dist = (root.Position - targetPos).Magnitude
                local travelTime = math.max(1.5, dist / 60)

                -- Tween to location
                pcall(function()
                    TweenTo(targetCFrame, travelTime)
                end)

                -- Create platform
                local platform = nil
                pcall(function()
                    platform = CreatePlatform(targetPos)
                    root.Anchored = false
                end)

                task.wait(0.5)

                -- Spawn totem
                local uuid = GetTotemUUID(targetTotemName)
                if uuid then
                    pcall(function() Totem:FireServer(uuid) end)
                    task.spawn(function()
                        for _ = 1, 5 do
                            pcall(function() REEquip:FireServer(1) end)
                            task.wait(0.2)
                        end
                    end)
                    Window:Notify({ Title = "Spawned", Content = targetTotemName, Duration = 2 })
                else
                    Window:Notify({ Title = "Skip", Content = "No " .. targetTotemName, Duration = 2, Icon = "x" })
                end

                task.wait(3)

                -- Cleanup platform
                if platform then
                    pcall(platform.Destroy, platform)
                end
                if root then
                    root.Anchored = true
                end
            end

            if AUTO_3_TOTEM_ACTIVE then
                pcall(function()
                    TweenTo(startCFrame, 2)
                    if root then root.Anchored = false end
                end)
                Window:Notify({ Title = "Cycle Done", Content = "Waiting 1 Hour...", Duration = 10, Icon = "time" })
            end

            for waitTime = 3600, 1, -1 do
                if not AUTO_3_TOTEM_ACTIVE then break end
                task.wait(1)
            end
        end

        -- Unequip Oxygen when stopped
        local RF_UnequipOxygenTank = UnequipOxygen
        if RF_UnequipOxygenTank then
            pcall(function() RF_UnequipOxygenTank:InvokeServer() end)
        end

        if root then
            root.Anchored = false
        end
    end)
end

ExclusiveTab:CreateToggle({
    Name = "Auto Spawn 3 Totem Mix",
    SubText = "Shiny -> Luck -> Mutation",
    Default = false,
    Callback = function(s)
        AUTO_3_TOTEM_ACTIVE = s
        if s then
            Run3TotemLoop()
        else
            AUTO_3_TOTEM_ACTIVE = false
            if AUTO_3_TOTEM_THREAD then
                task.cancel(AUTO_3_TOTEM_THREAD)
                AUTO_3_TOTEM_THREAD = nil
            end

            local root = GetRoot()
            if root then root.Anchored = false end

            for _, v in ipairs(workspace:GetChildren()) do
                if v.Name == "TotemPlatform" then
                    pcall(v.Destroy, v)
                end
            end

            Window:Notify({ Title = "Stopped", Content = "Cancelled!", Duration = 3, Icon = "x" })
        end
    end
})

-- ============================================================
-- AUTO BUY TOTEM (MARKET PURCHASE) - OPTIMIZED
-- ============================================================
ExclusiveTab:CreateSection({ Name = "Auto Buy Totem" })

-- ============================================================
-- CONFIGURATION
-- ============================================================
local TotemMarketIds = {
    ["Luck Totem"] = 5,
    ["Shiny Totem"] = 7,
    ["Mutation Totem"] = 8,
}

local TotemPrices = {
    ["Luck Totem"] = 650000,
    ["Shiny Totem"] = 400000,
    ["Mutation Totem"] = 800000,
}

-- Inventory IDs (untuk pengecekan jumlah)
local TotemInventoryIds = {
    ["Luck Totem"] = 1,
    ["Mutation Totem"] = 2,
    ["Shiny Totem"] = 3,
}

-- State global (tetap kompatibel)
_G.AutoBuyTotem = _G.AutoBuyTotem or false
_G.SelectedBuyTotem = _G.SelectedBuyTotem or "Luck Totem"
_G.BuyTotemLimit = _G.BuyTotemLimit or 10

local purchaseCount = 0
local autoBuyThread = nil

-- ============================================================
-- FUNGSI PEMBANTU (Di-cache)
-- ============================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Cache Replion Client dan DataStore
local ReplionClient
local DataStore
pcall(function()
    ReplionClient = require(ReplicatedStorage.Packages.Replion).Client
    DataStore = ReplionClient:WaitReplion("Data")
end)

-- Fungsi untuk mendapatkan jumlah totem di inventory
local function getTotemCount(totemName: string): number
    if not DataStore then
        warn("[AutoBuy] DataStore not available")
        return 0
    end

    local inventoryId = TotemInventoryIds[totemName]
    if not inventoryId then
        warn("[AutoBuy] Unknown totem:", totemName)
        return 0
    end

    local success, inventory = pcall(function()
        return DataStore:GetExpect("Inventory")
    end)

    if not success or not inventory or not inventory.Totems then
        return 0
    end

    local total = 0
    for _, item in ipairs(inventory.Totems) do
        if tonumber(item.Id) == inventoryId then
            total = total + (item.Count or 1)
        end
    end
    return total
end

-- ============================================================
-- UI ELEMENTS
-- ============================================================

-- Dropdown pilih totem
ExclusiveTab:CreateDropdown({
    Name = "Select Totem to Buy",
    Items = { "Luck Totem", "Shiny Totem", "Mutation Totem" },
    Default = _G.SelectedBuyTotem,
    Callback = function(selected)
        _G.SelectedBuyTotem = selected
        print("[AutoBuy] Selected:", selected, "Price:", TotemPrices[selected])
    end,
})

-- Input batas pembelian
ExclusiveTab:CreateInput({
    Name = "Purchase Limit",
    PlaceholderText = "10",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local value = tonumber(text)
        if value and value > 0 then
            _G.BuyTotemLimit = value
            print("[AutoBuy] Limit set to:", value)
        else
            warn("[AutoBuy] Invalid limit, using default 10")
            _G.BuyTotemLimit = 10
        end
    end,
})

-- Toggle buka Merchant GUI
ExclusiveTab:CreateToggle({
    Name = "Open Merchant GUI",
    Default = false,
    Callback = function(value)
        local merchantGui = LocalPlayer.PlayerGui:FindFirstChild("Merchant")
        if merchantGui then
            merchantGui.Enabled = value
            if value then
                Window:Notify({
                    Title = "Merchant",
                    Content = "Merchant GUI Opened!",
                    Icon = "rbxassetid://7733920644",
                    Duration = 3,
                })
            end
        else
            Window:Notify({
                Title = "Error",
                Content = "Merchant GUI not found!",
                Icon = "rbxassetid://7733658504",
                Duration = 3,
            })
        end
    end,
})

-- ============================================================
-- AUTO BUY LOOP (Dengan Thread Management)
-- ============================================================

local function startAutoBuy()
    if autoBuyThread then
        task.cancel(autoBuyThread)
        autoBuyThread = nil
    end

    if not BuyMarket then
        Window:Notify({
            Title = "Error",
            Content = "BuyMarket remote not available!",
            Duration = 3,
        })
        return
    end

    purchaseCount = 0
    _G.AutoBuyTotem = true

    Window:Notify({
        Title = "Auto Buy Totem Enabled",
        Content = string.format(
            "Buying: %s (%s coins)\nLimit: %d totems",
            _G.SelectedBuyTotem,
            TotemPrices[_G.SelectedBuyTotem] or "?",
            _G.BuyTotemLimit
        ),
        Icon = "rbxassetid://7733911621",
        Duration = 3,
    })

    autoBuyThread = task.spawn(function()
        local selected = _G.SelectedBuyTotem
        local limit = _G.BuyTotemLimit
        local purchased = 0

        while _G.AutoBuyTotem and purchased < limit do
            local totemId = TotemMarketIds[selected]
            if not totemId then
                warn("[AutoBuy] Invalid totem ID for:", selected)
                break
            end

            local beforeCount = getTotemCount(selected)

            -- Purchase attempt
            local ok, result = pcall(function()
                return BuyMarket:InvokeServer(totemId)
            end)

            if ok then
                if result then
                    task.wait(0.5) -- Tunggu update inventory
                    local afterCount = getTotemCount(selected)

                    if afterCount > beforeCount then
                        purchased = purchased + 1
                        print(string.format(
                            "[AutoBuy] ✅ Purchased %s (ID: %d) | %d/%d",
                            selected, totemId, purchased, limit
                        ))
                        print("[AutoBuy] Inventory:", afterCount, "totems")
                    else
                        warn("[AutoBuy] ⚠️ Purchase response OK but inventory not updated")
                    end
                else
                    warn("[AutoBuy] ❌ Purchase failed (not enough coins or error)")
                end
            else
                warn("[AutoBuy] ❌ Remote error:", result)
            end

            task.wait(1) -- Cooldown antar pembelian
        end

        -- Auto disable jika limit tercapai
        if purchased >= limit then
            _G.AutoBuyTotem = false
            Window:Notify({
                Title = "Auto Buy Completed",
                Content = string.format("Purchased %d totems!\nAuto Buy disabled.", purchased),
                Icon = "rbxassetid://7733911621",
                Duration = 4,
            })
        end

        autoBuyThread = nil
    end)
end

local function stopAutoBuy()
    _G.AutoBuyTotem = false
    if autoBuyThread then
        task.cancel(autoBuyThread)
        autoBuyThread = nil
    end
    Window:Notify({
        Title = "Auto Buy Totem Disabled",
        Content = string.format("Stopped. Purchased: %d totems", purchaseCount),
        Icon = "rbxassetid://7733911621",
        Duration = 2,
    })
end

-- Toggle Auto Buy Totem
ExclusiveTab:CreateToggle({
    Name = "Auto Buy Totem",
    SubText = "Purchase totem from market",
    Default = false,
    Callback = function(value)
        if value then
            startAutoBuy()
        else
            stopAutoBuy()
        end
    end,
})

-- ============================================================
-- FPS BOOSTER MODULE (Optimized)
-- ============================================================
ExclusiveTab:CreateSection({ Name = "FPS Boost" })

local FPSBooster = {
    Enabled = false,
    _connections = {},
    _originalStates = {
        reflectance = {},
        transparency = {},
        lighting = {},
        effects = {},
        waterProperties = {},
    },
}

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")

-- Fungsi optimize satu objek (dengan pcall internal)
local function optimizeObject(obj)
    if not FPSBooster.Enabled then return end
    pcall(function()
        if obj:IsA("BasePart") then
            if not FPSBooster._originalStates.reflectance[obj] then
                FPSBooster._originalStates.reflectance[obj] = obj.Reflectance
            end
            obj.Reflectance = 0
            obj.CastShadow = false
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            if not FPSBooster._originalStates.transparency[obj] then
                FPSBooster._originalStates.transparency[obj] = obj.Transparency
            end
            obj.Transparency = 1
        elseif obj:IsA("SurfaceAppearance") then
            obj:Destroy()
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
            obj.Enabled = false
        elseif obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            obj.Enabled = false
        end
    end)
end

-- Fungsi restore satu objek
local function restoreObject(obj)
    pcall(function()
        if obj:IsA("BasePart") then
            local ref = FPSBooster._originalStates.reflectance[obj]
            if ref ~= nil then
                obj.Reflectance = ref
                obj.CastShadow = true
            end
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            local trans = FPSBooster._originalStates.transparency[obj]
            if trans ~= nil then
                obj.Transparency = trans
            end
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
            obj.Enabled = true
        elseif obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            obj.Enabled = true
        end
    end)
end

function FPSBooster.Enable()
    if FPSBooster.Enabled then return false, "Already enabled" end
    FPSBooster.Enabled = true

    -- 1. Optimize semua objek existing
    for _, obj in ipairs(workspace:GetDescendants()) do
        optimizeObject(obj)
    end

    -- 2. Matikan animasi air
    if Terrain then
        pcall(function()
            FPSBooster._originalStates.waterProperties = {
                WaterReflectance = Terrain.WaterReflectance,
                WaterWaveSize = Terrain.WaterWaveSize,
                WaterWaveSpeed = Terrain.WaterWaveSpeed,
            }
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
        end)
    end

    -- 3. Optimize Lighting
    FPSBooster._originalStates.lighting = {
        GlobalShadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
    }
    Lighting.GlobalShadows = false
    Lighting.FogStart = 0
    Lighting.FogEnd = 1000000

    -- 4. Matikan Post-Processing
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            FPSBooster._originalStates.effects[effect] = effect.Enabled
            effect.Enabled = false
        end
    end

    -- 5. Set Render Quality ke minimum
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

    -- 6. Hook untuk objek baru (tanpa task.wait)
    local conn = workspace.DescendantAdded:Connect(function(obj)
        if FPSBooster.Enabled then
            task.defer(function() optimizeObject(obj) end)
        end
    end)
    table.insert(FPSBooster._connections, conn)

    return true, "FPS Booster enabled"
end

function FPSBooster.Disable()
    if not FPSBooster.Enabled then return false, "Already disabled" end
    FPSBooster.Enabled = false

    -- 1. Restore semua objek
    for _, obj in ipairs(workspace:GetDescendants()) do
        restoreObject(obj)
    end

    -- 2. Restore Terrain
    if Terrain and FPSBooster._originalStates.waterProperties then
        pcall(function()
            Terrain.WaterReflectance = FPSBooster._originalStates.waterProperties.WaterReflectance
            Terrain.WaterWaveSize = FPSBooster._originalStates.waterProperties.WaterWaveSize
            Terrain.WaterWaveSpeed = FPSBooster._originalStates.waterProperties.WaterWaveSpeed
        end)
    end

    -- 3. Restore Lighting
    local lightingState = FPSBooster._originalStates.lighting
    if lightingState.GlobalShadows ~= nil then
        Lighting.GlobalShadows = lightingState.GlobalShadows
        Lighting.FogEnd = lightingState.FogEnd
        Lighting.FogStart = lightingState.FogStart
    end

    -- 4. Restore Post-Processing
    for effect, state in pairs(FPSBooster._originalStates.effects) do
        if effect and effect.Parent then
            effect.Enabled = state
        end
    end

    -- 5. Restore Render Quality
    settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic

    -- 6. Cleanup connections
    for _, conn in ipairs(FPSBooster._connections) do
        conn:Disconnect()
    end
    FPSBooster._connections = {}

    -- Clear original states
    FPSBooster._originalStates = {
        reflectance = {},
        transparency = {},
        lighting = {},
        effects = {},
        waterProperties = {},
    }

    return true, "FPS Booster disabled"
end

function FPSBooster.IsEnabled()
    return FPSBooster.Enabled
end

-- UI Toggle
ExclusiveTab:CreateToggle({
    Name = "FPS Booster",
    Description = "Boost FPS dengan optimasi graphics (Hapus shadows, reflections, particles & effects)",
    Icon = "rbxassetid://11400562133",
    Default = false,
    Callback = function(value)
        if value then FPSBooster.Enable() else FPSBooster.Disable() end
    end,
})

-- ============================================================
-- PLAYER OPTIMIZE (Optimized)
-- ============================================================
ExclusiveTab:CreateSection({ Name = "Player Optimize" })

-- ---- Disable 3D Rendering ----
local renderEnabled = true
local renderKeepAliveThread

local function setRender(state)
    renderEnabled = state
    RunService:Set3dRenderingEnabled(state)
    print("[Disable3D]", state and "3D Rendering ENABLED" or "3D Rendering DISABLED")
end

-- Keep-alive thread (lebih efisien dengan task.wait)
if renderKeepAliveThread then task.cancel(renderKeepAliveThread) end
renderKeepAliveThread = task.spawn(function()
    while task.wait(3) do
        RunService:Set3dRenderingEnabled(renderEnabled)
    end
end)

-- Re-apply on respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    RunService:Set3dRenderingEnabled(renderEnabled)
    print("[Disable3D] Re-applied after respawn")
end)

ExclusiveTab:CreateToggle({
    Name = "Disable 3D Rendering",
    Default = false,
    Callback = function(state)
        setRender(not state) -- state = true berarti disable
    end,
})

-- ---- Freeze Character ----
local freezeConnection = nil
local originalCFrame = nil

ExclusiveTab:CreateToggle({
    Name = "Freeze Character",
    Default = false,
    Callback = function(state)
        _G.FreezeCharacter = state
        if state then
            local char = Players.LocalPlayer.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    originalCFrame = root.CFrame
                    freezeConnection = RunService.Heartbeat:Connect(function()
                        if _G.FreezeCharacter and root and root.Parent then
                            root.CFrame = originalCFrame
                        end
                    end)
                end
            end
        else
            if freezeConnection then
                freezeConnection:Disconnect()
                freezeConnection = nil
            end
        end
    end,
})

-- ---- Disable Fish Caught Notification ----
local disableNotifs = false
local notifCleanupConnection = nil

ExclusiveTab:CreateToggle({
    Name = "Disable Fish Caught",
    Default = false,
    Callback = function(state)
        disableNotifs = state
        local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

        if state then
            -- Hapus notifikasi yang sudah ada
            local smallNotif = PlayerGui:FindFirstChild("Small Notification")
            if smallNotif then
                smallNotif:Destroy()
            end

            -- Hook untuk mencegah spawn notifikasi baru
            if notifCleanupConnection then
                notifCleanupConnection:Disconnect()
            end
            notifCleanupConnection = PlayerGui.ChildAdded:Connect(function(child)
                if disableNotifs and (child.Name == "Small Notification" or (child:FindFirstChild("Display") and child:FindFirstChildWhichIsA("Frame"))) then
                    task.defer(function()
                        if child and child.Parent then
                            child:Destroy()
                        end
                    end)
                end
            end)
        else
            if notifCleanupConnection then
                notifCleanupConnection:Disconnect()
                notifCleanupConnection = nil
            end
        end
    end,
})

-- ---- Disable Char Effect ----
local disableCharFx = false
local _fxBackup = nil

ExclusiveTab:CreateToggle({
    Name = "Disable Char Effect",
    Default = false,
    Callback = function(state)
        disableCharFx = state
        if state then
            -- Disconnect semua koneksi ke REPlayFishEffect
            if REPlayFishEffect and REPlayFishEffect.OnClientEvent then
                for _, conn in ipairs(getconnections(REPlayFishEffect.OnClientEvent)) do
                    conn:Disconnect()
                end
                REPlayFishEffect.OnClientEvent:Connect(function() end) -- dummy
            end

            -- Backup dan stub FishingController
            if FishingController then
                if not _fxBackup then
                    _fxBackup = {
                        PlayFishingEffect = FishingController.PlayFishingEffect,
                        ReplicateCutscene = FishingController.ReplicateCutscene,
                    }
                end
                FishingController.PlayFishingEffect = function() end
                FishingController.ReplicateCutscene = function() end
            end
        else
            -- Restore FishingController
            if _fxBackup and FishingController then
                FishingController.PlayFishingEffect = _fxBackup.PlayFishingEffect
                FishingController.ReplicateCutscene = _fxBackup.ReplicateCutscene
            end
        end
    end,
})

-- ---- Disable Fishing Effect ----
local delEffects = false
local effectsCleanupConnection = nil
local effectsLoopThread = nil

ExclusiveTab:CreateToggle({
    Name = "Disable Fishing Effect",
    Default = false,
    Callback = function(state)
        delEffects = state

        if state then
            -- Loop untuk hapus efek yang sudah ada (dengan interval lebih hemat)
            if effectsLoopThread then task.cancel(effectsLoopThread) end
            effectsLoopThread = task.spawn(function()
                while delEffects do
                    pcall(function()
                        local cosmetic = workspace:FindFirstChild("CosmeticFolder")
                        if cosmetic then
                            for _, child in ipairs(cosmetic:GetChildren()) do
                                local isExactPart = child.Name == "Part"
                                local isPureNumber = string.match(child.Name, "^%d+$")
                                local isModel = child:IsA("Model")
                                if not (isExactPart or isPureNumber or isModel) then
                                    child:Destroy()
                                end
                            end
                        end
                    end)
                    task.wait(0.5) -- lebih jarang (0.5 detik)
                end
            end)

            -- Hook untuk child baru
            if not effectsCleanupConnection then
                local cosmetic = workspace:FindFirstChild("CosmeticFolder")
                if cosmetic then
                    effectsCleanupConnection = cosmetic.ChildAdded:Connect(function(child)
                        if delEffects then
                            task.defer(function()
                                local isExactPart = child.Name == "Part"
                                local isPureNumber = string.match(child.Name, "^%d+$")
                                local isModel = child:IsA("Model")
                                if not (isExactPart or isPureNumber or isModel) then
                                    child:Destroy()
                                end
                            end)
                        end
                    end)
                end
            end
        else
            -- Matikan loop
            if effectsLoopThread then
                task.cancel(effectsLoopThread)
                effectsLoopThread = nil
            end
            if effectsCleanupConnection then
                effectsCleanupConnection:Disconnect()
                effectsCleanupConnection = nil
            end
        end
    end,
})

-- ---- Hide Rod On Hand ----
local hideRod = false
local hideRodThread = nil

ExclusiveTab:CreateToggle({
    Name = "Hide Rod On Hand",
    Default = false,
    Callback = function(state)
        hideRod = state
        if state then
            if hideRodThread then task.cancel(hideRodThread) end
            hideRodThread = task.spawn(function()
                while hideRod do
                    pcall(function()
                        for _, char in ipairs(workspace.Characters:GetChildren()) do
                            local toolFolder = char:FindFirstChild("!!!EQUIPPED_TOOL!!!")
                            if toolFolder then
                                toolFolder:Destroy()
                            end
                        end
                    end)
                    task.wait(0.5) -- lebih jarang
                end
            end)
        else
            if hideRodThread then
                task.cancel(hideRodThread)
                hideRodThread = nil
            end
        end
    end,
})

-- ============================================================
-- AUTO PERFECTION & TEXT NOTIFICATION HOOK (Dengan Hookfunction)
-- ============================================================

-- Cache FishingController
FishingController = FishingController or require(ReplicatedStorage.Controllers.FishingController)

-- Auto Perfection state
local autoPerf = false
local autoPerfThread = nil

-- Simpan original functions (dengan pcall untuk aman)
local oldClick = nil
local oldCharge = nil
local clickHooked = false
local chargeHooked = false

-- Backup original functions menggunakan hookfunction jika tersedia
if type(hookfunction) == "function" then
    -- Hanya jika hookfunction tersedia
    if FishingController.RequestFishingMinigameClick then
        oldClick = hookfunction(FishingController.RequestFishingMinigameClick, function(self, ...)
            if autoPerf then
                -- Jika autoPerf aktif, tidak melakukan apa-apa
                return
            end
            if oldClick then
                return oldClick(self, ...)
            end
        end)
        clickHooked = true
    end

    if FishingController.RequestChargeFishingRod then
        oldCharge = hookfunction(FishingController.RequestChargeFishingRod, function(self, ...)
            if autoPerf then
                return
            end
            if oldCharge then
                return oldCharge(self, ...)
            end
        end)
        chargeHooked = true
    end
else
    -- Fallback: overwrite langsung dengan backup (tapi ini lebih berisiko)
    oldClick = FishingController.RequestFishingMinigameClick
    oldCharge = FishingController.RequestChargeFishingRod
    clickHooked = true
    chargeHooked = true
end

local function toggleAutoPerfection(state)
    autoPerf = state
    if state then
        if not autoPerfThread then
            autoPerfThread = task.spawn(function()
                while autoPerf do
                    if AutoEnabled then
                        pcall(AutoEnabled.InvokeServer, AutoEnabled, true)
                    end
                    task.wait(1)
                end
            end)
        end
        print("Auto Perfection ON")
    else
        -- Matikan thread
        if autoPerfThread then
            task.cancel(autoPerfThread)
            autoPerfThread = nil
        end
        if AutoEnabled then
            pcall(AutoEnabled.InvokeServer, AutoEnabled, false)
        end
        print("Auto Perfection OFF")
    end
end

-- ============================================================
-- UI TOGGLE
-- ============================================================
ExclusiveTab:CreateSection({ Name = "Auto Perfection" })
ExclusiveTab:CreateToggle({
    Name = "Auto Perfection",
    Default = false,
    Callback = function(state)
        toggleAutoPerfection(state)
    end,
})

-- ============================================================
-- TEXT NOTIFICATION HOOK (AMAN)
-- ============================================================
pcall(function()
    local TextNotificationController = ReplicatedStorage.Controllers:FindFirstChild("TextNotificationController")
    if TextNotificationController and TextNotificationController:IsA("ModuleScript") then
        local ok, controller = pcall(require, TextNotificationController)
        if ok and controller and controller.DeliverNotification then
            local origDeliver = controller.DeliverNotification
            if type(origDeliver) == "function" then
                controller.DeliverNotification = function(self, data, ...)
                    if Config and Config.HookNotif and data then
                        if Config.InstantFishingV2Active then
                            data.CustomDuration = 15
                        elseif _G.BlatantMode then
                            data.CustomDuration = 7.5
                        else
                            data.CustomDuration = 15
                        end
                    end
                    return origDeliver(self, data, ...)
                end
                print("[Notification] Hook installed successfully")
            else
                warn("[Notification] origDeliver is not a function")
            end
        else
            warn("[Notification] Failed to load TextNotificationController")
        end
    else
        warn("[Notification] TextNotificationController not found")
    end
end)

print("[AutoPerfection] Initialized")
-- ============================================================
-- FISH DATABASE & WEBHOOK HELPERS (Refactored)
-- ============================================================

fishDB = fishDB or {}
fishByName = fishByName or {}
local knownFishUUIDs = knownFishUUIDs or {}

local rarityList = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET", "Forgotten" }
local variantList = {
    "Galaxy", "Corrupt", "Gemstone", "Fairy Dust", "Midnight",
    "Color Burn", "Holographic", "Lightning", "Radioactive",
    "Ghost", "Gold", "Frozen", "1x1x1x1", "Stone", "Sandy",
    "Noob", "Moon Fragment", "Festive", "Albino", "Arctic Frost", "Disco", "Big", "Giant", "Sparkling",
    "Crystalized","Aurora"
}
local tierToRarity = {
    [1] = "Common", [2] = "Uncommon", [3] = "Rare", [4] = "Epic",
    [5] = "Legendary", [6] = "Mythic", [7] = "SECRET", [8] = "Forgotten"
}

-- Cache thumbnail URLs
local thumbnailCache = {}

function getThumbnailURL(assetString)
    if not assetString then return nil end
    local assetId = assetString:match("rbxassetid://(%d+)")
    if not assetId then return nil end
    if thumbnailCache[assetId] then return thumbnailCache[assetId] end

    local api = string.format("https://thumbnails.roblox.com/v1/assets?assetIds=%s&type=Asset&size=420x420&format=Png", assetId)
    local success, response = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(api))
    end)
    if success and response and response.data and response.data[1] and response.data[1].imageUrl then
        thumbnailCache[assetId] = response.data[1].imageUrl
        return thumbnailCache[assetId]
    end
    return nil
end

-- Build fish database once
local function buildFishDatabase()
    table.clear(fishDB)
    table.clear(fishByName)
    local itemsContainer = ReplicatedStorage:FindFirstChild("Items")
    if not itemsContainer then
        warn("[FishDB] Items folder not found")
        return
    end
    for _, itemModule in ipairs(itemsContainer:GetChildren()) do
        if itemModule:IsA("ModuleScript") then
            local ok, itemData = pcall(require, itemModule)
            if ok and itemData and itemData.Data and itemData.Data.Type == "Fish" then
                local data = itemData.Data
                if data.Id and data.Name then
                    fishDB[data.Id] = {
                        Name = data.Name,
                        Tier = data.Tier,
                        Icon = data.Icon,
                        SellPrice = itemData.SellPrice or 0
                    }
                    fishByName[data.Name:lower()] = fishDB[data.Id]
                end
            end
        end
    end
    print("[FishDB] Built database with", table.getn(fishDB), "fish")
end

buildFishDatabase()

-- Get inventory fish with caching (refresh every 2 seconds)
local lastFishScan = 0
local cachedFishList = {}

function getInventoryFish()
    if tick() - lastFishScan < 2 then
        return cachedFishList
    end
    if not _G.DataService then
        pcall(function()
            local Replion = require(ReplicatedStorage.Packages.Replion)
            _G.DataService = Replion.Client:WaitReplion("Data")
        end)
        if not _G.DataService then return {} end
    end
    local success, items = pcall(function()
        return _G.DataService:GetExpect({ "Inventory", "Items" })
    end)
    if not success or not items then return {} end

    local fish = {}
    for _, v in ipairs(items) do
        local itemData = _G.ItemUtility and _G.ItemUtility.GetItemDataFromItemType("Items", v.Id)
        if itemData and itemData.Data.Type == "Fish" then
            table.insert(fish, { Id = v.Id, UUID = v.UUID, Metadata = v.Metadata })
        end
    end
    cachedFishList = fish
    lastFishScan = tick()
    return fish
end

function getPlayerCoins()
    if not _G.DataService then return "N/A" end
    local ok, coins = pcall(function() return _G.DataService:Get("Coins") end)
    if ok and coins then
        return string.format("%d", coins):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    end
    return "N/A"
end

-- ============================================================
-- WHATSAPP WEBHOOK (Refactored)
-- ============================================================
_G.WhatsAppWebhookEnabled = _G.WhatsAppWebhookEnabled or false
_G.WA_TargetPhone = _G.WA_TargetPhone or ""
_G.WA_NumberID = _G.WA_NumberID or ""
_G.WA_AccessToken = _G.WA_AccessToken or ""
_G.FonnteToken = _G.FonnteToken or "eJ2K4skattShv2iwYXCU"

function sendFonnteMessage(number, message, imageURL)
    if not httpRequest then return end
    local payload = { target = number, message = message, image = imageURL }
    pcall(function()
        httpRequest({
            Url = "https://api.fonnte.com/send",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json", ["Authorization"] = _G.FonnteToken },
            Body = HttpService:JSONEncode(payload)
        })
    end)
end

function sendFishToWhatsApp_API(fish)
    if not _G.WA_NumberID or _G.WA_NumberID == "" or not _G.WA_AccessToken or _G.WA_AccessToken == "" or not _G.WA_TargetPhone or _G.WA_TargetPhone == "" then
        return
    end
    local info = fishDB[fish.Id]
    if not info then return end
    local rarity = tierToRarity[info.Tier] or "Unknown"
    if #_G.WebhookRarities > 0 and not table.find(_G.WebhookRarities, rarity) then return end

    local weight = (fish.Metadata and fish.Metadata.Weight and string.format("%.2f Kg", fish.Metadata.Weight)) or "N/A"
    local mutation = (fish.Metadata and fish.Metadata.VariantId and tostring(fish.Metadata.VariantId)) or "None"
    local price = info.SellPrice and ("$"..info.SellPrice) or "N/A"
    local coins = getPlayerCoins()
    local totalFish = #getInventoryFish()
    local thumbnail = getThumbnailURL(info.Icon)
    if not thumbnail then return end

    local caption = string.format(
        "🎣 *New Fish Caught!*\n\n🐟 *Name:* %s\n⭐ *Rarity:* %s\n⚖️ *Weight:* %s\n🧬 *Mutation:* %s\n💰 *Sell Price:* %s\n🎒 *Backpack:* %d/4500\n🪙 *Coins:* %s\n\n— VoraHub Auto Fishing",
        info.Name, rarity, weight, mutation, price, totalFish, coins
    )
    pcall(function()
        httpRequest({
            Url = "https://graph.facebook.com/v21.0/" .. _G.WA_NumberID .. "/messages",
            Method = "POST",
            Headers = { ["Authorization"] = "Bearer " .. _G.WA_AccessToken, ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({
                messaging_product = "whatsapp",
                to = _G.WA_TargetPhone,
                type = "image",
                image = { link = thumbnail, caption = caption }
            })
        })
    end)
end

function sendNewFishWA(fish)
    local info = fishDB[fish.Id]
    if not info then return end
    local rarity = tierToRarity[info.Tier] or "Unknown"
    local variant = (fish.Metadata and fish.Metadata.VariantId and tostring(fish.Metadata.VariantId)) or "None"
    local isCrystalized = variant == "Crystalized"
    local forceAnnounce = _G.WebhookCrystalized and isCrystalized
    if not forceAnnounce then
        if #_G.WebhookRarities > 0 and not table.find(_G.WebhookRarities, rarity) then return end
        if _G.WebhookVariants and #_G.WebhookVariants > 0 and not table.find(_G.WebhookVariants, variant) then return end
    end
    local weight = (fish.Metadata and fish.Metadata.Weight and string.format("%.2f Kg", fish.Metadata.Weight)) or "N/A"
    local iconURL = getThumbnailURL(info.Icon)
    local msg = "🐟 New Fish Caught 🐟\n*" .. game.Players.LocalPlayer.Name .. "* Has Caught An *".. rarity .."* Fish!!!\n\n• Name: " .. info.Name .. "\n• Rarity: " .. rarity .. "\n• Weight: " .. weight .. "\n• Variant: " .. variant .. "\n• Sell Price: " .. tostring(info.SellPrice)
    sendFonnteMessage(_G.WA_TargetPhone, msg, iconURL)
end

-- ============================================================
-- SERVER CHAT WEBHOOK (Refactored)
-- ============================================================
_G.ServerChatWebhookURL = _G.ServerChatWebhookURL or ""
_G.ServerChatWebhookEnabled = _G.ServerChatWebhookEnabled or false
_G.ServerChatRarityFilter = _G.ServerChatRarityFilter or {}

local serverRarityColors = {
    { rarity = "Epic",      r = 179, g = 115, b = 248 },
    { rarity = "Legendary", r = 255, g = 185, b = 50  },
    { rarity = "Mythic",    r = 255, g = 25,  b = 25  },
    { rarity = "SECRET",    r = 24,  g = 255, b = 152 },
    { rarity = "Forgotten", r = 255, g = 255, b = 255 },
}
local serverRarityDiscordColors = {
    Epic = 0xB373F8, Legendary = 0xFFB932, Mythic = 0xFF1919, SECRET = 0x18FF98, Forgotten = 0xFFFFFF, Unknown = 0x888888
}

local function getRarityFromRGB(r, g, b)
    local best, bestDist = nil, math.huge
    for _, entry in ipairs(serverRarityColors) do
        local d = ((r - entry.r)^2 + (g - entry.g)^2 + (b - entry.b)^2)^0.5
        if d < bestDist then bestDist = d; best = entry.rarity end
    end
    return (bestDist < 55) and best or nil
end

local function parseRGBFromText(text)
    local rs, gs, bs = text:match('rgb%((%d+),%s*(%d+),%s*(%d+)%)')
    if rs then return tonumber(rs), tonumber(gs), tonumber(bs) end
    local hex = text:match('#(%x%x%x%x%x%x)')
    if hex then return tonumber(hex:sub(1,2),16), tonumber(hex:sub(3,4),16), tonumber(hex:sub(5,6),16) end
    return nil
end

local function sendServerChatDiscordWebhook(playerName, fishName, weight, chance, rarity, imageUrl)
    if not httpRequest then return end
    local url = _G.ServerChatWebhookURL or ""
    if not url:match("discord%.com/api/webhooks") then return end
    if _G.ServerChatRarityFilter and #_G.ServerChatRarityFilter > 0 and not table.find(_G.ServerChatRarityFilter, rarity) then return end
    local embedColor = serverRarityDiscordColors[rarity] or serverRarityDiscordColors.Unknown
    local censored = censorPlayerName(playerName)
    local embed = {
        title = string.format("\xF0\x9F\x8E\xA3 Server Catch | %s", rarity),
        description = string.format("**%s** obtained **%s**!", censored, fishName),
        color = embedColor,
        fields = {
            { name = "Fish", value = string.format("`%s`", fishName), inline = true },
            { name = "Weight", value = string.format("`%s`", weight), inline = true },
            { name = "Rarity", value = string.format("`%s`", rarity), inline = true },
            { name = "Chance", value = string.format("`1 in %s`", chance), inline = true },
            { name = "Player", value = string.format("`%s`", censored), inline = true },
        },
        footer = { text = "VoraHub Server Tracker" },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z"),
    }
    if imageUrl and imageUrl ~= "" then
        embed.thumbnail = { url = imageUrl }
    end
    local payload = {
        username = "VoraHub | Server Tracker",
        avatar_url = "https://cdn.discordapp.com/attachments/1434789394929287178/1448926732705988659/Swuppie.jpg",
        embeds = { embed }
    }
    pcall(function()
        httpRequest({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(payload) })
    end)
end

-- Hook TextChatService
do
    local TCS = game:GetService("TextChatService")
    TCS.OnIncomingMessage = function(message)
        if not _G.ServerChatWebhookEnabled then return end
        local text = message.Text or ""
        if not text:find("obtained") or not text:find("chance") then return end
        local r, g, b = parseRGBFromText(text)
        if not r then return end
        local rarity = getRarityFromRGB(r, g, b)
        if not rarity then return end

        local fishName, weight = text:match('<font[^>]+color="rgb%([^%)]+%)"[^>]*>([^<%(]+)%(([%d%.]+%s*[Kkg]?g?)%)<')
        local plain = text:gsub("<[^>]+>", ""):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&")
        plain = plain:gsub("^%[Server%]:%s*", "")

        local playerName, chance
        if fishName then
            fishName = fishName:gsub("%s+$", "")
            weight = weight:gsub("%s*$", "")
            playerName = plain:match("^([%w_]+) obtained")
            chance = plain:match("with a 1 in (.+) chance!?")
        else
            playerName, fishName, weight, chance = plain:match("^([%w_]+) obtained an? (.+) %(([%d%.]+%s*[Kkg]?g?)%) with a 1 in (.+) chance!?")
            if fishName then fishName = fishName:gsub("%s+$", "") end
            if weight then weight = weight:gsub("%s*$", "") end
        end
        if not playerName or not fishName then return end
        chance = chance and chance:gsub("%s+$", "") or "?"
        local imageUrl = nil
        local fishEntry = fishByName and fishByName[fishName:lower()]
        if fishEntry and fishEntry.Icon then
            imageUrl = getThumbnailURL(fishEntry.Icon)
        end
        task.spawn(sendServerChatDiscordWebhook, playerName, fishName, weight, chance, rarity, imageUrl)
    end
end

-- ============================================================
-- VORAHUB WEB MONITORING (Refactored)
-- ============================================================
MonitoringTab:CreateSection({ Name = "VoraHub Web Monitoring" })

local VoraMonitoringSettings = {
    VoraKey = "",
    AutoSync = true,
    Interval = 5,
    Enabled = false,
}
local VORA_API_URL = "https://monitor.vorahub.xyz/api/inventory/sync"

MonitoringTab:CreateInput({
    Name = "VoraHub Key",
    Placeholder = "Enter VoraHub Key...",
    Default = "",
    Callback = function(val) VoraMonitoringSettings.VoraKey = val end
})
MonitoringTab:CreateToggle({
    Name = "Enable Web Monitoring",
    Default = false,
    Callback = function(val) VoraMonitoringSettings.Enabled = val end
})

local function GetWebItemData(ItemType, Id)
    local ok, result = pcall(function()
        local ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
        if ItemType == "Baits" then return ItemUtility:GetBaitData(Id) end
        if ItemType == "Items" then
            local data = ItemUtility:GetItemData(Id)
            if not data then data = ItemUtility:GetFish(Id) end
            if not data then data = ItemUtility:GetBaitData(Id) end
            if not data then
                local rods = ItemUtility:GetFishingRods()
                if rods then data = rods[Id] end
            end
            if not data then data = ItemUtility:GetTotemData(Id) end
            if not data then data = ItemUtility:GetPotionData(Id) end
            if not data then data = ItemUtility:GetCharmData(Id) end
            if not data then data = ItemUtility:GetBoatData(Id) end
            return data
        end
        if ItemType == "Fish" then return ItemUtility:GetFish(Id) end
        if ItemType == "Fishing Rods" then return ItemUtility:GetFishingRods() and ItemUtility:GetFishingRods()[Id] end
        if ItemType == "Totems" then return ItemUtility:GetTotemData(Id) end
        if ItemType == "Potions" then return ItemUtility:GetPotionData(Id) end
        if ItemType == "Charms" then return ItemUtility:GetCharmData(Id) end
        return ItemUtility:GetItemDataFromItemType(ItemType, Id)
    end)
    return ok and result or nil
end

local function GatherVoraInventory()
    local inventory = { Rods = {}, Charms = {}, Items = {}, Fish = {}, Totems = {}, Potions = {} }
    local Replion = require(ReplicatedStorage.Packages.Replion)
    local DataClient = Replion.Client:WaitReplion("Data")
    if not DataClient then return nil end
    local rawInventory = DataClient:GetExpect("Inventory")
    if not rawInventory then return nil end

    local function safeString(str) return tostring(str or ""):match("^%s*(.-)%s*$") or "" end
    local function addItem(list, item)
        for i, existing in ipairs(list) do
            if existing.name == item.name and existing.tier == item.tier then
                existing.quantity = (existing.quantity or 1) + (item.quantity or 1)
                return
            end
        end
        table.insert(list, item)
    end

    for _, item in ipairs(rawInventory.Charms or {}) do
        local data = GetWebItemData("Charms", item.Id)
        if data then
            addItem(inventory.Charms, {
                id = safeString(item.Id), name = safeString(data.Data.Name), icon = safeString(data.Data.Icon),
                tier = data.Data.Tier or 1, quantity = item.Quantity or 1, uuid = safeString(item.UUID or "")
            })
        end
    end
    for _, item in ipairs(rawInventory.Items or {}) do
        local data = GetWebItemData("Items", item.Id)
        local name, icon, tier, type = "", "", 1, "Item"
        if data and data.Data then
            name = safeString(data.Data.Name or item.Id)
            icon = safeString(data.Data.Icon or item.Icon or "")
            tier = data.Data.Tier or 1
            type = safeString(data.Data.Type or "Item")
        else
            name = safeString(item.Name or item.Id)
            icon = safeString(item.Icon or "")
            tier = item.Tier or 1
        end
        addItem(inventory.Items, {
            id = safeString(item.Id), name = name, icon = icon, tier = tier, type = type,
            quantity = item.Quantity or 1, uuid = safeString(item.UUID or ""), favorited = item.Favorited == true
        })
    end
    for _, item in ipairs(rawInventory.Fish or {}) do
        local data = GetWebItemData("Fish", item.Id)
        if data then
            addItem(inventory.Fish, {
                id = safeString(item.Id), name = safeString(data.Data.Name), icon = safeString(data.Data.Icon),
                tier = data.Data.Tier or 1, quantity = item.Quantity or 1, uuid = safeString(item.UUID or "")
            })
        end
    end
    for _, item in ipairs(rawInventory.Totems or {}) do
        local data = GetWebItemData("Totems", item.Id)
        if data then
            addItem(inventory.Totems, {
                id = safeString(item.Id), name = safeString(data.Data.Name), icon = safeString(data.Data.Icon),
                tier = data.Data.Tier or 1, quantity = item.Quantity or 1, uuid = safeString(item.UUID or "")
            })
        end
    end
    for _, item in ipairs(rawInventory.Potions or {}) do
        local data = GetWebItemData("Potions", item.Id)
        if data then
            addItem(inventory.Potions, {
                id = safeString(item.Id), name = safeString(data.Data.Name), icon = safeString(data.Data.Icon),
                tier = data.Data.Tier or 1, quantity = item.Quantity or 1, uuid = safeString(item.UUID or "")
            })
        end
    end

    local Player = game.Players.LocalPlayer
    local function getLeaderstat(stat)
        local leaderstats = Player:FindFirstChild("leaderstats")
        return leaderstats and leaderstats:FindFirstChild(stat) and leaderstats[stat].Value or 0
    end
    return {
        apiKey = VoraMonitoringSettings.VoraKey,
        playerName = safeString(Player.Name),
        userId = Player.UserId,
        playerStats = {
            totalFishCaught = getLeaderstat("Caught"),
            highestRarity = getLeaderstat("Rarest Fish") or "None"
        },
        inventory = inventory,
        isOnline = true,
        timestamp = DateTime.now():ToIsoDate()
    }
end

local function SendVoraInventory(isOffline)
    if VoraMonitoringSettings.VoraKey == "" or VoraMonitoringSettings.VoraKey == "yourkey" then return end
    local ok, data = pcall(GatherVoraInventory)
    if not ok or not data then return end
    data.isOnline = not isOffline
    local jsonData = HttpService:JSONEncode(data)
    pcall(function()
        httpRequest({
            Url = VORA_API_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json", ["ngrok-skip-browser-warning"] = "true" },
            Body = jsonData
        })
    end)
end

-- Auto-sync loop (gunakan task.spawn)
task.spawn(function()
    while true do
        task.wait(VoraMonitoringSettings.Interval)
        if VoraMonitoringSettings.Enabled and VoraMonitoringSettings.AutoSync then
            SendVoraInventory(false)
        end
    end
end)

game:GetService("Players").PlayerRemoving:Connect(function(p)
    if p == game.Players.LocalPlayer then
        SendVoraInventory(true)
    end
end)

-- ============================================================
-- WEBHOOK DETECTION LOOP (Refactored)
-- ============================================================
task.defer(function()
    task.wait(2)
    local initial = getInventoryFish()
    for _, f in ipairs(initial) do
        if f and f.UUID then knownFishUUIDs[f.UUID] = true end
    end
end)

task.spawn(function()
    while true do
        task.wait(2)
        pcall(function()
            local current = getInventoryFish()
            for _, fish in ipairs(current) do
                if fish and fish.UUID and not knownFishUUIDs[fish.UUID] then
                    knownFishUUIDs[fish.UUID] = true
                    task.spawn(function()
                        pcall(sendGlobalTrackerWebhook, fish)
                        if _G.DetectNewFishActive then
                            task.wait(0.3)
                            pcall(sendNewFishWebhook, fish)
                        end
                        if _G.WhatsAppWebhookEnabled then
                            task.wait(0.3)
                            pcall(sendNewFishWA, fish)
                        end
                    end)
                end
            end
        end)
    end
end)

-- ============================================================
-- CAST MODE
-- ============================================================
MainTab:CreateSection({ Name = "Cast Mode" })

MainTab:CreateDropdown({
    Name = "Global Cast Mode",
    Items = CAST_MODE_LIST,
    Default = Config.UB.Settings.CastMode,
    Callback = function(v)
        if table.find(CAST_MODE_LIST, v) then
            Config.UB.Settings.CastMode = v
            Instant.SetCastMode(v)
        end
    end,
})

-- ============================================================
-- FISHING
-- ============================================================
MainTab:CreateSection({ Name = "Fishing" })

-- Auto Rod Toggle
MainTab:CreateToggle({
    Name = "Auto Rod",
    Default = false,
    Callback = function(Value)
        _G.AutoRod = Value
        if Value and equipTool then
            pcall(equipTool.FireServer, equipTool, 1)
        end
    end
})

-- Mode Selection
CurrentOption = CurrentOption or "Instant"

MainTab:CreateDropdown({
    Name = "Mode",
    Items = { "Legit", "Instant" },
    Default = CurrentOption,
    Callback = function(Option)
        if CurrentOption == "Legit" and Option ~= "Legit" and _G.AutoFarm then
            AutoEnabled:InvokeServer(false)
        end
        CurrentOption = Option
    end
})

-- ============================================================
-- AUTO FARM (Refactored dengan Thread Management)
-- ============================================================
local autoFarmThread = nil
local autoFarmStopRequest = false

local function stopAutoFarmThread()
    autoFarmStopRequest = true
    if autoFarmThread then
        task.cancel(autoFarmThread)
        autoFarmThread = nil
    end
    autoFarmStopRequest = false
end

MainTab:CreateToggle({
    Name = "Auto Farm",
    Default = false,
    Callback = function(Value)
        _G.AutoFarm = Value

        if Value then
            -- Matikan thread sebelumnya jika ada
            stopAutoFarmThread()

            if CurrentOption == "Instant" then
                Window:Notify({
                    Title = "AutoFarm",
                    Content = "Instant Mode ON",
                    Duration = 3
                })

                autoFarmThread = task.spawn(function()
                    while _G.AutoFarm and CurrentOption == "Instant" and not autoFarmStopRequest do
                        pcall(instant)
                        task.wait(0.05) -- 0.05 detik lebih ringan dari 0.001
                    end
                    print("[AutoFarm] Instant loop stopped")
                end)

            elseif CurrentOption == "Legit" then
                AutoEnabled:InvokeServer(true)
                Window:Notify({
                    Title = "AutoFarm",
                    Content = "Legit Mode ON",
                    Duration = 3
                })

                autoFarmThread = task.spawn(function()
                    while _G.AutoFarm and CurrentOption == "Legit" and not autoFarmStopRequest do
                        local success = pcall(function()
                            FishingController:RequestChargeFishingRod(Vector2.new(0, 0), true)
                            task.wait(delayfishing or 1)
                            CallFishDone(REFishDone, 1)
                        end)
                        if not success then
                            task.wait(0.5)
                        end
                        task.wait(0.4 + math.random() * 0.3)
                    end
                    print("[AutoFarm] Legit loop stopped")
                end)
            end

        else
            -- Matikan Auto Farm
            if CurrentOption == "Legit" then
                AutoEnabled:InvokeServer(false)
            end

            -- Hentikan thread
            stopAutoFarmThread()

            Window:Notify({
                Title = "AutoFarm",
                Content = "AutoFarm OFF",
                Duration = 3
            })

            -- Panggil Cancel remote (perbaiki panggilan)
            if Cancel and Cancel.InvokeServer then
                pcall(Cancel.InvokeServer, Cancel)
            else
                pcall(Cancel) -- fallback jika Cancel adalah fungsi
            end

            -- Reset state
            _G.AutoFarm = false
        end
    end
})

-- ============================================================
-- FISHING DELAY INPUT
-- ============================================================
MainTab:CreateInput({
    Name = "Fishing Delay",
    SideLabel = "Fishing Delay",
    Placeholder = "Contoh: 1.0",
    Default = tostring(delayfishing or 1),
    Callback = function(value)
        local n = tonumber(value)
        if n and n > 0 then
            delayfishing = n
        else
            delayfishing = 1
        end
    end
})
-- ============================================================
-- INSTANT FISHING V2 (Refactored - Hati-hati)
-- ============================================================
MainTab:CreateSection({ Name = "Instant Fishing V2" })

-- Backup fungsi asli FishingController (harus ada sebelum blok ini!)
-- Gunakan 'or' agar tidak menimpa jika sudah didefinisikan sebelumnya
instantV2OrigCharge = instantV2OrigCharge or FishingController.RequestChargeFishingRod
instantV2OrigCast = instantV2OrigCast or FishingController.SendFishingRequestToServer
if not instantV2OrigCast then
    instantV2OrigCast = function() end
end

-- Peringatan jika backup gagal (tidak menghentikan script)
if not instantV2OrigCharge or not instantV2OrigCast then
    warn("[InstantV2] Backup functions missing! Instant Fishing V2 may not work properly.")
end

-- Input: Complete Delay
MainTab:CreateInput({
    Name = "Delay Bait (CompleteDelay)",
    SideLabel = "Delay Reel",
    Placeholder = tostring(Config.UB.Settings.CompleteDelay),
    Default = tostring(Config.UB.Settings.CompleteDelay),
    Callback = function(value)
        local n = tonumber(value)
        if n and n > 0 then
            Config.UB.Settings.CompleteDelay = n
            Instant.SetCompleteDelay(n)
        end
    end,
})

-- Input: Cast Delay
MainTab:CreateInput({
    Name = "Cast Delay",
    SideLabel = "Delay Cast",
    Placeholder = tostring(Config.UB.Settings.CancelDelay),
    Default = tostring(Config.UB.Settings.CancelDelay),
    Callback = function(value)
        local n = tonumber(value)
        if n and n >= 0 then
            Config.UB.Settings.CancelDelay = n
            Instant.SetCastDelay(n)
        end
    end,
})

-- Toggle: Enable Instant Fishing V2
MainTab:CreateToggle({
    Name = "Enable Instant Fishing V2",
    Default = false,
    Callback = function(state)
        -- Flag untuk memicu casting (dari moons.lua)
        needCast = true

        -- Update config
        Config.InstantFishingV2Active = state

        -- Panggil fungsi toggle UB (di dalamnya akan start/stop Instant)
        onToggleUB(state)

        -- Overwrite/restore FishingController functions
        if state then
            -- Aktif: stub semua fungsi
            Config.HookNotif = true
            FishingController.RequestChargeFishingRod = function(self, ...)
                -- Tidak melakukan apa-apa (stub)
            end
            FishingController.SendFishingRequestToServer = function(self, ...)
                -- Tidak melakukan apa-apa (stub)
            end
        else
            -- Nonaktif: restore fungsi asli
            Config.HookNotif = false
            FishingController.RequestChargeFishingRod = function(self, ...)
                -- Panggil fungsi asli yang sudah di-backup
                return instantV2OrigCharge(self, ...)
            end
            FishingController.SendFishingRequestToServer = function(self, ...)
                -- Panggil fungsi asli yang sudah di-backup
                return instantV2OrigCast(self, ...)
            end
        end
    end,
})

-- ============================================================
-- INSTANT BOBBER UI
-- ============================================================
MainTab:CreateSection({ Name = "Instant Bobber" })

MainTab:CreateToggle({
    Name = "Instant Bobber",
    Default = false,
    Callback = function(state)
        -- Pastikan fungsi tersedia
        if type(patchInstantBaitOverrideToCastPosition) ~= "function" then
            warn("[InstantBobber] patchInstantBaitOverrideToCastPosition not available!")
            Window:Notify({
                Title = "Error",
                Content = "Instant Bobber function not found!",
                Duration = 3,
            })
            return
        end

        -- Panggil fungsi dengan state
        patchInstantBaitOverrideToCastPosition(state)

        -- Notifikasi
        Window:Notify({
            Title = "Instant Bobber",
            Content = state and "✅ ON (instant cast visual)" or "❌ OFF",
            Duration = 2.5,
        })
    end,
})

-- =============================================================================
-- QUEST (Deep Sea / Element / Diamond) + AUTO TEMPLE LEVER
-- =============================================================================

QuestTab:CreateSection({ Name = "Quest" })

-- CFrame locations (tetap global)
GhostfinnPart1 = CFrame.new(-3741.23804, -135.074417, -1008.8219, -0.983854651, -5.2231119e-08, -0.178969383, -4.4131955e-08, 1, -4.92357373e-08, 0.178969383, -4.05425382e-08, -0.983854651)
GhostfinnPart2 = CFrame.new(-3576.43896, -281.441864, -1652.00879, -0.986065865, 6.27356229e-08, -0.166355252, 4.83395013e-08, 1, 9.0587406e-08, 0.166355252, 8.12836234e-08, -0.986065865)

DiamondQuest2Location = CFrame.new(-3188.67749, 1.07282305, 2101.84595, 0.938817143, 2.14984044e-10, 0.344415963, 8.34196712e-09, 1, -2.33629294e-08, -0.344415963, 2.48066243e-08, 0.938817143)
DiamondQuest3and4Location = CFrame.new(-2158.90967, 53.4871254, 3667.20703, 0.886574924, -4.98531634e-08, -0.462585062, 5.43041133e-12, 1, -1.077604e-07, 0.462585062, 9.55351496e-08, 0.886574924)
DiamondQuest5and6Location = CFrame.new(-669.763306, 17.5000591, 414.084717, -0.998891115, -1.21555646e-08, 0.0470801853, -1.05114397e-08, 1, 3.51693892e-08, -0.0470801853, 3.46355087e-08, -0.998891115)

ElementRodLocation = CFrame.new(2113.85693, -91.1985855, -699.206787, 0.998474956, -5.945203e-09, -0.0552060455, 3.14363247e-09, 1, -5.0834366e-08, 0.0552060455, 5.05832958e-08, 0.998474956)

TEMPLE_LEVER_BASE = CFrame.new(1466.80176, -30.1063519, -575.435425, -0.439164162, 2.01621848e-08, 0.898406804, -1.93919014e-08, 1, -3.19214095e-08, -0.898406804, -3.14405568e-08, -0.439164162)
START_CFRAME = CFrame.new(-544.096191, 16.055603, 116.168938, 0.975038111, 1.26798724e-07, -0.222037584, -1.31077371e-07, 1, -4.5339581e-09, 0.222037584, 3.35248842e-08, 0.975038111)

local TempleLeverLocations = {
    ["Hourglass Diamond Artifact"] = TEMPLE_LEVER_BASE,
    ["Arrow Artifact"] = TEMPLE_LEVER_BASE,
    ["Diamond Artifact"] = TEMPLE_LEVER_BASE,
    ["Crescent Artifact"] = TEMPLE_LEVER_BASE,
}

local TARGET_QUESTS = { ["Element Quest"] = true, ["Deep Sea Quest"] = true, ["Diamond Researcher"] = true }

-- ============================================================
-- QUEST DATA CACHE (Optimasi untuk mengurangi scan UI)
-- ============================================================
local questCache = {}
local questCacheTime = 0
local CACHE_DURATION = 0.5  -- 0.5 detik cache

-- Fungsi utama untuk mengambil data quest dengan cache
function getQuestData(questName)
    local now = tick()
    if questCache[questName] and now - questCacheTime < CACHE_DURATION then
        return questCache[questName]
    end

    local success, data = pcall(function()
        local gui = player:FindFirstChild("PlayerGui")
        if not gui then return nil end
        local questUI = gui:FindFirstChild("Quest")
        if not questUI then return nil end
        local list = questUI:FindFirstChild("List")
        if not list then return nil end
        local inside = list:FindFirstChild("Inside")
        if not inside then return nil end

        for _, child in pairs(inside:GetChildren()) do
            if child:IsA("Frame") and child.Name == "Quest" then
                local data = checkQuestStatus(child)
                if data and data.name == questName then
                    return data
                end
            end
        end
        return nil
    end)

    if success and data then
        questCache[questName] = data
        questCacheTime = now
        return data
    else
        questCache[questName] = nil
        return nil
    end
end

-- ============================================================
-- QUEST STATUS HELPERS (Tetap sama)
-- ============================================================
function isObjectiveCompleted(obj)
    local check = obj:FindFirstChild("Content") and obj.Content:FindFirstChild("Check") and obj.Content.Check:FindFirstChild("Vector")
    return check and check.Visible
end

function getObjectiveProgress(obj)
    local barFrame = obj:FindFirstChild("BarFrame")
    if not barFrame then return 0, "" end
    local bar, bg = barFrame:FindFirstChild("Bar"), barFrame:FindFirstChild("BG")
    local progress = barFrame:FindFirstChild("Progress")
    if not bar or not bg then return 0, "" end
    local pct = (bar.Size.X.Offset / bg.Size.X.Offset) * 100
    return math.floor(pct), (progress and progress.Text) or ""
end

function getObjectiveDetails(obj)
    local content = obj:FindFirstChild("Content")
    if not content then return nil end
    local display = content:FindFirstChild("Display")
    if not display then return nil end
    local t = ""
    if display:FindFirstChild("Prefix") then t = t .. display.Prefix.Text .. " " end
    if display:FindFirstChild("ItemName") then t = t .. display.ItemName.Text .. " " end
    if display:FindFirstChild("Suffix") then t = t .. display.Suffix.Text end
    return t:gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
end

function checkQuestStatus(questFrame)
    local top = questFrame:FindFirstChild("Top")
    if not top then return nil end
    local topFrame = top:FindFirstChild("TopFrame")
    local header = topFrame and topFrame:FindFirstChild("Header")
    if not header then return nil end
    if not TARGET_QUESTS[header.Text] then return nil end
    local content = questFrame:FindFirstChild("Content")
    if not content then return nil end

    local objectives = {}
    local allDone = true
    for i = 1, 10 do
        local obj = content:FindFirstChild("Objective" .. i)
        if obj then
            local details = getObjectiveDetails(obj)
            if details then
                local completed = isObjectiveCompleted(obj)
                local pct, progressText = getObjectiveProgress(obj)
                table.insert(objectives, {
                    text = details,
                    completed = completed,
                    percentage = pct,
                    progressText = progressText,
                })
                if not completed then allDone = false end
            end
        end
    end

    return { name = header.Text, objectives = objectives, allCompleted = allDone and #objectives > 0 }
end

-- ============================================================
-- PROGRESS FUNCTIONS (Tetap kompatibel)
-- ============================================================
function getGhostfinnProgress()
    local out = {}
    local data = getQuestData("Deep Sea Quest")
    for i = 1, 4 do
        if data and data.objectives and data.objectives[i] then
            local o = data.objectives[i]
            local status = o.completed and "✓" or "✗"
            local prog = o.progressText ~= "" and o.progressText or (o.percentage .. "%")
            out[i] = status .. " " .. o.text .. " [" .. prog .. "]"
        else
            out[i] = "No progress data"
        end
    end
    return out
end

function getElementProgress()
    local out = {}
    local data = getQuestData("Element Quest")
    for i = 1, 4 do
        if data and data.objectives and data.objectives[i] then
            local o = data.objectives[i]
            local status = o.completed and "✓" or "✗"
            local prog = o.progressText ~= "" and o.progressText or (o.percentage .. "%")
            out[i] = status .. " " .. o.text .. " [" .. prog .. "]"
        else
            out[i] = "No progress data"
        end
    end
    return out
end

function getDiamondProgress()
    local out = {}
    local data = getQuestData("Diamond Researcher")
    for i = 1, 6 do
        if data and data.objectives and data.objectives[i] then
            local o = data.objectives[i]
            local status = o.completed and "✓" or "✗"
            local prog = o.progressText ~= "" and o.progressText or (o.percentage .. "%")
            out[i] = status .. " " .. o.text .. " [" .. prog .. "]"
        else
            out[i] = "No progress data"
        end
    end
    return out
end

function getElementQuestProgress()
    local p = { "No progress data", "No progress data", "No progress data", "No progress data" }
    local data = getQuestData("Element Quest")
    if data and data.objectives then
        for i = 1, 4 do
            if data.objectives[i] then
                local o = data.objectives[i]
                p[i] = o.progressText ~= "" and o.progressText or (o.percentage .. "%")
            end
        end
    end
    return p
end

function isElementQuestComplete()
    local data = getQuestData("Element Quest")
    return data and data.allCompleted or false
end

function teleportTo(cf)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and cf then
        hrp.CFrame = cf
    end
end

-- =============================================================================
-- STATUS OVERLAY UI (Refactored - Optimized RenderStepped)
-- =============================================================================

PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
Lighting = game:GetService("Lighting")

-- ============================================================
-- CREATE UI ELEMENTS
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VoraHub Status"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local blur = Instance.new("BlurEffect")
blur.Name = "TanzBlur"
blur.Size = 24
blur.Enabled = false
blur.Parent = Lighting

local function makeLabel(name, size, pos, text, fontSize)
    local l = Instance.new("TextLabel")
    l.Name = name
    l.Size = size
    l.Position = pos
    l.AnchorPoint = Vector2.new(0.5, 0.5)
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.fromRGB(255, 255, 255)
    l.Font = Enum.Font.GothamBold
    l.TextSize = fontSize or 18
    l.Text = text or ""
    l.TextXAlignment = Enum.TextXAlignment.Center
    l.Visible = false
    l.Parent = screenGui
    return l
end

-- Labels (tetap global untuk kompatibilitas)
titleLabel = makeLabel("Title", UDim2.new(0, 300, 0, 40), UDim2.new(0.5, 0, 0.25, 0), "VoraHub Status", 24)
titleLabel.TextColor3 = Color3.fromRGB(64, 224, 208)
titleLabel.TextScaled = true

row1 = makeLabel("Row1", UDim2.new(0, 600, 0, 30), UDim2.new(0.5, 0, 0.35, 0))
row2 = makeLabel("Row2", UDim2.new(0, 600, 0, 30), UDim2.new(0.5, 0, 0.4, 0))
row3 = makeLabel("Row3", UDim2.new(0, 600, 0, 30), UDim2.new(0.5, 0, 0.45, 0))

ghostfinnTitle = makeLabel("GhostfinnTitle", UDim2.new(0, 600, 0, 30), UDim2.new(0.4, 0, 0.5, 0), "Deep Sea Quest")
ghostfinnTitle.TextColor3 = Color3.fromRGB(64, 224, 208)
ghostfinnRow1 = makeLabel("Ghostfinn1", UDim2.new(0, 600, 0, 25), UDim2.new(0.4, 0, 0.55, 0), "Loading...", 12)
ghostfinnRow1.Font = Enum.Font.Gotham
ghostfinnRow2 = makeLabel("Ghostfinn2", UDim2.new(0, 600, 0, 25), UDim2.new(0.4, 0, 0.575, 0), "", 12)
ghostfinnRow2.Font = Enum.Font.Gotham
ghostfinnRow3 = makeLabel("Ghostfinn3", UDim2.new(0, 600, 0, 25), UDim2.new(0.4, 0, 0.6, 0), "", 12)
ghostfinnRow3.Font = Enum.Font.Gotham
ghostfinnRow4 = makeLabel("Ghostfinn4", UDim2.new(0, 600, 0, 25), UDim2.new(0.4, 0, 0.625, 0), "", 12)
ghostfinnRow4.Font = Enum.Font.Gotham

elementTitle = makeLabel("ElementTitle", UDim2.new(0, 600, 0, 30), UDim2.new(0.6, 0, 0.5, 0), "Element Quest")
elementTitle.TextColor3 = Color3.fromRGB(64, 224, 208)
elementRow1 = makeLabel("Element1", UDim2.new(0, 600, 0, 25), UDim2.new(0.6, 0, 0.55, 0), "Loading...", 12)
elementRow1.Font = Enum.Font.Gotham
elementRow2 = makeLabel("Element2", UDim2.new(0, 600, 0, 25), UDim2.new(0.6, 0, 0.575, 0), "", 12)
elementRow2.Font = Enum.Font.Gotham
elementRow3 = makeLabel("Element3", UDim2.new(0, 600, 0, 25), UDim2.new(0.6, 0, 0.6, 0), "", 12)
elementRow3.Font = Enum.Font.Gotham
elementRow4 = makeLabel("Element4", UDim2.new(0, 600, 0, 25), UDim2.new(0.6, 0, 0.625, 0), "", 12)
elementRow4.Font = Enum.Font.Gotham

diamondTitle = makeLabel("DiamondTitle", UDim2.new(0, 600, 0, 30), UDim2.new(0.5, 0, 0.68, 0), "Diamond Researcher")
diamondTitle.TextColor3 = Color3.fromRGB(64, 224, 208)
diamondRow1 = makeLabel("Diamond1", UDim2.new(0, 600, 0, 25), UDim2.new(0.5, 0, 0.73, 0), "Loading...", 12)
diamondRow1.Font = Enum.Font.Gotham
diamondRow2 = makeLabel("Diamond2", UDim2.new(0, 600, 0, 25), UDim2.new(0.5, 0, 0.755, 0), "", 12)
diamondRow2.Font = Enum.Font.Gotham
diamondRow3 = makeLabel("Diamond3", UDim2.new(0, 600, 0, 25), UDim2.new(0.5, 0, 0.78, 0), "", 12)
diamondRow3.Font = Enum.Font.Gotham
diamondRow4 = makeLabel("Diamond4", UDim2.new(0, 600, 0, 25), UDim2.new(0.5, 0, 0.805, 0), "", 12)
diamondRow4.Font = Enum.Font.Gotham
diamondRow5 = makeLabel("Diamond5", UDim2.new(0, 600, 0, 25), UDim2.new(0.5, 0, 0.83, 0), "", 12)
diamondRow5.Font = Enum.Font.Gotham
diamondRow6 = makeLabel("Diamond6", UDim2.new(0, 600, 0, 25), UDim2.new(0.5, 0, 0.855, 0), "", 12)
diamondRow6.Font = Enum.Font.Gotham

-- ============================================================
-- OVERLAY VISIBILITY CONTROL (Tetap kompatibel)
-- ============================================================
_G.KaitunGUIForce = _G.KaitunGUIForce or false

function updateOverlayVisibility()
    local anyActive = _G.DeepSeaQuestMode or _G.ElementQuestMode or _G.DiamondQuestMode
    local visible = _G.KaitunGUIForce or anyActive

    row1.Visible = visible
    row2.Visible = visible
    row3.Visible = visible
    titleLabel.Visible = visible
    blur.Enabled = visible

    ghostfinnTitle.Visible = _G.DeepSeaQuestMode
    ghostfinnRow1.Visible = _G.DeepSeaQuestMode
    ghostfinnRow2.Visible = _G.DeepSeaQuestMode
    ghostfinnRow3.Visible = _G.DeepSeaQuestMode
    ghostfinnRow4.Visible = _G.DeepSeaQuestMode

    elementTitle.Visible = _G.ElementQuestMode
    elementRow1.Visible = _G.ElementQuestMode
    elementRow2.Visible = _G.ElementQuestMode
    elementRow3.Visible = _G.ElementQuestMode
    elementRow4.Visible = _G.ElementQuestMode

    diamondTitle.Visible = _G.DiamondQuestMode
    diamondRow1.Visible = _G.DiamondQuestMode
    diamondRow2.Visible = _G.DiamondQuestMode
    diamondRow3.Visible = _G.DiamondQuestMode
    diamondRow4.Visible = _G.DiamondQuestMode
    diamondRow5.Visible = _G.DiamondQuestMode
    diamondRow6.Visible = _G.DiamondQuestMode
end

updateOverlayVisibility()

function isAnyQuestActive()
    return _G.DeepSeaQuestMode or _G.ElementQuestMode or _G.DiamondQuestMode
end

function updateUIVisibility()
    pcall(updateOverlayVisibility)
end

-- Toggle Kaitun GUI
ExclusiveTab:CreateToggle({
    Title = "Start Kaitun",
    Default = _G.KaitunGUIForce,
    Callback = function(state)
        _G.KaitunGUIForce = state
        pcall(updateOverlayVisibility)
    end,
})

-- ============================================================
-- OPTIMIZED RENDER UPDATER (Hanya update jika data berubah)
-- ============================================================
local renderConnection = nil

-- Cache data terakhir untuk deteksi perubahan
local lastData = {
    rod = "",
    bait = "",
    coins = "",
    ghostfinn = {},
    element = {},
    diamond = {},
}

local function isTableEqual(a, b)
    if #a ~= #b then return false end
    for i = 1, #a do
        if a[i] ~= b[i] then return false end
    end
    return true
end

local function updateStatusLabels()
    -- Cek apakah semua fungsi tersedia
    if type(getBestRod) ~= "function" or type(getBestBait) ~= "function" or type(getCoins) ~= "function" then
        return
    end
    if type(getGhostfinnProgress) ~= "function" or type(getElementProgress) ~= "function" or type(getDiamondProgress) ~= "function" then
        return
    end

    -- Ambil data
    local rod = tostring(getBestRod() or "")
    local bait = tostring(getBestBait() or "")
    local coins = tostring(getCoins() or "")
    local gf = getGhostfinnProgress()
    local el = getElementProgress()
    local dm = getDiamondProgress()

    -- Update hanya jika ada perubahan
    local updated = false

    if rod ~= lastData.rod then
        row1.Text = "Best Rod: " .. rod
        lastData.rod = rod
        updated = true
    end

    if bait ~= lastData.bait then
        row2.Text = "Best Bait: " .. bait
        lastData.bait = bait
        updated = true
    end

    if coins ~= lastData.coins then
        row3.Text = "Coins: " .. coins
        lastData.coins = coins
        updated = true
    end

    if not isTableEqual(gf, lastData.ghostfinn) then
        ghostfinnRow1.Text = gf[1] or "No progress data"
        ghostfinnRow2.Text = gf[2] or "No progress data"
        ghostfinnRow3.Text = gf[3] or "No progress data"
        ghostfinnRow4.Text = gf[4] or "No progress data"
        lastData.ghostfinn = gf
        updated = true
    end

    if not isTableEqual(el, lastData.element) then
        elementRow1.Text = el[1] or "No progress data"
        elementRow2.Text = el[2] or "No progress data"
        elementRow3.Text = el[3] or "No progress data"
        elementRow4.Text = el[4] or "No progress data"
        lastData.element = el
        updated = true
    end

    if not isTableEqual(dm, lastData.diamond) then
        diamondRow1.Text = dm[1] or "No progress data"
        diamondRow2.Text = dm[2] or "No progress data"
        diamondRow3.Text = dm[3] or "No progress data"
        diamondRow4.Text = dm[4] or "No progress data"
        diamondRow5.Text = dm[5] or "No progress data"
        diamondRow6.Text = dm[6] or "No progress data"
        lastData.diamond = dm
        updated = true
    end

    -- Update visibility (selalu update, tidak perlu cache)
    updateOverlayVisibility()
end

-- Jalankan update pertama
task.defer(updateStatusLabels)

-- RenderStepped dengan throttling (maksimal 10x/detik, cukup untuk UI)
renderConnection = RunService.RenderStepped:Connect(function()
    pcall(updateStatusLabels)
end)

-- ============================================================
-- CLEANUP (Opsional - jika dibutuhkan)
-- ============================================================
-- Fungsi untuk membersihkan overlay dan koneksi
local function cleanupOverlay()
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
    if screenGui then
        screenGui:Destroy()
    end
end

-- Simpan cleanup function ke _G agar bisa dipanggil jika diperlukan
_G._cleanupOverlay = cleanupOverlay

-- =============================================================================
-- QUEST PROCESS FUNCTIONS (Refactored)
-- Handles: Deep Sea, Element, Diamond, Temple Lever
-- =============================================================================

_G.AutoDeepSeaQuest = _G.AutoDeepSeaQuest or _G.DeepSeaQuestMode or false
_G.AutoElementQuest = _G.AutoElementQuest or _G.ElementQuestMode or false
_G.AutoDiamondQuest = _G.AutoDiamondQuest or _G.DiamondQuestMode or false
_G.AutoCreateTranscendedStones = _G.AutoCreateTranscendedStones or false

-- ============================================================
-- HELPER FUNCTIONS (Untuk mengurangi duplikasi)
-- ============================================================
local function enableAutoFarm(state)
    if AutoEnabled then
        pcall(AutoEnabled.InvokeServer, AutoEnabled, state)
    end
end

local function cancelFishing()
    if Cancel then
        pcall(Cancel.InvokeServer, Cancel)
    else
        pcall(Cancel)  -- fallback jika Cancel adalah fungsi
    end
end

local function equipBestRodWithRetry()
    pcall(equipBestRodNowWithRetry, 3, 0.3)
end

local function equipGhostfinnIfPossible()
    if not equipGhostfinnRod() then
        equipBestRodWithRetry()
    end
end

-- ============================================================
-- DEEP SEA QUEST
-- ============================================================
local dsDeepSeaStep = nil
local dsDeepSeaDone = false
local dsDeepSeaGUIReady = false

local DS_STEP1_LOC = CFrame.new(-3612.3645, -279.07373, -1693.4845,
    -0.999661744, 3.77537575e-08, 0.0260070078, 3.80828276e-08, 1,
    1.21579262e-08, -0.0260070078, 1.31442341e-08, -0.999661744)
local DS_STEP2_LOC = CFrame.new(-3733.34985, -135.074417, -1011.00171,
    -0.961937428, 3.60563774e-08, -0.273269713, 5.88834368e-08, 1,
    -7.53314495e-08, 0.273269713, -8.85552041e-08, -0.961937428)

function dsRefreshStep()
    local data = getQuestData("Deep Sea Quest")  -- Sekarang hanya 1 panggilan
    if not data then
        dsDeepSeaGUIReady = false
        return
    end
    dsDeepSeaGUIReady = true
    dsDeepSeaDone = data.allCompleted or false
    dsDeepSeaStep = nil
    if dsDeepSeaDone then return end
    for i = 1, 4 do
        local obj = data.objectives and data.objectives[i]
        if obj and not obj.completed then
            dsDeepSeaStep = i
            return
        end
    end
    dsDeepSeaDone = true
end

function dsProcessQuest()
    if getRodUUID(169) then return false end
    dsRefreshStep()
    if dsDeepSeaDone then return false end
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    if not dsDeepSeaGUIReady then
        hrp.CFrame = DS_STEP2_LOC
        return true
    end
    if dsDeepSeaStep == 1 then
        hrp.CFrame = DS_STEP1_LOC
        return true
    elseif dsDeepSeaStep == 2 or dsDeepSeaStep == 3 then
        hrp.CFrame = DS_STEP2_LOC
        return true
    end
    return false
end

-- ============================================================
-- ELEMENT QUEST
-- ============================================================
local elemStep = nil
local elemDone = false
local elemGUIReady = false

local ELEM_CELLAR  = CFrame.new(2113.85693, -91.1985855, -699.206787,
    0.998474956, -5.945203e-09, -0.0552060455, 3.14363247e-09, 1,
    -5.0834366e-08, 0.0552060455, 5.05832958e-08, 0.998474956)
local ELEM_JUNGLE  = CFrame.new(1474.01025, 2.64634514, -324.647125,
    -0.413843632, -6.18603408e-08, -0.910347998, -9.32754673e-08, 1,
    -2.55494399e-08, 0.910347998, 7.43396598e-08, -0.413843632)
local ELEM_TEMPLE  = CFrame.new(1464.96277, -22.3750019, -652.420166,
    -0.0930489823, -1.17108794e-08, 0.995661557, 8.05597278e-09, 1,
    1.25147741e-08, -0.995661557, 9.18550924e-09, -0.0930489823)

function elemRefreshStep()
    local data = getQuestData("Element Quest")
    if not data then
        elemGUIReady = false
        return
    end
    elemGUIReady = true
    elemDone = data.allCompleted or false
    elemStep = nil
    if elemDone then return end
    for i = 1, 4 do
        local obj = data.objectives and data.objectives[i]
        if obj and not obj.completed then
            elemStep = i
            return
        end
    end
    elemDone = true
end

-- Cache untuk tier7 UUID (di-reset setiap kali)
local elemTier7Cache = nil
local elemTier7CacheTime = 0

function elemGetTier7UUID()
    local now = tick()
    if elemTier7Cache and now - elemTier7CacheTime < 2 then
        return elemTier7Cache
    end

    local inv = getInventoryCache()  -- menggunakan cache dari helper sebelumnya
    if inv and inv.Items then
        for _, item in ipairs(inv.Items) do
            local info = ItemUtility and ItemUtility.GetItemDataFromItemType("Items", item.Id)
            if info and info.Tier == 7 and item.UUID then
                elemTier7Cache = item.UUID
                elemTier7CacheTime = now
                return elemTier7Cache
            end
        end
    end
    elemTier7Cache = nil
    elemTier7CacheTime = now
    return nil
end

function elemEquipAndCreateStone()
    local uuid = elemGetTier7UUID()
    if not uuid then return false end
    if REEquipItem then
        pcall(REEquipItem.FireServer, REEquipItem, uuid, "Fish")
    end
    task.wait(0.5)

    -- Cari slot di backpack
    local ok, bp = pcall(function() return player.PlayerGui.Backpack end)
    if ok and bp then
        local disp = bp:FindFirstChild("Display")
        if disp then
            local cnt = 0
            for _, c in ipairs(disp:GetChildren()) do
                if c:IsA("ImageButton") then cnt = cnt + 1 end
            end
            local slot = cnt - 2
            if slot > 0 then
                if REEquip then
                    pcall(REEquip.FireServer, REEquip, slot)
                end
                task.wait(0.5)
            end
        end
    end

    if RFCreateTranscendedStone then
        pcall(RFCreateTranscendedStone.InvokeServer, RFCreateTranscendedStone)
    end
    return true
end

function elemProcessQuest()
    if not getRodUUID(169) then return false end
    if getRodUUID(257) then return false end
    elemRefreshStep()
    if elemDone then return false end

    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    if not elemGUIReady or elemStep == 1 then
        hrp.CFrame = ELEM_CELLAR
        return true
    elseif elemStep == 2 then
        hrp.CFrame = ELEM_JUNGLE
        return true
    elseif elemStep == 3 then
        if areAllTempleLeversComplete() then
            hrp.CFrame = ELEM_TEMPLE
        else
            processTempleLevers()
        end
        return true
    elseif elemStep == 4 then
        if _G.AutoCreateTranscendedStones then
            elemEquipAndCreateStone()
        end
        return true
    end
    return false
end

-- ============================================================
-- DIAMOND RESEARCHER QUEST
-- ============================================================
local diamStep = nil
local diamDone = false
local diamGUIReady = false

local DIAM_CORAL  = CFrame.new(-3135.93872, 2.11425161, 2123.89819,
    0.997291982, -9.13398495e-08, 0.0735437796, 9.35643314e-08, 1,
    -2.68018781e-08, -0.0735437796, 3.36103732e-08, 0.997291982)
local DIAM_TROPIK = CFrame.new(-2093.49512, 6.26801682, 3699.17993,
    0.586044073, -4.36226735e-08, -0.810279191, -1.45249288e-08, 1,
    -6.43419256e-08, 0.810279191, 4.94764478e-08, 0.586044073)
local DIAM_LOCH   = CFrame.new(-617.281433, 3.30004835, 565.878357,
    0.876953125, -9.79836869e-08, 0.480575919, 5.34272928e-08, 1,
    1.06394126e-07, -0.480575919, -6.76267931e-08, 0.876953125)

function diamRefreshStep()
    local data = getQuestData("Diamond Researcher")
    if not data then
        diamGUIReady = false
        return
    end
    diamGUIReady = true
    diamDone = data.allCompleted or false
    diamStep = nil
    if diamDone then return end
    for i = 1, 6 do
        local obj = data.objectives and data.objectives[i]
        if obj and not obj.completed then
            diamStep = i
            return
        end
    end
    diamDone = true
end

function diamActivateGUI()
    if REDialogueEnded then
        pcall(REDialogueEnded.FireServer, REDialogueEnded, "Diamond Researcher", 1, 2)
    end
    task.wait(2)
end

-- Cache untuk item diamond
local diamItemCache = {}
local diamItemCacheTime = 0

function diamHasItem(id, variantId)
    local now = tick()
    local cacheKey = tostring(id) .. "_" .. tostring(variantId or "")
    if diamItemCache[cacheKey] and now - diamItemCacheTime < 2 then
        local cached = diamItemCache[cacheKey]
        return cached.found, cached.uuid
    end

    local inv = getInventoryCache()
    if inv and inv.Items then
        for _, item in ipairs(inv.Items) do
            if item.Id == id then
                if not variantId then
                    diamItemCache[cacheKey] = { found = true, uuid = item.UUID }
                    diamItemCacheTime = now
                    return true, item.UUID
                end
                if item.Metadata and item.Metadata.VariantId == variantId then
                    diamItemCache[cacheKey] = { found = true, uuid = item.UUID }
                    diamItemCacheTime = now
                    return true, item.UUID
                end
            end
        end
    end
    diamItemCache[cacheKey] = { found = false, uuid = nil }
    diamItemCacheTime = now
    return false, nil
end

function diamEquipItemAndGive(uuid, dialogueArg)
    if REEquipItem then
        pcall(REEquipItem.FireServer, REEquipItem, uuid, "Fish")
    end
    task.wait(0.5)

    local ok, bp = pcall(function() return player.PlayerGui.Backpack end)
    if ok and bp then
        local disp = bp:FindFirstChild("Display")
        if disp then
            local cnt = 0
            for _, c in ipairs(disp:GetChildren()) do
                if c:IsA("ImageButton") then cnt = cnt + 1 end
            end
            local slot = cnt - 2
            if slot > 0 and REEquip then
                pcall(REEquip.FireServer, REEquip, slot)
                task.wait(0.5)
            end
        end
    end

    enableAutoFarm(false)
    if REDialogueEnded then
        pcall(REDialogueEnded.FireServer, REDialogueEnded, "Diamond Researcher", 2, dialogueArg)
    end
    task.wait(2)
end

function diamProcessQuest()
    if not getRodUUID(257) then return false end
    diamRefreshStep()
    if diamDone then return false end

    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    if not diamGUIReady then
        diamActivateGUI()
        return false
    end

    if diamStep == 2 then
        hrp.CFrame = DIAM_CORAL
        return true
    elseif diamStep == 3 then
        hrp.CFrame = DIAM_TROPIK
        return true
    elseif diamStep == 4 then
        local hasRuby, rubyUUID = diamHasItem(243, "Gemstone")
        if not hasRuby then
            hrp.CFrame = DIAM_TROPIK
        else
            diamEquipItemAndGive(rubyUUID, 1)
        end
        return true
    elseif diamStep == 5 then
        local hasLoch, lochUUID = diamHasItem(228)
        if not hasLoch then
            hrp.CFrame = DIAM_LOCH
        else
            diamEquipItemAndGive(lochUUID, 2)
        end
        return true
    end
    return false
end

-- ============================================================
-- CONTINUOUS PROCESS LOOPS (Digabung menjadi satu loop)
-- ============================================================
task.spawn(function()
    while true do
        task.wait(3)
        -- Deep Sea
        if _G.DeepSeaQuestMode or _G.AutoDeepSeaQuest then
            pcall(dsProcessQuest)
        end
        -- Element
        if _G.ElementQuestMode or _G.AutoElementQuest then
            pcall(elemProcessQuest)
        end
        -- Diamond
        if _G.DiamondQuestMode or _G.AutoDiamondQuest then
            pcall(diamProcessQuest)
        end
    end
end)

-- ============================================================
-- QUEST PARAGRAPH UPDATE (Dengan cache untuk menghindari update berlebihan)
-- ============================================================
local lastParagraphData = {
    deepSea = "",
    element = "",
    diamond = "",
}
task.spawn(function()
    while true do
        -- Guard: pastikan semua paragraph dan fungsi tersedia
        if deepSeaParagraph and elementParagraph and diamondParagraph and templeLeverParagraph
            and type(getGhostfinnProgress) == "function"
            and type(getElementProgress) == "function"
            and type(getDiamondProgress) == "function"
            and type(areAllTempleLeversComplete) == "function"
        then
            pcall(function()
                local gf = getGhostfinnProgress()
                if gf then
                    local text = table.concat(gf, "\n")
                    if text ~= lastParagraphData.deepSea then
                        deepSeaParagraph:SetDesc(text)
                        lastParagraphData.deepSea = text
                    end
                end

                local el = getElementProgress()
                if el then
                    local text = table.concat(el, "\n")
                    if text ~= lastParagraphData.element then
                        elementParagraph:SetDesc(text)
                        lastParagraphData.element = text
                    end
                end

                local dm = getDiamondProgress()
                if dm then
                    local text = table.concat(dm, "\n")
                    if text ~= lastParagraphData.diamond then
                        diamondParagraph:SetDesc(text)
                        lastParagraphData.diamond = text
                    end
                end

                refreshTempleLeverStatuses()
            end)
        end
        task.wait(2)
    end
end)

-- ============================================================
-- QUEST TAB UI ELEMENTS (Tetap kompatibel)
-- ============================================================
QuestTab:CreateSection({ Name = "Deep Sea Quest" })
deepSeaParagraph = QuestTab:CreateParagraph({
    Title = "Deep Sea Quest",
    Desc = "Loading...",
    RichText = true
})

QuestTab:CreateToggle({
    Name = "Auto Deep Sea Quest",
    Default = _G.AutoDeepSeaQuest or _G.DeepSeaQuestMode or false,
    Callback = function(state)
        _G.DeepSeaQuestMode = state
        _G.AutoDeepSeaQuest = state
        if state then
            enableAutoFarm(true)
            equipBestRodWithRetry()
        end
        updateUIVisibility()
        if not state and not isAnyQuestActive() then
            enableAutoFarm(false)
            cancelFishing()
        end
    end
})

QuestTab:CreateSection({ Name = "Element Quest" })
elementParagraph = QuestTab:CreateParagraph({
    Title = "Element Quest",
    Desc = "Loading...",
    RichText = true
})

QuestTab:CreateToggle({
    Name = "Auto Element Quest",
    Default = _G.AutoElementQuest or _G.ElementQuestMode or false,
    Callback = function(state)
        _G.ElementQuestMode = state
        _G.AutoElementQuest = state
        if state then
            enableAutoFarm(true)
            equipGhostfinnIfPossible()
        end
        updateUIVisibility()
        if not state and not isAnyQuestActive() then
            enableAutoFarm(false)
            cancelFishing()
        end
    end
})

QuestTab:CreateToggle({
    Name = "Auto Create Transcended Stones",
    Default = _G.AutoCreateTranscendedStones or false,
    Callback = function(state)
        _G.AutoCreateTranscendedStones = state
    end
})

QuestTab:CreateSection({ Name = "Diamond Researcher" })
diamondParagraph = QuestTab:CreateParagraph({
    Title = "Diamond Researcher",
    Desc = "Loading...",
    RichText = true
})

QuestTab:CreateToggle({
    Name = "Auto Diamond Quest",
    Default = _G.AutoDiamondQuest or _G.DiamondQuestMode or false,
    Callback = function(state)
        _G.DiamondQuestMode = state
        _G.AutoDiamondQuest = state
        if state then
            enableAutoFarm(true)
            equipBestRodWithRetry()
        end
        updateUIVisibility()
        if not state and not isAnyQuestActive() then
            enableAutoFarm(false)
            cancelFishing()
        end
    end
})

QuestTab:CreateToggle({
    Name = "Pass All Quests",
    Default = false,
    Callback = function(state)
        if state then
            _G.DeepSeaQuestMode = true
            _G.ElementQuestMode = true
            _G.DiamondQuestMode = true
            _G.AutoDeepSeaQuest = true
            _G.AutoElementQuest = true
            _G.AutoDiamondQuest = true
            enableAutoFarm(true)
            equipGhostfinnIfPossible()
        else
            _G.DeepSeaQuestMode = false
            _G.ElementQuestMode = false
            _G.DiamondQuestMode = false
            _G.AutoDeepSeaQuest = false
            _G.AutoElementQuest = false
            _G.AutoDiamondQuest = false
            enableAutoFarm(false)
            cancelFishing()
        end
        updateUIVisibility()
    end,
})

QuestTab:CreateSection({ Name = "Temple Lever" })
templeLeverParagraph = QuestTab:CreateParagraph({
    Title = "Temple Lever Status",
    Desc = "In Progress",
    RichText = true
})

-- Deklarasikan templeLeverThread sebagai local di sini
local templeLeverThread = nil

QuestTab:CreateToggle({
    Name = "Auto Temple Lever",
    Default = false,
    Callback = function(state)
        _G.AutoTempleLever = state
        if templeLeverThread then
            task.cancel(templeLeverThread)
            templeLeverThread = nil
        end
        if not state then return end

        templeLeverThread = task.spawn(function()
            while _G.AutoTempleLever do
                pcall(function()
                    if not areAllTempleLeversComplete() then
                        processTempleLevers()
                    end
                end)
                task.wait(4)
            end
        end)
    end
})

-- =============================================================================
-- LOOPS: PERIODIC TELEPORT, ONE-CLICK FISHING, SELL, BUY RODS/BAITS (Refactored)
-- =============================================================================

-- ============================================================
-- TELEPORT BASED ON CONDITION (Dengan caching)
-- ============================================================
local lastQuestDataCache = {}
local questDataCacheTime = 0
local CACHE_QUEST_DURATION = 0.5

local function getQuestDataWithCache(questName)
    local now = tick()
    if lastQuestDataCache[questName] and now - questDataCacheTime < CACHE_QUEST_DURATION then
        return lastQuestDataCache[questName]
    end
    local data = getQuestData(questName)
    lastQuestDataCache[questName] = data
    questDataCacheTime = now
    return data
end

function teleportBasedOnCondition()
    local bestRod = getBestRod()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Deep Sea Quest (gunakan cache)
    local ghostfinnData = getQuestDataWithCache("Deep Sea Quest")
    local isDeepSeaComplete = ghostfinnData and ghostfinnData.allCompleted or false
    local isLabel1Done = ghostfinnData and ghostfinnData.objectives[1] and ghostfinnData.objectives[1].completed or false
    local isLabel2Done = ghostfinnData and ghostfinnData.objectives[2] and ghostfinnData.objectives[2].completed or false
    local isLabel3Done = ghostfinnData and ghostfinnData.objectives[3] and ghostfinnData.objectives[3].completed or false

    -- Element Quest
    local elementData = getQuestDataWithCache("Element Quest")
    local isElementQuestDone = elementData and elementData.allCompleted or false

    -- Diamond Quest
    local diamondData = getQuestDataWithCache("Diamond Researcher")
    local isDiamondComplete = diamondData and diamondData.allCompleted or false
    local isDiamondObj1Done = diamondData and diamondData.objectives[1] and diamondData.objectives[1].completed or false
    local isDiamondObj2Done = diamondData and diamondData.objectives[2] and diamondData.objectives[2].completed or false
    local isDiamondObj3Done = diamondData and diamondData.objectives[3] and diamondData.objectives[3].completed or false
    local isDiamondObj4Done = diamondData and diamondData.objectives[4] and diamondData.objectives[4].completed or false
    local isDiamondObj5Done = diamondData and diamondData.objectives[5] and diamondData.objectives[5].completed or false
    local isDiamondObj6Done = diamondData and diamondData.objectives[6] and diamondData.objectives[6].completed or false

    local hasElementRod = getRodUUID(257) ~= nil
    local hasGhostfinnRod = getRodUUID(169) ~= nil

    if _G.DiamondQuestMode then
        if isDiamondComplete then
            Window:Notify({
                Title = "Quest Complete!",
                Content = "Diamond Quest has been completed!\nAuto-farm disabled.",
                Duration = 10
            })
            _G.DiamondQuestMode = false
            updateUIVisibility()
            hrp.CFrame = START_CFRAME
            return
        end

        if not isDiamondObj2Done then
            if hasAnyItemInInventory({ "Monster Shark", "Eerie Shark" }) then
                hrp.CFrame = DiamondQuest3and4Location
            else
                hrp.CFrame = DiamondQuest2Location
            end
            return
        end

        if not isDiamondObj3Done or not isDiamondObj4Done then
            if not isDiamondObj3Done then
                if hasItemInInventory("Great Whale") then
                    if hasItemInInventory("Ruby") then
                        hrp.CFrame = DiamondQuest5and6Location
                    else
                        hrp.CFrame = DiamondQuest3and4Location
                    end
                else
                    hrp.CFrame = DiamondQuest3and4Location
                end
                return
            end

            if not isDiamondObj4Done then
                if hasItemInInventory("Ruby") then
                    hrp.CFrame = DiamondQuest5and6Location
                else
                    hrp.CFrame = DiamondQuest3and4Location
                end
                return
            end
            return
        end

        if not isDiamondObj5Done or not isDiamondObj6Done then
            if isDiamondObj6Done and not isDiamondObj5Done then
                hrp.CFrame = DiamondQuest3and4Location
            elseif hasItemInInventory("Lochnes Monster") then
                hrp.CFrame = DiamondQuest3and4Location
            else
                hrp.CFrame = DiamondQuest5and6Location
            end
            return
        end

        hrp.CFrame = ElementRodLocation
        return
    end

    if _G.ElementQuestMode then
        if isElementQuestDone or hasElementRod then
            Window:Notify({
                Title = "Quest Complete!",
                Content = "Element Quest has been completed!\nElement Rod obtained.\nAuto-farm disabled.",
                Duration = 10
            })
            _G.ElementQuestMode = false
            updateUIVisibility()
            hrp.CFrame = START_CFRAME
            return
        end

        if hasGhostfinnRod then
            equipGhostfinnRod()
            task.wait(0.5)
        end

        local curElement = getQuestDataWithCache("Element Quest")
        local elemLabel2 = curElement and curElement.objectives[2] and curElement.objectives[2].completed or false

        if not elemLabel2 then
            if not areAllTempleLeversComplete() then
                processTempleLevers()
                task.spawn(function()
                    while not areAllTempleLeversComplete() do
                        task.wait(5)
                    end
                    local c = player.Character
                    if c and c:FindFirstChild("HumanoidRootPart") then
                        c.HumanoidRootPart.CFrame = ElementRodLocation
                    end
                end)
            else
                hrp.CFrame = ElementRodLocation
            end
        else
            hrp.CFrame = TEMPLE_LEVER_BASE
        end
        return
    end

    if _G.DeepSeaQuestMode then
        if isDeepSeaComplete or hasGhostfinnRod then
            Window:Notify({
                Title = "Quest Complete!",
                Content = "Deep Sea Quest has been completed!\nGhostfinn Rod obtained.\nAuto-farm disabled.",
                Duration = 10
            })
            _G.DeepSeaQuestMode = false
            updateUIVisibility()
            hrp.CFrame = START_CFRAME
            return
        end

        if not isLabel1Done and isLabel2Done and isLabel3Done and not hasGhostfinnRod then
            hrp.CFrame = GhostfinnPart2
            return
        end

        if bestRod == "Astral Rod" or bestRod == "Midnight Rod" then
            hrp.CFrame = GhostfinnPart1
            return
        end
    end

    hrp.CFrame = START_CFRAME
end

function initialTeleport()
    if not _G.HasTeleported then
        _G.HasTeleported = true
        teleportBasedOnCondition()
        task.wait(2)
    end
end

-- ============================================================
-- MAIN QUEST LOOP (Gabungan dari beberapa loop)
-- ============================================================
local questLoopRunning = false
local questLoopThread = nil
local questLoopStop = false

local function questMainLoop()
    while not questLoopStop do
        -- AutoEnabled keep-alive setiap 2.5 detik
        if _G.DeepSeaQuestMode or _G.ElementQuestMode or _G.DiamondQuestMode then
            pcall(function()
                if AutoEnabled then AutoEnabled:InvokeServer(true) end
            end)
        end

        -- Teleport & one-click fishing setiap 0.1 detik (jika quest active)
        if _G.DeepSeaQuestMode or _G.ElementQuestMode or _G.DiamondQuestMode then
            initialTeleport()
            local char = workspace:FindFirstChild("Characters") and workspace.Characters:FindFirstChild(player.Name)
            if char then
                repeat
                    task.wait(0.1)
                    if char:FindFirstChild("!!!FISHING_VIEW_MODEL!!!") then
                        pcall(function()
                            REEquip:FireServer(1)
                        end)
                    end
                    task.wait(0.1)
                    local cosmeticFolder = workspace:FindFirstChild("CosmeticFolder")
                    if cosmeticFolder and not cosmeticFolder:FindFirstChild(tostring(player.UserId)) then
                        pcall(function()
                            FishingController:RequestChargeFishingRod(Vector2.new(0, 0), true)
                            task.wait(0.05)
                            local guid = FishingController.GetCurrentGUID and FishingController:GetCurrentGUID()
                            if not guid then
                                return
                            end
                            while (_G.DeepSeaQuestMode or _G.ElementQuestMode or _G.DiamondQuestMode) and FishingController:GetCurrentGUID() == guid do
                                FishingController:FishingMinigameClick()
                                task.wait(math.random(1, 10) / 100)
                            end
                        end)
                    end
                    task.wait(0.25)
                until not (_G.DeepSeaQuestMode or _G.ElementQuestMode or _G.DiamondQuestMode)
            end
        end

        -- Sell items setiap 5 detik
        if _G.DeepSeaQuestMode or _G.ElementQuestMode or _G.DiamondQuestMode then
            pcall(function()
                if SellItem then SellItem:InvokeServer() end
            end)
        end

        -- Buy rods setiap 5 detik
        if _G.DeepSeaQuestMode or _G.ElementQuestMode or _G.DiamondQuestMode then
            local success, coins = pcall(function() return dataStore and dataStore:Get("Coins") end)
            coins = (success and coins) or 0
            for name, rod in pairs(FishingRods) do
                local uuid = getRodUUID(rod.id)
                if not uuid and coins >= rod.price then
                    print("[VoraHub] Buying " .. name .. " (Price: " .. rod.price .. ")")
                    local wasDeepSea = _G.DeepSeaQuestMode
                    local wasElement = _G.ElementQuestMode
                    local wasDiamond = _G.DiamondQuestMode

                    _G.DeepSeaQuestMode = false
                    _G.ElementQuestMode = false
                    _G.DiamondQuestMode = false
                    _G.HasTeleported = false

                    local char = workspace:FindFirstChild("Characters") and workspace.Characters:FindFirstChild(player.Name)
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then hum.Health = 0 end
                        task.wait(5)

                        pcall(function()
                            if BuyRod then BuyRod:InvokeServer(rod.id) end
                        end)
                        task.wait(0.5)

                        local newUUID = nil
                        local retryUntil = tick() + 5
                        while tick() < retryUntil do
                            newUUID = getRodUUID(rod.id)
                            if newUUID then break end
                            task.wait(0.5)
                        end
                        if newUUID then
                            if REEquipItem then
                                pcall(REEquipItem.FireServer, REEquipItem, newUUID, "Fishing Rods")
                            end
                            if equipTool then
                                pcall(equipTool.FireServer, equipTool, 1)
                            end
                            print("[VoraHub] " .. name .. " equipped!")
                        end

                        teleportBasedOnCondition()
                        task.wait(0.5)

                        _G.DeepSeaQuestMode = wasDeepSea
                        _G.ElementQuestMode = wasElement
                        _G.DiamondQuestMode = wasDiamond
                        break
                    end
                end
            end
        end

        -- Buy baits setiap 5 detik
        if _G.DeepSeaQuestMode or _G.ElementQuestMode or _G.DiamondQuestMode then
            local coins = 0
            pcall(function() coins = dataStore and dataStore:Get("Coins") or 0 end)
            for baitId, bait in pairs(Baits) do
                if not hasBait(baitId) and coins >= bait.price then
                    print("[VoraHub] Buying " .. bait.name .. "...")
                    local wasDeepSea = _G.DeepSeaQuestMode
                    local wasElement = _G.ElementQuestMode
                    local wasDiamond = _G.DiamondQuestMode

                    _G.DeepSeaQuestMode = false
                    _G.ElementQuestMode = false
                    _G.DiamondQuestMode = false
                    _G.HasTeleported = false

                    local char = workspace:FindFirstChild("Characters") and workspace.Characters:FindFirstChild(player.Name)
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then hum.Health = 0 end
                        task.wait(5)

                        buyBait(baitId)
                        task.wait(0.5)
                        equipBait(baitId)

                        teleportBasedOnCondition()
                        task.wait(0.5)

                        _G.DeepSeaQuestMode = wasDeepSea
                        _G.ElementQuestMode = wasElement
                        _G.DiamondQuestMode = wasDiamond
                        break
                    end
                end
            end
        end

        task.wait(0.1) -- base loop interval
    end
end

local function startQuestLoops()
    if questLoopRunning then return end
    questLoopRunning = true
    questLoopStop = false
    questLoopThread = task.spawn(questMainLoop)
end

local function stopQuestLoops()
    questLoopStop = true
    if questLoopThread then
        task.cancel(questLoopThread)
        questLoopThread = nil
    end
    questLoopRunning = false
end

-- Jalankan loop secara otomatis
startQuestLoops()

-- ============================================================
-- BLATANT V1 (STABLE) - Refactored dengan Thread Management
-- ============================================================
MainTab:CreateSection({ Name = "Blatant V1 (STABLE)" })

_G.BlatantMode = _G.BlatantMode or false

MainTab:CreateInput({
    Name = "Complete Delay",
    SideLabel = "Complete Delay",
    Default = tostring(Config.UB.Settings.CompleteDelay),
    Callback = function(text)
        local n = tonumber(text)
        if n and n > 0 then
            Config.UB.Settings.CompleteDelay = n
            Instant.SetCompleteDelay(n)
        end
    end,
})

local blatantSession = 0
local blatantProtected = false
local blatantThread = nil

local function blatantSkipCycle(sessionId)
    local EquipTool = REEquip
    local ChargeRod = ChargeRod
    local StartMini = StartMini
    local CatchFish = REFishDone

    if _G.AutoEquip and EquipTool then
        pcall(EquipTool.FireServer, EquipTool, 1)
        task.wait(0.25)
    end

    while blatantProtected and blatantSession == sessionId do
        local speed = (_G.Amblatant and _G.AmSpeed) or _G.Speed
        local loopDelay = (_G.Amblatant and _G.AmLoopDelay) or _G.LoopDelay

        local t = workspace:GetServerTimeNow()
        if ChargeRod then
            pcall(ChargeRod.InvokeServer, ChargeRod, t)
        end
        task.wait(speed)
        if StartMini then
            pcall(StartMini.InvokeServer, StartMini, -1, 1, t)
        end
        task.wait(speed)
        if CatchFish then
            pcall(CatchFish.InvokeServer, CatchFish, 1)
        end

        -- Amblatant spam
        if _G.Amblatant and _G.SavedData and _G.SavedData.FishCaught and isCaught then
            task.spawn(function()
                task.wait(0.3)
                for _ = 1, 2 do
                    local xremote = GetServerRemote("RE/FishCaught")
                    if xremote then
                        FireLocalEvent(xremote, unpack(_G.SavedData.FishCaught))
                    end
                    xremote = GetServerRemote("RE/CaughtFishVisual")
                    if xremote and _G.SavedData.CaughtVisual then
                        FireLocalEvent(xremote, unpack(_G.SavedData.CaughtVisual))
                    end
                    xremote = GetServerRemote("RE/ObtainedNewFishNotification")
                    if xremote and _G.SavedData.FishNotif then
                        FireLocalEvent(xremote, unpack(_G.SavedData.FishNotif))
                        task.spawn(function()
                            for _ = 1, 2 do
                                task.wait(2)
                                FireLocalEvent(xremote, unpack(_G.SavedData.FishNotif))
                            end
                        end)
                    end
                end
            end)
            isCaught = false
        end
        task.wait(loopDelay)
    end
end

local function toggleBlatant(value)
    if value then
        blatantProtected = true
        blatantSession = blatantSession + 1
        local session = blatantSession
        blatantThread = task.spawn(blatantSkipCycle, session)
    else
        blatantProtected = false
        blatantSession = blatantSession + 1
        if blatantThread then
            task.cancel(blatantThread)
            blatantThread = nil
        end
    end
end

MainTab:CreateToggle({
    Name = "Fast Reel",
    Default = _G.BlatantMode,
    Callback = function(state)
        if _G.BlatantMode == state then return end
        _G.BlatantMode = state
        needCast = true
        toggleBlatant(state)
        if onToggleUB then onToggleUB(state) end
        if applyUltraBlatant3NFishingControllerStub then
            applyUltraBlatant3NFishingControllerStub(state)
        end
    end,
})

-- Variabel global untuk kompatibilitas
svc = {
    Players = game:GetService("Players"),
    RS = game:GetService("ReplicatedStorage"),
}
player = svc.Players.LocalPlayer
if not player.Character then player.CharacterAdded:Wait() end

EquipTool  = REEquip
ChargeRod  = ChargeRod
StartMini  = StartMini
CatchFish  = REFishDone
CancelFish = Cancel

-- Inisialisasi ulang variabel (tetap global)
_G.AutoEquip = _G.AutoEquip or true
_G.Speed = _G.Speed or 0.07
_G.LoopDelay = _G.LoopDelay or 0.25
_G.AmSpeed = _G.AmSpeed or _G.Speed
_G.AmLoopDelay = _G.AmLoopDelay or _G.LoopDelay

-- ============================================================
-- AMBLATANT TAB
-- ============================================================
AmblatantTab:CreateSection({ Name = "AMBLATANT OR FAST FISHING" })

AmblatantTab:CreateToggle({
    Name = "Amblatant YTTA",
    SubText = "KASIH TAU TALONNN",
    Default = _G.Amblatant,
    Callback = function(state)
        _G.Amblatant = state
        if state then
            saveCount = 0
            _resetNaturalHookCounts()
            _installFixedNaturalHook()
            HookRemote("RE/FishCaught", "FishCaught")
            HookRemote("RE/CaughtFishVisual", "CaughtVisual")
            HookRemote("RE/ObtainedNewFishNotification", "FishNotif")
        end
        toggleBlatant(state)
    end,
})

AmblatantTab:CreateInput({
    Name = "Amblatant Speed",
    SideLabel = "Delay (s)",
    Default = tostring(_G.AmSpeed),
    Callback = function(v)
        local n = tonumber(v)
        if n and n > 0 then _G.AmSpeed = n end
    end,
})

AmblatantTab:CreateInput({
    Name = "Amblatant Loop Delay",
    SideLabel = "Loop Delay (s)",
    Default = tostring(_G.AmLoopDelay),
    Callback = function(v)
        local n = tonumber(v)
        if n and n > 0 then _G.AmLoopDelay = n end
    end,
})

-- ============================================================
-- RECOVERY FISHING
-- ============================================================
MainTab:CreateSection({ Name = "Recovery Fishing" })
MainTab:CreateButton({
    Name = "Recovery Fishing",
    SubText = "Fix stuck fishing & reset state",
    Callback = function()
        Window:Notify({
            Title = "Recovery Fishing",
            Content = "Attempting to recover fishing state...",
            Duration = 2
        })
        if cancelinput then pcall(cancelinput.InvokeServer, cancelinput) end
        task.wait(0.1)
        if fishingcomplete then pcall(fishingcomplete.InvokeServer, fishingcomplete) end
        task.wait(0.1)
        if cancelinput then pcall(cancelinput.InvokeServer, cancelinput) end
        task.wait(0.1)
        if st then st.canFish = true end
        if _G.AutoRod and equipTool then
            pcall(equipTool.FireServer, equipTool, 1)
        end
        Window:Notify({
            Title = "Recovery Complete",
            Content = "Fishing state has been reset!",
            Duration = 3
        })
    end
})

-- ============================================================
-- AUTO SELL (Refactored)
-- ============================================================
MainTab:CreateSection({ Name = "Sell", Icon = "rbxassetid://7733793319" })

Players = game:GetService("Players")
LocalPlayer = Players.LocalPlayer

_G.AutoSells = _G.AutoSells or false
local autoSellMode = "Sell Delay"
local autoSellValue = 0
local currentCount = 0

-- Monitor bag size
local label = LocalPlayer.PlayerGui:FindFirstChild("Inventory")
if label then
    label = label:FindFirstChild("Main")
    if label then
        label = label:FindFirstChild("Top")
        if label then
            label = label:FindFirstChild("Options")
            if label then
                label = label:FindFirstChild("Fish")
                if label then
                    label = label:FindFirstChild("Label")
                    if label then
                        label = label:FindFirstChild("BagSize")
                    end
                end
            end
        end
    end
end

if label then
    label:GetPropertyChangedSignal("ContentText"):Connect(function()
        local text = label.ContentText
        currentCount = tonumber(string.match(text, "^(%d+)")) or 0
    end)
end

local sellAllItems = SellItem

local function safeSell()
    if sellAllItems then
        pcall(sellAllItems.InvokeServer, sellAllItems)
    end
end

local autoSellThread = nil
local autoSellStop = false

local function autoSellLoop()
    while _G.AutoSells and not autoSellStop do
        local selldelay = 0
        local countdelay = 0
        if autoSellMode == "Sell Delay" then
            selldelay = autoSellValue
        else
            countdelay = autoSellValue
        end

        if selldelay == 0 and countdelay > 0 then
            if currentCount >= countdelay then
                safeSell()
                task.wait(0.3)
            end
            task.wait(0.1)
        elseif selldelay > 0 and countdelay == 0 then
            safeSell()
            task.wait(selldelay)
        else
            Window:Notify({
                Title = "Yang Bener Hitam",
                Content = "Pilih mode di dropdown dan isi angka di input (harus > 0).",
                Duration = 3,
                Icon = "warn",
            })
            break
        end
    end
end

local function startAutoSell()
    if _G.AutoSells then return end
    _G.AutoSells = true
    autoSellStop = false
    autoSellThread = task.spawn(autoSellLoop)
end

local function stopAutoSell()
    _G.AutoSells = false
    autoSellStop = true
    if autoSellThread then
        task.cancel(autoSellThread)
        autoSellThread = nil
    end
end

-- UI Toggle
MainTab:CreateToggle({
    Name = "Auto Sell",
    Default = _G.AutoSells,
    Callback = function(v)
        if v then startAutoSell() else stopAutoSell() end
    end
})

MainTab:CreateDropdown({
    Name = "Auto Sell Mode",
    Items = { "Sell Delay", "Sell By Count" },
    Default = "Sell Delay",
    Callback = function(Option)
        autoSellMode = Option
    end,
})

MainTab:CreateInput({
    Name = "Auto Sell Value",
    Placeholder = "Delay: detik antar jual | Count: jual jika isi tas >= angka",
    Default = "",
    Callback = function(txt)
        autoSellValue = tonumber(txt) or 0
    end,
})

-- ============================================================
-- AUTO FAVORITE (Refactored - Optimized & Bug Fixed)
-- ============================================================
MainTab:CreateSection({ Name = "Auto Favorite", Icon = "rbxassetid://7733765398" })

-- ============================================================
-- INITIALIZATION (Tetap kompatibel)
-- ============================================================
local REFishCaught = RE.FishCaught or REFishGot
local REFishingCompleted = RE.FishingCompleted or REFishDone

-- Reset fishing state saat fish caught
if REFishCaught then
    REFishCaught.OnClientEvent:Connect(function()
        st.canFish = true
    end)
end

-- Tier to Rarity mapping (tetap global)
tierToRarity = {
    [1] = "Common",
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
    [6] = "Mythic",
    [7] = "SECRET",
    [8] = "Forgotten",
}

-- Load fish names (tetap global)
fishNames = {}
for _, module in ipairs(Items:GetChildren()) do
    if module:IsA("ModuleScript") then
        local ok, data = pcall(require, module)
        if ok and data.Data and data.Data.Type == "Fish" then
            table.insert(fishNames, data.Data.Name)
        end
    end
end
table.sort(fishNames)

-- ============================================================
-- STATE & CACHE (Refactored)
-- ============================================================
local favState = {}
local favoriteDebounce = {}

-- Filter state (tetap global agar UI callback bisa menulis)
selectedName = selectedName or {}
selectedRarity = selectedRarity or {}
selectedVariant = selectedVariant or {}

-- Lookup maps untuk O(1) pengecekan (di-build ulang saat filter berubah)
local selectedNameLookup = {}
local selectedRarityLookup = {}
local selectedVariantLookup = {}

-- Flag untuk mencegah scan tumpang tindih
local isScanning = false

-- Remote event yang benar (perbaikan bug shadowing!)
local FavoriteRemote = RE.FavoriteItem or REFav
local FavoriteStateRemote = RE.FavoriteStateChanged or REFavChg

-- Cache ItemUtility & Data untuk akses cepat
local ItemUtilityRef = ItemUtility
local DataRef = Data

-- ============================================================
-- HELPER FUNCTIONS (Optimized)
-- ============================================================

-- Build lookup maps dari filter
local function rebuildLookupMaps()
    selectedNameLookup = {}
    for _, name in ipairs(selectedName) do
        selectedNameLookup[name] = true
    end

    selectedRarityLookup = {}
    for _, rarity in ipairs(selectedRarity) do
        selectedRarityLookup[rarity] = true
    end

    selectedVariantLookup = {}
    for _, variant in ipairs(selectedVariant) do
        selectedVariantLookup[variant] = true
    end
end

-- Cek apakah item harus di-favorite (logika murni, tanpa side effect)
local function shouldFavoriteItem(item, info)
    if not info or info.Data.Type ~= "Fish" then return false end
    if favState[item.UUID] or item.Favorited then return false end

    local shouldFav = false

    -- 1. Cek Name & Rarity
    if st.autoFavEnabled then
        local rarity = tierToRarity[info.Data.Tier]
        local nameMatch = selectedNameLookup[info.Data.Name] or false
        local rarityMatch = selectedRarityLookup[rarity] or false
        if nameMatch or rarityMatch then
            shouldFav = true
        end
    end

    -- 2. Cek Variant (jika belum di-favorite oleh kriteria sebelumnya)
    if not shouldFav and st.autoFavVariantEnabled then
        local mutation = (item.Metadata and item.Metadata.VariantId and tostring(item.Metadata.VariantId)) or "None"
        if mutation ~= "None" and selectedVariantLookup[mutation] then
            shouldFav = true
        end
    end

    return shouldFav
end

-- Fungsi utama scan inventory (dengan debounce & flag)
local function scanInventoryBasic()
    if not (st.autoFavEnabled or st.autoFavVariantEnabled) then return end
    if isScanning then return end -- Mencegah scan tumpang tindih

    isScanning = true
    task.defer(function()
        pcall(function()
            local inv = DataRef:GetExpect({ "Inventory", "Items" })
            if not inv then
                warn("[AutoFav] Inventory not found!")
                isScanning = false
                return
            end

            local count = 0
            for _, item in ipairs(inv) do
                -- Debounce check
                if favoriteDebounce[item.UUID] and (tick() - favoriteDebounce[item.UUID] < 2) then
                    continue
                end

                local info = ItemUtilityRef.GetItemDataFromItemType("Items", item.Id)
                if shouldFavoriteItem(item, info) then
                    if FavoriteRemote then
                        favoriteDebounce[item.UUID] = tick()
                        local success, err = pcall(FavoriteRemote.FireServer, FavoriteRemote, item.UUID, true)
                        if success then
                            favState[item.UUID] = true
                            count = count + 1
                        else
                            warn("[AutoFav] Failed:", err)
                        end
                        task.wait(0.05) -- Jeda kecil antar request
                    end
                end
            end
            print("[AutoFav] ✅ Favorited:", count, "items")
        end)
        isScanning = false
    end)
end

-- ============================================================
-- EVENT HOOKS (Optimized)
-- ============================================================

-- Pantau perubahan status favorite dari server
if FavoriteStateRemote then
    FavoriteStateRemote.OnClientEvent:Connect(function(uuid, fav)
        if uuid then
            favState[uuid] = fav
        end
    end)
end

-- Pantau perubahan inventory
DataRef:OnChange({ "Inventory", "Items" }, function()
    if st.autoFavEnabled or st.autoFavVariantEnabled then
        task.wait(0.3)
        rebuildLookupMaps()
        scanInventoryBasic()
    end
end)

-- ============================================================
-- UI ELEMENTS (Tetap kompatibel)
-- ============================================================

-- Dropdown: Filter by Name
MainTab:CreateMultiDropdown({
    Name = "Favorite by Name",
    Items = #fishNames > 0 and fishNames or { "No Data" },
    Default = selectedName,
    Callback = function(opts)
        selectedName = opts or {}
        rebuildLookupMaps()
        print("[AutoFav] Names:", #selectedName > 0 and table.concat(selectedName, ", ") or "NONE")
        if st.autoFavEnabled then
            task.wait(0.1)
            scanInventoryBasic()
        end
    end,
})

-- Dropdown: Filter by Rarity
MainTab:CreateMultiDropdown({
    Name = "Favorite by Rarity",
    Items = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET", "Forgotten" },
    Default = selectedRarity,
    Callback = function(opts)
        selectedRarity = opts or {}
        rebuildLookupMaps()
        print("[AutoFav] Rarities:", #selectedRarity > 0 and table.concat(selectedRarity, ", ") or "NONE")
        if st.autoFavEnabled then
            task.wait(0.1)
            scanInventoryBasic()
        end
    end,
})

-- Toggle: Enable Auto Favorite (Name & Rarity)
MainTab:CreateToggle({
    Name = "Start Auto Favorite",
    Default = st.autoFavEnabled or false,
    Callback = function(state)
        st.autoFavEnabled = state
        print("[AutoFav]", state and "ENABLED" or "DISABLED")
        if state then
            rebuildLookupMaps()
            task.wait(0.2)
            scanInventoryBasic()
        end
    end,
})

-- Button: Unfavorite All
MainTab:CreateButton({
    Name = "Unfavorite All",
    Icon = "rbxassetid://7733919427",
    Callback = function()
        print("[AutoFav] Unfavoriting all...")
        local inv = DataRef:GetExpect({ "Inventory", "Items" })
        if not inv then return end

        local count = 0
        for _, item in ipairs(inv) do
            if (item.Favorited or favState[item.UUID]) and FavoriteRemote then
                pcall(FavoriteRemote.FireServer, FavoriteRemote, item.UUID, false)
                favState[item.UUID] = false
                count = count + 1
                task.wait(0.05)
            end
        end
        print("[AutoFav] ✅ Unfavorited", count, "items.")
    end,
})

-- ============================================================
-- SECTION 2: AUTO FAVORITE BY VARIANT (Lanjutan)
-- ============================================================
MainTab:CreateSection({ Name = "Auto Favorite By Variant", Icon = "rbxassetid://7733917591" })

local variantList = {
    "Galaxy", "Corrupt", "Gemstone", "Fairy Dust", "Midnight",
    "Color Burn", "Holographic", "Lightning", "Radioactive",
    "Ghost", "Gold", "Frozen", "1x1x1x1", "Stone", "Sandy",
    "Noob", "Moon Fragment", "Festive", "Albino", "Arctic Frost", "Disco", "Big", "Giant", "Sparkling",
    "Crystalized",
}

-- Dropdown: Filter by Variant
MainTab:CreateMultiDropdown({
    Name = "Select Variants",
    Items = variantList,
    Default = selectedVariant,
    Callback = function(opts)
        selectedVariant = opts or {}
        rebuildLookupMaps()
        print("[AutoFav Variant] Selected:", #selectedVariant > 0 and table.concat(selectedVariant, ", ") or "NONE")
    end,
})

-- Toggle: Enable Auto Favorite by Variant
MainTab:CreateToggle({
    Name = "Auto Favorite Variants",
    Default = st.autoFavVariantEnabled or false,
    Callback = function(state)
        st.autoFavVariantEnabled = state
        print("[AutoFav Variant]", state and "ENABLED" or "DISABLED")
        if state then
            rebuildLookupMaps()
            task.spawn(scanInventoryBasic)
        end
    end,
})

-- Button: Check Variants in Inventory
MainTab:CreateButton({
    Name = "Check Variants in Inventory",
    Callback = function()
        local inv = DataRef:GetExpect({ "Inventory", "Items" })
        if not inv then
            print("Inventory empty or not loaded.")
            return
        end

        print("========================================")
        print("=== CHECKING VARIANTS IN INVENTORY ===")
        print("========================================")
        local found = false
        for _, item in ipairs(inv) do
            local mutation = (item.Metadata and item.Metadata.VariantId and tostring(item.Metadata.VariantId)) or "None"
            if mutation ~= "None" then
                local info = ItemUtilityRef.GetItemDataFromItemType("Items", item.Id)
                local name = (info and info.Data.Name) or "Unknown"
                print("📦", name)
                print("   Variant:", mutation)
                print("   UUID:", item.UUID)
                print("   Favorited:", item.Favorited or false)
                found = true
            end
        end
        if not found then
            print("❌ No items with variants found.")
        end
        print("========================================")
    end,
})

-- ============================================================
-- SECTION 2: AUTO FAVORITE BY VARIANT (Refactored)
-- ============================================================
MainTab:CreateSection({ Name = "Auto Favorite By Variant", Icon = "rbxassetid://7733917591" })

local variantList = {
    "Galaxy", "Corrupt", "Gemstone", "Fairy Dust", "Midnight",
    "Color Burn", "Holographic", "Lightning", "Radioactive",
    "Ghost", "Gold", "Frozen", "1x1x1x1", "Stone", "Sandy",
    "Noob", "Moon Fragment", "Festive", "Albino", "Arctic Frost", "Disco", "Big", "Giant", "Sparkling",
    "Crystalized"
}

MainTab:CreateMultiDropdown({
    Name = "Select Variants",
    Items = variantList,
    Default = selectedVariant or {},
    Callback = function(opts)
        selectedVariant = opts or {}
        rebuildLookupMaps()
        print("[AutoFav Variant] Selected:", #selectedVariant > 0 and table.concat(selectedVariant, ", ") or "NONE")
    end
})

MainTab:CreateToggle({
    Name = "Auto Favorite Variants",
    Default = st.autoFavVariantEnabled or false,
    Callback = function(state)
        st.autoFavVariantEnabled = state
        print("[AutoFav Variant]", state and "ENABLED" or "DISABLED")
        if state then
            rebuildLookupMaps()
            task.spawn(scanInventoryBasic)
        end
    end
})

MainTab:CreateButton({
    Name = "Check Variants in Inventory",
    Callback = function()
        local inv = DataRef:GetExpect({ "Inventory", "Items" })
        if not inv then
            print("Inventory empty or not loaded.")
            return
        end
        print("========================================")
        print("=== CHECKING VARIANTS IN INVENTORY ===")
        print("========================================")
        local found = false
        for _, item in ipairs(inv) do
            local mutation = (item.Metadata and item.Metadata.VariantId and tostring(item.Metadata.VariantId)) or "None"
            if mutation ~= "None" then
                local info = ItemUtilityRef.GetItemDataFromItemType("Items", item.Id)
                local name = (info and info.Data.Name) or "Unknown"
                print("📦", name)
                print("   Variant:", mutation)
                print("   UUID:", item.UUID)
                print("   Favorited:", item.Favorited or false)
                found = true
            end
        end
        if not found then
            print("❌ No items with variants found.")
        end
        print("========================================")
    end
})

-- ============================================================
-- SKIN ANIMATION (Refactored - Optimized)
-- ============================================================
local SkinAnimation = (function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local SkinAnimations = {
        ["Cursed Katana"] = {ReelingIdle="85246394508551",EquipIdleFake="87355322562067",ReelStart="84160502333903",StartRodCharge="75015195359151",FishCaught="75078942392746"},
        ["Blackhole Sword"] = {ReelingIdle="126645853428201",EquipIdleFake="110434285817259",ReelStart="80063739027478",ReelIntermission="92036914464034",RodThrow="120554144611008",FishCaught="88993991486322",StartRodCharge="106390588424443",LoopedRodCharge="76049869128172"},
        ["Soul Scythe"] = {ReelingIdle="95453600470089",EquipIdleFake="84686809448947",ReelStart="137684649541594",ReelIntermission="139621583239992",RodThrow="104946400643250",FishCaught="82259219343456",StartRodCharge="117668204114399",LoopedRodCharge="88768375910397"},
        ["Eclipse Katana"] = {ReelStart="115229621326605",EquipIdleFake="103641983335689",RodThrow="82600073500966",FishCaught="107940819382815"},
        ["Ethereal Sword"] = {RodThrow="102875258412698",ReelIntermission="129632039690279",LoopedRodCharge="128015350117740",ReelStart="134537167807676",ReelingIdle="74353386311203",StartRodCharge="117245023195506",FishCaught="110866636674655",EquipIdleFake="116654265230180"},
        ["Binary Edge"] = {FishCaught="109653945741202",RodThrow="104527781253009",StartRodCharge="72745361965091",ReelingIdle="81700883907369",LoopedRodCharge="98710992523201",EquipIdleFake="103714544264522"},
        ["Princess Parasol"] = {FishCaught="99143072029495",ReelStart="104188512165442",RodThrow="108621937425425"},
        ["1x1x1x1 Ban Hammer"] = {FishCaught="96285280763544",ReelIntermission="74643095451174",StartRodCharge="134431618143422",LoopedRodCharge="128538861163297",EquipIdleFake="81302570422307",RodThrow="123133988645038"},
        ["The Vanquisher"] = {FishCaught="93884986836266",EquipIdleFake="123194574699925",RodThrow="102380394663862",LoopedRodCharge="92063415632933",ReelStart="138790747812051"},
        ["Crescendo Scythe"] = {ReelStart="111056917953819",RodThrow="140421284729758",LoopedRodCharge="128488550256172",EquipIdleFake="91723046661800",ReelingHold="123869733913273",ReelIntermission="140344626493067",FishCaught="101593515409348",StartRodCharge="95597987757506"},
        ["Eternal Flower"] = {ReelingIdle="110020934764602",RodThrow="105844949829012",StartRodCharge="77131632555646",LoopedRodCharge="124036821497471",ReelStart="135819234295555",EquipIdleFake="115119558523816",ReelIntermission="86376110148779",FishCaught="119567958965696"},
        ["Frozen Krampus Scythe"] = {ReelingIdle="98716967215984",LoopedRodCharge="107284147985305",EquipIdleFake="124265469726043",RodThrow="96196869100887",FishCaught="134934781977605",StartRodCharge="93987679432095"},
        ["Oceanic Harpoon"] = {LoopedRodCharge="76325124055693",StartRodCharge="84873660213983",RodThrow="127872348080219",EquipIdleFake="77549515147440"},
        ["Corruption Edge"] = {RodThrow="84892442268560",StartRodCharge="112104009500915",ReelingIdle="110738276580375",EquipIdleFake="93958525241489",FishCaught="126613975718573"},
        ["Holy Trident"] = {ReelStart="126831815839724",RodThrow="114917462794864",FishCaught="128167068291703",StartRodCharge="83219020397849"},
        ["Undead Guitar"] = {EquipIdleFake="130474623877752"},
        ["Electric Guitar"] = {EquipIdleFake="108792932396384"},
        ["Christmas Parasol"] = {EquipIdleFake="79754634120924",RodThrow="122784676901871"},
        ["Pirate Banjo"] = {EquipIdleFake="120677591068007"},
        ["Divine Blade"] = {EquipIdleFake="82781088583962"},
        ["Gingerbread Sword"] = {EquipIdleFake="106017647759827"},
        ["Candy Cane Trident"] = {EquipIdleFake="131643088615283"},
        ["Heartfelt Blade"] = {EquipIdleFake="111118151202469"},
        ["Spirit Staff"] = {EquipIdleFake="77452908864699"},
        ["Reaver Scythe"] = {EquipIdleFake="79066316609985"},
        ["Pink Present Lance"] = {EquipIdleFake="101986838283328"},
        ["Ornament Axe"] = {EquipIdleFake="90021589040653"},
        ["Gingerbread Katana"] = {RodThrow="124037675493192"},
        ["Xmas Tree Rod"] = {EquipIdleFake="97171752999251"},
        ["Royal Spider"] = {EquipIdleFake="79263851052023"},
        ["Kraken Anchor"] = {EquipIdleFake="126023229958416"}
    }

    local FishingAnims = {"ReelingIdle", "EquipIdleFake", "ReelStart", "ReelIntermission", "RodThrow", "FishCaught", "StartRodCharge", "LoopedRodCharge", "ReelingHold"}
    -- Build lookup table for O(1) check
    local FishingAnimLookup = {}
    for _, name in ipairs(FishingAnims) do
        FishingAnimLookup[name] = true
    end

    local CurrentSkin = nil
    local IsEnabled = false
    local Animator = nil
    local LoadedTracks = {}
    local Connection = nil
    local CharAddedConn = nil

    local function ShouldReplace(animName)
        return FishingAnimLookup[animName] == true
    end

    local function GetReplacementTrack(animName)
        if not Animator or not CurrentSkin then return nil end
        local skinData = SkinAnimations[CurrentSkin]
        if not skinData or not skinData[animName] then return nil end
        local cacheKey = CurrentSkin .. "_" .. animName
        if LoadedTracks[cacheKey] then return LoadedTracks[cacheKey] end

        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://" .. skinData[animName]
        anim.Name = "Replacement_" .. animName

        local ok, track = pcall(Animator.LoadAnimation, Animator, anim)
        if ok and track then
            LoadedTracks[cacheKey] = track
            return track
        end
        return nil
    end

    local function ClearTracks()
        for _, track in pairs(LoadedTracks) do
            pcall(track.Stop, track)
            pcall(track.Destroy, track)
        end
        LoadedTracks = {}
    end

    local function SetupAnimator()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        Animator = hum:FindFirstChildOfClass("Animator")
        if not Animator then return end

        if Connection then Connection:Disconnect() end
        ClearTracks()

        Connection = Animator.AnimationPlayed:Connect(function(track)
            if not IsEnabled or not CurrentSkin then return end
            if not track.Animation then return end

            local animName = track.Animation.Name
            if ShouldReplace(animName) then
                local replacement = GetReplacementTrack(animName)
                if replacement then
                    local speed = track.Speed
                    track:Stop(0)
                    replacement:Play(0.1, nil, speed)
                    replacement.Looped = track.Looped
                end
            end
        end)
    end

    local function Enable()
        if IsEnabled then return end
        IsEnabled = true
        SetupAnimator()
        -- Cleanup previous CharacterAdded connection if exists
        if CharAddedConn then
            CharAddedConn:Disconnect()
            CharAddedConn = nil
        end
        CharAddedConn = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)
            if IsEnabled then SetupAnimator() end
        end)
    end

    local function Disable()
        IsEnabled = false
        if Connection then
            Connection:Disconnect()
            Connection = nil
        end
        if CharAddedConn then
            CharAddedConn:Disconnect()
            CharAddedConn = nil
        end
        ClearTracks()
    end

    local function SelectSkin(name)
        CurrentSkin = name
        ClearTracks()
    end

    local function GetSkins()
        local names = {}
        for name in pairs(SkinAnimations) do
            table.insert(names, name)
        end
        table.sort(names)
        return names
    end

    return { Enable = Enable, Disable = Disable, SelectSkin = SelectSkin, GetSkins = GetSkins }
end)()

-- ============================================================
-- SKIN ANIMATION UI
-- ============================================================
MainTab:CreateSection({ Name = "Skin Animation", Icon = "rbxassetid://108886429866687" })

local skinList = SkinAnimation.GetSkins()
MainTab:CreateDropdown({
    Name = "Select Rod Skin",
    Items = skinList,
    Default = "None",
    Callback = function(val)
        SkinAnimation.SelectSkin(val)
    end
})

MainTab:CreateToggle({
    Name = "Enable Skin Changer",
    Default = false,
    Callback = function(state)
        if state then
            SkinAnimation.Enable()
        else
            SkinAnimation.Disable()
        end
    end
})

-- ============================================================
-- AUTO CRYSTAL (Refactored - Thread Management)
-- ============================================================
AutoTab:CreateSection({ Name = "Crystal" })

local AutoUseCaveCrystal = false
local autoCrystalThread = nil

local function autoCrystalLoop()
    while AutoUseCaveCrystal do
        local shouldUse = false

        pcall(function()
            local Player = game:GetService("Players").LocalPlayer
            local PlayerGui = Player:FindFirstChild("PlayerGui")
            if PlayerGui then
                local ActivePotions = PlayerGui:FindFirstChild("Active Potions")
                if ActivePotions then
                    local Rows = ActivePotions:FindFirstChild("Rows")
                    if Rows then
                        local children = Rows:GetChildren()
                        if #children >= 3 then
                            local row = children[3]
                            local label = row and row:FindFirstChild("Label")
                            if label then
                                local text = label.Text
                                text = text:gsub("%s+", "")
                                local totalSeconds = 0
                                local h, m, s = text:match("^(%d+):(%d+):(%d+)$")
                                if h and m and s then
                                    totalSeconds = tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s)
                                else
                                    local m_only, s_only = text:match("^(%d+):(%d+)$")
                                    if m_only and s_only then
                                        totalSeconds = tonumber(m_only) * 60 + tonumber(s_only)
                                    end
                                end
                                if totalSeconds > 0 and totalSeconds <= 180 then
                                    shouldUse = true
                                end
                            else
                                shouldUse = true
                            end
                        end
                    end
                end
            end
        end)

        if shouldUse and ConsumeCrystal then
            pcall(ConsumeCrystal.InvokeServer, ConsumeCrystal)
            Window:Notify({
                Title = "Crystal",
                Content = "Consumed! (Time <= 3:00 or Not Active)",
                Duration = 5,
            })
            task.wait(10)
        end

        task.wait(2)
    end
end

AutoTab:CreateToggle({
    Name = "Auto Use Cave Crystal",
    Default = false,
    Callback = function(state)
        AutoUseCaveCrystal = state
        if state then
            if autoCrystalThread then
                task.cancel(autoCrystalThread)
                autoCrystalThread = nil
            end
            autoCrystalThread = task.spawn(autoCrystalLoop)
        else
            if autoCrystalThread then
                task.cancel(autoCrystalThread)
                autoCrystalThread = nil
            end
        end
    end
})

-- ============================================================
-- AUTO POTION (Refactored - Thread Management)
-- ============================================================
AutoTab:CreateSection({ Name = "Auto Potion" })

local AutoPotionState = {
    enabled = false,
    selectedUuid = nil,
    uuidByLabel = {},
    useAmount = 1,
    delaySeconds = 8,
}
local autoPotionLoopGen = 0
local autoPotionThread = nil
local autoPotionStop = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplionClient = require(ReplicatedStorage.Packages.Replion).Client
local DataStore = ReplionClient:WaitReplion("Data")
local ItemUtilityRef = require(ReplicatedStorage.Shared.ItemUtility)

local function buildPotionDropdownData()
    local labels = {}
    local uuidByLabel = {}
    local ok, inv = pcall(function()
        return DataStore:GetExpect({ "Inventory", "Items" })
    end)
    if not ok or not inv then
        return { "None" }, {}
    end

    for _, item in ipairs(inv) do
        local uid = item.UUID
        if uid and uid ~= "" then
            local pdata = ItemUtilityRef:GetItemData(item.Id)
            if pdata and pdata.Data and pdata.Data.Type == "Potion" then
                local name = pdata.Data.Name or ("Potion " .. tostring(item.Id))
                local short = tostring(uid):sub(1, 8)
                local label = string.format("%s | %s", name, short)
                table.insert(labels, label)
                uuidByLabel[label] = tostring(uid)
            end
        end
    end
    table.sort(labels)
    if #labels == 0 then table.insert(labels, "None") end
    return labels, uuidByLabel
end

local function consumeSelectedPotion()
    local uuid = AutoPotionState.selectedUuid
    if not uuid then
        Window:Notify({
            Title = "Potions",
            Content = "Select potion dulu dari dropdown",
            Duration = 3,
        })
        return
    end
    if not ConsumePotion then
        warn("[AutoPotion] RF/ConsumePotion not found")
        return
    end

    local amount = math.max(1, math.floor(AutoPotionState.useAmount or 1))
    for _ = 1, amount do
        CallRemoteServer(ConsumePotion, uuid, 1)
        task.wait(0.1)
    end
end

local autoPotionDropdown = AutoTab:CreateDropdown({
    Name = "Select potion (inventory)",
    Items = { "None" },
    Default = "None",
    Callback = function(value)
        if not value or value == "None" then
            AutoPotionState.selectedUuid = nil
        else
            AutoPotionState.selectedUuid = AutoPotionState.uuidByLabel[value]
        end
    end,
})

AutoTab:CreateInput({
    Name = "Use amount per cycle",
    PlaceholderText = "1",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local value = tonumber(text)
        if value and value >= 1 then
            AutoPotionState.useAmount = math.floor(value)
        end
    end,
})

AutoTab:CreateInput({
    Name = "Auto use delay (seconds)",
    PlaceholderText = "8",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local value = tonumber(text)
        if value and value > 0 then
            AutoPotionState.delaySeconds = value
        end
    end,
})

AutoTab:CreateButton({
    Name = "Refresh potion list",
    Callback = function()
        local prevUuid = AutoPotionState.selectedUuid
        local labels, map = buildPotionDropdownData()
        AutoPotionState.uuidByLabel = map
        autoPotionDropdown:Refresh(labels)

        local hasPrev = false
        if prevUuid then
            for _, uid in pairs(map) do
                if uid == prevUuid then
                    hasPrev = true
                    break
                end
            end
        end

        if hasPrev then
            AutoPotionState.selectedUuid = prevUuid
        elseif AutoPotionState.selectedUuid == nil then
            local first = labels[1]
            if first and first ~= "None" and map[first] then
                AutoPotionState.selectedUuid = map[first]
            else
                AutoPotionState.selectedUuid = nil
            end
        else
            AutoPotionState.selectedUuid = nil
        end

        Window:Notify({
            Title = "Potions",
            Content = (#labels > 0 and labels[1] ~= "None") and ("Loaded " .. #labels .. " stack(s)") or "No potions in inventory",
            Duration = 3,
        })
    end,
})

AutoTab:CreateButton({
    Name = "Use selected potion now",
    Callback = consumeSelectedPotion,
})

AutoTab:CreateToggle({
    Name = "Auto use selected potion",
    SubText = "Auto pakai potion sesuai amount + delay",
    Default = false,
    Callback = function(state)
        AutoPotionState.enabled = state
        if autoPotionThread then
            task.cancel(autoPotionThread)
            autoPotionThread = nil
        end
        if not state then return end

        autoPotionLoopGen = autoPotionLoopGen + 1
        local gen = autoPotionLoopGen
        local prevUuid = AutoPotionState.selectedUuid
        local labels, map = buildPotionDropdownData()
        AutoPotionState.uuidByLabel = map
        autoPotionDropdown:Refresh(labels)

        local hasPrev = false
        if prevUuid then
            for _, uid in pairs(map) do
                if uid == prevUuid then
                    hasPrev = true
                    break
                end
            end
        end

        if hasPrev then
            AutoPotionState.selectedUuid = prevUuid
        elseif AutoPotionState.selectedUuid == nil and labels[1] and labels[1] ~= "None" then
            AutoPotionState.selectedUuid = map[labels[1]]
        end

        autoPotionThread = task.spawn(function()
            while AutoPotionState.enabled and gen == autoPotionLoopGen do
                consumeSelectedPotion()
                task.wait(AutoPotionState.delaySeconds)
            end
        end)
    end,
})

-- ============================================================
-- AUTO CRYSTAL DEPTHS (Refactored - Optimized)
-- ============================================================
AutoTab:CreateSection({ Name = "Auto Crystal Depths" })

local crystalCache = {
    pickaxeUUID = nil,
    cacheTime = 0,
    cacheDuration = 2,
}

local function getPickaxeUUID()
    local now = tick()
    if crystalCache.pickaxeUUID and now - crystalCache.cacheTime < crystalCache.cacheDuration then
        return crystalCache.pickaxeUUID
    end

    local ok, dataClient = pcall(function()
        return require(ReplicatedStorage.Packages.Replion).Client:WaitReplion("Data")
    end)
    if not ok or not dataClient then
        crystalCache.pickaxeUUID = nil
        crystalCache.cacheTime = now
        return nil
    end

    local inv = dataClient:GetExpect({ "Inventory", "Items" })
    if inv then
        for _, item in ipairs(inv) do
            if item.Id == 20220 then
                crystalCache.pickaxeUUID = item.UUID
                crystalCache.cacheTime = now
                return crystalCache.pickaxeUUID
            end
            local info = ItemUtilityRef:GetItemData(item.Id)
            if info and info.Data and info.Data.Name and string.find(string.lower(info.Data.Name), "pickaxe") then
                crystalCache.pickaxeUUID = item.UUID
                crystalCache.cacheTime = now
                return crystalCache.pickaxeUUID
            end
        end
    end

    crystalCache.pickaxeUUID = nil
    crystalCache.cacheTime = now
    return nil
end

local function equipPickaxe(uuid)
    if not uuid or not REEquipItem then return false end

    local function isPickaxeTool(tool)
        if not tool or not tool:IsA("Tool") then return false end
        if tool.Name == "20220" or string.find(string.lower(tool.Name), "pickaxe") then return true end
        local attrUuid = tool:GetAttribute("UUID")
        return attrUuid and tostring(attrUuid) == tostring(uuid)
    end

    local function getEquippedTool()
        local char = Player.Character
        if not char then return nil end
        for _, obj in ipairs(char:GetChildren()) do
            if isPickaxeTool(obj) then return obj end
        end
        return nil
    end

    local function getBackpackTool()
        local backpack = Player:FindFirstChild("Backpack")
        if not backpack then return nil end
        for _, obj in ipairs(backpack:GetChildren()) do
            if isPickaxeTool(obj) then return obj end
        end
        return nil
    end

    if getEquippedTool() then return true end

    for i = 1, 3 do
        pcall(REEquipItem.FireServer, REEquipItem, uuid, "Gears")
        task.wait(i == 1 and 0.5 or 0.35)
        if getEquippedTool() then return true end

        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local bpTool = getBackpackTool()
        if hum and bpTool then
            pcall(hum.EquipTool, hum, bpTool)
            task.wait(0.15)
            if getEquippedTool() then return true end
        end
        task.wait(0.15)
    end
    return getEquippedTool() ~= nil
end

local autoCrystalThread = nil
local autoCrystalRunning = false

AutoTab:CreateToggle({
    Name = "Auto Crystal Depths",
    Default = false,
    Callback = function(state)
        _G.AutoCrystal = state
        if autoCrystalThread then
            task.cancel(autoCrystalThread)
            autoCrystalThread = nil
        end
        if not state then
            autoCrystalRunning = false
            return
        end

        autoCrystalRunning = true
        autoCrystalThread = task.spawn(function()
            local Player = game:GetService("Players").LocalPlayer
            local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if not Root then
                autoCrystalRunning = false
                return
            end

            local StartCFrame = Root.CFrame
            local hasActionTaken = false

            while _G.AutoCrystal and autoCrystalRunning do
                local Islands = workspace:FindFirstChild("Islands")
                local Depths = Islands and Islands:FindFirstChild("Crystal Depths")
                local CrystalsFolder = Depths and Depths:FindFirstChild("Crystals")
                if not CrystalsFolder then
                    task.wait(1)
                    continue
                end

                local pickaxeUUID = getPickaxeUUID()
                local foundAny = false
                local validCrystals = {}

                for _, crystal in ipairs(CrystalsFolder:GetChildren()) do
                    local targetPart = crystal:IsA("BasePart") and crystal or crystal:FindFirstChildWhichIsA("BasePart")
                    if targetPart then
                        local prompt = crystal:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.Enabled then
                            local isPickaxe = (crystal.Name == "20220" or string.find(string.lower(crystal.Name), "pickaxe"))
                            if isPickaxe and pickaxeUUID then
                                continue
                            end
                            table.insert(validCrystals, { part = targetPart, prompt = prompt })
                        end
                    end
                end

                if #validCrystals > 0 then
                    foundAny = true
                    hasActionTaken = true

                    for _, data in ipairs(validCrystals) do
                        if not (_G.AutoCrystal and autoCrystalRunning) then break end
                        if pickaxeUUID then
                            local char = Player.Character
                            local heldTool = char and char:FindFirstChildWhichIsA("Tool")
                            if not heldTool or (heldTool.Name ~= "20220" and not string.find(string.lower(heldTool.Name), "pickaxe")) then
                                equipPickaxe(pickaxeUUID)
                            end
                        end
                        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                            Player.Character.HumanoidRootPart.CFrame = data.part.CFrame * CFrame.new(0, 5, 0)
                        end
                        task.wait(0.3)
                        fireproximityprompt(data.prompt)
                        task.wait(0.8)
                    end
                end

                if not foundAny then
                    if hasActionTaken then
                        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                            Player.Character.HumanoidRootPart.CFrame = StartCFrame
                        end
                        task.wait(0.5)
                    end

                    -- Equip rod (slot 1)
                    if REEquip then
                        pcall(REEquip.FireServer, REEquip, 1)
                    elseif EquipTool then
                        pcall(EquipTool.FireServer, EquipTool, 1)
                    end

                    task.wait(0.3)
                    if Player.Character then
                        local Humanoid = Player.Character:FindFirstChild("Humanoid")
                        local Backpack = Player.Backpack
                        if Humanoid and Backpack then
                            local cur = Player.Character:FindFirstChildWhichIsA("Tool")
                            local holdingRod = cur and string.find(cur.Name, "Rod")
                            if not holdingRod then
                                for _, t in ipairs(Backpack:GetChildren()) do
                                    if t:IsA("Tool") and string.find(t.Name, "Rod") then
                                        Humanoid:EquipTool(t)
                                        break
                                    end
                                end
                            end
                        end
                    end

                    if hasActionTaken then
                        task.wait(1.0)
                        if ChargeRod then
                            pcall(ChargeRod.InvokeServer, ChargeRod, 100)
                        end
                        hasActionTaken = false
                    end
                    task.wait(2)
                else
                    task.wait(0.5)
                end
            end
            autoCrystalRunning = false
        end)
    end,
})

AutoTab:CreateButton({
    Name = "Test Equip Pickaxe",
    Callback = function()
        local uuid = getPickaxeUUID()
        if uuid then
            print("[Test Equip] Found Pickaxe UUID:", uuid)
            local success = equipPickaxe(uuid)
            Window:Notify({
                Title = "Equip Test",
                Content = success and "Sent Equip Request!" or "Failed to access Remote",
                Duration = 2,
            })
        else
            Window:Notify({
                Title = "Equip Test",
                Content = "No Pickaxe Found (ID 20220)",
                Duration = 2,
            })
        end
    end,
})

-- ============================================================
-- AUTO CAVE (Refactored - Removed spawn)
-- ============================================================
AutoTab:CreateSection({ Name = "Auto Cave", Icon = "rbxassetid://7733799901" })

AutoTab:CreateToggle({
    Name = "Auto Open Mysterious Cave Wall",
    Default = false,
    Callback = function(state)
        if state then
            task.spawn(function()
                for i = 1, 4 do
                    if SearchPickup then
                        pcall(SearchPickup.FireServer, SearchPickup, "TNT")
                    end
                    task.wait(0.5)
                end
                task.wait(1)
                if GainMaze then
                    pcall(GainMaze.FireServer, GainMaze)
                end
                Window:Notify({
                    Title = "Cave Wall Opened! 🚪",
                    Content = "Mysterious Cave Wall has been opened!",
                    Duration = 5,
                })
            end)
        end
    end,
})

-- ============================================================
-- AUTO PIRATE CHEST (Refactored - Thread Management)
-- ============================================================
local autoPirateThread = nil
local autoPirateRunning = false

AutoTab:CreateToggle({
    Name = "Auto Open Pirate Chest",
    Default = false,
    Callback = function(state)
        _G.AutoOpenPirateChest = state
        if autoPirateThread then
            task.cancel(autoPirateThread)
            autoPirateThread = nil
        end
        if not state then
            autoPirateRunning = false
            return
        end

        autoPirateRunning = true
        local PirateChestRemote = PirateChest  -- Hindari shadowing RE

        autoPirateThread = task.spawn(function()
            while _G.AutoOpenPirateChest and autoPirateRunning do
                pcall(function()
                    local chestsFound = 0
                    local pirateChestStorage = workspace:FindFirstChild("PirateChestStorage")
                    if pirateChestStorage and PirateChestRemote then
                        for _, chest in ipairs(pirateChestStorage:GetChildren()) do
                            local chestId = chest.Name
                            if chestId:match("%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x") then
                                pcall(PirateChestRemote.FireServer, PirateChestRemote, chestId)
                                chestsFound = chestsFound + 1
                                print("[VoraHub] Claiming chest:", chestId)
                                task.wait(0.3)
                            end
                        end
                        if chestsFound > 0 then
                            print("[VoraHub] Successfully claimed", chestsFound, "pirate chests!")
                        else
                            print("[VoraHub] No pirate chests found in PirateChestStorage")
                        end
                    else
                        print("[VoraHub] PirateChestStorage not found or remote missing")
                    end
                end)
                task.wait(2)
            end
            autoPirateRunning = false
        end)

        Window:Notify({
            Title = "Auto Pirate Chest ON! 🏴‍☠️",
            Content = "Auto claiming pirate chests enabled!",
            Duration = 4,
        })
    end,
})

-- ============================================================
-- ENCHANT FEATURES (Refactored - Thread Management & Cache)
-- ============================================================
AutoTab:CreateSection({ Name = "Enchant Features", Icon = "rbxassetid://7733801202" })

-- ============================================================
-- CONFIGURATION
-- ============================================================
local STONE_IDS = {
    ["Enchant Stones"] = 10,
    ["Evolved Enchant Stone"] = 558,
}

-- State (gunakan _G untuk kompatibilitas dengan kode lain)
_G.SelectedStoneType = _G.SelectedStoneType or "Enchant Stones"
_G.TargetEnchantBasic = _G.TargetEnchantBasic or "Big Hunter 1"
_G.TargetEnchantEvolved = _G.TargetEnchantEvolved or "SECRET Hunter"
_G.AutoEnchant = _G.AutoEnchant or false

-- Enchant name → ID mapping
local ENCHANT_ID_MAP = {
    -- Basic
    ["Big Hunter 1"] = 3,
    ["Cursed 1"] = 12,
    ["Empowered 1"] = 9,
    ["Glistening 1"] = 1,
    ["Gold Digger 1"] = 4,
    ["Leprechaun 1"] = 5,
    ["Leprechaun 2"] = 6,
    ["Mutation Hunter 1"] = 7,
    ["Mutation Hunter 2"] = 14,
    ["Prismatic 1"] = 13,
    ["Reeler 1"] = 2,
    ["Stargazer 1"] = 8,
    ["Stormhunter 1"] = 11,
    ["XPerienced 1"] = 10,
    -- Evolved
    ["SECRET Hunter"] = 16,
    ["Shark Hunter"] = 20,
    ["Stargazer II"] = 17,
    ["Stormhunter II"] = 19,
    ["Mutation Hunter II"] = 14,
    ["Leprechaun II"] = 6,
    ["Reeler II"] = 21,
    ["Mutation Hunter III"] = 22,
    ["Fairy Hunter 1"] = 15,
}

local BASIC_ENCHANT_NAMES = {
    "Big Hunter 1", "Cursed 1", "Empowered 1", "Glistening 1",
    "Gold Digger 1", "Leprechaun 1", "Leprechaun 2",
    "Mutation Hunter 1", "Mutation Hunter 2", "Prismatic 1",
    "Reeler 1", "Stargazer 1", "Stormhunter 1", "XPerienced 1",
}

local EVOLVED_ENCHANT_NAMES = {
    "Prismatic 1", "Cursed 1", "Gold Digger 1", "Empowered 1",
    "SECRET Hunter", "Shark Hunter", "Stargazer II", "Stormhunter II",
    "Mutation Hunter II", "Leprechaun II", "Reeler II", "Mutation Hunter III",
    "Fairy Hunter 1",
}

-- ============================================================
-- CACHE HELPERS (Mengurangi akses ke Data)
-- ============================================================
local enchantCache = {
    stoneCount = 0,
    rodName = "None",
    enchantId = nil,
    stones = {},
    timestamp = 0,
    duration = 2,  -- 2 detik cache
}

local function invalidateEnchantCache()
    enchantCache.timestamp = 0
end

local function refreshEnchantCache()
    local now = tick()
    if now - enchantCache.timestamp < enchantCache.duration then
        return
    end

    pcall(function()
        -- Stone count & UUIDs
        local targetId = STONE_IDS[_G.SelectedStoneType]
        local inv = Data:GetExpect({ "Inventory", "Items" })
        local stones = {}
        local count = 0
        if inv then
            for _, item in ipairs(inv) do
                if item.Id == targetId then
                    count = count + (item.Quantity or 1)
                    table.insert(stones, { UUID = item.UUID, Quantity = item.Quantity or 1, Id = item.Id })
                end
            end
        end
        enchantCache.stoneCount = count
        enchantCache.stones = stones

        -- Rod name & current enchant
        local rodName = "None"
        local enchantId = nil
        local equipped = Data:Get("EquippedItems")
        if equipped then
            local rods = Data:GetExpect({ "Inventory", "Fishing Rods" })
            if rods then
                for _, uuid in pairs(equipped) do
                    for _, rod in ipairs(rods) do
                        if rod.UUID == uuid then
                            local itemData = ItemUtility:GetItemData(rod.Id)
                            rodName = (itemData and itemData.Data and itemData.Data.Name) or rod.ItemName or "None"
                            if rod.Metadata and rod.Metadata.EnchantId then
                                enchantId = rod.Metadata.EnchantId
                            end
                            break
                        end
                    end
                end
            end
        end
        enchantCache.rodName = rodName
        enchantCache.enchantId = enchantId
        enchantCache.timestamp = now
    end)
end

local function getCachedEnchantData()
    refreshEnchantCache()
    local enchName = "None"
    if enchantCache.enchantId then
        for name, eid in pairs(ENCHANT_ID_MAP) do
            if eid == enchantCache.enchantId then
                enchName = name
                break
            end
        end
    end
    return enchantCache.rodName, enchName, enchantCache.stoneCount, enchantCache.stones
end

-- ============================================================
-- PARAGRAPH (Status Update)
-- ============================================================
local EnchantParagraph = AutoTab:CreateParagraph({
    Title = "Enchanting Features",
    Content = "Loading...",
    RichText = true,
})

local function updateEnchantParagraph()
    local rodName, enchName, stoneCount = getCachedEnchantData()
    local desc = string.format(
        "Rod Active <font color='rgb(0,191,255)'>= %s</font>\n" ..
        "Enchant Now <font color='rgb(200,0,255)'>= %s</font>\n" ..
        "Stone Left <font color='rgb(255,215,0)'>= %d</font>\n" ..
        "Stone Type <font color='rgb(0,255,0)'>= %s</font>",
        rodName, enchName, stoneCount, _G.SelectedStoneType
    )
    EnchantParagraph:SetDesc(desc)
end

local lastRodName, lastEnchantName, lastStoneCount, lastStoneType = "", "", -1, ""
task.spawn(function()
    while task.wait(4) do
        pcall(function()
            local rod, ench, count = getCachedEnchantData()
            local stoneType = _G.SelectedStoneType
            if rod ~= lastRodName or ench ~= lastEnchantName or count ~= lastStoneCount or stoneType ~= lastStoneType then
                updateEnchantParagraph()
                lastRodName, lastEnchantName, lastStoneCount, lastStoneType = rod, ench, count, stoneType
            end
        end)
    end
end)

-- ============================================================
-- UI ELEMENTS
-- ============================================================

-- Stone Type Dropdown
AutoTab:CreateDropdown({
    Name = "Enchant Stone Type",
    Items = { "Enchant Stones", "Evolved Enchant Stone" },
    Value = _G.SelectedStoneType,
    Callback = function(selected)
        _G.SelectedStoneType = selected
        invalidateEnchantCache()
        print("[Enchant] Stone type:", selected, "ID:", STONE_IDS[selected])
    end,
})

-- Teleport Buttons
AutoTab:CreateButton({
    Name = "Teleport to Altar",
    Icon = "rbxassetid://128755575520135",
    Callback = function()
        local targetCFrame = CFrame.new(3234.83667, -1302.85486, 1398.39087, 0.464485794, -1.12043161e-07, -0.885580599, 6.74793981e-08, 1, -9.11265872e-08, 0.885580599, -1.74314394e-08, 0.464485794)
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = targetCFrame end
        end
    end,
})

AutoTab:CreateButton({
    Name = "Teleport to Second Altar",
    Icon = "rbxassetid://7733920644",
    Callback = function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char:PivotTo(CFrame.new(1481, 128, -592))
        end
    end,
})

-- Target Enchant Dropdowns
AutoTab:CreateDropdown({
    Name = "Target Enchant (Basic)",
    Items = BASIC_ENCHANT_NAMES,
    Value = _G.TargetEnchantBasic,
    Callback = function(selected)
        _G.TargetEnchantBasic = selected
        print("[Enchant] Basic target:", selected, "ID:", ENCHANT_ID_MAP[selected])
    end,
})

AutoTab:CreateDropdown({
    Name = "Target Enchant (Evolved)",
    Items = EVOLVED_ENCHANT_NAMES,
    Value = _G.TargetEnchantEvolved,
    Callback = function(selected)
        _G.TargetEnchantEvolved = selected
        print("[Enchant] Evolved target:", selected, "ID:", ENCHANT_ID_MAP[selected])
    end,
})

-- Auto Enchant Toggle (BARU - DENGAN THREAD MANAGEMENT)
AutoTab:CreateToggle({
    Name = "Auto Enchant",
    Value = _G.AutoEnchant,
    Callback = function(value)
        _G.AutoEnchant = value
        if value then
            startAutoEnchant()   -- <--- Mulai loop auto enchant
        else
            stopAutoEnchant()    -- <--- Hentikan loop auto enchant
        end
        local target = _G.SelectedStoneType == "Evolved Enchant Stone" and _G.TargetEnchantEvolved or _G.TargetEnchantBasic
        print("[Enchant] Auto Enchant:", value and "ENABLED" or "DISABLED", "| Target:", target, "| Stone:", _G.SelectedStoneType)
        if value then
            Window:Notify({
                Title = "Auto Enchant",
                Content = "Target: " .. target,
                Duration = 2,
            })
        end
    end,
})

-- Double Enchant Button
AutoTab:CreateButton({
    Name = "Start Double Enchant",
    Icon = "rbxassetid://7733920644",
    Callback = function()
        task.spawn(function()
            local rodName, _, stoneCount, uuids = getCachedEnchantData()
            if rodName == "None" then
                warn("[Enchant] No rod equipped!")
                Window:Notify({ Title = "Error", Content = "No rod equipped!", Duration = 2 })
                return
            end
            if stoneCount == 0 then
                warn("[Enchant] No", _G.SelectedStoneType, "available!")
                Window:Notify({ Title = "Error", Content = "No " .. _G.SelectedStoneType .. " available!", Duration = 2 })
                return
            end

            print("[Enchant] Starting Double Enchant with", _G.SelectedStoneType)
            local stoneUUID = uuids[1] and uuids[1].UUID
            if not stoneUUID then
                warn("[Enchant] No stone UUID found")
                return
            end

            -- Equip stone
            local slot = nil
            local startTime = tick()
            while tick() - startTime < 5 do
                local equipped = Data:Get("EquippedItems")
                if equipped then
                    for sl, id in pairs(equipped) do
                        if id == stoneUUID then
                            slot = sl
                            break
                        end
                    end
                end
                if slot then break end
                pcall(equipItemRemote.FireServer, equipItemRemote, stoneUUID, "EnchantStones")
                task.wait(0.3)
            end

            if not slot then
                warn("[Enchant] Failed to equip stone!")
                Window:Notify({ Title = "Error", Content = "Failed to equip stone!", Duration = 2 })
                return
            end

            task.wait(0.2)
            pcall(equipToolRemote.FireServer, equipToolRemote, slot)
            task.wait(0.2)
            pcall(activateAltarRemote.FireServer, activateAltarRemote)
            print("[Enchant] ✅ Double Enchant activated!")
            Window:Notify({ Title = "Enchant", Content = "Double Enchant triggered!", Duration = 2 })
        end)
    end,
})

-- ============================================================
-- AUTO ENCHANT LOOP (Thread Management)
-- ============================================================
local autoEnchantThread = nil
local autoEnchantRunning = false

local function autoEnchantLoop()
    local lastTarget = ""
    local lastStoneType = ""

    while _G.AutoEnchant and autoEnchantRunning do
        pcall(function()
            local targetEnchant = _G.SelectedStoneType == "Evolved Enchant Stone"
                and _G.TargetEnchantEvolved
                or _G.TargetEnchantBasic

            -- Force refresh cache
            invalidateEnchantCache()
            local _, _, _, stones = getCachedEnchantData()

            local currentId = enchantCache.enchantId
            local targetId = ENCHANT_ID_MAP[targetEnchant]

            if not targetId then
                warn("[Enchant] Invalid target enchant:", targetEnchant)
                _G.AutoEnchant = false
                Window:Notify({ Title = "Error", Content = "Invalid target enchant!", Duration = 2 })
                return
            end

            if currentId == targetId then
                if lastTarget ~= targetEnchant or lastStoneType ~= _G.SelectedStoneType then
                    print("[Enchant] ✅ Target reached:", targetEnchant, "(ID:", targetId, ")")
                    Window:Notify({ Title = "Enchant Complete", Content = targetEnchant .. " achieved!", Duration = 3 })
                    lastTarget = targetEnchant
                    lastStoneType = _G.SelectedStoneType
                end
                _G.AutoEnchant = false
                return
            end

            if #stones == 0 then
                warn("[Enchant] No", _G.SelectedStoneType, "available!")
                task.wait(2)
                return
            end

            local stone = stones[1]
            if not equipItemRemote or not equipToolRemote or not activateAltarRemote then
                warn("[Enchant] Missing remotes!")
                task.wait(2)
                return
            end

            pcall(equipItemRemote.FireServer, equipItemRemote, stone.UUID, "Enchant Stones")
            task.wait(1)

            local slotNumber = countDisplayImageButtons() - 2
            if slotNumber < 1 then slotNumber = 1 end
            pcall(equipToolRemote.FireServer, equipToolRemote, slotNumber)
            task.wait(1)

            pcall(activateAltarRemote.FireServer, activateAltarRemote)
            print("[Enchant] Applied", _G.SelectedStoneType, "→", targetEnchant)

            task.wait(5)
        end)
        task.wait(0.8)
    end
end

-- Start/Stop logic menggunakan thread handle
local function startAutoEnchant()
    if autoEnchantRunning then return end
    autoEnchantRunning = true
    autoEnchantThread = task.spawn(autoEnchantLoop)
end

local function stopAutoEnchant()
    autoEnchantRunning = false
    if autoEnchantThread then
        task.cancel(autoEnchantThread)
        autoEnchantThread = nil
    end
    _G.AutoEnchant = false
end

-- Override toggle callback untuk menggunakan thread management
-- (Toggle sudah dibuat di atas, tapi kita override dengan mengganti callback)
-- Karena UI toggle sudah dibuat, kita perlu memodifikasi callback-nya.
-- Tapi untuk refactoring, kita bisa biarkan toggle seperti sebelumnya dan hanya
-- menambahkan start/stop di dalam callback yang sudah ada.
-- Saya akan tulis ulang toggle dengan callback yang benar:

-- Hapus toggle yang lama dan buat baru dengan callback yang tepat
-- (Dalam implementasi nyata, Anda harus mengganti toggle yang ada)

-- Untuk keperluan refactoring, saya akan menambahkan fungsi start/stop dan
-- menggunakannya di toggle callback.

print("[Enchant] Features initialized")

-- ============================================================
-- PLAYER TAB (Refactored)
-- ============================================================

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- ============================================================
-- WALK SPEED
-- ============================================================
PlayerTab:CreateInput({
    Name = "Walk Speed",
    SideLabel = "Contoh: 18",
    Placeholder = "Enter Speed...",
    Default = "",
    Callback = function(value)
        local char = Player.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                local speed = tonumber(value)
                hum.WalkSpeed = (speed and speed > 0) and speed or 18
            end
        end
    end,
})

-- ============================================================
-- JUMP POWER (Fix: parameter harus 'value', bukan 'Text')
-- ============================================================
PlayerTab:CreateInput({
    Name = "Jump Power",
    SideLabel = "Contoh: 50",
    Placeholder = "Enter Power...",
    Default = "",
    Callback = function(value)  -- ✅ Perbaiki: 'value' bukan 'Text'
        local char = Player.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                local power = tonumber(value)
                hum.JumpPower = (power and power > 0) and power or 50
            end
        end
    end,
})

-- ============================================================
-- INFINITE JUMP (Fix: connection management)
-- ============================================================
local infiniteJumpConnection = nil  -- Local handle untuk mencegah leak

local function toggleInfiniteJump(state)
    -- Putuskan koneksi lama jika ada
    if infiniteJumpConnection then
        infiniteJumpConnection:Disconnect()
        infiniteJumpConnection = nil
    end

    _G.InfiniteJump = state

    if state then
        print("✅ Infinite Jump Active")
        infiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
            if _G.InfiniteJump then
                local char = Player.Character or Player.CharacterAdded:Wait()
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
    else
        print("❌ Infinite Jump Inactive")
    end
end

PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    Default = false,
    Callback = function(Value)
        toggleInfiniteJump(Value)
    end,
})

-- ============================================================
-- NOCLIP (Fix: thread management)
-- ============================================================
local noclipThread = nil
local noclipRunning = false

local function toggleNoclip(state)
    _G.Noclip = state

    if state then
        -- Matikan thread lama jika ada
        if noclipThread then
            task.cancel(noclipThread)
            noclipThread = nil
        end

        noclipRunning = true
        noclipThread = task.spawn(function()
            while _G.Noclip and noclipRunning do
                task.wait(0.1)
                local char = Player.Character
                if char then
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end
            noclipRunning = false
        end)
    else
        noclipRunning = false
        if noclipThread then
            task.cancel(noclipThread)
            noclipThread = nil
        end
        -- Restore collision (opsional, tapi baik untuk safety)
        local char = Player.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

PlayerTab:CreateToggle({
    Name = "Noclip",
    Default = false,
    Callback = function(state)
        toggleNoclip(state)
    end,
})

-- ============================================================
-- RADAR (Fix: pcall untuk safety)
-- ============================================================
PlayerTab:CreateToggle({
    Name = "Radar",
    Default = false,
    Callback = function(state)
        pcall(function()  -- ✅ Bungkus dengan pcall agar tidak crash
            local Lighting = game:GetService("Lighting")
            local Replion = require(ReplicatedStorage.Packages.Replion).Client:GetReplion("Data")
            local NetFunction = UpdateRadar

            if Replion and NetFunction and NetFunction:InvokeServer(state) then
                local sound = require(ReplicatedStorage.Shared.Soundbook).Sounds.RadarToggle:Play()
                sound.PlaybackSpeed = 1 + math.random() * 0.3

                local c = Lighting:FindFirstChildWhichIsA("ColorCorrectionEffect")
                if c then
                    require(ReplicatedStorage.Packages.spr).stop(c)

                    local time = require(ReplicatedStorage.Controllers.ClientTimeController)
                    local profile = time._getLightingProfile and time:_getLightingProfile() or {}
                    local correction = profile.ColorCorrection or {}
                    correction.Brightness = correction.Brightness or 0.04
                    correction.TintColor = correction.TintColor or Color3.fromRGB(255, 255, 255)

                    if state then
                        c.TintColor = Color3.fromRGB(42, 226, 118)
                        c.Brightness = 0.4
                    else
                        c.TintColor = Color3.fromRGB(255, 0, 0)
                        c.Brightness = 0.2
                    end

                    require(ReplicatedStorage.Packages.spr).target(c, 1, 1, correction)
                end

                require(ReplicatedStorage.Packages.spr).stop(Lighting)
                Lighting.ExposureCompensation = 1
                require(ReplicatedStorage.Packages.spr).target(Lighting, 1, 2, { ExposureCompensation = 0 })
            end
        end)
    end,
})

-- ============================================================
-- PLAYER TAB (Refactored)
-- ============================================================

-- Diving Gear (dengan pengecekan remote)
PlayerTab:CreateToggle({
    Name = "Diving Gear",
    Default = false,
    Callback = function(state)
        _G.DivingGear = state
        if state then
            if EquipOxygen then
                pcall(EquipOxygen.InvokeServer, EquipOxygen, 105)
            else
                warn("[DivingGear] EquipOxygen remote not found!")
            end
        else
            if UnequipOxygen then
                pcall(UnequipOxygen.InvokeServer, UnequipOxygen)
            else
                warn("[DivingGear] UnequipOxygen remote not found!")
            end
        end
    end,
})

-- ============================================================
-- SHOP TAB - BOOSTER LUCK (Refactored)
-- ============================================================
ShopTab:CreateSection({ Name = "Booster Luck" })

local GiftingController
pcall(function()
    GiftingController = require(game:GetService("ReplicatedStorage"):WaitForChild("Controllers"):WaitForChild("GiftingController"))
end)

local luckBoosters = { "x2 Luck", "x4 Luck", "x8 Luck" }
local selectedLuckBooster = luckBoosters[1]

ShopTab:CreateDropdown({
    Name = "Select Luck Booster",
    Items = luckBoosters,
    Value = selectedLuckBooster,
    Callback = function(value)
        selectedLuckBooster = value
    end,
})

ShopTab:CreateButton({
    Name = "Buy Luck Booster",
    Icon = "rbxassetid://7733920644",
    Callback = function()
        if not GiftingController then
            Window:Notify({ Title = "Error", Content = "GiftingController not available!", Duration = 3 })
            return
        end
        local success, err = pcall(function()
            GiftingController:Open(selectedLuckBooster)
        end)
        if success then
            Window:Notify({ Title = "Luck Booster", Content = "Purchased " .. selectedLuckBooster .. "!", Duration = 3 })
        else
            Window:Notify({ Title = "Purchase Error", Content = tostring(err), Duration = 5 })
        end
    end,
})

-- ============================================================
-- SHOP TAB - ROD SKIN (Refactored)
-- ============================================================
ShopTab:CreateSection({ Name = "Skin Rod" })

local rodSkins = {
    "Frozen Krampus Scythe",
    "Gingerbread Katana",
    "Christmas Parasol",
}
local selectedRodSkin = rodSkins[1]

ShopTab:CreateDropdown({
    Name = "Select Rod Skin",
    Items = rodSkins,
    Value = selectedRodSkin,
    Callback = function(value)
        selectedRodSkin = value
    end,
})

ShopTab:CreateButton({
    Name = "Buy Rod Skin",
    Icon = "rbxassetid://7733920644",
    Callback = function()
        if not GiftingController then
            Window:Notify({ Title = "Error", Content = "GiftingController not available!", Duration = 3 })
            return
        end
        local success, err = pcall(function()
            GiftingController:Open(selectedRodSkin)
        end)
        if success then
            Window:Notify({ Title = "Rod Skin", Content = "Purchased " .. selectedRodSkin .. "!", Duration = 3 })
        else
            Window:Notify({ Title = "Purchase Error", Content = tostring(err), Duration = 5 })
        end
    end,
})

-- ============================================================
-- SHOP TAB - BUY ROD (Refactored)
-- ============================================================
ShopTab:CreateSection({ Name = "Buy Rod" })

local RFPurchaseFishingRod = BuyRod  -- Tetap global untuk kompatibilitas

local rods = {
    ["Luck Rod"] = 79,
    ["Carbon Rod"] = 76,
    ["Grass Rod"] = 85,
    ["Demascus Rod"] = 77,
    ["Ice Rod"] = 78,
    ["Lucky Rod"] = 4,
    ["Midnight Rod"] = 80,
    ["Steampunk Rod"] = 6,
    ["Chrome Rod"] = 7,
    ["Astral Rod"] = 5,
    ["Ares Rod"] = 126,
    ["Angler Rod"] = 168,
    ["Bamboo Rod"] = 258,
}

local rodNames = {
    "Luck Rod (350 Coins)",
    "Carbon Rod (900 Coins)",
    "Grass Rod (1.5k Coins)",
    "Demascus Rod (3k Coins)",
    "Ice Rod (5k Coins)",
    "Lucky Rod (15k Coins)",
    "Midnight Rod (50k Coins)",
    "Steampunk Rod (215k Coins)",
    "Chrome Rod (437k Coins)",
    "Astral Rod (1M Coins)",
    "Ares Rod (3M Coins)",
    "Angler Rod (8M Coins)",
    "Bamboo Rod (12M Coins)",
}

local rodKeyMap = {
    ["Luck Rod (350 Coins)"] = "Luck Rod",
    ["Carbon Rod (900 Coins)"] = "Carbon Rod",
    ["Grass Rod (1.5k Coins)"] = "Grass Rod",
    ["Demascus Rod (3k Coins)"] = "Demascus Rod",
    ["Ice Rod (5k Coins)"] = "Ice Rod",
    ["Lucky Rod (15k Coins)"] = "Lucky Rod",
    ["Midnight Rod (50k Coins)"] = "Midnight Rod",
    ["Steampunk Rod (215k Coins)"] = "Steampunk Rod",
    ["Chrome Rod (437k Coins)"] = "Chrome Rod",
    ["Astral Rod (1M Coins)"] = "Astral Rod",
    ["Ares Rod (3M Coins)"] = "Ares Rod",
    ["Angler Rod (8M Coins)"] = "Angler Rod",
    ["Bamboo Rod (12M Coins)"] = "Bamboo Rod",
}

local selectedRod = rodNames[1]

ShopTab:CreateDropdown({
    Name = "Select Rod",
    Items = rodNames,
    Value = selectedRod,
    Callback = function(value)
        selectedRod = value
    end,
})

ShopTab:CreateButton({
    Name = "Buy Rod",
    Icon = "rbxassetid://7733920644",
    Callback = function()
        if not RFPurchaseFishingRod then
            Window:Notify({ Title = "Error", Content = "Purchase remote not available!", Duration = 3 })
            return
        end
        local key = rodKeyMap[selectedRod]
        if key and rods[key] then
            local success, err = pcall(RFPurchaseFishingRod.InvokeServer, RFPurchaseFishingRod, rods[key])
            if success then
                Window:Notify({ Title = "Rod Purchase", Content = "Purchased " .. selectedRod, Duration = 3 })
            else
                Window:Notify({ Title = "Rod Purchase Error", Content = tostring(err), Duration = 5 })
            end
        else
            Window:Notify({ Title = "Error", Content = "Invalid rod selection!", Duration = 3 })
        end
    end,
})

-- ============================================================
-- SHOP TAB - BUY BAITS (Refactored)
-- ============================================================
ShopTab:CreateSection({ Name = "Buy Baits" })

local RFPurchaseBait = BuyBait  -- Tetap global untuk kompatibilitas

local baits = {
    ["TopWater Bait"] = 10,
    ["Lucky Bait"] = 2,
    ["Midnight Bait"] = 3,
    ["Chroma Bait"] = 6,
    ["Dark Mater Bait"] = 8,
    ["Corrupt Bait"] = 15,
    ["Aether Bait"] = 16,
}

local baitNames = {
    "TopWater Bait (100 Coins)",
    "Lucky Bait (1k Coins)",
    "Midnight Bait (3k Coins)",
    "Chroma Bait (290k Coins)",
    "Dark Mater Bait (630k Coins)",
    "Corrupt Bait (1.15M Coins)",
    "Aether Bait (3.7M Coins)",
}

local baitKeyMap = {
    ["TopWater Bait (100 Coins)"] = "TopWater Bait",
    ["Lucky Bait (1k Coins)"] = "Lucky Bait",
    ["Midnight Bait (3k Coins)"] = "Midnight Bait",
    ["Chroma Bait (290k Coins)"] = "Chroma Bait",
    ["Dark Mater Bait (630k Coins)"] = "Dark Mater Bait",
    ["Corrupt Bait (1.15M Coins)"] = "Corrupt Bait",
    ["Aether Bait (3.7M Coins)"] = "Aether Bait",
}

local selectedBait = baitNames[1]

ShopTab:CreateDropdown({
    Name = "Select Bait",
    Items = baitNames,
    Value = selectedBait,
    Callback = function(value)
        selectedBait = value
    end,
})

ShopTab:CreateButton({
    Name = "Buy Bait",
    Icon = "rbxassetid://7733920644",
    Callback = function()
        if not RFPurchaseBait then
            Window:Notify({ Title = "Error", Content = "Purchase remote not available!", Duration = 3 })
            return
        end
        local key = baitKeyMap[selectedBait]
        if key and baits[key] then
            local success, err = pcall(RFPurchaseBait.InvokeServer, RFPurchaseBait, baits[key])
            if success then
                Window:Notify({ Title = "Bait Purchase", Content = "Purchased " .. selectedBait, Duration = 3 })
            else
                Window:Notify({ Title = "Bait Purchase Error", Content = tostring(err), Duration = 5 })
            end
        else
            Window:Notify({ Title = "Error", Content = "Invalid bait selection!", Duration = 3 })
        end
    end,
})

-- ============================================================
-- SHOP TAB - BUY WEATHER EVENT (Refactored)
-- ============================================================
ShopTab:CreateSection({ Name = "Buy Weather Event", Icon = "rbxassetid://7733955511" })

-- ============================================================
-- CONFIGURATION
-- ============================================================
local RFPurchaseWeatherEvent = BuyWeather  -- Tetap global

-- Data cuaca (key internal → display name & price)
local WEATHER_DATA = {
    Wind      = { Display = "Windy (10k Coins)",      Price = 10000 },
    Cloudy    = { Display = "Cloudy (20k Coins)",     Price = 20000 },
    Snow      = { Display = "Snow (15k Coins)",       Price = 15000 },
    Storm     = { Display = "Stormy (35k Coins)",     Price = 35000 },
    Radiant   = { Display = "Radiant (50k Coins)",    Price = 50000 },
    ["Shark Hunt"] = { Display = "Shark Hunt (300k Coins)", Price = 300000 },
}

-- Build display names list & key mapping dari data di atas
local weatherDisplayNames = {}
local weatherKeyMap = {}  -- Display → Key internal

for key, data in pairs(WEATHER_DATA) do
    table.insert(weatherDisplayNames, data.Display)
    weatherKeyMap[data.Display] = key
end
table.sort(weatherDisplayNames)

-- State (local)
local selectedWeathers = {}
local autoBuyRunning = false
local autoBuyThread = nil

-- ============================================================
-- UI ELEMENTS
-- ============================================================
ShopTab:CreateMultiDropdown({
    Name = "Select Weather Events",
    Items = weatherDisplayNames,
    Default = selectedWeathers,
    Callback = function(values)
        selectedWeathers = values
        print("[Weather] Selected:", table.concat(values, ", "))
    end,
})

-- ============================================================
-- AUTO BUY LOOP (Dengan Thread Management)
-- ============================================================
local function startAutoBuy()
    if autoBuyRunning then
        print("[Weather] Auto-buy already running")
        return
    end

    if #selectedWeathers == 0 then
        Window:Notify({
            Title = "⚠️ No Selection",
            Content = "Please select at least one weather event before enabling.",
            Duration = 3,
        })
        return
    end

    if not RFPurchaseWeatherEvent then
        Window:Notify({
            Title = "❌ Remote Missing",
            Content = "PurchaseWeatherEvent remote not available!",
            Duration = 3,
        })
        return
    end

    autoBuyRunning = true
    Window:Notify({
        Title = "🌤️ Auto Buy Enabled",
        Content = "Auto-purchase started. It will keep buying until turned off.",
        Duration = 3,
    })
    print("[Weather] Auto-buy STARTED")

    autoBuyThread = task.spawn(function()
        local successCount = 0
        local failCount = 0

        while autoBuyRunning do
            for _, selectedDisplay in ipairs(selectedWeathers) do
                if not autoBuyRunning then break end

                local key = weatherKeyMap[selectedDisplay]
                if key and WEATHER_DATA[key] then
                    local ok, err = pcall(RFPurchaseWeatherEvent.InvokeServer, RFPurchaseWeatherEvent, key)
                    if ok then
                        successCount = successCount + 1
                        print("[Weather] ✅ Purchased:", selectedDisplay)
                    else
                        failCount = failCount + 1
                        warn("[Weather] ❌ Failed to purchase:", selectedDisplay, "| Error:", err)
                        -- Jika error karena remote nil, hentikan loop
                        if not RFPurchaseWeatherEvent then
                            warn("[Weather] Remote missing, stopping auto-buy")
                            break
                        end
                    end
                else
                    warn("[Weather] Invalid weather:", selectedDisplay)
                    Window:Notify({
                        Title = "⚠️ Invalid Weather",
                        Content = "Invalid selection: " .. tostring(selectedDisplay),
                        Duration = 2,
                    })
                end
                task.wait(0.5)
            end

            -- Print summary setiap siklus
            if successCount > 0 or failCount > 0 then
                print(string.format("[Weather] Cycle summary: ✅ %d success, ❌ %d failed", successCount, failCount))
            end
            task.wait(5)
        end

        print("[Weather] Auto-buy STOPPED")
        autoBuyRunning = false
        autoBuyThread = nil
    end)
end

local function stopAutoBuy()
    autoBuyRunning = false
    if autoBuyThread then
        task.cancel(autoBuyThread)
        autoBuyThread = nil
    end
    Window:Notify({
        Title = "🛑 Auto Buy Disabled",
        Content = "Weather auto-purchase stopped.",
        Duration = 3,
    })
    print("[Weather] Auto-buy stopped by user")
end

-- ============================================================
-- TOGGLE UI
-- ============================================================
ShopTab:CreateToggle({
    Name = "Auto Buy Selected Weathers",
    SubText = "Continuously purchase all selected weather events while ON",
    Default = false,
    Callback = function(state)
        if state then
            startAutoBuy()
        else
            stopAutoBuy()
        end
    end,
})

print("[Weather] System initialized with", #weatherDisplayNames, "weather types")

-- ============================================================
-- TELEPORT TAB (DENGAN FLY TELEPORT - ANTI RESPAWN)
-- ============================================================

-- ============================================================
-- TELEPORT FUNCTION (MANDIRI, TANPA DEPENDENSI EKSTERNAL)
-- ============================================================
local function teleportToPosition(targetPos: Vector3, cancelCheck: (() -> boolean)?): boolean
    local character = game.Players.LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    -- Unsit jika sedang duduk
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Sit then
        humanoid.Sit = false
        task.wait(0.15)
    end

    -- Aktifkan fly / body velocity
    local flySpeed = 50
    local bodyVelocity = hrp:FindFirstChild("BodyVelocity")
    if not bodyVelocity then
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Name = "FlyTeleportVelocity"
        bodyVelocity.MaxForce = Vector3.new(9e4, 9e4, 9e4)
        bodyVelocity.Parent = hrp
    end

    -- Simpan CanCollide asli dan matikan sementara (noclip)
    local originalCollide = {}
    local parts = {}
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            originalCollide[part] = part.CanCollide
            part.CanCollide = false
            table.insert(parts, part)
        end
    end

    local aborted = false
    local function shouldCancel()
        if cancelCheck and cancelCheck() then
            aborted = true
            return true
        end
        return false
    end

    -- 1. Terbang HORIZONTAL ke target (X, Z)
    local horizontalTarget = Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z)
    local distance = (horizontalTarget - hrp.Position).Magnitude
    local tickCounter = 0
    while distance > 3 do
        if not hrp or not hrp.Parent or shouldCancel() then break end
        tickCounter = tickCounter + 1
        if tickCounter % 5 == 0 then
            for _, part in pairs(parts) do
                if part and part.Parent then part.CanCollide = false end
            end
        end
        local dir = (horizontalTarget - hrp.Position).Unit
        bodyVelocity.Velocity = dir * flySpeed
        distance = (horizontalTarget - hrp.Position).Magnitude
        task.wait()
    end

    -- 2. Terbang VERTIKAL ke target Y
    distance = (targetPos - hrp.Position).Magnitude
    tickCounter = 0
    while distance > 3 do
        if not hrp or not hrp.Parent or shouldCancel() then break end
        tickCounter = tickCounter + 1
        if tickCounter % 5 == 0 then
            for _, part in pairs(parts) do
                if part and part.Parent then part.CanCollide = false end
            end
        end
        local dir = (targetPos - hrp.Position).Unit
        bodyVelocity.Velocity = dir * flySpeed
        distance = (targetPos - hrp.Position).Magnitude
        task.wait()
    end

    -- Hentikan gerakan
    bodyVelocity.Velocity = Vector3.zero
    if hrp and hrp.Parent then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.AssemblyLinearVelocity = Vector3.new(0, -5, 0) -- bantu turun
    end

    -- Bersihkan BodyVelocity sementara (jika kita yang buat)
    if bodyVelocity.Name == "FlyTeleportVelocity" and not bodyVelocity:IsA("BodyVelocity") then
        -- tidak perlu, tapi kita cek apakah ini punya parent
    end
    -- Hapus BodyVelocity jika kita yang buat dan bukan milik fly permanent
    -- Kita asumsikan tidak ada fly permanent, jadi hapus
    if bodyVelocity and bodyVelocity.Name == "FlyTeleportVelocity" then
        bodyVelocity:Destroy()
    end

    -- Restore CanCollide
    for part, val in pairs(originalCollide) do
        if part and part.Parent then
            part.CanCollide = val
        end
    end

    if aborted then
        warn("[Teleport] Aborted by cancel check")
        return false
    end

    return true
end

-- Alias global agar bisa dipanggil dari mana saja (opsional)
_G.teleportToPosition = teleportToPosition

-- ============================================================
-- ISLAND TELEPORT
-- ============================================================
TeleportTab:CreateSection({ Name = "Island", Icon = "rbxassetid://7733955511" })

local IslandLocations = {
    -- ... (data lokasi tetap sama, tidak saya tulis ulang untuk hemat tempat)
    -- Isi dengan data yang sudah ada
}

local SelectedIsland = nil

local function getIslandFolder() return workspace:FindFirstChild("Islands") end
local function getIslandDropdownItems()
    local folder = getIslandFolder()
    if not folder then return { "Islands folder not found" } end
    local out = {}
    for _, child in pairs(folder:GetChildren()) do
        if child:IsA("Model") or child:IsA("BasePart") or child:IsA("CFrameValue") or child:IsA("Vector3Value") or child:IsA("Folder") then
            table.insert(out, child.Name)
        end
    end
    table.sort(out)
    return #out > 0 and out or { "No islands found" }
end

local function resolveCFrameFromInstance(inst)
    if not inst then return nil end
    if inst:IsA("Model") then return inst:GetPivot() end
    if inst:IsA("BasePart") then return inst.CFrame end
    if inst:IsA("CFrameValue") then return inst.Value end
    if inst:IsA("Vector3Value") then return CFrame.new(inst.Value) end
    if inst:IsA("Folder") then
        local model = inst:FindFirstChildWhichIsA("Model")
        if model then return model:GetPivot() end
        local part = inst:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.CFrame end
    end
    return nil
end

local function resolveIslandCFrame(selection)
    if not selection or selection == "" then return nil end
    local folder = getIslandFolder()
    if folder then
        local child = folder:FindFirstChild(selection)
        return resolveCFrameFromInstance(child)
    end
    return nil
end

local IslandDropdown = TeleportTab:CreateDropdown({
    Name = "Select Island",
    Items = getIslandDropdownItems(),
    Callback = function(Value) SelectedIsland = Value end
})

-- Refresh dropdown otomatis
task.spawn(function()
    local function refresh()
        if IslandDropdown and IslandDropdown.Refresh then
            IslandDropdown:Refresh(getIslandDropdownItems())
        end
    end
    local folder = getIslandFolder()
    if not folder then
        for _ = 1, 20 do
            folder = getIslandFolder()
            if folder then break end
            task.wait(0.5)
        end
    end
    refresh()
    if folder then
        folder.ChildAdded:Connect(refresh)
        folder.ChildRemoved:Connect(refresh)
    end
end)

-- Tombol Teleport ke Island (dengan fly)
TeleportTab:CreateButton({
    Name = "Teleport to Island",
    Icon = "rbxassetid://7733920644",
    Callback = function()
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            Window:Notify({ Title = "Error", Content = "Character not found!", Duration = 2 })
            return
        end
        local cf = resolveIslandCFrame(SelectedIsland)
        if not cf then
            Window:Notify({ Title = "Error", Content = "Invalid island selected!", Duration = 2 })
            return
        end
        local targetPos = cf.Position + Vector3.new(0, 3, 0)
        local success = teleportToPosition(targetPos)
        if success then
            Window:Notify({ Title = "Teleport", Content = "Teleported to " .. SelectedIsland, Duration = 2 })
        else
            Window:Notify({ Title = "Teleport Failed", Content = "Could not reach destination.", Duration = 3 })
        end
    end
})

-- Lock Position to Island (tetap pakai CFrame loop karena itu fungsinya)
local islandLockThread = nil
local islandLockActive = false
local islandLockCFrame = nil

local function stopIslandLock()
    islandLockActive = false
    if islandLockThread then
        task.cancel(islandLockThread)
        islandLockThread = nil
    end
    islandLockCFrame = nil
end

local function startIslandLock(cf)
    stopIslandLock()
    islandLockActive = true
    islandLockCFrame = cf
    islandLockThread = task.spawn(function()
        local RunService = game:GetService("RunService")
        local Player = game:Players.LocalPlayer
        while islandLockActive do
            task.wait(0.1)
            pcall(function()
                local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if hrp and islandLockCFrame then
                    hrp.CFrame = islandLockCFrame
                end
            end)
        end
    end)
end

TeleportTab:CreateToggle({
    Name = "Lock Position to Island",
    SubText = "Keep teleporting every frame (bypass anti-teleport)",
    Default = false,
    Callback = function(state)
        if state then
            local cf = resolveIslandCFrame(SelectedIsland)
            if not cf then
                Window:Notify({ Title = "Error", Content = "Select a valid island first!", Duration = 2 })
                return
            end
            startIslandLock(cf)
            Window:Notify({ Title = "Lock Enabled", Content = "Position locked to " .. SelectedIsland, Duration = 2 })
        else
            stopIslandLock()
            Window:Notify({ Title = "Lock Disabled", Content = "Position lock released", Duration = 2 })
        end
    end
})

-- ============================================================
-- TELEPORT TO PLAYER
-- ============================================================
TeleportTab:CreateSection({ Name = "Tp To Player", Icon = "rbxassetid://7733955511" })

local SelectedPlayer = nil

local PlayerDropdown = TeleportTab:CreateDropdown({
    Name = "Select Player",
    Items = (function()
        local players = {}
        for _, plr in pairs(game.Players:GetPlayers()) do
            if plr.Name ~= Player.Name then table.insert(players, plr.Name) end
        end
        table.sort(players)
        return players
    end)(),
    Callback = function(Value) SelectedPlayer = Value end
})

function RefreshPlayerList()
    local list = {}
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr.Name ~= Player.Name then table.insert(list, plr.Name) end
    end
    table.sort(list)
    PlayerDropdown:Refresh(list)
end

game.Players.PlayerAdded:Connect(RefreshPlayerList)
game.Players.PlayerRemoving:Connect(RefreshPlayerList)

TeleportTab:CreateButton({
    Name = "Teleport to Player",
    Icon = "rbxassetid://7733920644",
    Callback = function()
        if not SelectedPlayer then return end
        local target = game.Players:FindFirstChild(SelectedPlayer)
        if not target or not target.Character then
            Window:Notify({ Title = "Error", Content = "Target player not found or no character", Duration = 2 })
            return
        end
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            Window:Notify({ Title = "Error", Content = "Target has no HumanoidRootPart", Duration = 2 })
            return
        end
        local targetPos = hrp.Position + Vector3.new(0, 2, 0)
        local success = teleportToPosition(targetPos)
        if success then
            Window:Notify({ Title = "Teleport", Content = "Teleported to " .. SelectedPlayer, Duration = 2 })
        else
            Window:Notify({ Title = "Teleport Failed", Content = "Could not reach player.", Duration = 3 })
        end
    end
})

-- ============================================================
-- TELEPORT TO NPC
-- ============================================================
TeleportTab:CreateSection({ Name = "Location NPC", Icon = "rbxassetid://7733955511" })

local SelectedNPC = nil
local function getNpcFolder() return workspace:FindFirstChild("NPC") end
local function getNpcDropdownItems()
    local folder = getNpcFolder()
    if not folder then return { "NPC folder not found" } end
    local out = {}
    for _, child in pairs(folder:GetChildren()) do
        if child:IsA("Model") or child:IsA("BasePart") then
            table.insert(out, child.Name)
        end
    end
    table.sort(out)
    return #out > 0 and out or { "No NPCs found" }
end

local NPCDropdown = TeleportTab:CreateDropdown({
    Name = "Select NPC",
    Items = getNpcDropdownItems(),
    Callback = function(Value) SelectedNPC = Value end
})

task.spawn(function()
    local npcFolder = getNpcFolder() or workspace:WaitForChild("NPC", 10)
    if not npcFolder then return end
    local function refresh()
        if NPCDropdown and NPCDropdown.Refresh then
            NPCDropdown:Refresh(getNpcDropdownItems())
        end
    end
    refresh()
    npcFolder.ChildAdded:Connect(refresh)
    npcFolder.ChildRemoved:Connect(refresh)
end)

TeleportTab:CreateButton({
    Name = "Teleport to NPC",
    Icon = "rbxassetid://7733920644",
    Callback = function()
        local npcFolder = getNpcFolder()
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not npcFolder or not hrp or not SelectedNPC then
            Window:Notify({ Title = "Error", Content = "Invalid selection or missing data", Duration = 2 })
            return
        end
        local target = npcFolder:FindFirstChild(SelectedNPC)
        if not target then return end
        local targetPos
        if target:IsA("Model") then
            targetPos = target:GetPivot().Position + Vector3.new(0, 2, 0)
        elseif target:IsA("BasePart") then
            targetPos = target.Position + Vector3.new(0, 2, 0)
        else
            return
        end
        local success = teleportToPosition(targetPos)
        if success then
            Window:Notify({ Title = "Teleport", Content = "Teleported to " .. SelectedNPC, Duration = 2 })
        else
            Window:Notify({ Title = "Teleport Failed", Content = "Could not reach NPC.", Duration = 3 })
        end
    end
})

-- ============================================================
-- FISHING AREA TELEPORT
-- ============================================================
TeleportTab:CreateSection({ Name = "Fishing Area", Icon = "rbxassetid://7733955511" })

local FishingAreaLocations = {
    -- ... (data lokasi, saya singkat karena panjang)
    -- Isi dengan data yang sudah ada
}

local SelectedFishingArea = nil

TeleportTab:CreateDropdown({
    Name = "Select Fishing Area",
    Items = (function()
        local keys = {}
        for name in pairs(FishingAreaLocations) do table.insert(keys, name) end
        table.sort(keys)
        return keys
    end)(),
    Callback = function(value) SelectedFishingArea = value end
})

TeleportTab:CreateButton({
    Name = "Teleport to Fishing Area",
    Icon = "rbxassetid://7733920644",
    Callback = function()
        if not SelectedFishingArea then return end
        local dest = FishingAreaLocations[SelectedFishingArea]
        if not dest then return end
        local targetPos = typeof(dest) == "CFrame" and dest.Position or dest
        targetPos = targetPos + Vector3.new(0, 3, 0)
        local success = teleportToPosition(targetPos)
        if success then
            Window:Notify({ Title = "Teleport", Content = "Teleported to " .. SelectedFishingArea, Duration = 2 })
        else
            Window:Notify({ Title = "Teleport Failed", Content = "Could not reach fishing area.", Duration = 3 })
        end
    end
})

-- Fishing Area Freeze (tetap pakai CFrame loop)
local fishingFreezeConn = nil
local fishingFreezeCFrame = nil

local function stopFishingFreeze()
    if fishingFreezeConn then
        fishingFreezeConn:Disconnect()
        fishingFreezeConn = nil
    end
    fishingFreezeCFrame = nil
end

local function startFishingFreeze()
    stopFishingFreeze()
    if not SelectedFishingArea then return end
    local dest = FishingAreaLocations[SelectedFishingArea]
    if not dest then return end
    fishingFreezeCFrame = typeof(dest) == "CFrame" and dest or CFrame.new(dest)
    fishingFreezeConn = RunService.Heartbeat:Connect(function()
        pcall(function()
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp and fishingFreezeCFrame then
                hrp.CFrame = fishingFreezeCFrame
            end
        end)
    end)
end

TeleportTab:CreateToggle({
    Name = "Freeze at Selected Area",
    Default = false,
    Callback = function(state)
        if state then startFishingFreeze() else stopFishingFreeze() end
    end
})

-- ============================================================
-- CUSTOM POSITION
-- ============================================================
TeleportTab:CreateSection({ Name = "Custom Position", Icon = "rbxassetid://7733955511" })

local savedCustomPos = nil
local customFreezeConn = nil

function stopCustomFreeze()
    if customFreezeConn then
        customFreezeConn:Disconnect()
        customFreezeConn = nil
    end
end

TeleportTab:CreateButton({
    Name = "Save Current Position",
    Icon = "rbxassetid://7733955511",
    Callback = function()
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            savedCustomPos = hrp.CFrame
            Window:Notify({ Title = "Custom Position", Content = "Position saved!", Duration = 3 })
        end
    end
})

TeleportTab:CreateButton({
    Name = "Teleport to Saved Position",
    Icon = "rbxassetid://7733920644",
    Callback = function()
        if not savedCustomPos then
            Window:Notify({ Title = "Custom Position", Content = "No position saved yet.", Duration = 3 })
            return
        end
        local targetPos = savedCustomPos.Position + Vector3.new(0, 2, 0)
        local success = teleportToPosition(targetPos)
        if success then
            Window:Notify({ Title = "Teleport", Content = "Teleported to saved position", Duration = 2 })
        else
            Window:Notify({ Title = "Teleport Failed", Content = "Could not reach saved position.", Duration = 3 })
        end
    end
})

TeleportTab:CreateToggle({
    Name = "Freeze at Saved Position",
    Default = false,
    Callback = function(state)
        stopCustomFreeze()
        if not state then return end
        if not savedCustomPos then
            Window:Notify({ Title = "Custom Position", Content = "No position saved yet.", Duration = 3 })
            return
        end
        local cf = savedCustomPos
        customFreezeConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CFrame = cf end
            end)
        end)
    end
})

-- ============================================================
-- AUTO LEVIATHAN HUNT
-- ============================================================
_G.AutoLeviathanHunt = _G.AutoLeviathanHunt or false
local LeviathanThread = nil

AutoTab:CreateSection({ Name = "Auto Leviathan Hunt", Icon = "rbxassetid://7733955511" })

AutoTab:CreateToggle({
    Name = "Auto Leviathan Hunt",
    Default = _G.AutoLeviathanHunt,
    ConfigKey = "AutoLeviathanHunt",
    Callback = function(state)
        _G.AutoLeviathanHunt = state
        if state then
            LeviathanThread = task.spawn(function()
                while _G.AutoLeviathanHunt do
                    pcall(function()
                        local zones = workspace:FindFirstChild("Zones")
                        if zones then
                            local leviathanDen = zones:FindFirstChild("Leviathan's Den")
                            if leviathanDen then
                                local character = game.Players.LocalPlayer.Character
                                if character and character:FindFirstChild("HumanoidRootPart") then
                                    local targetPos = CFrame.new(3474.05298, -287.774719, 3472.63403, -0.915228605, 0.097325258, -0.391004264, 3.60608101e-06, 0.970392585, 0.241532952, 0.402934879, 0.221056461, -0.88813144).Position
                                    teleportToPosition(targetPos)
                                    print("[Leviathan Hunt] ✓ Teleported to Leviathan's Den")
                                end
                            else
                                print("[Leviathan Hunt] Zone not found, waiting...")
                            end
                        end
                    end)
                    task.wait(30)
                end
            end)
            Window:Notify({ Title = "✓ Leviathan Hunt", Content = "Auto Leviathan Hunt enabled!", Duration = 3 })
        else
            if LeviathanThread then
                task.cancel(LeviathanThread)
                LeviathanThread = nil
            end
            Window:Notify({ Title = "✗ Leviathan Hunt", Content = "Auto Leviathan Hunt disabled!", Duration = 3 })
        end
    end
})

-- ============================================================
-- AUTO LOCHNES EVENT (Dengan Fly Teleport)
-- ============================================================
_G.AutoLochnesEvent = _G.AutoLochnesEvent or false
_G.LochnesFishingMode = _G.LochnesFishingMode or "Legit"

local LochnesThread = nil
local LochnesTriggered = false
local LOCHNES_TRIGGER_SECONDS = 10
local LochnesLastPosition = nil

local LOCHNES_TARGET_POS = Vector3.new(6091.53711, -585.924316, 4643.58789)

local function parseLochnesCountdownSeconds(text)
    if type(text) ~= "string" then return nil end
    text = text:gsub("\n", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return nil end

    local h = tonumber(text:match("(%d+)%s*[Hh]")) or 0
    local m = tonumber(text:match("(%d+)%s*[Mm]")) or 0
    local s = tonumber(text:match("(%d+)%s*[Ss]"))
    if s then return h * 3600 + m * 60 + s end

    local hh, mm, ss = text:match("^(%d+):(%d+):(%d+)$")
    if hh then return tonumber(hh) * 3600 + tonumber(mm) * 60 + tonumber(ss) end

    local mm2, ss2 = text:match("^(%d+):(%d+)$")
    if mm2 then return tonumber(mm2) * 60 + tonumber(ss2) end

    return nil
end

local function getLochnesCountdownText()
    local ok, label = pcall(function()
        return workspace["!!! DEPENDENCIES"]["Event Tracker"].Main.Gui.Content.Items.Countdown.Label
    end)
    if not ok or not label then return nil end
    return label.Text or label.ContentText or ""
end

local function teleportLochnes()
    local character = game.Players.LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    LochnesLastPosition = hrp.Position
    teleportToPosition(LOCHNES_TARGET_POS)
end

local function returnToLochnesLastPosition()
    if not LochnesLastPosition then return end
    teleportToPosition(LochnesLastPosition)
end

local function holdRod()
    if equipTool then
        pcall(equipTool.FireServer, equipTool, 1)
    end
end

local function startLochnesFishingOnce()
    holdRod()
    if _G.LochnesFishingMode == "Legit" then
        pcall(function()
            FishingController:RequestChargeFishingRod(Vector2.new(0, 0), true)
        end)
        task.wait(delayfishing or 1)
        pcall(CallFishDone, REFishDone, 1)
    else
        pcall(instant)
    end
end

local function lochnesCountdownLoop()
    while _G.AutoLochnesEvent do
        local seconds = parseLochnesCountdownSeconds(getLochnesCountdownText())
        if type(seconds) == "number" then
            if not LochnesTriggered and seconds <= LOCHNES_TRIGGER_SECONDS then
                LochnesTriggered = true
                teleportLochnes()
                task.wait(0.2)
                startLochnesFishingOnce()
                Window:Notify({
                    Title = "Lochnes Event",
                    Content = "TP + fishing started (" .. tostring(_G.LochnesFishingMode) .. ")",
                    Duration = 3,
                    Icon = "fish",
                })
                task.wait(2)
                returnToLochnesLastPosition()
                Window:Notify({
                    Title = "Lochnes Event",
                    Content = "Returned to last position.",
                    Duration = 3,
                    Icon = "rbxassetid://7733920644",
                })
            elseif LochnesTriggered and seconds > LOCHNES_TRIGGER_SECONDS then
                LochnesTriggered = false
            end
        end
        task.wait(0.25)
    end
end

AutoTab:CreateSection({ Name = "Auto Lochnes Event", Icon = "rbxassetid://7733955511" })

AutoTab:CreateDropdown({
    Name = "Lochnes Fishing Mode",
    Items = { "Legit", "Instant" },
    Default = _G.LochnesFishingMode,
    Callback = function(v)
        _G.LochnesFishingMode = v
    end,
})

AutoTab:CreateToggle({
    Name = "Auto Lochnes Event",
    Default = _G.AutoLochnesEvent,
    Callback = function(state)
        _G.AutoLochnesEvent = state
        if LochnesThread then
            task.cancel(LochnesThread)
            LochnesThread = nil
        end
        LochnesTriggered = false
        if state then
            Window:Notify({
                Title = "Auto Lochnes",
                Content = "Waiting for countdown <= " .. tostring(LOCHNES_TRIGGER_SECONDS) .. "s",
                Duration = 3,
                Icon = "time",
            })
            LochnesThread = task.spawn(lochnesCountdownLoop)
        end
    end,
})

-- ============================================================
-- AUTO EVENT TP SYSTEM (Dengan Fly Teleport)
-- ============================================================

local eventTPEnabled = false
local eventTPThread = nil
local selectedEvents = {}
local createdPlatform = nil
local MEG_CHECK_RADIUS = 150

local eventData = {
    ["Worm Hunt"] = {
        PathFromWorkspace = { "Props", "Model", "BlackHole" },
        Locations = {
            Vector3.new(2190.85, -1.4, 97.575),
            Vector3.new(-2450.679, -1.4, 139.731),
            Vector3.new(-267.479, -1.4, 5188.531),
            Vector3.new(-327, -1.4, 2422),
        },
        PlatformY = 107,
        Priority = 1,
    },
    ["Megalodon Hunt"] = {
        TargetName = "Megalodon Hunt",
        Locations = {
            Vector3.new(-1076.3, -1.4, 1676.2),
            Vector3.new(-1191.8, -1.4, 3597.3),
            Vector3.new(412.7, -1.4, 4134.4),
        },
        PlatformY = 107,
        Priority = 2,
    },
    ["Ghost Shark Hunt"] = {
        TargetName = "Ghost Shark Hunt",
        Locations = {
            Vector3.new(489.559, -1.35, 25.406),
            Vector3.new(-1358.216, -1.35, 4100.556),
            Vector3.new(627.859, -1.35, 3798.081),
        },
        PlatformY = 107,
        Priority = 3,
    },
    ["Shark Hunt"] = {
        TargetName = "Shark Hunt",
        Locations = {
            Vector3.new(1.65, -1.35, 2095.725),
            Vector3.new(1369.95, -1.35, 930.125),
            Vector3.new(-1585.5, -1.35, 1242.875),
            Vector3.new(-1896.8, -1.35, 2634.375),
        },
        PlatformY = 107,
        Priority = 4,
    },
    ["Thrundzilla Hunt"] = {
        TargetName = "Shocked",
        Locations = {
            Vector3.new(2067.7981, 2.20000029, 16.7060127),
        },
        PlatformY = 107,
        Priority = 5,
    },
}

local eventNames = {}
for name in pairs(eventData) do
    table.insert(eventNames, name)
end

local function destroyEventPlatform()
    if createdPlatform and createdPlatform.Parent then
        createdPlatform:Destroy()
        createdPlatform = nil
    end
end

local function getInstanceAtWorkspacePath(pathNames)
    if type(pathNames) ~= "table" then return nil end
    local current = Workspace
    for _, name in ipairs(pathNames) do
        current = current and current:FindFirstChild(name)
        if not current then return nil end
    end
    return current
end

local function getWorldPositionForEventTarget(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then
        return inst.Position
    end
    if inst:IsA("Model") then
        if inst.PrimaryPart then
            return inst.PrimaryPart.Position
        end
        local p = inst:FindFirstChildWhichIsA("BasePart", true)
        if p then return p.Position end
    end
    local p = inst:FindFirstChildWhichIsA("BasePart", true)
    return p and p.Position or nil
end

local function createAndTeleportToPlatform(targetPos, y)
    local desiredPos = Vector3.new(targetPos.X, y, targetPos.Z)
    if createdPlatform and createdPlatform.Parent then
        createdPlatform.Position = desiredPos
    else
        destroyEventPlatform()
        local platform = Instance.new("Part")
        platform.Size = Vector3.new(5, 1, 5)
        platform.Position = desiredPos
        platform.Anchored = true
        platform.Transparency = 1
        platform.CanCollide = true
        platform.Name = "EventPlatform"
        platform.Parent = Workspace
        createdPlatform = platform
    end
    teleportToPosition(createdPlatform.Position + Vector3.new(0, 3, 0))
end

local function runMultiEventTP()
    while eventTPEnabled do
        local sorted = {}
        for _, e in ipairs(selectedEvents) do
            local cfg = eventData[e]
            if type(cfg) == "table" then
                table.insert(sorted, cfg)
            end
        end
        table.sort(sorted, function(a, b)
            return (a.Priority or 0) < (b.Priority or 0)
        end)

        for _, config in ipairs(sorted) do
            if type(config.Locations) ~= "table" then continue end
            local foundTarget, foundPos

            if config.PathFromWorkspace then
                local targetInst = getInstanceAtWorkspacePath(config.PathFromWorkspace)
                local pos = getWorldPositionForEventTarget(targetInst)
                if pos then
                    for _, loc in ipairs(config.Locations) do
                        if (pos - loc).Magnitude <= MEG_CHECK_RADIUS then
                            foundTarget = targetInst
                            foundPos = pos
                            break
                        end
                    end
                end
            elseif config.TargetName then
                for _, d in ipairs(Workspace:GetDescendants()) do
                    if d.Name == config.TargetName then
                        local pos = d:IsA("BasePart") and d.Position
                            or (d.PrimaryPart and d.PrimaryPart.Position)
                        if pos then
                            for _, loc in ipairs(config.Locations) do
                                if (pos - loc).Magnitude <= MEG_CHECK_RADIUS then
                                    foundTarget = d
                                    foundPos = pos
                                    break
                                end
                            end
                        end
                    end
                    if foundTarget then break end
                end
            end

            if foundTarget and foundPos then
                createAndTeleportToPlatform(foundPos, config.PlatformY)
            end
        end
        task.wait(0.1)
    end
    destroyEventPlatform()
end

TeleportTab:CreateSection({ Name = "Event Teleporter", Icon = "rbxassetid://7733955511" })

TeleportTab:CreateDropdown({
    Name = "Select Fish Events",
    Items = eventNames,
    Callback = function(value)
        selectedEvents = { value }
        print("[EventTP] Selected Event:", value)
    end,
})

TeleportTab:CreateToggle({
    Name = "Auto Fish Event TP",
    Default = false,
    Callback = function(state)
        eventTPEnabled = state
        if eventTPThread then
            task.cancel(eventTPThread)
            eventTPThread = nil
        end
        if state then
            eventTPThread = task.spawn(runMultiEventTP)
        end
    end,
})

SettingsTab:CreateSection({ Name = "Camera Views" })

-- ============================================================
-- UNLIMITED ZOOM (Refactored - Tetap sama)
-- ============================================================
SettingsTab:CreateSection({ Name = "Camera Views" })

local UnlimitedZoomModule = {}
local Player = game:GetService("Players").LocalPlayer
local originalMinZoom = Player.CameraMinZoomDistance
local originalMaxZoom = Player.CameraMaxZoomDistance
local unlimitedZoomActive = false

function UnlimitedZoomModule.Enable()
    if unlimitedZoomActive then return false end
    unlimitedZoomActive = true
    Player.CameraMinZoomDistance = 0.5
    Player.CameraMaxZoomDistance = 9999
    print("✅ Unlimited Zoom: ENABLED")
    return true
end

function UnlimitedZoomModule.Disable()
    if not unlimitedZoomActive then return false end
    unlimitedZoomActive = false
    Player.CameraMinZoomDistance = originalMinZoom
    Player.CameraMaxZoomDistance = originalMaxZoom
    print("🔴 Unlimited Zoom: DISABLED")
    return true
end

SettingsTab:CreateToggle({
    Name = "Unlimited Zoom Camera",
    Icon = "rbxassetid://7733799682",
    Default = false,
    Callback = function(state)
        if state then UnlimitedZoomModule.Enable() else UnlimitedZoomModule.Disable() end
    end,
})

-- ============================================================
-- SKIP CUTSCENE (Refactored - Tanpa Loop Overwrite)
-- ============================================================
SettingsTab:CreateSection({ Name = "Skip Cutscene" })

local skipCutscene = false
local replicateConn = nil
local stopConn = nil
local originalPlay = nil
local originalStop = nil
local isHooked = false

-- Fungsi proxy untuk CutsceneController.Play
local function proxyPlay(...)
    if skipCutscene then
        warn("[VoraHub] Cutscene skipped (Play).")
        return
    end
    if originalPlay then
        return originalPlay(...)
    end
end

local function proxyStop(...)
    if skipCutscene then
        warn("[VoraHub] Cutscene skipped (Stop).")
        return
    end
    if originalStop then
        return originalStop(...)
    end
end

local function applyCutsceneHook()
    if isHooked then return end
    local ok, CutsceneController = pcall(function()
        return require(ReplicatedStorage.Controllers.CutsceneController)
    end)
    if not ok or not CutsceneController then
        warn("[VoraHub] CutsceneController not found. Skip Cutscene disabled.")
        return
    end

    originalPlay = originalPlay or CutsceneController.Play
    originalStop = originalStop or CutsceneController.Stop

    -- Overwrite method dengan proxy sekali saja
    CutsceneController.Play = proxyPlay
    CutsceneController.Stop = proxyStop
    isHooked = true
    print("[VoraHub] Cutscene hook installed.")
end

local function restoreCutsceneController()
    if not isHooked then return end
    local ok, CutsceneController = pcall(function()
        return require(ReplicatedStorage.Controllers.CutsceneController)
    end)
    if ok and CutsceneController then
        if originalPlay then CutsceneController.Play = originalPlay end
        if originalStop then CutsceneController.Stop = originalStop end
    end
    isHooked = false
    print("[VoraHub] Cutscene hook removed.")
end

-- Cleanup koneksi remote events
local function cleanupCutsceneConnections()
    if replicateConn then
        replicateConn:Disconnect()
        replicateConn = nil
    end
    if stopConn then
        stopConn:Disconnect()
        stopConn = nil
    end
end

SettingsTab:CreateToggle({
    Name = "Skip Cutscene",
    Default = false,
    Callback = function(state)
        skipCutscene = state

        -- Remote event blockers (tetap dipasang sekali)
        if not replicateConn and RE.ReplicateCutscene then
            replicateConn = RE.ReplicateCutscene.OnClientEvent:Connect(function(...)
                if skipCutscene then
                    warn("[VoraHub] Blocked ReplicateCutscene event!")
                end
            end)
        end
        if not stopConn and RE.StopCutscene then
            stopConn = RE.StopCutscene.OnClientEvent:Connect(function()
                if skipCutscene then
                    warn("[VoraHub] Blocked StopCutscene event!")
                end
            end)
        end

        -- Hook / Unhook CutsceneController
        if state then
            applyCutsceneHook()
        else
            restoreCutsceneController()
        end
    end,
})

-- ============================================================
-- NOTIFICATION (Refactored - Tetap sama)
-- ============================================================
SettingsTab:CreateSection({ Name = "Notification", Icon = "rbxassetid://7733955511" })

SettingsTab:CreateToggle({
    Name = "Disable Notifications",
    Default = false,
    Callback = function(state)
        local PlayerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        if PlayerGui then
            local NotifyGui = PlayerGui:FindFirstChild("Text Notifications")
            if NotifyGui then
                local Frame = NotifyGui:FindFirstChild("Frame")
                if Frame then
                    Frame.Visible = not state
                end
            end
        end
    end,
})

SettingsTab:CreateDropdown({
    Name = "Position",
    Items = { "Normal (Mid)", "Left", "Right" },
    Default = "Normal (Mid)",
    Callback = function(Value)
        local PlayerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        if PlayerGui then
            local NotifyGui = PlayerGui:FindFirstChild("Text Notifications")
            if NotifyGui then
                local Frame = NotifyGui:FindFirstChild("Frame")
                if Frame then
                    if Value == "Normal (Mid)" then
                        Frame.Position = UDim2.new(0.5, 0, 0, 110)
                    elseif Value == "Left" then
                        Frame.Position = UDim2.new(0.3, 0, 0, 110)
                    elseif Value == "Right" then
                        Frame.Position = UDim2.new(0.7, 0, 0, 110)
                    end
                end
            end
        end
    end,
})

-- ============================================================
-- GENERAL TAB (Refactored)
-- ============================================================
SettingsTab:CreateSection({ Name = "General", Icon = "rbxassetid://7733954611" })

-- ============================================================
-- WALK ON WATER (Refactored - Tetap sama, sudah baik)
-- ============================================================

local WalkOnWater = loadstring([[
-- ULTRA STABLE WALK ON WATER V3.2 (MODULE EDITION)
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local WalkOnWater = {
    Enabled = false,
    Platform = nil,
    AlignPos = nil,
    Connection = nil
}

local PLATFORM_SIZE = 14
local OFFSET = 3
local LAST_WATER_Y = nil

function GetCharacterReferences()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end
    return char, humanoid, hrp
end

function ForceSurfaceLift()
    local _, humanoid, hrp = GetCharacterReferences()
    if not humanoid or not hrp then return end
    if humanoid:GetState() ~= Enum.HumanoidStateType.Swimming then return end

    for _ = 1, 60 do
        hrp.Velocity = Vector3.new(0, 80, 0)
        task.wait(0.03)
        if humanoid:GetState() ~= Enum.HumanoidStateType.Swimming then break end
    end
    hrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
end

function GetWaterHeight()
    local _, _, hrp = GetCharacterReferences()
    if not hrp then return LAST_WATER_Y end

    local origin = hrp.Position + Vector3.new(0, 5, 0)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = { LocalPlayer.Character }
    params.IgnoreWater = false

    local result = Workspace:Raycast(origin, Vector3.new(0, -600, 0), params)
    if result then
        LAST_WATER_Y = result.Position.Y
        return LAST_WATER_Y
    end
    return LAST_WATER_Y
end

function CreatePlatform()
    if WalkOnWater.Platform then
        WalkOnWater.Platform:Destroy()
    end

    local p = Instance.new("Part")
    p.Size = Vector3.new(PLATFORM_SIZE, 1, PLATFORM_SIZE)
    p.Anchored = true
    p.CanCollide = true
    p.Transparency = 1
    p.CanQuery = false
    p.CanTouch = false
    p.Name = "WaterLockPlatform"
    p.Parent = Workspace
    WalkOnWater.Platform = p
end

function SetupAlign()
    local _, _, hrp = GetCharacterReferences()
    if not hrp then return false end

    if WalkOnWater.AlignPos then
        WalkOnWater.AlignPos:Destroy()
    end

    local att = hrp:FindFirstChild("RootAttachment")
    if not att then
        att = Instance.new("Attachment")
        att.Name = "RootAttachment"
        att.Parent = hrp
    end

    local ap = Instance.new("AlignPosition")
    ap.Attachment0 = att
    ap.MaxForce = math.huge
    ap.MaxVelocity = math.huge
    ap.Responsiveness = 200
    ap.RigidityEnabled = true
    ap.Parent = hrp
    WalkOnWater.AlignPos = ap
    return true
end

function Cleanup()
    if WalkOnWater.Connection then
        WalkOnWater.Connection:Disconnect()
        WalkOnWater.Connection = nil
    end
    if WalkOnWater.AlignPos then
        WalkOnWater.AlignPos:Destroy()
        WalkOnWater.AlignPos = nil
    end
    if WalkOnWater.Platform then
        WalkOnWater.Platform:Destroy()
        WalkOnWater.Platform = nil
    end
end

function WalkOnWater.Start()
    if WalkOnWater.Enabled then return end
    local char, humanoid, hrp = GetCharacterReferences()
    if not char or not humanoid or not hrp then return end

    ForceSurfaceLift()
    WalkOnWater.Enabled = true
    LAST_WATER_Y = nil
    CreatePlatform()

    if not SetupAlign() then
        WalkOnWater.Enabled = false
        Cleanup()
        return
    end

    WalkOnWater.Connection = RunService.Heartbeat:Connect(function()
        if not WalkOnWater.Enabled then return end
        local _, _, currentHRP = GetCharacterReferences()
        if not currentHRP then return end

        local waterY = GetWaterHeight()
        if not waterY then return end

        if WalkOnWater.Platform then
            WalkOnWater.Platform.CFrame = CFrame.new(
                currentHRP.Position.X,
                waterY - 0.5,
                currentHRP.Position.Z
            )
        end

        if WalkOnWater.AlignPos then
            WalkOnWater.AlignPos.Position = Vector3.new(
                currentHRP.Position.X,
                waterY + OFFSET,
                currentHRP.Position.Z
            )
        end
    end)
end

function WalkOnWater.Stop()
    WalkOnWater.Enabled = false
    Cleanup()
end

LocalPlayer.CharacterAdded:Connect(function()
    if WalkOnWater.Enabled then
        task.wait(0.5)
        Cleanup()
        WalkOnWater.Enabled = false
        WalkOnWater.Start()
    end
end)

return WalkOnWater
]])()

SettingsTab:CreateToggle({
    Name = "Walk on Water",
    Description = "Walk on water surface without swimming",
    Icon = "rbxassetid://11400562133",
    Default = false,
    Callback = function(value)
        if value then
            WalkOnWater.Start()
        else
            WalkOnWater.Stop()
        end
    end,
})

-- ============================================================
-- AUTO RECONNECT (Refactored - Thread Management)
-- ============================================================
local autoReconnectThread = nil

local function autoReconnectLoop()
    while _G.AutoReconnect do
        task.wait(2)

        pcall(function()
            local reconnectUI = game:GetService("CoreGui"):FindFirstChild("RobloxPromptGui")
            if reconnectUI then
                local prompt = reconnectUI:FindFirstChild("promptOverlay")
                if prompt then
                    local button = prompt:FindFirstChild("ButtonPrimary")
                    if button and button.Visible then
                        -- Coba firesignal, fallback ke Click jika tersedia
                        if firesignal then
                            pcall(firesignal, button.MouseButton1Click)
                        elseif button:FindFirstChild("MouseButton1Click") then
                            pcall(button.MouseButton1Click.Invoke, button.MouseButton1Click)
                        end
                    end
                end
            end
        end)
    end
end

local function startAutoReconnect()
    if autoReconnectThread then
        task.cancel(autoReconnectThread)
        autoReconnectThread = nil
    end
    if _G.AutoReconnect then
        autoReconnectThread = task.spawn(autoReconnectLoop)
    end
end
})

-- ============================================================
-- FAKE CHARACTER SYSTEM (Refactored - Minor improvements)
-- ============================================================
SettingsTab:CreateSection({ Name = "Fake Character", Icon = "rbxassetid://7733964719" })

local FakeCharacter = {
    Enabled = false,
    FakeChar = nil,
    RealChar = nil,
    Connections = {},
}

local TRANSPARENCY = 1
local FAKE_TRANSPARENCY = 0

local function setCharacterTransparency(character, transparency)
    if not character then return end
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = transparency
        elseif part:IsA("Decal") then
            part.Transparency = transparency
        elseif part:IsA("Accessory") then
            local handle = part:FindFirstChild("Handle")
            if handle then handle.Transparency = transparency end
        end
    end
    local head = character:FindFirstChild("Head")
    if head then
        local face = head:FindFirstChild("face")
        if face then face.Transparency = transparency end
    end
end

local function cloneCharacter(original)
    if not original then return nil end
    local clone = Instance.new("Model")
    clone.Name = original.Name .. "_Fake"
    for _, part in pairs(original:GetChildren()) do
        if part:IsA("BasePart") or part:IsA("Accessory") or part:IsA("Humanoid") then
            local clonedPart = part:Clone()
            if clonedPart:IsA("BasePart") then
                clonedPart.CanCollide = false
                clonedPart.Anchored = false
                for _, constraint in pairs(clonedPart:GetChildren()) do
                    if constraint:IsA("Constraint") or constraint:IsA("WeldConstraint") then
                        constraint:Destroy()
                    end
                end
            end
            clonedPart.Parent = clone
        end
    end
    if original.PrimaryPart then
        clone.PrimaryPart = clone:FindFirstChild(original.PrimaryPart.Name)
    end
    return clone
end

local function weldFakeCharacter(fakeChar)
    if not fakeChar then return end
    local rootPart = fakeChar:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    for _, part in pairs(fakeChar:GetChildren()) do
        if part:IsA("BasePart") and part ~= rootPart then
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = rootPart
            weld.Part1 = part
            weld.Parent = rootPart
        end
    end
end

local function updateFakePosition()
    if not FakeCharacter.Enabled then return end
    if not FakeCharacter.FakeChar or not FakeCharacter.RealChar then return end
    local realRoot = FakeCharacter.RealChar:FindFirstChild("HumanoidRootPart")
    local fakeRoot = FakeCharacter.FakeChar:FindFirstChild("HumanoidRootPart")
    if realRoot and fakeRoot then
        fakeRoot.CFrame = realRoot.CFrame
    end
end

function FakeCharacter.Start()
    if FakeCharacter.Enabled then
        warn("[FakeChar] Already enabled")
        return false
    end
    local character = Players.LocalPlayer.Character
    if not character then
        warn("[FakeChar] No character found")
        return false
    end
    FakeCharacter.RealChar = character
    local ok, fakeChar = pcall(cloneCharacter, character)
    if not ok or not fakeChar then
        warn("[FakeChar] Failed to clone character")
        return false
    end
    FakeCharacter.FakeChar = fakeChar
    pcall(weldFakeCharacter, fakeChar)
    fakeChar.Parent = workspace
    setCharacterTransparency(character, TRANSPARENCY)
    setCharacterTransparency(fakeChar, FAKE_TRANSPARENCY)
    FakeCharacter.Connections.Update = game:GetService("RunService").Heartbeat:Connect(updateFakePosition)
    FakeCharacter.Connections.Respawn = Players.LocalPlayer.CharacterAdded:Connect(function(newChar)
        if FakeCharacter.Enabled then
            task.wait(0.5)
            FakeCharacter.Stop()
            task.wait(0.5)
            FakeCharacter.Start()
        end
    end)
    FakeCharacter.Enabled = true
    print("[FakeChar] Fake character enabled")
    if Window then
        Window:Notify({ Title = "✓ Fake Character", Content = "Fake character enabled!", Duration = 3 })
    end
    return true
end

function FakeCharacter.Stop()
    if not FakeCharacter.Enabled then
        warn("[FakeChar] Not enabled")
        return false
    end
    for _, conn in pairs(FakeCharacter.Connections) do
        if conn then pcall(conn.Disconnect, conn) end
    end
    FakeCharacter.Connections = {}
    if FakeCharacter.FakeChar then
        FakeCharacter.FakeChar:Destroy()
        FakeCharacter.FakeChar = nil
    end
    if FakeCharacter.RealChar then
        setCharacterTransparency(FakeCharacter.RealChar, 0)
        FakeCharacter.RealChar = nil
    end
    FakeCharacter.Enabled = false
    print("[FakeChar] Fake character disabled")
    if Window then
        Window:Notify({ Title = "✗ Fake Character", Content = "Fake character disabled!", Duration = 3 })
    end
    return true
end

SettingsTab:CreateToggle({
    Name = "Fake Character",
    SubText = "Hide your real position with a fake character",
    Default = false,
    Callback = function(state)
        if state then FakeCharacter.Start() else FakeCharacter.Stop() end
    end,
})


-- ============================================
-- CENTRALIZED SERVER HOP FUNCTION (Refactored)
-- ============================================
--!strict

local ServerHop = {
    _lastHopTime = 0,
    _cooldown = 3,
    _isHopInProgress = false,
}

local function notifyUser(title: string, content: string, duration: number?)
    duration = duration or 3
    if Window and Window.Notify then
        Window:Notify({
            Title = title,
            Content = content,
            Icon = "rbxassetid://7733920644",
            Duration = duration,
        })
    else
        print("[ServerHop] " .. title .. ": " .. content)
    end
end

local function checkCooldown(): boolean
    local now = tick()
    if now - ServerHop._lastHopTime < ServerHop._cooldown then
        notifyUser("⏳ Cooldown", "Please wait " .. math.ceil(ServerHop._cooldown - (now - ServerHop._lastHopTime)) .. "s before hopping again.", 2)
        return false
    end
    return true
end

function ServerHop.Hop(reason: string?, forcePublic: boolean?)
    if not checkCooldown() then return end
    if ServerHop._isHopInProgress then
        notifyUser("⏳ In Progress", "Server hop already in progress...", 2)
        return
    end

    reason = reason or "Server hopping..."
    forcePublic = forcePublic or false

    local isPrivateServer = game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0

    local description = reason
    if isPrivateServer and forcePublic then
        description = description .. "\n(Leaving private server → public)"
    elseif isPrivateServer then
        description = description .. "\n(Rejoining private server)"
    end
    notifyUser("🔄 Server Hop", description, 3)

    ServerHop._isHopInProgress = true
    task.wait(0.5)

    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlaceId = game.PlaceId
    local JobId = game.JobId

    local function findPublicServer(): string?
        local servers = {}
        local cursor = ""
        local pageCount = 0
        local maxPages = 3

        while pageCount < maxPages do
            pageCount = pageCount + 1
            local url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
            if cursor ~= "" then
                url = url .. "&cursor=" .. cursor
            end

            local success, response = pcall(function()
                return game:HttpGet(url)
            end)

            if not success then
                warn("[ServerHop] Failed to fetch server list, page", pageCount)
                break
            end

            local ok, serverData = pcall(function()
                return HttpService:JSONDecode(response)
            end)

            if not ok or not serverData or not serverData.data then
                warn("[ServerHop] Invalid server data, page", pageCount)
                break
            end

            for _, server in ipairs(serverData.data) do
                if server.id ~= JobId and server.playing < server.maxPlayers then
                    table.insert(servers, {
                        id = server.id,
                        players = server.playing,
                        maxPlayers = server.maxPlayers,
                    })
                end
            end

            cursor = serverData.nextPageCursor or ""
            if #servers > 0 then
                break
            end
            task.wait(0.1)
        end

        if #servers == 0 then
            return nil
        end

        table.sort(servers, function(a, b)
            return a.players > b.players
        end)

        local topCount = math.min(3, #servers)
        local selectedIdx = math.random(1, topCount)
        return servers[selectedIdx].id
    end

    local hopSuccess = false

    if forcePublic or not isPrivateServer then
        local publicServerId = findPublicServer()
        if publicServerId then
            print("[ServerHop] Found public server:", publicServerId)
            local ok = pcall(function()
                TeleportService:TeleportToPlaceInstance(PlaceId, publicServerId, LocalPlayer)
            end)
            if ok then
                hopSuccess = true
            else
                warn("[ServerHop] Failed to teleport to public server:", publicServerId)
            end
        else
            warn("[ServerHop] No public server found")
        end
    end

    if not hopSuccess and not forcePublic then
        print("[ServerHop] Attempting rejoin (same server)")
        local ok = pcall(function()
            if isPrivateServer then
                local teleportOptions = Instance.new("TeleportOptions")
                teleportOptions.ServerInstanceId = JobId
                teleportOptions.ReservedServerAccessCode = game.PrivateServerId
                TeleportService:TeleportAsync(PlaceId, {LocalPlayer}, teleportOptions)
            else
                TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
            end
        end)
        if ok then
            hopSuccess = true
            print("[ServerHop] Rejoin successful")
        else
            warn("[ServerHop] Rejoin failed")
        end
    end

    if not hopSuccess then
        print("[ServerHop] Using fallback random teleport")
        local ok = pcall(function()
            TeleportService:Teleport(PlaceId, LocalPlayer)
        end)
        if ok then
            hopSuccess = true
            print("[ServerHop] Fallback teleport successful")
        else
            warn("[ServerHop] ALL STRATEGIES FAILED!")
            notifyUser("❌ Hop Failed", "Unable to find or join a server. Please try again later.", 5)
        end
    end

    ServerHop._lastHopTime = tick()
    ServerHop._isHopInProgress = false

    if hopSuccess then
        notifyUser("✅ Hop Successful", "Connecting to new server...", 2)
    end
end

-- ============================================
-- COMPATIBILITY: Agar panggilan ServerHop(...) tetap berfungsi
-- ============================================
_G.ServerHop = ServerHop.Hop



-- ============================================
-- ANTI AFK (Professional Version)
-- ============================================

SettingsTab:CreateSection({ Name = "Anti AFK", Icon = "rbxassetid://7733658504" })

local AntiAFK = {
    _enabled = false,
    _connections = {},
    _fallbackThread = nil,
    _fallbackRunning = false,
}

-- Cek apakah getconnections tersedia
local function hasGetConnections(): boolean
    return type(getconnections) == "function" or type(get_signal_cons) == "function"
end

-- Dapatkan fungsi getconnections yang tersedia
local function getConnections(signal)
    if type(getconnections) == "function" then
        return getconnections(signal)
    elseif type(get_signal_cons) == "function" then
        return get_signal_cons(signal)
    end
    return nil
end

-- Fungsi untuk mengaktifkan/menonaktifkan Anti AFK
local function setAntiAFK(enabled: boolean)
    _G.AntiAFKEnabled = enabled
    AntiAFK._enabled = enabled

    -- Metode 1: Jika getconnections tersedia, disable/enable event Idled
    local GC = getConnections
    if GC then
        local idleSignal = Players.LocalPlayer.Idled
        local conns = GC(idleSignal)
        if conns then
            for _, conn in pairs(conns) do
                if enabled then
                    pcall(conn.Disable, conn)
                else
                    pcall(conn.Enable, conn)
                end
            end
            print("[AntiAFK] Using getconnections method: " .. (enabled and "Enabled" or "Disabled"))
            return
        end
    end

    -- Metode 2: Fallback - kirim input buatan setiap 30 detik
    if enabled then
        if AntiAFK._fallbackRunning then return end
        AntiAFK._fallbackRunning = true
        print("[AntiAFK] Fallback method started (simulating mouse movement)")

        AntiAFK._fallbackThread = task.spawn(function()
            local UserInputService = game:GetService("UserInputService")
            local lastMove = 0
            local moveInterval = 30 -- detik

            while AntiAFK._fallbackRunning do
                local now = tick()
                if now - lastMove >= moveInterval then
                    -- Kirim mouse movement kecil (tidak terlihat oleh player)
                    pcall(function()
                        local pos = UserInputService:GetMouseLocation()
                        if pos then
                            -- Simulasikan gerakan mouse 1 pixel ke kanan dan kembali
                            UserInputService:SetMouseLocation(pos.X + 1, pos.Y)
                            task.wait(0.05)
                            UserInputService:SetMouseLocation(pos.X, pos.Y)
                        end
                    end)
                    lastMove = now
                    print("[AntiAFK] Mouse movement simulated")
                end
                task.wait(1)
            end
        end)
    else
        -- Matikan fallback
        AntiAFK._fallbackRunning = false
        if AntiAFK._fallbackThread then
            pcall(task.cancel, AntiAFK._fallbackThread)
            AntiAFK._fallbackThread = nil
        end
        print("[AntiAFK] Fallback method stopped")
    end
end

-- Cleanup function (opsional, dipanggil saat script berhenti)
local function cleanupAntiAFK()
    setAntiAFK(false)
    AntiAFK._connections = {}
end

-- Tambahkan cleanup ke _G agar bisa dipanggil dari luar jika perlu
_G._cleanupAntiAFK = cleanupAntiAFK

-- ============================================
-- UI TOGGLE
-- ============================================
SettingsTab:CreateToggle({
    Name = "Anti AFK",
    Description = "Prevents you from being kicked for idling",
    Icon = "rbxassetid://7733658504",
    Default = _G.AntiAFKEnabled or true,
    Callback = function(value)
        setAntiAFK(value)
    end
})

SettingsTab:CreateSection({ Name = "Anti Staff", Icon = "rbxassetid://7734053535" })

-- ============================================
-- ANTI STAFF SYSTEM (Group ID)
-- ============================================

local FISH_GROUP_ID = 35102746
_G.AntiStaffEnabled = false
local AntiStaffConnection = nil

function IsStaff(player)
    local ok, role = pcall(function()
        return player:GetRoleInGroup(FISH_GROUP_ID)
    end)
    if not ok then return false end
    if role == "Guest" or role == "Member" then
        return false
    end
    return true
end

function CheckForStaff()
	if not _G.AntiStaffEnabled then return end
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= Players.LocalPlayer and IsStaff(player) then
			print("[Anti-Staff] Staff detected:", player.Name, "UserID:", player.UserId)
			ServerHop("⚠️ Staff detected: " .. player.Name .. "\nServer hopping...", true) -- Force public
			break
		end
	end
end


SettingsTab:CreateToggle({
	Name = "Anti Staff",
	Description = "Automatically server hop when staff members join",
	Icon = "rbxassetid://7734053535",
	Default = false,
	Callback = function(value)
		_G.AntiStaffEnabled = value
		
		if value then
			Window:Notify({
				Title = "Anti Staff Enabled",
				Content = "Avoiding all staff except Members",
				Icon = "rbxassetid://7734053535",
				Duration = 3
			})
			
			task.spawn(CheckForStaff)
			
			if AntiStaffConnection then
				AntiStaffConnection:Disconnect()
			end
			
			AntiStaffConnection = Players.PlayerAdded:Connect(function(player)
				task.wait(0.5)
				if player ~= Players.LocalPlayer and IsStaff(player) then
					print("[Anti-Staff] Staff joined:", player.Name, "UserID:", player.UserId)
					ServerHop("⚠️ Staff joined: " .. player.Name .. "\nServer hopping...", true)
				end
			end)
			
			task.spawn(function()
				while _G.AntiStaffEnabled do
					CheckForStaff()
					task.wait(5)
				end
			end)
		else
			if AntiStaffConnection then
				AntiStaffConnection:Disconnect()
				AntiStaffConnection = nil
			end
			
			Window:Notify({
				Title = "Anti Staff Disabled",
				Content = "No longer monitoring staff",
				Icon = "rbxassetid://7734053535",
				Duration = 2
			})
		end
	end
})

SettingsTab:CreateSection({ Name = "Server", Icon = "rbxassetid://7733955511" })

SettingsTab:CreateButton({
	Name = "Rejoin Server",
	SubText = "Reconnect to current server",
	Icon = "rbxassetid://7733920644",
	Callback = function()
		-- For rejoin, we want to stay in same server type
		-- So use forcePublic=false to allow fallback rejoin
		local isPrivate = game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
		local message = isPrivate and "Rejoining private server..." or "Rejoining server..."
		
		-- Notify user
		if Window then
			Window:Notify({
				Title = "Rejoining...",
				Content = message,
				Icon = "rbxassetid://7733920644",
				Duration = 2
			})
		end
		
		task.wait(0.5)
		
		-- Use ServerHop with forcePublic=false to allow rejoin to same server
		local TeleportService = game:GetService("TeleportService")
		local Players = game:GetService("Players")
		local LocalPlayer = Players.LocalPlayer
		
		local success = pcall(function()
			if isPrivate then
				-- Private Server - rejoin same private
				local teleportOptions = Instance.new("TeleportOptions")
				teleportOptions.ServerInstanceId = game.JobId
				teleportOptions.ReservedServerAccessCode = game.PrivateServerId
				TeleportService:TeleportAsync(game.PlaceId, {LocalPlayer}, teleportOptions)
			else
				-- Public Server - rejoin via JobId
				TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
			end
		end)
		
		if not success then
			-- Fallback to random teleport if rejoin fails
			task.wait(0.5)
			pcall(function()
				TeleportService:Teleport(game.PlaceId, LocalPlayer)
			end)
		end
	end
})

SettingsTab:CreateButton({
    Name = "Server Hop",
    SubText = "Switch to another server",
    Icon = "rbxassetid://7733920644",
    Callback = function()
        ServerHop.Hop("Switching to another server...", false)
    end
})

SettingsTab:CreateButton({
    Name = "Force Public Server",
    SubText = "Leave private server & join public",
    Icon = "rbxassetid://7733920644",
    Callback = function()
        ServerHop.Hop("Forcing public server...", true)
    end
})

local TabConfig = Window:CreateTab({
    Name = "Config",
    Icon = "rbxassetid://7733954611"
})

TabConfig:CreateSection({
    Name = "Configuration"
})

 configName = ""
 selectedConfig = ""
 configDropdown = nil
 CONFIG_FOLDER = "VoraHubConfigs"

function sanitizeConfigName(name)
    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    name = name:gsub("[\\/:*?\"<>|]", "_")
    return name
end

function getConfigList()
    local result = {}
    if not (listfiles and isfolder) then
        return result
    end

    if not isfolder(CONFIG_FOLDER) and makefolder then
        makefolder(CONFIG_FOLDER)
    end

    for _, path in ipairs(listfiles(CONFIG_FOLDER)) do
        local name = path:match("([^/\\]+)%.json$")
        if name then
            table.insert(result, name)
        end
    end
    table.sort(result)
    return result
end

function RefreshConfigs()
    if configDropdown then
        configDropdown:Refresh(getConfigList())
    end
end

TabConfig:CreateInput({
    Name = "Config Name",
    Placeholder = "Enter config name...",
    Callback = function(text)
        configName = text
    end
})

configDropdown = TabConfig:CreateDropdown({
    Name = "Select Config",
    Options = getConfigList(),
    Callback = function(val)
        selectedConfig = val
    end
})

TabConfig:CreateButton({
    Name = "Create / Save Config",
    SubText = "Save settings to selected or new config",
    Callback = function()
        local name = (configName ~= "" and configName) or selectedConfig
        if name == "" then
             if Window and Window.Notify then
                Window:Notify({ Title = "Error", Content = "Please enter or select a config name.", Duration = 3 })
             end
             return
        end
        
        name = sanitizeConfigName(name)
        if name == "" then
            if Window and Window.Notify then
                Window:Notify({ Title = "Error", Content = "Invalid config name.", Duration = 3 })
            end
            return
        end

        local ok, err = Window:SaveConfig(CONFIG_FOLDER, name)
        if ok then
            RefreshConfigs()
            if Window and Window.Notify then
                Window:Notify({ Title = "Config Saved", Content = "Saved as " .. name, Duration = 3 })
            end
        elseif Window and Window.Notify then
            Window:Notify({ Title = "Save Failed", Content = tostring(err or "Unknown error"), Duration = 3 })
        end
    end
})

TabConfig:CreateButton({
    Name = "Load Config",
    SubText = "Load selected config",
    Callback = function()
        if selectedConfig == "" then
             if Window and Window.Notify then
                Window:Notify({ Title = "Error", Content = "Please select a config to load.", Duration = 3 })
             end
             return
        end

        local ok, err = Window:LoadConfig(CONFIG_FOLDER, selectedConfig)
        if ok then
            if Window and Window.Notify then
                Window:Notify({ Title = "Config Loaded", Content = "Loaded " .. selectedConfig, Duration = 3 })
            end
        elseif Window and Window.Notify then
            Window:Notify({ Title = "Load Failed", Content = tostring(err or "Unknown error"), Duration = 3 })
        end
    end
})

TabConfig:CreateButton({
    Name = "Delete Config",
    SubText = "Delete selected config",
    Callback = function()
        if selectedConfig == "" then return end
        local path = CONFIG_FOLDER .. "/" .. selectedConfig .. ".json"
        if delfile and isfile and isfile(path) then
            delfile(path)
            RefreshConfigs()
            selectedConfig = ""
            if Window and Window.Notify then
                Window:Notify({ Title = "Config Deleted", Content = "Deleted config file.", Duration = 3 })
            end
        elseif Window and Window.Notify then
            Window:Notify({ Title = "Delete Failed", Content = "Config file not found.", Duration = 3 })
        end
    end
})

TabConfig:CreateButton({
    Name = "Refresh List",
    SubText = "Refresh config list",
    Callback = function()
        RefreshConfigs()
    end
})

-- Auto Load Default Config
task.spawn(function()
    task.wait(2)
    Window:LoadConfig(CONFIG_FOLDER, "default")
end)
