local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local FishRemote = FishingSystem:WaitForChild("FishGiver")
local PublishRemote = FishingSystem:WaitForChild("PublishFishCatch")
local SellRemote = FishingSystem:WaitForChild("SellFish")

local PlayerDataRemotes = ReplicatedStorage:WaitForChild("ReplicAssets"):WaitForChild("AssetsRemotes"):WaitForChild("PlayerDataRemotes")
local TransferRemote = PlayerDataRemotes:WaitForChild("TransferMoneyFunction")

local SelectedFishData = nil
local SelectedWeightMode = "Random Kg"
local AutoGive = false
local GiveDelay = 0.5
local AutoSellAll = false
local SellAllDelay = 2
local AutoSellRarity = false
local SellRarityDelay = 2
local SelectedSellRarity = nil

local SelectedTargetPlayer = nil
local SelectedAmount = "100000000000000"
local TransferDelay = 5

local FishTable = {
    { name = "Boar Fish", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Blackcap Basslet", minKg = 0.5, maxKg = 45, rarity = "Common" },
    { name = "Freshwater Piranha", minKg = 1, maxKg = 60, rarity = "Common" },
    { name = "Hermit Crab", minKg = 0.8, maxKg = 40, rarity = "Common" },
    { name = "Fangtooth", minKg = 1.5, maxKg = 55, rarity = "Common" },
    { name = "Fish", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Mujaer Fish", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Roster Fish", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Cobia", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Goldfish", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Nila Fish", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Cleo Fish", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Bone Fish", minKg = 0.5, maxKg = 45, rarity = "Common" },
    { name = "Chines Blue Fish", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Chines Fish", minKg = 0.5, maxKg = 45, rarity = "Common" },
    { name = "Chines Green Fish", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Puffy Blowhog", minKg = 0.5, maxKg = 45, rarity = "Common" },
    { name = "Fish benrtol", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Totol", minKg = 0.5, maxKg = 45, rarity = "Common" },
    { name = "Fish Black", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Yellow Fish", minKg = 0.5, maxKg = 45, rarity = "Common" },
    { name = "Nemo", minKg = 0.5, maxKg = 45, rarity = "Common" },
    { name = "Blue Fish", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Fish Tipis", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Ular kadut", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Fish gead", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Fish Lake", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Geo Fish", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Piranha Fish", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Genetik Fish", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Rock Fish", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Barracuda Fish", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Deep Fish", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Green Fish", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "ArapaimaFish", minKg = 0.5, maxKg = 50, rarity = "Common" },
    { name = "Dead Spooky Koi Fish", minKg = 5, maxKg = 80, rarity = "Uncommon" },
    { name = "Dead Scary Clownfish", minKg = 4, maxKg = 75, rarity = "Uncommon" },
    { name = "Lion Fish", minKg = 10, maxKg = 120, rarity = "Rare" },
    { name = "Luminous Fish", minKg = 12, maxKg = 130, rarity = "Rare" },
    { name = "Wraithfin Abyssal", minKg = 15, maxKg = 140, rarity = "Rare" },
    { name = "Ghost Ray", minKg = 15, maxKg = 140, rarity = "Rare" },
    { name = "purple Kraken", minKg = 15, maxKg = 140, rarity = "Rare" },
    { name = "Ghost Fish", minKg = 15, maxKg = 140, rarity = "Rare" },
    { name = "Morning Star", minKg = 0.5, maxKg = 50, rarity = "Epic" },
    { name = "Goliath Tiger", minKg = 2, maxKg = 70, rarity = "Epic" },
    { name = "Jellyfish", minKg = 3, maxKg = 65, rarity = "Epic" },
    { name = "Loving Shark", minKg = 250, maxKg = 500, rarity = "Legendary" },
    { name = "Pumpkin Carved Shark", minKg = 350, maxKg = 550, rarity = "Legendary" },
    { name = "Pink Dolphin", minKg = 190, maxKg = 500, rarity = "Legendary" },
    { name = "Crimsom Ray", minKg = 80, maxKg = 400, rarity = "Legendary" },
    { name = "Plasma Shark", minKg = 80, maxKg = 400, rarity = "Mitos" },
    { name = "Ancient Relic Crocodile", minKg = 150, maxKg = 600, rarity = "Mitos" },
    { name = "Light Dolphin", minKg = 15, maxKg = 140, rarity = "Mitos" },
    { name = "Ancient Whale", minKg = 2011, maxKg = 2900, rarity = "Secret" },
    { name = "Kraken", minKg = 1653, maxKg = 3211, rarity = "Secret" },
    { name = "Sotong", minKg = 200, maxKg = 800, rarity = "Secret" },
    { name = "Shark Bone", minKg = 200, maxKg = 800, rarity = "Secret" },
    { name = "King Crab", minKg = 200, maxKg = 800, rarity = "Secret" },
    { name = "Naga", minKg = 1125, maxKg = 1600, rarity = "Secret" },
    { name = "El Maja", minKg = 1250, maxKg = 3500, rarity = "Secret" },
    { name = "Mega Hunt", minKg = 1100, maxKg = 2245, rarity = "Secret" },
    { name = "Jungle Crocodile", minKg = 200, maxKg = 800, rarity = "Secret" },
    { name = "KingJally Strong", minKg = 800, maxKg = 1255, rarity = "Secret" },
    { name = "Sapu Sapu Goib", minKg = 200, maxKg = 800, rarity = "Secret" },
    { name = "Monster Shark", minKg = 1500, maxKg = 2200, rarity = "Secret" },
    { name = "Queen Crab", minKg = 500, maxKg = 850, rarity = "Secret" },
    { name = "Zombie Shark", minKg = 780, maxKg = 1200, rarity = "Secret" },
}

local DropdownList = {}
local FishMap = {}
local RarityOrder = { ["Common"] = 1, ["Uncommon"] = 2, ["Rare"] = 3, ["Epic"] = 4, ["Legendary"] = 5, ["Mitos"] = 6, ["Secret"] = 7 }
local SellRarityList = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mitos", "Secret"}

table.sort(FishTable, function(a, b)
    local rankA = RarityOrder[a.rarity] or 100
    local rankB = RarityOrder[b.rarity] or 100
    if rankA == rankB then return a.name < b.name else return rankA < rankB end
end)

for _, fish in ipairs(FishTable) do
    local formattedName = string.format("[%s] %s", fish.rarity, fish.name)
    table.insert(DropdownList, formattedName)
    FishMap[formattedName] = fish
end

local function GetPlayerDisplayNames()
    local tbl = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(tbl, p.DisplayName .. " (@" .. p.Name .. ")")
        end
    end
    return tbl
end

local function GiveFish()
    if not SelectedFishData then return end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local finalWeight = (SelectedWeightMode == "Min Kg" and SelectedFishData.minKg) or (SelectedWeightMode == "Max Kg" and SelectedFishData.maxKg) or (SelectedFishData.minKg + math.random() * (SelectedFishData.maxKg - SelectedFishData.minKg))
        local hookPos = char.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5).Position
        FishRemote:FireServer({ hookPosition = hookPos, name = SelectedFishData.name, rarity = SelectedFishData.rarity, weight = finalWeight })
        return finalWeight
    end
end

local function GiveAndPublishFish()
    if not SelectedFishData then return end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local finalWeight = (SelectedWeightMode == "Min Kg" and SelectedFishData.minKg) or (SelectedWeightMode == "Max Kg" and SelectedFishData.maxKg) or (SelectedFishData.minKg + math.random() * (SelectedFishData.maxKg - SelectedFishData.minKg))
        local hookPos = char.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5).Position
        FishRemote:FireServer({ hookPosition = hookPos, name = SelectedFishData.name, rarity = SelectedFishData.rarity, weight = finalWeight })
        PublishRemote:FireServer(SelectedFishData.name, finalWeight, SelectedFishData.rarity)
        return finalWeight
    end
end

local Window = WindUI:CreateWindow({
    Title = "Sunda Voice | MDVK",
    Folder = "SundaVoiceConfig",
    Icon = "solar:fish-bold-duotone",
    NewElements = true,
    
    OpenButton = {
        Title = "Open Menu",
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 25)), ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 60, 60))})
    }
})

