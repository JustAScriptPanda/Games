if not game:IsLoaded() then game.Loaded:Wait() end
if game.PlaceId == 15536298749 then

local cloneref = cloneref or function(...) return ... end
local DeltaLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/JustAScriptPanda/Games/refs/heads/main/UI%20Libary/Delta%20Lib.lua"))()
local Player = game.Players.LocalPlayer
local MarketplaceService = cloneref(game:GetService("MarketplaceService"))
local VirtualUser = cloneref(game:GetService("VirtualUser"))
local SoundService = cloneref(game:GetService("SoundService"))

local gameInfo = MarketplaceService:GetProductInfo(game.PlaceId)
local gameName = gameInfo.Name
local executorName = identifyexecutor()
local HWID = game:GetService("RbxAnalyticsService"):GetClientId()

local function playNotificationSound()
	local notificationSound = Instance.new("Sound")
	notificationSound.SoundId = "rbxassetid://8745692251"
	notificationSound.Volume = 0.5
	notificationSound.Parent = SoundService
	notificationSound:Play()
end

local function sendNotification(title, text, duration)
	pcall(function()
		game.StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration or 3,
		})
	end)
end

-- Create DeltaLib Window
local Window = DeltaLib:CreateWindow("Littlest Shop v1.1", UDim2.new(0, 550, 0, 400))
local UserProfile = Window:AddUserProfile()

local HomeTab = Window:CreateTab("Home")
local FarmTab = Window:CreateTab("Auto Farm")
local MiscTab = Window:CreateTab("Misc") 
local Whygay = Window:CreateTab("Egg")

-- HOME TAB
local Info = HomeTab:CreateSection("Account Info")
Info:AddLabel("Executor and Player Info")
Info:AddLabel("Game Name: " .. gameName)
Info:AddLabel("Place ID: " .. game.PlaceId)
Info:AddLabel("Username: " .. Player.Name)
Info:AddLabel("Display Name: " .. Player.DisplayName)
Info:AddLabel("User ID: " .. Player.UserId)
Info:AddLabel("Account Age: " .. Player.AccountAge .. " days")
Info:AddLabel("Executor: " .. executorName)
Info:AddLabel("HWID: " .. HWID)

local Discord = HomeTab:CreateSection("Discord")
Discord:AddLabel("Join our support server")
Discord:AddButton("Copy Discord Link", function()
	setclipboard("https://discord.gg/n8Mxqmze")
	playNotificationSound()
end)
Discord:AddButton("Set Username to Anonymous", function()
        UserProfile.SetDisplayName("Unknown")
        StatusLabel:SetText("Status: Username set to Unknown")
    end)
-- AUTO FARM TAB
local Main = FarmTab:CreateSection("Main Features")

Main:AddToggle("Auto Collect Drop Coins", true, function(state)
	getgenv().Stealer = state
	task.spawn(function()
		while getgenv().Stealer and task.wait(0.1) do
			for _, v in pairs(workspace:GetDescendants()) do
				if v.Name:lower() == "coins" and v:IsA("BasePart") then
					local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
					if hrp then
						pcall(function() v.CFrame = hrp.CFrame end)
					end
				end
			end
		end
	end)
	playNotificationSound()
end)

Main:AddToggle("Auto Farm Coins", false, function(state)
	getgenv().Farms = state
	task.spawn(function()
		while getgenv().Farms and task.wait() do
			local args = { "ReturnBoat" }
			local rideService = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_knit@1.7.0"].knit.Services.RideService.RF
			pcall(function()
				rideService.RequestRideStart:InvokeServer(unpack(args))
			end)
		end
	end)
	playNotificationSound()
end)

Main:AddToggle("Auto Claim Gifts", false, function(state)
	getgenv().RiyuKitty = state
	task.spawn(function()
		while getgenv().RiyuKitty and task.wait() do
			for i = 1, 7 do
				pcall(function()
					game:GetService("ReplicatedStorage").Packages._Index["sleitnick_knit@1.7.0"].knit.Services.SessionGiftService.RF.ClaimGift:InvokeServer(i)
				end)
			end
		end
	end)
	playNotificationSound()
end)

Main:AddButton("Anti AFK", function()
	sendNotification("AntiAfk", "Turned On", 10)
	Player.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
	playNotificationSound()
end)

-- CODES
local Codes = FarmTab:CreateSection("Codes")

