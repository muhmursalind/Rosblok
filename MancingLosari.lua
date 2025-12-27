local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem", 10)
local FishGiver = FishingSystem and FishingSystem:WaitForChild("FishGiver", 5)
local SellFish = FishingSystem and FishingSystem:WaitForChild("SellFish", 5)
local DropMoney = ReplicatedStorage:WaitForChild("DropMoney", 10)


local StateTable = nil
local function FindStateTable()
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            if rawget(v, "casted") ~= nil and rawget(v, "fishingCaught") ~= nil and rawget(v, "cooldownTime") then
                StateTable = v
                return true
            end
        end
    end
    return false
end
local successLogic = FindStateTable()

local FishTable = {
    { name = "BlueFish", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Boar Fish", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Blackcap Basslet", minKg = 0.5, maxKg = 100, rarity = "Common" },
    { name = "Pumpkin Carved Shark", minKg = 0.5, maxKg = 100, rarity = "Common" },
    { name = "Hermit Crab", minKg = 1, maxKg = 100.5, rarity = "Common" },
    { name = "Goliath Tiger", minKg = 1, maxKg = 100.5, rarity = "Common" },
    { name = "Fangtooth", minKg = 1, maxKg = 100.5, rarity = "Common" },
    { name = "StreakyFish", minKg = 10, maxKg = 100, rarity = "Uncommon" },
    { name = "Dead Spooky Koi Fish", minKg = 10, maxKg = 100, rarity = "Uncommon" },
    { name = "Dead Scary Clownfish", minKg = 10, maxKg = 100, rarity = "Uncommon" },
    { name = "Jellyfish", minKg = 40, maxKg = 100, rarity = "Uncommon" },
    { name = "Lion Fish", minKg = 20, maxKg = 150, rarity = "Rare" },
    { name = "Luminous Fish", minKg = 20, maxKg = 150, rarity = "Rare" },
    { name = "Zombie Shark", minKg = 50, maxKg = 150, rarity = "Rare" },
    { name = "Wraithfin Abyssal", minKg = 20, maxKg = 150, rarity = "Rare" },
    { name = "Loving Shark", minKg = 10, maxKg = 300, rarity = "Epic" },
    { name = "Queen Crab", minKg = 10, maxKg = 300, rarity = "Epic" },
    { name = "Pink Dolphin", minKg = 8, maxKg = 300, rarity = "Epic" },
    { name = "Plasma Shark", minKg = 300, maxKg = 450, rarity = "Legendary" },
    { name = "Ancient Relic Crocodile", minKg = 100, maxKg = 500, rarity = "Unknown" },
    { name = "Colossal Squid", minKg = 40, maxKg = 450, rarity = "Legendary" },
    { name = "Ancient Whale", minKg = 400, maxKg = 500, rarity = "Unknown" },
    { name = "Monster Shark", minKg = 400, maxKg = 500, rarity = "Unknown" },
    { name = "Lava Megalodon", minKg = 1000, maxKg = 1000, rarity = "Unknown" },
    { name = "Megalodon", minKg = 900, maxKg = 1000, rarity = "Unknown" },
    { name = "Zombie Megalodon", minKg = 800, maxKg = 900, rarity = "Unknown" },
    { name = "Kraken", minKg = 800, maxKg = 850, rarity = "Unknown" },
    { name = "Naga Keramat", minKg = 1000, maxKg = 1000, rarity = "Unknown" },
    { name = "RobotMegalodon", minKg = 800, maxKg = 1000, rarity = "Unknown" }
}

local FishLookup = {}
local FishNameList = {}
for _, fish in ipairs(FishTable) do FishLookup[fish.name] = fish; table.insert(FishNameList, fish.name) end

local MoneyAmountList = {}
local MoneyAmountLookup = {}
for i = 1, 10 do local label = tostring(i) .. " Juta"; MoneyAmountList[i] = label; MoneyAmountLookup[label] = i * 1000000 end

local Character, HumanoidRootPart, Humanoid
local SelectedPlayerName = nil

local AutoCastEnabled = false
local CastChargeTime = 0.9
local ReelClickDelay = 0.05

local AutoFishGiver = false
local AutoSellFish = false
local AutoDropMoney = false
local SelectedFish = FishTable[1]
local DelayAmount = 0.1
local SellDelayAmount = 5
local SelectedDropAmount = 1000000
local MinDropDelay, MaxDropDelay = 5, 10

