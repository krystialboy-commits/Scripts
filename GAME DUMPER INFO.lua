local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPack = game:GetService("StarterPack")
local StarterPlayer = game:GetService("StarterPlayer")
local SoundService = game:GetService("SoundService")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdvancedDumperGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 380, 0, 280)
frame.Position = UDim2.new(0.5, -190, 0.5, -140)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui

local dragging, dragInput, dragStart, startPos
frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

frame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Advanced File & Clipboard Dumper"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 25)
statusLabel.Position = UDim2.new(0, 0, 0, 32)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
statusLabel.TextSize = 13
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.Parent = frame

local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(0.9, 0, 0, 100)
textBox.Position = UDim2.new(0.05, 0, 0, 65)
textBox.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
textBox.TextColor3 = Color3.fromRGB(150, 255, 150)
textBox.Text = "Ready to dump..."
textBox.TextSize, textBox.TextWrapped, textBox.ClearTextOnFocus = 11, true, false
textBox.Font = Enum.Font.Code
textBox.TextXAlignment, textBox.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
textBox.Parent = frame

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 6)
boxCorner.Parent = textBox

local button = Instance.new("TextButton")
button.Size = UDim2.new(0.9, 0, 0, 45)
button.Position = UDim2.new(0.05, 0, 0, 175)
button.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Text = "Dump Game & Save File"
button.TextSize = 15
button.Font = Enum.Font.GothamBold
button.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = button

local function getGameInfo()
	local info = {
		PlaceId = game.PlaceId,
		GameId = game.GameId,
		JobId = game.JobId,
		PlaceVersion = game.PlaceVersion,
		IsStudio = RunService:IsStudio(),
		CreatorId = 0,
		CreatorType = "",
		Name = "",
		Description = ""
	}
	pcall(function()
		local productInfo = MarketplaceService:GetProductInfo(game.PlaceId)
		if productInfo then
			info.Name = productInfo.Name or ""
			info.Description = productInfo.Description or ""
			if productInfo.Creator then
				info.CreatorId = productInfo.Creator.CreatorId or 0
				info.CreatorType = productInfo.Creator.CreatorType or ""
			end
		end
	end)
	return info
end

local function serializeValue(val)
	local t = typeof(val)
	if t == "string" then
		return "\"" .. val:gsub("\n", "\\n"):gsub("\"", "\\\"") .. "\""
	elseif t == "number" or t == "boolean" then
		return tostring(val)
	elseif t == "Vector3" then
		return "Vector3.new(" .. val.X .. ", " .. val.Y .. ", " .. val.Z .. ")"
	elseif t == "CFrame" then
		return "CFrame.new(" .. tostring(val) .. ")"
	elseif t == "Color3" then
		return "Color3.new(" .. val.R .. ", " .. val.G .. ", " .. val.B .. ")"
	elseif t == "UDim2" then
		return "UDim2.new(" .. val.X.Scale .. ", " .. val.X.Offset .. ", " .. val.Y.Scale .. ", " .. val.Y.Offset .. ")"
	end
	return nil
end

local function serialize(obj, depth)
	depth = depth or 0
	if depth > 12 or obj == screenGui then return nil end
	
	local success, name = pcall(function() return obj.Name end)
	local successClass, className = pcall(function() return obj.ClassName end)
	if not success or not successClass then return nil end

	local t = {
		Name = name,
		ClassName = className,
		Properties = {},
		Attributes = {},
		Children = {}
	}
	
	pcall(function()
		local attrs = obj:GetAttributes()
		if attrs then
			for k, v in pairs(attrs) do
				local sv = serializeValue(v)
				if sv then t.Attributes[k] = sv end
			end
		end
	end)

	pcall(function()
		if obj:IsA("BasePart") then
			t.Properties.Position = serializeValue(obj.Position)
			t.Properties.Size = serializeValue(obj.Size)
			t.Properties.Transparency = obj.Transparency
			t.Properties.Color = serializeValue(obj.Color)
			t.Properties.Material = tostring(obj.Material)
			t.Properties.Anchored = obj.Anchored
			t.Properties.CanCollide = obj.CanCollide
		elseif obj:IsA("Model") then
			local pivotSuccess, pivot = pcall(function() return obj:GetPivot() end)
			if pivotSuccess and pivot then
				t.Properties.WorldPivot = serializeValue(pivot)
			end
		elseif obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			t.Properties.Text = serializeValue(obj.Text)
			t.Properties.TextSize = obj.TextSize
			t.Properties.TextColor3 = serializeValue(obj.TextColor3)
			t.Properties.Size = serializeValue(obj.Size)
			t.Properties.Position = serializeValue(obj.Position)
		end
	end)

	local childrenSuccess, children = pcall(function()
		return obj:GetChildren()
	end)
	
	if childrenSuccess and children then
		for _, child in ipairs(children) do
			if child then
				local serializedChild = serialize(child, depth + 1)
				if serializedChild then
					table.insert(t.Children, serializedChild)
				end
			end
			if depth == 0 then
				task.wait() 
			end
		end
	end
	return t
