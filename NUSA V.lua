local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- // [ 1. SERVICES ]
local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    VirtualInput = game:GetService("VirtualInputManager"),
    RunService = game:GetService("RunService")
}

local LocalPlayer = Services.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- // [ 2. PATHS & REMOTES ]
local FishingRemotes = Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Fishing")
local SpawnBobber = FishingRemotes:WaitForChild("SpawnBobber")

local FishingGui = PlayerGui:WaitForChild("FishingGui")
local MinigameUI = FishingGui:WaitForChild("MinigameContainer")

-- // [ 3. CONFIGURATION ]
local Config = {
    AutoFish = false,
    ClickDelay = 0.05,
    WaitAfterCatch = 2,
    BiteTimeout = 20,
    
    -- Cast Power Settings
    CastPower = 1000,      -- Default Slider
    InfiniteCast = false   -- Default Toggle
}

-- // [ 4. UI SETUP ]
local Window = WindUI:CreateWindow({
    Title = "Fishing Elite (Power Update)",
    Author = "Sequence Mode",
    Size = UDim2.fromOffset(500, 500),
    Theme = "Dark",
    Transparent = true,
    Acrylic = true,
    Folder = "FishingElitePower",
    OpenButton = { Title = "Open", CornerRadius = UDim.new(0,10) }
})

local Tabs = {
    Main = Window:Tab({ Title = "Main", Icon = "anchor" }),
    Settings = Window:Tab({ Title = "Settings", Icon = "settings" })
}

-- // [ 5. HELPER FUNCTIONS ]

local function GetRod()
    local Char = LocalPlayer.Character
    if Char then
        local Tool = Char:FindFirstChildOfClass("Tool")
        if Tool then return Tool.Name end
    end
    return nil
end

local function TapScreen()
    Services.VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.wait() 
    Services.VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

-- // [ 6. UI COMPONENTS ]

local MainSec = Tabs.Main:Section({ Title = "Automation", Icon = "zap" })

MainSec:Toggle({
    Title = "Enable Auto Fish",
    Desc = "Sequence: Cast > Wait > Reel > Repeat",
    Value = false,
    Callback = function(val)
        Config.AutoFish = val
        if val then
            WindUI:Notify({Title = "Started", Content = "Auto Fishing Started...", Duration = 2})
        else
            WindUI:Notify({Title = "Stopped", Content = "Stopping...", Duration = 2})
        end
    end
})

local PowerSec = Tabs.Main:Section({ Title = "Casting Power", Icon = "biceps-flexed" })

-- Toggle Infinite Power
PowerSec:Toggle({
    Title = "Infinite Cast Power",
    Desc = "Overrides slider to 9,999,999",
    Value = false,
    Callback = function(val)
        Config.InfiniteCast = val
    end
})

-- Slider Cast Power (Updated)
PowerSec:Slider({
    Title = "Manual Cast Power",
    Desc = "Used if Infinite is OFF",
    Value = {Min = 1000, Max = 10000, Default = 1000},
    Step = 1000, -- Increment 1000
    Callback = function(v) 
        Config.CastPower = tonumber(v) 
    end
})

local SettingSec = Tabs.Main:Section({ Title = "Timings", Icon = "clock" })

SettingSec:Slider({
    Title = "Reel/Tap Speed",
    Desc = "Lower = Faster Tapping",
    Value = {Min = 0, Max = 0.5, Default = 0.05},
    Step = 0.01,
    Callback = function(v) Config.ClickDelay = tonumber(v) end
})

SettingSec:Slider({
    Title = "Wait After Catch",
    Desc = "Delay before casting again",
    Value = {Min = 0, Max = 5, Default = 2},
    Step = 0.5,
    Callback = function(v) Config.WaitAfterCatch = tonumber(v) end
})

-- // [ 7. MAIN LOGIC LOOP ]

task.spawn(function()
    while true do
        if not Config.AutoFish then
            task.wait(0.5)
        else
            local Rod = GetRod()
            if Rod then
                -- [LOGIKA CASTING]
                if not MinigameUI.Visible then
                    -- Tentukan Power (Infinite vs Manual)
                    local PowerToUse = Config.CastPower
                    if Config.InfiniteCast then
                        PowerToUse = 9999999
                    end

                    -- Lempar Kail
                    SpawnBobber:FireServer(Rod, PowerToUse)
                    task.wait(1) 
                end
                
                -- [LOGIKA MENUNGGU IKAN]
                local StartTime = tick()
                local GotBite = false
                
                repeat
                    task.wait(0.1)
                    if MinigameUI.Visible then GotBite = true end
                    if (tick() - StartTime) > Config.BiteTimeout then break end
                    if not Config.AutoFish then break end
                until GotBite or not Config.AutoFish

                -- [LOGIKA REELING / MINIGAME]
                if GotBite and Config.AutoFish then
                    while MinigameUI.Visible and Config.AutoFish do
                        TapScreen()
                        if Config.ClickDelay <= 0 then task.wait() else task.wait(Config.ClickDelay) end
                    end
                end

                -- [COOLDOWN]
                if GotBite then
                    task.wait(Config.WaitAfterCatch)
                else
                    task.wait(0.5)
                end
            else
                WindUI:Notify({Title = "Error", Content = "Please equip your rod!", Duration = 3})
                task.wait(2)
            end
        end
    end
end)

WindUI:Notify({ Title = "Script Loaded", Content = "Infinite Power Added.", Icon = "check", Duration = 3 })