local function makeCodeDropdown(title, list)
	local options = {}
	for _, v in ipairs(list) do table.insert(options, v) end
	Codes:AddDropdown(title, options, options[1], function(code)
		local args = { code }
		pcall(function()
			game:GetService("ReplicatedStorage").Packages._Index["sleitnick_knit@1.7.0"].knit.Services.CodeService.RE.RequestCodeValidation:FireServer(unpack(args))
		end)
	end)
end

makeCodeDropdown("Codes - Pets", {
	"CSDream", "PF", "PFLeaf", "PIPal2", "PIFun62", "PIGame2",
	"PICode2", "PSLake2", "PSSky72", "PSHero2", "PSSun", "PSStar2",
	"PSPlay2", "PSGift", "PIZoom"
})

makeCodeDropdown("Codes - Diamonds", {
	"PGTSurfz", "CSJolt2", "SPBold", "PTTune", "PTJump", "PTMix6",
	"PSFun3", "PSFree", "PSWish", "PSSmile", "PSJoy8", "PSCode",
	"PSCool62", "PSJoy82", "PSWave2", "PSBulbV"
})

makeCodeDropdown("Codes - Coins", {
	"PISun2", "PIBest2", "PSJazze", "PSJazz", "PSWave", "PSWord",
	"PSSong2", "PSGame52", "PSWord2", "PSDancer", "PSSmile2", "PSFree2"
})

-- Pets
local EggSection = Whygay:CreateSection("Auto Hatch Eggs")

local podsFolder = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Pods")
local eggList = {}
for _, pod in ipairs(podsFolder:GetChildren()) do
    table.insert(eggList, pod.Name)
end

local selectedEgg = eggList[1]
EggSection:AddDropdown("Select Egg", eggList, selectedEgg, function(selected)
    selectedEgg = selected
end)

EggSection:AddButton("Hatch Egg Once", function()
    local shopService = game:GetService("ReplicatedStorage")
        .Packages._Index["sleitnick_knit@1.7.0"].knit.Services.ShopService.RF.RequestPurchase
    local args = {
        PodName = selectedEgg,
        Type = "PetPod"
    }
    pcall(function()
        shopService:InvokeServer(args)
    end)
    playNotificationSound()
end)

EggSection:AddToggle("Auto Hatch Egg", false, function(didisex)
    getgenv().AutoHatch = didisex
    task.spawn(function()
        local shopService = game:GetService("ReplicatedStorage")
            .Packages._Index["sleitnick_knit@1.7.0"].knit.Services.ShopService.RF.RequestPurchase
        while getgenv().AutoHatch and task.wait(1.5) do
            local args = {
                PodName = selectedEgg,
                Type = "PetPod"
            }
            pcall(function()
                shopService:InvokeServer(args)
            end)
        end
    end)
    playNotificationSound()
end)
-- MISC
local Other = MiscTab:CreateSection("Performance / Utility")

Other:AddButton("Anti-Lag Booster", function()
	local decalsyeeted = true
	local w, l, t = workspace, game:GetService("Lighting"), workspace.Terrain
	sethiddenproperty(l, "Technology", 2)
	sethiddenproperty(t, "Decoration", false)
	t.WaterWaveSize = 0 t.WaterWaveSpeed = 0
	t.WaterReflectance = 0 t.WaterTransparency = 0
	l.GlobalShadows = false
	l.FogEnd = 9e9
	l.Brightness = 0
	settings().Rendering.QualityLevel = "Level01"

	for _, v in pairs(w:GetDescendants()) do
		pcall(function()
			if v:IsA("BasePart") and not v:IsA("MeshPart") then
				v.Material = "Plastic" v.Reflectance = 0
			elseif v:IsA("Decal") or v:IsA("Texture") and decalsyeeted then
				v.Transparency = 1
			elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
				v.Lifetime = NumberRange.new(0)
			elseif v:IsA("Explosion") then
				v.BlastPressure = 1 v.BlastRadius = 1
			elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
				v.Enabled = false
			end
		end)
	end

	for _, e in ipairs(l:GetChildren()) do
		if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
			e.Enabled = false
		end
	end
end)

Other:AddToggle("Hide Other Players", false, function(state)
	getgenv().Hide = state
	task.spawn(function()
		while getgenv().Hide and task.wait() do
			for _, v in pairs(game.Players:GetPlayers()) do
				if v ~= Player and v.Character then
					pcall(function() v.Character:Destroy() end)
				end
			end
		end
	end)
end)

Other:AddButton("Show Console", function()
	game:GetService("StarterGui"):SetCore("DevConsoleVisible", true)
end)

Other:AddButton("Credits", function()
	sendNotification("Alwi", "Made With Love", 10)
end)

end -- if place check
