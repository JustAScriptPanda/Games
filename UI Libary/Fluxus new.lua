-- Last Updated 04/02/2022
-- FULLY FIXED VERSION
-- Fixes: multi-select dropdown (no table.find), config buttons, layout updates
--loadstring(Game:HttpGet("https://raw.githubusercontent.com/JustAScriptPanda/Games/refs/heads/main/Tools/Webhook.lua"))()
local lib = {};
local UIS = game:GetService("UserInputService");
local TS = game:GetService("TweenService");
local RS = game:GetService("RunService");
local LP = game:GetService("Players").LocalPlayer;
local Mouse = LP:GetMouse();
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

local GUI = Instance.new("ScreenGui");
GUI.Name = "FluxHub";
GUI.Parent = game.CoreGui;
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
GUI.IgnoreGuiInset = true

function Create(instance, properties, children)
    local obj = Instance.new(instance)
    for i, v in pairs(properties or {}) do
        obj[i] = v
        for _, child in pairs(children or {}) do
            child.Parent = obj;
        end
    end
    return obj;
end

function tween(instance, time, properties, callback)
    callback = callback or function() end
    local tween = TS:Create(instance, TweenInfo.new(time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), properties)
    tween:Play()
    tween.Completed:Connect(function()
        callback()
    end)
end

-- File system helpers (check if executor supports)
local function ensureFolder(path)
    if not isfolder then return false end
    if not isfolder(path) then
        makefolder(path)
    end
    return true
end

local function listConfigs(gameFolder)
    if not listfiles then return {} end
    local files = listfiles(gameFolder)
    local configs = {}
    for _, file in ipairs(files) do
        if file:sub(-5) == ".json" then
            local name = file:match("([^/\\]+)%.json$")
            table.insert(configs, name)
        end
    end
    return configs
end

