--!strict
-- RemoteManager.lua - Mengelola semua koneksi remote net (RF/RE)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CONFIG = {
    PACKAGE_PATH = { "Packages", "_Index", "sleitnick_net@0.2.0" },
    NET_FOLDER = "net",
    PREFIX_PATTERN = "^R[FE]/",
    MIN_HASH_LEN = 16,
}

local RemoteManager = {
    _map = nil,
    _built = false,
    _cache = {},
}

-- Helper: Cek apakah nama adalah hash hex
local function isHex(name: string): boolean
    local stripped = name:sub(4)
    return #stripped > CONFIG.MIN_HASH_LEN and stripped:match("^%x+$") ~= nil
end

-- Build map dari folder net (Lazy Loading)
local function buildRemoteMap(): { [string]: Instance }
    local current = ReplicatedStorage
    for _, key in ipairs(CONFIG.PACKAGE_PATH) do
        current = current:FindFirstChild(key)
        if not current then
            warn("[RemoteManager] Path tidak ditemukan: " .. key)
            return {}
        end
    end
    local netFolder = current:FindFirstChild(CONFIG.NET_FOLDER)
    if not netFolder then
        warn("[RemoteManager] Folder 'net' tidak ditemukan")
        return {}
    end

    local children = netFolder:GetChildren()
    local map = {}
    for i = 1, #children - 1 do
        local cur = children[i]
        local nxt = children[i + 1]
        if not isHex(cur.Name) and isHex(nxt.Name) then
            local key = cur.Name:gsub(CONFIG.PREFIX_PATTERN, "")
            map[key] = nxt
        end
    end
    return map
end

-- Dapatkan map (cache, build sekali)
local function getMap(): { [string]: Instance }
    if not RemoteManager._built then
        RemoteManager._map = buildRemoteMap()
        RemoteManager._built = true
    end
    return RemoteManager._map or {}
end

-- ============================================
-- PUBLIC API
-- ============================================

function RemoteManager.getRemote(name: string): Instance?
    local map = getMap()
    return map[name]
end

function RemoteManager.fireServer(name: string, ...): boolean
    local remote = getMap()[name]
    if remote and remote:IsA("RemoteEvent") then
        pcall(function() remote:FireServer(...) end)
        return true
    end
    return false
end

function RemoteManager.invokeServer(name: string, ...)
    local remote = getMap()[name]
    if remote and remote:IsA("RemoteFunction") then
        local ok, result = pcall(function() return remote:InvokeServer(...) end)
        return ok and result or nil
    end
    return nil
end

function RemoteManager.callServer(name: string, ...)
    local remote = getMap()[name]
    if not remote then return false, nil end
    if remote:IsA("RemoteEvent") then
        pcall(function() remote:FireServer(...) end)
        return true, nil
    elseif remote:IsA("RemoteFunction") then
        local ok, result = pcall(function() return remote:InvokeServer(...) end)
        return ok, ok and result or nil
    end
    return false, nil
end

function RemoteManager.hookClientEvent(name: string, callback: (...any) -> ())
    local remote = getMap()[name]
    if not remote or not remote:IsA("RemoteEvent") then return nil end
    return remote.OnClientEvent:Connect(callback)
end

function RemoteManager.getRemoteMap(): { [string]: Instance }
    return getMap()
end

-- Untuk kompatibilitas dengan kode lama (RF/RE)
function RemoteManager.RF(name) return RemoteManager.getRemote(name) end
function RemoteManager.RE(name) return RemoteManager.getRemote(name) end

return RemoteManager