local MainTab = Window:Tab({ Title = "Main", Icon = "solar:home-smile-bold", Border = true })
local SellingTab = Window:Tab({ Title = "Selling", Icon = "solar:wallet-money-bold", Border = true })
local EconomyTab = Window:Tab({ Title = "Economy", Icon = "solar:bank-note-bold", Border = true })

local FishSection = MainTab:Section({ Title = "Instant Fish (Exploit)" })

FishSection:Dropdown({ Title = "Select Fish", Values = DropdownList, Callback = function(val) SelectedFishData = FishMap[val] end })
FishSection:Dropdown({ Title = "Weight Mode", Values = { "Random Kg", "Min Kg", "Max Kg" }, Value = "Random Kg", Callback = function(val) SelectedWeightMode = val end })
FishSection:Slider({ Title = "Auto Give Delay", Step = 0.1, Value = { Min = 0.1, Max = 5, Default = 0.5 }, Callback = function(val) GiveDelay = val end })

FishSection:Button({
    Title = "Give Fish (Silent)",
    Callback = function()
        local w = GiveFish()
        if w then WindUI:Notify({ Title = "Success", Content = "Caught: " .. SelectedFishData.name, Icon = "check", Duration = 2 }) end
    end
})

FishSection:Button({
    Title = "Give & Publish (Flex)",
    Callback = function()
        local w = GiveAndPublishFish()
        if w then WindUI:Notify({ Title = "Published!", Content = "Broadcasted: " .. SelectedFishData.name, Icon = "solar:bell-bold", Duration = 3 }) end
    end
})

