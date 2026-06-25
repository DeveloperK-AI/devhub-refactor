print("[Loader] ========================================")
print("[Loader] devHub Refactored - Starting...")
print("[Loader] ========================================")

-- === CEK FUNGSI DASAR ===
print("[Loader] Step 0: Testing game:HttpGet...")
local testContent = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/DeveloperK-AI/devhub-refactor/main/Modules/State.lua")
end)
if testContent then
    print("[Loader] ✅ game:HttpGet works!")
else
    warn("[Loader] ❌ game:HttpGet FAILED!")
    return
end

-- === URL CONFIG ===
local BASE_URL = "https://raw.githubusercontent.com/DeveloperK-AI/devhub-refactor/main/Modules/"

-- === FUNGSI LOAD MODULE ===
function loadModule(name)
    print("[Loader] 📦 Loading: " .. name)
    local url = BASE_URL .. name .. ".lua"
    print("[Loader]    URL: " .. url)
    
    local success, content = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success then
        warn("[Loader] ❌ HttpGet failed for " .. name .. ": " .. tostring(content))
        return nil
    end
    
    print("[Loader]    Content length: " .. #content .. " bytes")
    
    local fn, err = loadstring(content)
    if not fn then
        warn("[Loader] ❌ loadstring failed for " .. name .. ": " .. tostring(err))
        return nil
    end
    
    local ok, result = pcall(fn)
    if not ok then
        warn("[Loader] ❌ Execution failed for " .. name .. ": " .. tostring(result))
        return nil
    end
    
    print("[Loader] ✅ " .. name .. " loaded!")
    return result
end

-- === MULAI LOAD SEMUA MODUL ===
print("[Loader] Step 1: Loading State...")
local State = loadModule("State")
if not State then 
    warn("[Loader] CRITICAL: State is nil! STOPPING.")
    return 
end
print("[Loader] State contents:", State)

print("[Loader] Step 2: Loading RemoteManager...")
local RemoteManager = loadModule("RemoteManager")
if not RemoteManager then 
    warn("[Loader] CRITICAL: RemoteManager is nil! STOPPING.")
    return 
end

print("[Loader] Step 3: Loading Utils...")
local Utils = loadModule("Utils")
if not Utils then 
    warn("[Loader] CRITICAL: Utils is nil! STOPPING.")
    return 
end

print("[Loader] Step 4: Loading FishingCore...")
local FishingCore = loadModule("FishingCore")
if not FishingCore then 
    warn("[Loader] CRITICAL: FishingCore is nil! STOPPING.")
    return 
end

print("[Loader] Step 5: Loading QuestManager...")
local QuestManager = loadModule("QuestManager")
if not QuestManager then 
    warn("[Loader] CRITICAL: QuestManager is nil! STOPPING.")
    return 
end

print("[Loader] Step 6: Loading AutoFeatures...")
local AutoFeatures = loadModule("AutoFeatures")
if not AutoFeatures then 
    warn("[Loader] CRITICAL: AutoFeatures is nil! STOPPING.")
    return 
end

print("[Loader] Step 7: Loading UIManager...")
local UIManager = loadModule("UIManager")
if not UIManager then 
    warn("[Loader] CRITICAL: UIManager is nil! STOPPING.")
    return 
end

print("[Loader] ========================================")
print("[Loader] ✅ SEMUA MODUL BERHASIL DIMUAT!")
print("[Loader] ========================================")

-- === INJECT DEPENDENCIES ===
print("[Loader] Injecting dependencies...")
local ok, err = pcall(function()
    FishingCore:Init(State, RemoteManager, Utils)
    QuestManager:Init(State, RemoteManager, Utils)
    AutoFeatures:Init(State, RemoteManager, Utils)
    UIManager:Init(State, RemoteManager, Utils, FishingCore, QuestManager, AutoFeatures)
end)
if not ok then
    warn("[Loader] ❌ Failed to inject dependencies: " .. tostring(err))
    return
end

-- === BUILD UI ===
print("[Loader] Building UI...")
local buildOk, buildErr = pcall(function()
    UIManager:Build()
end)
if not buildOk then
    warn("[Loader] ❌ UI Build failed: " .. tostring(buildErr))
    return
end

print("[Loader] ✅ UI build complete!")

-- === START LOOPS ===
print("[Loader] Starting Quest loops...")
local loopOk, loopErr = pcall(function()
    QuestManager:startQuestLoops()
end)
if not loopOk then
    warn("[Loader] ❌ Quest loops failed: " .. tostring(loopErr))
end

print("[Loader] ========================================")
print("[Loader] ✅ devHub Refactored READY!")
print("[Loader] ========================================")
