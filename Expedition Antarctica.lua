local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Config = {
    RestTime = 5,           
    PreTeleportDelay = 5,   
    HoverTime = 5,          
    JumpInterval = 3,       
    SafeHeight = 5,         
    
    WaterHoverHeight = 5,   
    RefillThreshold = 30,   
    RefillTarget = 95,      
    
    PassTrigger = 75, PassTarget = 140, 
    NoPassTrigger = 50, NoPassTarget = 90,

    TimerCoord = CFrame.new(-5917.80, -156.94, -4.67)
}

local AutoExpeditionEnabled = false
local AutoTimerEnabled = false
local IsBusy = false 
local CurrentStatus = "Idle"

local ExpeditionWaypoints = {
    ["Base Camp"] = CFrame.new(-3719.18, 223.20, 235.39),
    ["Camp 1"] = CFrame.new(-3719.18, 223.20, 235.39),
    ["Camp 2"] = CFrame.new(1790.31, 103.66, -137.85),
    ["Camp 3"] = CFrame.new(5892.38, 319.35, -19.07),
    ["Camp 4"] = CFrame.new(8992.36, 594.10, 103.06),
    ["South Pole"] = CFrame.new(10995.24, 545.25, 114.80)
}

local WaterWaypoints = {
    ["Base Camp Water"] = CFrame.new(-6043.26, -159.64, -60.20),
    ["Camp 1 Water"]    = CFrame.new(-3718.26, 228.39, 264.40),
    ["Camp 2 Water"]    = CFrame.new(1800.04, 104.71, -163.36),
    ["Camp 3 Water"]    = CFrame.new(5884.99, 320.36, 6.23),
    ["Camp 4 Water"]    = CFrame.new(9000.64, 596.78, 85.16)
}

local SequenceMap = {
    ["Base Camp"] = "Camp 1",
    ["Camp 1"]    = "Camp 2",
    ["Camp 2"]    = "Camp 3",
    ["Camp 3"]    = "Camp 4",
    ["Camp 4"]    = "South Pole",
    ["South Pole"]= "Finish"
}

local function UpdateStatus(text)
    CurrentStatus = text
end

local function GetCurrentSpawn()
    return LocalPlayer:GetAttribute("SpawnLocation") or "Base Camp"
end

local function GetRoot()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function ForceJump()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.Jump = true
        char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

local function CheckGamepass()
    local store = LocalPlayer:FindFirstChild("Store_Info")
    if store and store:FindFirstChild("Gamepasses_Own") then
        return store.Gamepasses_Own:FindFirstChild("ExtraStamina") ~= nil
    end
    return false
end

local function GetHydration() return LocalPlayer:GetAttribute("Hydration") or 100 end

local function GetBottleValue()
    local inv = LocalPlayer:FindFirstChild("Inventory")
    if inv and inv:FindFirstChild("Bottle") then
        return inv.Bottle:GetAttribute("Value") or inv.Bottle.Value or 100
    end
    return 100
end

local function GetNearestWaterSource()
    local root = GetRoot()
    if not root then return WaterWaypoints["Camp 1 Water"], "Camp 1 Water" end
    local myPos = root.Position
    local closest, closestName, shortest = nil, nil, math.huge
    for name, cf in pairs(WaterWaypoints) do
        local dist = (myPos - cf.Position).Magnitude
        if dist < shortest then
            shortest = dist
            closest = cf
            closestName = name
        end
    end
    return closest, closestName
end

local function PerformSafeTeleport(targetCFrame, name, heightOverride, hoverOverride)
    local root = GetRoot()
    if not root then return end
    
    UpdateStatus("Teleporting to " .. name)
    local height = heightOverride or Config.SafeHeight
    local hover = hoverOverride or Config.HoverTime
    
    root.CFrame = targetCFrame + Vector3.new(0, height, 0)
    root.Anchored = true
    
    for i = hover, 1, -1 do
        if not root.Anchored then break end
        task.wait(1) 
    end
    
    if root then root.Anchored = false end
    UpdateStatus("Landed at " .. name)
end

local function PerformDrink()
    local char = LocalPlayer.Character
    if not char then return end
    
    UpdateStatus("Drinking...")
    local hasPass = CheckGamepass()
    local target = hasPass and Config.PassTarget or Config.NoPassTarget
    
    local bottle = char:FindFirstChild("Water Bottle")
    if not bottle then
        local bpBottle = LocalPlayer.Backpack:FindFirstChild("Water Bottle")
        if bpBottle then
            char.Humanoid:EquipTool(bpBottle)
            bottle = bpBottle
            task.wait(0.5)
        end
    end

    local timeout = 0
    repeat
        if not AutoExpeditionEnabled and not AutoTimerEnabled then break end
        if bottle and bottle:FindFirstChild("RemoteEvent") then
            bottle.RemoteEvent:FireServer()
        end
        task.wait(0.5)
        timeout = timeout + 1
    until GetHydration() >= target or GetBottleValue() <= 0 or timeout > 20
    
    UpdateStatus("Drinking Finished")
