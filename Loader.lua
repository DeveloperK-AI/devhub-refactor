--!strict
-- Loader.lua - Entry point utama. Memuat semua modul dari GitHub dan menjalankan aplikasi.

local BASE_URL = "https://raw.githubusercontent.com/DeveloperK-AI/devhub-refactor/main/Modules/"

-- Fungsi untuk memuat module dengan error handling
local function loadModule(name: string)
    local url = BASE_URL .. name .. ".lua"
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if not ok then
        warn("[Loader] Gagal memuat module: " .. name .. " | Error: " .. tostring(result))
        return nil
    end
    return result
end

-- 1. Load semua modul
local State = loadModule("State")
local RemoteManager = loadModule("RemoteManager")
local Utils = loadModule("Utils")
local FishingCore = loadModule("FishingCore")
local QuestManager = loadModule("QuestManager")
local AutoFeatures = loadModule("AutoFeatures")
local UIManager = loadModule("UIManager")

if not (State and RemoteManager and Utils and FishingCore and QuestManager and AutoFeatures and UIManager) then
    error("[Loader] Gagal memuat satu atau lebih modul. Periksa koneksi internet dan URL GitHub.")
end

-- 2. Inisialisasi Core Global
_G.Core = {
    State = State,
    Remote = RemoteManager,
    Utils = Utils,
    Fishing = FishingCore,
    Quest = QuestManager,
    Auto = AutoFeatures,
    UI = nil, -- akan diisi oleh UIManager
}

-- 3. Inject dependencies ke setiap modul
FishingCore:Init(State, RemoteManager, Utils)
QuestManager:Init(State, RemoteManager, Utils)
AutoFeatures:Init(State, RemoteManager, Utils)
UIManager:Init(State, RemoteManager, Utils, FishingCore, QuestManager, AutoFeatures)

-- 4. Build UI
UIManager:Build()

-- 5. Jalankan background loops
-- Quest loop
QuestManager:startQuestLoops()

-- Webhook detection loop (jika diperlukan)
task.spawn(function()
    local knownFish = {}
    while true do
        task.wait(2)
        pcall(function()
            local Replion = require(game:GetService("ReplicatedStorage").Packages.Replion)
            local Data = Replion.Client:WaitReplion("Data")
            local fish = Data:GetExpect({ "Inventory", "Fish" }) or {}
            for _, f in ipairs(fish) do
                if f.UUID and not knownFish[f.UUID] then
                    knownFish[f.UUID] = true
                    -- Kirim webhook jika diinginkan
                    -- pcall(function() Utils.sendWebhook(f) end)
                end
            end
        end)
    end
end)

-- Keep Alive untuk AutoFarm (jika quest mode aktif)
task.spawn(function()
    while true do
        task.wait(2.5)
        local state = State
        if state.DeepSeaQuestMode or state.ElementQuestMode or state.DiamondQuestMode then
            pcall(function()
                RemoteManager.fireServer("UpdateAutoFishingState", true)
            end)
        end
    end
end)

print("[Loader] devHub Refactored berhasil dimuat!")
