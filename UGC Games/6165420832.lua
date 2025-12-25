local Wowwhwyusee = cloneref(game:GetService("Players"))
local tptofurrysexh18 = cloneref(game:GetService("TeleportService"))
local likebefurrymeow = cloneref(game:GetService("ReplicatedStorage"))

local idontlikego = cloneref(Wowwhwyusee.LocalPlayer)

if game.PlaceId == 6165420832 then
    tptofurrysexh18:Teleport(112159233440883, idontlikego)
    return
elseif game.PlaceId ~= 112159233440883 then
    idontlikego:Kick("no support")
    return
end

loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))()

local hitlikeurass = cloneref(likebefurrymeow
    :WaitForChild("WeaponsSystem")
    :WaitForChild("Network")
    :WaitForChild("WeaponHit"))

local npcsex = workspace:FindFirstChild("NPCs")
local grinchstealurugc = workspace:FindFirstChild("Grinch")

getgenv().lua = true

while getgenv().lua and task.wait() do
    local noslid = idontlikego.Character
    if not noslid then continue end

    local slup = noslid:FindFirstChild("Usp-s") or noslid:FindFirstChildOfClass("Tool")
    if not slup then continue end

    if grinchstealurugc and grinchstealurugc:FindFirstChild("Head") and grinchstealurugc:FindFirstChild("Humanoid") then
        local head = grinchstealurugc.Head
        local hum = grinchstealurugc.Humanoid
        local origin = slup:FindFirstChild("Handle") and slup.Handle.Position or head.Position
        local hitPos = head.Position

        local args = {
            slup,
            {
                p = hitPos,
                pid = 1,
                part = head,
                d = (hitPos - origin).Magnitude,
                maxDist = 1000,
                h = hum,
                m = Enum.Material.Plastic,
                n = (hitPos - origin).Unit,
                t = tick(),
                sid = 2
            }
        }

        hitlikeurass:FireServer(unpack(args))
    end

    if npcsex then
        for _, npc in ipairs(npcsex:GetChildren()) do
            local hum = npc:FindFirstChildOfClass("Humanoid")
            local part = npc:FindFirstChild("Head")
            if hum and part then
                local origin = slup:FindFirstChild("Handle") and slup.Handle.Position or part.Position
                local hitPos = part.Position

                hitlikeurass:FireServer(slup, {
                    p = hitPos,
                    pid = 1,
                    part = part,
                    d = (hitPos - origin).Magnitude,
                    maxDist = 1000,
                    h = hum,
                    m = Enum.Material.Plastic,
                    n = (hitPos - origin).Unit,
                    t = tick(),
                    sid = 2
                })
            end
        end
    end
end
