local RunService = cloneref(game:GetService("RunService"))
local CoreGui = cloneref(game:GetService("CoreGui"))
loadstring(Game:HttpGet("https://raw.githubusercontent.com/JustAScriptPanda/Games/refs/heads/main/Tools/Webhook.lua"))()
local ErrorPrompt = getrenv().require(CoreGui.RobloxGui.Modules.ErrorPrompt)
local function NewScreen(ScreenName)
    local Screen = Instance.new("ScreenGui")
    Screen.Name = ScreenName
    Screen.ResetOnSpawn = false
    Screen.IgnoreGuiInset = true
    sethiddenproperty(Screen, "OnTopOfCoreBlur", true)
    Screen.Parent = CoreGui
    return Screen
end

return function(Title, Message, Buttons, RichText)
    local Screen = NewScreen("Prompt")
    local Prompt =
        ErrorPrompt.new(
        "Default",
        {
            MessageTextScaled = false,
            PlayAnimation = false,
            HideErrorCode = true
        }
    )
    if RichText then
        Prompt._frame.MessageArea.ErrorFrame.ErrorMessage.RichText = true
    end

    for Index, Button in pairs(Buttons) do
        local Old = Button.Callback
        Button.Callback = function(...)
            RunService:SetRobloxGuiFocused(false)
            Prompt:_close()
            Screen:Destroy()
            return Old(...)
        end
    end

    Prompt:setErrorTitle(Title)
    Prompt:updateButtons(Buttons)
    Prompt:setParent(Screen)
    RunService:SetRobloxGuiFocused(true)
    Prompt:_open(Message)
    return Prompt, Screen
end
