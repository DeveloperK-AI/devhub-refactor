-- Loader.lua (Debug Version)
print("[Loader] ========================================")
print("[Loader] devHub Refactored - Starting...")
print("[Loader] ========================================")

local BASE_URL = "https://raw.githubusercontent.com/DeveloperK-AI/devhub-refactor/main/Modules/"

-- Fungsi untuk memuat module dengan error handling dan logging
local function loadModule(name)
    print("[Loader] 📦 Loading module: " .. name)
    local url = BASE_URL .. name .. ".lua"
    print("[Loader]    URL: " .. url)
    
    local success, result = pcall(function()
        local content = game:HttpGet(url)
        print("[Loader]    Content length: " .. #content .. " bytes")
        local fn = loadstring(content)
        if not fn then
            error("loadstring returned nil for " .. name)
        end
        return fn()
    end)
    
    if not success then
        warn("[Loader] ❌ Failed to load " .. name .. ": " .. tostring(result))
        return nil
    end
    
    print("[Loader] ✅ " .. name .. " loaded successfully")
    return result
end

-- 1. Load State
print("[Loader] Step 1: Loading State...")
local State = loadModule("State")
if not State then error("[Loader] CRITICAL: State is nil!") end

-- 2. Load RemoteManager
print("[Loader] Step 2: Loading RemoteManager...")
local RemoteManager = loadModule("RemoteManager")
if not RemoteManager then error("[Loader] CRITICAL: RemoteManager is nil!") end

-- 3. Load Utils
print("[Loader] Step 3: Loading Utils...")
local Utils = loadModule("Utils")
if not Utils then error("[Loader] CRITICAL: Utils is nil!") end

-- 4. Load FishingCore
print("[Loader] Step 4: Loading FishingCore...")
local FishingCore = loadModule("FishingCore")
if not FishingCore then error("[Loader] CRITICAL: FishingCore is nil!") end

-- 5. Load QuestManager
print("[Loader] Step 5: Loading QuestManager...")
local QuestManager = loadModule("QuestManager")
if not QuestManager then error("[Loader] CRITICAL: QuestManager is nil!") end

-- 6. Load AutoFeatures
print("[Loader] Step 6: Loading AutoFeatures...")
local AutoFeatures = loadModule("AutoFeatures")
if not AutoFeatures then error("[Loader] CRITICAL: AutoFeatures is nil!") end

-- 7. Load UIManager
print("[Loader] Step 7: Loading UIManager...")
local UIManager = loadModule("UIManager")
if not UIManager then error("[Loader] CRITICAL: UIManager is nil!") end

print("[Loader] ✅ All modules loaded successfully!")
print("[Loader] ========================================")

-- Inisialisasi Core
_G.Core = {
    State = State,
    Remote = RemoteManager,
    Utils = Utils,
    Fishing = FishingCore,
    Quest = QuestManager,
    Auto = AutoFeatures,
    UI = nil,
}

print("[Loader] Injecting dependencies...")
FishingCore:Init(State, RemoteManager, Utils)
QuestManager:Init(State, RemoteManager, Utils)
AutoFeatures:Init(State, RemoteManager, Utils)
UIManager:Init(State, RemoteManager, Utils, FishingCore, QuestManager, AutoFeatures)

print("[Loader] Building UI...")
UIManager:Build()
print("[Loader] UI build completed!")

print("[Loader] Starting Quest loops...")
QuestManager:startQuestLoops()
print("[Loader] ✅ devHub Refactored is ready!")
print("[Loader] ========================================")
