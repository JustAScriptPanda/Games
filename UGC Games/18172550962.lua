local Env = loadstring(game:HttpGet("https://raw.githubusercontent.com/Mainery-foxxie/Main/refs/heads/main/UI%20Libary/Kawai%20Lib/Source.luau", true))()

local Banner = {
	Combat = 112935442242481
}

local Window = Env:Window({
	Title = "Velocity X",
	Desc = "Pixel Blade"
})

local CombatTab = Env.Tabs:Add({
	Title = "Combat",
	Desc = "Pixel Blade Combat",
	Banner = Banner.Combat
})

local Section = CombatTab:Section({
	Title = "Main",
	Side = "l"
})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

_G.Kill = false
_G.Mobs = false
local WalkSpeed = 32

local function getChar()
	return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
	local c = getChar()
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function KillAura()
	task.spawn(function()
		while _G.Kill do
			task.wait()

			local hrp = getHRP()
			if not hrp then continue end

			for _, mob in ipairs(workspace:GetChildren()) do
				if mob:IsA("Model")
				and mob:GetAttribute("hadEntrance")
				and mob:FindFirstChild("HumanoidRootPart") then

					if (mob.HumanoidRootPart.Position - hrp.Position).Magnitude <= 30 then
						ReplicatedStorage.remotes.swing:FireServer()
						ReplicatedStorage.remotes.onHit:FireServer(
							mob:FindFirstChild("Humanoid"),
							math.huge,
							{},
							0
						)
					end
				end
			end
		end
	end)
end

local function getClosestMob(hrp)
	local closest, dist = nil, math.huge

	for _, mob in ipairs(workspace:GetChildren()) do
		if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") then
			local mag = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
			if mag < dist then
				closest = mob
				dist = mag
			end
		end
	end

	return closest
end

local function AutoFarm()
	workspace.Gravity = 0

	task.spawn(function()
		while _G.Mobs do
			task.wait()

			local hrp = getHRP()
			if not hrp then continue end

			local mob = getClosestMob(hrp)
			if mob and mob:FindFirstChild("HumanoidRootPart") then
				local target = mob.HumanoidRootPart.CFrame * CFrame.new(0, 0, 15)
				local dist = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude

				local tween = TweenService:Create(
					hrp,
					TweenInfo.new(dist / 50, Enum.EasingStyle.Sine),
					{CFrame = target}
				)

				tween:Play()
				tween.Completed:Wait()
			end
		end

		workspace.Gravity = 196
	end)
end

Section:Toggle({
	Title = "Kill Aura",
	Desc = "Auto attack nearby mobs",
	Value = false,
	Callback = function(v)
		_G.Kill = v
		if v then KillAura() end
	end
})

Section:Toggle({
	Title = "Auto Mobs",
	Desc = "Auto farm closest mobs",
	Value = false,
	Callback = function(v)
		_G.Mobs = v
		if v then AutoFarm() end
	end
})

Section:Slider({
	Title = "Walk Speed",
	Desc = "Adjust movement speed",
	Min = 16,
	Max = 100,
	Value = 32,
	Rounding = 1,
	CallBack = function(v)
		WalkSpeed = v
		local char = getChar()
		if char:FindFirstChild("Humanoid") then
			char.Humanoid.WalkSpeed = v
		end
	end
})

task.spawn(function()
	while task.wait(0.1) do
		local char = LocalPlayer.Character
		if char and char:FindFirstChild("Humanoid") then
			if char.Humanoid.WalkSpeed ~= WalkSpeed then
				char.Humanoid.WalkSpeed = WalkSpeed
			end
		end
	end
end)
