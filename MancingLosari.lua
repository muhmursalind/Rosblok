local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local FishGiver = ReplicatedStorage:WaitForChild("FishingSystem"):WaitForChild("FishGiver")
local SellFish = ReplicatedStorage:WaitForChild("FishingSystem"):WaitForChild("SellFish")
local DropMoney = ReplicatedStorage:WaitForChild("DropMoney")

-- ========================================
-- FISH DATA
-- ========================================
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
    {name = "Megalodon", maxKg = 900, rarity = "Unknown"},
    {name = "Kraken", maxKg = 850, rarity = "Unknown"},
    {name = "Naga Keramat", maxKg = 850, rarity = "Unknown"}
}

local FishLookup = {}
local FishNameList = {}
for i, fish in ipairs(FishTable) do
    FishLookup[fish.name] = fish
    table.insert(FishNameList, fish.name)
end

local MoneyAmountList = {}
local MoneyAmountLookup = {}

for i = 1, 10 do
    local label = tostring(i) .. " Juta"
    MoneyAmountList[i] = label
    MoneyAmountLookup[label] = i * 1000000
end

-- ========================================
-- VARIABLES
-- ========================================
local AutoFishGiver = false
local AutoSellFish = false
local SelectedFish = FishTable[1]
local DelayAmount = 1
local SellDelayAmount = 5
local Connection
local SellConnection

local AutoDropMoney = false
local SelectedDropAmount = 1000000
local MinDropDelay, MaxDropDelay = 5, 10
local DropMoneyThread

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

-- ========================================
-- FISH GIVE FUNCTIONS
-- ========================================
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

-- ========================================
-- AUTO SELL FISH FUNCTIONS
-- ========================================
local function GetBackpackFishData()
    local backpack = LocalPlayer:WaitForChild("Backpack")
    local fishList = {}
    
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            local weight = item:GetAttribute("Weight") or item:GetAttribute("weight")
            local rarity = item:GetAttribute("Rarity") or item:GetAttribute("rarity")
            local fishId = item:GetAttribute("FishId") or item:GetAttribute("fishId")
            
            if not weight and item:FindFirstChild("Weight") then
                weight = item.Weight.Value
            end
            if not rarity and item:FindFirstChild("Rarity") then
                rarity = item.Rarity.Value
            end
            if not fishId and item:FindFirstChild("FishId") then
                fishId = item.FishId.Value
            end
            
            if weight and rarity and fishId then
                table.insert(fishList, {
                    weight = weight,
                    rarity = rarity,
                    fishId = fishId
                })
            end
        end
    end
    
    return fishList
end

local function SellAllBackpackFish()
    local batch = GetBackpackFishData()
    
    if #batch == 0 then
        return false, "No fish in backpack"
    end
    
    local success = pcall(function()
        SellFish:FireServer("SellAllBatch", batch)
    end)
    
    return success, #batch
end

local function StartAutoSellFish()
    if SellConnection then return end
    
    local lastSellTime = tick()
    SellConnection = RunService.Heartbeat:Connect(function()
        if AutoSellFish then
            local currentTime = tick()
            if currentTime - lastSellTime >= SellDelayAmount then
                SellAllBackpackFish()
                lastSellTime = currentTime
            end
        end
    end)
end

local function StopAutoSellFish()
    AutoSellFish = false
    if SellConnection then
        SellConnection:Disconnect()
        SellConnection = nil
    end
end

-- ========================================
-- PLAYER FUNCTIONS
-- ========================================
local function GetAllPlayers()
    local playerList = {}
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playerList, player.Name)
        end
    end

    table.sort(playerList, function(a, b)
        return string.lower(a) < string.lower(b)
    end)

    return playerList
end


local function TeleportToPlayer(targetPlayerName)
    local targetPlayer = Players:FindFirstChild(targetPlayerName)
    if not targetPlayer or not targetPlayer.Character then
        warn("[Teleport] Player not found or has no character: " .. targetPlayerName)
        return false
    end
    
    UpdateCharacterCache()

    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot or not HumanoidRootPart then
        warn("[Teleport] Failed to get root parts")
        return false
    end

    HumanoidRootPart.CFrame = targetRoot.CFrame
    return true
end

-- ========================================
-- AUTO DROP MONEY FUNCTIONS
-- ========================================
local function StartAutoDropMoney()
    if DropMoneyThread then return end

    DropMoneyThread = task.spawn(function()
        while AutoDropMoney do
            pcall(function()
                DropMoney:FireServer(SelectedDropAmount)
            end)

            local delayTime = math.random(MinDropDelay, MaxDropDelay)
            task.wait(delayTime)
        end
        DropMoneyThread = nil
    end)
end

local function StopAutoDropMoney()
    AutoDropMoney = false
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

