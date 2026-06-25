--[[
    devHub UI Library
    Version : 2.0.0
    Author  : DeveloperK
    License : MIT
    Description: Lightweight, high-performance UI library for Roblox
]]

-- ============================================
-- SERVICES
-- ============================================
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- CONSTANTS & CONFIG
-- ============================================
local DEFAULT_THEME = {
    Background = Color3.fromRGB(10, 12, 25),
    Sidebar = Color3.fromRGB(15, 18, 32),
    ElementBg = Color3.fromRGB(25, 30, 50),
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(180, 200, 230),
    Accent = Color3.fromRGB(0, 140, 210),
    Hover = Color3.fromRGB(35, 45, 70),
    Outline = Color3.fromRGB(40, 60, 90),
    Danger = Color3.fromRGB(220, 50, 50),
    Success = Color3.fromRGB(50, 200, 100),
}

local ICONS = {
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

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================
local function createInstance(className: string, properties: table): Instance
    local inst = Instance.new(className)
    for k, v in pairs(properties) do
        inst[k] = v
    end
    return inst
end

local function cloneTable(t: table): table
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

local function getParent()
    local success, parent = pcall(function()
        return (gethui and gethui()) or CoreGui
    end)
    return success and parent or LocalPlayer:WaitForChild("PlayerGui")
end

-- ============================================
-- DEV LIBRARY MODULE
-- ============================================
local voraLib = {
    _theme = cloneTable(DEFAULT_THEME),
    _icons = cloneTable(ICONS),
    _connections = {},
    _keybindSession = nil,
    _dropdownLayoutOrder = 0,
}

-- ============================================
-- THEME MANAGEMENT
-- ============================================
function voraLib:setTheme(theme: table)
    for k, v in pairs(theme) do
        if self._theme[k] ~= nil then
            self._theme[k] = v
        end
    end
end

function voraLib:getTheme(): table
    return self._theme
end

function voraLib:getIcons(): table
    return self._icons
end

-- ============================================
-- DRAGGABLE
-- ============================================
function voraLib:makeDraggable(topbar: GuiObject, target: GuiObject)
    local dragging = false
    local dragInput, dragStart, startPos

    local function update(input: InputObject)
        local delta = input.Position - dragStart
        local pos = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        local tween = TweenService:Create(target, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = pos })
        tween:Play()
    end

    local conns = {}
    table.insert(conns, topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            local c = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    c:Disconnect()
                end
            end)
            table.insert(conns, c)
        end
    end))

    table.insert(conns, topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    table.insert(conns, UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end))

    return conns
end

