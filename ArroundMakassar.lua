local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- System Variables
local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem", 10)
local FishGiver = FishingSystem:WaitForChild("FishGiver", 5)
local SellFish = FishingSystem:WaitForChild("SellFish", 5)
local TransferRequest = FishingSystem:WaitForChild("TransferRequest", 5)

-- UI Variables (Agar bisa diakses fungsi refresh)
local DropTradePlayer, DropTPPlayer

-- Data Ikan
local FishTable = {
    {name = "Boar Fish", minKg = 0.5, maxKg = 50, rarity = "Common"},
    {name = "Blackcap Basslet", minKg = 0.5, maxKg = 45, rarity = "Common"},
    {name = "Pumpkin Carved Shark", minKg = 1, maxKg = 60, rarity = "Common"},
    {name = "Freshwater Piranha", minKg = 1, maxKg = 60, rarity = "Common"},
    {name = "Hermit Crab", minKg = 0.8, maxKg = 40, rarity = "Common"},
    {name = "Goliath Tiger", minKg = 2, maxKg = 70, rarity = "Common"},
    {name = "Fangtooth", minKg = 1.5, maxKg = 55, rarity = "Common"},
    {name = "Dead Spooky Koi Fish", minKg = 5, maxKg = 80, rarity = "Uncommon"},
    {name = "Poop", minKg = 5, maxKg = 80, rarity = "Uncommon"},
    {name = "Dead Scary Clownfish", minKg = 4, maxKg = 75, rarity = "Uncommon"},
    {name = "Jellyfish", minKg = 3, maxKg = 65, rarity = "Uncommon"},
    {name = "Lion Fish", minKg = 10, maxKg = 120, rarity = "Rare"},
    {name = "Luminous Fish", minKg = 12, maxKg = 130, rarity = "Rare"},
    {name = "Zombie Shark", minKg = 20, maxKg = 150, rarity = "Rare"},
    {name = "Wraithfin Abyssal", minKg = 15, maxKg = 140, rarity = "Rare"},
    {name = "Loving Shark", minKg = 30, maxKg = 250, rarity = "Epic"},
    {name = "Monster Shark", minKg = 35, maxKg = 280, rarity = "Epic"},
    {name = "Queen Crab", minKg = 25, maxKg = 220, rarity = "Epic"},
    {name = "Pink Dolphin", minKg = 40, maxKg = 300, rarity = "Epic"},
    {name = "Ghost Fish", minKg = 40, maxKg = 300, rarity = "Epic"},
    {name = "Plasma Shark", minKg = 80, maxKg = 400, rarity = "Legendary"},
    {name = "Ancient Relic Crocodile", minKg = 150, maxKg = 600, rarity = "Unknown"},
    {name = "Mega Pink", minKg = 175, maxKg = 700, rarity = "Unknown"},
    {name = "Ancient Whale", minKg = 200, maxKg = 800, rarity = "Unknown"}
}

-- Mapping Data Ikan
local FishNames, FishDataMap = {"All Fish"}, {}
for _, fish in ipairs(FishTable) do
    local dName = string.format("[%s] %s", fish.rarity, fish.name)
    table.insert(FishNames, dName)
    FishDataMap[dName] = fish
end