end

local function PerformRefill(returnLocationName)
    UpdateStatus("Refilling Water...")
    local waterCF, waterName = GetNearestWaterSource()
    local targetBackName = returnLocationName or GetCurrentSpawn()
    
    local targetBackCF
    if targetBackName == "TimerPoint" then
        targetBackCF = Config.TimerCoord
    else
        targetBackCF = ExpeditionWaypoints[targetBackName] or ExpeditionWaypoints["Base Camp"]
    end

    WindUI:Notify({Title="Survival", Content="Refilling at " .. waterName, Duration=3})

    PerformSafeTeleport(waterCF, waterName, Config.WaterHoverHeight, 5)

    local root = GetRoot()
    if root then root.Anchored = false end 
    task.wait(1) 
    ForceJump() 

    local timeout = 0
    repeat
        if not AutoExpeditionEnabled and not AutoTimerEnabled then break end
        UpdateStatus("Refilling... " .. GetBottleValue() .. "%")
        task.wait(1)
        timeout = timeout + 1
        if timeout % 3 == 0 then ForceJump() end 
    until GetBottleValue() >= Config.RefillTarget or timeout > 40

    UpdateStatus("Refill Done. Returning...")
    PerformSafeTeleport(targetBackCF, targetBackName, Config.SafeHeight, 5)
end

local function HandleVitals(currentLocationTarget)
    if IsBusy then return false end 
    
    if GetBottleValue() <= Config.RefillThreshold then
        IsBusy = true
        PerformRefill(currentLocationTarget)
        IsBusy = false
        return true 
    end
    
    local hasPass = CheckGamepass()
    local trigger = hasPass and Config.PassTrigger or Config.NoPassTrigger
    if GetHydration() <= trigger and GetBottleValue() > 0 then
        IsBusy = true
        PerformDrink()
        IsBusy = false
        return true 
    end
    
    return false 
end

local function SmartWait(seconds, locationContext, enableCheck)
    local elapsed = 0
    local checkEnabled = (enableCheck == nil and true) or enableCheck
    
    while elapsed < seconds do
        local isRunning = AutoExpeditionEnabled or AutoTimerEnabled
        if not isRunning then break end
        
        local actionTaken = false
        if checkEnabled then
            actionTaken = HandleVitals(locationContext)
        end
        
        if not actionTaken then
            task.wait(1)
            elapsed = elapsed + 1
        else
            UpdateStatus("Resuming wait (" .. (seconds - elapsed) .. "s left)")
        end
    end
end

local function StartExpedition()
    task.spawn(function()
        while AutoExpeditionEnabled do
            task.wait(0.5) 
            
            local currentLoc = GetCurrentSpawn()
            HandleVitals(currentLoc)
            
            if currentLoc == "South Pole" then
                UpdateStatus("Reached South Pole! Resetting...")
                WindUI:Notify({Title="Finish", Content="Expedition Complete! Resetting...", Duration=5})
                task.wait(3)
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    LocalPlayer.Character.Humanoid.Health = 0
                end
                repeat task.wait(1) until GetCurrentSpawn() == "Base Camp" or not AutoExpeditionEnabled
                task.wait(5)
                continue
            end
            
            local nextDestName = SequenceMap[currentLoc]
            if not nextDestName then
                UpdateStatus("Waiting logic... (" .. currentLoc .. ")")
                task.wait(1)
                continue
            end
            local targetCF = ExpeditionWaypoints[nextDestName]

            UpdateStatus("Resting (" .. Config.RestTime .. "s) -> " .. nextDestName)
            SmartWait(Config.RestTime, currentLoc) 
            if not AutoExpeditionEnabled then break end

            UpdateStatus("Preparing Teleport ("..Config.PreTeleportDelay.."s)...")
            SmartWait(Config.PreTeleportDelay, currentLoc)
            if not AutoExpeditionEnabled then break end

            HandleVitals(currentLoc) 
            
            PerformSafeTeleport(targetCF, nextDestName, Config.SafeHeight)
            if not AutoExpeditionEnabled then break end

            UpdateStatus("Triggering Checkpoint: " .. nextDestName)
            repeat
                if not AutoExpeditionEnabled then break end
                HandleVitals(nextDestName) 
                task.wait(Config.JumpInterval)
                ForceJump()
            until GetCurrentSpawn() == nextDestName
            
            if AutoExpeditionEnabled then
                WindUI:Notify({Title="Progress", Content="Saved: " .. nextDestName, Duration=3})
            end
        end
        
        UpdateStatus("Expedition Stopped")
        local root = GetRoot()
        if root then root.Anchored = false end
    end)