local GiverConnection, SellConnection, DropMoneyThread

local function UpdateCharacterCache()
    Character = LocalPlayer.Character
    if Character then
        HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
        Humanoid = Character:FindFirstChild("Humanoid")
    end
end
LocalPlayer.CharacterAdded:Connect(function(_) task.wait(0.5); UpdateCharacterCache() end)
UpdateCharacterCache()

local function GetPlayerPosition()
    return HumanoidRootPart and HumanoidRootPart.Position or Vector3.new(0, 0, 0)
end

local function SmartClick(action, holdTime)
    local CenterX = Camera.ViewportSize.X / 2
    local CenterY = Camera.ViewportSize.Y / 2

    if action == "Hold" then
        VirtualInputManager:SendMouseButtonEvent(CenterX, CenterY, 0, true, game, 1)
        task.wait(holdTime)
        VirtualInputManager:SendMouseButtonEvent(CenterX, CenterY, 0, false, game, 1)
    elseif action == "Click" then
        VirtualInputManager:SendMouseButtonEvent(CenterX, CenterY, 0, true, game, 1)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(CenterX, CenterY, 0, false, game, 1)
    end
end

local function GiveFish(fish)
    if not FishGiver then return false end
    local hookPosition = GetPlayerPosition()
    return pcall(function()
        FishGiver:FireServer({hookPosition = hookPosition, rarity = fish.rarity, name = fish.name, weight = fish.maxKg})
    end)
end

local function GetBackpackFishData()
    local backpack = LocalPlayer:WaitForChild("Backpack", 5)
    local fishList = {}
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and not item.Name:match("Rod") then
                local weight = item:GetAttribute("Weight") or item:GetAttribute("weight") or (item:FindFirstChild("Weight") and item.Weight.Value)
                local rarity = item:GetAttribute("Rarity") or item:GetAttribute("rarity") or (item:FindFirstChild("Rarity") and item.Rarity.Value)
                local fishId = item:GetAttribute("FishId") or item:GetAttribute("fishId") or (item:FindFirstChild("FishId") and item.FishId.Value)
                if weight and rarity and fishId then
                    table.insert(fishList, {weight = weight, rarity = rarity, fishId = fishId})
                end
            end
        end
    end
    return fishList
end

local function SellAllBackpackFish()
    if not SellFish then return false, "Remote SellFish not found" end
    local batch = GetBackpackFishData()
    if #batch == 0 then return false, "No fish in backpack" end
    pcall(function() SellFish:FireServer("SellAllBatch", batch) end)
    return true, #batch
end

local function GetAllPlayers()
    local playerList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then table.insert(playerList, player.Name) end
    end
    table.sort(playerList, function(a, b) return string.lower(a) < string.lower(b) end)
    return playerList
end

local function TeleportToPlayer(targetName)
    local target = Players:FindFirstChild(targetName)
    local targetRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    
    UpdateCharacterCache()
    
    if Character and targetRoot and Character.PrimaryPart then
        local targetCFrame = targetRoot.CFrame * CFrame.new(0, 5, 0)
        
        Character:SetPrimaryPartCFrame(targetCFrame)
        return true
    end
    return false
end


local function StartAutoFishGiver() if GiverConnection then return end
    local lastGiveTime = tick()
    GiverConnection = RunService.Heartbeat:Connect(function()
        if AutoFishGiver and SelectedFish and (tick() - lastGiveTime >= DelayAmount) then
            if GiveFish(SelectedFish) then lastGiveTime = tick() end
        end
    end)
end
local function StopAutoFishGiver() AutoFishGiver = false; if GiverConnection then GiverConnection:Disconnect(); GiverConnection = nil end end

local function StartAutoSellFish() if SellConnection then return end
    local lastSellTime = tick()
    SellConnection = RunService.Heartbeat:Connect(function()
        if AutoSellFish and (tick() - lastSellTime >= SellDelayAmount) then
            SellAllBackpackFish()
            lastSellTime = tick()
        end
    end)
end
local function StopAutoSellFish() AutoSellFish = false; if SellConnection then SellConnection:Disconnect(); SellConnection = nil end end