-- State Variables
local SelectedFish = FishTable[#FishTable]
local SelectedWeightMode = "RandomKG"
local AutoGive, GiveDelay, AutoSell, SellDelay = false, 0.1, false, 5.0
local SelectedTradePlayer, SelectedTeleportPlayer = nil, nil
local SelectedTradeFish = "All Fish"
local AutoGiftEnabled, isCurrentlyGifting = false, false

-----------------------------------------------------------
-- CORE FUNCTIONS
-----------------------------------------------------------

local function GetPlayerList()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(names, p.Name) end
    end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    return names
end

local function UpdateAllPlayerLists()
    local newList = GetPlayerList()
    if DropTradePlayer then DropTradePlayer:SetValues(newList) end
    if DropTPPlayer then DropTPPlayer:SetValues(newList) end
end

local function ActionSellAll()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local batch = {}
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and not item.Name:match("Rod") then
                local w = item:GetAttribute("Weight") or (item:FindFirstChild("Weight") and item.Weight.Value)
                local r = item:GetAttribute("Rarity") or (item:FindFirstChild("Rarity") and item.Rarity.Value)
                local id = item:GetAttribute("FishId") or (item:FindFirstChild("FishId") and item.FishId.Value)
                if w and r and id then table.insert(batch, {weight = w, rarity = r, fishId = id}) end
            end
        end
    end
    if #batch > 0 then 
        pcall(function() SellFish:FireServer("SellAllBatch", batch) end)
        return #batch
    end
    return 0
end

local function ActionGiveFish()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root and SelectedFish then
        local w = SelectedWeightMode == "MinKG" and SelectedFish.minKg 
                  or SelectedWeightMode == "MaxKG" and SelectedFish.maxKg 
                  or math.random(SelectedFish.minKg * 10, SelectedFish.maxKg * 10) / 10
        pcall(function()
            FishGiver:FireServer({hookPosition = root.Position, rarity = SelectedFish.rarity, name = SelectedFish.name, weight = w})
        end)
    end
end

local function ActionGiftOne()
    if isCurrentlyGifting or not SelectedTradePlayer then return end
    local target = Players:FindFirstChild(SelectedTradePlayer)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not target or not backpack then return end

    for _, item in ipairs(backpack:GetChildren()) do
        local id = item:FindFirstChild("FishId")
        if id then
            local isMatch = (SelectedTradeFish == "All Fish") or string.find(SelectedTradeFish, item.Name)
            if isMatch then
                isCurrentlyGifting = true
                TransferRequest:FireServer(target, id.Value)
                local timeout = 0
                while item.Parent == backpack and timeout < 5 do
                    task.wait(0.5)
                    timeout = timeout + 0.5
                end
                isCurrentlyGifting = false
                return true
            end
        end
    end
    return false
end

-----------------------------------------------------------
-- MAIN UI SETUP
-----------------------------------------------------------

local Window = WindUI:CreateWindow({
    Title = "MDVKLuaX | MancingYuk",
    Author = "MDVKLuaX",
    Folder = "MDVKMancingYukConfig",
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
    Main = Window:Tab({ Title = "Fish", Icon = "fish" }),
    Trade = Window:Tab({ Title = "Trade", Icon = "gift" }),
    Economy = Window:Tab({ Title = "Sell", Icon = "shopping-cart" }),
    World = Window:Tab({ Title = "Teleport", Icon = "map-pin" }),
}

--- [TAB: FISH GIVER] ---
local SectionGen = Tabs.Main:Section({ Title = "Fishing", Opened = true })
SectionGen:Dropdown({
    Title = "Select Fish",
    Values = FishNames, 
    Value = FishNames[#FishNames], 
    SearchBarEnabled = true, 
    Callback = function(val) SelectedFish = FishDataMap[val] end
})
SectionGen:Dropdown({
    Title = "Select Weight",
    Values = {"MinKG", "MaxKG", "RandomKG"}, 
    Value = "RandomKG", 
    Callback = function(val) SelectedWeightMode = val end
})
SectionGen:Slider({
    Title = "Delay FishGiver",
    Value = {Min = 0.1, Max = 5.0, Default = 0.5}, 
    Step = 0.1, 
    Callback = function(v) GiveDelay = v end
})
SectionGen:Toggle({
    Title = "Auto Give Fish", 
    Callback = function(state)
        AutoGive = state
        task.spawn(function() while AutoGive do ActionGiveFish() task.wait(GiveDelay) end end)
    end
})
-- TAMBAHAN: Tombol Give Fish Manual
SectionGen:Button({
    Title = "Give Fish (Manual)", 
    Icon = "hand", 
    Callback = function() 
        ActionGiveFish() 
        WindUI:Notify({Title="Success", Content="Fish given successfully!"})
    end
})

--- [TAB: TRADE / GIFT] ---
local SectionGift = Tabs.Trade:Section({ Title = "Trading", Opened = true })

DropTradePlayer = SectionGift:Dropdown({
    Title = "Target Player", 
    Values = GetPlayerList(), 
    SearchBarEnabled = true, 
    Callback = function(val) SelectedTradePlayer = val end
})

SectionGift:Dropdown({
    Title = "Filter Fish", 
    Values = FishNames, 
    Value = "All Fish", 
    SearchBarEnabled = true, 
    Callback = function(val) SelectedTradeFish = val end
})

SectionGift:Toggle({
    Title = "Auto Gift Fish",
    Callback = function(state)
        AutoGiftEnabled = state
        task.spawn(function() while AutoGiftEnabled do ActionGiftOne() task.wait(0.5) end end)
    end
})

-- TAMBAHAN: Tombol Trade/Gift Fish Manual
SectionGift:Button({
    Title = "Gift Fish (Manual)", 
    Icon = "send", 
    Callback = function() 
        local success = ActionGiftOne()
        if success then
            WindUI:Notify({Title="Trade", Content="Sent fish to "..tostring(SelectedTradePlayer)})
        else
            WindUI:Notify({Title="Error", Content="Failed to gift fish. Check player target or filter!"})
        end
    end
})

SectionGift:Button({
    Title = "Manual Refresh Players", 
    Icon = "refresh-cw", 
    Callback = function() UpdateAllPlayerLists() end
})

--- [TAB: TELEPORT] ---
local SectionTP = Tabs.World:Section({ Title = "Teleport", Opened = true })

DropTPPlayer = SectionTP:Dropdown({
    Title = "Select Player", 
    Values = GetPlayerList(), 
    SearchBarEnabled = true, 
    Callback = function(val) SelectedTeleportPlayer = val end
})

SectionTP:Button({
    Title = "Teleport to Player", 
    Icon = "map-pin", 
    Callback = function()
        local target = Players:FindFirstChild(SelectedTeleportPlayer)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)
        end
    end
})

SectionTP:Button({
    Title = "Refresh List (A-Z)", 
    Icon = "refresh-ccw", 
    Callback = function()
        UpdateAllPlayerLists()
        WindUI:Notify({Title="System", Content="Player list updated and sorted (A-Z)."})
    end
})

--- [TAB: ECONOMY] ---
local SectionSell = Tabs.Economy:Section({ Title = "Selling", Opened = true })
SectionSell:Slider({
    Title = "Selling Delay", 
    Value = { Min = 1.0, Max = 10.0, Default = 5.0 }, 
    Step = 1.0, 
    Callback = function(v) SellDelay = v end
})
SectionSell:Toggle({
    Title = "Auto Sell", 
    Callback = function(state)
        AutoSell = state
        task.spawn(function() while AutoSell do ActionSellAll() task.wait(SellDelay) end end)
    end
})

-- TAMBAHAN: Tombol Sell All Manual
SectionSell:Button({
    Title = "Sell All Items", 
    Icon = "dollar-sign", 
    Callback = function() 
        local count = ActionSellAll()
        WindUI:Notify({Title="Economy", Content="Sold "..tostring(count).." items!"})
    end
})

-----------------------------------------------------------
-- AUTO-UPDATE SYSTEM
-----------------------------------------------------------

Players.PlayerAdded:Connect(function()
    task.wait(1)
    UpdateAllPlayerLists()
end)

Players.PlayerRemoving:Connect(function()
    UpdateAllPlayerLists()
end)

WindUI:Notify({
    Title = "MDVKLuaX",
    Content = "System Fully Loaded with Manual Buttons!",
    Duration = 5
})