end

local function StartTimerExpedition()
    task.spawn(function()
        while AutoTimerEnabled do
            task.wait(1)

            if GetCurrentSpawn() == "South Pole" then
                UpdateStatus("Timer Done! Resetting...")
                WindUI:Notify({Title="Timer", Content="Run Complete! Resetting...", Duration=5})
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    LocalPlayer.Character.Humanoid.Health = 0
                end
                repeat task.wait(1) until GetCurrentSpawn() == "Base Camp" or not AutoTimerEnabled
                task.wait(5)
                continue
            end

            UpdateStatus("Going to Timer Point...")
            
            HandleVitals("Base Camp")
            
            PerformSafeTeleport(Config.TimerCoord, "Timer Point", Config.SafeHeight)
            
            if not AutoTimerEnabled then break end

            UpdateStatus("Waiting for Timer (5s)...")
            SmartWait(5, "TimerPoint") 

            if not AutoTimerEnabled then break end
            
            UpdateStatus("Teleporting to South Pole...")
            HandleVitals("TimerPoint")

            PerformSafeTeleport(ExpeditionWaypoints["South Pole"], "South Pole", Config.SafeHeight)
            
            if not AutoTimerEnabled then break end

            UpdateStatus("Triggering South Pole...")
            repeat
                if not AutoTimerEnabled then break end
                HandleVitals("South Pole")
                task.wait(Config.JumpInterval)
                ForceJump()
            until GetCurrentSpawn() == "South Pole"

            if AutoTimerEnabled then
                WindUI:Notify({Title="Success", Content="Expedition Complete!", Duration=3})
            end
        end
        UpdateStatus("Timer Stopped")
        local root = GetRoot()
        if root then root.Anchored = false end
    end)
end

local Window = WindUI:CreateWindow({
    Title = "Expedition Antarctica | MDVK",
    Folder = "MDVKExpeditionAntarctica",
    HideSearchBar = true,
    Topbar = { Height = 44, ButtonsType = "Default" },

    OpenButton = {
        Title = "MDVK",
        CornerRadius = UDim.new(0, 8),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 25)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 60, 60))
        })
    }
})

local MainTab = Window:Tab({ Title = "Expedition" })
local StatusLabel = MainTab:Paragraph({ Title = "Status", Desc = "Ready" })

task.spawn(function()
    while true do
        local hydration = math.floor(GetHydration())
        local bottle = GetBottleValue()
        StatusLabel:SetDesc(
            string.format("Location: %s\nMessages: %s\nHydration: %d%%\nBottle: %d", 
            GetCurrentSpawn(), CurrentStatus, hydration, bottle)
        )
        task.wait(0.5)
    end
end)

local SectionNormal = MainTab:Section({ Title = "Mode: Normal" })

SectionNormal:Toggle({
    Title = "Auto Expedition Normal",
    Callback = function(state)
        if state and AutoTimerEnabled then
            WindUI:Notify({Title="Warning", Content="Timer Mode disabled.", Duration=3})
        end

        AutoExpeditionEnabled = state
        if state then 
            StartExpedition() 
        else 
            CurrentStatus = "Stopping..." 
            IsBusy = false 
            local root = GetRoot()
            if root then root.Anchored = false end
        end
    end
})

local SectionTimer = MainTab:Section({ Title = "Mode: Timer" })

SectionTimer:Toggle({
    Title = "Auto Expedition Timer",
    Callback = function(state)
        if state and AutoExpeditionEnabled then
             WindUI:Notify({Title="Warning", Content="Normal Mode disabled internally.", Duration=3})
             AutoExpeditionEnabled = false
        end

        AutoTimerEnabled = state
        if state then
            StartTimerExpedition()
        else
            CurrentStatus = "Stopping Timer..."
            IsBusy = false
            local root = GetRoot()
            if root then root.Anchored = false end
        end
    end
})

local TpTab = Window:Tab({ Title = "Teleport" })
TpTab:Section({ Title="Teleport Area" })
for _, name in ipairs({"Camp 1", "Camp 2", "Camp 3", "Camp 4"}) do
    TpTab:Button({
        Title = name,
        Callback = function() PerformSafeTeleport(ExpeditionWaypoints[name], name, Config.SafeHeight) end
    })
end
TpTab:Button({
    Title = "South Pole",
    Color = Color3.fromRGB(255, 215, 0),
    Callback = function() PerformSafeTeleport(ExpeditionWaypoints["South Pole"], "South Pole", Config.SafeHeight) end
})
