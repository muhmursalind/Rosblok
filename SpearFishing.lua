local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- --- SERVICES ---
local Services = {
    Players = game:GetService("Players"),
    Workspace = game:GetService("Workspace"),
    RunService = game:GetService("RunService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    TweenService = game:GetService("TweenService")
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera
local Remotes = Services.ReplicatedStorage:WaitForChild("Remotes")
local FireRE = Remotes:WaitForChild("FireRE")
local FishRE = Remotes:WaitForChild("FishRE")

-- --- CONFIG & STATE ---
local State = { 
    Target = nil, 
    ActiveTween = nil
}

local Config = {
    AutoCatch = false, 
    AutoBoss = false,   
    IsCharge = false, 
    
    -- SETTING KECEPATAN
    ChargeDelay = 0,    
    AttackDelay = 0.1, 
    InstantHit = true, 
    
    AutoTween = false, 
    TweenSpeed = 130, 
    TweenDistance = 15, 
    
    AimLock = false, 
    ScanRange = 25000, 
    
    AutoSellAll = false, 
    SellDelay = 60,
    
    NoAnimFire = false, 
    NoAnimHit = false,
    
    -- FILTER
    SelectedSea = "All", 
    Priority = "All", 
    MinWeight = 100 
}

-- --- UI SETUP ---
local Window = WindUI:CreateWindow({
    Title = "Spear Fishing Elite",
    Author = "MDVKLuaX",
    Size = UDim2.fromOffset(550, 480),
    Theme = "Dark",
    Transparent = true,
    Acrylic = true,
    Folder = "SpearFishingElite",
    OpenButton = {
        Title = "MDVKLuaX",
        CornerRadius = UDim.new(0, 12),
        StrokeThickness = 0,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Position = UDim2.new(0.01, 0, 0.8, 0),
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHex("#00c6ff")),
            ColorSequenceKeypoint.new(1, Color3.fromHex("#0072ff"))
        })
    }
})

local Tabs = {
    Main = Window:Tab({ Title = "Farming", Icon = "crosshair" }),
    Settings = Window:Tab({ Title = "Settings", Icon = "settings" }),
    Market = Window:Tab({ Title = "Market", Icon = "coins" })
}

-- --- HELPER FUNCTIONS ---

local function GetTool()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
end

local function StopAnimations()
    local Char = LocalPlayer.Character
    local Hum = Char and Char:FindFirstChild("Humanoid")
    if Hum then
        for _, track in ipairs(Hum:GetPlayingAnimationTracks()) do
            track:Stop()
        end
    end
end

local function StopTween()
    if State.ActiveTween then
        State.ActiveTween:Cancel()
        State.ActiveTween = nil
    end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.zero
        LocalPlayer.Character.HumanoidRootPart.RotVelocity = Vector3.zero
    end
end

