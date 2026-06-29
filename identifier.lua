--!strict
-- IdentityManager.lua - Mengelola disguise karakter dan obfuskasi teks
-- Version: 1.0.0

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local IdentityManager = {
    _config = nil,
    _connections = {},
    _isActive = false,
}

-- ============================================
-- CONFIGURATION
-- ============================================
function IdentityManager:Init(config: table)
    self._config = config or {
        Headless = false,
        FakeDisplayName = "AmySchumer",
        FakeName = "redmiint8",
        FakeId = 13886182,
    }
end

-- ============================================
-- PRIVATE HELPERS
-- ============================================
local function getLocalPlayer(): Player
    return Players.LocalPlayer
end

local function safeWaitForChild(parent: Instance, name: string, timeout: number?): Instance?
    timeout = timeout or 5
    local start = tick()
    while tick() - start < timeout do
        local child = parent:FindFirstChild(name)
        if child then return child end
        task.wait(0.1)
    end
    return nil
end

-- ============================================
-- DISGUISE CHARACTER
-- ============================================
function IdentityManager:_disguiseCharacter(char: Model?, id: number)
    if not char then return end
    
    local success, err = pcall(function()
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        
        local head = char:FindFirstChild("Head")
        if not head then return end
        
        -- Get description dengan timeout
        local desc = nil
        local attempts = 0
        local maxAttempts = 10
        
        while attempts < maxAttempts do
            local ok, result = pcall(function()
                return Players:GetHumanoidDescriptionFromUserId(id)
            end)
            if ok and result then
                desc = result
                break
            end
            attempts = attempts + 1
            task.wait(1)
        end
        
        if not desc then
            warn("[IdentityManager] Failed to get description for user:", id)
            return
        end
        
        -- Preserve height scale
        local humDesc = hum:FindFirstChild("HumanoidDescription")
        if humDesc then
            desc.HeightScale = humDesc.HeightScale
        end
        
        char.Archivable = true
        
        -- Clone character for disguise
        local disguiseClone = char:Clone()
        disguiseClone.Name = "disguisechar"
        disguiseClone.Parent = Workspace
        
        -- Remove existing accessories from clone
        for _, child in pairs(disguiseClone:GetChildren()) do
            if child:IsA("Accessory") or child:IsA("ShirtGraphic") or 
               child:IsA("Shirt") or child:IsA("Pants") then
                child:Destroy()
            end
        end
        
        -- Apply new description
        disguiseClone.Humanoid:ApplyDescriptionClientServer(desc)
        
        -- Remove original accessories
        for _, child in pairs(char:GetChildren()) do
            local isAccessory = child:IsA("Accessory") and 
                child:GetAttribute("InvItem") == nil and 
                child:GetAttribute("ArmorSlot") == nil
            if isAccessory or child:IsA("ShirtGraphic") or 
               child:IsA("Shirt") or child:IsA("Pants") or 
               child:IsA("BodyColors") then
                child.Parent = game
            end
        end
        
        -- Block new accessories from being added
        local childAddedConn = char.ChildAdded:Connect(function(child)
            local isAccessory = child:IsA("Accessory") and 
                child:GetAttribute("InvItem") == nil and 
                child:GetAttribute("ArmorSlot") == nil
            if (isAccessory or child:IsA("ShirtGraphic") or 
                child:IsA("Shirt") or child:IsA("Pants") or 
                child:IsA("BodyColors")) and 
                child:GetAttribute("Disguise") == nil then
                child.Parent = game
            end
        end)
        table.insert(self._connections, childAddedConn)
        
        -- Transfer animations
local animateClone = disguiseClone:FindFirstChild("Animate")
local animateReal = char:FindFirstChild("Animate")  -- ✅ Aman, tidak nil
if animateClone and animateReal then
    for _, child in pairs(animateClone:GetChildren()) do
        child:SetAttribute("Disguise", true)
        local real = animateReal:FindFirstChild(child.Name)
        if child:IsA("StringValue") and real then
            real.Parent = game
            child.Parent = animateReal
        end
    end
end
        
        -- Transfer accessories with welds
        for _, child in pairs(disguiseClone:GetChildren()) do
            child:SetAttribute("Disguise", true)
            
            if child:IsA("Accessory") then
                -- Fix welds
                for _, weld in pairs(child:GetDescendants()) do
                    if weld:IsA("Weld") and weld.Part1 then
                        weld.Part1 = char:FindFirstChild(weld.Part1.Name)
                    end
                end
                child.Parent = char
            elseif child:IsA("ShirtGraphic") or child:IsA("Shirt") or 
                   child:IsA("Pants") or child:IsA("BodyColors") then
                child.Parent = char
            elseif child.Name == "Head" then
                local mesh = child:FindFirstChildOfClass("SpecialMesh")
                if mesh then
                    local targetMesh = char.Head:FindFirstChildOfClass("SpecialMesh")
                    if targetMesh then
                        targetMesh.MeshId = mesh.MeshId
                    end
                end
            end
        end
        
        -- Transfer face
        local localFace = char:FindFirstChild("face", true)
        local cloneFace = disguiseClone:FindFirstChild("face", true)
        if localFace and cloneFace then
            localFace.Parent = game
            cloneFace.Parent = char.Head
        end
        
        -- Transfer emotes
        local humDesc2 = char.Humanoid:FindFirstChild("HumanoidDescription")
        if humDesc2 then
            humDesc2:SetEmotes(desc:GetEmotes())
            humDesc2:SetEquippedEmotes(desc:GetEquippedEmotes())
        end
        
        disguiseClone:Destroy()
        print("[IdentityManager] Disguise applied successfully")
    end)
    
    if not success then
        warn("[IdentityManager] Disguise failed:", err)
    end
