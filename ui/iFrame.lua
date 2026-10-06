--[[ iFrame | UI framework I-Hub | fase 1: window holder ]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local iFrame = {}

iFrame.VERSION = "0.1.3"
iFrame.RAW = "https://raw.githubusercontent.com/ihubreal/iHub/refs/heads/main/ui/iFrame.lua"

local WINDOW_SIZE = Vector2.new(560, 400)
local WINDOW_POSITION = UDim2.fromScale(0.5, 0.5)

local function getGuiParent()
	if typeof(gethui) == "function" then
		local hui = gethui()
		if hui then
			return hui
		end
	end
	local player = Players.LocalPlayer
	if not player then
		player = Players.PlayerAdded:Wait()
	end
	return player:WaitForChild("PlayerGui")
end

local function bindWindowDrag(holder: Frame)
	holder.Active = true
	local dragging = false
	local dragStart: Vector2? = nil
	local startPos: UDim2? = nil

	local function isDragInput(input: InputObject)
		return input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
	end

	local began = holder.InputBegan:Connect(function(input)
		if not isDragInput(input) then
			return
		end
		dragging = true
		dragStart = input.Position
		startPos = holder.Position
	end)

	local changed = UserInputService.InputChanged:Connect(function(input)
		if not dragging or not dragStart or not startPos then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local delta = input.Position - dragStart
		holder.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end)

	local ended = UserInputService.InputEnded:Connect(function(input)
		if isDragInput(input) then
			dragging = false
			dragStart = nil
			startPos = nil
		end
	end)

	return { began, changed, ended }
end

function iFrame.window(options)
	options = options or {}
	local title = options.name or "iFrame"

	local gui = Instance.new("ScreenGui")
	gui.Name = title .. "_iFrame"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = getGuiParent()

	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = WINDOW_POSITION
	holder.Size = UDim2.fromOffset(WINDOW_SIZE.X, WINDOW_SIZE.Y)
	holder.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	holder.BorderSizePixel = 1
	holder.Parent = gui

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Size = UDim2.fromScale(1, 1)
	content.Parent = holder

	local dragConnections = bindWindowDrag(holder)

	return {
		Gui = gui,
		Holder = holder,
		Content = content,
		Destroy = function(self)
			for _, conn in dragConnections do
				conn:Disconnect()
			end
			if self.Gui then
				self.Gui:Destroy()
			end
		end,
	}
end

return iFrame
