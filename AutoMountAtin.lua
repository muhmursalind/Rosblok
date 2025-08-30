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

queue_on_teleport([[
    loadstring(game:HttpGet("https://raw.githubusercontent.com/muhmursalind/Rosblok/refs/heads/main/AutoMountAtin.lua"))()
]])

local function teleportAndRejoin()
    instantTeleport()
    wait(5)
    TeleportService:TeleportToPlaceInstance(PlaceId, JobId)
end

-- Jalankan loop saat karakter spawn
player.CharacterAdded:Connect(function()
    wait(1)
    teleportAndRejoin()
end)

-- Jika karakter sudah ada saat script mulai, jalankan loop sekali
if player.Character then
    wait(1)
    teleportAndRejoin()
end
TeleportService:TeleportToPlaceInstance(PlaceId, JobId)