FishSection:Toggle({
    Title = "Auto Give Fish (Silent)",
    Value = false,
    Callback = function(val)
        AutoGive = val
        if val then
            task.spawn(function()
                while AutoGive do
                    if SelectedFishData then GiveFish() end
                    task.wait(GiveDelay)
                end
            end)
        end
    end
})

local SellAllSection = SellingTab:Section({ Title = "Sell Everything" })
SellAllSection:Button({ Title = "Sell All Fish", Callback = function() SellRemote:FireServer("SellAll") end })
SellAllSection:Toggle({
    Title = "Auto Sell All",
    Value = false,
    Callback = function(val)
        AutoSellAll = val
        if val then
            task.spawn(function()
                while AutoSellAll do
                    SellRemote:FireServer("SellAll")
                    task.wait(SellAllDelay)
                end
            end)
        end
    end
})
SellAllSection:Slider({ Title = "Sell All Delay", Step = 1, Value = { Min = 1, Max = 60, Default = 10 }, Callback = function(val) SellAllDelay = val end })

local SellRaritySection = SellingTab:Section({ Title = "Sell Specific Rarity" })
SellRaritySection:Dropdown({ Title = "Select Rarity to Sell", Values = SellRarityList, Callback = function(val) SelectedSellRarity = val end })
SellRaritySection:Button({ Title = "Sell Selected Rarity", Callback = function() if SelectedSellRarity then SellRemote:FireServer("SellByRarity", { rarity = SelectedSellRarity }) end end })

local EconomySection = EconomyTab:Section({ Title = "Mass Transfer Artos" })

local PlayerDropdownUI = EconomySection:Dropdown({
    Title = "Select Player",
    Values = GetPlayerDisplayNames(),
    Callback = function(val)
        local username = val:match("@([%w_]+)")
        SelectedTargetPlayer = Players:FindFirstChild(username)
    end
})

EconomySection:Button({
    Title = "Refresh Player List",
    Icon = "solar:refresh-bold",
    Callback = function()
        PlayerDropdownUI:Refresh(GetPlayerDisplayNames())
        WindUI:Notify({ Title = "System", Content = "Player list updated!", Duration = 2 })
    end
})

EconomySection:Dropdown({
    Title = "Select Amount",
    Values = {"100000000", "500000000", "1000000000", "1000000000000", "100000000000000"},
    Value = "100000000000000",
    Callback = function(val) SelectedAmount = val end
})

EconomySection:Slider({
    Title = "Transfer Delay (Give All)",
    Desc = "Naikkan jika transfer tidak masuk ke semua orang",
    Step = 1,
    Value = { Min = 3, Max = 10, Default = 5 },
    Callback = function(val) TransferDelay = val end
})

EconomySection:Button({
    Title = "Give Selected Player",
    Icon = "solar:user-bold",
    Callback = function()
        if SelectedTargetPlayer then
            task.spawn(function()
                local success, result = pcall(function() 
                    return TransferRemote:InvokeServer(SelectedTargetPlayer.UserId, SelectedAmount) 
                end)
                if success then
                    WindUI:Notify({ Title = "Success", Content = "Uang dikirim ke " .. SelectedTargetPlayer.Name, Duration = 2 })
                else
                    WindUI:Notify({ Title = "Error", Content = "Gagal mengirim uang!", Duration = 2 })
                end
            end)
        else
            WindUI:Notify({ Title = "Error", Content = "Pilih player terlebih dahulu!", Duration = 2 })
        end
    end
})

EconomySection:Button({
    Title = "Give All Players",
    Icon = "solar:users-group-two-rounded-bold",
    Callback = function()
        local allPlayers = Players:GetPlayers()
        local count = 0
        
        WindUI:Notify({ Title = "Economy", Content = "Memulai Mass Transfer...", Duration = 2 })
        
        task.spawn(function()
            for _, target in ipairs(allPlayers) do
                if target ~= LocalPlayer and target.Parent then
                    count = count + 1
                    pcall(function() 
                        TransferRemote:InvokeServer(target.UserId, SelectedAmount) 
                    end)
                    
                    task.wait(TransferDelay)
                end
            end
            WindUI:Notify({ Title = "Done", Content = "Selesai! Berhasil mengirim ke " .. tostring(count) .. " player.", Duration = 3 })
        end)
    end
})

local MiscSection = MainTab:Section({ Title = "Settings" })
MiscSection:Keybind({
    Title = "Toggle Menu Key",
    Value = "RightControl",
    Callback = function(key) Window:SetToggleKey(Enum.KeyCode[key]) end
})

Window.ConfigManager:Load("default")
