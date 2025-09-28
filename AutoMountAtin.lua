local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer

local JobId = game.JobId
local PlaceId = game.PlaceId
local PrivateServerId = game.PrivateServerId
local IsPrivateServer = PrivateServerId and PrivateServerId ~= ""

local firstPosition = Vector3.new(625.46, 1801.57, 3433.30)
local secondPosition = Vector3.new(781.18, 2165.92, 3921.32)

local function teleportToPosition(position)
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(position)
end

local function hasFriendInServer()
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local success, isFriend = pcall(function()
                return player:IsFriendsWith(otherPlayer.UserId)
            end)

            if success and isFriend then
                return true
            end
        end
    end
    return false
end

local function teleportBack()
    if IsPrivateServer then
        if hasFriendInServer() then
            print("Rejoining private server with friend...")
            TeleportService:TeleportToPlaceInstance(PlaceId, JobId)
        else
            print("Rejoining current private server (no friend found)...")
            TeleportService:TeleportToPlaceInstance(PlaceId, JobId)
        end
    else
        print("Rejoining to a public server...")
        TeleportService:Teleport(PlaceId)
    end
end

local function teleportSequenceAndRejoin()
    teleportToPosition(firstPosition)
    wait(2)
    teleportToPosition(secondPosition)
    wait(5)
    teleportBack()
end

player.CharacterAdded:Connect(function()
    wait(1)
    teleportSequenceAndRejoin()
end)

if player.Character then
    wait(1)
    teleportSequenceAndRejoin()
end

queue_on_teleport([[ 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/muhmursalind/Rosblok/refs/heads/main/AutoMountAtin.lua"))()
]])

player.PlayerGui.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("TextLabel") and descendant.Text:lower() == "checkpoint saved" then
        teleportBack()
    end
end)
