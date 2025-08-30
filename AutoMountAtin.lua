local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local JobId = game.JobId
local PlaceId = game.PlaceId

local targetPosition = Vector3.new(781.18, 2165.92, 3921.32)

local function Fire(obj)
    obj:FireServer()
end

local function instantTeleport()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(targetPosition)
end

local function teleportAndRejoin()
    instantTeleport()
    wait(5)
    TeleportService:TeleportToPlaceInstance(PlaceId, JobId)
end

player.CharacterAdded:Connect(function()
    wait(1)
    teleportAndRejoin()
end)

if player.Character then
    wait(1)
    teleportAndRejoin()
end

queue_on_teleport([[
    loadstring(game:HttpGet("https://raw.githubusercontent.com/muhmursalind/Rosblok/refs/heads/main/AutoMountAtin.lua"))()
]])

-- Fungsi cek semua TextLabel di PlayerGui apakah ada yang bertuliskan "checkpoint saved"
local function checkForCheckpoint()
    for _, guiObject in ipairs(player.PlayerGui:GetDescendants()) do
        if guiObject:IsA("TextLabel") then
            if guiObject.Text:lower() == "checkpoint saved" then
                TeleportService:TeleportToPlaceInstance(PlaceId, JobId)
                break
            end
        end
    end
end

-- Bisa dijalankan terus menerus dengan event ChildAdded agar realtime cek saat muncul label baru
player.PlayerGui.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("TextLabel") and descendant.Text:lower() == "checkpoint saved" then
        TeleportService:TeleportToPlaceInstance(PlaceId, JobId)
    end
end)