local function StartAutoDropMoney() if DropMoneyThread then return end
    DropMoneyThread = task.spawn(function()
        while AutoDropMoney do
            if DropMoney then pcall(function() DropMoney:FireServer(SelectedDropAmount) end) end
            task.wait(math.random(MinDropDelay, MaxDropDelay))
        end
        DropMoneyThread = nil
    end)
end
local function StopAutoDropMoney() AutoDropMoney = false end

local Window = WindUI:CreateWindow({
    Title = "MDVKLuaX | Pantai Losari HUB",
    Author = "MDVKLuaX",
    Folder = "MDVKPantaiLosariHubConfig",
    Size = UDim2.fromOffset(580, 480),
    Theme = "Dark",
    Transparent = true,
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
        Position = UDim2.new(0.01, 0, 0.8, 0),
        Color = ColorSequence.new({ 
            ColorSequenceKeypoint.new(0, Color3.fromRGB(13, 110, 253)), 
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 230, 255)) 
        })
    }
})

local Tabs = {
    AutoFish = Window:Tab({ Title = "Auto Fish", Icon = "anchor" }),
    Exploits = Window:Tab({ Title = "Exploits", Icon = "sparkles" }),
    Money = Window:Tab({ Title = "Money/Sell", Icon = "wallet" }),
    Player = Window:Tab({ Title = "Player", Icon = "user" }),
}

local MechSection = Tabs.AutoFish:Section({ Title = "Auto Cast & Reel", Opened = true })

local StatusParagraph = MechSection:Paragraph({ Title = "Game Logic Status", Desc = successLogic and "Connected" or "Scanning...", Icon = successLogic and "check" or "loader" })
if not successLogic then
    task.spawn(function()
        while not StateTable do FindStateTable(); task.wait(1) end
        StatusParagraph:SetTitle("Game Logic Status: Connected")
        StatusParagraph:SetIcon("check")
    end)
end

MechSection:Toggle({
    Title = "Enable Auto Fish Bot",
    Desc = "Mancing otomatis (Wajib Pegang Joran dan berada di air)",
    Value = false,
    Callback = function(state) AutoCastEnabled = state; if state and not StateTable then FindStateTable() end end
})

Tabs.AutoFish:Section({ Title = "Bot Timing" })

Tabs.AutoFish:Slider({
    Title = "Cast Power (Charge Time)", Desc = "Lama tahan klik untuk melempar (0.9 = Power Tinggi)",
    Value = { Min = 0.1, Max = 1.5, Default = 0.9 }, Step = 0.1, Callback = function(v) CastChargeTime = v end
})

Tabs.AutoFish:Slider({
    Title = "Reel Speed (Click Delay)", Desc = "Jeda klik saat menarik ikan (0.01 = Cepat)",
    Value = { Min = 0.01, Max = 0.5, Default = 0.05 }, Step = 0.01, Callback = function(v) ReelClickDelay = v end
})

Tabs.Exploits:Section({ Title = "Instant Fish Giver" })

Tabs.Exploits:Dropdown({
    Title = "Select Fish Type", Values = FishNameList, Value = FishNameList[1],
    Callback = function(val) SelectedFish = FishLookup[val]; WindUI:Notify({ Title = "Fish Selected", Content = SelectedFish.name, Duration = 2 }) end
})

Tabs.Exploits:Button({
    Title = "Give Fish Once",
    Callback = function()
        if GiveFish(SelectedFish) then
            WindUI:Notify({ Title = "Fish Given!", Content = string.format("%s - %.1fkg", SelectedFish.name, SelectedFish.maxKg), Duration = 2 })
        else
            WindUI:Notify({ Title = "Error", Content = "Gagal memberi ikan.", Duration = 2 })
        end
    end
})

Tabs.Exploits:Toggle({
    Title = "Auto Give Fish", Desc = "Mendapatkan ikan tanpa mancing (Langsung masuk tas)",
    Callback = function(state)
        AutoFishGiver = state
        if state then StartAutoFishGiver() else StopAutoFishGiver() end
        WindUI:Notify({ Title = "Auto Give Fish", Content = state and "Started!" or "Stopped!", Duration = 2 })
    end
})

Tabs.Exploits:Slider({
    Title = "Give Delay", Value = {Min = 0.1, Max = 10, Default = 0.1}, Step = 0.1,
    Callback = function(v) DelayAmount = v end
})

local SellSection = Tabs.Money:Section({ Title = "Selling" })

