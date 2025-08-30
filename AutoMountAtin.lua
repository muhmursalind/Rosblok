local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local PlaceId = game.PlaceId
local JobId = game.JobId

-- Path ke Stat, sesuaikan dengan GUI game-mu
local Stat = player:WaitForChild("PlayerGui"):WaitForChild("Altimeter"):WaitForChild("ImageLabel"):WaitForChild("Coin_Image"):WaitForChild("Coin_Amount")

local targetPosition = Vector3.new(781.18, 2165.92, 3921.32)

-- Queue script supaya otomatis reload saat teleport/rejoin
queue_on_teleport([[
    loadstring(game:HttpGet("https://raw.githubusercontent.com/muhmursalind/Rosblok/refs/heads/main/AutoMountAtin.lua"))()
]])

-- Fungsi teleport instan ke koordinat
local function instantTeleport()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(targetPosition)
end

-- Fungsi loop: teleport, tunggu 5 detik, lalu rejoin
local function loop()
    instantTeleport()
    wait(5)
    TeleportService:TeleportToPlaceInstance(PlaceId, JobId)
end

-- Mulai loop saat karakter siap
player.CharacterAdded:Connect(function()
    wait(1)
    loop()
end)

-- Jika karakter sudah ada saat script mulai, langsung jalankan loop
if player.Character then
    wait(1)
    loop()
end

-- Trigger rejoin saat Stat berubah
Stat.Changed:Connect(function()
    TeleportService:TeleportToPlaceInstance(PlaceId, JobId)
end)
