local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPack = game:GetService("StarterPack")
local StarterPlayer = game:GetService("StarterPlayer")
local SoundService = game:GetService("SoundService")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Screengui = Instance.new("ScreenGui")
Screengui.Name = "Screengui"
Screengui.ResetOnSpawn = false
Screengui.Parent = playerGui

local text = Instance.new("TextLabel")
text.Name = "text"
text.Size = UDim2.new(1, 0, 0, 50)
text.Position = UDim2.new(0, 0, 0, 20)
text.BackgroundTransparency = 1
text.Text = "NOTE DUMPER BY @wifikaney - DUMPING GAME TO NOTE... (0.0s)"
text.TextColor3 = Color3.fromRGB(255, 255, 255)
text.TextStrokeTransparency = 0.5
text.TextSize = 22
text.Font = Enum.Font.GothamBold
text.Parent = Screengui

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
	if depth > 12 or obj == Screengui then return nil end
	
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
		elseif obj:IsA("LocalScript") or obj:IsA("Script") or obj:IsA("ModuleScript") then
			local sourceSuccess, source = pcall(function() return obj.Source end)
			if sourceSuccess and source and source ~= "" then
				t.Properties.Source = serializeValue(source)
			else
				t.Properties.Source = "\"-- [Empty or Restricted Script Source]\""
			end
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
				else
					table.insert(t.Children, {
						Name = child.Name or "Unknown",
						ClassName = child.ClassName or "Instance",
						Properties = {},
						Attributes = {},
						Children = {}
					})
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

task.spawn(function()
	local startTime = tick()
	local timerRunning = true

	task.spawn(function()
		while timerRunning do
			local elapsed = tick() - startTime
			text.Text = string.format("NOTE DUMPER BY @wifikaney - DUMPING GAME TO NOTE... (%.1fs)", elapsed)
			task.wait(0.1)
		end
	end)

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
		else
			allData[name] = {
				Name = name,
				ClassName = "Folder",
				Properties = {},
				Attributes = {},
				Children = {}
			}
		end
		task.wait()
	end

	local codeSuccess, resultText = pcall(function()
		local code = "local gameDumpNote = {\n"
		code = code .. "  GameInfo = " .. tableToString(allData.GameInfo, "  ") .. ",\n"
		for serviceName, data in pairs(allData) do
			if serviceName ~= "GameInfo" and data then
				code = code .. "  " .. serviceName .. " = " .. instanceTableToString(data, "  ") .. ",\n"
			end
		end
		code = code .. "}\nreturn gameDumpNote"
		return code
	end)

	timerRunning = false

	if codeSuccess and resultText then
		text.Text = "NOTE DUMPER BY @wifikaney - Copied to Clipboard & Saved to Workspace!"
		text.TextColor3 = Color3.fromRGB(0, 255, 100)
		
		pcall(function()
			setclipboard(resultText)
		end)

		pcall(function()
			if writefile then
				writefile("GameDumpNote.lua", resultText)
			end
		end)
	else
		text.Text = "NOTE DUMPER BY @wifikaney - Dump Failed!"
		text.TextColor3 = Color3.fromRGB(255, 50, 50)
	end

	task.delay(4, function()
		Screengui:Destroy()
	end)
end)
