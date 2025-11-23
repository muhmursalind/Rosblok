local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local SellChoiceEvent = ReplicatedStorage:WaitForChild("SellChoiceEvent")
local DropMoneyRemote = ReplicatedStorage:WaitForChild("DropMoney")

local function getRod()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer.Backpack
    return (char and char:FindFirstChild("NormalRod")) or (backpack and backpack:FindFirstChild("NormalRod"))
end

local function getMiniGame()
    local rod = getRod()
    return rod and rod:FindFirstChild("MiniGame")
end

local function getRoot(char)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
end

local function getHumanoid()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
end

local State = {
    autoFish = false,
    fishConnection = nil,
    
    autoSell = false,
    sellDelay = 5,
    sellConnection = nil,
    
    autoDrop = false,
    dropAmount = 1_000_000,
    dropDelay = 3,
    dropConnection = nil,
    
    walkSpeed = 16,
    jumpPower = 50,
    speedConnection = nil,
    jumpConnection = nil,
    
    flying = false,
    flySpeed = 1,
    flyKeyDown = nil,
    flyKeyUp = nil,
}

local function disconnectConnection(name)
    if State[name] then
        State[name]:Disconnect()
        State[name] = nil
    end
end

local function cleanupAll()
    disconnectConnection("fishConnection")
    disconnectConnection("sellConnection")
    disconnectConnection("dropConnection")
    disconnectConnection("speedConnection")
    disconnectConnection("jumpConnection")
    disconnectConnection("flyKeyDown")
    disconnectConnection("flyKeyUp")
    State.flying = false
end

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "MDVKLuaX",
    LoadingTitle = "MDVKLuaX",
    LoadingSubtitle = "by NeuF",
    ConfigurationSaving = {Enabled = false},
    Discord = {Enabled = false},
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main", 4483362458)
local PlayerTab = Window:CreateTab("Player", 4483362458)

MainTab:CreateSection("Fishing")

MainTab:CreateToggle({
    Name = "Instant Auto Fish",
    CurrentValue = false,
    Callback = function(enabled)
        State.autoFish = enabled
        disconnectConnection("fishConnection")
        
        if enabled then
            local notified = false
            
            State.fishConnection = RunService.Heartbeat:Connect(function()
                local miniGame = getMiniGame()
                if miniGame then
                    for i = 1, 3 do
                        pcall(function() miniGame:FireServer("Complete") end)
                    end
                    notified = false
                elseif not notified then
                    notified = true
                    Rayfield:Notify({
                        Title = "Instant Fishing",
                        Content = "Mancing manual dulu sampai dapat ikan besar",
                        Duration = 6,
                    })
                end
            end)
            
            task.spawn(function()
                while State.autoFish do
                    local miniGame = getMiniGame()
                    if miniGame then
                        for i = 1, 5 do
                            pcall(function() miniGame:FireServer("Complete") end)
                        end
                    end
                    task.wait()
                end
            end)
        end
    end,
})

MainTab:CreateSection("Sell")

MainTab:CreateSlider({
    Name = "Delay Auto Sell (detik)",
    Range = {1, 30},
    Increment = 1,
    Suffix = "s",
    CurrentValue = State.sellDelay,
    Callback = function(value) State.sellDelay = value end,
})

MainTab:CreateToggle({
    Name = "Auto Sell",
    CurrentValue = false,
    Callback = function(enabled)
        State.autoSell = enabled
        disconnectConnection("sellConnection")
        
        if enabled then
            task.spawn(function()
                while State.autoSell do
                    pcall(function() SellChoiceEvent:FireServer("Option1") end)
                    task.wait(State.sellDelay)
                end
            end)
        end
    end,
})

MainTab:CreateSection("Drop Money")

local dropOptions = {
    ["1 Juta"] = 1_000_000, ["2 Juta"] = 2_000_000, ["3 Juta"] = 3_000_000,
    ["4 Juta"] = 4_000_000, ["5 Juta"] = 5_000_000, ["6 Juta"] = 6_000_000,
    ["7 Juta"] = 7_000_000, ["8 Juta"] = 8_000_000, ["9 Juta"] = 9_000_000,
    ["10 Juta"] = 10_000_000,
}

MainTab:CreateDropdown({
    Name = "Nominal Drop",
    Options = {"1 Juta","2 Juta","3 Juta","4 Juta","5 Juta","6 Juta","7 Juta","8 Juta","9 Juta","10 Juta"},
    CurrentOption = "1 Juta",
    Callback = function(opt)
        local key = type(opt) == "table" and opt[1] or opt
        State.dropAmount = dropOptions[key] or 1_000_000
    end,
})

MainTab:CreateSlider({
    Name = "Delay Auto Drop (detik)",
    Range = {0, 10},
    Increment = 1,
    Suffix = "s",
    CurrentValue = State.dropDelay,
    Callback = function(value) State.dropDelay = value end,
})