end

-- ============================================
-- TEXT PROCESSING
-- ============================================
function IdentityManager:_processText(text: string?): string
    if not text or type(text) ~= "string" then return "" end
    
    local config = self._config
    local lp = getLocalPlayer()
    local oldName = lp.Name
    local oldUserId = tostring(lp.UserId)
    local oldDisplayName = lp.DisplayName
    
    -- Cache gsub results
    local result = text
    
    if config.FakeName and oldName ~= config.FakeName then
        local replaced = string.gsub(result, oldName, config.FakeName)
        if replaced ~= result then
            result = replaced
        end
    end
    
    if config.FakeId and oldUserId ~= config.FakeId then
        local replaced = string.gsub(result, oldUserId, tostring(config.FakeId))
        if replaced ~= result then
            result = replaced
        end
    end
    
    if config.FakeDisplayName and oldDisplayName ~= config.FakeDisplayName then
        local replaced = string.gsub(result, oldDisplayName, config.FakeDisplayName)
        if replaced ~= result then
            result = replaced
        end
    end
    
    return result
end

-- ============================================
-- UI TEXT OBFUSCATION
-- ============================================
function IdentityManager:_obfuscateUI()
    local targetGui = CoreGui  -- Gunakan CoreGui saja, bukan seluruh game
    
    local function processDescendant(descendant: Instance)
        if descendant:IsA("TextBox") or descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
            local oldText = descendant.Text
            local newText = self:_processText(oldText)
            if newText ~= oldText then
                descendant.Text = newText
            end
            
            local oldName = descendant.Name
            local newName = self:_processText(oldName)
            if newName ~= oldName then
                descendant.Name = newName
            end
            
            -- Simpan connection untuk cleanup
            local conn = descendant:GetAttribute("_textHook")
            if conn then
                pcall(conn.Disconnect, conn)
            end
            
            local newConn = descendant.Changed:Connect(function(property)
                if property == "Text" then
                    local currentText = descendant.Text
                    local processed = self:_processText(currentText)
                    if processed ~= currentText then
                        descendant.Text = processed
                    end
                elseif property == "Name" then
                    local currentName = descendant.Name
                    local processed = self:_processText(currentName)
                    if processed ~= currentName then
                        descendant.Name = processed
                    end
                end
            end)
            
            descendant:SetAttribute("_textHook", newConn)
            table.insert(self._connections, newConn)
        end
    end
    
    -- Process existing descendants in CoreGui
    for _, descendant in pairs(targetGui:GetDescendants()) do
        processDescendant(descendant)
    end
    
    -- Process new descendants
    local descendantAddedConn = targetGui.DescendantAdded:Connect(function(descendant)
        processDescendant(descendant)
    end)
    table.insert(self._connections, descendantAddedConn)
end

-- ============================================
-- HEADLESS MODE
-- ============================================
function IdentityManager:_applyHeadless()
    if not self._config.Headless then return end
    
    local taskId = nil
    local function headlessLoop()
        while self._isActive and self._config.Headless do
            local lp = getLocalPlayer()
            local char = lp.Character or lp.CharacterAdded:Wait()
            local head = safeWaitForChild(char, "Head", 1)
            
            if head then
                head.Transparency = 1
                local decal = head:FindFirstChildOfClass("Decal")
                if decal then
                    decal:Destroy()
                end
            end
            
            task.wait(0.5)
        end
    end
    
    taskId = task.spawn(headlessLoop)
    table.insert(self._connections, {
        Disconnect = function()
            task.cancel(taskId)
        end
    })
end

-- ============================================
-- PUBLIC API
-- ============================================
function IdentityManager:Start()
    if self._isActive then
        warn("[IdentityManager] Already active")
        return
    end
    
    self._isActive = true
    local config = self._config
    local lp = getLocalPlayer()
    
    print("[IdentityManager] Starting...")
    
    -- Apply disguise
    if config.FakeId then
        local char = lp.Character
        if char then
            self:_disguiseCharacter(char, config.FakeId)
        end
        
        lp.CharacterAdded:Connect(function(char)
            task.wait(1)
            if self._isActive then
                self:_disguiseCharacter(char, config.FakeId)
            end
        end)
    end
    
    -- Apply display name
    if config.FakeDisplayName then
        lp.DisplayName = config.FakeDisplayName
    end
    
    -- Apply character appearance
    if config.FakeId then
        lp.CharacterAppearanceId = config.FakeId
    end
    
    -- Apply headless
    if config.Headless then
        self:_applyHeadless()
    end
    
    -- Apply UI text obfuscation
    self:_obfuscateUI()
    
    print("[IdentityManager] ✅ Started successfully")
end

function IdentityManager:Stop()
    if not self._isActive then
        warn("[IdentityManager] Not active")
        return
    end
    
    self._isActive = false
    
    -- Cleanup connections
    for _, conn in pairs(self._connections) do
        pcall(conn.Disconnect, conn)
    end
    self._connections = {}
    
    -- Restore character visibility if headless
    if self._config.Headless then
        local lp = getLocalPlayer()
        local char = lp.Character
        if char then
            local head = char:FindFirstChild("Head")
            if head then
                head.Transparency = 0
            end
        end
    end
    
    print("[IdentityManager] Stopped")
end

-- ============================================
-- MODULE INIT
-- ============================================
function IdentityManager:InitFromGlobal()
    local config = getgenv().Config or {
        Headless = false,
        FakeDisplayName = "AmySchumer",
        FakeName = "redmiint8",
        FakeId = 13886182,
    }
    self:Init(config)
    return self
end

return IdentityManager
