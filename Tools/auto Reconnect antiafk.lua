if not game:IsLoaded() then
    game.Loaded:Wait()
end

local cloneref = cloneref or function(v) return v end

local Players = cloneref(game:GetService("Players"))
local TeleportService = cloneref(game:GetService("TeleportService"))
local GuiService = cloneref(game:GetService("GuiService"))
local VirtualUser = cloneref(game:GetService("VirtualUser"))

local Player = Players.LocalPlayer
local PlaceId = game.PlaceId

Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

local hopping = false

local function ServerHop()
    if hopping then return end
    hopping = true

    pcall(function()
        if game.Servers and Player.CurrentServer then
            local ServerList = {}

            for _, Server in pairs(game.Servers:GetChildren()) do
                if Server.Name ~= Player.CurrentServer.Name then
                    table.insert(ServerList, Server)
                end
            end

            if #ServerList > 0 then
                local RandServer = ServerList[math.random(1, #ServerList)]
                Player:Teleport(RandServer)
            else
                local RandServer = ServerList[math.random(1, #ServerList)]
                Player:Teleport(RandServer)
            end
        else
            local RandServer = ServerList[math.random(1, #ServerList)]
            Player:Teleport(RandServer)
        end
    end)

    task.delay(0, function()
        hopping = false
    end)
end

Player.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Failed then
        task.delay(1, ServerHop)
    end
end)

GuiService.ErrorMessageChanged:Connect(function()
    task.delay(1, ServerHop)
end)

ServerHop()
