--[file name]:nil
local DeltaLib = {}
local cloneref = cloneref or function(...) return ... end
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local Players = cloneref(game:GetService("Players"))
local Player = Players.LocalPlayer
local RunService = cloneref(game:GetService("RunService"))
local TextService = cloneref(game:GetService("TextService"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local HttpService = cloneref(game:GetService("HttpService"))

-- Configuration System
local ConfigSystem = {}
ConfigSystem.Version = "1.3"
ConfigSystem.FolderName = "DeltaLib_Configs"
ConfigSystem.AutoSave = true
ConfigSystem.AutoSaveInterval = 0.1 -- seconds
ConfigSystem.AutoLoad = false -- New: Auto-load config on startup

-- Track open config managers to prevent spam
local OpenConfigManagers = {}

-- Get config path based on environment
local function GetConfigPath()
    if writefile and readfile then
        -- Synapse/Other exploits with file system access
        return ConfigSystem.FolderName
    elseif isfolder and makefolder and readfile and writefile then
        -- KRNL-like file system
        return ConfigSystem.FolderName
    else
        -- No file system access, use DataStores or just memory
        return nil
    end
end

-- Check if file system is available
local function IsFileSystemAvailable()
    return (writefile and readfile) or (isfolder and makefolder and readfile and writefile)
end

-- Initialize config folder
local ConfigPath = GetConfigPath()
if ConfigPath and IsFileSystemAvailable() then
    pcall(function()
        if not isfolder(ConfigPath) then
            makefolder(ConfigPath)
        end
    end)
end

-- Helper functions for error handling
local function SafeCall(func, ...)
    if not func then return nil end
    local success, result = pcall(func, ...)
    if not success then
        warn("DeltaLib Error: " .. tostring(result))
        return nil
    end
    return result
end

local function SafeDestroy(instance)
    if instance and typeof(instance) == "Instance" then
        pcall(function()
            instance:Destroy()
        end)
    end
end

local function SafeConnect(signal, callback)
    if not signal then return nil end
    return pcall(function()
        return signal:Connect(callback)
    end)
end

-- Debounce function to prevent spamming
local function CreateDebounce(delay)
    local lastCall = 0
    return function()
        local now = tick()
        if now - lastCall < delay then
            return true
        end
        lastCall = now
        return false
    end
end

-- Colors - Updated with darker edges
local Colors = {
    Background = Color3.fromRGB(25, 25, 25),
    DarkBackground = Color3.fromRGB(15, 15, 15),
    LightBackground = Color3.fromRGB(35, 35, 35),
    NeonRed = Color3.fromRGB(255, 0, 60),
    DarkNeonRed = Color3.fromRGB(200, 0, 45),
    LightNeonRed = Color3.fromRGB(255, 50, 90),
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(200, 200, 200),
    Border = Color3.fromRGB(35, 35, 35), -- Darker border
    DarkBorder = Color3.fromRGB(20, 20, 20), -- Even darker for edges
    Success = Color3.fromRGB(0, 200, 83),
    Warning = Color3.fromRGB(255, 149, 0),
    Error = Color3.fromRGB(255, 59, 48),
    PanelBackground = Color3.fromRGB(28, 28, 28)
}

-- Improved Draggable Function with Delta Movement and Error Handling
local function MakeDraggable(frame, dragArea)
    if not frame or not dragArea then return end

    local dragToggle = nil
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    local function updateInput(input)
        if not startPos then return end
        local delta = input.Position - dragStart
        pcall(function()
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end)
    end

    SafeConnect(dragArea.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragToggle = true
            dragStart = input.Position
            startPos = frame.Position

            -- Track when input ends
            SafeConnect(input.Changed, function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false
                end
            end)
        end
    end)

    SafeConnect(dragArea.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    SafeConnect(UserInputService.InputChanged, function(input)
        if input == dragInput and dragToggle then
            updateInput(input)
        end
    end)
end

-- Get Player Avatar with error handling
local function GetPlayerAvatar(userId, size)
    local success, result = pcall(function()
        size = size or "420x420"
        return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=" .. size:split("x")[1] .. "&height=" .. size:split("x")[2] .. "&format=png"
    end)

    if not success then
        warn("Failed to get avatar: " .. tostring(result))
        return "rbxassetid://7784647711" -- Default avatar fallback
    end

    return result
end

-- Create UI Elements
function DeltaLib:CreateWindow(title, size)
    local Window = {}
    size = size or UDim2.new(0, 400, 0, 300) -- Smaller default size

    -- Main GUI
    local DeltaLibGUI = Instance.new("ScreenGui")
    DeltaLibGUI.Name = "DeltaLibGUI"
    DeltaLibGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    DeltaLibGUI.ResetOnSpawn = false

    -- Try to parent to CoreGui if possible (for exploits)
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(DeltaLibGUI)
            DeltaLibGUI.Parent = CoreGui
        elseif gethui then
            DeltaLibGUI.Parent = gethui()
        else
            DeltaLibGUI.Parent = CoreGui
        end
    end)

    if not DeltaLibGUI.Parent then
        pcall(function()
            DeltaLibGUI.Parent = Player:WaitForChild("PlayerGui")
        end)
    end

    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = size
    MainFrame.Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2)
    MainFrame.BackgroundColor3 = Colors.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = DeltaLibGUI

    -- Add rounded corners
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 4) -- Smaller corner radius
    UICorner.Parent = MainFrame

    -- Add shadow
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.BackgroundTransparency = 1
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    Shadow.Size = UDim2.new(1, 25, 1, 25) -- Smaller shadow
    Shadow.ZIndex = -1
    Shadow.Image = "rbxassetid://5554236805"
    Shadow.ImageColor3 = Colors.NeonRed
    Shadow.ImageTransparency = 0.6
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    Shadow.Parent = MainFrame

    -- Add border for main frame
    local MainFrameStroke = Instance.new("UIStroke")
    MainFrameStroke.Color = Colors.DarkBorder
    MainFrameStroke.Thickness = 1
    MainFrameStroke.Parent = MainFrame

    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 25) -- Smaller title bar
    TitleBar.BackgroundColor3 = Colors.DarkBackground
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame

    local TitleBarCorner = Instance.new("UICorner")
    TitleBarCorner.CornerRadius = UDim.new(0, 4) -- Smaller corner radius
    TitleBarCorner.Parent = TitleBar

    local TitleBarCover = Instance.new("Frame")
    TitleBarCover.Name = "TitleBarCover"
    TitleBarCover.Size = UDim2.new(1, 0, 0.5, 0)
    TitleBarCover.Position = UDim2.new(0, 0, 0.5, 0)
    TitleBarCover.BackgroundColor3 = Colors.DarkBackground
    TitleBarCover.BorderSizePixel = 0
    TitleBarCover.Parent = TitleBar

    -- Add border to title bar
    local TitleBarStroke = Instance.new("UIStroke")
    TitleBarStroke.Color = Colors.DarkBorder
    TitleBarStroke.Thickness = 1
    TitleBarStroke.Parent = TitleBar

    -- User Avatar
    local AvatarContainer = Instance.new("Frame")
    AvatarContainer.Name = "AvatarContainer"
    AvatarContainer.Size = UDim2.new(0, 18, 0, 18) -- Smaller avatar
    AvatarContainer.Position = UDim2.new(0, 4, 0, 3)
    AvatarContainer.BackgroundColor3 = Colors.NeonRed
    AvatarContainer.BorderSizePixel = 0
    AvatarContainer.Parent = TitleBar

    local AvatarCorner = Instance.new("UICorner")
    AvatarCorner.CornerRadius = UDim.new(1, 0)
    AvatarCorner.Parent = AvatarContainer

    local AvatarImage = Instance.new("ImageLabel")
    AvatarImage.Name = "AvatarImage"
    AvatarImage.Size = UDim2.new(1, -2, 1, -2)
    AvatarImage.Position = UDim2.new(0, 1, 0, 1)
    AvatarImage.BackgroundTransparency = 1

    -- Use pcall for getting avatar
    pcall(function()
        AvatarImage.Image = GetPlayerAvatar(Player.UserId, "100x100")
    end)

    AvatarImage.Parent = AvatarContainer

    local AvatarImageCorner = Instance.new("UICorner")
    AvatarImageCorner.CornerRadius = UDim.new(1, 0)
    AvatarImageCorner.Parent = AvatarImage

    -- Username
    local UsernameLabel = Instance.new("TextLabel")
    UsernameLabel.Name = "UsernameLabel"
    UsernameLabel.Size = UDim2.new(0, 120, 1, 0)
    UsernameLabel.Position = UDim2.new(0, 26, 0, 0)
    UsernameLabel.BackgroundTransparency = 1
    UsernameLabel.Text = Player.Name
    UsernameLabel.TextColor3 = Colors.Text
    UsernameLabel.TextSize = 12 -- Smaller text size
    UsernameLabel.Font = Enum.Font.GothamSemibold
    UsernameLabel.TextXAlignment = Enum.TextXAlignment.Left
    UsernameLabel.Parent = TitleBar

    -- Title
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Size = UDim2.new(1, -180, 1, 0)
    TitleLabel.Position = UDim2.new(0, 150, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title or "Delta UI"
    TitleLabel.TextColor3 = Colors.NeonRed
    TitleLabel.TextSize = 12 -- Smaller text size
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
    TitleLabel.Parent = TitleBar

    -- Minimize Button
    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Name = "MinimizeButton"
    MinimizeButton.Size = UDim2.new(0, 20, 0, 20) -- Smaller button
    MinimizeButton.Position = UDim2.new(1, -45, 0, 2) -- Position it to the left of the close button
    MinimizeButton.BackgroundTransparency = 1
    MinimizeButton.Text = "-" -- Minus symbol
    MinimizeButton.TextColor3 = Colors.Text
    MinimizeButton.TextSize = 14 -- Smaller text size
    MinimizeButton.Font = Enum.Font.GothamBold
    MinimizeButton.Parent = TitleBar

    SafeConnect(MinimizeButton.MouseEnter, function()
        MinimizeButton.TextColor3 = Colors.NeonRed
    end)

    SafeConnect(MinimizeButton.MouseLeave, function()
        MinimizeButton.TextColor3 = Colors.Text
    end)

    -- Config Button
    local ConfigButton = Instance.new("TextButton")
    ConfigButton.Name = "ConfigButton"
    ConfigButton.Size = UDim2.new(0, 20, 0, 20) -- Smaller button
    ConfigButton.Position = UDim2.new(1, -68, 0, 2) -- Position it to the left of minimize button
    ConfigButton.BackgroundTransparency = 1
    ConfigButton.Text = "⚙" -- Gear symbol
    ConfigButton.TextColor3 = Colors.Text
    ConfigButton.TextSize = 14 -- Smaller text size
    ConfigButton.Font = Enum.Font.GothamBold
    ConfigButton.Parent = TitleBar

    -- Debounce for config button
    local configButtonDebounce = CreateDebounce(0.5)

    SafeConnect(ConfigButton.MouseEnter, function()
        ConfigButton.TextColor3 = Colors.NeonRed
    end)

    SafeConnect(ConfigButton.MouseLeave, function()
        ConfigButton.TextColor3 = Colors.Text
    end)

    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 20, 0, 20) -- Smaller button
    CloseButton.Position = UDim2.new(1, -22, 0, 2)
    CloseButton.BackgroundTransparency = 1
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Colors.Text
    CloseButton.TextSize = 14 -- Smaller text size
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Parent = TitleBar

    SafeConnect(CloseButton.MouseEnter, function()
        CloseButton.TextColor3 = Colors.NeonRed
    end)

    SafeConnect(CloseButton.MouseLeave, function()
        CloseButton.TextColor3 = Colors.Text
    end)

    SafeConnect(CloseButton.MouseButton1Click, function()
        SafeDestroy(DeltaLibGUI)
    end)

    -- Make window draggable with improved function
    MakeDraggable(MainFrame, TitleBar)

    -- Container for tabs with horizontal scrolling
    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, 0, 0, 25) -- Smaller tab container
    TabContainer.Position = UDim2.new(0, 0, 0, 25)
    TabContainer.BackgroundColor3 = Colors.LightBackground
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = MainFrame

    -- Add border to tab container
    local TabContainerStroke = Instance.new("UIStroke")
    TabContainerStroke.Color = Colors.DarkBorder
    TabContainerStroke.Thickness = 1
    TabContainerStroke.Parent = TabContainer

    -- Left Scroll Button
    local LeftScrollButton = Instance.new("TextButton")
    LeftScrollButton.Name = "LeftScrollButton"
    LeftScrollButton.Size = UDim2.new(0, 20, 0, 25) -- Smaller button
    LeftScrollButton.Position = UDim2.new(0, 0, 0, 0)
    LeftScrollButton.BackgroundColor3 = Colors.DarkBackground
    LeftScrollButton.BorderSizePixel = 0
    LeftScrollButton.Text = "<"
    LeftScrollButton.TextColor3 = Colors.Text
    LeftScrollButton.TextSize = 14 -- Smaller text size
    LeftScrollButton.Font = Enum.Font.GothamBold
    LeftScrollButton.ZIndex = 3
    LeftScrollButton.Parent = TabContainer

    local LeftScrollButtonCorner = Instance.new("UICorner")
    LeftScrollButtonCorner.CornerRadius = UDim.new(0, 3)
    LeftScrollButtonCorner.Parent = LeftScrollButton

    -- Right Scroll Button
    local RightScrollButton = Instance.new("TextButton")
    RightScrollButton.Name = "RightScrollButton"
    RightScrollButton.Size = UDim2.new(0, 20, 0, 25) -- Smaller button
    RightScrollButton.Position = UDim2.new(1, -20, 0, 0)
    RightScrollButton.BackgroundColor3 = Colors.DarkBackground
    RightScrollButton.BorderSizePixel = 0
    RightScrollButton.Text = ">"
    RightScrollButton.TextColor3 = Colors.Text
    RightScrollButton.TextSize = 14 -- Smaller text size
    RightScrollButton.Font = Enum.Font.GothamBold
    RightScrollButton.ZIndex = 3
    RightScrollButton.Parent = TabContainer

    local RightScrollButtonCorner = Instance.new("UICorner")
    RightScrollButtonCorner.CornerRadius = UDim.new(0, 3)
    RightScrollButtonCorner.Parent = RightScrollButton

    -- Tab Scroll Frame
    local TabScrollFrame = Instance.new("ScrollingFrame")
    TabScrollFrame.Name = "TabScrollFrame"
    TabScrollFrame.Size = UDim2.new(1, -40, 1, 0) -- Leave space for scroll buttons
    TabScrollFrame.Position = UDim2.new(0, 20, 0, 0) -- Center between scroll buttons
    TabScrollFrame.BackgroundTransparency = 1
    TabScrollFrame.BorderSizePixel = 0
    TabScrollFrame.ScrollBarThickness = 0 -- Hide scrollbar
    TabScrollFrame.ScrollingDirection = Enum.ScrollingDirection.X
    TabScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated dynamically
    TabScrollFrame.Parent = TabContainer

    -- Tab Buttons Container
    local TabButtons = Instance.new("Frame")
    TabButtons.Name = "TabButtons"
    TabButtons.Size = UDim2.new(1, 0, 1, 0)
    TabButtons.BackgroundTransparency = 1
    TabButtons.Parent = TabScrollFrame

    local TabButtonsLayout = Instance.new("UIListLayout")
    TabButtonsLayout.FillDirection = Enum.FillDirection.Horizontal
    TabButtonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    TabButtonsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabButtonsLayout.Padding = UDim.new(0, 4) -- Smaller padding
    TabButtonsLayout.Parent = TabButtons

    -- Add padding to the first tab
    local TabButtonsPadding = Instance.new("UIPadding")
    TabButtonsPadding.PaddingLeft = UDim.new(0, 4) -- Smaller padding
    TabButtonsPadding.PaddingRight = UDim.new(0, 4) -- Smaller padding
    TabButtonsPadding.Parent = TabButtons

    -- Update tab scroll canvas size when tabs change
    SafeConnect(TabButtonsLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        pcall(function()
            TabScrollFrame.CanvasSize = UDim2.new(0, TabButtonsLayout.AbsoluteContentSize.X, 0, 0)
        end)
    end)

    -- Scroll buttons functionality
    local scrollAmount = 100 -- Smaller scroll amount
    local scrollDuration = 0.3 -- Duration of scroll animation

    -- Function to scroll with animation
    local function ScrollTabs(direction)
        pcall(function()
            local currentPos = TabScrollFrame.CanvasPosition.X
            local targetPos

            if direction == "left" then
                targetPos = math.max(currentPos - scrollAmount, 0)
            else
                local maxScroll = TabScrollFrame.CanvasSize.X.Offset - TabScrollFrame.AbsoluteSize.X
                targetPos = math.min(currentPos + scrollAmount, maxScroll)
            end

            -- Create a smooth scrolling animation
            local tweenInfo = TweenInfo.new(scrollDuration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            local tween = TweenService:Create(TabScrollFrame, tweenInfo, {CanvasPosition = Vector2.new(targetPos, 0)})
            tween:Play()
        end)
    end

    -- Button hover effects
    SafeConnect(LeftScrollButton.MouseEnter, function()
        TweenService:Create(LeftScrollButton, TweenInfo.new(0.2), {BackgroundColor3 = Colors.NeonRed}):Play()
    end)

    SafeConnect(LeftScrollButton.MouseLeave, function()
        TweenService:Create(LeftScrollButton, TweenInfo.new(0.2), {BackgroundColor3 = Colors.DarkBackground}):Play()
    end)

    SafeConnect(RightScrollButton.MouseEnter, function()
        TweenService:Create(RightScrollButton, TweenInfo.new(0.2), {BackgroundColor3 = Colors.NeonRed}):Play()
    end)

    SafeConnect(RightScrollButton.MouseLeave, function()
        TweenService:Create(RightScrollButton, TweenInfo.new(0.2), {BackgroundColor3 = Colors.DarkBackground}):Play()
    end)

    -- Connect scroll buttons
    SafeConnect(LeftScrollButton.MouseButton1Click, function()
        ScrollTabs("left")
    end)

    SafeConnect(RightScrollButton.MouseButton1Click, function()
        ScrollTabs("right")
    end)

    -- Add continuous scrolling when holding the button
    local isScrollingLeft = false
    local isScrollingRight = false

    SafeConnect(LeftScrollButton.MouseButton1Down, function()
        isScrollingLeft = true

        -- Initial scroll
        ScrollTabs("left")

        -- Continue scrolling while button is held
        spawn(function()
            local initialDelay = 0.5 -- Wait before starting continuous scroll
            wait(initialDelay)

            while isScrollingLeft do
                ScrollTabs("left")
                wait(0.2) -- Scroll interval
            end
        end)
    end)

    SafeConnect(LeftScrollButton.MouseButton1Up, function()
        isScrollingLeft = false
    end)

    SafeConnect(LeftScrollButton.MouseLeave, function()
        isScrollingLeft = false
    end)

    SafeConnect(RightScrollButton.MouseButton1Down, function()
        isScrollingRight = true

        -- Initial scroll
        ScrollTabs("right")

        -- Continue scrolling while button is held
        spawn(function()
            local initialDelay = 0.5 -- Wait before starting continuous scroll
            wait(initialDelay)

            while isScrollingRight do
                ScrollTabs("right")
                wait(0.2) -- Scroll interval
            end
        end)
    end)

    SafeConnect(RightScrollButton.MouseButton1Up, function()
        isScrollingRight = false
    end)

    SafeConnect(RightScrollButton.MouseLeave, function()
        isScrollingRight = false
    end)

    -- Content Container
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, 0, 1, -50) -- Smaller content container
    ContentContainer.Position = UDim2.new(0, 0, 0, 50)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = MainFrame

    -- Track minimized state
    local isMinimized = false
    local originalSize = size

    -- Minimize/Restore function
    SafeConnect(MinimizeButton.MouseButton1Click, function()
        isMinimized = not isMinimized

        if isMinimized then
            -- Save current size before minimizing if it's been resized
            originalSize = MainFrame.Size

            -- Minimize animation
            pcall(function()
                TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 25)
                }):Play()
            end)

            -- Hide content
            ContentContainer.Visible = false
            TabContainer.Visible = false

            -- Change minimize button to restore symbol
            MinimizeButton.Text = "+"
        else
            -- Restore animation
            pcall(function()
                TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Size = originalSize
                }):Play()
            end)

            -- Show content (with slight delay to match animation)
            task.delay(0.1, function()
                ContentContainer.Visible = true
                TabContainer.Visible = true
            end)

            -- Change restore button back to minimize symbol
            MinimizeButton.Text = "-"
        end
    end)

    -- Tab Management
    local Tabs = {}
    local SelectedTab = nil

    -- Configuration Management
    local Configurations = {}
    local ConfigCallbacks = {}
    local CurrentConfig = "default"
    local ConfigSettings = {
        AutoLoadConfig = false,
        LastLoadedConfig = ""
    }

    -- Function to create config file name
    local function GetConfigFileName(configName)
        local safeTitle = title or "DeltaUI"
        safeTitle = safeTitle:gsub("[^%w%s]", ""):gsub("%s+", "_")
        return safeTitle .. "_" .. (configName or "default") .. ".json"
    end

    -- Function to save configuration settings
    local function SaveConfigSettings()
        if not IsFileSystemAvailable() then
            return false
        end
        
        local settingsData = {
            Version = ConfigSystem.Version,
            AutoLoadConfig = ConfigSettings.AutoLoadConfig,
            LastLoadedConfig = ConfigSettings.LastLoadedConfig
        }
        
        -- Convert to JSON
        local jsonData
        pcall(function()
            jsonData = HttpService:JSONEncode(settingsData)
        end)
        
        if not jsonData then
            return false
        end
        
        -- Save to file
        local success, result = pcall(function()
            local fileName = "config_settings.json"
            local filePath = ConfigPath .. "/" .. fileName
            writefile(filePath, jsonData)
            return true
        end)
        
        return success
    end

    -- Function to load configuration settings
    local function LoadConfigSettings()
        if not IsFileSystemAvailable() then
            return false
        end
        
        local fileName = "config_settings.json"
        local filePath = ConfigPath .. "/" .. fileName
        
        if not isfile(filePath) then
            return false
        end
        
        -- Read from file
        local jsonData
        local success, result = pcall(function()
            jsonData = readfile(filePath)
            return true
        end)
        
        if not success or not jsonData then
            return false
        end
        
        -- Parse JSON
        local settingsData
        pcall(function()
            settingsData = HttpService:JSONDecode(jsonData)
        end)
        
        if not settingsData then
            return false
        end
        
        -- Apply settings
        ConfigSettings.AutoLoadConfig = settingsData.AutoLoadConfig or false
        ConfigSettings.LastLoadedConfig = settingsData.LastLoadedConfig or ""
        
        return true
    end

    -- Function to save configuration
    local function SaveConfiguration(configName)
        configName = configName or CurrentConfig
        
        if not IsFileSystemAvailable() then
            return false
        end
        
        local configData = {
            Version = ConfigSystem.Version,
            LastSaved = os.time(),
            WindowTitle = title,
            Settings = {}
        }
        
        -- Collect all settings
        for elementId, callbackInfo in pairs(ConfigCallbacks) do
            if callbackInfo.GetValue then
                local value = SafeCall(callbackInfo.GetValue)
                if value ~= nil then
                    configData.Settings[elementId] = {
                        Type = callbackInfo.Type,
                        Value = value,
                        Tab = callbackInfo.Tab,
                        Section = callbackInfo.Section
                    }
                end
            end
        end
        
        -- Convert to JSON
        local jsonData
        pcall(function()
            jsonData = HttpService:JSONEncode(configData)
        end)
        
        if not jsonData then
            return false
        end
        
        -- Save to file
        local success, result = pcall(function()
            local fileName = GetConfigFileName(configName)
            local filePath = ConfigPath .. "/" .. fileName
            writefile(filePath, jsonData)
            return true
        end)
        
        if success then
            return true
        else
            return false
        end
    end

    -- Function to load configuration
    local function LoadConfiguration(configName)
        configName = configName or CurrentConfig
        
        if not IsFileSystemAvailable() then
            return false
        end
        
        local fileName = GetConfigFileName(configName)
        local filePath = ConfigPath .. "/" .. fileName
        
        if not isfile(filePath) then
            return false
        end
        
        -- Read from file
        local jsonData
        local success, result = pcall(function()
            jsonData = readfile(filePath)
            return true
        end)
        
        if not success or not jsonData then
            return false
        end
        
        -- Parse JSON
        local configData
        pcall(function()
            configData = HttpService:JSONDecode(jsonData)
        end)
        
        if not configData then
            return false
        end
        
        -- Apply settings
        for elementId, setting in pairs(configData.Settings or {}) do
            local callbackInfo = ConfigCallbacks[elementId]
            if callbackInfo and callbackInfo.SetValue then
                SafeCall(callbackInfo.SetValue, setting.Value)
            end
        end
        
        -- Update last loaded config
        ConfigSettings.LastLoadedConfig = configName
        SaveConfigSettings()
        
        return true
    end

    -- Function to delete configuration
    local function DeleteConfiguration(configName)
        configName = configName or CurrentConfig
        
        if not IsFileSystemAvailable() then
            return false
        end
        
        local fileName = GetConfigFileName(configName)
        local filePath = ConfigPath .. "/" .. fileName
        
        if not isfile(filePath) then
            return false
        end
        
        local success, result = pcall(function()
            delfile(filePath)
            return true
        end)
        
        if success then
            -- If we deleted the current config, reset to default
            if CurrentConfig == configName then
                CurrentConfig = "default"
            end
            return true
        else
            return false
        end
    end

    -- Function to list ALL available configurations (all .json files in folder)
    local function ListAllConfigurations()
        if not IsFileSystemAvailable() then
            return {}
        end
        
        local allConfigs = {}
        pcall(function()
            local files = listfiles(ConfigPath)
            for _, filePath in ipairs(files) do
                local fileName = filePath:match("[^\\/]+$")
                if fileName:match("%.json$") and fileName ~= "config_settings.json" then
                    local configName = fileName:gsub("%.json$", "")
                    -- Extract the base name (remove window title prefix)
                    local baseName = configName:match("^.+_(.+)$") or configName
                    table.insert(allConfigs, {
                        FullName = configName,
                        BaseName = baseName,
                        FileName = fileName
                    })
                end
            end
        end)
        
        return allConfigs
    end

    -- Function to list configurations for this specific window
    local function ListConfigurations()
        if not IsFileSystemAvailable() then
            return {}
        end
        
        local windowConfigs = {}
        local allConfigs = ListAllConfigurations()
        local safeTitle = title or "DeltaUI"
        safeTitle = safeTitle:gsub("[^%w%s]", ""):gsub("%s+", "_")
        
        for _, config in ipairs(allConfigs) do
            if config.FullName:match("^" .. safeTitle .. "_") then
                table.insert(windowConfigs, config.BaseName)
            end
        end
        
        return windowConfigs
    end

    -- Function to register element for configuration
    local function RegisterConfigElement(elementId, elementType, tabName, sectionName, getCallback, setCallback)
        ConfigCallbacks[elementId] = {
            Type = elementType,
            Tab = tabName,
            Section = sectionName,
            GetValue = getCallback,
            SetValue = setCallback
        }
    end

    -- Function to unregister element from configuration
    local function UnregisterConfigElement(elementId)
        ConfigCallbacks[elementId] = nil
    end

    -- Function to show compact configuration manager
    local function ShowConfigManager()
        -- Prevent spam with debounce
        if configButtonDebounce() then
            return
        end
        
        -- Close any existing config manager for this window
        if OpenConfigManagers[DeltaLibGUI] then
            SafeDestroy(OpenConfigManagers[DeltaLibGUI])
        end
        
        -- Get all available configurations
        local allConfigs = ListAllConfigurations()
        local windowConfigs = ListConfigurations()
        
        -- Calculate dynamic height - Made more compact
        local baseHeight = 350  -- Slightly taller for new toggle
        local configListHeight = 100
        
        -- Create config manager window - Made more compact
        local ConfigWindow = Instance.new("Frame")
        ConfigWindow.Name = "ConfigManager"
        ConfigWindow.Size = UDim2.new(0, 300, 0, baseHeight)
        ConfigWindow.Position = UDim2.new(0.5, -150, 0.5, -baseHeight/2)
        ConfigWindow.BackgroundColor3 = Colors.Background
        ConfigWindow.BorderSizePixel = 0
        ConfigWindow.ZIndex = 100
        ConfigWindow.Parent = DeltaLibGUI
        
        -- Store reference to prevent spam
        OpenConfigManagers[DeltaLibGUI] = ConfigWindow

        local ConfigCorner = Instance.new("UICorner")
        ConfigCorner.CornerRadius = UDim.new(0, 4)
        ConfigCorner.Parent = ConfigWindow

        -- Add darker border
        local ConfigBorder = Instance.new("UIStroke")
        ConfigBorder.Color = Colors.DarkBorder
        ConfigBorder.Thickness = 2
        ConfigBorder.Parent = ConfigWindow

        local ConfigTitleBar = Instance.new("Frame")
        ConfigTitleBar.Name = "ConfigTitleBar"
        ConfigTitleBar.Size = UDim2.new(1, 0, 0, 25)
        ConfigTitleBar.BackgroundColor3 = Colors.DarkBackground
        ConfigTitleBar.BorderSizePixel = 0
        ConfigTitleBar.Parent = ConfigWindow

        local ConfigTitleBarCorner = Instance.new("UICorner")
        ConfigTitleBarCorner.CornerRadius = UDim.new(0, 3)
        ConfigTitleBarCorner.Parent = ConfigTitleBar

        -- Add border to title bar
        local TitleBarBorder = Instance.new("UIStroke")
        TitleBarBorder.Color = Colors.DarkBorder
        TitleBarBorder.Thickness = 1
        TitleBarBorder.Parent = ConfigTitleBar

        local ConfigTitle = Instance.new("TextLabel")
        ConfigTitle.Name = "ConfigTitle"
        ConfigTitle.Size = UDim2.new(1, 0, 1, 0)
        ConfigTitle.BackgroundTransparency = 1
        ConfigTitle.Text = "Config Manager"
        ConfigTitle.TextColor3 = Colors.NeonRed
        ConfigTitle.TextSize = 12
        ConfigTitle.Font = Enum.Font.GothamBold
        ConfigTitle.TextXAlignment = Enum.TextXAlignment.Center
        ConfigTitle.Parent = ConfigTitleBar

        local ConfigCloseButton = Instance.new("TextButton")
        ConfigCloseButton.Name = "ConfigCloseButton"
        ConfigCloseButton.Size = UDim2.new(0, 18, 0, 18)
        ConfigCloseButton.Position = UDim2.new(1, -20, 0, 3)
        ConfigCloseButton.BackgroundTransparency = 1
        ConfigCloseButton.Text = "X"
        ConfigCloseButton.TextColor3 = Colors.Text
        ConfigCloseButton.TextSize = 12
        ConfigCloseButton.Font = Enum.Font.GothamBold
        ConfigCloseButton.Parent = ConfigTitleBar

        SafeConnect(ConfigCloseButton.MouseButton1Click, function()
            ConfigWindow:Destroy()
            OpenConfigManagers[DeltaLibGUI] = nil
        end)

        SafeConnect(ConfigCloseButton.MouseEnter, function()
            ConfigCloseButton.TextColor3 = Colors.NeonRed
        end)

        SafeConnect(ConfigCloseButton.MouseLeave, function()
            ConfigCloseButton.TextColor3 = Colors.Text
        end)

        MakeDraggable(ConfigWindow, ConfigTitleBar)

        local ConfigContent = Instance.new("ScrollingFrame")
        ConfigContent.Name = "ConfigContent"
        ConfigContent.Size = UDim2.new(1, -10, 1, -35)
        ConfigContent.Position = UDim2.new(0, 5, 0, 30)
        ConfigContent.BackgroundTransparency = 1
        ConfigContent.BorderSizePixel = 0
        ConfigContent.ScrollBarThickness = 3
        ConfigContent.ScrollBarImageColor3 = Colors.NeonRed
        ConfigContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
        ConfigContent.ScrollingEnabled = true
        ConfigContent.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
        ConfigContent.Parent = ConfigWindow

        local ConfigLayout = Instance.new("UIListLayout")
        ConfigLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ConfigLayout.Padding = UDim.new(0, 6)
        ConfigLayout.Parent = ConfigContent

        local ConfigPadding = Instance.new("UIPadding")
        ConfigPadding.PaddingTop = UDim.new(0, 6)
        ConfigPadding.PaddingBottom = UDim.new(0, 6)
        ConfigPadding.Parent = ConfigContent

        -- Current Config Section
        local CurrentConfigSection = Instance.new("Frame")
        CurrentConfigSection.Name = "CurrentConfigSection"
        CurrentConfigSection.Size = UDim2.new(1, 0, 0, 65)
        CurrentConfigSection.BackgroundColor3 = Colors.PanelBackground
        CurrentConfigSection.BorderSizePixel = 0
        CurrentConfigSection.LayoutOrder = 1
        CurrentConfigSection.Parent = ConfigContent

        local CurrentConfigCorner = Instance.new("UICorner")
        CurrentConfigCorner.CornerRadius = UDim.new(0, 3)
        CurrentConfigCorner.Parent = CurrentConfigSection

        -- Add border to section
        local SectionBorder = Instance.new("UIStroke")
        SectionBorder.Color = Colors.DarkBorder
        SectionBorder.Thickness = 1
        SectionBorder.Parent = CurrentConfigSection

        local CurrentConfigLabel = Instance.new("TextLabel")
        CurrentConfigLabel.Name = "CurrentConfigLabel"
        CurrentConfigLabel.Size = UDim2.new(1, -10, 0, 18)
        CurrentConfigLabel.Position = UDim2.new(0, 5, 0, 4)
        CurrentConfigLabel.BackgroundTransparency = 1
        CurrentConfigLabel.Text = "Current Configuration"
        CurrentConfigLabel.TextColor3 = Colors.NeonRed
        CurrentConfigLabel.TextSize = 11
        CurrentConfigLabel.Font = Enum.Font.GothamBold
        CurrentConfigLabel.TextXAlignment = Enum.TextXAlignment.Left
        CurrentConfigLabel.Parent = CurrentConfigSection

        local ConfigNameInput = Instance.new("TextBox")
        ConfigNameInput.Name = "ConfigNameInput"
        ConfigNameInput.Size = UDim2.new(1, -10, 0, 22)
        ConfigNameInput.Position = UDim2.new(0, 5, 0, 25)
        ConfigNameInput.BackgroundColor3 = Colors.DarkBackground
        ConfigNameInput.BorderSizePixel = 0
        ConfigNameInput.PlaceholderText = "Enter config name..."
        ConfigNameInput.Text = CurrentConfig
        ConfigNameInput.TextColor3 = Colors.Text
        ConfigNameInput.PlaceholderColor3 = Colors.SubText
        ConfigNameInput.TextSize = 11
        ConfigNameInput.Font = Enum.Font.Gotham
        ConfigNameInput.TextXAlignment = Enum.TextXAlignment.Left
        ConfigNameInput.ClearTextOnFocus = false
        ConfigNameInput.Parent = CurrentConfigSection

        local ConfigNameInputCorner = Instance.new("UICorner")
        ConfigNameInputCorner.CornerRadius = UDim.new(0, 3)
        ConfigNameInputCorner.Parent = ConfigNameInput

        -- Add border to input
        local InputBorder = Instance.new("UIStroke")
        InputBorder.Color = Colors.DarkBorder
        InputBorder.Thickness = 1
        InputBorder.Parent = ConfigNameInput

        local ConfigNameInputPadding = Instance.new("UIPadding")
        ConfigNameInputPadding.PaddingLeft = UDim.new(0, 6)
        ConfigNameInputPadding.Parent = ConfigNameInput

        -- Settings Section - NEW: Added Auto Load Toggle
        local SettingsSection = Instance.new("Frame")
        SettingsSection.Name = "SettingsSection"
        SettingsSection.Size = UDim2.new(1, 0, 0, 40)
        SettingsSection.BackgroundColor3 = Colors.PanelBackground
        SettingsSection.BorderSizePixel = 0
        SettingsSection.LayoutOrder = 2
        SettingsSection.Parent = ConfigContent

        local SettingsCorner = Instance.new("UICorner")
        SettingsCorner.CornerRadius = UDim.new(0, 3)
        SettingsCorner.Parent = SettingsSection

        -- Add border to settings section
        local SettingsBorder = Instance.new("UIStroke")
        SettingsBorder.Color = Colors.DarkBorder
        SettingsBorder.Thickness = 1
        SettingsBorder.Parent = SettingsSection

        local AutoLoadToggle = Instance.new("TextButton")
        AutoLoadToggle.Name = "AutoLoadToggle"
        AutoLoadToggle.Size = UDim2.new(1, -10, 1, -8)
        AutoLoadToggle.Position = UDim2.new(0, 5, 0, 4)
        AutoLoadToggle.BackgroundColor3 = Colors.DarkBackground
        AutoLoadToggle.BorderSizePixel = 0
        AutoLoadToggle.Text = ""
        AutoLoadToggle.Parent = SettingsSection

        local AutoLoadToggleCorner = Instance.new("UICorner")
        AutoLoadToggleCorner.CornerRadius = UDim.new(0, 3)
        AutoLoadToggleCorner.Parent = AutoLoadToggle

        -- Add border to toggle
        local ToggleBorder = Instance.new("UIStroke")
        ToggleBorder.Color = Colors.DarkBorder
        ToggleBorder.Thickness = 1
        ToggleBorder.Parent = AutoLoadToggle

        local AutoLoadLabel = Instance.new("TextLabel")
        AutoLoadLabel.Name = "AutoLoadLabel"
        AutoLoadLabel.Size = UDim2.new(1, -40, 1, 0)
        AutoLoadLabel.BackgroundTransparency = 1
        AutoLoadLabel.Text = "Auto Load Config"
        AutoLoadLabel.TextColor3 = Colors.Text
        AutoLoadLabel.TextSize = 11
        AutoLoadLabel.Font = Enum.Font.Gotham
        AutoLoadLabel.TextXAlignment = Enum.TextXAlignment.Left
        AutoLoadLabel.Parent = AutoLoadToggle

        local AutoLoadPadding = Instance.new("UIPadding")
        AutoLoadPadding.PaddingLeft = UDim.new(0, 8)
        AutoLoadPadding.Parent = AutoLoadLabel

        local AutoLoadToggleButton = Instance.new("Frame")
        AutoLoadToggleButton.Name = "AutoLoadToggleButton"
        AutoLoadToggleButton.Size = UDim2.new(0, 28, 0, 14)
        AutoLoadToggleButton.Position = UDim2.new(1, -32, 0.5, -7)
        AutoLoadToggleButton.BackgroundColor3 = Colors.DarkBackground
        AutoLoadToggleButton.BorderSizePixel = 0
        AutoLoadToggleButton.Parent = AutoLoadToggle

        local AutoLoadToggleCorner2 = Instance.new("UICorner")
        AutoLoadToggleCorner2.CornerRadius = UDim.new(1, 0)
        AutoLoadToggleCorner2.Parent = AutoLoadToggleButton

        local AutoLoadToggleCircle = Instance.new("Frame")
        AutoLoadToggleCircle.Name = "AutoLoadToggleCircle"
        AutoLoadToggleCircle.Size = UDim2.new(0, 10, 0, 10)
        AutoLoadToggleCircle.Position = UDim2.new(0, 2, 0, 2)
        AutoLoadToggleCircle.BackgroundColor3 = Colors.Text
        AutoLoadToggleCircle.BorderSizePixel = 0
        AutoLoadToggleCircle.Parent = AutoLoadToggleButton

        local AutoLoadToggleCircleCorner = Instance.new("UICorner")
        AutoLoadToggleCircleCorner.CornerRadius = UDim.new(1, 0)
        AutoLoadToggleCircleCorner.Parent = AutoLoadToggleCircle

        -- Update auto load toggle appearance
        local function UpdateAutoLoadToggle()
            if ConfigSettings.AutoLoadConfig then
                TweenService:Create(AutoLoadToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Colors.NeonRed}):Play()
                TweenService:Create(AutoLoadToggleCircle, TweenInfo.new(0.2), {Position = UDim2.new(0, 16, 0, 2)}):Play()
            else
                TweenService:Create(AutoLoadToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Colors.DarkBackground}):Play()
                TweenService:Create(AutoLoadToggleCircle, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0, 2)}):Play()
            end
        end

        -- Set initial state
        UpdateAutoLoadToggle()

        -- Auto load toggle logic
        SafeConnect(AutoLoadToggle.MouseButton1Click, function()
            ConfigSettings.AutoLoadConfig = not ConfigSettings.AutoLoadConfig
            UpdateAutoLoadToggle()
            SaveConfigSettings()
        end)

        -- Action Buttons Section
        local ActionButtonsSection = Instance.new("Frame")
        ActionButtonsSection.Name = "ActionButtonsSection"
        ActionButtonsSection.Size = UDim2.new(1, 0, 0, 85)
        ActionButtonsSection.BackgroundColor3 = Colors.PanelBackground
        ActionButtonsSection.BorderSizePixel = 0
        ActionButtonsSection.LayoutOrder = 3
        ActionButtonsSection.Parent = ConfigContent

        local ActionButtonsCorner = Instance.new("UICorner")
        ActionButtonsCorner.CornerRadius = UDim.new(0, 3)
        ActionButtonsCorner.Parent = ActionButtonsSection

        -- Add border to section
        local ActionBorder = Instance.new("UIStroke")
        ActionBorder.Color = Colors.DarkBorder
        ActionBorder.Thickness = 1
        ActionBorder.Parent = ActionButtonsSection

        local ActionButtonsLabel = Instance.new("TextLabel")
        ActionButtonsLabel.Name = "ActionButtonsLabel"
        ActionButtonsLabel.Size = UDim2.new(1, -10, 0, 18)
        ActionButtonsLabel.Position = UDim2.new(0, 5, 0, 4)
        ActionButtonsLabel.BackgroundTransparency = 1
        ActionButtonsLabel.Text = "Actions"
        ActionButtonsLabel.TextColor3 = Colors.NeonRed
        ActionButtonsLabel.TextSize = 11
        ActionButtonsLabel.Font = Enum.Font.GothamBold
        ActionButtonsLabel.TextXAlignment = Enum.TextXAlignment.Left
        ActionButtonsLabel.Parent = ActionButtonsSection

        -- Save Button with debounce
        local saveDebounce = CreateDebounce(0.5)
        local SaveButton = Instance.new("TextButton")
        SaveButton.Name = "SaveButton"
        SaveButton.Size = UDim2.new(1, -10, 0, 22)
        SaveButton.Position = UDim2.new(0, 5, 0, 25)
        SaveButton.BackgroundColor3 = Colors.NeonRed
        SaveButton.BorderSizePixel = 0
        SaveButton.Text = "Save Configuration"
        SaveButton.TextColor3 = Colors.Text
        SaveButton.TextSize = 11
        SaveButton.Font = Enum.Font.Gotham
        SaveButton.Parent = ActionButtonsSection

        local SaveButtonCorner = Instance.new("UICorner")
        SaveButtonCorner.CornerRadius = UDim.new(0, 3)
        SaveButtonCorner.Parent = SaveButton

        -- Add border to button
        local SaveButtonBorder = Instance.new("UIStroke")
        SaveButtonBorder.Color = Colors.DarkBorder
        SaveButtonBorder.Thickness = 1
        SaveButtonBorder.Parent = SaveButton

        SafeConnect(SaveButton.MouseButton1Click, function()
            if saveDebounce() then return end
            
            local newName = ConfigNameInput.Text:gsub("%s+", "")
            if newName == "" then
                newName = "default"
            end
            
            CurrentConfig = newName
            ConfigNameInput.Text = newName
            
            if SaveConfiguration(newName) then
                -- Show success feedback
                SaveButton.Text = "✓ Saved!"
                SaveButton.BackgroundColor3 = Colors.Success
                
                task.wait(0.8)
                
                SaveButton.Text = "Save Configuration"
                SaveButton.BackgroundColor3 = Colors.NeonRed
                
                -- Refresh config list
                RefreshConfigList()
            else
                -- Show error feedback
                SaveButton.Text = "✗ Failed!"
                SaveButton.BackgroundColor3 = Colors.Error
                
                task.wait(0.8)
                
                SaveButton.Text = "Save Configuration"
                SaveButton.BackgroundColor3 = Colors.NeonRed
            end
        end)

        -- Load Button with debounce
        local loadDebounce = CreateDebounce(0.5)
        local LoadButton = Instance.new("TextButton")
        LoadButton.Name = "LoadButton"
        LoadButton.Size = UDim2.new(1, -10, 0, 22)
        LoadButton.Position = UDim2.new(0, 5, 0, 50)
        LoadButton.BackgroundColor3 = Colors.DarkBackground
        LoadButton.BorderSizePixel = 0
        LoadButton.Text = "Load Configuration"
        LoadButton.TextColor3 = Colors.Text
        LoadButton.TextSize = 11
        LoadButton.Font = Enum.Font.Gotham
        LoadButton.Parent = ActionButtonsSection

        local LoadButtonCorner = Instance.new("UICorner")
        LoadButtonCorner.CornerRadius = UDim.new(0, 3)
        LoadButtonCorner.Parent = LoadButton

        -- Add border to button
        local LoadButtonBorder = Instance.new("UIStroke")
        LoadButtonBorder.Color = Colors.DarkBorder
        LoadButtonBorder.Thickness = 1
        LoadButtonBorder.Parent = LoadButton

        SafeConnect(LoadButton.MouseButton1Click, function()
            if loadDebounce() then return end
            
            local configName = ConfigNameInput.Text:gsub("%s+", "")
            if configName == "" then
                configName = "default"
            end
            
            if LoadConfiguration(configName) then
                CurrentConfig = configName
                ConfigNameInput.Text = configName
                
                -- Show success feedback
                LoadButton.Text = "✓ Loaded!"
                LoadButton.BackgroundColor3 = Colors.Success
                
                task.wait(0.8)
                
                LoadButton.Text = "Load Configuration"
                LoadButton.BackgroundColor3 = Colors.DarkBackground
            else
                -- Show error feedback
                LoadButton.Text = "✗ Failed!"
                LoadButton.BackgroundColor3 = Colors.Error
                
                task.wait(0.8)
                
                LoadButton.Text = "Load Configuration"
                LoadButton.BackgroundColor3 = Colors.DarkBackground
            end
        end)

        -- Config List Section (Window-specific configs)
        local ConfigListSection = Instance.new("Frame")
        ConfigListSection.Name = "ConfigListSection"
        ConfigListSection.Size = UDim2.new(1, 0, 0, configListHeight + 25)
        ConfigListSection.BackgroundColor3 = Colors.PanelBackground
        ConfigListSection.BorderSizePixel = 0
        ConfigListSection.LayoutOrder = 4
        ConfigListSection.Parent = ConfigContent

        local ConfigListCorner = Instance.new("UICorner")
        ConfigListCorner.CornerRadius = UDim.new(0, 3)
        ConfigListCorner.Parent = ConfigListSection

        -- Add border to section
        local ListBorder = Instance.new("UIStroke")
        ListBorder.Color = Colors.DarkBorder
        ListBorder.Thickness = 1
        ListBorder.Parent = ConfigListSection

        local ConfigListLabel = Instance.new("TextLabel")
        ConfigListLabel.Name = "ConfigListLabel"
        ConfigListLabel.Size = UDim2.new(1, -10, 0, 18)
        ConfigListLabel.Position = UDim2.new(0, 5, 0, 4)
        ConfigListLabel.BackgroundTransparency = 1
        ConfigListLabel.Text = "Configurations (" .. #windowConfigs .. ")"
        ConfigListLabel.TextColor3 = Colors.NeonRed
        ConfigListLabel.TextSize = 11
        ConfigListLabel.Font = Enum.Font.GothamBold
        ConfigListLabel.TextXAlignment = Enum.TextXAlignment.Left
        ConfigListLabel.Parent = ConfigListSection

        local ConfigList = Instance.new("ScrollingFrame")
        ConfigList.Name = "ConfigList"
        ConfigList.Size = UDim2.new(1, -10, 0, configListHeight - 5)
        ConfigList.Position = UDim2.new(0, 5, 0, 25)
        ConfigList.BackgroundColor3 = Colors.DarkBackground
        ConfigList.BorderSizePixel = 0
        ConfigList.ScrollBarThickness = 3
        ConfigList.ScrollBarImageColor3 = Colors.NeonRed
        ConfigList.AutomaticCanvasSize = Enum.AutomaticSize.Y
        ConfigList.ScrollingEnabled = true
        ConfigList.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
        ConfigList.Parent = ConfigListSection

        -- Add border to list
        local ConfigListBorder = Instance.new("UIStroke")
        ConfigListBorder.Color = Colors.DarkBorder
        ConfigListBorder.Thickness = 1
        ConfigListBorder.Parent = ConfigList

        local ConfigListLayout = Instance.new("UIListLayout")
        ConfigListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ConfigListLayout.Padding = UDim.new(0, 2)
        ConfigListLayout.Parent = ConfigList

        local ConfigListPadding = Instance.new("UIPadding")
        ConfigListPadding.PaddingLeft = UDim.new(0, 5)
        ConfigListPadding.PaddingRight = UDim.new(0, 5)
        ConfigListPadding.PaddingTop = UDim.new(0, 5)
        ConfigListPadding.PaddingBottom = UDim.new(0, 5)
        ConfigListPadding.Parent = ConfigList

        -- Function to refresh config list with delete buttons
        function RefreshConfigList()
            -- Clear existing items
            for _, child in ipairs(ConfigList:GetChildren()) do
                if child:IsA("Frame") and child.Name:match("^ConfigItem_") then
                    child:Destroy()
                end
            end

            -- Add config items
            local configs = ListConfigurations()
            ConfigListLabel.Text = "Configurations (" .. #configs .. ")"
            
            for _, configName in ipairs(configs) do
                local ConfigItem = Instance.new("Frame")
                ConfigItem.Name = "ConfigItem_" .. configName
                ConfigItem.Size = UDim2.new(1, -10, 0, 22)
                ConfigItem.BackgroundTransparency = 1
                ConfigItem.LayoutOrder = _
                ConfigItem.Parent = ConfigList

                -- Config name button (load on click)
                local ConfigNameButton = Instance.new("TextButton")
                ConfigNameButton.Name = "ConfigNameButton"
                ConfigNameButton.Size = UDim2.new(1, -25, 1, 0)
                ConfigNameButton.BackgroundColor3 = Colors.PanelBackground
                ConfigNameButton.BorderSizePixel = 0
                ConfigNameButton.Text = configName
                ConfigNameButton.TextColor3 = Colors.Text
                ConfigNameButton.TextSize = 11
                ConfigNameButton.Font = Enum.Font.Gotham
                ConfigNameButton.Parent = ConfigItem

                local ConfigNameButtonCorner = Instance.new("UICorner")
                ConfigNameButtonCorner.CornerRadius = UDim.new(0, 3)
                ConfigNameButtonCorner.Parent = ConfigNameButton

                -- Add border to config name button
                local NameButtonBorder = Instance.new("UIStroke")
                NameButtonBorder.Color = Colors.DarkBorder
                NameButtonBorder.Thickness = 1
                NameButtonBorder.Parent = ConfigNameButton

                -- Delete button
                local DeleteConfigButton = Instance.new("TextButton")
                DeleteConfigButton.Name = "DeleteConfigButton"
                DeleteConfigButton.Size = UDim2.new(0, 22, 1, 0)
                DeleteConfigButton.Position = UDim2.new(1, -22, 0, 0)
                DeleteConfigButton.BackgroundColor3 = Colors.Error
                DeleteConfigButton.BorderSizePixel = 0
                DeleteConfigButton.Text = "X"
                DeleteConfigButton.TextColor3 = Colors.Text
                DeleteConfigButton.TextSize = 11
                DeleteConfigButton.Font = Enum.Font.GothamBold
                DeleteConfigButton.Parent = ConfigItem

                local DeleteButtonCorner = Instance.new("UICorner")
                DeleteButtonCorner.CornerRadius = UDim.new(0, 3)
                DeleteButtonCorner.Parent = DeleteConfigButton

                -- Add border to delete button
                local DeleteButtonBorder = Instance.new("UIStroke")
                DeleteButtonBorder.Color = Colors.DarkBorder
                DeleteButtonBorder.Thickness = 1
                DeleteButtonBorder.Parent = DeleteConfigButton

                -- Config name button click (load config)
                SafeConnect(ConfigNameButton.MouseButton1Click, function()
                    CurrentConfig = configName
                    ConfigNameInput.Text = configName
                    LoadConfiguration(configName)
                    
                    -- Highlight selected item
                    for _, item in ipairs(ConfigList:GetChildren()) do
                        if item:IsA("Frame") and item:FindFirstChild("ConfigNameButton") then
                            item.ConfigNameButton.BackgroundColor3 = Colors.PanelBackground
                        end
                    end
                    ConfigNameButton.BackgroundColor3 = Colors.NeonRed
                end)

                -- Config name button hover effects
                SafeConnect(ConfigNameButton.MouseEnter, function()
                    if ConfigNameButton.BackgroundColor3 ~= Colors.NeonRed then
                        ConfigNameButton.BackgroundColor3 = Colors.LightNeonRed
                    end
                end)

                SafeConnect(ConfigNameButton.MouseLeave, function()
                    if ConfigNameButton.BackgroundColor3 ~= Colors.NeonRed then
                        ConfigNameButton.BackgroundColor3 = Colors.PanelBackground
                    end
                end)

                -- Delete button click (delete config)
                SafeConnect(DeleteConfigButton.MouseButton1Click, function()
                    if DeleteConfiguration(configName) then
                        -- Remove from list
                        ConfigItem:Destroy()
                        ConfigListLabel.Text = "Configurations (" .. (#configs - 1) .. ")"
                        
                        -- Update input if we deleted current config
                        if CurrentConfig == configName then
                            CurrentConfig = "default"
                            ConfigNameInput.Text = "default"
                        end
                    end
                end)

                -- Delete button hover effects
                SafeConnect(DeleteConfigButton.MouseEnter, function()
                    DeleteConfigButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
                end)

                SafeConnect(DeleteConfigButton.MouseLeave, function()
                    DeleteConfigButton.BackgroundColor3 = Colors.Error
                end)
            end
        end

        -- Refresh button
        local RefreshButton = Instance.new("TextButton")
        RefreshButton.Name = "RefreshButton"
        RefreshButton.Size = UDim2.new(0, 60, 0, 18)
        RefreshButton.Position = UDim2.new(1, -65, 0, 4)
        RefreshButton.BackgroundColor3 = Colors.DarkBackground
        RefreshButton.BorderSizePixel = 0
        RefreshButton.Text = "Refresh"
        RefreshButton.TextColor3 = Colors.Text
        RefreshButton.TextSize = 10
        RefreshButton.Font = Enum.Font.Gotham
        RefreshButton.Parent = ConfigListSection

        local RefreshButtonCorner = Instance.new("UICorner")
        RefreshButtonCorner.CornerRadius = UDim.new(0, 3)
        RefreshButtonCorner.Parent = RefreshButton

        -- Add border to refresh button
        local RefreshBorder = Instance.new("UIStroke")
        RefreshBorder.Color = Colors.DarkBorder
        RefreshBorder.Thickness = 1
        RefreshBorder.Parent = RefreshButton

        SafeConnect(RefreshButton.MouseButton1Click, function()
            RefreshConfigList()
        end)

        -- Auto-size the content
        SafeConnect(ConfigLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            ConfigContent.CanvasSize = UDim2.new(0, 0, 0, ConfigLayout.AbsoluteContentSize.Y + 12)
        end)

        -- Initial refresh
        RefreshConfigList()
        
        -- Clean up when window is destroyed
        ConfigWindow.Destroying:Connect(function()
            OpenConfigManagers[DeltaLibGUI] = nil
        end)
    end

    -- Connect config button with debounce
    SafeConnect(ConfigButton.MouseButton1Click, function()
        ShowConfigManager()
    end)

    -- Auto-save thread
    if ConfigSystem.AutoSave and IsFileSystemAvailable() then
        spawn(function()
            while task.wait(ConfigSystem.AutoSaveInterval) do
                if DeltaLibGUI and DeltaLibGUI.Parent then
                    pcall(function()
                        SaveConfiguration(CurrentConfig)
                    end)
                end
            end
        end)
    end

    -- Load config settings and auto-load config if enabled
    if IsFileSystemAvailable() then
        LoadConfigSettings()
        
        -- Auto-load config if enabled
        if ConfigSettings.AutoLoadConfig and ConfigSettings.LastLoadedConfig ~= "" then
            task.spawn(function()
                task.wait(0.5) -- Wait for UI to initialize
                LoadConfiguration(ConfigSettings.LastLoadedConfig)
            end)
        end
    end

    -- Create Tab Function
    function Window:CreateTab(tabName)
        local Tab = {}

        -- Tab Button
        local TabButton = Instance.new("TextButton")
        TabButton.Name = tabName.."Button"

        -- Use pcall to safely get text size
        local textWidth = 80 -- Default width
        pcall(function()
            textWidth = TextService:GetTextSize(tabName, 12, Enum.Font.GothamSemibold, Vector2.new(math.huge, 20)).X + 16
        end)

        TabButton.Size = UDim2.new(0, textWidth, 1, -6) -- Smaller tab button
        TabButton.Position = UDim2.new(0, 0, 0, 3) -- Centered vertically
        TabButton.BackgroundColor3 = Colors.DarkBackground
        TabButton.BorderSizePixel = 0
        TabButton.Text = tabName
        TabButton.TextColor3 = Colors.SubText
        TabButton.TextSize = 12 -- Smaller text size
        TabButton.Font = Enum.Font.GothamSemibold
        TabButton.Parent = TabButtons

        local TabButtonCorner = Instance.new("UICorner")
        TabButtonCorner.CornerRadius = UDim.new(0, 3) -- Smaller corner radius
        TabButtonCorner.Parent = TabButton

        -- Add border to tab button
        local TabButtonStroke = Instance.new("UIStroke")
        TabButtonStroke.Color = Colors.DarkBorder
        TabButtonStroke.Thickness = 1
        TabButtonStroke.Parent = TabButton

        -- Tab Content
        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Name = tabName.."Content"
        TabContent.Size = UDim2.new(1, -16, 1, -8) -- Smaller content area
        TabContent.Position = UDim2.new(0, 8, 0, 4)
        TabContent.BackgroundTransparency = 1
        TabContent.BorderSizePixel = 0
        TabContent.ScrollBarThickness = 2
        TabContent.ScrollBarImageColor3 = Colors.NeonRed
        TabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
        TabContent.ScrollingEnabled = true
        TabContent.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
        TabContent.Visible = false
        TabContent.Parent = ContentContainer

        local TabContentLayout = Instance.new("UIListLayout")
        TabContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        TabContentLayout.Padding = UDim.new(0, 8) -- Smaller padding
        TabContentLayout.Parent = TabContent

        local TabContentPadding = Instance.new("UIPadding")
        TabContentPadding.PaddingTop = UDim.new(0, 4) -- Smaller padding
        TabContentPadding.PaddingBottom = UDim.new(0, 4) -- Smaller padding
        TabContentPadding.Parent = TabContent

        -- Tab Selection Logic with error handling
        SafeConnect(TabButton.MouseButton1Click, function()
            pcall(function()
                if SelectedTab then
                    -- Deselect current tab
                    SelectedTab.Button.BackgroundColor3 = Colors.DarkBackground
                    SelectedTab.Button.TextColor3 = Colors.SubText
                    SelectedTab.Content.Visible = false
                end

                -- Select new tab
                TabButton.BackgroundColor3 = Colors.NeonRed
                TabButton.TextColor3 = Colors.Text
                TabContent.Visible = true
                SelectedTab = {Button = TabButton, Content = TabContent}

                -- Scroll to make the selected tab visible
                local buttonPosition = TabButton.AbsolutePosition.X - TabScrollFrame.AbsolutePosition.X
                local buttonEnd = buttonPosition + TabButton.AbsoluteSize.X
                local viewportWidth = TabScrollFrame.AbsoluteSize.X

                if buttonPosition < 0 then
                    -- Button is to the left of the visible area
                    local targetPos = TabScrollFrame.CanvasPosition.X + buttonPosition - 8
                    TweenService:Create(TabScrollFrame, TweenInfo.new(0.3), {
                        CanvasPosition = Vector2.new(math.max(targetPos, 0), 0)
                    }):Play()
                elseif buttonEnd > viewportWidth then
                    -- Button is to the right of the visible area
                    local targetPos = TabScrollFrame.CanvasPosition.X + (buttonEnd - viewportWidth) + 8
                    local maxScroll = TabScrollFrame.CanvasSize.X.Offset - viewportWidth
                    TweenService:Create(TabScrollFrame, TweenInfo.new(0.3), {
                        CanvasPosition = Vector2.new(math.min(targetPos, maxScroll), 0)
                    }):Play()
                end
            end)
        end)

        -- Add to tabs table
        table.insert(Tabs, {Button = TabButton, Content = TabContent})

        -- If this is the first tab, select it
        if #Tabs == 1 then
            TabButton.BackgroundColor3 = Colors.NeonRed
            TabButton.TextColor3 = Colors.Text
            TabContent.Visible = true
            SelectedTab = {Button = TabButton, Content = TabContent}
        end

        -- Section Creation Function
        function Tab:CreateSection(sectionName)
            local Section = {}

            -- Section Container
            local SectionContainer = Instance.new("Frame")
            SectionContainer.Name = sectionName.."Section"
            SectionContainer.Size = UDim2.new(1, 0, 0, 25) -- Will be resized based on content
            SectionContainer.BackgroundColor3 = Colors.LightBackground
            SectionContainer.BorderSizePixel = 0
            SectionContainer.Parent = TabContent

            local SectionCorner = Instance.new("UICorner")
            SectionCorner.CornerRadius = UDim.new(0, 3) -- Smaller corner radius
            SectionCorner.Parent = SectionContainer

            -- Add border to section
            local SectionStroke = Instance.new("UIStroke")
            SectionStroke.Color = Colors.DarkBorder
            SectionStroke.Thickness = 1
            SectionStroke.Parent = SectionContainer

            -- Section Title
            local SectionTitle = Instance.new("TextLabel")
            SectionTitle.Name = "SectionTitle"
            SectionTitle.Size = UDim2.new(1, -8, 0, 20) -- Smaller title
            SectionTitle.Position = UDim2.new(0, 8, 0, 0)
            SectionTitle.BackgroundTransparency = 1
            SectionTitle.Text = sectionName
            SectionTitle.TextColor3 = Colors.NeonRed
            SectionTitle.TextSize = 12 -- Smaller text size
            SectionTitle.Font = Enum.Font.GothamBold
            SectionTitle.TextXAlignment = Enum.TextXAlignment.Left
            SectionTitle.Parent = SectionContainer

            -- Section Content with Scrolling
            local SectionScrollFrame = Instance.new("ScrollingFrame")
            SectionScrollFrame.Name = "SectionScrollFrame"
            SectionScrollFrame.Size = UDim2.new(1, -16, 0, 80) -- Initial height, will be adjusted
            SectionScrollFrame.Position = UDim2.new(0, 8, 0, 20)
            SectionScrollFrame.BackgroundTransparency = 1
            SectionScrollFrame.BorderSizePixel = 0
            SectionScrollFrame.ScrollBarThickness = 2
            SectionScrollFrame.ScrollBarImageColor3 = Colors.NeonRed
            SectionScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
            SectionScrollFrame.ScrollingEnabled = true
            SectionScrollFrame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
            SectionScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated dynamically
            SectionScrollFrame.Parent = SectionContainer

            local SectionContent = Instance.new("Frame")
            SectionContent.Name = "SectionContent"
            SectionContent.Size = UDim2.new(1, 0, 0, 0) -- Will be resized based on content
            SectionContent.BackgroundTransparency = 1
            SectionContent.Parent = SectionScrollFrame

            local SectionContentLayout = Instance.new("UIListLayout")
            SectionContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
            SectionContentLayout.Padding = UDim.new(0, 6) -- Smaller padding
            SectionContentLayout.Parent = SectionContent

            -- Auto-size the section based on content with error handling
            SafeConnect(SectionContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                pcall(function()
                    local contentHeight = SectionContentLayout.AbsoluteContentSize.Y
                    SectionContent.Size = UDim2.new(1, 0, 0, contentHeight)

                    -- Adjust the section height (capped at 150 for scrolling)
                    local newHeight = math.min(contentHeight, 150) -- Smaller max height
                    SectionScrollFrame.Size = UDim2.new(1, -16, 0, newHeight)
                    SectionContainer.Size = UDim2.new(1, 0, 0, newHeight + 28) -- +28 for the title
                end)
            end)

            -- Label Creation Function
            function Section:AddLabel(labelText)
                local LabelContainer = Instance.new("Frame")
                LabelContainer.Name = "LabelContainer"
                LabelContainer.Size = UDim2.new(1, 0, 0, 16) -- Smaller label
                LabelContainer.BackgroundTransparency = 1
                LabelContainer.Parent = SectionContent

                local Label = Instance.new("TextLabel")
                Label.Name = "Label"
                Label.Size = UDim2.new(1, 0, 1, 0)
                Label.BackgroundTransparency = 1
                Label.Text = labelText
                Label.TextColor3 = Colors.Text
                Label.TextSize = 12 -- Smaller text size
                Label.Font = Enum.Font.Gotham
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = LabelContainer

                local LabelFunctions = {}

                function LabelFunctions:SetText(newText)
                    pcall(function()
                        Label.Text = newText
                    end)
                end

                return LabelFunctions
            end

            -- Button Creation Function
            function Section:AddButton(buttonText, callback)
                callback = callback or function() end

                local ButtonContainer = Instance.new("Frame")
                ButtonContainer.Name = "ButtonContainer"
                ButtonContainer.Size = UDim2.new(1, 0, 0, 24) -- Smaller button
                ButtonContainer.BackgroundTransparency = 1
                ButtonContainer.Parent = SectionContent

                local Button = Instance.new("TextButton")
                Button.Name = "Button"
                Button.Size = UDim2.new(1, 0, 1, 0)
                Button.BackgroundColor3 = Colors.DarkBackground
                Button.BorderSizePixel = 0
                Button.Text = buttonText
                Button.TextColor3 = Colors.Text
                Button.TextSize = 12 -- Smaller text size
                Button.Font = Enum.Font.Gotham
                Button.Parent = ButtonContainer

                local ButtonCorner = Instance.new("UICorner")
                ButtonCorner.CornerRadius = UDim.new(0, 3) -- Smaller corner radius
                ButtonCorner.Parent = Button

                -- Add border to button
                local ButtonStroke = Instance.new("UIStroke")
                ButtonStroke.Color = Colors.DarkBorder
                ButtonStroke.Thickness = 1
                ButtonStroke.Parent = Button

                -- Button Effects
                SafeConnect(Button.MouseEnter, function()
                    Button.BackgroundColor3 = Colors.NeonRed
                end)

                SafeConnect(Button.MouseLeave, function()
                    Button.BackgroundColor3 = Colors.DarkBackground
                end)

                SafeConnect(Button.MouseButton1Click, function()
                    SafeCall(callback)
                end)

                local ButtonFunctions = {}
                ButtonFunctions.Object = ButtonContainer
                

                function ButtonFunctions:SetText(newText)
                    pcall(function()
                        Button.Text = newText
                    end)
                end

                return ButtonFunctions
            end

            -- Toggle Creation Function with config registration
            function Section:AddToggle(toggleText, default, callback)
                default = default or false
                callback = callback or function() end

                local ToggleContainer = Instance.new("Frame")
                ToggleContainer.Name = "ToggleContainer"
                ToggleContainer.Size = UDim2.new(1, 0, 0, 20) -- Smaller toggle
                ToggleContainer.BackgroundTransparency = 1
                ToggleContainer.Parent = SectionContent

                local ToggleLabel = Instance.new("TextLabel")
                ToggleLabel.Name = "ToggleLabel"
                ToggleLabel.Size = UDim2.new(1, -40, 1, 0)
                ToggleLabel.BackgroundTransparency = 1
                ToggleLabel.Text = toggleText
                ToggleLabel.TextColor3 = Colors.Text
                ToggleLabel.TextSize = 12 -- Smaller text size
                ToggleLabel.Font = Enum.Font.Gotham
                ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
                ToggleLabel.Parent = ToggleContainer

                local ToggleButton = Instance.new("Frame")
                ToggleButton.Name = "ToggleButton"
                ToggleButton.Size = UDim2.new(0, 32, 0, 16) -- Smaller toggle button
                ToggleButton.Position = UDim2.new(1, -32, 0, 2)
                ToggleButton.BackgroundColor3 = Colors.DarkBackground
                ToggleButton.BorderSizePixel = 0
                ToggleButton.Parent = ToggleContainer

                local ToggleButtonCorner = Instance.new("UICorner")
                ToggleButtonCorner.CornerRadius = UDim.new(1, 0)
                ToggleButtonCorner.Parent = ToggleButton

                -- Add border to toggle
                local ToggleStroke = Instance.new("UIStroke")
                ToggleStroke.Color = Colors.DarkBorder
                ToggleStroke.Thickness = 1
                ToggleStroke.Parent = ToggleButton

                local ToggleCircle = Instance.new("Frame")
                ToggleCircle.Name = "ToggleCircle"
                ToggleCircle.Size = UDim2.new(0, 12, 0, 12) -- Smaller toggle circle
                ToggleCircle.Position = UDim2.new(0, 2, 0, 2)
                ToggleCircle.BackgroundColor3 = Colors.Text
                ToggleCircle.BorderSizePixel = 0
                ToggleCircle.Parent = ToggleButton

                local ToggleCircleCorner = Instance.new("UICorner")
                ToggleCircleCorner.CornerRadius = UDim.new(1, 0)
                ToggleCircleCorner.Parent = ToggleCircle

                -- Make the entire container clickable
                local ToggleClickArea = Instance.new("TextButton")
                ToggleClickArea.Name = "ToggleClickArea"
                ToggleClickArea.Size = UDim2.new(1, 0, 1, 0)
                ToggleClickArea.BackgroundTransparency = 1
                ToggleClickArea.Text = ""
                ToggleClickArea.Parent = ToggleContainer

                -- Toggle State
                local Enabled = default

                -- Update toggle appearance based on state
                local function UpdateToggle()
                    pcall(function()
                        if Enabled then
                            TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Colors.NeonRed}):Play()
                            TweenService:Create(ToggleCircle, TweenInfo.new(0.2), {Position = UDim2.new(0, 18, 0, 2)}):Play()
                        else
                            TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Colors.DarkBackground}):Play()
                            TweenService:Create(ToggleCircle, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0, 2)}):Play()
                        end
                    end)
                end

                -- Set initial state
                UpdateToggle()

                -- Toggle Logic
                SafeConnect(ToggleClickArea.MouseButton1Click, function()
                    Enabled = not Enabled
                    UpdateToggle()
                    SafeCall(callback, Enabled)
                end)

                -- Register for configuration
                local elementId = tabName .. "_" .. sectionName .. "_" .. toggleText
                RegisterConfigElement(elementId, "Toggle", tabName, sectionName,
                    function() return Enabled end,
                    function(value) 
                        Enabled = value
                        UpdateToggle()
                        SafeCall(callback, Enabled)
                    end
                )

                local ToggleFunctions = {}
                ToggleFunctions.Object = ToggleContainer
                

                function ToggleFunctions:SetState(state)
                    Enabled = state
                    UpdateToggle()
                    SafeCall(callback, Enabled)
                end

                function ToggleFunctions:GetState()
                    return Enabled
                end

                return ToggleFunctions
            end

            -- Slider Creation Function - Improved for PC and Android with error handling and config registration
            function Section:AddSlider(sliderText, min, max, default, callback)
                min = min or 0
                max = max or 100
                default = default or min
                callback = callback or function() end

                local SliderContainer = Instance.new("Frame")
                SliderContainer.Name = "SliderContainer"
                SliderContainer.Size = UDim2.new(1, 0, 0, 36) -- Smaller slider
                SliderContainer.BackgroundTransparency = 1
                SliderContainer.Parent = SectionContent

                local SliderLabel = Instance.new("TextLabel")
                SliderLabel.Name = "SliderLabel"
                SliderLabel.Size = UDim2.new(1, 0, 0, 16) -- Smaller label
                SliderLabel.BackgroundTransparency = 1
                SliderLabel.Text = sliderText
                SliderLabel.TextColor3 = Colors.Text
                SliderLabel.TextSize = 12 -- Smaller text size
                SliderLabel.Font = Enum.Font.Gotham
                SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                SliderLabel.Parent = SliderContainer

                local SliderValue = Instance.new("TextLabel")
                SliderValue.Name = "SliderValue"
                SliderValue.Size = UDim2.new(0, 25, 0, 16) -- Smaller value label
                SliderValue.Position = UDim2.new(1, -25, 0, 0)
                SliderValue.BackgroundTransparency = 1
                SliderValue.Text = tostring(default)
                SliderValue.TextColor3 = Colors.NeonRed
                SliderValue.TextSize = 12 -- Smaller text size
                SliderValue.Font = Enum.Font.GothamBold
                SliderValue.TextXAlignment = Enum.TextXAlignment.Right
                SliderValue.Parent = SliderContainer

                local SliderBackground = Instance.new("Frame")
                SliderBackground.Name = "SliderBackground"
                SliderBackground.Size = UDim2.new(1, 0, 0, 8) -- Smaller slider bar
                SliderBackground.Position = UDim2.new(0, 0, 0, 20)
                SliderBackground.BackgroundColor3 = Colors.DarkBackground
                SliderBackground.BorderSizePixel = 0
                SliderBackground.Parent = SliderContainer

                local SliderBackgroundCorner = Instance.new("UICorner")
                SliderBackgroundCorner.CornerRadius = UDim.new(1, 0)
                SliderBackgroundCorner.Parent = SliderBackground

                -- Add border to slider background
                local SliderBackgroundStroke = Instance.new("UIStroke")
                SliderBackgroundStroke.Color = Colors.DarkBorder
                SliderBackgroundStroke.Thickness = 1
                SliderBackgroundStroke.Parent = SliderBackground

                local SliderFill = Instance.new("Frame")
                SliderFill.Name = "SliderFill"
                SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
                SliderFill.BackgroundColor3 = Colors.NeonRed
                SliderFill.BorderSizePixel = 0
                SliderFill.Parent = SliderBackground

                local SliderFillCorner = Instance.new("UICorner")
                SliderFillCorner.CornerRadius = UDim.new(1, 0)
                SliderFillCorner.Parent = SliderFill

                local SliderButton = Instance.new("TextButton")
                SliderButton.Name = "SliderButton"
                SliderButton.Size = UDim2.new(1, 0, 1, 0)
                SliderButton.BackgroundTransparency = 1
                SliderButton.Text = ""
                SliderButton.Parent = SliderBackground

                -- Slider Logic with error handling
                local function UpdateSlider(value)
                    pcall(function()
                        value = math.clamp(value, min, max)
                        value = math.floor(value + 0.5) -- Round to nearest integer

                        SliderValue.Text = tostring(value)
                        SliderFill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                        SafeCall(callback, value)
                    end)
                end

                -- Set initial value
                UpdateSlider(default)

                -- Improved Slider Interaction for PC and Android with error handling
                local isDragging = false

                SafeConnect(SliderButton.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDragging = true

                        -- Calculate value directly from initial press position
                        pcall(function()
                            local relativePos = input.Position.X - SliderBackground.AbsolutePosition.X
                            local percent = math.clamp(relativePos / SliderBackground.AbsoluteSize.X, 0, 1)
                            local value = min + (max - min) * percent

                            UpdateSlider(value)
                        end)
                    end
                end)

                SafeConnect(UserInputService.InputEnded, function(input)
                    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                        isDragging = false
                    end
                end)

                SafeConnect(UserInputService.InputChanged, function(input)
                    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        -- Use delta movement for smoother control
                        pcall(function()
                            local relativePos = input.Position.X - SliderBackground.AbsolutePosition.X
                            local percent = math.clamp(relativePos / SliderBackground.AbsoluteSize.X, 0, 1)
                            local value = min + (max - min) * percent

                            UpdateSlider(value)
                        end)
                    end
                end)

                -- Register for configuration
                local elementId = tabName .. "_" .. sectionName .. "_" .. sliderText
                RegisterConfigElement(elementId, "Slider", tabName, sectionName,
                    function() return tonumber(SliderValue.Text) end,
                    function(value) UpdateSlider(value) end
                )

                local SliderFunctions = {}
                SliderFunctions.Object = SliderContainer
                

                function SliderFunctions:SetValue(value)
                    UpdateSlider(value)
                end

                function SliderFunctions:GetValue()
                    return tonumber(SliderValue.Text)
                end

                return SliderFunctions
            end

            function Section:AddDropdown(dropdownText, options, default, callback)
                local DropdownFunctions = {}
                options = options or {}
                default = default or options[1] or ""
                callback = callback or function() end

                local DropdownContainer = Instance.new("Frame")
                DropdownContainer.Name = "DropdownContainer"
                DropdownContainer.Size = UDim2.new(1, 0, 0, 40)
                DropdownContainer.BackgroundTransparency = 1
                DropdownContainer.Parent = SectionContent

                local DropdownLabel = Instance.new("TextLabel")
                DropdownLabel.Name = "DropdownLabel"
                DropdownLabel.Size = UDim2.new(1, 0, 0, 20)
                DropdownLabel.BackgroundTransparency = 1
                DropdownLabel.Text = dropdownText
                DropdownLabel.TextColor3 = Colors.Text
                DropdownLabel.TextSize = 14
                DropdownLabel.Font = Enum.Font.Gotham
                DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
                DropdownLabel.Parent = DropdownContainer

                local DropdownButton = Instance.new("TextButton")
                DropdownButton.Name = "DropdownButton"
                DropdownButton.Size = UDim2.new(1, 0, 0, 25)
                DropdownButton.Position = UDim2.new(0, 0, 0, 20)
                DropdownButton.BackgroundColor3 = Colors.DarkBackground
                DropdownButton.BorderSizePixel = 0
                DropdownButton.Text = ""
                DropdownButton.Parent = DropdownContainer

                local DropdownButtonCorner = Instance.new("UICorner")
                DropdownButtonCorner.CornerRadius = UDim.new(0, 3)
                DropdownButtonCorner.Parent = DropdownButton

                local DropdownButtonStroke = Instance.new("UIStroke")
                DropdownButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                DropdownButtonStroke.Color = Colors.DarkBorder
                DropdownButtonStroke.Thickness = 1
                DropdownButtonStroke.Parent = DropdownButton

                local SelectedTextBox = Instance.new("TextBox")
                SelectedTextBox.Name = "SelectedTextBox"
                SelectedTextBox.Size = UDim2.new(1, -50, 1, 0)
                SelectedTextBox.Position = UDim2.new(0, 10, 0, 0)
                SelectedTextBox.BackgroundTransparency = 1
                SelectedTextBox.Text = default
                SelectedTextBox.PlaceholderText = "..."
                SelectedTextBox.TextColor3 = Colors.Text
                SelectedTextBox.TextSize = 13
                SelectedTextBox.Font = Enum.Font.Gotham
                SelectedTextBox.TextXAlignment = Enum.TextXAlignment.Left
                SelectedTextBox.ClearTextOnFocus = false
                SelectedTextBox.TextEditable = false
                SelectedTextBox.Parent = DropdownButton

                local DropdownArrow = Instance.new("ImageLabel")
                DropdownArrow.Name = "DropdownArrow"
                DropdownArrow.Size = UDim2.new(0, 18, 0, 18)
                DropdownArrow.Position = UDim2.new(1, -24, 0, 3)
                DropdownArrow.BackgroundTransparency = 1
                DropdownArrow.Image = "rbxassetid://6031094670"
                DropdownArrow.ImageColor3 = Colors.NeonRed
                DropdownArrow.Rotation = 270
                DropdownArrow.Parent = DropdownButton

                local DropdownList = Instance.new("Frame")
                DropdownList.Name = "DropdownList"
                DropdownList.Size = UDim2.new(1, 0, 0, 0)
                DropdownList.Position = UDim2.new(0, 0, 0, 45)
                DropdownList.BackgroundColor3 = Colors.DarkBackground
                DropdownList.BorderSizePixel = 0
                DropdownList.Visible = false
                DropdownList.ZIndex = 999999
                DropdownList.ClipsDescendants = false
                DropdownList.Parent = DropdownContainer

                local DropdownListCorner = Instance.new("UICorner")
                DropdownListCorner.CornerRadius = UDim.new(0, 3)
                DropdownListCorner.Parent = DropdownList

                local DropdownListStroke = Instance.new("UIStroke")
                DropdownListStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                DropdownListStroke.Color = Colors.DarkBorder
                DropdownListStroke.Thickness = 1
                DropdownListStroke.Parent = DropdownList

                local DropdownScrollFrame = Instance.new("ScrollingFrame")
                DropdownScrollFrame.Name = "DropdownScrollFrame"
                DropdownScrollFrame.Size = UDim2.new(1, -10, 1, -10)
                DropdownScrollFrame.Position = UDim2.new(0, 5, 0, 5)
                DropdownScrollFrame.BackgroundTransparency = 1
                DropdownScrollFrame.BorderSizePixel = 0
                DropdownScrollFrame.ScrollBarThickness = 3
                DropdownScrollFrame.ScrollBarImageColor3 = Colors.NeonRed
                DropdownScrollFrame.BottomImage = ""
                DropdownScrollFrame.TopImage = ""
                DropdownScrollFrame.ZIndex = 1000000
                DropdownScrollFrame.Parent = DropdownList

                local DropdownOptionsLayout = Instance.new("UIListLayout")
                DropdownOptionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
                DropdownOptionsLayout.Padding = UDim.new(0, 4)
                DropdownOptionsLayout.Parent = DropdownScrollFrame

                local DropdownOptionsPadding = Instance.new("UIPadding")
                DropdownOptionsPadding.PaddingLeft = UDim.new(0, 5)
                DropdownOptionsPadding.PaddingRight = UDim.new(0, 5)
                DropdownOptionsPadding.PaddingTop = UDim.new(0, 4)
                DropdownOptionsPadding.PaddingBottom = UDim.new(0, 4)
                DropdownOptionsPadding.Parent = DropdownScrollFrame

                local isOpen = false
                local isAnimating = false

                local function ToggleDropdown()
                    if isAnimating then return end
                    isAnimating = true
                    isOpen = not isOpen

                    TweenService:Create(DropdownArrow, TweenInfo.new(0.3), {Rotation = isOpen and 90 or 270}):Play()
                    TweenService:Create(DropdownButtonStroke, TweenInfo.new(0.3), {Color = isOpen and Colors.NeonRed or Colors.DarkBorder}):Play()

                    if isOpen then
                        DropdownList.Visible = true
                        DropdownList.ZIndex = 999999

                        local optionsHeight = math.min(#options * 28 + 8, 140)

                        TweenService:Create(DropdownList, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, optionsHeight)}):Play()
                        TweenService:Create(DropdownContainer, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 40 + optionsHeight)}):Play()

                        DropdownScrollFrame.CanvasSize = UDim2.new(0, 0, 0, DropdownOptionsLayout.AbsoluteContentSize.Y + 8)

                        task.delay(0.3, function() isAnimating = false end)
                    else
                        TweenService:Create(DropdownList, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 0)}):Play()
                        TweenService:Create(DropdownContainer, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 40)}):Play()

                        task.delay(0.3, function()
                            DropdownList.Visible = false
                            isAnimating = false
                        end)
                    end
                end

                local OptionButtons = {}

                local function CreateOptionButton(option, index)
                    local OptionButton = Instance.new("TextButton")
                    OptionButton.Name = "Option_" .. option
                    OptionButton.Size = UDim2.new(1, 0, 0, 24)
                    OptionButton.BackgroundColor3 = Colors.PanelBackground
                    OptionButton.BorderSizePixel = 0
                    OptionButton.Text = ""
                    OptionButton.LayoutOrder = index
                    OptionButton.ZIndex = 1000001
                    OptionButton.Parent = DropdownScrollFrame

                    local OptionButtonCorner = Instance.new("UICorner")
                    OptionButtonCorner.CornerRadius = UDim.new(0, 3)
                    OptionButtonCorner.Parent = OptionButton

                    -- Add border to option button
                    local OptionButtonStroke = Instance.new("UIStroke")
                    OptionButtonStroke.Color = Colors.DarkBorder
                    OptionButtonStroke.Thickness = 1
                    OptionButtonStroke.Parent = OptionButton

                    local OptionText = Instance.new("TextLabel")
                    OptionText.Name = "OptionText"
                    OptionText.Size = UDim2.new(1, -10, 1, 0)
                    OptionText.Position = UDim2.new(0, 8, 0, 0)
                    OptionText.BackgroundTransparency = 1
                    OptionText.Text = option
                    OptionText.TextColor3 = Colors.Text
                    OptionText.TextSize = 13
                    OptionText.Font = Enum.Font.Gotham
                    OptionText.TextXAlignment = Enum.TextXAlignment.Left
                    OptionText.ZIndex = 1000002
                    OptionText.Parent = OptionButton

                    OptionButton.MouseButton1Down:Connect(function()
                        if isAnimating then return end
                        isAnimating = true

                        SelectedTextBox.Text = option
                        task.spawn(function()
                            callback(option)
                        end)

                        task.delay(0.03, function()
                            ToggleDropdown()
                        end)

                        task.delay(0.15, function()
                            isAnimating = false
                        end)

                        TweenService:Create(OptionText, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true), {
                            TextColor3 = Colors.NeonRed
                        }):Play()
                    end)

                    return OptionButton
                end

                for i, option in ipairs(options) do
                    table.insert(OptionButtons, CreateOptionButton(option, i))
                end

                DropdownButton.MouseButton1Click:Connect(ToggleDropdown)

                local globalClickConnection
                globalClickConnection = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                    if not isOpen then return end

                    task.wait(0.05)

                    local mousePos = UserInputService:GetMouseLocation()
                    local inButton = (
                        mousePos.X >= DropdownButton.AbsolutePosition.X and 
                        mousePos.X <= DropdownButton.AbsolutePosition.X + DropdownButton.AbsoluteSize.X and
                        mousePos.Y >= DropdownButton.AbsolutePosition.Y and 
                        mousePos.Y <= DropdownButton.AbsolutePosition.Y + DropdownButton.AbsoluteSize.Y
                    )

                    local inList = (
                        mousePos.X >= DropdownList.AbsolutePosition.X and 
                        mousePos.X <= DropdownList.AbsolutePosition.X + DropdownList.AbsoluteSize.X and
                        mousePos.Y >= DropdownList.AbsolutePosition.Y and 
                        mousePos.Y <= DropdownList.AbsolutePosition.Y + DropdownList.AbsoluteSize.Y
                    )

                    if not inButton and not inList and not isAnimating then
                        ToggleDropdown()
                    end
                end)

                DropdownContainer.AncestryChanged:Connect(function(_, parent)
                    if not parent and globalClickConnection then
                        globalClickConnection:Disconnect()
                    end
                end)

                -- Register for configuration
                local elementId = tabName .. "_" .. sectionName .. "_" .. dropdownText
                RegisterConfigElement(elementId, "Dropdown", tabName, sectionName,
                    function() return SelectedTextBox.Text end,
                    function(value)
                        if table.find(options, value) then
                            SelectedTextBox.Text = value
                            callback(value)
                        end
                    end
                )

                function DropdownFunctions:SetValue(value)
                    if table.find(options, value) then
                        SelectedTextBox.Text = value
                        callback(value)
                    end
                end

                function DropdownFunctions:GetValue()
                    return SelectedTextBox.Text
                end

                function DropdownFunctions:Refresh(newOptions, newDefault)
                    options = newOptions or options
                    default = newDefault or (options[1] or "")

                    for _, button in ipairs(OptionButtons) do
                        button:Destroy()
                    end

                    OptionButtons = {}

                    for i, option in ipairs(options) do
                        table.insert(OptionButtons, CreateOptionButton(option, i))
                    end

                    DropdownScrollFrame.CanvasSize = UDim2.new(0, 0, 0, DropdownOptionsLayout.AbsoluteContentSize.Y + 8)
                    SelectedTextBox.Text = default

                    if isOpen then
                        local optionsHeight = math.min(#options * 28 + 8, 140)
                        DropdownList.Size = UDim2.new(1, 0, 0, optionsHeight)
                        DropdownContainer.Size = UDim2.new(1, 0, 0, 40 + optionsHeight)
                    end
                end

                return DropdownFunctions
            end

            -- TextBox Creation Function with error handling and config registration
            function Section:AddTextBox(boxText, placeholder, default, callback)
                placeholder = placeholder or ""
                default = default or ""
                callback = callback or function() end

                local TextBoxContainer = Instance.new("Frame")
                TextBoxContainer.Name = "TextBoxContainer"
                TextBoxContainer.Size = UDim2.new(1, 0, 0, 36) -- Smaller textbox
                TextBoxContainer.BackgroundTransparency = 1
                TextBoxContainer.Parent = SectionContent

                local TextBoxLabel = Instance.new("TextLabel")
                TextBoxLabel.Name = "TextBoxLabel"
                TextBoxLabel.Size = UDim2.new(1, 0, 0, 16) -- Smaller label
                TextBoxLabel.BackgroundTransparency = 1
                TextBoxLabel.Text = boxText
                TextBoxLabel.TextColor3 = Colors.Text
                TextBoxLabel.TextSize = 12 -- Smaller text size
                TextBoxLabel.Font = Enum.Font.Gotham
                TextBoxLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextBoxLabel.Parent = TextBoxContainer

                local TextBox = Instance.new("TextBox")
                TextBox.Name = "TextBox"
                TextBox.Size = UDim2.new(1, 0, 0, 20) -- Smaller textbox
                TextBox.Position = UDim2.new(0, 0, 0, 16)
                TextBox.BackgroundColor3 = Colors.DarkBackground
                TextBox.BorderSizePixel = 0
                TextBox.PlaceholderText = placeholder
                TextBox.Text = default
                TextBox.TextColor3 = Colors.Text
                TextBox.PlaceholderColor3 = Colors.SubText
                TextBox.TextSize = 12 -- Smaller text size
                TextBox.Font = Enum.Font.Gotham
                TextBox.TextXAlignment = Enum.TextXAlignment.Left
                TextBox.ClearTextOnFocus = false
                TextBox.Parent = TextBoxContainer

                local TextBoxPadding = Instance.new("UIPadding")
                TextBoxPadding.PaddingLeft = UDim.new(0, 8) -- Smaller padding
                TextBoxPadding.Parent = TextBox

                local TextBoxCorner = Instance.new("UICorner")
                TextBoxCorner.CornerRadius = UDim.new(0, 3) -- Smaller corner radius
                TextBoxCorner.Parent = TextBox

                -- Add border to textbox
                local TextBoxStroke = Instance.new("UIStroke")
                TextBoxStroke.Color = Colors.DarkBorder
                TextBoxStroke.Thickness = 1
                TextBoxStroke.Parent = TextBox

                -- TextBox Logic with error handling
                SafeConnect(TextBox.Focused, function()
                    pcall(function()
                        TweenService:Create(TextBox, TweenInfo.new(0.2), {BorderSizePixel = 1, BorderColor3 = Colors.NeonRed}):Play()
                    end)
                end)

                SafeConnect(TextBox.FocusLost, function(enterPressed)
                    pcall(function()
                        TweenService:Create(TextBox, TweenInfo.new(0.2), {BorderSizePixel = 0}):Play()
                        SafeCall(callback, TextBox.Text, enterPressed)
                    end)
                end)

                -- Register for configuration
                local elementId = tabName .. "_" .. sectionName .. "_" .. boxText
                RegisterConfigElement(elementId, "TextBox", tabName, sectionName,
                    function() return TextBox.Text end,
                    function(value)
                        TextBox.Text = value
                        SafeCall(callback, value, false)
                    end
                )

                local TextBoxFunctions = {}
                TextBoxFunctions.Object = TextBoxContainer

                function TextBoxFunctions:SetText(text)
                    pcall(function()
                        TextBox.Text = text
                        SafeCall(callback, text, false)
                    end)
                end

                function TextBoxFunctions:GetText()
                    return TextBox.Text
                end

                return TextBoxFunctions
            end

            return Section
        end

        return Tab
    end

    -- Add User Profile Section with error handling
    function Window:AddUserProfile(displayName)
        displayName = displayName or Player.DisplayName

        -- Update username label
        pcall(function()
            UsernameLabel.Text = displayName
        end)

        -- Create a function to update the avatar
        local function UpdateAvatar(userId)
            pcall(function()
                AvatarImage.Image = GetPlayerAvatar(userId or Player.UserId, "100x100")
            end)
        end

        return {
            SetDisplayName = function(name)
                pcall(function()
                    UsernameLabel.Text = name
                end)
            end,
            UpdateAvatar = UpdateAvatar
        }
    end

    -- Configuration functions for the window
    function Window:SaveConfig(configName)
        return SaveConfiguration(configName)
    end

    function Window:LoadConfig(configName)
        return LoadConfiguration(configName)
    end

    function Window:DeleteConfig(configName)
        return DeleteConfiguration(configName)
    end

    function Window:ListConfigs()
        return ListConfigurations()
    end

    function Window:ListAllConfigs()
        return ListAllConfigurations()
    end

    function Window:SetCurrentConfig(configName)
        CurrentConfig = configName
        return true
    end

    function Window:GetCurrentConfig()
        return CurrentConfig
    end

    function Window:GetAutoLoadEnabled()
        return ConfigSettings.AutoLoadConfig
    end

    function Window:SetAutoLoadEnabled(enabled)
        ConfigSettings.AutoLoadConfig = enabled
        SaveConfigSettings()
        return true
    end

    return Window
end

return DeltaLib