function lib:CreateWindow(title, gameInfo)
    local window = {
        Font = Enum.Font.RobotoMono,
        AccentColor = Color3.fromRGB(255, 85, 85),
        _controls = {},
        ConfigEnabled = gameInfo and true or false,
        GameId = gameInfo and (gameInfo.id or gameInfo.gameId or game.GameId),
        GameName = gameInfo and (gameInfo.name or gameInfo.gameName or game.Name)
    }
    local hidden = false;

    local ToolTip = Create("TextLabel", {
        BackgroundColor3 = Color3.fromRGB(13, 14, 16),
        AutomaticSize = Enum.AutomaticSize.XY,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        TextTransparency = 1,
        Font = window.Font,
        TextSize = 14,
        TextColor3 = Color3.new(1, 1, 1),
        LineHeight = 1.15,
        Parent = GUI,
        ZIndex = 99,
    }, {
        Create("UICorner", {
            CornerRadius = UDim.new(0, 4)
        }),
        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 5),
            PaddingBottom = UDim.new(0, 5)
        }),
        Create("UIStroke", {
            ApplyStrokeMode = 1,
            Color = Color3.fromRGB(23, 25, 29),
            Transparency = 1
        })
    })
    function tooltipFollow()
        RS.RenderStepped:Connect(function()
            ToolTip.Position = UDim2.new(0, UIS:GetMouseLocation().X + 20, 0, UIS:GetMouseLocation().Y + 30);
        end)
    end
    coroutine.wrap(tooltipFollow)()

    function showTooltip(text)
        if typeof(text) ~= "string" then return end
        if text == nil then return end
        ToolTip.Text = text;
        TS:Create(ToolTip, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BackgroundTransparency = 0.2, TextTransparency = 0.2}):Play()
        TS:Create(ToolTip.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Transparency = 0.2}):Play()
    end

    function hideTooltip()
        tween(ToolTip, 0.4, {BackgroundTransparency = 1, TextTransparency = 1})
        tween(ToolTip.UIStroke, 0.4, {Transparency = 1})
    end

    local MainFrame = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(19, 21, 25),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 600, 0, 300),
        Position = UDim2.new(0.5, -300, 0.5, -150),
        Parent = GUI
    }, {
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -20, 0, 25),
            Position = UDim2.new(0, 25, 0, 1),
            Text = title,
            Font = Enum.Font.Roboto,
            TextColor3 = Color3.fromRGB(243, 243, 243),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left
    }), Create("ImageLabel", {
        Position = UDim2.new(0, 3, 0, 3),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundTransparency = 1,
        Image = "rbxassetid://9483813933"
    }), Create("UICorner", {
        CornerRadius = UDim.new(0, 3)
    })})

    local dragging
	local dragInput
	local dragStart
	local startPos

	local function update(input)
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

	MainFrame.TextLabel.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = MainFrame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	MainFrame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)

    local ToggleButton = Create("ImageButton", {
        BackgroundTransparency = 1,
        Image = "",
        Position = UDim2.new(1, -25, 0, 0),
        Size = UDim2.new(0, 25, 0, 25),
        Parent = MainFrame
    })

    local toggleIcon = Create("ImageLabel", {
        BackgroundTransparency = 1,
        Image = "http://www.roblox.com/asset/?id=6031094670",
        Size = UDim2.new(1, 0, 1, 0),
        Rotation = 90,
        Parent = ToggleButton
    })


    local toggleDebounce = false
    local titleTextSize = TextService:GetTextSize(MainFrame.TextLabel.Text, 14, window.Font, Vector2.new(MainFrame.TextLabel.AbsoluteSize.X, MainFrame.TextLabel.AbsoluteSize.Y))
    ToggleButton.MouseButton1Click:Connect(function()
        if toggleDebounce then return end
        toggleDebounce = true;
        hidden = not hidden;
        tween(toggleIcon, 0.5, {Rotation = hidden and 270 or 90})
        if not hidden then
            tween(MainFrame, 0.5, {Size = UDim2.new(0, 600, 0, 27)}, function()
                tween(MainFrame, 0.5, {Size = UDim2.new(0, 600, 0, 300)}, function()
                    toggleDebounce = false
                end)
            end)
        else
            tween(MainFrame, 0.5, {Size = UDim2.new(0, 600, 0, 27)}, function()
                tween(MainFrame, 0.5, {Size = UDim2.new(0, titleTextSize.X + 50, 0, 27)}, function()
                    toggleDebounce = false
                end)
            end)
        end
    end)

    local Container = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(13, 14, 16),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 2, 0, 25),
        Size = UDim2.new(1, -4, 1, -27),
        ClipsDescendants = true,
        Parent = MainFrame
    })

    local Mnu = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(13, 14, 16),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 130, 1, 0),
        Parent = Container
    }, {Create("Frame", {
        BorderSizePixel = 0,
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 100, 1, 0)
    }, {Create("UIGradient", {
        Color = ColorSequence.new(Color3.new(0, 0, 0)),
        Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.795, 0), NumberSequenceKeypoint.new(0.295, 1, 0), NumberSequenceKeypoint.new(1, 1, 0)})
    })})})

    local MenuCount = 0
    local Menu = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -5, 1, 0),
        Parent = Mnu,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 6,
        VerticalScrollBarInset = 1,
        ScrollBarImageColor3 = Color3.fromRGB(42, 43, 53),
        BottomImage = "",
        TopImage = "",
        BorderSizePixel = 0
    }, {
        Create("UIListLayout", {
            Padding = UDim.new(0, 2),
            SortOrder = Enum.SortOrder.LayoutOrder
        }),
        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 2),
            PaddingTop = UDim.new(0, 2),
            PaddingBottom = UDim.new(0, 2)
        })
    })

    local Pages = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 135, 0, 0),
        Size = UDim2.new(1, -135, 1, 0),
        ZIndex = 5,
        Parent = Container
    })

    local selectedPage = nil;
    local pagedebounce = false;

    local function selectTab(btn)
        if pagedebounce then return end
        pagedebounce = true
        for i, v in pairs(Menu:GetChildren()) do
            if v:IsA("TextButton") then
                if v ~= btn then
                    tween(v.TextLabel, 0.3, {TextColor3 = Color3.fromRGB(222, 222, 222)})
                    tween(v.ImageLabel, 0.5, {Size = UDim2.new(0, 0, 1, -5)})
                    tween(Pages[v.Name], 0.4, {Position = UDim2.new(0, 0, 1, 10)})
                end
            end
        end
        if selectedPage ~= nil then wait(0.3) end
        tween(btn.TextLabel, 0.3, {TextColor3 = window.AccentColor})
        tween(btn.ImageLabel, 0.5, {Size = UDim2.new(0, 25, 1, -5)})
        tween(Pages[btn.Name], 0.4, {Position = UDim2.new(0, 0, 0, 0)})
        selectedPage = btn.Name
        pagedebounce = false
    end

    function sizeTab(tab)
        local size = 0;
        for i, v in pairs(tab:GetChildren()) do
            if v:IsA("Frame") then
                size = size + v.Size.Y.Offset + 5
            end
        end
        return size
    end

    -- Internal function to create a tab (used by both user and config)
    local function createInternalTab(tabTitle, layoutOrder)
        local button = Create("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 25),
            Font = window.Font,
            Text = "",
            Name = tabTitle,
            LayoutOrder = layoutOrder,
            TextColor3 = Color3.fromRGB(222, 222, 222),
            TextSize = 14,
            Parent = Menu
        }, {
            Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center
            }),
            Create("ImageLabel", {
                Size = UDim2.new(0, 0, 1, -5),
                Image = "http://www.roblox.com/asset/?id=6031094680",
                ImageColor3 = window.AccentColor,
                ScaleType = Enum.ScaleType.Fit,
                BackgroundTransparency = 1
            }),
            Create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.7, 0, 1, 0),
                Font = window.Font,
                TextXAlignment = Enum.TextXAlignment.Center,
                Text = tabTitle,
                TextColor3 = Color3.fromRGB(222, 222, 222),
                TextSize = 14,
            })
        })
        
        local tabTextSize = TextService:GetTextSize(button.TextLabel.Text, 14, window.Font, Vector2.new(button.TextLabel.AbsoluteSize.X, button.TextLabel.AbsoluteSize.Y))
        button.TextLabel.Size = UDim2.new(0, tabTextSize.X, 1, 0)
        button.MouseButton1Click:Connect(function()
            coroutine.wrap(selectTab)(button)
        end)
        button.MouseEnter:Connect(function()
            tween(button.TextLabel, 0.4, {TextTransparency = 0.25})
        end)
        button.MouseLeave:Connect(function()
            tween(button.TextLabel, 0.4, {TextTransparency = 0})
        end)

        local page = Create("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarImageColor3 = Color3.fromRGB(42, 43, 53),
            BottomImage = "",
            TopImage = "",
            ScrollBarThickness = 6,
            VerticalScrollBarInset = 1,
            Name = tabTitle,
            Parent = Pages,
            Position = UDim2.new(0, 0, 1, 10)
        }, {
            Create("UIListLayout", {
                Padding = UDim.new(0, 5)
            }),
            Create("UIPadding", {
                PaddingLeft = UDim.new(0, 5),
                PaddingRight = UDim.new(0, 5),
                PaddingTop = UDim.new(0, 5),
                PaddingBottom = UDim.new(0, 5)
            })
        })
        return {
            Button = button,
            Page = page
        }
    end

    -- Create config tab if enabled
    if window.ConfigEnabled then
        window.ConfigFolder = "FluxusLibConfigs/" .. (window.GameId or window.GameName or "UnknownGame")
        ensureFolder(window.ConfigFolder)
        window.AutoLoadFile = window.ConfigFolder .. "/_autoload.txt"

        -- Create the config tab as the first tab (LayoutOrder 0)
        local configTab = createInternalTab("⚙️ Config", 0)
        window.ConfigTabPage = configTab.Page
        MenuCount = MenuCount + 1  -- increment so user tabs start after

        -- Now build the config UI on the config page
        local configSection = {}
        local order = 0

        -- Dropdown for config files
        local configDropdown
        local selectedConfig = ""

        -- Function to refresh dropdown items
        local function refreshConfigList()
            local configs = listConfigs(window.ConfigFolder)
            if configDropdown then
                configDropdown:Update(configs)
            end
        end

        -- Create a section in the config tab
        local bg = Create("Frame", {
            BackgroundColor3 = Color3.fromRGB(13, 14, 16),
            Size = UDim2.new(1, 0, 0, 25),
            ClipsDescendants = true,
            Parent = window.ConfigTabPage
        }, {
            Create("UICorner", {
                CornerRadius = UDim.new(0, 4)
            }),
            Create("UIPadding", {
                PaddingLeft = UDim.new(0, 5),
                PaddingRight = UDim.new(0, 5),
                PaddingTop = UDim.new(0, 5),
                PaddingBottom = UDim.new(0, 5)
            }),
            Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 5, 0, 2),
                Size = UDim2.new(1, -5, 0, 15),
                Font = window.Font,
                Text = "Configuration Manager",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            }),
            Create("UIStroke", {
                ApplyStrokeMode = 1,
                Color = Color3.fromRGB(24, 25, 30)
            })
        })

        local container = Create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 25),
            Size = UDim2.new(1, 0, 0, 0),
            Parent = bg
        }, {
            Create("UIListLayout", {
                Padding = UDim.new(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder
            })
        })

        -- Helper to update container size
        local function updateContainerSize()
            local h = 0
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("Frame") or child:IsA("TextButton") then
                    h = h + child.Size.Y.Offset + 5
                end
            end
            container.Size = UDim2.new(1, 0, 0, h)
            bg.Size = UDim2.new(1, 0, 0, h + 30)
            window.ConfigTabPage.CanvasSize = UDim2.new(0, 0, 0, sizeTab(window.ConfigTabPage) + 10)
        end

        -- Dropdown for config files
        local dropdownContainer = {}
        function dropdownContainer:AddDropdown(text, tooltip, items, default, multi, callback)
            -- Simple dropdown without multi (just for config selection)
            local selected = default
            local frame = Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(13, 14, 16),
                Size = UDim2.new(1, 0, 0, 30),
                Parent = container,
                LayoutOrder = order,
                ClipsDescendants = true
            }, {
                Create("UIStroke", {Color = Color3.fromRGB(24,25,30)}),
                Create("UICorner", {CornerRadius = UDim.new(0,4)}),
                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0,10,0,8),
                    Size = UDim2.new(1,-10,0,14),
                    Font = window.Font,
                    Text = text,
                    TextColor3 = Color3.new(1,1,1),
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
            })
            local textbox = Create("TextBox", {
                BackgroundColor3 = Color3.fromRGB(13,14,16),
                Size = UDim2.new(0,150,0,24),
                Position = UDim2.new(1,-185,0,3),
                Parent = frame,
                Font = window.Font,
                Text = default,
                PlaceholderText = "...",
                TextColor3 = Color3.new(1,1,1),
                TextSize = 14,
                TextEditable = false
            }, {
                Create("UIStroke", {Color = Color3.fromRGB(24,25,30)}),
                Create("UICorner", {CornerRadius = UDim.new(0,4)})
            })
            local togBtn = Create("ImageButton", {
                BackgroundTransparency = 1,
                Position = UDim2.new(1,-30,0,3),
                Size = UDim2.new(0,24,0,24),
                Parent = frame
            }, {
                Create("UIStroke", {Color = Color3.fromRGB(24,25,30)}),
                Create("UICorner", {CornerRadius = UDim.new(0,4)}),
                Create("ImageLabel", {
                    BackgroundTransparency = 1,
                    Image = "http://www.roblox.com/asset/?id=6031094670",
                    Size = UDim2.new(1,0,1,0),
                    Rotation = 270,
                    Parent = togBtn
                })
            })
            local dropdownFrame = Create("ScrollingFrame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1,-4,1,-32),
                CanvasSize = UDim2.new(0,0,0,0),
                ScrollBarThickness = 6,
                Parent = frame,
                Position = UDim2.new(0,2,0,32),
                Visible = false
            }, {
                Create("UIListLayout", {Padding = UDim.new(0,5)}),
                Create("UIPadding", {PaddingLeft = UDim.new(0,5), PaddingRight = UDim.new(0,5), PaddingTop = UDim.new(0,5), PaddingBottom = UDim.new(0,5)})
            })
            local open = false
            togBtn.MouseButton1Click:Connect(function()
                open = not open
                tween(togBtn.ImageLabel, 0.5, {Rotation = open and 90 or 270})
                tween(frame, 0.5, {Size = open and UDim2.new(1,0,0,120) or UDim2.new(1,0,0,30)})
                dropdownFrame.Visible = open
            end)
            frame.Changed:Connect(function(prop)
                if prop == "Size" then updateContainerSize() end
            end)

            local function populate()
                for _, child in ipairs(dropdownFrame:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for i, v in pairs(items) do
                    local btn = Create("TextButton", {
                        BackgroundColor3 = Color3.fromRGB(13,14,16),
                        Size = UDim2.new(1,0,0,30),
                        Parent = dropdownFrame,
                        Text = ""
                    }, {
                        Create("UIStroke", {Color = Color3.fromRGB(24,25,30)}),
                        Create("UICorner", {CornerRadius = UDim.new(0,4)}),
                        Create("TextLabel", {
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0,10,0.5,-8),
                            Size = UDim2.new(1,-10,0,14),
                            Font = window.Font,
                            Text = v,
                            TextColor3 = Color3.new(1,1,1),
                            TextSize = 14,
                            TextXAlignment = Enum.TextXAlignment.Left
                        })
                    })
                    btn.MouseButton1Click:Connect(function()
                        selected = v
                        textbox.Text = v
                        open = false
                        tween(togBtn.ImageLabel, 0.5, {Rotation = 270})
                        tween(frame, 0.5, {Size = UDim2.new(1,0,0,30)})
                        dropdownFrame.Visible = false
                        if callback then callback(v) end
                    end)
                    dropdownFrame.CanvasSize = UDim2.new(0,0,0, dropdownFrame.CanvasSize.Y.Offset + 36)
                end
            end
            populate()
            return {
                Update = function(newItems)
                    items = newItems
                    populate()
                end,
                GetSelected = function() return selected end,
                SetSelected = function(val) selected = val; textbox.Text = val end
            }
        end

        configDropdown = dropdownContainer:AddDropdown("Select Config", "Choose a config file", listConfigs(window.ConfigFolder), "", false, function(val)
            selectedConfig = val
        end)

        -- Buttons row
        local buttonRow = Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,35),
            Parent = container,
            LayoutOrder = order+1
        })
        local function createButton(name, pos, callback)
            local btn = Create("TextButton", {
                BackgroundColor3 = Color3.fromRGB(13,14,16),
                Size = UDim2.new(0, 100, 0, 30),
                Position = pos,
                Parent = buttonRow,
                Text = "",
                AutoButtonColor = false
            }, {
                Create("UIStroke", {Color = Color3.fromRGB(24,25,30)}),
                Create("UICorner", {CornerRadius = UDim.new(0,4)}),
                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1,0,1,0),
                    Font = window.Font,
                    Text = name,
                    TextColor3 = Color3.new(1,1,1),
                    TextSize = 14
                })
            })
            btn.MouseButton1Click:Connect(callback)
            return btn
        end

        -- Load button
        createButton("Load", UDim2.new(0,0,0,0), function()
            if not isfile then
                showTooltip("File system not supported")
                return
            end
            local name = configDropdown.GetSelected()
            if name == "" then
                showTooltip("No config selected")
                wait(1)
                hideTooltip()
                return
            end
            local path = window.ConfigFolder .. "/" .. name .. ".json"
            if isfile and isfile(path) then
                local success, data = pcall(readfile, path)
                if success then
                    local success2, config = pcall(HttpService.JSONDecode, HttpService, data)
                    if success2 then
                        window:SetConfig(config)
                        showTooltip("Config loaded: " .. name)
                        wait(1)
                        hideTooltip()
                    else
                        showTooltip("Invalid config file")
                        wait(1)
                        hideTooltip()
                    end
                else
                    showTooltip("Failed to read file")
                    wait(1)
                    hideTooltip()
                end
            else
                showTooltip("File not found")
                wait(1)
                hideTooltip()
            end
        end)

        -- Save button
        createButton("Save", UDim2.new(0,105,0,0), function()
            if not writefile then
                showTooltip("File system not supported")
                return
            end
            local name = configDropdown.GetSelected()
            if name == "" then
                showTooltip("No config selected")
                wait(1)
                hideTooltip()
                return
            end
            local path = window.ConfigFolder .. "/" .. name .. ".json"
            local config = window:GetConfig()
            local success, json = pcall(HttpService.JSONEncode, HttpService, config)
            if success then
                local success2 = pcall(writefile, path, json)
                if success2 then
                    showTooltip("Config saved: " .. name)
                    wait(1)
                    hideTooltip()
                    refreshConfigList()
                else
                    showTooltip("Failed to write file")
                    wait(1)
                    hideTooltip()
                end
            else
                showTooltip("Failed to encode config")
                wait(1)
                hideTooltip()
            end
        end)

        -- Delete button
        createButton("Delete", UDim2.new(0,210,0,0), function()
            if not delfile then
                showTooltip("File system not supported")
                return
            end
            local name = configDropdown.GetSelected()
            if name == "" then
                showTooltip("No config selected")
                wait(1)
                hideTooltip()
                return
            end
            local path = window.ConfigFolder .. "/" .. name .. ".json"
            if isfile and isfile(path) then
                local success = pcall(delfile, path)
                if success then
                    showTooltip("Config deleted: " .. name)
                    wait(1)
                    hideTooltip()
                    configDropdown.SetSelected("")
                    refreshConfigList()
                else
                    showTooltip("Failed to delete file")
                    wait(1)
                    hideTooltip()
                end
            else
                showTooltip("File not found")
                wait(1)
                hideTooltip()
            end
        end)

        -- Create new config with textbox
        local newNameBox = Create("TextBox", {
            BackgroundColor3 = Color3.fromRGB(13,14,16),
            Size = UDim2.new(0, 150, 0, 30),
            Position = UDim2.new(0,0,0,35),
            Parent = buttonRow,
            Font = window.Font,
            PlaceholderText = "New config name",
            Text = "",
            TextColor3 = Color3.new(1,1,1),
            TextSize = 14
        }, {
            Create("UIStroke", {Color = Color3.fromRGB(24,25,30)}),
            Create("UICorner", {CornerRadius = UDim.new(0,4)})
        })

        createButton("Create", UDim2.new(0,155,0,35), function()
            if not writefile then
                showTooltip("File system not supported")
                return
            end
            local name = newNameBox.Text:gsub("%s+", "")
            if name == "" then
                showTooltip("Enter a name")
                wait(1)
                hideTooltip()
                return
            end
            local path = window.ConfigFolder .. "/" .. name .. ".json"
            if isfile and isfile(path) then
                showTooltip("Config already exists")
                wait(1)
                hideTooltip()
                return
            end
            -- Save current config as new file
            local config = window:GetConfig()
            local success, json = pcall(HttpService.JSONEncode, HttpService, config)
            if success then
                local success2 = pcall(writefile, path, json)
                if success2 then
                    showTooltip("Config created: " .. name)
                    wait(1)
                    hideTooltip()
                    refreshConfigList()
                    configDropdown.SetSelected(name)
                    newNameBox.Text = ""
                else
                    showTooltip("Failed to write file")
                    wait(1)
                    hideTooltip()
                end
            else
                showTooltip("Failed to encode config")
                wait(1)
                hideTooltip()
            end
        end)

        -- Auto-load toggle
        local autoLoadToggle = Create("Frame", {
            BackgroundColor3 = Color3.fromRGB(13,14,16),
            Size = UDim2.new(1,0,0,30),
            Parent = container,
            LayoutOrder = order+2
        }, {
            Create("UIStroke", {Color = Color3.fromRGB(24,25,30)}),
            Create("UICorner", {CornerRadius = UDim.new(0,4)}),
            Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0,10,0.5,-8),
                Size = UDim2.new(1,-10,0,14),
                Font = window.Font,
                Text = "Auto-load last config",
                TextColor3 = Color3.new(1,1,1),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })
        })
        local autoCheck = Create("Frame", {
            BackgroundColor3 = Color3.fromRGB(20,21,25),
            Size = UDim2.new(0,24,0,24),
            Position = UDim2.new(1,-30,0.5,-12),
            Parent = autoLoadToggle
        }, {
            Create("UIStroke", {Color = Color3.fromRGB(24,25,30)}),
            Create("UICorner", {CornerRadius = UDim.new(0,4)}),
            Create("ImageLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0,0,0,0),
                Position = UDim2.new(0.5,0,0.5,0),
                Image = "http://www.roblox.com/asset/?id=6031094667",
                ImageColor3 = window.AccentColor,
                ImageTransparency = 1
            })
        })
        local autoState = false
        -- Read auto-load setting
        if isfile and isfile(window.AutoLoadFile) then
            local success, data = pcall(readfile, window.AutoLoadFile)
            if success and data ~= "" then
                autoState = true
                configDropdown.SetSelected(data)
            end
        end
        -- Update check appearance
        local function updateAutoCheck()
            TS:Create(autoCheck.ImageLabel, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
                Size = autoState and UDim2.new(0,20,0,20) or UDim2.new(0,0,0,0),
                Position = autoState and UDim2.new(0.5,-10,0.5,-10) or UDim2.new(0.5,0,0.5,0),
                ImageTransparency = autoState and 0 or 1
            })
            tween(autoCheck.UIStroke, 0.3, {Color = autoState and window.AccentColor or Color3.fromRGB(24,25,30)})
        end
        updateAutoCheck()

        autoLoadToggle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                autoState = not autoState
                updateAutoCheck()
                -- Save auto-load setting
                if autoState then
                    local name = configDropdown.GetSelected()
                    if name ~= "" and writefile then
                        pcall(writefile, window.AutoLoadFile, name)
                    else
                        autoState = false
                        updateAutoCheck()
                        if name == "" then
                            showTooltip("Select a config first")
                        else
                            showTooltip("File system not supported")
                        end
                        wait(1)
                        hideTooltip()
                    end
                else
                    if writefile then
                        pcall(writefile, window.AutoLoadFile, "")
                    end
                end
            end
        end)

        -- Force container size update after all elements are added
        updateContainerSize()

        -- If auto-load is enabled, load the config now
        if autoState then
            local name = configDropdown.GetSelected()
            if name ~= "" then
                local path = window.ConfigFolder .. "/" .. name .. ".json"
                if isfile and isfile(path) then
                    local success, data = pcall(readfile, path)
                    if success then
                        local success2, config = pcall(HttpService.JSONDecode, HttpService, data)
                        if success2 then
                            window:SetConfig(config)
                        end
                    end
                end
            end
        end
    end

    -- User-facing NewTab function
    function window:NewTab(tabTitle)
        local comp1 = {}
        comp1._tabName = tabTitle

        local tab = createInternalTab(tabTitle, MenuCount)
        MenuCount = MenuCount + 1
        local page = tab.Page

        function comp1:AddSection(secTitle)
            local components = {}
            local secCollapsed = false;
            local order = 0;
            local bg = Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(13, 14, 16),
                Size = UDim2.new(1, 0, 0, 25),
                ClipsDescendants = true,
                Parent = page
            }, {
                Create("UICorner", {
                    CornerRadius = UDim.new(0, 4)
                }),
                Create("UIPadding", {
                    PaddingLeft = UDim.new(0, 5),
                    PaddingRight = UDim.new(0, 5),
                    PaddingTop = UDim.new(0, 5),
                    PaddingBottom = UDim.new(0, 5)
                }),
                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 5, 0, 2),
                    Size = UDim2.new(1, -5, 0, 15),
                    Font = window.Font,
                    Text = secTitle,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                }),
                Create("UIStroke", {
                    ApplyStrokeMode = 1,
                    Color = Color3.fromRGB(24, 25, 30)
                })
            })

            local container = Create("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 25),
                Size = UDim2.new(1, 0, 0, 0),
                Parent = bg
            }, {
                Create("UIListLayout", {
                    Padding = UDim.new(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
            })

            local secTog = Create("ImageButton", {
                BackgroundTransparency = 1,
                Image = "",
                Position = UDim2.new(1, -20, 0, 0),
                Size = UDim2.new(0, 20, 0, 20),
                Parent = bg
            })
        
            local sectoggleIcon = Create("ImageLabel", {
                BackgroundTransparency = 1,
                Image = "http://www.roblox.com/asset/?id=6031094670",
                Size = UDim2.new(1, 0, 1, 0),
                Rotation = 90,
                Parent = secTog
            })

            local function sectionSize(section)
                local size = 0
                for i, v in pairs(section:FindFirstChildOfClass("Frame"):GetChildren()) do
                    if not v:IsA("UIListLayout") then
                        size = size + (v.Size.Y.Offset + 5)
                    end
                end
                return size;
            end

            secTog.MouseButton1Click:Connect(function()
                secCollapsed = not secCollapsed;
                tween(sectoggleIcon, 0.5, {Rotation = secCollapsed and 270 or 90})
                tween(bg, 0.5, {Size = secCollapsed and UDim2.new(1, 0, 0, 30) or UDim2.new(1, 0, 0, sectionSize(bg) + 30)})
            end)

            function components:AddButton(buttonTitle, tooltip, callback)
                tooltip = tooltip or nil
                callback = callback or function() end
                local btndebounce = false;
                local b1 = Create("TextButton", {
                    BackgroundColor3 = Color3.fromRGB(13, 14, 16),
                    Size = UDim2.new(1, 0, 0, 30),
                    Parent = container,
                    Text = "",
                    AutoButtonColor = false,
                    LayoutOrder = order
                }, {
                    Create("UIStroke", {
                        ApplyStrokeMode = 1,
                        Color = Color3.fromRGB(24, 25, 30)
                    }),
                    Create("UICorner", {
                        CornerRadius = UDim.new(0, 4)
                    }),
                    Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 10, 0.5, -8),
                        Size = UDim2.new(1, -10, 0, 14),
                        Font = window.Font,
                        Text = buttonTitle,
                        TextColor3 = Color3.new(1, 1, 1),
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left
                    }),
                    Create("ImageLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, -30, 0.5, -12),
                        Size = UDim2.new(0, 24, 0, 24),
                        Image = "http://www.roblox.com/asset/?id=6023565895",
                        ImageTransparency = 0.7,
                        ScaleType = Enum.ScaleType.Stretch
                    })
                })
                b1.MouseButton1Click:Connect(function()
                    callback()
                    if not btndebounce then
                        btndebounce = true
                        TS:Create(b1:FindFirstChildOfClass("UIStroke"), TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true), {Color = window.AccentColor}):Play()
                        TS:Create(b1:FindFirstChildOfClass("ImageLabel"), TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true), {ImageColor3 = window.AccentColor}):Play()
                        wait(0.4)
                        btndebounce = false
                    end
                end)
                b1.MouseEnter:Connect(function()
                    showTooltip(tooltip)
                end)
                b1.MouseLeave:Connect(function()
                    hideTooltip()
                end)
                container.Size = UDim2.new(1, 0, 0, sectionSize(bg));
                bg.Size = UDim2.new(1, 0, 0, sectionSize(bg) + 30);
                order = order + 1;
            end

            function components:AddToggle(buttonTitle, tooltip, default, callback)
                local t1 = {}
                tooltip = tooltip or nil
                t1.State = default or false;
                callback = callback or function() end
                local b1 = Create("TextButton", {
                    BackgroundColor3 = Color3.fromRGB(13, 14, 16),
                    Size = UDim2.new(1, 0, 0, 30),
                    Parent = container,
                    Text = "",
                    AutoButtonColor = false,
                    LayoutOrder = order
                }, {
                    Create("UIStroke", {
                        ApplyStrokeMode = 1,
                        Color = Color3.fromRGB(24, 25, 30)
                    }),
                    Create("UICorner", {
                        CornerRadius = UDim.new(0, 4)
                    }),
                    Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 10, 0.5, -8),
                        Size = UDim2.new(1, -10, 0, 14),
                        Font = window.Font,
                        Text = buttonTitle,
                        TextColor3 = Color3.new(1, 1, 1),
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                })
                local toggle = Create("Frame", {
                    BackgroundColor3 = Color3.fromRGB(20, 21, 25),
                    Size = UDim2.new(0, 24, 0, 24),
                    Position = UDim2.new(1, -30, 0.5, -12),
                    Parent = b1
                }, {
                    Create("UIStroke", {
                        ApplyStrokeMode = 1,
                        Color = t1.State and window.AccentColor or Color3.fromRGB(24, 25, 30)
                    }),
                    Create("UICorner", {
                        CornerRadius = UDim.new(0, 4)
                    }),
                    Create("ImageLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 20, 0, 20),
                        Position = UDim2.new(0.5, -10, 0.5, -10),
                        Image = "http://www.roblox.com/asset/?id=6031094667",
                        ImageColor3 = window.AccentColor,
                        ImageTransparency = t1.State and 0 or 1
                    })
                })

                b1.MouseButton1Click:Connect(function()
                    t1.State = not t1.State;
                    callback(t1.State)
                    TS:Create(toggle.ImageLabel, TweenInfo.new(t1.State and 0.3 or 0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = t1.State and UDim2.new(0, 20, 0, 20) or UDim2.new(0, 0, 0, 0), Position = t1.State and UDim2.new(0.5, -10, 0.5, -10) or UDim2.new(0.5, 0, 0.5, 0)}):Play()
                    tween(toggle.ImageLabel, t1.State and 0.3 or 0.8, {ImageTransparency = t1.State and 0 or 1})
                    tween(toggle.UIStroke, 0.3, {Color = t1.State and window.AccentColor or Color3.fromRGB(24, 25, 30)})
                end)
                b1.MouseEnter:Connect(function()
                    showTooltip(tooltip)
                end)
                b1.MouseLeave:Connect(function()
                    hideTooltip()
                end)
                container.Size = UDim2.new(1, 0, 0, sectionSize(bg));
                bg.Size = UDim2.new(1, 0, 0, sectionSize(bg) + 30);
                order = order + 1
                function t1:SetState(state)
                    t1.State = state
                    callback(t1.State)
                    TS:Create(toggle.ImageLabel, TweenInfo.new(t1.State and 0.3 or 0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = t1.State and UDim2.new(0, 20, 0, 20) or UDim2.new(0, 0, 0, 0), Position = t1.State and UDim2.new(0.5, -10, 0.5, -10) or UDim2.new(0.5, 0, 0.5, 0)}):Play()
                    tween(toggle.ImageLabel, t1.State and 0.3 or 0.8, {ImageTransparency = t1.State and 0 or 1})
                    tween(toggle.UIStroke, 0.3, {Color = t1.State and window.AccentColor or Color3.fromRGB(24, 25, 30)})
                end
                -- Add to controls
                local path = comp1._tabName.."."..secTitle.."."..buttonTitle
                window._controls[path] = {
                    GetValue = function() return t1.State end,
                    SetValue = function(val) t1:SetState(val) end
                }
                return t1;
            end

            function components:AddTextBox(boxTitle, tooltip, placeholder, default, callback)
                tooltip = tooltip or nil
                placeholder = placeholder or ""
                default = default or ""
                callback = callback or function() end
                local b1 = Create("Frame", {
                    BackgroundColor3 = Color3.fromRGB(13, 14, 16),
                    Size = UDim2.new(1, 0, 0, 30),
                    Parent = container,
                    LayoutOrder = order
                }, {
                    Create("UIStroke", {
                        ApplyStrokeMode = 1,
                        Color = Color3.fromRGB(24, 25, 30)
                    }),
                    Create("UICorner", {
                        CornerRadius = UDim.new(0, 4)
                    }),
                    Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 10, 0.5, -8),
                        Size = UDim2.new(1, -10, 0, 14),
                        Font = window.Font,
                        Text = boxTitle,
                        TextColor3 = Color3.new(1, 1, 1),
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                })
                local textbox = Create("TextBox", {
                    BackgroundColor3 = Color3.fromRGB(13, 14, 16),
                    Size = UDim2.new(0, 150, 0, 24),
                    Position = UDim2.new(1, -155, 0.5, -12),
                    Parent = b1,
                    Font = window.Font,
                    Text = default,
                    PlaceholderText = placeholder,
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 14,
                    TextWrapped = true
                }, {
                    Create("UIStroke", {
                        ApplyStrokeMode = 1,
                        Color =Color3.fromRGB(24, 25, 30)
                    }),
                    Create("UICorner", {
                        CornerRadius = UDim.new(0, 4)
                    })
                })

                textbox.Focused:Connect(function()
                    tween(textbox.UIStroke, 0.3, {Color = window.AccentColor})
                end)

                textbox.FocusLost:Connect(function()
                    tween(textbox.UIStroke, 0.3, {Color = Color3.fromRGB(24, 25, 30)})
                    callback(textbox.Text)
                end)

                b1.MouseEnter:Connect(function()
                    showTooltip(tooltip)
                end)
                b1.MouseLeave:Connect(function()
                    hideTooltip()
                end)
                container.Size = UDim2.new(1, 0, 0, sectionSize(bg));
                bg.Size = UDim2.new(1, 0, 0, sectionSize(bg) + 30);
                order = order + 1;
                -- Add to controls
                local path = comp1._tabName.."."..secTitle.."."..boxTitle
                window._controls[path] = {
                    GetValue = function() return textbox.Text end,
                    SetValue = function(val) textbox.Text = val; callback(val) end
                }
            end

            -- FIXED dropdown with multi-select support (no table.find)
            function components:AddDropdown(dropdownText, tooltip, items, default, multi, callback)
                -- Helper to find in table (replaces table.find)
                local function tableFind(t, val)
                    for i, v in ipairs(t) do
                        if v == val then return i end
                    end
                    return nil
                end

                -- Handle optional multi parameter
                if type(multi) == "function" then
                    callback = multi
                    multi = false
                end
                multi = multi or false
                callback = callback or function() end
                local ee = {}  -- returned object
                tooltip = tooltip or nil
                items = items or {}
                local dropdownOpen = false
                local selectedValues = multi and {} or nil
                local selectedSingle = not multi and (default or "")

                if multi then
                    if type(default) == "table" then
                        selectedValues = default
                    else
                        selectedValues = {}
                    end
                else
                    selectedSingle = default or ""
                end

                local b1 = Create("Frame", {
                    BackgroundColor3 = Color3.fromRGB(13, 14, 16),
                    Size = UDim2.new(1, 0, 0, 30),
                    Parent = container,
                    LayoutOrder = order,
                    ClipsDescendants = true
                }, {
                    Create("UIStroke", {
                        ApplyStrokeMode = 1,
                        Color = Color3.fromRGB(24, 25, 30)
                    }),
                    Create("UICorner", {
                        CornerRadius = UDim.new(0, 4)
                    }),
                    Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 10, 0, 8),
                        Size = UDim2.new(1, -10, 0, 14),
                        Font = window.Font,
                        Text = dropdownText,
                        TextColor3 = Color3.new(1, 1, 1),
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                })

                local textbox = Create("TextBox", {
                    BackgroundColor3 = Color3.fromRGB(13, 14, 16),
                    Size = UDim2.new(0, 150, 0, 24),
                    Position = UDim2.new(1, -185, 0, 3),
                    Parent = b1,
                    Font = window.Font,
                    Text = multi and (#selectedValues.." selected") or selectedSingle,
                    PlaceholderText = "...",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 14,
                    TextWrapped = true,
                    TextEditable = false
                }, {
                    Create("UIStroke", {
                        ApplyStrokeMode = 1,
                        Color =Color3.fromRGB(24, 25, 30)
                    }),
                    Create("UICorner", {
                        CornerRadius = UDim.new(0, 4)
                    })
                })

                local dropdownTog = Create("ImageButton", {
                    BackgroundTransparency = 1,
                    Image = "",
                    Position = UDim2.new(1, -30, 0, 3),
                    Size = UDim2.new(0, 24, 0, 24),
                    Parent = b1
                }, {
                    Create("UIStroke", {
                        ApplyStrokeMode = 1,
                        Color =Color3.fromRGB(24, 25, 30)
                    }),
                    Create("UICorner", {
                        CornerRadius = UDim.new(0, 4)
                    })
                })
            
                local dropdownIcon = Create("ImageLabel", {
                    BackgroundTransparency = 1,
                    Image = "http://www.roblox.com/asset/?id=6031094670",
                    Size = UDim2.new(1, 0, 1, 0),
                    Rotation = 270,
                    Parent = dropdownTog
                })

                local dropdownContainer = Create("ScrollingFrame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -4, 1, -32),
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    ScrollBarImageColor3 = Color3.fromRGB(42, 43, 53),
                    BottomImage = "",
                    TopImage = "",
                    ScrollBarThickness = 6,
                    VerticalScrollBarInset = 1,
                    Parent = b1,
                    Position = UDim2.new(0, 2, 0, 32)
                }, {
                    Create("UIListLayout", {
                        Padding = UDim.new(0, 5)
                    }),
                    Create("UIPadding", {
                        PaddingLeft = UDim.new(0, 5),
                        PaddingRight = UDim.new(0, 5),
                        PaddingTop = UDim.new(0, 5),
                        PaddingBottom = UDim.new(0, 5)
                    })
                })

                local function updateDisplay()
                    if multi then
                        local count = #selectedValues
                        if count == 0 then
                            textbox.Text = "None selected"
                        elseif count == 1 then
                            textbox.Text = selectedValues[1]
                        else
                            textbox.Text = count.." selected"
                        end
                    else
                        textbox.Text = selectedSingle or ""
                    end
                end

                local function populateDropdown()
                    for _, child in ipairs(dropdownContainer:GetChildren()) do
                        if child:IsA("TextButton") then
                            child:Destroy()
                        end
                    end

                    for i, v in pairs(items) do
                        local itemText = i.." - "..v
                        local isSelected = false
                        if multi then
                            isSelected = tableFind(selectedValues, v) ~= nil
                        else
                            isSelected = (v == selectedSingle)
                        end

                        local itemBtn = Create("TextButton", {
                            BackgroundColor3 = Color3.fromRGB(13, 14, 16),
                            Size = UDim2.new(1, 0, 0, 30),
                            Parent = dropdownContainer,
                            Text = "",
                            AutoButtonColor = false,
                        }, {
                            Create("UIStroke", {
                                ApplyStrokeMode = 1,
                                Color = Color3.fromRGB(24, 25, 30)
                            }),
                            Create("UICorner", {
                                CornerRadius = UDim.new(0, 4)
                            }),
                            Create("TextLabel", {
                                BackgroundTransparency = 1,
                                Position = UDim2.new(0, 10, 0.5, -8),
                                Size = UDim2.new(1, -40, 0, 14),
                                Font = window.Font,
                                Text = itemText,
                                TextColor3 = Color3.new(1, 1, 1),
                                TextSize = 14,
                                TextXAlignment = Enum.TextXAlignment.Left
                            })
                        })

                        if multi then
                            local check = Create("ImageLabel", {
                                BackgroundTransparency = 1,
                                Position = UDim2.new(1, -25, 0.5, -10),
                                Size = UDim2.new(0, 20, 0, 20),
                                Image = "http://www.roblox.com/asset/?id=6031094667",
                                ImageColor3 = window.AccentColor,
                                ImageTransparency = isSelected and 0 or 1,
                                Parent = itemBtn
                            })
                            itemBtn._check = check
                        else
                            if isSelected then
                                tween(itemBtn.UIStroke, 0.2, {Color = window.AccentColor})
                            end
                        end

                        itemBtn.MouseButton1Click:Connect(function()
                            if multi then
                                local idx = tableFind(selectedValues, v)
                                if idx then
                                    table.remove(selectedValues, idx)
                                else
                                    table.insert(selectedValues, v)
                                end
                                if itemBtn._check then
                                    tween(itemBtn._check, 0.2, {ImageTransparency = (idx == nil) and 0 or 1})
                                end
                                updateDisplay()
                                callback(selectedValues)
                            else
                                selectedSingle = v
                                updateDisplay()
                                dropdownOpen = false
                                tween(dropdownIcon, 0.5, {Rotation = 270})
                                tween(b1, 0.5, {Size = UDim2.new(1, 0, 0, 30)})
                                for _, btn in ipairs(dropdownContainer:GetChildren()) do
                                    if btn:IsA("TextButton") then
                                        tween(btn.UIStroke, 0.2, {Color = Color3.fromRGB(24, 25, 30)})
                                    end
                                end
                                tween(itemBtn.UIStroke, 0.2, {Color = window.AccentColor})
                                callback(v)
                            end
                        end)

                        dropdownContainer.CanvasSize = UDim2.new(0, 0, 0, dropdownContainer.CanvasSize.Y.Offset + 36)
                    end
                end

                populateDropdown()

                dropdownTog.MouseButton1Click:Connect(function()
                    dropdownOpen = not dropdownOpen;
                    tween(dropdownIcon, 0.5, {Rotation = dropdownOpen and 90 or 270})
                    tween(b1, 0.5, {Size = dropdownOpen and UDim2.new(1, 0, 0, 120) or UDim2.new(1, 0, 0, 30)})
                end)

                b1.Changed:Connect(function(it)
                    if it == "Size" then
                        container.Size = UDim2.new(1, 0, 0, sectionSize(bg));
                        bg.Size = UDim2.new(1, 0, 0, sectionSize(bg) + 30);
                    end
                end)

                function ee:Update(newlist)
                    items = newlist
                    if multi then
                        selectedValues = {}
                    else
                        selectedSingle = ""
                    end
                    updateDisplay()
                    populateDropdown()
                end

                local path = comp1._tabName.."."..secTitle.."."..dropdownText
                window._controls[path] = {
                    GetValue = function() 
                        if multi then return selectedValues else return selectedSingle end
                    end,
                    SetValue = function(val)
                        if multi then
                            if type(val) == "table" then
                                selectedValues = val
                                updateDisplay()
                                populateDropdown()
                                callback(val)
                            end
                        else
                            if type(val) == "string" then
                                selectedSingle = val
                                updateDisplay()
                                populateDropdown()
                                callback(val)
                            end
                        end
                    end
                }

                b1.MouseEnter:Connect(function()
                    showTooltip(tooltip)
                end)
                b1.MouseLeave:Connect(function()
                    hideTooltip()
                end)
                container.Size = UDim2.new(1, 0, 0, sectionSize(bg));
                bg.Size = UDim2.new(1, 0, 0, sectionSize(bg) + 30);
                order = order + 1;
                return ee;
            end

            function components:AddSlider(boxTitle, tooltip, minValue, maxValue, default, precise, callback)
                local t1 = {}
                precise = precise or false
                tooltip = tooltip or nil
                minValue = minValue or 0
                maxValue = maxValue or 1
                default = default or 0
                callback = callback or function() end
                local valuee = 0;
                local b1 = Create("Frame", {
                    BackgroundColor3 = Color3.fromRGB(13, 14, 16),
                    Size = UDim2.new(1, 0, 0, 30),
                    Parent = container,
                    LayoutOrder = order
                }, {
                    Create("UIStroke", {
                        ApplyStrokeMode = 1,
                        Color = Color3.fromRGB(24, 25, 30)
                    }),
                    Create("UICorner", {
                        CornerRadius = UDim.new(0, 4)
                    }),
                    Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 10, 0.5, -8),
                        Size = UDim2.new(1, -10, 0, 14),
                        Font = window.Font,
                        Text = boxTitle,
                        TextColor3 = Color3.new(1, 1, 1),
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                })

                local sliderBg = Create("Frame", {
                    BackgroundColor3 = Color3.fromRGB(13, 14, 16),
                    Size = UDim2.new(0, 150, 0, 12),
                    Position = UDim2.new(1, -155, 0.5, -6),
                    Parent = b1,
                    ClipsDescendants = true
                }, {
                    Create("UIStroke", {
                        ApplyStrokeMode = 1,
                        Color =Color3.fromRGB(24, 25, 30)
                    }),
                    Create("UICorner", {
                        CornerRadius = UDim.new(1, 0)
                    })
                })

                local sliderVal = Create("Frame", {
                    BackgroundColor3 = window.AccentColor,
                    Size = UDim2.new(default / maxValue, 0, 1, 0),
                    Parent = sliderBg
                }, {
                    Create("UICorner", {
                        CornerRadius = UDim.new(1, 0)
                    })
                })

                local draggingg = false;
                local function move(input)
                    local pos = UDim2.new(math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1), 0, 1, 0)
                    tween(sliderVal, 0.3, {Size = pos})
                    local SliderPrecise = ((pos.X.Scale * maxValue) / maxValue) * (maxValue - minValue) + minValue
                    local SliderNotPrecise = math.floor(((pos.X.Scale * maxValue) / maxValue) * (maxValue - minValue) + minValue)
                    local Value = precise and SliderNotPrecise or SliderPrecise
                    Value = tonumber(string.format("%.2f", Value))
                    valuee = Value
                    showTooltip(string.format("[%.2f/%.2f]", valuee, maxValue))
                    callback(valuee)
                end

                function t1:SetValue(Value)
                    tween(sliderVal, 0.3, {Size = UDim2.new(Value / maxValue, 0, 1, 0)})
                    valuee = Value
                    callback(valuee)
                end

                function t1:GetValue()
                    return valuee;
                end

    sliderBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        move(input)
        draggingg = true
    end