MainTab:Section({
    Title = "Farm Fish"
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
                Title = "Auto Give Fish",
                Content = "Started!",
                Duration = 2
            })
        else
            StopAutoFishGiver()
            WindUI:Notify({
                Title = "Auto Give Fish",
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

MainTab:Section({
    Title = "Sell Fish"
})

MainTab:Button({
    Title = "Sell All Fish",
    Callback = function()
        local success, result = SellAllBackpackFish()
        if success then
            WindUI:Notify({
                Title = "Fish Sold!",
                Content = string.format("Sold %d fish from backpack", result),
                Duration = 2
            })
        else
            WindUI:Notify({
                Title = "Sell Failed",
                Content = result or "No fish found",
                Duration = 2
            })
        end
    end
})

MainTab:Toggle({
    Title = "Auto Sell Fish",
    Callback = function(state)
        AutoSellFish = state
        if state then
            StartAutoSellFish()
            WindUI:Notify({
                Title = "Auto Sell Fish",
                Content = "Started!",
                Duration = 2
            })
        else
            StopAutoSellFish()
            WindUI:Notify({
                Title = "Auto Sell Fish",
                Content = "Stopped!",
                Duration = 2
            })
        end
    end
})

MainTab:Slider({
    Title = "Auto Sell Delay",
    Step = 1,
    Value = {
        Min = 5,
        Max = 30,
        Default = 5
    },
    Callback = function(value)
        SellDelayAmount = value
    end
})

MainTab:Section({
    Title = "Drop Money"
})

MainTab:Dropdown({
    Title = "Amount",
    Desc = "Pilih jumlah uang",
    Values = MoneyAmountList,
    Value = MoneyAmountList[1],
    Callback = function(selectedLabel)
        local amount = MoneyAmountLookup[selectedLabel]
        if amount then
            SelectedDropAmount = amount
            WindUI:Notify({
                Title = "Drop Amount Selected",
                Content = selectedLabel .. " (" .. tostring(amount) .. ")",
                Duration = 2
            })
        end
    end
})

MainTab:Button({
    Title = "Drop Sekali",
    Desc = "Drop uang sekali",
    Callback = function()
        pcall(function()
            DropMoney:FireServer(SelectedDropAmount)
        end)
        WindUI:Notify({
            Title = "Drop Money",
            Content = "Dropped: " .. tostring(SelectedDropAmount),
            Duration = 2
        })
    end
})

MainTab:Toggle({
    Title = "Auto Drop Money",
    Desc = "Random delay 5-10 detik",
    Callback = function(state)
        AutoDropMoney = state
        if state then
            StartAutoDropMoney()
            WindUI:Notify({
                Title = "Auto Drop Money",
                Content = "Started!",
                Duration = 2
            })
        else
            StopAutoDropMoney()
            WindUI:Notify({
                Title = "Auto Drop Money",
                Content = "Stopped!",
                Duration = 2
            })
        end
    end
})

-- ========================================
-- TAB 2: PLAYER
-- ========================================
local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "user"
})

local SelectedPlayerName = nil
local TeleportDropdown

local function RefreshTeleportDropdown()
    local players = GetAllPlayers()

    if TeleportDropdown then
        TeleportDropdown:SetValues(players)
    end

    if #players > 0 then
        SelectedPlayerName = players[1]
    else
        SelectedPlayerName = nil
    end
end

TeleportDropdown = PlayerTab:Dropdown({
    Title = "Player List",
    Desc = "Pilih player",
    Values = GetAllPlayers(),
    Callback = function(selectedName)
        SelectedPlayerName = selectedName

        if SelectedPlayerName then
            WindUI:Notify({
                Title = "Player Selected",
                Content = "Selected: " .. SelectedPlayerName,
                Duration = 2
            })
        end
    end
})

PlayerTab:Button({
    Title = "Teleport",
    Desc = "Teleport ke player yang dipilih",
    Callback = function()
        if not SelectedPlayerName then
            WindUI:Notify({
                Title = "Teleport",
                Content = "Pilih player dulu!",
                Duration = 2
            })
            return
        end

        if TeleportToPlayer(SelectedPlayerName) then
            WindUI:Notify({
                Title = "Teleported",
                Content = "To: " .. SelectedPlayerName,
                Duration = 2
            })
        else
            WindUI:Notify({
                Title = "Teleport Failed",
                Content = "Tidak bisa teleport ke: " .. tostring(SelectedPlayerName),
                Duration = 2
            })
        end
    end
})

PlayerTab:Button({
    Title = "Refresh Player List",
    Desc = "Update daftar player",
    Callback = function()
        RefreshTeleportDropdown()
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
        StopAutoSellFish()
        StopAutoDropMoney()
    end
end)

WindUI:Notify({
    Title = "MDVKLuaX | Pantai Losari",
    Content = "Script loaded successfully!",
    Duration = 5
})
