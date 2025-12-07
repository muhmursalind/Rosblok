local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local FishGiver = ReplicatedStorage:WaitForChild("FishingSystem"):WaitForChild("FishGiver")

local FishTable = {
    {name = "BlueFish", maxKg = 50, rarity = "Common"},
    {name = "Boar Fish", maxKg = 50, rarity = "Common"},
    {name = "Blackcap Basslet", maxKg = 100, rarity = "Common"},
    {name = "Pumpkin Carved Shark", maxKg = 100, rarity = "Common"},
    {name = "Hermit Crab", maxKg = 100.5, rarity = "Common"},
    {name = "Goliath Tiger", maxKg = 100.5, rarity = "Common"},
    {name = "Fangtooth", maxKg = 100.5, rarity = "Common"},
    {name = "StreakyFish", maxKg = 100, rarity = "Uncommon"},
    {name = "Dead Spooky Koi Fish", maxKg = 100, rarity = "Uncommon"},
    {name = "Dead Scary Clownfish", maxKg = 100, rarity = "Uncommon"},
    {name = "Jellyfish", maxKg = 100, rarity = "Uncommon"},
    {name = "Lion Fish", maxKg = 150, rarity = "Rare"},
    {name = "Luminous Fish", maxKg = 150, rarity = "Rare"},
    {name = "Zombie Shark", maxKg = 150, rarity = "Rare"},
    {name = "Wraithfin Abyssal", maxKg = 150, rarity = "Rare"},
    {name = "Loving Shark", maxKg = 300, rarity = "Epic"},
    {name = "Queen Crab", maxKg = 300, rarity = "Epic"},
    {name = "Pink Dolphin", maxKg = 300, rarity = "Epic"},
    {name = "Plasma Shark", maxKg = 450, rarity = "Legendary"},
    {name = "Ancient Relic Crocodile", maxKg = 500, rarity = "Unknown"},
    {name = "Colossal Squid", maxKg = 450, rarity = "Legendary"},
    {name = "Ancient Whale", maxKg = 500, rarity = "Unknown"},
    {name = "Monster Shark", maxKg = 500, rarity = "Unknown"},
    {name = "Lava Megalodon", maxKg = 1000, rarity = "Unknown"},
    {name = "Zombie Megalodon", maxKg = 900, rarity = "Unknown"},
    {name = "Kraken", maxKg = 850, rarity = "Unknown"},
    {name = "Naga Keramat", maxKg = 850, rarity = "Unknown"}
}

local FishLookup = {}
local FishNameList = {}
for i, fish in ipairs(FishTable) do
    FishLookup[fish.name] = fish
    table.insert(FishNameList, fish.name)
end

local AutoFishGiver = false
local SelectedFish = FishTable[1]
local DelayAmount = 1
local Connection

local Character
local HumanoidRootPart
local Humanoid

local function UpdateCharacterCache()
    Character = LocalPlayer.Character
    if Character then
        HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
        Humanoid = Character:FindFirstChild("Humanoid")
    end
end

UpdateCharacterCache()

local function GetPlayerPosition()
    if HumanoidRootPart then
        return HumanoidRootPart.Position
    end
    return Vector3.new(0, 0, 0)
end

local function GiveFish(fish)
    local hookPosition = GetPlayerPosition()
    
    local success = pcall(function()
        FishGiver:FireServer({
            hookPosition = hookPosition,
            rarity = fish.rarity,
            name = fish.name,
            weight = fish.maxKg
        })
    end)
    
    return success
end

local function StartAutoFishGiver()
    if Connection then return end
    
    local lastGiveTime = tick()
    Connection = RunService.Heartbeat:Connect(function()
        if AutoFishGiver and SelectedFish then
            local currentTime = tick()
            if currentTime - lastGiveTime >= DelayAmount then
                GiveFish(SelectedFish)
                lastGiveTime = currentTime
            end
        end
    end)
end

local function StopAutoFishGiver()
    AutoFishGiver = false
    if Connection then
        Connection:Disconnect()
        Connection = nil
    end
end

local function GetAllPlayers()
    local playerList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playerList, player.Name)
        end
    end
    return playerList
end