end)

sliderBg.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingg = false
        hideTooltip()
    end
end)

UIS.InputChanged:Connect(function(input)
    if draggingg and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        move(input)
    end
end)


                sliderBg.MouseEnter:Connect(function()
                    showTooltip(string.format("[%f/%f]", valuee, maxValue))
                end)

                sliderBg.MouseLeave:Connect(function()
                    hideTooltip()
                end)

                b1.MouseEnter:Connect(function()
                    showTooltip(tooltip)
                end)
                b1.MouseLeave:Connect(function()
                    hideTooltip()
                end)
                container.Size = UDim2.new(1, 0, 0, sectionSize(bg));
                bg.Size = UDim2.new(1, 0, 0, sectionSize(bg) + 30);
                order = order + 1;
                local path = comp1._tabName.."."..secTitle.."."..boxTitle
                window._controls[path] = {
                    GetValue = function() return t1:GetValue() end,
                    SetValue = function(val) t1:SetValue(val) end
                }
                return t1;
            end

            bg.Changed:Connect(function(thing)
                if(thing == "Size") then
                    page.CanvasSize = UDim2.new(0, 0, 0, sizeTab(page) + 10)
                end
            end)

            page.CanvasSize = UDim2.new(0, 0, 0, sizeTab(page) + 10)
            return components;
        end
        return comp1;
    end

    -- Config methods
    function window:GetConfig()
        local config = {}
        for path, control in pairs(self._controls) do
            config[path] = control.GetValue()
        end
        return config
    end

    function window:SetConfig(config)
        for path, value in pairs(config) do
            if self._controls[path] then
                self._controls[path].SetValue(value)
            end
        end
    end

    return window;
end;
return lib;