end

local function tableToString(tbl, indent)
	indent = indent or ""
	local result = "{\n"
	for k, v in pairs(tbl) do
		local keyFormatted = type(k) == "string" and "[\"" .. k .. "\"]" or "[" .. tostring(k) .. "]"
		if type(v) == "table" then
			result = result .. indent .. "  " .. keyFormatted .. " = " .. tableToString(v, indent .. "  ") .. ",\n"
		elseif type(v) == "string" then
			result = result .. indent .. "  " .. keyFormatted .. " = \"" .. tostring(v) .. "\",\n"
		else
			result = result .. indent .. "  " .. keyFormatted .. " = " .. tostring(v) .. ",\n"
		end
	end
	result = result .. indent .. "}"
	return result
end

local function instanceTableToString(tbl, indent)
	indent = indent or ""
	local result = "{\n"
	result = result .. indent .. "  Name = \"" .. tostring(tbl.Name) .. "\",\n"
	result = result .. indent .. "  ClassName = \"" .. tostring(tbl.ClassName) .. "\",\n"
	
	result = result .. indent .. "  Properties = {\n"
	for k, v in pairs(tbl.Properties) do
		if v ~= nil then
			result = result .. indent .. "    [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
		end
	end
	result = result .. indent .. "  },\n"
	
	result = result .. indent .. "  Attributes = {\n"
	for k, v in pairs(tbl.Attributes) do
		if v ~= nil then
			result = result .. indent .. "    [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
		end
	end
	result = result .. indent .. "  },\n"
	
	result = result .. indent .. "  Children = {\n"
	for _, child in ipairs(tbl.Children) do
		result = result .. indent .. "    " .. instanceTableToString(child, indent .. "    ") .. ",\n"
	end
	result = result .. indent .. "  }\n"
	result = result .. indent .. "}"
	return result
end

button.MouseButton1Click:Connect(function()
	button.Enabled = false
	local startTime = tick()
	local timerRunning = true

	task.spawn(function()
		while timerRunning do
			local elapsed = tick() - startTime
			statusLabel.Text = string.format("DUMPING GAME TO NOTE... (%.1fs)", elapsed)
			task.wait(0.1)
		end
	end)

	task.spawn(function()
		local gameInfo = getGameInfo()
		local servicesToDump = {
			Workspace = Workspace,
			ReplicatedStorage = ReplicatedStorage,
			Lighting = Lighting,
			SoundService = SoundService,
			StarterGui = StarterGui,
			StarterPack = StarterPack,
			StarterPlayer = StarterPlayer,
			Teams = Teams,
			CoreGui = CoreGui
		}

		local allData = {}
		allData.GameInfo = gameInfo

		for name, service in pairs(servicesToDump) do
			local success, result = pcall(function()
				return serialize(service, 0)
			end)
			if success and result then
				allData[name] = result
			end
			task.wait()
		end

		local codeSuccess, resultText = pcall(function()
			local code = "local gameDumpNote = {\n"
			code = code .. "  GameInfo = " .. tableToString(allData.GameInfo, "  ") .. ",\n"
			for serviceName, data in pairs(allData) do
				if serviceName ~= "GameInfo" and data then
					code = code .. "  " .. serviceName + " = " .. instanceTableToString(data, "  ") .. ",\n" -- fixed concatenation
				end
			end
			code = code .. "}\nreturn gameDumpNote"
			return code
		end)

		timerRunning = false

		if codeSuccess and resultText then
			textBox.Text = resultText
			textBox:CaptureFocus()
			
			pcall(function()
				setclipboard(resultText)
			end)

			pcall(function()
				if writefile then
					writefile("GameDumpNote.lua", resultText)
				end
			end)

			statusLabel.Text = "Status: Copied to Clipboard & Saved to Workspace!"
			statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
			button.Text = "Copied to Clipboard!"
		else
			statusLabel.Text = "Status: Dump Failed!"
			statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
			button.Text = "Failed"
		end

		task.wait(3)
		button.Text = "Dump Game & Save File"
		button.Enabled = true
	end)
end)