local function TeleportToPlayer(targetPlayerName)
    local targetPlayer = Players:FindFirstChild(targetPlayerName)
    if not targetPlayer or not targetPlayer.Character then
        warn("[Teleport] Player not found or has no character: " .. targetPlayerName)
        return false
    end
    
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot or not HumanoidRootPart then
        warn("[Teleport] Failed to get root parts")
        return false
    end
    
    HumanoidRootPart.CFrame = targetRoot.CFrame
    return true
end

-- ========================================
-- WINDOW SETUP WITH OPENBUTTON
-- ========================================
local Window = WindUI:CreateWindow({
    Title = "MDVKLuaX | Pantai Losari",
    Author = "MDVKLuaX",
    Folder = "MDVKPantaiLosariConfig",
    Size = UDim2.new(0, 550, 0, 450),
    KeySystem = false,
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170,
    HasOutline = true,
    
    OpenButton = {
    Title = "MDVKLuaX",
        Size = UDim2.fromOffset(55, 55),
        CornerRadius = UDim.new(0, 12),
        StrokeThickness = 2.5,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(13, 110, 253)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 191, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 230, 255))
        })
    }
})

-- ========================================
-- TAB 1: MAIN
-- ========================================
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "fish"
})

local FishDropdown = MainTab:Dropdown({
    Title = "Select Fish",
    Values = FishNameList,
    Value = FishNameList[1],
    Callback = function(selectedValue)
        SelectedFish = FishLookup[selectedValue]
        if SelectedFish then
            WindUI:Notify({
                Title = "Fish Selected",
                Content = string.format("%s (%.1fkg)", SelectedFish.name, SelectedFish.maxKg),
                Duration = 2
            })
        end
    end
})

MainTab:Button({
    Title = "Give Fish",
    Callback = function()
        if SelectedFish and GiveFish(SelectedFish) then
            WindUI:Notify({
                Title = "Fish Given!",
                Content = string.format("%s - %.1fkg", SelectedFish.name, SelectedFish.maxKg),
                Duration = 2
            })
        end
    end
})

MainTab:Toggle({
    Title = "Auto Give Fish",
    Callback = function(state)
        AutoFishGiver = state
        if state then
            StartAutoFishGiver()
            WindUI:Notify({
                Title = "Auto FishGiver",
                Content = "Started!",
                Duration = 2
            })
        else
            StopAutoFishGiver()
            WindUI:Notify({
                Title = "Auto FishGiver",
                Content = "Stopped!",
                Duration = 2
            })
        end
    end
})

MainTab:Slider({
    Title = "Auto Delay",
    Step = 1,
    Value = {
        Min = 1,
        Max = 30,
        Default = 1
    },
    Callback = function(value)
        DelayAmount = value
    end
})

-- ========================================
-- TAB 2: PLAYER
-- ========================================
local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "user"
})

local function GeneratePlayerDropdownValues()
    local playerList = {}
    for _, playerName in ipairs(GetAllPlayers()) do
        table.insert(playerList, {
            Title = playerName,
            Icon = "user",
            Callback = function()
                if TeleportToPlayer(playerName) then
                    WindUI:Notify({
                        Title = "Teleported",
                        Content = "To: " .. playerName,
                        Duration = 2
                    })
                end
            end
        })
    end
    return playerList
end

local TeleportDropdown = PlayerTab:Dropdown({
    Title = "Teleport To Player",
    Desc = "Select player to teleport",
    Values = GeneratePlayerDropdownValues()
})

PlayerTab:Button({
    Title = "Refresh Player List",
    Desc = "Update teleport player list",
    Callback = function()
        TeleportDropdown:SetValues(GeneratePlayerDropdownValues())
        WindUI:Notify({
            Title = "Player List",
            Content = "Refreshed! Total: " .. #GetAllPlayers(),
            Duration = 2
        })
    end
})

PlayerTab:Button({
    Title = "Respawn Character",
    Desc = "Kill character to respawn",
    Callback = function()
        if Character then
            Character:BreakJoints()
            WindUI:Notify({
                Title = "Character",
                Content = "Respawning...",
                Duration = 2
            })
        end
    end
})

-- ========================================
-- EVENT HANDLERS
-- ========================================

LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    task.wait(0.5)
    UpdateCharacterCache()
end)

game:GetService("CoreGui").DescendantRemoving:Connect(function(obj)
    if obj.Name == "WindUI" then
        StopAutoFishGiver()
    end
end)

WindUI:Notify({
    Title = "MDVKLuaX | Pantai Losari",
    Content = "Script loaded successfully!",
    Duration = 5
})
