--[[ iFrame | UI framework I-Hub | fase 1: window holder ]]

local Players = game:GetService("Players")

local iFrame = {}

iFrame.VERSION = "0.1.1"
iFrame.RAW = "https://raw.githubusercontent.com/ihubreal/iHub/refs/heads/main/ui/iFrame.lua"

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

function iFrame.window(options)
	options = options or {}
	local title = options.name or "iFrame"
	local size = options.size or Vector2.new(560, 400)

	local gui = Instance.new("ScreenGui")
	gui.Name = title .. "_iFrame"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = getGuiParent()

	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = options.position or UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromOffset(size.X, size.Y)
	holder.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	holder.BorderSizePixel = 1
	holder.Parent = gui

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Size = UDim2.fromScale(1, 1)
	content.Parent = holder

	return {
		Gui = gui,
		Holder = holder,
		Content = content,
		Destroy = function(self)
			if self.Gui then
				self.Gui:Destroy()
			end
		end,
	}
end

return iFrame