MainTab:CreateToggle({
    Name = "Auto Drop Money",
    CurrentValue = false,
    Callback = function(enabled)
        State.autoDrop = enabled
        disconnectConnection("dropConnection")
        
        if enabled then
            task.spawn(function()
                while State.autoDrop do
                    pcall(function() DropMoneyRemote:FireServer(State.dropAmount) end)
                    task.wait(State.dropDelay)
                end
            end)
        end
    end,
})

PlayerTab:CreateSection("Fly")

PlayerTab:CreateSlider({
    Name = "Fly Speed",
    Range = {1, 10},
    Increment = 1,
    Suffix = "x",
    CurrentValue = State.flySpeed,
    Callback = function(value) State.flySpeed = value end,
})

local function startFly()
    repeat task.wait() until LocalPlayer.Character and getRoot(LocalPlayer.Character) and getHumanoid()
    
    local root = getRoot(LocalPlayer.Character)
    local control = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
    local lastControl = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
    local speed = 0
    
    State.flying = true
    
    local bodyGyro = Instance.new('BodyGyro')
    bodyGyro.P = 9e4
    bodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.cframe = root.CFrame
    bodyGyro.Parent = root
    
    local bodyVelocity = Instance.new('BodyVelocity')
    bodyVelocity.velocity = Vector3.new(0, 0, 0)
    bodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVelocity.Parent = root
    
    State.flyKeyDown = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        local key = input.KeyCode.Name:lower()
        
        if key == 'w' then control.F = 1
        elseif key == 's' then control.B = -1
        elseif key == 'a' then control.L = -1
        elseif key == 'd' then control.R = 1
        elseif key == 'e' then control.Q = 1
        elseif key == 'q' then control.E = -1
        end
        
        pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Track end)
    end)
    
    State.flyKeyUp = UserInputService.InputEnded:Connect(function(input)
        local key = input.KeyCode.Name:lower()
        
        if key == 'w' then control.F = 0
        elseif key == 's' then control.B = 0
        elseif key == 'a' then control.L = 0
        elseif key == 'd' then control.R = 0
        elseif key == 'e' then control.Q = 0
        elseif key == 'q' then control.E = 0
        end
    end)
    
    task.spawn(function()
        repeat
            task.wait()
            
            speed = (control.F ~= 0 or control.B ~= 0 or control.L ~= 0 or control.R ~= 0 or control.Q ~= 0 or control.E ~= 0) and 50 or 0
            
            if speed > 0 then
                local cam = workspace.CurrentCamera.CoordinateFrame
                bodyVelocity.velocity = ((cam.lookVector * (control.F + control.B)) + 
                    ((cam * CFrame.new(control.L + control.R, (control.F + control.B + control.Q + control.E) * 0.2, 0).p) - cam.p)) * speed * State.flySpeed
                lastControl = {F = control.F, B = control.B, L = control.L, R = control.R}
            else
                bodyVelocity.velocity = Vector3.new(0, 0, 0)
            end
            
            bodyGyro.cframe = workspace.CurrentCamera.CoordinateFrame
        until not State.flying
        
        bodyGyro:Destroy()
        bodyVelocity:Destroy()
        pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
    end)
end

local function stopFly()
    State.flying = false
    disconnectConnection("flyKeyDown")
    disconnectConnection("flyKeyUp")
end

PlayerTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(enabled)
        if enabled then
            startFly()
            Rayfield:Notify({
                Title = "Fly Enabled",
                Content = "WASD: Move | Q: Down | E: Up",
                Duration = 4,
            })
        else
            stopFly()
        end
    end,
})

PlayerTab:CreateSection("Movement")

local function initializeMovement()
    State.speedConnection = RunService.Heartbeat:Connect(function()
        local humanoid = getHumanoid()
        if humanoid and humanoid.WalkSpeed ~= State.walkSpeed then
            humanoid.WalkSpeed = State.walkSpeed
        end
    end)
    
    State.jumpConnection = RunService.Heartbeat:Connect(function()
        local humanoid = getHumanoid()
        if humanoid and humanoid.JumpPower ~= State.jumpPower then
            humanoid.JumpPower = State.jumpPower
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.WalkSpeed = State.walkSpeed
        humanoid.JumpPower = State.jumpPower
    end
end)

task.spawn(initializeMovement)

PlayerTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 1,
    Suffix = " speed",
    CurrentValue = State.walkSpeed,
    Callback = function(value)
        State.walkSpeed = value
        local humanoid = getHumanoid()
        if humanoid then humanoid.WalkSpeed = value end
    end,
})

PlayerTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 200},
    Increment = 1,
    Suffix = " power",
    CurrentValue = State.jumpPower,
    Callback = function(value)
        State.jumpPower = value
        local humanoid = getHumanoid()
        if humanoid then humanoid.JumpPower = value end
    end,
})

PlayerTab:CreateButton({
    Name = "Reset to Default",
    Callback = function()
        State.walkSpeed = 16
        State.jumpPower = 50
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.WalkSpeed = State.walkSpeed
            humanoid.JumpPower = State.jumpPower
        end
        Rayfield:Notify({
            Title = "Reset",
            Content = "Speed & Jump reset ke default",
            Duration = 3,
        })
    end,
})

Players.PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        cleanupAll()
    end
end)
