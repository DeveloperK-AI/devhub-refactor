--!strict
-- Utils.lua - Fungsi-fungsi utilitas umum (Webhook, FPS, Teleport, ServerHop, dll.)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Utils = {}

-- === SAFE EXECUTION ===
function Utils.safeCall(func: () -> ()): boolean
    local ok, err = pcall(func)
    if not ok then
        warn("[Utils] Error in safeCall:", err)
    end
    return ok
end

function Utils.safeSpawn(func: () -> ())
    task.spawn(function()
        Utils.safeCall(func)
    end)
end

-- === SERVER HOP (Dengan fallback) ===
function Utils.serverHop(reason: string?, forcePublic: boolean?)
    reason = reason or "Server hopping..."
    forcePublic = forcePublic or false
    
    local TeleportService = game:GetService("TeleportService")
    
    -- Notifikasi (jika UI tersedia)
    pcall(function()
        if _G.Core and _G.Core.UI then
            _G.Core.UI:Notify({ Title = "🔄 Server Hop", Content = reason, Duration = 3 })
        end
    end)
    
    task.wait(0.5)
    
    local success, err = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
        local response = game:HttpGet(url)
        local serverList = HttpService:JSONDecode(response)
        
        if serverList and serverList.data then
            for _, server in ipairs(serverList.data) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                    return true
                end
            end
        end
        return false
    end)
    
    if not success or not err then
        -- Fallback
        pcall(function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)
    end
end

-- === CENSOR NAME ===
function Utils.censorName(name: string?): string
    if not name or type(name) ~= "string" or #name < 1 then return "N/A" end
    if #name <= 3 then return name end
    local prefix = name:sub(1, 3)
    return prefix .. string.rep("*", #name - 3)
end

-- === SHORTEN NUMBER (K, M, B, T) ===
function Utils.shortenNumber(n: number): string
    if type(n) ~= "number" then return "N/A" end
    if n < 1000 then return tostring(math.floor(n)) end
    local scales = {
        { 1e18, "Qi" }, { 1e15, "Qa" }, { 1e12, "T" },
        { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" }
    }
    for _, scale in ipairs(scales) do
        if n >= scale[1] then
            local val = n / scale[1]
            return (val % 1 == 0 and string.format("%.0f%s", val, scale[2])) or string.format("%.2f%s", val, scale[2])
        end
    end
    return tostring(n)
end

-- === GET PLAYER COINS (Dari Replion Data) ===
function Utils.getCoins(): number
    local ok, data = pcall(function()
        local Replion = require(game:GetService("ReplicatedStorage").Packages.Replion)
        return Replion.Client:WaitReplion("Data"):Get("Coins")
    end)
    return (ok and data) or 0
end

-- === GET ROD UUID ===
function Utils.getRodUUID(rodId: number): string?
    local ok, inv = pcall(function()
        local Replion = require(game:GetService("ReplicatedStorage").Packages.Replion)
        return Replion.Client:WaitReplion("Data"):GetExpect({ "Inventory", "Fishing Rods" })
    end)
    if not ok or not inv then return nil end
    for _, rod in ipairs(inv) do
        if rod.Id == rodId then return rod.UUID end
    end
    return nil
end

-- === FPS BOOSTER ===
local FPSBooster = { Enabled = false, _connections = {} }

function FPSBooster.Enable()
    if FPSBooster.Enabled then return false end
    FPSBooster.Enabled = true
    
    -- Matikan Shadow & Fog
    Lighting.GlobalShadows = false
    Lighting.FogStart = 0
    Lighting.FogEnd = 1000000
    
    -- Matikan Water Wave
    local Terrain = Workspace:FindFirstChildOfClass("Terrain")
    if Terrain then
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
    end
    
    -- Set Render Quality
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    
    -- Hook untuk object baru
    FPSBooster._connections.descAdded = Workspace.DescendantAdded:Connect(function(obj)
        if not FPSBooster.Enabled then return end
        task.wait(0.1)
        pcall(function()
            if obj:IsA("BasePart") then obj.Reflectance = 0; obj.CastShadow = false end
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then obj.Enabled = false end
            if obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then obj.Enabled = false end
        end)
    end)
    
    return true
end

function FPSBooster.Disable()
    FPSBooster.Enabled = false
    if FPSBooster._connections.descAdded then
        FPSBooster._connections.descAdded:Disconnect()
        FPSBooster._connections.descAdded = nil
    end
    settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    return true
end

Utils.FPSBooster = FPSBooster

-- === WALK ON WATER ===
local WalkOnWater = { Enabled = false, Platform = nil, AlignPos = nil, Connection = nil }

function WalkOnWater.Start()
    if WalkOnWater.Enabled then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    WalkOnWater.Enabled = true
    
    -- Buat platform invisible
    local platform = Instance.new("Part")
    platform.Size = Vector3.new(14, 1, 14)
    platform.Anchored = true
    platform.CanCollide = true
    platform.Transparency = 1
    platform.Name = "WaterLockPlatform"
    platform.Parent = Workspace
    WalkOnWater.Platform = platform
    
    -- AlignPosition untuk mengapung
    local att = hrp:FindFirstChild("RootAttachment") or Instance.new("Attachment", hrp)
    att.Name = "RootAttachment"
    local align = Instance.new("AlignPosition")
    align.Attachment0 = att
    align.MaxForce = math.huge
    align.MaxVelocity = math.huge
    align.Responsiveness = 200
    align.RigidityEnabled = true
    align.Parent = hrp
    WalkOnWater.AlignPos = align
    
    WalkOnWater.Connection = RunService.Heartbeat:Connect(function()
        if not WalkOnWater.Enabled then return end
        local currentHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not currentHRP then return end
        
        -- Raycast untuk mencari permukaan air
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = { LocalPlayer.Character }
        params.IgnoreWater = false
        
        local result = Workspace:Raycast(currentHRP.Position + Vector3.new(0, 10, 0), Vector3.new(0, -600, 0), params)
        if result then
            local waterY = result.Position.Y
            WalkOnWater.Platform.CFrame = CFrame.new(currentHRP.Position.X, waterY - 0.5, currentHRP.Position.Z)
            WalkOnWater.AlignPos.Position = Vector3.new(currentHRP.Position.X, waterY + 3, currentHRP.Position.Z)
        end
    end)
end

function WalkOnWater.Stop()
    WalkOnWater.Enabled = false
    if WalkOnWater.Connection then WalkOnWater.Connection:Disconnect(); WalkOnWater.Connection = nil end
    if WalkOnWater.Platform then WalkOnWater.Platform:Destroy(); WalkOnWater.Platform = nil end
    if WalkOnWater.AlignPos then WalkOnWater.AlignPos:Destroy(); WalkOnWater.AlignPos = nil end
end

Utils.WalkOnWater = WalkOnWater

return Utils