local function MoveTo(targetPos)
    local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not Root then return end

    local Distance = (targetPos - Root.Position).Magnitude
    local Time = Distance / Config.TweenSpeed
    local Tween = Services.TweenService:Create(Root, TweenInfo.new(Time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos)})
    
    State.ActiveTween = Tween
    Tween:Play()
    
    for _, part in ipairs(LocalPlayer.Character:GetChildren()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
end

-- === SYSTEM VALIDASI TARGET ===
local function IsTargetValid(Target)
    -- 1. Cek Fisik Dasar
    if not Target or not Target.Parent then return false end
    if not Target:IsDescendantOf(Services.Workspace) then return false end
    
    -- 2. Cek HP Boss (Khusus jika target adalah Boss)
    -- Kita cek apakah target ini punya atribut CurHP, atau Parentnya (Point) punya
    local HP = Target:GetAttribute("CurHP")
    if not HP and Target.Parent then HP = Target.Parent:GetAttribute("CurHP") end
    
    -- Jika HP ada dan 0, berarti mati
    if HP and HP <= 0 then return false end
    
    return true
end

local function GetTargetBoss()
    local WorldBoss = Services.Workspace:FindFirstChild("WorldBoss")
    if not WorldBoss then return nil end

    -- Loop setiap titik spawn (Point) didalam folder WorldBoss
    for _, point in ipairs(WorldBoss:GetChildren()) do
        if point then
            -- KITA CARI ANAK DARI POINT INI (BOSS ADA DI DALAMNYA)
            for _, child in ipairs(point:GetChildren()) do
                -- Filter: Kita hanya ambil jika itu Model atau Part (Bukan script/attachment)
                if child:IsA("Model") or child:IsA("BasePart") then
                    
                    -- Cek HP untuk memastikan Boss masih hidup
                    -- Prioritas: Cek attribute di Boss dulu, baru di Point
                    local HP = child:GetAttribute("CurHP")
                    if not HP then HP = point:GetAttribute("CurHP") end
                    
                    -- Validasi Akhir:
                    -- 1. Jika ada HP dan HP > 0, maka ini targetnya.
                    -- 2. Jika tidak ada attribute HP sama sekali tapi objectnya ada, kita anggap itu Boss (Fallback).
                    if (HP and HP > 0) or (not HP) then
                        return child
                    end
                end
            end
        end
    end
    return nil
end

local function GetTargetFish()
    local Success, Result = pcall(function()
        local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local WorldSea = Services.Workspace:FindFirstChild("WorldSea")
        if not Root or not WorldSea then return nil end

        local Candidates = { Closest = nil, Mutation = nil, Big = nil }
        local Distances = { Closest = Config.ScanRange, Mutation = Config.ScanRange, Big = Config.ScanRange }

        local FoldersToScan = {}
        if Config.SelectedSea == "All" then
            FoldersToScan = WorldSea:GetChildren()
        else
            local SpecificSea = WorldSea:FindFirstChild(Config.SelectedSea)
            if SpecificSea then table.insert(FoldersToScan, SpecificSea) end
        end

        for _, sea in ipairs(FoldersToScan) do
            if sea and sea:IsA("Instance") then
                for _, fish in ipairs(sea:GetChildren()) do
                    local IsFish = fish:GetAttribute("Weight") or fish:GetAttribute("CurHP") or string.find(fish.Name, "Fish")
                    
                    if fish and fish.Parent and IsFish then
                        
                        local IsPosOk, FishPos = pcall(function()
                            if fish:IsA("BasePart") then return fish.Position
                            elseif fish:IsA("Model") then return fish:GetPivot().Position
                            end
                            return nil
                        end)

                        if IsPosOk and FishPos then
                            local Dist = (FishPos - Root.Position).Magnitude
                            
                            if Dist < Config.ScanRange then
                                if Dist < Distances.Closest then
                                    Distances.Closest = Dist
                                    Candidates.Closest = fish
                                end

                                local Mutation = fish:GetAttribute("Mutation")
                                local Weight = tonumber(fish:GetAttribute("Weight")) or 0

                                if Mutation and Mutation ~= "None" and Mutation ~= "" then
                                    if Dist < Distances.Mutation then
                                        Distances.Mutation = Dist
                                        Candidates.Mutation = fish
                                    end
                                end

                                if Weight >= Config.MinWeight then
                                    if Dist < Distances.Big then
                                        Distances.Big = Dist
                                        Candidates.Big = fish
                                    end
                                end
                            end 
                        end 
                    end 
                end 
            end 
        end 

        if Config.Priority == "All" then
            if Candidates.Mutation then return Candidates.Mutation end
            if Candidates.Big then return Candidates.Big end
            return Candidates.Closest
        elseif Config.Priority == "Mutation Only" then
            return Candidates.Mutation
        elseif Config.Priority == "Big Weight" then
            return Candidates.Big
        else 
            return Candidates.Closest
        end
    end)

    if Success then return Result else return nil end
end

local function SellFish(manual)
    local uids = {}
    pcall(function()
        local FishData = LocalPlayer.PlayerGui.Data.Fish
        for _, item in ipairs(FishData:GetChildren()) do
            local uid = item:GetAttribute("UID") or item.Value or (tonumber(item.Name) and item.Name)
            if uid and not item:GetAttribute("Lock") then
                table.insert(uids, tostring(uid))
            end
        end
    end)
    if #uids > 0 then
        FishRE:FireServer("SellAll", { UIDs = uids })
        if manual then WindUI:Notify({ Title = "Sold!", Content = #uids.." Items sold.", Duration = 2 }) end
    elseif manual then
        WindUI:Notify({ Title = "Empty", Content = "Nothing to sell.", Duration = 2 })
    end
end

-- --- UI SECTIONS ---

local AutoTab = Tabs.Main:Section({ Title = "Automation", Icon = "zap" })

AutoTab:Toggle({
    Title = "Auto Catch", Desc = "Enable Farming Loop", Value = false,
    Callback = function(v)
        Config.AutoCatch = v
        if not v then 
            StopTween() 
            State.Target = nil 
        else
            WindUI:Notify({Title="Started", Content="Scanning...", Duration=2})
        end
    end
})

AutoTab:Toggle({
    Title = "Auto Farm Boss", 
    Desc = "IMMEDIATELY switch to Boss", 
    Value = false,
    Callback = function(v)
        Config.AutoBoss = v
        -- Tidak perlu reset target, loop utama akan mengurusnya
    end
})

AutoTab:Dropdown({
    Title = "Priority Filter",
    Values = {"All", "Closest", "Mutation Only", "Big Weight"},
    Default = "All",
    Callback = function(v) Config.Priority = v; State.Target = nil end
})

AutoTab:Dropdown({
    Title = "Area Selection",
    Values = {"All", "Sea1", "Sea2", "Sea3", "Sea4", "Sea5"},
    Default = "All",
    Callback = function(v) Config.SelectedSea = v; State.Target = nil end
})

local MoveTab = Tabs.Main:Section({ Title = "Movement", Icon = "wind" })
MoveTab:Toggle({
    Title = "Auto Tween", Desc = "Fly to fish", Value = false,
    Callback = function(v) Config.AutoTween = v; if not v then StopTween() end end
})
MoveTab:Slider({
    Title = "Speed", Value = {Min=50, Max=350, Default=130},
    Callback = function(v) Config.TweenSpeed = tonumber(v) end 
})
MoveTab:Slider({
    Title = "Stop Distance", Value = {Min=0, Max=50, Default=15},
    Callback = function(v) Config.TweenDistance = tonumber(v) end 
})

local CombatTab = Tabs.Settings:Section({ Title = "Combat", Icon = "sword" })

CombatTab:Toggle({ Title = "Charge Attack", Value = false, Callback = function(v) Config.IsCharge = v end })
CombatTab:Toggle({ 
    Title = "Instant Hit", 
    Desc = "Fast Kill (No travel time)", 
    Value = true, 
    Callback = function(v) Config.InstantHit = v end 
})

CombatTab:Slider({ 
    Title = "Attack Delay", 
    Value = {Min=0.01, Max=1, Default=0.1}, 
    Step=0.01, 
    Callback = function(v) Config.AttackDelay = tonumber(v) or 0.1 end 
})

CombatTab:Slider({ 
    Title = "Charge Time", 
    Value = {Min=0, Max=2, Default=0}, Step=0.1, 
    Callback = function(v) Config.ChargeDelay = tonumber(v) or 0 end 
})

CombatTab:Toggle({ Title = "No Anim (Fire)", Value = false, Callback = function(v) Config.NoAnimFire = v end })
CombatTab:Toggle({ Title = "No Anim (Hit)", Value = false, Callback = function(v) Config.NoAnimHit = v end })

local MarketTab = Tabs.Market:Section({ Title = "Selling", Icon = "tag" })
MarketTab:Toggle({ Title = "Auto Sell", Value = false, Callback = function(v) Config.AutoSellAll = v end })
MarketTab:Slider({
    Title = "Sell Interval",
    Value = {Min = 5, Max = 300, Default = 60},
    Step = 5,
    Callback = function(v) Config.SellDelay = tonumber(v) or 60 end
})
MarketTab:Button({ Title = "Sell All Now", Callback = function() SellFish(true) end })

-- --- MAIN LOGIC LOOP ---

Services.RunService.RenderStepped:Connect(function()
    if Config.AutoCatch and Config.AimLock and State.Target and State.Target.Parent then
        local TargetPos = nil
        pcall(function()
            if State.Target:IsA("BasePart") then TargetPos = State.Target.Position
            elseif State.Target:IsA("Model") then TargetPos = State.Target:GetPivot().Position end
        end)
        if TargetPos then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, TargetPos)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(tonumber(Config.AttackDelay) or 0.1) 
        
        if Config.AutoCatch then
            local Tool = GetTool()
            
            -- [LANGKAH 1]: Cek Boss (BOSS OVERRIDE)
            -- Jika fitur Boss nyala, kita cek setiap frame.
            -- Jika Boss ditemukan, kita PAKSA ganti target ke Boss, 
            -- tidak peduli kita sedang menargetkan ikan apa.
            if Config.AutoBoss then
                local ActiveBoss = GetTargetBoss()
                if ActiveBoss then
                    if State.Target ~= ActiveBoss then
                        State.Target = ActiveBoss
                        -- WindUI:Notify({Title="BOSS!", Content="Target switched to Boss", Duration=2})
                    end
                end
            end

            -- [LANGKAH 2]: Validasi Target Sekarang
            -- Jika target sudah mati atau hilang, hapus dari memori
            if State.Target and not IsTargetValid(State.Target) then
                State.Target = nil 
            end
            
            -- [LANGKAH 3]: Cari Ikan (Hanya jika tidak ada Target/Boss)
            if not State.Target then
                State.Target = GetTargetFish()
                
                -- Matikan Tween jika idle
                if not State.Target and Config.AutoTween then 
                    StopTween() 
                end
            end
            
            local Target = State.Target

            -- [LANGKAH 4]: Eksekusi Serangan
            if Tool and Target and Target.Parent then
                local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local Success, FishPos = pcall(function()
                    if Target:IsA("BasePart") then return Target.Position
                    elseif Target:IsA("Model") then return Target:GetPivot().Position end
                end)
                
                if Success and FishPos and MyRoot then
                    local Dist = (FishPos - MyRoot.Position).Magnitude
                    
                    if Config.AutoTween then
                        if Dist > tonumber(Config.TweenDistance) then
                            MoveTo(FishPos + Vector3.new(0, 10, 0)) 
                        else
                            StopTween()
                        end
                    end
                    
                    local ShootRange = (tonumber(Config.TweenDistance) or 15) + 45
                    local CanShoot = (not Config.AutoTween) or (Dist <= ShootRange)
                    
                    if CanShoot then
                        local CamPos = Camera.CFrame.Position
                        
                        -- CHARGE
                        if Config.IsCharge then
                            FireRE:FireServer("ChargeStart", { toolInstance = Tool })
                            FireRE:FireServer("Star", { toolInstance = Tool })
                            local cDelay = tonumber(Config.ChargeDelay) or 0
                            if cDelay > 0 then task.wait(cDelay) end
                        end
                        
                        -- FIRE
                        FireRE:FireServer("Fire", { 
                            cameraOrigin = CamPos, 
                            player = LocalPlayer, 
                            toolInstance = Tool, 
                            destination = FishPos, 
                            isCharge = Config.IsCharge 
                        })
                        if Config.NoAnimFire then StopAnimations() end
                        
                        -- DELAY
                        if not Config.InstantHit then
                            task.wait(0.05) 
                        else
                            task.wait() 
                        end
                        
                        -- HIT
                        if Target and Target.Parent then
                            FireRE:FireServer("Hit", { 
                                fishInstance = Target, 
                                HitPos = FishPos, 
                                toolInstance = Tool 
                            })
                            if Config.NoAnimHit then StopAnimations() end
                        end
                        
                        -- Target TIDAK di-reset disini agar tetap nembak target yang sama sampai mati
                        -- atau sampai Boss Override mengambil alih.
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(tonumber(Config.SellDelay) or 60)
        if Config.AutoSellAll then SellFish(false) end
    end
end)

WindUI:Notify({ Title = "Target System", Content = "Boss Priority + Override Active.", Icon = "target", Duration = 3 })
