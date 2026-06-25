--!strict
-- State.lua - Single source of truth untuk semua konfigurasi dan toggle

local State = {
    -- === AUTO FARMING ===
    AutoFarm = false,
    AutoRod = false,
    AutoSell = false,
    AutoCatch = false,
    AutoReconnect = false,
    
    -- === PLAYER ===
    InfiniteJump = false,
    Noclip = false,
    Radar = false,
    AntiAFK = true,
    DivingGear = false,
    FreezeCharacter = false,
    
    -- === FISHING MODES ===
    Amblatant = false,
    BlatantMode = false,
    InstantFishingV2Active = false,
    CurrentFishingMode = "Instant", -- "Instant" | "Legit"
    
    -- === QUEST ===
    DeepSeaQuestMode = false,
    ElementQuestMode = false,
    DiamondQuestMode = false,
    AutoDeepSeaQuest = false,
    AutoElementQuest = false,
    AutoDiamondQuest = false,
    AutoCreateTranscendedStones = false,
    AutoTempleLever = false,
    
    -- === AUTO FEATURES ===
    AutoBuyTotem = false,
    AutoLeviathanHunt = false,
    AutoLochnesEvent = false,
    AutoCrystal = false,
    AutoEnchant = false,
    AutoOpenPirateChest = false,
    AntiStaffEnabled = false,
    KaitunGUIForce = false,
    
    -- === ULTRA BLATANT SETTINGS ===
    UB = {
        Active = false,
        Settings = {
            CompleteDelay = 3.7,
            CancelDelay = 0.2,
            CastMode = "Fast", -- "Perfect" | "Fast" | "Random"
        },
        Stats = {
            castCount = 0,
            startTime = 0,
        }
    },
    
    -- === AMBLATANT SAVED DATA ===
    SavedData = {
        FishCaught = {},
        CaughtVisual = {},
        FishNotif = {},
    },
    
    -- === MISC ===
    HasTeleported = false,
    HookNotif = false, -- Untuk durasi notifikasi
    FreezeCharacter = false,
}

return State