-- ============================================
-- WINDOW CREATION
-- ============================================
function voraLib:createWindow(options: table?)
    options = options or {}
    local titleName = options.Name or "devHub"
    local introEnabled = options.Intro or false
    local theme = self._theme

    local screenGui = createInstance("ScreenGui", {
        Name = "devHub",
        Parent = getParent(),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
    })

    -- Determine initial size (mobile vs desktop)
    local viewportSize = workspace.CurrentCamera.ViewportSize
    local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
    local defaultSize = isMobile and UDim2.new(0, 500, 0, 320) or UDim2.new(0, 700, 0, 450)
    local defaultPos = isMobile and UDim2.new(0.5, -250, 0.5, -160) or UDim2.new(0.5, -350, 0.5, -225)

    -- Main Frame
    local mainFrame = createInstance("Frame", {
        Name = "MainFrame",
        Parent = screenGui,
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Position = defaultPos,
        Size = defaultSize,
        ClipsDescendants = false,
    })
    createInstance("UICorner", { CornerRadius = UDim.new(0, 10), Parent = mainFrame })
    createInstance("UIStroke", {
        Transparency = 0,
        Thickness = 1,
        Color = theme.Outline,
        Parent = mainFrame,
    })

    -- Shadow
    local shadow = createInstance("ImageLabel", {
        Name = "Shadow",
        Parent = screenGui,
        BackgroundTransparency = 1,
        Position = defaultPos,
        Size = defaultSize,
        Image = "rbxassetid://6015897843",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.5,
        ZIndex = -1,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ScaleType = Enum.ScaleType.Slice,
        SliceScale = 1,
    })

    -- Update shadow on resize
    mainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        shadow.Size = UDim2.new(0, mainFrame.AbsoluteSize.X + 34, 0, mainFrame.AbsoluteSize.Y + 34)
    end)
    mainFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
        shadow.Position = UDim2.new(0, mainFrame.AbsolutePosition.X - 17, 0, mainFrame.AbsolutePosition.Y - 17)
    end)

    -- Resize Handle
    local resizeHandle = createInstance("TextButton", {
        Name = "ResizeHandle",
        Parent = mainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -4, 1, -4),
        Size = UDim2.new(0, 16, 0, 16),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 100,
        AnchorPoint = Vector2.new(1, 1),
    })

    -- Resize lines
    for i = 1, 3 do
        local line = createInstance("Frame", {
            Parent = resizeHandle,
            BackgroundColor3 = theme.TextSecondary,
            BorderSizePixel = 0,
            Rotation = -45,
            Size = UDim2.new(0, 4 + i * 4, 0, 2),
            Position = UDim2.new(1, -2, 1, -(2 + i * 4)),
            AnchorPoint = Vector2.new(1, 1),
            ZIndex = 101,
        })
        createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = line })
    end

    -- Resize logic
    local resizing = false
    local resizeStart, startSize
    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            startSize = mainFrame.AbsoluteSize
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStart
            local newWidth = math.max(400, startSize.X + delta.X)
            local newHeight = math.max(300, startSize.Y + delta.Y)
            mainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end)

    -- Header
    local header = createInstance("Frame", {
        Name = "Header",
        Parent = mainFrame,
        BackgroundColor3 = theme.Sidebar,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
    })
    createInstance("UICorner", { CornerRadius = UDim.new(0, 10), Parent = header })
    createInstance("Frame", {
        Parent = header,
        BackgroundColor3 = theme.Outline,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 2,
    })

    -- Logo
    local logo = createInstance("ImageLabel", {
        Name = "Logo",
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 5),
        Size = UDim2.new(0, 25, 0, 25),
        Image = "rbxassetid://112067161065104",
        ImageColor3 = theme.Accent,
        ZIndex = 2,
    })

    -- Title
    local titleLabel = createInstance("TextLabel", {
        Name = "Title",
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 45, 0, 0),
        Size = UDim2.new(1, -160, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = titleName,
        TextColor3 = theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
    })

    -- Intro animation
    if introEnabled then
        local startSize = mainFrame.Size
        mainFrame.Size = UDim2.new(0, 0, 0, 0)
        mainFrame.BackgroundTransparency = 1
        TweenService:Create(mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = startSize,
            BackgroundTransparency = 0.05,
        }):Play()
    end

    -- Sidebar
    local sidebar = createInstance("Frame", {
        Name = "Sidebar",
        Parent = mainFrame,
        BackgroundColor3 = theme.Sidebar,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 38),
        Size = UDim2.new(0, 160, 1, -38),
    })
    createInstance("Frame", {
        Name = "Separator",
        Parent = sidebar,
        BackgroundColor3 = theme.Outline,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -2, 0, 0),
        Size = UDim2.new(0, 2, 1, 0),
    })

    -- Controls (Minimize, Maximize, Close)
    local controls = createInstance("Frame", {
        Name = "Controls",
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -100, 0, 0),
        Size = UDim2.new(0, 100, 1, 0),
        ZIndex = 2,
    })
    local controlsLayout = createInstance("UIListLayout", {
        Parent = controls,
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
    })
    createInstance("UIPadding", { Parent = controls, PaddingRight = UDim.new(0, 15) })

    -- Minimize / Restore Button
    local isMinimized = false
    local toggleButton = createInstance("ImageButton", {
        Name = "ToggleUI",
        Parent = screenGui,
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Position = UDim2.new(0.1, 0, 0.1, 0),
        Size = UDim2.new(0, 50, 0, 50),
        Image = "rbxassetid://127876061340518",
        ImageColor3 = theme.Text,
        Visible = true,
        Active = true,
        Draggable = true,
        ZIndex = 100,
    })
    createInstance("UICorner", { CornerRadius = UDim.new(0, 10), Parent = toggleButton })
    createInstance("UIStroke", { Color = theme.Outline, Thickness = 1, Parent = toggleButton })

    local function toggleUI()
        isMinimized = not isMinimized
        if isMinimized then
            local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 0)
            })
            tween:Play()
            task.delay(0.3, function()
                if isMinimized then
                    mainFrame.Visible = false
                    shadow.Visible = false
                end
            end)
        else
            mainFrame.Visible = true
            shadow.Visible = true
            mainFrame.Size = UDim2.new(0, 0, 0, 0)
            TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = defaultSize,
            }):Play()
        end
    end

    toggleButton.MouseButton1Click:Connect(toggleUI)

    -- Keyboard shortcut (RightControl)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
            toggleUI()
        end
    end)

    -- Control Buttons: Minimize, Maximize, Close
    local function createControlButton(name, icon, layoutOrder, callback)
        local btn = createInstance("ImageButton", {
            Name = name,
            Parent = controls,
            BackgroundTransparency = 1,
            LayoutOrder = layoutOrder,
            Size = UDim2.new(0, 20, 0, 20),
            Image = icon,
            ImageColor3 = theme.TextSecondary,
            AutoButtonColor = false,
        })
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), { ImageColor3 = theme.Text }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), { ImageColor3 = theme.TextSecondary }):Play()
        end)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    createControlButton("Minimize", "rbxassetid://71686683787518", 1, toggleUI)

    local maximized = false
    local maxSize = isMobile and UDim2.new(0, 600, 0, 350) or UDim2.new(0, 900, 0, 600)
    local maxPos = isMobile and UDim2.new(0.5, -300, 0.5, -175) or UDim2.new(0.5, -450, 0.5, -300)

    createControlButton("Maximize", "rbxassetid://135582116755237", 2, function()
        maximized = not maximized
        if maximized then
            TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = maxSize,
                Position = maxPos,
            }):Play()
        else
            TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = defaultSize,
                Position = defaultPos,
            }):Play()
        end
    end)

    createControlButton("Close", "rbxassetid://121948938505669", 3, function()
        TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
        }):Play()
        task.wait(0.4)
        window:destroy()
    end)

    -- Tab Container (Sidebar)
    local tabContainer = createInstance("ScrollingFrame", {
        Name = "TabContainer",
        Parent = sidebar,
        Active = true,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 15),
        Size = UDim2.new(1, 0, 1, -25),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.Accent,
    })

    local buttonsHolder = createInstance("Frame", {
        Name = "ButtonsHolder",
        Parent = tabContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    createInstance("UIListLayout", {
        Parent = buttonsHolder,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
    })
    createInstance("UIPadding", {
        Parent = buttonsHolder,
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
    })

    -- Sliding Indicator
    local slidingIndicator = createInstance("Frame", {
        Name = "SlidingIndicator",
        Parent = tabContainer,
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 3, 0, 20),
        Visible = false,
        ZIndex = 2,
    })
    createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = slidingIndicator })

    -- Content Container
    local contentContainer = createInstance("Frame", {
        Name = "ContentContainer",
        Parent = mainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 160, 0, 45),
        Size = UDim2.new(1, -160, 1, -45),
    })

    -- Make draggable
    self:makeDraggable(header, mainFrame)

    -- ============================================
    -- NOTIFICATION SYSTEM
    -- ============================================
    local notificationHolder = createInstance("Frame", {
        Name = "NotificationHolder",
        Parent = screenGui,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -20, 1, -20),
        Size = UDim2.new(0, 300, 1, -20),
        AnchorPoint = Vector2.new(1, 1),
        ZIndex = 100,
    })
    createInstance("UIListLayout", {
        Parent = notificationHolder,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 10),
    })

    local function notify(options)
        options = options or {}
        local title = options.Title or options.Name or "Notification"
        local content = options.Content or "Message"
        local duration = options.Duration or 3
        local image = options.Image or options.Icon or "rbxassetid://112067161065104"
        if self._icons[image] then image = self._icons[image] end

        local notifyFrame = createInstance("Frame", {
            Name = "NotifyFrame",
            Parent = notificationHolder,
            BackgroundColor3 = theme.Sidebar,
            BackgroundTransparency = 0.1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ClipsDescendants = true,
        })
        createInstance("UICorner", { CornerRadius = UDim.new(0, 8), Parent = notifyFrame })
        createInstance("UIStroke", { Color = theme.Outline, Thickness = 1, Parent = notifyFrame })

        local contentFrame = createInstance("Frame", {
            Parent = notifyFrame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 60),
        })

        local icon = createInstance("ImageLabel", {
            Parent = contentFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 12),
            Size = UDim2.new(0, 36, 0, 36),
            Image = image,
            ImageColor3 = theme.Accent,
        })
        createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = icon })

        local titleLabel = createInstance("TextLabel", {
            Parent = contentFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 58, 0, 10),
            Size = UDim2.new(1, -68, 0, 20),
            Font = Enum.Font.GothamBold,
            Text = title,
            TextColor3 = theme.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
        })

        local contentLabel = createInstance("TextLabel", {
            Parent = contentFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 58, 0, 30),
            Size = UDim2.new(1, -68, 0, 20),
            Font = Enum.Font.Gotham,
            Text = content,
            TextColor3 = theme.TextSecondary,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
        })

        -- Slide in animation
        notifyFrame.Position = UDim2.new(1, 320, 0, 0)
        TweenService:Create(notifyFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, 0, 0, 0),
        }):Play()

        -- Progress bar
        local progressBar = createInstance("Frame", {
            Parent = notifyFrame,
            BackgroundColor3 = theme.Accent,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -2),
            Size = UDim2.new(1, 0, 0, 2),
        })
        TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
            Size = UDim2.new(0, 0, 0, 2),
        }):Play()

        task.delay(duration, function()
            TweenService:Create(notifyFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 320, 0, 0),
            }):Play()
            task.wait(0.5)
            notifyFrame:Destroy()
        end)
    end

    -- ============================================
    -- DROPDOWN SYSTEM (Shared)
    -- ============================================
    local moreBlur = createInstance("Frame", {
        Name = "MoreBlur",
        Parent = mainFrame,
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 2000,
    })
    local connectButton = createInstance("TextButton", {
        Name = "ConnectButton",
        Parent = moreBlur,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 2000,
    })

    local dropdownSelect = createInstance("Frame", {
        Name = "DropdownSelect",
        Parent = moreBlur,
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = theme.Sidebar,
        BorderSizePixel = 0,
        Position = UDim2.new(1, 182, 0.5, 0),
        Size = UDim2.new(0, 180, 1, -20),
        ClipsDescendants = false,
        ZIndex = 2005,
    })
    createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = dropdownSelect })
    createInstance("UIStroke", { Color = theme.Accent, Thickness = 1, Transparency = 0.5, Parent = dropdownSelect })

    -- Shadow for dropdown
    createInstance("ImageLabel", {
        Parent = dropdownSelect,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, -15, 0, -15),
        Size = UDim2.new(1, 30, 1, 30),
        Image = "rbxassetid://6015897843",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = 2004,
    })

    local dropdownSelectReal = createInstance("Frame", {
        Name = "DropdownSelectReal",
        Parent = dropdownSelect,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, -10, 1, -10),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 2005,
    })

    local dropdownFolder = Instance.new("Folder", dropdownSelectReal)
    local dropPageLayout = Instance.new("UIPageLayout", dropdownFolder)
    dropPageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    dropPageLayout.EasingStyle = Enum.EasingStyle.Quint
    dropPageLayout.EasingDirection = Enum.EasingDirection.Out
    dropPageLayout.TweenTime = 0
    dropPageLayout.FillDirection = Enum.FillDirection.Vertical
    dropPageLayout.ScrollWheelInputEnabled = false

    connectButton.Activated:Connect(function()
        if moreBlur.Visible then
            TweenService:Create(moreBlur, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
            TweenService:Create(dropdownSelect, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 182, 0.5, 0),
            }):Play()
            task.wait(0.25)
            moreBlur.Visible = false
        end
    end)

    -- ============================================
    -- WINDOW OBJECT
    -- ============================================
    local window = {
        _tabs = {},
        _flags = {},
        _screenGui = screenGui,
        _mainFrame = mainFrame,
        _shadow = shadow,
        _tabContainer = tabContainer,
        _buttonsHolder = buttonsHolder,
        _contentContainer = contentContainer,
        _slidingIndicator = slidingIndicator,
        _moreBlur = moreBlur,
        _dropdownSelect = dropdownSelect,
        _dropdownSelectReal = dropdownSelectReal,
        _dropdownFolder = dropdownFolder,
        _dropPageLayout = dropPageLayout,
        _dropdownLayoutOrder = 0,
        _notificationHolder = notificationHolder,
        _notify = notify,
        _destroyed = false,
    }

    -- ============================================
    -- WINDOW METHODS
    -- ============================================
    function window:notify(options)
        self._notify(options)
    end

    function window:destroy()
        if self._destroyed then return end
        self._destroyed = true
        self._screenGui:Destroy()
        for _, conn in pairs(self._connections or {}) do
            pcall(conn.Disconnect, conn)
        end
        self._connections = {}
    end

    -- ============================================
    -- TAB CREATION
    -- ============================================
    function window:createTab(options)
        options = options or {}
        local tabName = options.Name or "Tab"
        local tabIcon = self._icons[options.Icon] or options.Icon or ""

        local tab = {
            _active = false,
            _currentSectionContainer = nil,
            _page = nil,
            _button = nil,
            _label = nil,
            _icon = nil,
        }

        local tabButton = createInstance("TextButton", {
            Name = tabName .. "Button",
            Parent = self._buttonsHolder,
            BackgroundColor3 = theme.ElementBg,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 36),
            AutoButtonColor = false,
            ClipsDescendants = true,
            Text = "",
        })
        createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = tabButton })
        createInstance("UIStroke", { Color = theme.Outline, Transparency = 0.8, Thickness = 1, Parent = tabButton })

        local iconImage
        if tabIcon ~= "" then
            iconImage = createInstance("ImageLabel", {
                Parent = tabButton,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0.5, -10),
                Size = UDim2.new(0, 20, 0, 20),
                Image = tabIcon,
                ImageColor3 = theme.TextSecondary,
            })
        end

        local tabLabel = createInstance("TextLabel", {
            Parent = tabButton,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, tabIcon ~= "" and 40 or 15, 0, 0),
            Size = UDim2.new(1, tabIcon ~= "" and -40 or -15, 1, 0),
            Font = Enum.Font.GothamMedium,
            Text = tabName,
            TextColor3 = theme.TextSecondary,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
        })

        -- Hover effects
        tabButton.MouseEnter:Connect(function()
            if not tab._active then
                TweenService:Create(tabButton, TweenInfo.new(0.2), { BackgroundTransparency = 0.9 }):Play()
                TweenService:Create(tabLabel, TweenInfo.new(0.2), { TextColor3 = theme.Text }):Play()
                if iconImage then
                    TweenService:Create(iconImage, TweenInfo.new(0.2), { ImageColor3 = theme.Text }):Play()
                end
            end
        end)
        tabButton.MouseLeave:Connect(function()
            if not tab._active then
                TweenService:Create(tabButton, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
                TweenService:Create(tabLabel, TweenInfo.new(0.2), { TextColor3 = theme.TextSecondary }):Play()
                if iconImage then
                    TweenService:Create(iconImage, TweenInfo.new(0.2), { ImageColor3 = theme.TextSecondary }):Play()
                end
            end
        end)

        -- Tab Page
        local tabPage = createInstance("ScrollingFrame", {
            Name = tabName .. "Page",
            Parent = self._contentContainer,
            Active = true,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = theme.Accent,
            Visible = false,
        })
        createInstance("UIListLayout", {
            Parent = tabPage,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
        })
        createInstance("UIPadding", {
            Parent = tabPage,
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 15),
            PaddingRight = UDim.new(0, 10),
        })

        -- Tab title inside page
        createInstance("TextLabel", {
            Name = "TabTitle",
            Parent = tabPage,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 40),
            Font = Enum.Font.GothamBold,
            Text = tabName,
            TextColor3 = theme.Text,
            TextSize = 26,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = -1,
        })

        tab._page = tabPage
        tab._button = tabButton
        tab._label = tabLabel
        tab._icon = iconImage

        -- Activate function
        function tab:activate()
            for _, t in pairs(window._tabs) do
                if t ~= tab then
                    TweenService:Create(t._button, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
                    TweenService:Create(t._label, TweenInfo.new(0.2), { TextColor3 = theme.TextSecondary }):Play()
                    if t._icon then
                        TweenService:Create(t._icon, TweenInfo.new(0.2), { ImageColor3 = theme.TextSecondary }):Play()
                    end
                    t._page.Visible = false
                    t._active = false
                end
            end

            tab._active = true
            TweenService:Create(tabButton, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.85,
            }):Play()
            TweenService:Create(tabLabel, TweenInfo.new(0.3), { TextColor3 = theme.Accent }):Play()
            if iconImage then
                TweenService:Create(iconImage, TweenInfo.new(0.3), { ImageColor3 = theme.Accent }):Play()
            end

            tabPage.Visible = true
            tabPage.Position = UDim2.new(0, 15, 0, 0)
            TweenService:Create(tabPage, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0, 0),
            }):Play()

            if not slidingIndicator.Visible then
                slidingIndicator.Visible = true
                slidingIndicator.Position = UDim2.new(0, 0, 0, tabButton.AbsolutePosition.Y - buttonsHolder.AbsolutePosition.Y + 8)
            end

            local targetY = tabButton.AbsolutePosition.Y - buttonsHolder.AbsolutePosition.Y + 8
            TweenService:Create(slidingIndicator, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0, targetY),
            }):Play()
        end

        -- Click handler
        tabButton.MouseButton1Click:Connect(function()
            -- Ripple effect
            task.spawn(function()
                local mouse = LocalPlayer:GetMouse()
                local ripple = createInstance("Frame", {
                    Parent = tabButton,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BackgroundTransparency = 0.8,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, mouse.X - tabButton.AbsolutePosition.X, 0, mouse.Y - tabButton.AbsolutePosition.Y),
                    Size = UDim2.new(0, 0, 0, 0),
                    ZIndex = 1,
                })
                createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ripple })
                local tween = TweenService:Create(ripple, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 150, 0, 150),
                    Position = UDim2.new(0, mouse.X - tabButton.AbsolutePosition.X - 75, 0, mouse.Y - tabButton.AbsolutePosition.Y - 75),
                    BackgroundTransparency = 1,
                })
                tween:Play()
                tween.Completed:Wait()
                ripple:Destroy()
            end)
            tab:activate()
        end)

        table.insert(window._tabs, tab)

        -- Activate first tab
        if #window._tabs == 1 then
            tab:activate()
        end

        -- Auto-update canvas size
        local layout = tabPage:FindFirstChildOfClass("UIListLayout")
        if layout then
            layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                tabPage.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
            end)
        end

        -- ============================================
        -- SECTION CREATION
        -- ============================================
        function tab:createSection(options)
            options = options or {}
            local sectionName = options.Name or "Section"

            local sectionContainer = createInstance("Frame", {
                Name = "SectionContainer",
                Parent = tabPage,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 32),
            })

            local sectionHeader = createInstance("TextButton", {
                Name = "SectionHeader",
                Parent = sectionContainer,
                BackgroundColor3 = theme.ElementBg,
                BackgroundTransparency = 0.5,
                Size = UDim2.new(1, 0, 0, 32),
                AutoButtonColor = false,
                Text = "",
            })
            createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = sectionHeader })
            createInstance("UIStroke", { Color = theme.Outline, Transparency = 0.6, Thickness = 1, Parent = sectionHeader })

            local headerLabel = createInstance("TextLabel", {
                Name = "Title",
                Parent = sectionHeader,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(1, -40, 1, 0),
                Font = Enum.Font.GothamBold,
                Text = sectionName,
                TextColor3 = theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            local chevron = createInstance("ImageLabel", {
                Name = "Chevron",
                Parent = sectionHeader,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -26, 0.5, -8),
                Size = UDim2.new(0, 16, 0, 16),
                Image = "rbxassetid://6031091004",
                ImageColor3 = theme.TextSecondary,
                Rotation = -90,
            })

            local contentFrame = createInstance("Frame", {
                Name = "SectionContent",
                Parent = sectionContainer,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 36),
                Size = UDim2.new(1, 0, 0, 0),
                ClipsDescendants = true,
                Visible = true,
            })
            createInstance("UIListLayout", {
                Parent = contentFrame,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 8),
            })
            createInstance("UIPadding", {
                Parent = contentFrame,
                PaddingTop = UDim.new(0, 5),
                PaddingBottom = UDim.new(0, 5),
                PaddingLeft = UDim.new(0, 5),
                PaddingRight = UDim.new(0, 5),
            })

            local open = false
            local canvasSizeConnection

            local function getContentHeight()
                local layout = contentFrame:FindFirstChildOfClass("UIListLayout")
                if layout then
                    return layout.AbsoluteContentSize.Y + 10
                end
                return 0
            end

            sectionHeader.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    TweenService:Create(chevron, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Rotation = 0 }):Play()
                    TweenService:Create(sectionHeader, TweenInfo.new(0.2), { BackgroundColor3 = theme.Accent, BackgroundTransparency = 0.8 }):Play()

                    local contentHeight = getContentHeight()
                    local totalHeight = contentHeight + 40
                    TweenService:Create(contentFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, contentHeight),
                    }):Play()
                    TweenService:Create(sectionContainer, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, totalHeight),
                    }):Play()

                    if not canvasSizeConnection then
                        local layout = contentFrame:FindFirstChildOfClass("UIListLayout")
                        if layout then
                            canvasSizeConnection = layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                                if open then
                                    local newContentHeight = layout.AbsoluteContentSize.Y + 10
                                    local newTotalHeight = newContentHeight + 40
                                    TweenService:Create(contentFrame, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, newContentHeight) }):Play()
                                    TweenService:Create(sectionContainer, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, newTotalHeight) }):Play()
                                end
                            end)
                        end
                    end
                else
                    TweenService:Create(chevron, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Rotation = -90 }):Play()
                    TweenService:Create(sectionHeader, TweenInfo.new(0.2), { BackgroundColor3 = theme.ElementBg, BackgroundTransparency = 0.5 }):Play()
                    TweenService:Create(contentFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, 0),
                    }):Play()
                    TweenService:Create(sectionContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, 32),
                    }):Play()
                    if canvasSizeConnection then
                        canvasSizeConnection:Disconnect()
                        canvasSizeConnection = nil
                    end
                end
            end)

            sectionHeader.MouseEnter:Connect(function()
                if not open then
                    TweenService:Create(sectionHeader, TweenInfo.new(0.2), { BackgroundTransparency = 0.3 }):Play()
                end
            end)
            sectionHeader.MouseLeave:Connect(function()
                if not open then
                    TweenService:Create(sectionHeader, TweenInfo.new(0.2), { BackgroundTransparency = 0.5 }):Play()
                end
            end)

            tab._currentSectionContainer = contentFrame
            return contentFrame
        end

        -- ============================================
        -- ELEMENTS
        -- ============================================
        function tab:createParagraph(options)
            options = options or {}
            local title = options.Title or "Paragraph"
            local desc = options.Desc or options.Content or ""

            local frame = createInstance("Frame", {
                Parent = tab._currentSectionContainer or tabPage,
                BackgroundColor3 = theme.ElementBg,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
            })
            createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = frame })
            createInstance("UIStroke", { Color = theme.Outline, Transparency = 0.6, Thickness = 1, Parent = frame })

            local titleLabel = createInstance("TextLabel", {
                Parent = frame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 8),
                Size = UDim2.new(1, -24, 0, 20),
                Font = Enum.Font.GothamBold,
                Text = title,
                TextColor3 = theme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            local descLabel = createInstance("TextLabel", {
                Parent = frame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 32),
                Size = UDim2.new(1, -24, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Font = Enum.Font.Gotham,
                Text = desc,
                TextColor3 = theme.TextSecondary,
                TextSize = 13,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                RichText = true,
            })
            createInstance("UIPadding", { Parent = frame, PaddingBottom = UDim.new(0, 12) })

            local obj = {
                _title = title,
                _desc = desc,
                _titleLabel = titleLabel,
                _descLabel = descLabel,
            }
            function obj:setTitle(newTitle)
                self._title = newTitle
                self._titleLabel.Text = newTitle
            end
            function obj:setDesc(newDesc)
                self._desc = newDesc
                self._descLabel.Text = newDesc
            end
            function obj:getTitle() return self._title end
            function obj:getDesc() return self._desc end
            return obj
        end

        function tab:createLabel(options)
            options = options or {}
            local text = options.Text or "Label"

            local frame = createInstance("Frame", {
                Parent = tab._currentSectionContainer or tabPage,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 26),
            })
            local label = createInstance("TextLabel", {
                Parent = frame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 5, 0, 0),
                Size = UDim2.new(1, -10, 1, 0),
                Font = Enum.Font.GothamMedium,
                Text = text,
                TextColor3 = theme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            return label
        end

        function tab:createButton(options)
            options = options or {}
            local name = options.Name or "Button"
            local subText = options.SubText
            local icon = options.Icon
            local callback = options.Callback or function() end

            local frame = createInstance("Frame", {
                Parent = tab._currentSectionContainer or tabPage,
                BackgroundColor3 = theme.ElementBg,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, subText and 50 or 38),
                ClipsDescendants = true,
            })
            createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = frame })
            local stroke = createInstance("UIStroke", {
                Color = theme.Outline,
                Transparency = 0.5,
                Thickness = 1,
                Parent = frame,
            })

            local button = createInstance("TextButton", {
                Name = "Button",
                Parent = frame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Font = Enum.Font.GothamMedium,
                Text = subText and "" or name,
                TextColor3 = theme.Text,
                TextSize = 14,
                AutoButtonColor = false,
                ZIndex = 2,
            })

            if subText then
                createInstance("TextLabel", {
                    Parent = button,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 8),
                    Size = UDim2.new(1, -50, 0, 20),
                    Font = Enum.Font.GothamBold,
                    Text = name,
                    TextColor3 = theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                createInstance("TextLabel", {
                    Parent = button,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 26),
                    Size = UDim2.new(1, -50, 0, 14),
                    Font = Enum.Font.Gotham,
                    Text = subText,
                    TextColor3 = theme.TextSecondary,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
            end

            if icon then
                createInstance("ImageLabel", {
                    Parent = button,
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -12, 0.5, 0),
                    Size = UDim2.new(0, 20, 0, 20),
                    Image = icon,
                    ImageColor3 = theme.TextSecondary,
                })
            end

            button.MouseEnter:Connect(function()
                TweenService:Create(frame, TweenInfo.new(0.2), { BackgroundColor3 = theme.Hover, BackgroundTransparency = 0.1 }):Play()
                TweenService:Create(stroke, TweenInfo.new(0.2), { Color = theme.Accent, Transparency = 0.2 }):Play()
            end)
            button.MouseLeave:Connect(function()
                TweenService:Create(frame, TweenInfo.new(0.2), { BackgroundColor3 = theme.ElementBg, BackgroundTransparency = 0.2 }):Play()
                TweenService:Create(stroke, TweenInfo.new(0.2), { Color = theme.Outline, Transparency = 0.5 }):Play()
            end)

            button.MouseButton1Click:Connect(function()
                -- Ripple effect
                task.spawn(function()
                    local mouse = LocalPlayer:GetMouse()
                    local ripple = createInstance("Frame", {
                        Parent = frame,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BackgroundTransparency = 0.8,
                        BorderSizePixel = 0,
                        Position = UDim2.new(0, mouse.X - frame.AbsolutePosition.X, 0, mouse.Y - frame.AbsolutePosition.Y),
                        Size = UDim2.new(0, 0, 0, 0),
                        ZIndex = 1,
                    })
                    createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ripple })
                    local tween = TweenService:Create(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 200, 0, 200),
                        Position = UDim2.new(0, mouse.X - frame.AbsolutePosition.X - 100, 0, mouse.Y - frame.AbsolutePosition.Y - 100),
                        BackgroundTransparency = 1,
                    })
                    tween:Play()
                    tween.Completed:Wait()
                    ripple:Destroy()
                end)

                TweenService:Create(frame, TweenInfo.new(0.1), { BackgroundColor3 = theme.Accent, BackgroundTransparency = 0 }):Play()
                task.wait(0.1)
                TweenService:Create(frame, TweenInfo.new(0.3), { BackgroundColor3 = theme.Hover, BackgroundTransparency = 0.1 }):Play()
                callback()
            end)
        end

        function tab:createToggle(options)
            options = options or {}
            local name = options.Name or "Toggle"
            local subText = options.SubText
            local default = options.Default or options.Value or false
            local values = options.Values or {}
            local callback = options.Callback or function() end

            local toggled = default
            local frame = createInstance("Frame", {
                Parent = tab._currentSectionContainer or tabPage,
                BackgroundColor3 = theme.ElementBg,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, subText and 50 or 38),
            })
            createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = frame })
            createInstance("UIStroke", { Color = theme.Outline, Transparency = 0.5, Thickness = 1, Parent = frame })

            local label = createInstance("TextLabel", {
                Parent = frame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, subText and 8 or 0),
                Size = UDim2.new(1, -60, 0, subText and 20 or 38),
                Font = subText and Enum.Font.GothamBold or Enum.Font.GothamMedium,
                Text = name,
                TextColor3 = theme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
            })
            if subText then
                createInstance("TextLabel", {
                    Parent = frame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 26),
                    Size = UDim2.new(1, -60, 0, 14),
                    Font = Enum.Font.Gotham,
                    Text = subText,
                    TextColor3 = theme.TextSecondary,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                })
            end

            local switchBg = createInstance("Frame", {
                Parent = frame,
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = toggled and theme.Accent or Color3.fromRGB(45, 45, 50),
                Position = UDim2.new(1, -12, 0.5, 0),
                Size = UDim2.new(0, 42, 0, 22),
            })
            createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = switchBg })

            local switchCircle = createInstance("Frame", {
                Parent = switchBg,
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Position = UDim2.new(0, toggled and 22 or 2, 0.5, 0),
                Size = UDim2.new(0, 18, 0, 18),
            })
            createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = switchCircle })

            local button = createInstance("TextButton", {
                Parent = frame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Text = "",
            })

            local obj = { Value = default }

            local function updateState(newValue)
                toggled = newValue
                obj.Value = toggled
                local targetColor = toggled and theme.Accent or Color3.fromRGB(45, 45, 50)
                local targetPos = UDim2.new(0, toggled and 22 or 2, 0.5, 0)
                TweenService:Create(switchBg, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundColor3 = targetColor }):Play()
                TweenService:Create(switchCircle, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = targetPos }):Play()
                if #values > 0 then
                    callback(values[toggled and 2 or 1])
                else
                    callback(toggled)
                end
            end

            function obj:set(newValue)
                if type(newValue) ~= "boolean" then
                    newValue = newValue == true or newValue == "true" or newValue == 1
                end
                updateState(newValue)
            end

            button.MouseButton1Click:Connect(function()
                updateState(not toggled)
            end)

            local flag = options.Flag or name
            if flag then window._flags[flag] = obj end
            return obj
        end

        function tab:createSlider(options)
            options = options or {}
            local name = options.Name or "Slider"
            local min = options.Min or 0
            local max = options.Max or 100
            local default = options.Default or options.Value or min
            local callback = options.Callback or function() end

            local frame = createInstance("Frame", {
                Parent = tab._currentSectionContainer or tabPage,
                BackgroundColor3 = theme.ElementBg,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 55),
            })
            createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = frame })
            createInstance("UIStroke", { Color = theme.Outline, Transparency = 0.5, Thickness = 1, Parent = frame })

            local label = createInstance("TextLabel", {
                Parent = frame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 8),
                Size = UDim2.new(1, -24, 0, 20),
                Font = Enum.Font.GothamMedium,
                Text = name,
                TextColor3 = theme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            local valueLabel = createInstance("TextLabel", {
                Parent = frame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 8),
                Size = UDim2.new(1, -24, 0, 20),
                Font = Enum.Font.Gotham,
                Text = tostring(default),
                TextColor3 = theme.TextSecondary,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Right,
            })

            local sliderBg = createInstance("Frame", {
                Parent = frame,
                BackgroundColor3 = Color3.fromRGB(50, 50, 55),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 12, 0, 38),
                Size = UDim2.new(1, -24, 0, 5),
            })
            createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sliderBg })

            local sliderFill = createInstance("Frame", {
                Parent = sliderBg,
                BackgroundColor3 = theme.Accent,
                BorderSizePixel = 0,
                Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
            })
            createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sliderFill })

            local sliderKnob = createInstance("Frame", {
                Parent = sliderBg,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0),
                Size = UDim2.new(0, 14, 0, 14),
                ZIndex = 2,
            })
            createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sliderKnob })

            local sliderButton = createInstance("TextButton", {
                Parent = sliderBg,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Text = "",
                ZIndex = 3,
            })

            local dragging = false
            local obj = { Value = default }

            local function updateSlider(input)
                local sizeX = sliderBg.AbsoluteSize.X
                local posX = sliderBg.AbsolutePosition.X
                local percent = math.clamp((input.Position.X - posX) / sizeX, 0, 1)
                local value = math.floor(min + ((max - min) * percent))
                TweenService:Create(sliderFill, TweenInfo.new(0.05), { Size = UDim2.new(percent, 0, 1, 0) }):Play()
                TweenService:Create(sliderKnob, TweenInfo.new(0.05), { Position = UDim2.new(percent, 0, 0.5, 0) }):Play()
                valueLabel.Text = tostring(value)
                obj.Value = value
                callback(value)
            end

            sliderButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    TweenService:Create(sliderKnob, TweenInfo.new(0.15), { Size = UDim2.new(0, 18, 0, 18) }):Play()
                    updateSlider(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                    TweenService:Create(sliderKnob, TweenInfo.new(0.15), { Size = UDim2.new(0, 14, 0, 14) }):Play()
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)

            function obj:set(value)
                if type(value) ~= "number" then value = tonumber(value) or min end
                value = math.clamp(value, min, max)
                local percent = (value - min) / (max - min)
                TweenService:Create(sliderFill, TweenInfo.new(0.3), { Size = UDim2.new(percent, 0, 1, 0) }):Play()
                TweenService:Create(sliderKnob, TweenInfo.new(0.3), { Position = UDim2.new(percent, 0, 0.5, 0) }):Play()
                valueLabel.Text = tostring(value)
                obj.Value = value
                callback(value)
            end

            local flag = options.Flag or name
            if flag then window._flags[flag] = obj end
            return obj
        end

        function tab:createInput(options)
            options = options or {}
            local name = options.Name or "Input"
            local placeholder = options.Placeholder or name
            local default = options.Default or ""
            local callback = options.Callback or function() end
            local multiLine = options.MultiLine or false
            local sideLabel = options.SideLabel

            local frame = createInstance("Frame", {
                Parent = tab._currentSectionContainer or tabPage,
                BackgroundColor3 = theme.ElementBg,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, multiLine and 100 or 40),
            })
            createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = frame })
            local stroke = createInstance("UIStroke", {
                Color = theme.Outline,
                Transparency = 0.5,
                Thickness = 1,
                Parent = frame,
            })

            if sideLabel then
                createInstance("TextLabel", {
                    Parent = frame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Font = Enum.Font.GothamMedium,
                    Text = sideLabel,
                    TextColor3 = theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
            end

            local inputBg = createInstance("Frame", {
                Parent = frame,
                BackgroundColor3 = theme.Sidebar,
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Position = sideLabel and UDim2.new(1, -160, 0.5, 0) or UDim2.new(0, 6, 0, 6),
                Size = sideLabel and UDim2.new(0, 150, 0, 28) or UDim2.new(1, -12, 1, -12),
                AnchorPoint = sideLabel and Vector2.new(1, 0.5) or Vector2.new(0, 0),
            })
            createInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = inputBg })
            local inputStroke = createInstance("UIStroke", {
                Color = theme.Outline,
                Transparency = 0.7,
                Thickness = 1,
                Parent = inputBg,
            })

            local textBox = createInstance("TextBox", {
                Parent = inputBg,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 8, 0, multiLine and 8 or 0),
                Size = UDim2.new(1, -16, 1, multiLine and -16 or 0),
                Font = Enum.Font.Gotham,
                PlaceholderText = placeholder,
                Text = default,
                TextColor3 = theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = multiLine and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
                ClearTextOnFocus = false,
                MultiLine = multiLine,
                TextWrapped = true,
            })

            textBox.Focused:Connect(function()
                TweenService:Create(inputStroke, TweenInfo.new(0.2), { Color = theme.Accent, Transparency = 0 }):Play()
            end)

            local obj = { Value = default }

            textBox.FocusLost:Connect(function(enterPressed)
                TweenService:Create(inputStroke, TweenInfo.new(0.2), { Color = theme.Outline, Transparency = 0.7 }):Play()
                local newValue = textBox.Text
                obj.Value = newValue
                callback(newValue)
            end)

            function obj:set(value)
                if value == nil then value = "" end
                value = tostring(value)
                obj.Value = value
                textBox.Text = value
                callback(value)
            end

            function obj:get() return obj.Value end

            if default ~= "" then callback(default) end

            local flag = options.Flag or name
            if flag then window._flags[flag] = obj end
            return obj
        end

        function tab:createDropdown(options)
            options = options or {}
            local name = options.Name or "Dropdown"
            local items = options.Items or {}
            local callback = options.Callback or function() end
            local default = options.Default or (items[1] or "...")

            local obj = { Value = default, Items = items }

            -- Main button
            local frame = createInstance("Frame", {
                Parent = tab._currentSectionContainer or tabPage,
                BackgroundColor3 = theme.ElementBg,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 38),
            })
            createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = frame })
            createInstance("UIStroke", { Color = theme.Outline, Transparency = 0.5, Thickness = 1, Parent = frame })

            local label = createInstance("TextLabel", {
                Parent = frame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -60, 1, 0),
                Font = Enum.Font.GothamMedium,
                Text = name,
                TextColor3 = theme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            local valueLabel = createInstance("TextLabel", {
                Parent = frame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -34, 1, 0),
                Font = Enum.Font.Gotham,
                Text = tostring(default),
                TextColor3 = theme.TextSecondary,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right,
            })

            local icon = createInstance("ImageLabel", {
                Parent = frame,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -26, 0.5, -8),
                Size = UDim2.new(0, 16, 0, 16),
                Image = "rbxassetid://6031091004",
                ImageColor3 = theme.TextSecondary,
                Rotation = -90,
            })

            local button = createInstance("TextButton", {
                Parent = frame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Text = "",
            })

            -- Dropdown page
            local selectFrame = createInstance("Frame", {
                Parent = window._dropdownFolder,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                LayoutOrder = window._dropdownLayoutOrder,
            })
            window._dropdownLayoutOrder = window._dropdownLayoutOrder + 1

            local searchBox = createInstance("TextBox", {
                Parent = selectFrame,
                BackgroundColor3 = theme.Background,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 28),
                Font = Enum.Font.Gotham,
                PlaceholderText = "Search...",
                Text = "",
                TextColor3 = theme.Text,
                PlaceholderColor3 = theme.TextSecondary,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
            })
            createInstance("UIPadding", { Parent = searchBox, PaddingLeft = UDim.new(0, 8) })
            createInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = searchBox })

            local scrollList = createInstance("ScrollingFrame", {
                Parent = selectFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 35),
                Size = UDim2.new(1, 0, 1, -35),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = theme.Accent,
                BorderSizePixel = 0,
            })
            local listLayout = createInstance("UIListLayout", {
                Parent = scrollList,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
            })

            local function populate(filter)
                filter = filter:lower()
                for _, c in pairs(scrollList:GetChildren()) do
                    if c:IsA("Frame") then c:Destroy() end
                end
                for _, item in ipairs(obj.Items) do
                    if filter == "" or tostring(item):lower():find(filter) then
                        local itemFrame = createInstance("Frame", {
                            Parent = scrollList,
                            BackgroundColor3 = theme.ElementBg,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 26),
                        })
                        local itemBtn = createInstance("TextButton", {
                            Parent = itemFrame,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 1, 0),
                            Text = "",
                            AutoButtonColor = false,
                        })
                        local isSelected = tostring(item) == tostring(obj.Value)
                        local itemTxt = createInstance("TextLabel", {
                            Parent = itemBtn,
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0, 8, 0, 0),
                            Size = UDim2.new(1, -16, 1, 0),
                            Font = isSelected and Enum.Font.GothamBold or Enum.Font.Gotham,
                            Text = tostring(item),
                            TextColor3 = isSelected and theme.Accent or theme.TextSecondary,
                            TextSize = 13,
                            TextXAlignment = Enum.TextXAlignment.Left,
                        })
                        itemBtn.MouseEnter:Connect(function()
                            if tostring(item) ~= tostring(obj.Value) then
                                itemTxt.TextColor3 = theme.Text
                            end
                        end)
                        itemBtn.MouseLeave:Connect(function()
                            if tostring(item) ~= tostring(obj.Value) then
                                itemTxt.TextColor3 = theme.TextSecondary
                            end
                        end)
                        itemBtn.MouseButton1Click:Connect(function()
                            obj:set(item)
                            -- Close dropdown
                            if window._moreBlur.Visible then
                                TweenService:Create(window._moreBlur, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
                                TweenService:Create(window._dropdownSelect, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                                    Position = UDim2.new(1, 182, 0.5, 0),
                                }):Play()
                                task.wait(0.25)
                                window._moreBlur.Visible = false
                            end
                        end)
                    end
                end
                scrollList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
            end

            searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                populate(searchBox.Text)
            end)
            listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                scrollList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
            end)

            populate("")

            -- Open/Close logic
            button.MouseButton1Click:Connect(function()
                if not window._moreBlur.Visible then
                    populate("")
                    searchBox.Text = ""
                    window._dropPageLayout:JumpTo(selectFrame)
                    window._moreBlur.Visible = true
                    TweenService:Create(window._moreBlur, TweenInfo.new(0.25), { BackgroundTransparency = 0.5 }):Play()
                    TweenService:Create(window._dropdownSelect, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.new(1, -16, 0.5, 0),
                    }):Play()
                end
            end)

            function obj:set(value)
                obj.Value = value
                valueLabel.Text = tostring(value)
                callback(value)
            end

            function obj:refresh(newItems)
                obj.Items = newItems
                if not table.find(obj.Items, obj.Value) then
                    obj.Value = obj.Items[1] or "..."
                    valueLabel.Text = tostring(obj.Value)
                end
                populate("")
            end

            local flag = options.Flag or name
            if flag then window._flags[flag] = obj end
            return obj
        end

        function tab:createMultiDropdown(options)
            options = options or {}
            local name = options.Name or "Multi Dropdown"
            local items = options.Items or options.Values or {}
            local default = options.Default or options.Value or {}
            local callback = options.Callback or function() end

            if type(default) ~= "table" then default = {} end
            local selected = default

            local obj = { Value = selected, Items = items }

            local function getSelectedText()
                if #selected == 0 then return "None" end
                if #selected == 1 then return tostring(selected[1]) end
                return #selected .. " Selected"
            end

            local frame = createInstance("Frame", {
                Parent = tab._currentSectionContainer or tabPage,
                BackgroundColor3 = theme.ElementBg,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 38),
            })
            createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = frame })
            createInstance("UIStroke", { Color = theme.Outline, Transparency = 0.5, Thickness = 1, Parent = frame })

            local label = createInstance("TextLabel", {
                Parent = frame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -60, 1, 0),
                Font = Enum.Font.GothamMedium,
                Text = name,
                TextColor3 = theme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            local valueLabel = createInstance("TextLabel", {
                Parent = frame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -34, 1, 0),
                Font = Enum.Font.Gotham,
                Text = getSelectedText(),
                TextColor3 = theme.TextSecondary,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right,
            })

            local icon = createInstance("ImageLabel", {
                Parent = frame,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -26, 0.5, -8),
                Size = UDim2.new(0, 16, 0, 16),
                Image = "rbxassetid://6031091004",
                ImageColor3 = theme.TextSecondary,
                Rotation = -90,
            })

            local button = createInstance("TextButton", {
                Parent = frame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Text = "",
            })

            -- Dropdown page
            local selectFrame = createInstance("Frame", {
                Parent = window._dropdownFolder,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                LayoutOrder = window._dropdownLayoutOrder,
            })
            window._dropdownLayoutOrder = window._dropdownLayoutOrder + 1

            local searchBox = createInstance("TextBox", {
                Parent = selectFrame,
                BackgroundColor3 = theme.Background,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 28),
                Font = Enum.Font.Gotham,
                PlaceholderText = "Search...",
                Text = "",
                TextColor3 = theme.Text,
                PlaceholderColor3 = theme.TextSecondary,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
            })
            createInstance("UIPadding", { Parent = searchBox, PaddingLeft = UDim.new(0, 8) })
            createInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = searchBox })

            local scrollList = createInstance("ScrollingFrame", {
                Parent = selectFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 35),
                Size = UDim2.new(1, 0, 1, -35),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = theme.Accent,
                BorderSizePixel = 0,
            })
            local listLayout = createInstance("UIListLayout", {
                Parent = scrollList,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
            })

            local function populate(filter)
                filter = filter:lower()
                for _, c in pairs(scrollList:GetChildren()) do
                    if c:IsA("Frame") then c:Destroy() end
                end
                for _, item in ipairs(obj.Items) do
                    if filter == "" or tostring(item):lower():find(filter) then
                        local itemFrame = createInstance("Frame", {
                            Parent = scrollList,
                            BackgroundColor3 = theme.ElementBg,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 26),
                        })
                        local itemBtn = createInstance("TextButton", {
                            Parent = itemFrame,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 1, 0),
                            Text = "",
                            AutoButtonColor = false,
                        })
                        local isSelected = table.find(selected, item) ~= nil
                        local checkbox = createInstance("Frame", {
                            Parent = itemBtn,
                            BackgroundColor3 = isSelected and theme.Accent or theme.Background,
                            BorderSizePixel = 0,
                            Position = UDim2.new(0, 8, 0.5, -7),
                            Size = UDim2.new(0, 14, 0, 14),
                        })
                        createInstance("UICorner", { CornerRadius = UDim.new(0, 3), Parent = checkbox })
                        local checkMark = createInstance("ImageLabel", {
                            Parent = checkbox,
                            BackgroundTransparency = 1,
                            Image = "rbxassetid://6031094667",
                            Size = UDim2.new(1, 2, 1, 2),
                            Position = UDim2.new(0, -1, 0, -1),
                            ImageTransparency = isSelected and 0 or 1,
                        })
                        local itemTxt = createInstance("TextLabel", {
                            Parent = itemBtn,
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0, 30, 0, 0),
                            Size = UDim2.new(1, -30, 1, 0),
                            Font = isSelected and Enum.Font.GothamBold or Enum.Font.Gotham,
                            Text = tostring(item),
                            TextColor3 = isSelected and theme.Text or theme.TextSecondary,
                            TextSize = 13,
                            TextXAlignment = Enum.TextXAlignment.Left,
                        })
                        itemBtn.MouseButton1Click:Connect(function()
                            local idx = table.find(selected, item)
                            if idx then
                                table.remove(selected, idx)
                                TweenService:Create(checkbox, TweenInfo.new(0.2), { BackgroundColor3 = theme.Background }):Play()
                                TweenService:Create(checkMark, TweenInfo.new(0.2), { ImageTransparency = 1 }):Play()
                                TweenService:Create(itemTxt, TweenInfo.new(0.2), { TextColor3 = theme.TextSecondary }):Play()
                                itemTxt.Font = Enum.Font.Gotham
                            else
                                table.insert(selected, item)
                                TweenService:Create(checkbox, TweenInfo.new(0.2), { BackgroundColor3 = theme.Accent }):Play()
                                TweenService:Create(checkMark, TweenInfo.new(0.2), { ImageTransparency = 0 }):Play()
                                TweenService:Create(itemTxt, TweenInfo.new(0.2), { TextColor3 = theme.Text }):Play()
                                itemTxt.Font = Enum.Font.GothamBold
                            end
                            obj.Value = selected
                            valueLabel.Text = getSelectedText()
                            callback(selected)
                        end)
                    end
                end
                scrollList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
            end

            searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                populate(searchBox.Text)
            end)
            listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                scrollList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
            end)

            populate("")

            button.MouseButton1Click:Connect(function()
                if not window._moreBlur.Visible then
                    populate("")
                    searchBox.Text = ""
                    window._dropPageLayout:JumpTo(selectFrame)
                    window._moreBlur.Visible = true
                    TweenService:Create(window._moreBlur, TweenInfo.new(0.25), { BackgroundTransparency = 0.5 }):Play()
                    TweenService:Create(window._dropdownSelect, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.new(1, -16, 0.5, 0),
                    }):Play()
                end
            end)

            function obj:set(values)
                selected = values
                obj.Value = selected
                valueLabel.Text = getSelectedText()
                callback(selected)
                populate(searchBox.Text)
            end

            function obj:refresh(newItems)
                obj.Items = newItems
                local newSel = {}
                for _, s in pairs(selected) do
                    if table.find(obj.Items, s) then table.insert(newSel, s) end
                end
                selected = newSel
                obj:set(selected)
            end

            local flag = options.Flag or name
            if flag then window._flags[flag] = obj end
            return obj
        end

        function tab:createColorPicker(options)
            options = options or {}
            local name = options.Name or "Color Picker"
            local default = options.Default or Color3.fromRGB(255, 255, 255)
            local callback = options.Callback or function() end

            local h, s, v = default:ToHSV()
            local colorVal = default
            local open = false

            local frame = createInstance("Frame", {
                Parent = tab._currentSectionContainer or tabPage,
                BackgroundColor3 = theme.ElementBg,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 38),
                ClipsDescendants = true,
            })
            createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = frame })
            createInstance("UIStroke", { Color = theme.Outline, Transparency = 0.5, Thickness = 1, Parent = frame })

            local label = createInstance("TextLabel", {
                Parent = frame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -60, 0, 38),
                Font = Enum.Font.GothamMedium,
                Text = name,
                TextColor3 = theme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            local preview = createInstance("Frame", {
                Parent = frame,
                BackgroundColor3 = default,
                Position = UDim2.new(1, -40, 0, 9),
                Size = UDim2.new(0, 28, 0, 20),
            })
            createInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = preview })

            local button = createInstance("TextButton", {
                Parent = frame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 38),
                Text = "",
            })

            local pickerContainer = createInstance("Frame", {
                Parent = frame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 42),
                Size = UDim2.new(1, -24, 0, 160),
                Visible = true,
            })

            -- SV Box
            local svBox = createInstance("ImageButton", {
                Parent = pickerContainer,
                BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, 120),
                Image = "rbxassetid://4155801252",
                AutoButtonColor = false,
            })
            createInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = svBox })

            local svCursor = createInstance("Frame", {
                Parent = svBox,
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                Position = UDim2.new(s, -3, 1 - v, -3),
                Size = UDim2.new(0, 6, 0, 6),
                ZIndex = 2,
            })
            createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = svCursor })
            createInstance("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Parent = svCursor })

            -- Hue Bar
            local hueBar = createInstance("ImageButton", {
                Parent = pickerContainer,
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, -24),
                Size = UDim2.new(1, 0, 0, 20),
                AutoButtonColor = false,
            })
            createInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = hueBar })
            createInstance("UIGradient", {
                Parent = hueBar,
                Rotation = 0,
                Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
                }
            })

            local hueCursor = createInstance("Frame", {
                Parent = hueBar,
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                Position = UDim2.new(h, -3, 0, -2),
                Size = UDim2.new(0, 6, 1, 4),
                ZIndex = 2,
            })
            createInstance("UICorner", { CornerRadius = UDim.new(0, 2), Parent = hueCursor })
            createInstance("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Parent = hueCursor })

            local function updateColor()
                colorVal = Color3.fromHSV(h, s, v)
                preview.BackgroundColor3 = colorVal
                svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                callback(colorVal)
            end

            local draggingSV = false
            local draggingHue = false

            svBox.MouseButton1Down:Connect(function() draggingSV = true end)
            hueBar.MouseButton1Down:Connect(function() draggingHue = true end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSV = false
                    draggingHue = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    if draggingSV then
                        local rx = math.clamp((input.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
                        local ry = math.clamp((input.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
                        s = rx
                        v = 1 - ry
                        svCursor.Position = UDim2.new(s, -3, 1 - v, -3)
                        updateColor()
                    elseif draggingHue then
                        local rx = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
                        h = rx
                        hueCursor.Position = UDim2.new(h, -3, 0, -2)
                        updateColor()
                    end
                end
            end)

            button.MouseButton1Click:Connect(function()
                open = not open
                TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                    Size = UDim2.new(1, 0, 0, open and 200 or 38),
                }):Play()
            end)

            local obj = { Value = default }
            function obj:set(val)
                obj.Value = val
                colorVal = val
                local h2, s2, v2 = val:ToHSV()
                h, s, v = h2, s2, v2
                preview.BackgroundColor3 = val
                svBox.BackgroundColor3 = Color3.fromHSV(h2, 1, 1)
                svCursor.Position = UDim2.new(s2, -3, 1 - v2, -3)
                hueCursor.Position = UDim2.new(h2, -3, 0, -2)
                callback(val)
            end

            local flag = options.Flag or name
            if flag then window._flags[flag] = obj end
            return obj
        end

        function tab:createKeybind(options)
            options = options or {}
            local name = options.Name or "Keybind"
            local default = options.Default or Enum.KeyCode.RightControl
            local callback = options.Callback or function() end

            local function keybindLabel()
                return (default == Enum.KeyCode.Unknown) and "None" or default.Name
            end

            local frame = createInstance("Frame", {
                Parent = tab._currentSectionContainer or tabPage,
                BackgroundColor3 = theme.ElementBg,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 38),
            })
            createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = frame })
            createInstance("UIStroke", { Color = theme.Outline, Transparency = 0.5, Thickness = 1, Parent = frame })

            local label = createInstance("TextLabel", {
                Parent = frame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -60, 1, 0),
                Font = Enum.Font.GothamMedium,
                Text = name,
                TextColor3 = theme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            local keybindButton = createInstance("TextButton", {
                Parent = frame,
                BackgroundColor3 = theme.Background,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                Position = UDim2.new(1, -95, 0.5, -12),
                Size = UDim2.new(0, 85, 0, 24),
                Font = Enum.Font.Gotham,
                Text = keybindLabel(),
                TextColor3 = theme.TextSecondary,
                TextSize = 13,
                ClipsDescendants = true,
            })
            createInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = keybindButton })
            createInstance("UIStroke", { Color = theme.Outline, Transparency = 0.7, Thickness = 1, Parent = keybindButton })

            local binding = false
            local obj = { Value = default }

            local function endBindSession()
                if binding then
                    binding = false
                    keybindButton.Text = keybindLabel()
                    TweenService:Create(keybindButton, TweenInfo.new(0.2), { TextColor3 = theme.TextSecondary }):Play()
                    voraLib._keybindSession = nil
                end
            end

            function obj:set(val)
                obj.Value = val
                default = val
                keybindButton.Text = (val == Enum.KeyCode.Unknown) and "None" or val.Name
            end

            keybindButton.MouseButton2Click:Connect(function()
                if binding then endBindSession() end
                default = Enum.KeyCode.Unknown
                obj.Value = default
                keybindButton.Text = "None"
                TweenService:Create(keybindButton, TweenInfo.new(0.2), { TextColor3 = theme.TextSecondary }):Play()
            end)

            keybindButton.MouseButton1Click:Connect(function()
                if voraLib._keybindSession then
                    voraLib._keybindSession()
                end
                voraLib._keybindSession = endBindSession
                binding = true
                keybindButton.Text = "..."
                TweenService:Create(keybindButton, TweenInfo.new(0.2), { TextColor3 = theme.Accent }):Play()
            end)

            UserInputService.InputBegan:Connect(function(input)
                if binding then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                            default = Enum.KeyCode.Unknown
                            obj.Value = default
                            keybindButton.Text = "None"
                            binding = false
                            voraLib._keybindSession = nil
                            TweenService:Create(keybindButton, TweenInfo.new(0.2), { TextColor3 = theme.TextSecondary }):Play()
                        else
                            default = input.KeyCode
                            obj.Value = default
                            keybindButton.Text = default.Name
                            binding = false
                            voraLib._keybindSession = nil
                            TweenService:Create(keybindButton, TweenInfo.new(0.2), { TextColor3 = theme.TextSecondary }):Play()
                            callback(default)
                        end
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                        endBindSession()
                    end
                else
                    if default ~= Enum.KeyCode.Unknown and input.KeyCode == default then
                        callback(default)
                    end
                end
            end)

            local flag = options.Flag or name
            if flag then window._flags[flag] = obj end
            return obj
        end

        return tab
    end

    -- ============================================
    -- CONFIG MANAGEMENT
    -- ============================================
    function window:saveConfig(folderName, fileName)
        if not writefile then
            warn("[voraLib] writefile not available")
            return false, "writefile unavailable"
        end

        local config = { _version = "2.0.0" }
        for flag, obj in pairs(self._flags) do
            local val = obj.Value
            if typeof(val) == "Color3" then
                val = { r = val.R, g = val.G, b = val.B, isColor = true }
            elseif typeof(val) == "EnumItem" then
                val = { name = val.Name, isKeybind = true }
            end
            config[flag] = val
        end

        if isfolder and not isfolder(folderName) and makefolder then
            makefolder(folderName)
        end

        local path = folderName .. "/" .. fileName .. ".json"
        local ok, err = pcall(function()
            writefile(path, HttpService:JSONEncode(config))
        end)
        if not ok then return false, tostring(err) end
        return true
    end

    function window:loadConfig(folderName, fileName)
        if not (isfile and readfile) then
            warn("[voraLib] readfile not available")
            return false, "readfile unavailable"
        end

        local path = folderName .. "/" .. fileName .. ".json"
        if not isfile(path) then
            return false, "config not found"
        end

        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(path))
        end)
        if not ok or type(decoded) ~= "table" then
            return false, "invalid config"
        end

        for flag, val in pairs(decoded) do
            if flag ~= "_version" and self._flags[flag] then
                if type(val) == "table" then
                    if val.isColor and val.r and val.g and val.b then
                        val = Color3.new(val.r, val.g, val.b)
                    elseif val.isKeybind and val.name then
                        val = Enum.KeyCode[val.name]
                    end
                end
                self._flags[flag]:set(val)
            end
        end
        return true
    end

    return window
end

-- ============================================
-- CLEANUP
-- ============================================
function voraLib:destroy()
    for _, conn in pairs(self._connections) do
        pcall(conn.Disconnect, conn)
    end
    self._connections = {}
    local gui = CoreGui:FindFirstChild("devHub")
    if gui then gui:Destroy() end
end

return voraLib
