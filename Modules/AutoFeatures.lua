--!strict
-- AutoFeatures.lua - Auto Sell, Enchant, Totem, Crystal, Lochnes, Leviathan

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local AutoFeatures = {}

-- ============================================
-- DEPENDENCIES
-- ============================================
AutoFeatures._State = nil
AutoFeatures._Remote = nil
AutoFeatures._Utils = nil

function AutoFeatures:Init(State, Remote, Utils)
    self._State = State
    self._Remote = Remote
    self._Utils = Utils
end

-- ============================================
-- AUTO SELL (By Delay or By Count)
-- ============================================
AutoFeatures._autoSellThread = nil
AutoFeatures._autoSellMode = "Sell Delay"
AutoFeatures._autoSellValue = 0

function AutoFeatures:startAutoSell(mode: string, value: number)
    self._autoSellMode = mode
    self._autoSellValue = value
    self._State.AutoSell = true
    self._autoSellThread = task.spawn(function()
        while self._State.AutoSell do
            if mode == "Sell Delay" and value > 0 then
                self._Remote.fireServer("SellAllItems")
                task.wait(value)
            elseif mode == "Sell By Count" and value > 0 then
                local currentCount = 0
                pcall(function()
                    local label = LocalPlayer.PlayerGui.Inventory.Main.Top.Options.Fish.Label.BagSize
                    currentCount = tonumber(string.match(label.ContentText, "^(%d+)")) or 0
                end)
                if currentCount >= value then
                    self._Remote.fireServer("SellAllItems")
                    task.wait(0.3)
                end
                task.wait(0.1)
            else
                break
            end
        end
    end)
end

function AutoFeatures:stopAutoSell()
    self._State.AutoSell = false
    if self._autoSellThread then
        pcall(task.cancel, self._autoSellThread)
        self._autoSellThread = nil
    end
end

-- ============================================
-- AUTO ENCHANT
-- ============================================
AutoFeatures._enchantThread = nil
local STONE_IDS = { ["Enchant Stones"] = 10, ["Evolved Enchant Stone"] = 558 }
local ENCHANT_MAP = {
    ["Big Hunter 1"] = 3, ["Cursed 1"] = 12, ["Empowered 1"] = 9,
    ["Glistening 1"] = 1, ["Gold Digger 1"] = 4, ["Leprechaun 1"] = 5,
    ["Leprechaun 2"] = 6, ["Mutation Hunter 1"] = 7, ["Mutation Hunter 2"] = 14,
    ["Prismatic 1"] = 13, ["Reeler 1"] = 2, ["Stargazer 1"] = 8,
    ["Stormhunter 1"] = 11, ["XPerienced 1"] = 10,
    ["SECRET Hunter"] = 16, ["Shark Hunter"] = 20, ["Stargazer II"] = 17,
    ["Stormhunter II"] = 19, ["Mutation Hunter III"] = 22, ["Fairy Hunter 1"] = 15,
}

function AutoFeatures:startAutoEnchant()
    self._State.AutoEnchant = true
    self._enchantThread = task.spawn(function()
        while self._State.AutoEnchant do
            pcall(function()
                local remote = self._Remote
                local state = self._State
                local targetEnchant = state.SelectedStoneType == "Evolved Enchant Stone" 
                    and "SECRET Hunter" or "Big Hunter 1" -- default fallback
                local targetId = ENCHANT_MAP[targetEnchant]
                if not targetId then return end
                
                -- Cek enchant saat ini
                local currentEnchant = nil
                pcall(function()
                    local equip = require(game:GetService("ReplicatedStorage").Packages.Replion).Client:WaitReplion("Data"):Get("EquippedItems")
                    local rods = require(...).Client:WaitReplion("Data"):GetExpect({ "Inventory", "Fishing Rods" })
                    for _, uuid in pairs(equip or {}) do
                        for _, rod in ipairs(rods or {}) do
                            if rod.UUID == uuid and rod.Metadata and rod.Metadata.EnchantId then
                                currentEnchant = rod.Metadata.EnchantId
                            end
                        end
                    end
                end)
                if currentEnchant == targetId then
                    self._State.AutoEnchant = false
                    return
                end
                
                -- Cari stone
                local stoneUUID = nil
                local inv = require(game:GetService("ReplicatedStorage").Packages.Replion).Client:WaitReplion("Data"):GetExpect({ "Inventory", "Items" })
                for _, item in ipairs(inv or {}) do
                    if item.Id == STONE_IDS[state.SelectedStoneType] then
                        stoneUUID = item.UUID
                        break
                    end
                end
                if not stoneUUID then
                    task.wait(2)
                    return
                end
                
                remote.fireServer("EquipItem", stoneUUID, "Enchant Stones")
                task.wait(1)
                remote.fireServer("EquipToolFromHotbar", 1)
                task.wait(1)
                remote.fireServer("ActivateEnchantingAltar")
                task.wait(5)
            end)
            task.wait(1)
        end
    end)
end

function AutoFeatures:stopAutoEnchant()
    self._State.AutoEnchant = false
    if self._enchantThread then
        pcall(task.cancel, self._enchantThread)
        self._enchantThread = nil
    end
end

-- ============================================
-- AUTO TOTEM (Single & 3 Mix)
-- ============================================
AutoFeatures._totemThread = nil
local TOTEM_DATA = {
    ["Luck Totem"] = {Id = 1, Duration = 3601},
    ["Mutation Totem"] = {Id = 2, Duration = 3601},
    ["Shiny Totem"] = {Id = 3, Duration = 3601},
}

function AutoFeatures:startAutoTotem(totemName: string)
    self._State.AutoBuyTotem = true
    self._totemThread = task.spawn(function()
        while self._State.AutoBuyTotem do
            pcall(function()
                local remote = self._Remote
                local uuid = nil
                local inv = require(game:GetService("ReplicatedStorage").Packages.Replion).Client:WaitReplion("Data"):GetExpect({ "Inventory", "Totems" })
                for _, item in ipairs(inv or {}) do
                    if item.Id == TOTEM_DATA[totemName].Id then
                        uuid = item.UUID
                        break
                    end
                end
                if uuid then
                    remote.fireServer("SpawnTotem", uuid)
                    task.wait(0.5)
                    remote.fireServer("EquipToolFromHotbar", 1)
                end
            end)
            task.wait(2)
        end
    end)
end

function AutoFeatures:stopAutoTotem()
    self._State.AutoBuyTotem = false
    if self._totemThread then
        pcall(task.cancel, self._totemThread)
        self._totemThread = nil
    end
end

return AutoFeatures