SellSection:Button({
    Title = "Sell All Fish Now",
    Callback = function()
        local s, r = SellAllBackpackFish()
        WindUI:Notify({ Title = "Sell Status", Content = s and ("Sold " .. r .. " items") or (r or "Failed"), Duration = 2 })
    end
})

SellSection:Toggle({
    Title = "Auto Sell Fish",
    Callback = function(state)
        AutoSellFish = state
        if state then StartAutoSellFish() else StopAutoSellFish() end
        WindUI:Notify({ Title = "Auto Sell Fish", Content = state and "Started!" or "Stopped!", Duration = 2 })
    end
})

SellSection:Slider({
    Title = "Auto Sell Delay", Step = 1,
    Value = { Min = 5, Max = 30, Default = 5 },
    Callback = function(v) SellDelayAmount = v end
})

local DropSection = Tabs.Money:Section({ Title = "Money Drop" })

DropSection:Dropdown({
    Title = "Drop Amount", Values = MoneyAmountList, Value = MoneyAmountList[1],
    Callback = function(v) SelectedDropAmount = MoneyAmountLookup[v] end
})

DropSection:Button({
    Title = "Drop Money Once",
    Callback = function()
        if DropMoney then pcall(function() DropMoney:FireServer(SelectedDropAmount) end) end
        WindUI:Notify({ Title = "Drop Money", Content = "Dropped: " .. tostring(SelectedDropAmount), Duration = 2 })
    end
})

DropSection:Toggle({
    Title = "Auto Drop Money", Desc = string.format("Random delay %d-%d detik", MinDropDelay, MaxDropDelay),
    Callback = function(state)
        AutoDropMoney = state
        if state then StartAutoDropMoney() else StopAutoDropMoney() end
        WindUI:Notify({ Title = "Auto Drop Money", Content = state and "Started!" or "Stopped!", Duration = 2 })
    end
})

Tabs.Player:Section({ Title = "Teleportation" })

local TeleportDropdown
TeleportDropdown = Tabs.Player:Dropdown({
    Title = "Player List", Values = GetAllPlayers(),
    Callback = function(v) SelectedPlayerName = v end
})

Tabs.Player:Button({ Title = "Refresh Player List", Callback = function() TeleportDropdown:SetValues(GetAllPlayers()) end })

Tabs.Player:Button({
    Title = "Teleport To Player",
    Callback = function()
        if TeleportToPlayer(SelectedPlayerName) then
            WindUI:Notify({ Title = "Teleported", Content = "To: " .. SelectedPlayerName, Duration = 2 })
        else
            WindUI:Notify({ Title = "Teleport Failed", Content = "Target tidak ditemukan atau karakter belum dimuat.", Duration = 2 })
        end
    end
})

Tabs.Player:Section({ Title = "Character Utilities" })

Tabs.Player:Button({
    Title = "Respawn Character",
    Callback = function()
        if Character then Character:BreakJoints() end
        WindUI:Notify({ Title = "Character", Content = "Respawning...", Duration = 2 })
    end
})

task.spawn(function()
    while true do
        task.wait()
        
        if AutoCastEnabled and StateTable then
            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
            
            if tool and tool:FindFirstChild("Part") then
                if not StateTable.casted and not StateTable.fishingInProgress and not StateTable.castingCooldown and StateTable.canCast then
                    task.wait(0.5)
                    SmartClick("Hold", CastChargeTime)
                    task.wait(1)
                
                elseif StateTable.fishingInProgress and StateTable.casted then
                    SmartClick("Click")
                    task.wait(ReelClickDelay > 0 and ReelClickDelay or 0.05) 

                elseif StateTable.fishingCaught then
                    SmartClick("Click")
                    task.wait(0.5) 
                end
            end
        else
            task.wait(0.5)
        end
    end
end)

game:GetService("CoreGui").DescendantRemoving:Connect(function(obj)
    if obj.Name == "WindUI" then
        StopAutoFishGiver()
        StopAutoSellFish()
        StopAutoDropMoney()
    end
end)

Window:CreateTopbarButton("theme", "moon", function()
    local theme = WindUI:GetCurrentTheme()
    WindUI:SetTheme(theme == "Dark" and "Light" or "Dark")
end)

WindUI:Notify({
    Title = "MDVKLuaX | Pantai Losari",
    Content = "Script Hub Loaded Successfully!",
    Duration = 5
})
