--// WAIT GAME LOAD
if not game:IsLoaded() then
    game.Loaded:Wait()
end
local cloneref = cloneref or function(v) return v end
local Players = cloneref(game:GetService("Players"))
local TeleportService = cloneref(game:GetService("TeleportService"))
local GuiService = cloneref(game:GetService("GuiService"))
local HttpService = cloneref(game:GetService("HttpService"))
local VirtualUser = cloneref(game:GetService("VirtualUser"))

local Player = Players.LocalPlayer
local PlaceId = game.PlaceId

Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

local MAX_RETRIES = math.huge
local RETRY_DELAY = 2
local hopping = false
local triedServers = {}
local function GetServer()
    local cursor = ""
    while true do
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=2&limit=100%s")
            :format(PlaceId, cursor ~= "" and "&cursor=" .. cursor or "")

        local success, response = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)

        if success and response and response.data then
            for _, server in ipairs(response.data) do
                if server.playing < server.maxPlayers and not triedServers[server.id] then
                    return server.id
                end
            end
            cursor = response.nextPageCursor
            if not cursor then break end
        else
            break
        end
        task.wait()
    end
end

local function ServerHop()
    if hopping then return end
    hopping = true

    for attempt = 1, MAX_RETRIES do
        local serverId = GetServer()
        if serverId then
            triedServers[serverId] = true

            local success = pcall(function()
                TeleportService:TeleportToPlaceInstance(PlaceId, serverId, Player)
            end)

            if success then
                break
            end
        end
        task.wait(RETRY_DELAY)
    end

    hopping = false
end
Player.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Failed then
        task.delay(0, ServerHop)
    end
end)

GuiService.ErrorMessageChanged:Connect(function()
    task.delay(0, ServerHop)
end)
