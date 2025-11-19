local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local SellChoiceEvent = ReplicatedStorage:WaitForChild("SellChoiceEvent")
local DropMoneyRemote

local autoFishing, autoSell, autoDrop = false, false, false
local fishDelay, sellDelay, dropDelay = 0, 10, 3
local dropAmount = 1000000

local dropOptions, optionLabels = {}, {}
for i = 1, 10 do
	local label = i .. " Juta"
	dropOptions[label] = i * 1000000
	table.insert(optionLabels, label)
end

local function getMiniGame()
	local char = LP.Character or LP.CharacterAdded:Wait()
	local rod = char:FindFirstChild("NormalRod") or (LP.Backpack and LP.Backpack:FindFirstChild("NormalRod"))
	return rod and rod:FindFirstChild("MiniGame")
end

local Window = Rayfield:CreateWindow({Name = "Mini Auto"})
local Tab = Window:CreateTab("Main")

Tab:CreateToggle({Name = "Auto Fishing", CurrentValue = false, Callback = function(v) autoFishing = v end})
Tab:CreateSlider({Name = "Fishing Delay", Range = {0,10}, Increment = 1, CurrentValue = 0, Callback = function(v) fishDelay = v end})

Tab:CreateToggle({Name = "Auto Sell", CurrentValue = false, Callback = function(v) autoSell = v end})
Tab:CreateSlider({Name = "Sell Delay", Range = {5,10}, Increment = 1, CurrentValue = 10, Callback = function(v) sellDelay = v end})

Tab:CreateDropdown({
	Name = "Drop Amount",
	Options = optionLabels,
	CurrentOption = "1 Juta",
	Flag = "DropAmountSelect",
	Callback = function(sel)
		local amt, method = nil, type(sel)
		
		if method == "string" and dropOptions[sel] then
			amt = dropOptions[sel]
		elseif method == "number" then
			local label = optionLabels[sel] or optionLabels[sel + 1]
			amt = label and dropOptions[label]
		elseif method == "table" then
			amt = (sel.Option and dropOptions[sel.Option]) or tonumber(sel.Value) or (sel[1] and dropOptions[sel[1]])
		end
		
		if amt then
			dropAmount = amt
			Rayfield:Notify({Title = "Drop Amount", Content = amt / 1000000 .. " Juta", Duration = 2})
		else
			warn("Dropdown tidak dikenali:", sel, "Type:", method)
		end
	end
})

Tab:CreateButton({
	Name = "Drop Now",
	Callback = function()
		DropMoneyRemote = DropMoneyRemote or ReplicatedStorage:FindFirstChild("DropMoney")
		if DropMoneyRemote then
			local ok, err = pcall(function() DropMoneyRemote:FireServer(dropAmount) end)
			Rayfield:Notify({
				Title = ok and "Dropped!" or "Error",
				Content = ok and (dropAmount / 1000000 .. " Juta") or tostring(err),
				Duration = 2
			})
		else
			Rayfield:Notify({Title = "Error", Content = "DropMoney remote not found", Duration = 3})
		end
	end
})

Tab:CreateToggle({Name = "Auto Drop", CurrentValue = false, Callback = function(v) autoDrop = v end})
Tab:CreateSlider({Name = "Drop Delay (s)", Range = {0,3}, Increment = 1, CurrentValue = 3, Callback = function(v) dropDelay = v end})

local function loop(condition, action, delay)
	task.spawn(function()
		while true do
			if condition() then
				pcall(action)
				task.wait(delay())
			else
				task.wait(0.2)
			end
		end
	end)
end

loop(function() return autoFishing end, function()
	local mg = getMiniGame()
	if mg then mg:FireServer("Complete") end
end, function() return fishDelay end)

loop(function() return autoSell end, function()
	SellChoiceEvent:FireServer("Option1")
end, function() return sellDelay end)

loop(function() return autoDrop end, function()
	DropMoneyRemote = DropMoneyRemote or ReplicatedStorage:FindFirstChild("DropMoney")
	if DropMoneyRemote then DropMoneyRemote:FireServer(dropAmount) end
end, function() return dropDelay end)
