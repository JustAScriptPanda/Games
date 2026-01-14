if not game:IsLoaded() then game.Loaded:Wait() end

local cloneref = cloneref or function(v) return v end

local Players = cloneref(game:GetService("Players"))
local TeleportService = cloneref(game:GetService("TeleportService"))
local GuiService = cloneref(game:GetService("GuiService"))
local VirtualUser = cloneref(game:GetService("VirtualUser"))

local Player = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

local function Rejoin()
    pcall(function()
        if #Players:GetPlayers() <= 1 then
            Player:Kick("Rejoining...")
            task.wait(0.5)
            TeleportService:Teleport(PlaceId, Player)
        else
            TeleportService:TeleportToPlaceInstance(PlaceId, JobId, Player)
        end
    end)
end

Player.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Failed then
        task.delay(0, Rejoin)
    end
end)

GuiService.ErrorMessageChanged:Connect(function()
    task.delay(0, Rejoin)
end)
