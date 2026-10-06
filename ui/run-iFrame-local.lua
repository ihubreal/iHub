--[[
	Copia pegada de ui/iFrame.lua para probar en local (un solo archivo, sin HttpGet/readfile).
	Sincroniza manualmente cuando cambies iFrame.lua.
]]
--[[ iFrame | UI framework I-Hub ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local iFrame = {}

-- Anotacion para el analizador (valor real: Enum.KeyCode en runtime).
type KeyCode = any

iFrame.VERSION = "0.4.2"
iFrame.RAW = "https://raw.githubusercontent.com/ihubreal/iHub/refs/heads/main/ui/iFrame.lua"

local WINDOW_SIZE = Vector2.new(660, 400)
local WINDOW_POSITION = UDim2.fromScale(0.5, 0.5)
local DRAG_SMOOTH_SPEED = 22
local HEADER_HEIGHT = 40
local SIDEBAR_WIDTH = 168
local SIDEBAR_PROFILE_H = 86
local WINDOW_CORNER_RADIUS = 12
local SPLASH_CORNER_RADIUS = 6
local SPLASH_SIZE = Vector2.new(156, 80)
local SPLASH_BRAND = "eyeLib"
local SPLASH_SUB = "(iLib)"
local INTRO_HOLD = 0.55
local INTRO_EXPAND_DURATION = 0.42
local INTRO_SPIN_SPEED = 380

local ROW_GAP = 8
local _SECTION_GAP = 14
local CONTROL_H = 34
local CONTROL_RADIUS = 10
local CONTENT_PAD = 12

local Theme = {
	Glass = Color3.fromRGB(28, 27, 25),
	GlassTrans = 0.2,
	Header = Color3.fromRGB(28, 27, 25),
	Sidebar = Color3.fromRGB(28, 27, 25),
	Content = Color3.fromRGB(28, 27, 25),
	PanelTrans = 0.5,
	Control = Color3.fromRGB(42, 41, 39),
	ControlTrans = 0.1,
	ControlHover = Color3.fromRGB(52, 50, 47),
	ControlActive = Color3.fromRGB(91, 106, 90),
	Divider = Color3.fromRGB(55, 52, 48),
	Border = Color3.fromRGB(241, 237, 228),
	BorderTrans = 0.82,
	Title = Color3.fromRGB(241, 237, 228),
	Text = Color3.fromRGB(241, 237, 228),
	Muted = Color3.fromRGB(132, 126, 118),
	Accent = Color3.fromRGB(91, 106, 90),
	Knob = Color3.fromRGB(241, 237, 228),
	Track = Color3.fromRGB(36, 35, 33),
}

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

local function applyCorner(guiObject: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = guiObject
	return corner
end

local function setCornerRadius(corner: UICorner, radius: number)
	corner.CornerRadius = UDim.new(0, radius)
end

local function styleGlass(gui: GuiObject, color: Color3?, transparency: number?)
	if not gui:IsA("GuiObject") then
		return
	end
	gui.BackgroundColor3 = color or Theme.Glass
	gui.BackgroundTransparency = transparency or Theme.GlassTrans
end

local function applyGlassShell(gui: Frame, radius: number)
	styleGlass(gui, Theme.Glass, Theme.GlassTrans)
	applyCorner(gui, radius)

	local stroke = Instance.new("UIStroke")
	stroke.Name = "GlassStroke"
	stroke.Color = Theme.Border
	stroke.Transparency = Theme.BorderTrans
	stroke.Thickness = 1
	stroke.Parent = gui
end

local function applyFrostBackdrop(parent: Frame, radius: number)
	local frost = Instance.new("Frame")
	frost.Name = "Frost"
	frost.Size = UDim2.fromScale(1, 1)
	frost.BackgroundColor3 = Color3.fromRGB(36, 34, 32)
	frost.BackgroundTransparency = 0.18
	frost.BorderSizePixel = 0
	frost.ZIndex = 0
	frost.Parent = parent
	applyCorner(frost, radius)

	local haze = Instance.new("Frame")
	haze.Name = "Haze"
	haze.Size = UDim2.fromScale(1, 1)
	haze.BackgroundColor3 = Color3.fromRGB(241, 237, 228)
	haze.BackgroundTransparency = 0.93
	haze.BorderSizePixel = 0
	haze.ZIndex = 1
	haze.Parent = frost

	local hazeGrad = Instance.new("UIGradient")
	hazeGrad.Rotation = 105
	hazeGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.55, 0.62),
		NumberSequenceKeypoint.new(1, 0.4),
	})
	hazeGrad.Parent = haze
end

local function styleControl(gui: GuiObject)
	styleGlass(gui, Theme.Control, Theme.ControlTrans)
end

local function bindWindowDrag(dragTarget: Frame, holder: Frame)
	dragTarget.Active = true
	local dragging = false
	local dragMouseStart: Vector2? = nil
	local dragPosStart: UDim2? = nil
	local targetPos = holder.Position

	local function isDragInput(input: InputObject)
		return input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
	end

	local function mousePosition()
		return UserInputService:GetMouseLocation()
	end

	local began = dragTarget.InputBegan:Connect(function(input)
		if not isDragInput(input) then
			return
		end
		dragging = true
		dragMouseStart = mousePosition()
		dragPosStart = holder.Position
		targetPos = holder.Position
	end)

	local function snapPosition(pos: UDim2)
		return UDim2.new(
			pos.X.Scale,
			math.floor(pos.X.Offset + 0.5),
			pos.Y.Scale,
			math.floor(pos.Y.Offset + 0.5)
		)
	end

	local stepped = RunService.RenderStepped:Connect(function(dt)
		if not dragging then
			return
		end
		if not dragMouseStart or not dragPosStart then
			return
		end

		local delta = mousePosition() - dragMouseStart
		targetPos = UDim2.new(
			dragPosStart.X.Scale,
			dragPosStart.X.Offset + delta.X,
			dragPosStart.Y.Scale,
			dragPosStart.Y.Offset + delta.Y
		)

		local current = holder.Position
		local alpha = 1 - math.exp(-DRAG_SMOOTH_SPEED * dt)
		local nextX = current.X.Offset + (targetPos.X.Offset - current.X.Offset) * alpha
		local nextY = current.Y.Offset + (targetPos.Y.Offset - current.Y.Offset) * alpha
		if math.abs(targetPos.X.Offset - nextX) < 0.5 and math.abs(targetPos.Y.Offset - nextY) < 0.5 then
			holder.Position = snapPosition(targetPos)
			return
		end
		holder.Position = UDim2.new(targetPos.X.Scale, nextX, targetPos.Y.Scale, nextY)
	end)

	local ended = UserInputService.InputEnded:Connect(function(input)
		if isDragInput(input) then
			dragging = false
			dragMouseStart = nil
			dragPosStart = nil
			holder.Position = snapPosition(targetPos)
		end
	end)

	return { began, stepped, ended }
end

local function introStep(dt: number)
	if typeof(dt) == "number" and dt > 0 then
		return dt
	end
	return 1 / 60
end

local function introEaseOut(t: number)
	return 1 - (1 - t) ^ 3
end

local function playWindowIntro(
	holder: Frame,
	clipRoot: Frame,
	splash: Frame,
	header: Frame,
	body: Frame,
	holderCorner: UICorner,
	clipCorner: UICorner,
	onComplete: () -> ()
)
	header.Visible = false
	body.Visible = false
	splash.Visible = true
	splash.BackgroundTransparency = 0

	holder.Size = UDim2.fromOffset(SPLASH_SIZE.X, SPLASH_SIZE.Y)
	setCornerRadius(holderCorner, SPLASH_CORNER_RADIUS)
	setCornerRadius(clipCorner, SPLASH_CORNER_RADIUS)

	local spinner = splash:FindFirstChild("Spinner") :: Frame?
	local splashCorner = splash:FindFirstChildOfClass("UICorner")
	local holdElapsed = 0
	local expandElapsed = 0
	local phase = "hold"
	local introDone = false
	local conn: RBXScriptConnection

	local function applyRadius(radius: number)
		setCornerRadius(holderCorner, radius)
		setCornerRadius(clipCorner, radius)
		if splashCorner then
			setCornerRadius(splashCorner, radius)
		end
	end

	local function finishIntro()
		if introDone then
			return
		end
		introDone = true
		holder.Size = UDim2.fromOffset(WINDOW_SIZE.X, WINDOW_SIZE.Y)
		applyRadius(WINDOW_CORNER_RADIUS)
		splash.Visible = false
		header.Visible = true
		body.Visible = true
		conn:Disconnect()
		onComplete()
	end

	conn = RunService.RenderStepped:Connect(function(dt)
		if introDone then
			return
		end

		local step = introStep(dt)

		if spinner then
			spinner.Rotation = (spinner.Rotation + INTRO_SPIN_SPEED * step) % 360
		end

		if phase == "hold" then
			holdElapsed = holdElapsed + step
			if holdElapsed >= INTRO_HOLD then
				phase = "expand"
				expandElapsed = 0
			end
			return
		end

		expandElapsed = expandElapsed + step
		local t = math.clamp(expandElapsed / INTRO_EXPAND_DURATION, 0, 1)
		local eased = introEaseOut(t)
		local w = SPLASH_SIZE.X + (WINDOW_SIZE.X - SPLASH_SIZE.X) * eased
		local h = SPLASH_SIZE.Y + (WINDOW_SIZE.Y - SPLASH_SIZE.Y) * eased
		holder.Size = UDim2.fromOffset(w, h)
		local radius = SPLASH_CORNER_RADIUS + (WINDOW_CORNER_RADIUS - SPLASH_CORNER_RADIUS) * eased
		applyRadius(radius)
		splash.BackgroundTransparency = t * 0.45

		if t >= 0.82 then
			splash.Visible = false
			header.Visible = true
			body.Visible = true
		end

		if t >= 1 then
			finishIntro()
		end
	end)

	return conn
end

-- --- component helpers ---

local function newListParent(scrolling: ScrollingFrame)
	local list = Instance.new("Frame")
	list.Name = "List"
	list.BackgroundTransparency = 1
	list.Size = UDim2.new(1, 0, 0, 0)
	list.AutomaticSize = Enum.AutomaticSize.Y
	list.Parent = scrolling

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, ROW_GAP)
	layout.Parent = list

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, CONTENT_PAD)
	pad.PaddingBottom = UDim.new(0, CONTENT_PAD)
	pad.PaddingLeft = UDim.new(0, CONTENT_PAD)
	pad.PaddingRight = UDim.new(0, CONTENT_PAD)
	pad.Parent = list

	scrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrolling.CanvasSize = UDim2.fromOffset(0, 0)

	return list
end

local function addSection(list: Frame, title: string)
	local wrap = Instance.new("Frame")
	wrap.Name = "Section"
	wrap.BackgroundTransparency = 1
	wrap.Size = UDim2.new(1, 0, 0, 0)
	wrap.AutomaticSize = Enum.AutomaticSize.Y
	wrap.LayoutOrder = #list:GetChildren()
	wrap.Parent = list

	local inner = Instance.new("UIListLayout")
	inner.SortOrder = Enum.SortOrder.LayoutOrder
	inner.Padding = UDim.new(0, ROW_GAP)
	inner.Parent = wrap

	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 18)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Theme.Muted
	label.Text = string.upper(title)
	label.LayoutOrder = 1
	label.Parent = wrap

	local items = Instance.new("Frame")
	items.Name = "Items"
	items.BackgroundTransparency = 1
	items.Size = UDim2.new(1, 0, 0, 0)
	items.AutomaticSize = Enum.AutomaticSize.Y
	items.LayoutOrder = 2
	items.Parent = wrap

	local itemsLayout = Instance.new("UIListLayout")
	itemsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	itemsLayout.Padding = UDim.new(0, ROW_GAP)
	itemsLayout.Parent = items

	return items
end

local function addText(list: Frame, text: string)
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextColor3 = Theme.Text
	label.Text = text
	label.Parent = list
	return label
end

local function addButton(list: Frame, name: string, callback: (() -> ())?)
	local btn = Instance.new("TextButton")
	btn.Name = "Button"
	btn.Size = UDim2.new(1, 0, 0, CONTROL_H)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	styleControl(btn)
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 14
	btn.TextColor3 = Theme.Title
	btn.Text = name
	btn.Parent = list
	applyCorner(btn, CONTROL_RADIUS)

	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = Theme.ControlHover
		btn.BackgroundTransparency = Theme.ControlTrans - 0.08
	end)
	btn.MouseLeave:Connect(function()
		styleControl(btn)
	end)
	btn.MouseButton1Click:Connect(function()
		if callback then
			callback()
		end
	end)

	return btn
end

local function formatKeyLabel(keyCode: KeyCode): string
	if keyCode == Enum.KeyCode.Unknown then
		return "Ninguna"
	end
	local name = keyCode.Name
	if string.sub(name, 1, 4) == "Left" then
		return name:sub(5)
	end
	if string.sub(name, 1, 5) == "Right" then
		return "R" .. name:sub(6)
	end
	return name
end

local function addKeybind(list: Frame, title: string, defaultKey: KeyCode, callback: ((KeyCode) -> ())?)
	local key = defaultKey or Enum.KeyCode.RightControl
	local listening = false
	local listenConn: RBXScriptConnection? = nil

	local row = Instance.new("Frame")
	row.Name = "Keybind"
	row.Size = UDim2.new(1, 0, 0, CONTROL_H)
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Parent = list

	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0.55, 0, 1, 0)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Theme.Text
	label.Text = title
	label.Parent = row

	local keyBtn = Instance.new("TextButton")
	keyBtn.Name = "Key"
	keyBtn.AnchorPoint = Vector2.new(1, 0.5)
	keyBtn.Position = UDim2.new(1, 0, 0.5, 0)
	keyBtn.Size = UDim2.fromOffset(108, 28)
	keyBtn.BorderSizePixel = 0
	keyBtn.AutoButtonColor = false
	styleControl(keyBtn)
	keyBtn.Font = Enum.Font.GothamMedium
	keyBtn.TextSize = 12
	keyBtn.TextColor3 = Theme.Title
	keyBtn.Parent = row
	applyCorner(keyBtn, 8)

	local function refreshKeyText()
		keyBtn.Text = if listening then "..." else formatKeyLabel(key)
	end

	local function stopListen()
		listening = false
		if listenConn then
			listenConn:Disconnect()
			listenConn = nil
		end
		refreshKeyText()
	end

	keyBtn.MouseButton1Click:Connect(function()
		if listening then
			stopListen()
			return
		end
		listening = true
		refreshKeyText()
		listenConn = UserInputService.InputBegan:Connect(function(input, _gameProcessed)
			if not listening then
				return
			end
			if input.UserInputType ~= Enum.UserInputType.Keyboard then
				return
			end
			if input.KeyCode == Enum.KeyCode.Escape then
				stopListen()
				return
			end
			key = input.KeyCode
			stopListen()
			if callback then
				callback(key)
			end
		end)
	end)

	refreshKeyText()

	return {
		Get = function()
			return key
		end,
		Set = function(_, newKey: KeyCode)
			key = newKey
			refreshKeyText()
			if callback then
				callback(key)
			end
		end,
	}
end

local function addToggle(list: Frame, name: string, default: boolean, callback: ((boolean) -> ())?)
	local row = Instance.new("Frame")
	row.Name = "Toggle"
	row.Size = UDim2.new(1, 0, 0, CONTROL_H)
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Parent = list

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(4, 0)
	label.Size = UDim2.new(1, -58, 1, 0)
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Theme.Text
	label.Text = name
	label.Parent = row

	local track = Instance.new("TextButton")
	track.Name = "Switch"
	track.AnchorPoint = Vector2.new(1, 0.5)
	track.Position = UDim2.new(1, -4, 0.5, 0)
	track.Size = UDim2.fromOffset(46, 24)
	track.BorderSizePixel = 0
	track.Text = ""
	track.AutoButtonColor = false
	track.Parent = row
	applyCorner(track, 12)

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Size = UDim2.fromOffset(18, 18)
	knob.BackgroundColor3 = Theme.Knob
	knob.BorderSizePixel = 0
	knob.Parent = track
	applyCorner(knob, 9)

	local on = default == true

	local function paintSwitch()
		track.BackgroundColor3 = if on then Theme.Accent else Theme.Track
		track.BackgroundTransparency = if on then 0.05 else 0.15
		knob.Position = if on then UDim2.new(1, -11, 0.5, 0) else UDim2.new(0, 11, 0.5, 0)
	end

	local function setState(value: boolean)
		on = value
		paintSwitch()
		if callback then
			callback(on)
		end
	end

	track.MouseButton1Click:Connect(function()
		setState(not on)
	end)

	paintSwitch()

	return {
		Set = setState,
		Get = function()
			return on
		end,
	}
end

local function addSlider(list: Frame, name: string, min: number, max: number, default: number, callback: ((number) -> ())?)
	local wrap = Instance.new("Frame")
	wrap.Name = "Slider"
	wrap.BackgroundTransparency = 1
	wrap.Size = UDim2.new(1, 0, 0, 52)
	wrap.Parent = list

	local top = Instance.new("Frame")
	top.BackgroundTransparency = 1
	top.Size = UDim2.new(1, 0, 0, 18)
	top.Parent = wrap

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -48, 1, 0)
	title.Font = Enum.Font.Gotham
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Theme.Text
	title.Text = name
	title.Parent = top

	local valueLabel = Instance.new("TextLabel")
	valueLabel.BackgroundTransparency = 1
	valueLabel.AnchorPoint = Vector2.new(1, 0)
	valueLabel.Position = UDim2.fromScale(1, 0)
	valueLabel.Size = UDim2.fromOffset(56, 18)
	valueLabel.Font = Enum.Font.GothamMedium
	valueLabel.TextSize = 12
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.TextColor3 = Theme.Muted
	valueLabel.Parent = top

	local track = Instance.new("TextButton")
	track.Name = "Track"
	track.Position = UDim2.fromOffset(0, 26)
	track.Size = UDim2.new(1, 0, 0, 10)
	styleControl(track)
	track.BorderSizePixel = 0
	track.Text = ""
	track.AutoButtonColor = false
	track.Parent = wrap
	applyCorner(track, 4)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0.5, 1)
	fill.BackgroundColor3 = Theme.Accent
	fill.BorderSizePixel = 0
	fill.Parent = track
	applyCorner(fill, 4)

	local thumb = Instance.new("Frame")
	thumb.Name = "Thumb"
	thumb.AnchorPoint = Vector2.new(0.5, 0.5)
	thumb.Position = UDim2.fromScale(0.5, 0.5)
	thumb.Size = UDim2.fromOffset(16, 16)
	thumb.BackgroundColor3 = Theme.Knob
	thumb.BorderSizePixel = 0
	thumb.ZIndex = 2
	thumb.Parent = track
	applyCorner(thumb, 7)

	local value = default
	local dragging = false

	local function clamp(n: number)
		return math.clamp(n, min, max)
	end

	local function ratio()
		if max <= min then
			return 0
		end
		return (value - min) / (max - min)
	end

	local function applyVisual()
		local r = ratio()
		fill.Size = UDim2.new(r, 0, 1, 0)
		thumb.Position = UDim2.new(r, 0, 0.5, 0)
		valueLabel.Text = string.format("%.2f", value)
	end

	local function setValue(n: number, fire: boolean?)
		value = clamp(n)
		applyVisual()
		if fire and callback then
			callback(value)
		end
	end

	local function setFromX(x: number)
		local rel = track.AbsolutePosition.X
		local w = track.AbsoluteSize.X
		if w <= 0 then
			return
		end
		local t = math.clamp((x - rel) / w, 0, 1)
		setValue(min + (max - min) * t, false)
	end

	local function commitValue()
		value = math.floor(value * 100 + 0.5) / 100
		applyVisual()
		if callback then
			callback(value)
		end
	end

	track.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			setFromX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			if dragging then
				dragging = false
				commitValue()
			end
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			setFromX(input.Position.X)
		end
	end)

	setValue(value, false)

	return {
		Set = function(n: number)
			setValue(n, true)
		end,
		Get = function()
			return value
		end,
	}
end

local function closeDropdownMenus(except: Frame?)
	for _, gui in getGuiParent():GetChildren() do
		if gui:IsA("ScreenGui") and gui.Name == "iFrame_DropdownMenu" then
			if except == nil or gui:FindFirstChild("Root") ~= except then
				gui:Destroy()
			end
		end
	end
end

local function addDropdown(list: Frame, name: string, optionsList: { string }, default: string?, callback: ((string) -> ())?)
	local selected = default or optionsList[1] or ""

	local row = Instance.new("TextButton")
	row.Name = "Dropdown"
	row.Size = UDim2.new(1, 0, 0, CONTROL_H)
	row.BorderSizePixel = 0
	row.AutoButtonColor = false
	row.Text = ""
	styleControl(row)
	row.Parent = list
	applyCorner(row, CONTROL_RADIUS)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(12, 0)
	label.Size = UDim2.new(0.45, 0, 1, 0)
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Theme.Text
	label.Text = name
	label.Parent = row

	local valueLabel = Instance.new("TextLabel")
	valueLabel.BackgroundTransparency = 1
	valueLabel.AnchorPoint = Vector2.new(1, 0)
	valueLabel.Position = UDim2.new(1, -22, 0, 0)
	valueLabel.Size = UDim2.new(0.45, -8, 1, 0)
	valueLabel.Font = Enum.Font.GothamMedium
	valueLabel.TextSize = 13
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.TextColor3 = Theme.Title
	valueLabel.Text = selected .. " >"
	valueLabel.Parent = row

	local chevron = Instance.new("TextLabel")
	chevron.BackgroundTransparency = 1
	chevron.AnchorPoint = Vector2.new(1, 0.5)
	chevron.Position = UDim2.new(1, -10, 0.5, 0)
	chevron.Size = UDim2.fromOffset(14, 14)
	chevron.Font = Enum.Font.GothamBold
	chevron.TextSize = 12
	chevron.TextColor3 = Theme.Muted
	chevron.Text = ""
	chevron.Parent = row

	local function setSelected(opt: string)
		selected = opt
		valueLabel.Text = selected .. " >"
		if callback then
			callback(selected)
		end
	end

	row.MouseButton1Click:Connect(function()
		closeDropdownMenus()

		local menuGui = Instance.new("ScreenGui")
		menuGui.Name = "iFrame_DropdownMenu"
		menuGui.ResetOnSpawn = false
		menuGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		menuGui.Parent = getGuiParent()

		local root = Instance.new("Frame")
		root.Name = "Root"
		root.BorderSizePixel = 0
		root.ZIndex = 100
		styleControl(root)
		root.Parent = menuGui
		applyCorner(root, CONTROL_RADIUS)

		local abs = row.AbsolutePosition
		local size = row.AbsoluteSize
		root.Position = UDim2.fromOffset(abs.X, abs.Y + size.Y + 4)
		root.Size = UDim2.fromOffset(size.X, math.min(#optionsList * 30 + 8, 160))

		local scroll = Instance.new("ScrollingFrame")
		scroll.BackgroundTransparency = 1
		scroll.Size = UDim2.new(1, -4, 1, -4)
		scroll.Position = UDim2.fromOffset(2, 2)
		scroll.ScrollBarThickness = 3
		scroll.CanvasSize = UDim2.fromOffset(0, 0)
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.Parent = root

		local optList = Instance.new("Frame")
		optList.BackgroundTransparency = 1
		optList.Size = UDim2.new(1, 0, 0, 0)
		optList.AutomaticSize = Enum.AutomaticSize.Y
		optList.Parent = scroll

		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 2)
		layout.Parent = optList

		for _, opt in optionsList do
			local item = Instance.new("TextButton")
			item.Size = UDim2.new(1, -4, 0, 28)
			item.BackgroundColor3 = Theme.Sidebar
			item.BorderSizePixel = 0
			item.AutoButtonColor = false
			item.Font = Enum.Font.Gotham
			item.TextSize = 13
			item.TextColor3 = Theme.Text
			item.Text = opt
			item.Parent = optList
			applyCorner(item, 4)

			item.MouseEnter:Connect(function()
				item.BackgroundColor3 = Theme.ControlHover
			end)
			item.MouseLeave:Connect(function()
				item.BackgroundColor3 = Theme.Sidebar
			end)
			item.MouseButton1Click:Connect(function()
				setSelected(opt)
				menuGui:Destroy()
			end)
		end

		task.defer(function()
			local closeConn
			closeConn = UserInputService.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
					return
				end
				if not menuGui.Parent then
					closeConn:Disconnect()
					return
				end
				local pos = input.Position
				local rPos = root.AbsolutePosition
				local rSize = root.AbsoluteSize
				local inMenu = pos.X >= rPos.X and pos.X <= rPos.X + rSize.X and pos.Y >= rPos.Y and pos.Y <= rPos.Y + rSize.Y
				local inRow = pos.X >= abs.X and pos.X <= abs.X + size.X and pos.Y >= abs.Y and pos.Y <= abs.Y + size.Y
				if not inMenu and not inRow then
					menuGui:Destroy()
					closeConn:Disconnect()
				end
			end)
		end)
	end)

	return {
		Set = setSelected,
		Get = function()
			return selected
		end,
	}
end

local function addInput(list: Frame, name: string, placeholder: string?, callback: ((string) -> ())?)
	local wrap = Instance.new("Frame")
	wrap.Name = "Input"
	wrap.BackgroundTransparency = 1
	wrap.Size = UDim2.new(1, 0, 0, 52)
	wrap.Parent = list

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 18)
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Theme.Text
	label.Text = name
	label.Parent = wrap

	local field = Instance.new("TextBox")
	field.Position = UDim2.fromOffset(0, 22)
	field.Size = UDim2.new(1, 0, 0, CONTROL_H)
	field.BorderSizePixel = 0
	styleControl(field)
	field.ClearTextOnFocus = false
	field.Font = Enum.Font.Gotham
	field.TextSize = 14
	field.TextXAlignment = Enum.TextXAlignment.Left
	field.TextColor3 = Theme.Title
	field.PlaceholderText = placeholder or ""
	field.PlaceholderColor3 = Theme.Muted
	field.Text = ""
	field.Parent = wrap
	applyCorner(field, CONTROL_RADIUS)

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = field

	field.FocusLost:Connect(function()
		if callback then
			callback(field.Text)
		end
	end)

	return {
		Set = function(text: string)
			field.Text = text
		end,
		Get = function()
			return field.Text
		end,
	}
end

local function colorToHex(c: Color3)
	return string.format(
		"#%02X%02X%02X",
		math.floor(c.R * 255 + 0.5),
		math.floor(c.G * 255 + 0.5),
		math.floor(c.B * 255 + 0.5)
	)
end

local function colorToRgbText(c: Color3)
	return string.format(
		"%d, %d, %d",
		math.floor(c.R * 255 + 0.5),
		math.floor(c.G * 255 + 0.5),
		math.floor(c.B * 255 + 0.5)
	)
end

-- Iconos por nombre Lucide (atlas Rayfield, mismo patron que Gen2). "settings", "lucide:settings"
local LUCIDE_ICONS_URL = "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua"
local lucideIconsTable: any = nil
local lucideIconsFailed = false

type IconResolved = {
	image: string,
	rectOffset: Vector2?,
	rectSize: Vector2?,
	tint: Color3?,
}

local function isCustomIconPath(value: string): boolean
	return string.find(value, "rbxasset://", 1, true) == 1 or string.find(value, "rbxthumb://", 1, true) == 1
end

local function resolveIconRef(icon: string): (string, string)
	local ref = icon:match("^%s*(.-)%s*$") or icon
	if isCustomIconPath(ref) then
		return "custom", ref
	end
	if typeof(getcustomasset) == "function" and ref:find("/", 1, true) and not ref:find(":", 1, true) then
		return "custom", ref
	end
	local set: string?
	local name: string?
	if string.find(ref, ":", 1, true) then
		set, name = ref:match("^([^:]+):(.+)$")
	elseif string.find(ref, "/", 1, true) then
		set, name = ref:match("^([^/]+)/(.+)$")
	else
		set = "lucide"
		name = ref
	end
	if not set or not name or name == "" then
		return "lucide", "circle"
	end
	return set, name
end

function iFrame.resolveIcon(icon: string): (string, string)
	return resolveIconRef(icon)
end

local function loadLucideIcons(): any
	if lucideIconsTable then
		return lucideIconsTable
	end
	if lucideIconsFailed then
		return nil
	end
	local ok, data = pcall(function()
		local src = game:HttpGet(LUCIDE_ICONS_URL)
		if type(src) ~= "string" or #src < 32 then
			return nil
		end
		return loadstring(src)()
	end)
	if ok and type(data) == "table" then
		lucideIconsTable = data
		return lucideIconsTable
	end
	lucideIconsFailed = true
	warn("[iFrame] iconos: no se pudo cargar atlas Lucide (icons.lua)")
	return nil
end

local function resolveLucideSprite(name: string): (string?, Vector2?, Vector2?)
	local icons = loadLucideIcons()
	if not icons then
		return nil, nil, nil
	end
	local key = string.lower((name:match("^%s*(.-)%s*$") or name))
	local sized = icons["48px"]
	if type(sized) ~= "table" then
		return nil, nil, nil
	end
	local entry = sized[key]
	if type(entry) ~= "table" then
		entry = sized.circle
	end
	if type(entry) ~= "table" then
		return nil, nil, nil
	end
	local id, rectSize, rectOffset = entry[1], entry[2], entry[3]
	if type(id) ~= "number" or type(rectSize) ~= "table" or type(rectOffset) ~= "table" then
		return nil, nil, nil
	end
	return "rbxassetid://" .. tostring(id), Vector2.new(rectOffset[1], rectOffset[2]), Vector2.new(rectSize[1], rectSize[2])
end

local function resolveIconVisual(icon: string, tint: Color3): IconResolved?
	local set, name = resolveIconRef(icon)
	if set == "custom" then
		local image = name
		if typeof(getcustomasset) == "function" and not isCustomIconPath(image) then
			local ok, asset = pcall(getcustomasset, image)
			if ok and type(asset) == "string" and asset ~= "" then
				image = asset
			end
		end
		return { image = image, rectOffset = nil, rectSize = nil, tint = tint }
	end
	if set ~= "lucide" then
		name = name:match("^%s*(.-)%s*$") or name
	end
	local image, offset, size = resolveLucideSprite(name)
	if not image then
		return nil
	end
	return { image = image, rectOffset = offset, rectSize = size, tint = tint }
end

function iFrame.iconUrl(icon: string, _opts: { size: number?, color: Color3? }?): string
	local resolved = resolveIconVisual(icon, Theme.Title)
	if resolved then
		return resolved.image
	end
	return ""
end

local function applyIconResolved(img: ImageLabel, resolved: IconResolved)
	img.Image = resolved.image
	if resolved.rectOffset and resolved.rectSize then
		img.ImageRectOffset = resolved.rectOffset
		img.ImageRectSize = resolved.rectSize
	else
		img.ImageRectOffset = Vector2.zero
		img.ImageRectSize = Vector2.zero
	end
	if resolved.tint then
		img.ImageColor3 = resolved.tint
	end
end

local function ensureIconImage(parent: Instance, name: string): ImageLabel
	local img = parent:FindFirstChild(name)
	if img and img:IsA("ImageLabel") then
		return img
	end
	if img then
		img:Destroy()
	end
	local label = Instance.new("ImageLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.ScaleType = Enum.ScaleType.Fit
	label.ZIndex = (parent:IsA("GuiObject") and parent.ZIndex or 1) + 2
	label.Parent = parent
	return label
end

local function applyIconImageAsync(img: ImageLabel, icon: string, opts: { size: number?, color: Color3? }?)
	opts = opts or {}
	local color = opts.color or Theme.Title

	task.spawn(function()
		local resolved = resolveIconVisual(icon, color)
		if resolved and img.Parent then
			applyIconResolved(img, resolved)
		end
	end)
end

function iFrame.setIcon(target: GuiObject, icon: string, opts: { size: number?, color: Color3? }?)
	opts = opts or {}
	local px = opts.size or 18
	local img = ensureIconImage(target, "Icon")
	img.Size = UDim2.fromOffset(px, px)
	applyIconImageAsync(img, icon, opts)
	return img
end

local function applyIconOnlyButton(btn: GuiButton, icon: string, px: number?)
	local size = px or 18
	btn.Text = ""
	iFrame.setIcon(btn, icon, { size = size, color = Theme.Title })
	local img = btn:FindFirstChild("Icon") :: ImageLabel
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Position = UDim2.fromScale(0.5, 0.5)
end

local function getTabTitleLabel(btn: TextButton): TextLabel?
	local row = btn:FindFirstChild("TabRow")
	if row then
		local title = row:FindFirstChild("Title")
		if title and title:IsA("TextLabel") then
			return title
		end
	end
	return nil
end

local function applyTabButtonIcon(btn: TextButton, icon: string, label: string)
	btn.Text = ""
	local px = 16
	local gap = 8
	local sidePad = 10

	local row = Instance.new("Frame")
	row.Name = "TabRow"
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromScale(1, 1)
	row.Parent = btn

	local rowPad = Instance.new("UIPadding")
	rowPad.PaddingLeft = UDim.new(0, sidePad)
	rowPad.PaddingRight = UDim.new(0, sidePad)
	rowPad.Parent = row

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, gap)
	list.Parent = row

	local iconImg = Instance.new("ImageLabel")
	iconImg.Name = "Icon"
	iconImg.LayoutOrder = 1
	iconImg.Size = UDim2.fromOffset(px, px)
	iconImg.BackgroundTransparency = 1
	iconImg.BorderSizePixel = 0
	iconImg.ScaleType = Enum.ScaleType.Fit
	iconImg.Parent = row
	applyIconImageAsync(iconImg, icon, { size = px, color = Theme.Title })

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.LayoutOrder = 2
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -(px + gap), 1, 0)
	title.Font = btn.Font
	title.TextSize = btn.TextSize
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.TextColor3 = Theme.Text
	title.Text = label
	title.Parent = row
end

local function makeRingCursor(parent: GuiObject, diameter: number)
	local ring = Instance.new("Frame")
	ring.Name = "Cursor"
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Size = UDim2.fromOffset(diameter, diameter)
	ring.BackgroundTransparency = 1
	ring.BorderSizePixel = 0
	ring.ZIndex = 4
	ring.Parent = parent

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 2
	stroke.Parent = ring

	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.fromScale(0.5, 0.5)
	inner.Size = UDim2.fromOffset(math.max(4, diameter - 8), math.max(4, diameter - 8))
	inner.BorderSizePixel = 0
	inner.Parent = ring
	applyCorner(inner, math.max(2, (diameter - 8) / 2))

	return ring, inner
end

local function bindPointerPick(
	target: GuiObject,
	onPick: (Vector2) -> (),
	onCommit: (() -> ())?
): { RBXScriptConnection }
	target.Active = true
	local dragging = false
	local conns: { RBXScriptConnection } = {}

	local function tryPick(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseMovement
		then
			onPick(Vector2.new(input.Position.X, input.Position.Y))
		end
	end

	table.insert(
		conns,
		target.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				tryPick(input)
			end
		end)
	)

	table.insert(
		conns,
		target.InputChanged:Connect(function(input)
			if not dragging then
				return
			end
			tryPick(input)
		end)
	)

	table.insert(
		conns,
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if dragging and onCommit then
					onCommit()
				end
				dragging = false
			end
		end)
	)

	return conns
end

local function addColorPicker(list: Frame, name: string, default: Color3, callback: ((Color3) -> ())?)
	local color = default
	local h, s, v = Color3.toHSV(color)

	local row = Instance.new("Frame")
	row.Name = "ColorPicker"
	row.Size = UDim2.new(1, 0, 0, CONTROL_H)
	row.BorderSizePixel = 0
	styleControl(row)
	row.Parent = list
	applyCorner(row, CONTROL_RADIUS)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(12, 0)
	label.Size = UDim2.new(1, -52, 1, 0)
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Theme.Text
	label.Text = name
	label.Parent = row

	local swatch = Instance.new("TextButton")
	swatch.Name = "Swatch"
	swatch.AnchorPoint = Vector2.new(1, 0.5)
	swatch.Position = UDim2.new(1, -10, 0.5, 0)
	swatch.Size = UDim2.fromOffset(28, 24)
	swatch.BackgroundColor3 = color
	swatch.BorderSizePixel = 0
	swatch.AutoButtonColor = false
	swatch.Text = ""
	swatch.Parent = row
	applyCorner(swatch, 5)

	local swatchStroke = Instance.new("UIStroke")
	swatchStroke.Color = Theme.Divider
	swatchStroke.Thickness = 1
	swatchStroke.Parent = swatch

	local function setColor(c: Color3, fire: boolean?)
		color = c
		h, s, v = Color3.toHSV(color)
		swatch.BackgroundColor3 = color
		if fire and callback then
			callback(color)
		end
	end

	swatch.MouseButton1Click:Connect(function()
		closeDropdownMenus()

		local menuGui = Instance.new("ScreenGui")
		menuGui.Name = "iFrame_DropdownMenu"
		menuGui.ResetOnSpawn = false
		menuGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		menuGui.Parent = getGuiParent()

		local panelPad = 12
		local panelW = 272
		local svH = 158
		local svW = panelW - panelPad * 2
		local hueH = 14
		local footerH = 42
		local panelH = panelPad + svH + 10 + hueH + 10 + footerH + panelPad

		local panel = Instance.new("Frame")
		panel.Name = "ColorPanel"
		panel.BorderSizePixel = 0
		panel.ZIndex = 120
		panel.Size = UDim2.fromOffset(panelW, panelH)
		panel.Parent = menuGui
		applyGlassShell(panel, 10)

		local abs = swatch.AbsolutePosition
		local sw = swatch.AbsoluteSize
		local posX = abs.X + sw.X * 0.5 - panelW * 0.5
		local posY = abs.Y + sw.Y + 8
		panel.Position = UDim2.fromOffset(posX, posY)

		local svPad = Instance.new("TextButton")
		svPad.Name = "SV"
		svPad.Position = UDim2.fromOffset(panelPad, panelPad)
		svPad.Size = UDim2.fromOffset(svW, svH)
		svPad.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svPad.BorderSizePixel = 0
		svPad.Text = ""
		svPad.AutoButtonColor = false
		svPad.ClipsDescendants = true
		svPad.Parent = panel
		applyCorner(svPad, 10)

		local satGrad = Instance.new("UIGradient")
		satGrad.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
		satGrad.Transparency = NumberSequence.new(0, 1)
		satGrad.Parent = svPad

		local valOverlay = Instance.new("Frame")
		valOverlay.Name = "Value"
		valOverlay.Size = UDim2.fromScale(1, 1)
		valOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
		valOverlay.BorderSizePixel = 0
		valOverlay.Parent = svPad

		local valGrad = Instance.new("UIGradient")
		valGrad.Rotation = 90
		valGrad.Transparency = NumberSequence.new(0, 1)
		valGrad.Parent = valOverlay

		local svCursor, svCursorInner = makeRingCursor(svPad, 16)
		svCursorInner.BackgroundTransparency = 1

		local hueY = panelPad + svH + 10
		local huePad = Instance.new("TextButton")
		huePad.Name = "Hue"
		huePad.Position = UDim2.fromOffset(panelPad, hueY)
		huePad.Size = UDim2.fromOffset(svW, hueH)
		huePad.BackgroundColor3 = Color3.new(1, 1, 1)
		huePad.BorderSizePixel = 0
		huePad.Text = ""
		huePad.AutoButtonColor = false
		huePad.ClipsDescendants = false
		huePad.Parent = panel
		applyCorner(huePad, 7)

		local hueGrad = Instance.new("UIGradient")
		hueGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		})
		hueGrad.Parent = huePad

		local hueCursor, hueCursorDot = makeRingCursor(huePad, 18)
		hueCursorDot.BackgroundColor3 = Color3.fromHSV(h, 1, 1)

		local footer = Instance.new("Frame")
		footer.Name = "Footer"
		footer.Position = UDim2.fromOffset(panelPad, hueY + hueH + 10)
		footer.Size = UDim2.fromOffset(svW, footerH)
		footer.BackgroundColor3 = Theme.Sidebar
		footer.BorderSizePixel = 0
		footer.Parent = panel
		applyCorner(footer, 8)

		local footerStroke = Instance.new("UIStroke")
		footerStroke.Color = Theme.Divider
		footerStroke.Thickness = 1
		footerStroke.Parent = footer

		local preview = Instance.new("Frame")
		preview.Name = "Preview"
		preview.AnchorPoint = Vector2.new(0, 0.5)
		preview.Position = UDim2.new(0, 10, 0.5, 0)
		preview.Size = UDim2.fromOffset(26, 26)
		preview.BackgroundColor3 = color
		preview.BorderSizePixel = 0
		preview.Parent = footer
		local previewCorner = Instance.new("UICorner")
		previewCorner.CornerRadius = UDim.new(1, 0)
		previewCorner.Parent = preview

		local valueLabel = Instance.new("TextLabel")
		valueLabel.Name = "Value"
		valueLabel.Position = UDim2.fromOffset(44, 0)
		valueLabel.Size = UDim2.new(1, -132, 1, 0)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Font = Enum.Font.GothamMedium
		valueLabel.TextSize = 14
		valueLabel.TextXAlignment = Enum.TextXAlignment.Left
		valueLabel.TextColor3 = Theme.Title
		valueLabel.Text = ""
		valueLabel.Parent = footer

		local copyBtn = Instance.new("TextButton")
		copyBtn.Name = "Copy"
		copyBtn.AnchorPoint = Vector2.new(1, 0.5)
		copyBtn.Position = UDim2.new(1, -58, 0.5, 0)
		copyBtn.Size = UDim2.fromOffset(28, 28)
		copyBtn.BackgroundTransparency = 1
		copyBtn.BorderSizePixel = 0
		copyBtn.AutoButtonColor = false
		copyBtn.Text = ""
		copyBtn.Parent = footer

		local copyA = Instance.new("Frame")
		copyA.Size = UDim2.fromOffset(10, 12)
		copyA.Position = UDim2.fromOffset(8, 6)
		copyA.BackgroundColor3 = Theme.Muted
		copyA.BorderSizePixel = 0
		copyA.Parent = copyBtn
		applyCorner(copyA, 2)

		local copyB = Instance.new("Frame")
		copyB.Size = UDim2.fromOffset(10, 12)
		copyB.Position = UDim2.fromOffset(12, 10)
		copyB.BackgroundColor3 = Theme.Text
		copyB.BorderSizePixel = 0
		copyB.Parent = copyBtn
		applyCorner(copyB, 2)

		local formatBtn = Instance.new("TextButton")
		formatBtn.Name = "Format"
		formatBtn.AnchorPoint = Vector2.new(1, 0.5)
		formatBtn.Position = UDim2.new(1, -8, 0.5, 0)
		formatBtn.Size = UDim2.fromOffset(46, 28)
		formatBtn.BackgroundColor3 = Theme.Control
		formatBtn.BorderSizePixel = 0
		formatBtn.AutoButtonColor = false
		formatBtn.Font = Enum.Font.GothamMedium
		formatBtn.TextSize = 12
		formatBtn.TextColor3 = Theme.Text
		formatBtn.Text = "Hex"
		formatBtn.Parent = footer
		applyCorner(formatBtn, 6)

		local formatMode = "Hex"

		local function valueText(c: Color3)
			if formatMode == "RGB" then
				return colorToRgbText(c)
			end
			local hex = colorToHex(c)
			return "# " .. hex:sub(2)
		end

		local function applyHsv(fire: boolean?)
			local c = Color3.fromHSV(h, s, v)
			setColor(c, fire)
			svPad.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
			hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
			hueCursorDot.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			preview.BackgroundColor3 = c
			valueLabel.Text = valueText(c)
		end

		local function pickSv(screenPos: Vector2)
			local p = svPad.AbsolutePosition
			local sz = svPad.AbsoluteSize
			if sz.X <= 0 or sz.Y <= 0 then
				return
			end
			s = math.clamp((screenPos.X - p.X) / sz.X, 0, 1)
			v = math.clamp(1 - (screenPos.Y - p.Y) / sz.Y, 0, 1)
			applyHsv(false)
		end

		local function pickHue(screenPos: Vector2)
			local p = huePad.AbsolutePosition
			local sz = huePad.AbsoluteSize
			if sz.X <= 0 then
				return
			end
			h = math.clamp((screenPos.X - p.X) / sz.X, 0, 1)
			applyHsv(false)
		end

		local function commitPick()
			applyHsv(true)
		end

		copyBtn.MouseButton1Click:Connect(function()
			local c = Color3.fromHSV(h, s, v)
			local clip = if formatMode == "RGB" then colorToRgbText(c) else colorToHex(c)
			if typeof(setclipboard) == "function" then
				setclipboard(clip)
			elseif typeof(writeclipboard) == "function" then
				writeclipboard(clip)
			end
		end)

		formatBtn.MouseButton1Click:Connect(function()
			formatMode = if formatMode == "Hex" then "RGB" else "Hex"
			formatBtn.Text = formatMode
			applyHsv(false)
		end)

		applyHsv(false)

		local pickConns: { RBXScriptConnection } = {}
		for _, conn in bindPointerPick(svPad, pickSv, commitPick) do
			table.insert(pickConns, conn)
		end
		for _, conn in bindPointerPick(huePad, pickHue, commitPick) do
			table.insert(pickConns, conn)
		end

		local function disposeMenu()
			for _, conn in pickConns do
				conn:Disconnect()
			end
		end

		menuGui.Destroying:Connect(disposeMenu)

		task.defer(function()
			local closeConn
			closeConn = UserInputService.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
					return
				end
				if not menuGui.Parent then
					closeConn:Disconnect()
					return
				end
				local pos = input.Position
				local pPos = panel.AbsolutePosition
				local pSize = panel.AbsoluteSize
				local inPanel = pos.X >= pPos.X and pos.X <= pPos.X + pSize.X and pos.Y >= pPos.Y and pos.Y <= pPos.Y + pSize.Y
				local sPos = swatch.AbsolutePosition
				local sSize = swatch.AbsoluteSize
				local inSwatch = pos.X >= sPos.X and pos.X <= sPos.X + sSize.X and pos.Y >= sPos.Y and pos.Y <= sPos.Y + sSize.Y
				if not inPanel and not inSwatch then
					menuGui:Destroy()
					closeConn:Disconnect()
				end
			end)
		end)
	end)

	return {
		Set = function(c: Color3)
			setColor(c, true)
		end,
		Get = function()
			return color
		end,
	}
end

local function addStatus(list: Frame, title: string, text: string, id: string?)
	local row = Instance.new("Frame")
	row.Name = "Status"
	row.Size = UDim2.new(1, 0, 0, 40)
	row.BorderSizePixel = 0
	styleControl(row)
	row.Parent = list
	applyCorner(row, CONTROL_RADIUS)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.fromOffset(12, 6)
	titleLabel.Size = UDim2.new(1, -24, 0, 14)
	titleLabel.Font = Enum.Font.GothamMedium
	titleLabel.TextSize = 12
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextColor3 = Theme.Muted
	titleLabel.Text = title
	titleLabel.Parent = row

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Value"
	textLabel.BackgroundTransparency = 1
	textLabel.Position = UDim2.fromOffset(12, 20)
	textLabel.Size = UDim2.new(1, -24, 0, 16)
	textLabel.Font = Enum.Font.Gotham
	textLabel.TextSize = 13
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextColor3 = Theme.Title
	textLabel.Text = text
	textLabel.Parent = row

	local handle = {
		SetText = function(_, newText: string)
			textLabel.Text = newText
		end,
	}

	if id then
		handle.Id = id
	end

	return handle
end

local function mountList(list: Frame, schema: { any })
	local sectionParent = list
	local handles = {}

	for _, item in schema do
		local t = item.type
		if t == "section" then
			sectionParent = addSection(list, item.title or "")
		elseif t == "text" then
			addText(sectionParent, item.text or "")
		elseif t == "button" then
			addButton(sectionParent, item.title or item.name or "Button", item.callback)
		elseif t == "toggle" then
			local h = addToggle(sectionParent, item.title or item.name or "Toggle", item.default == true, item.callback)
			if item.id then
				handles[item.id] = h
			end
		elseif t == "slider" then
			local h = addSlider(
				sectionParent,
				item.title or item.name or "Slider",
				item.min or 0,
				item.max or 100,
				item.default or item.min or 0,
				item.callback
			)
			if item.id then
				handles[item.id] = h
			end
		elseif t == "dropdown" then
			local h = addDropdown(sectionParent, item.title or item.name or "List", item.options or {}, item.default, item.callback)
			if item.id then
				handles[item.id] = h
			end
		elseif t == "input" then
			local h = addInput(sectionParent, item.title or item.name or "Input", item.placeholder, item.callback)
			if item.id then
				handles[item.id] = h
			end
		elseif t == "color" then
			local h = addColorPicker(sectionParent, item.title or item.name or "Color", item.default or Color3.fromRGB(255, 255, 255), item.callback)
			if item.id then
				handles[item.id] = h
			end
		elseif t == "status" then
			local h = addStatus(sectionParent, item.title or "Status", item.text or "", item.id)
			if item.id then
				handles[item.id] = h
			end
		elseif t == "keybind" then
			local defaultKey = item.default
			if typeof(defaultKey) ~= "EnumItem" then
				defaultKey = Enum.KeyCode.RightControl
			end
			local h = addKeybind(sectionParent, item.title or item.name or "Key", defaultKey, item.callback)
			if item.id then
				handles[item.id] = h
			end
		end
	end

	return handles
end

function iFrame.mount(tab, schema)
	if type(tab) ~= "table" then
		error("iFrame.mount(tab, schema) needs a tab from window:CreateTab")
	end
	local list = tab._list
	if list ~= nil and typeof(list) == "Instance" then
		return mountList(list, schema)
	end
	if type(tab.Mount) == "function" then
		return tab:Mount(schema)
	end
	error("iFrame.mount(tab, schema) needs a tab from window:CreateTab")
end

local function createSidebarProfile(parent: Frame, onConfig: (() -> ())?, configIcon: string?)
	local dock = Instance.new("Frame")
	dock.Name = "ProfileDock"
	dock.AnchorPoint = Vector2.new(0, 1)
	dock.Position = UDim2.new(0, 0, 1, 0)
	dock.Size = UDim2.new(1, 0, 0, SIDEBAR_PROFILE_H)
	dock.BackgroundTransparency = 1
	dock.BorderSizePixel = 0
	dock.Parent = parent

	local topLine = Instance.new("Frame")
	topLine.Name = "Divider"
	topLine.Size = UDim2.new(1, -16, 0, 1)
	topLine.Position = UDim2.fromOffset(8, 6)
	topLine.BackgroundColor3 = Theme.Divider
	topLine.BorderSizePixel = 0
	topLine.Parent = dock

	local profileCard = Instance.new("Frame")
	profileCard.Name = "Profile"
	profileCard.AnchorPoint = Vector2.new(0, 1)
	profileCard.Position = UDim2.new(0, 8, 1, -10)
	profileCard.Size = UDim2.new(1, -16, 0, 58)
	profileCard.BorderSizePixel = 0
	styleControl(profileCard)
	profileCard.Parent = dock
	applyCorner(profileCard, 8)

	local avatar = Instance.new("ImageLabel")
	avatar.Name = "Avatar"
	avatar.AnchorPoint = Vector2.new(0, 0.5)
	avatar.Position = UDim2.new(0, 8, 0.5, 0)
	avatar.Size = UDim2.fromOffset(36, 36)
	avatar.BackgroundColor3 = Theme.Track
	avatar.BackgroundTransparency = 0
	avatar.BorderSizePixel = 0
	avatar.ScaleType = Enum.ScaleType.Crop
	avatar.Parent = profileCard
	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(1, 0)
	avatarCorner.Parent = avatar

	local configBtn = Instance.new("TextButton")
	configBtn.Name = "Config"
	configBtn.AnchorPoint = Vector2.new(1, 0.5)
	configBtn.Position = UDim2.new(1, -8, 0.5, 0)
	configBtn.Size = UDim2.fromOffset(32, 32)
	configBtn.BorderSizePixel = 0
	configBtn.AutoButtonColor = false
	styleControl(configBtn)
	configBtn.Parent = profileCard
	applyCorner(configBtn, 8)
	applyIconOnlyButton(configBtn, configIcon or "lucide:settings", 18)

	local textCol = Instance.new("Frame")
	textCol.Name = "TextCol"
	textCol.AnchorPoint = Vector2.new(0, 0.5)
	textCol.Position = UDim2.new(0, 50, 0.5, 0)
	textCol.Size = UDim2.new(1, -98, 0, 44)
	textCol.BackgroundTransparency = 1
	textCol.BorderSizePixel = 0
	textCol.Parent = profileCard

	local textLayout = Instance.new("UIListLayout")
	textLayout.SortOrder = Enum.SortOrder.LayoutOrder
	textLayout.Padding = UDim.new(0, 1)
	textLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	textLayout.Parent = textCol

	local displayName = Instance.new("TextLabel")
	displayName.Name = "DisplayName"
	displayName.BackgroundTransparency = 1
	displayName.Size = UDim2.new(1, 0, 0, 15)
	displayName.Font = Enum.Font.GothamMedium
	displayName.TextSize = 12
	displayName.TextXAlignment = Enum.TextXAlignment.Left
	displayName.TextTruncate = Enum.TextTruncate.AtEnd
	displayName.TextColor3 = Theme.Title
	displayName.Text = "Player"
	displayName.LayoutOrder = 1
	displayName.Parent = textCol

	local userName = Instance.new("TextLabel")
	userName.Name = "UserName"
	userName.BackgroundTransparency = 1
	userName.Size = UDim2.new(1, 0, 0, 13)
	userName.Font = Enum.Font.Gotham
	userName.TextSize = 10
	userName.TextXAlignment = Enum.TextXAlignment.Left
	userName.TextTruncate = Enum.TextTruncate.AtEnd
	userName.TextColor3 = Theme.Muted
	userName.Text = "@player"
	userName.LayoutOrder = 2
	userName.Parent = textCol

	local userIdLabel = Instance.new("TextLabel")
	userIdLabel.Name = "UserId"
	userIdLabel.BackgroundTransparency = 1
	userIdLabel.Size = UDim2.new(1, 0, 0, 12)
	userIdLabel.Font = Enum.Font.Gotham
	userIdLabel.TextSize = 9
	userIdLabel.TextXAlignment = Enum.TextXAlignment.Left
	userIdLabel.TextTruncate = Enum.TextTruncate.AtEnd
	userIdLabel.TextColor3 = Theme.Muted
	userIdLabel.Text = "0"
	userIdLabel.LayoutOrder = 3
	userIdLabel.Parent = textCol

	local function applyPlayer(player: Player)
		displayName.Text = player.DisplayName
		userName.Text = "@" .. player.Name
		userIdLabel.Text = tostring(player.UserId)

		task.spawn(function()
			local ok, thumb = pcall(function()
				return Players:GetUserThumbnailAsync(
					player.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size48x48
				)
			end)
			if ok and type(thumb) == "string" and thumb ~= "" then
				avatar.Image = thumb
			end
		end)
	end

	local localPlayer = Players.LocalPlayer
	if localPlayer then
		applyPlayer(localPlayer)
	else
		Players.PlayerAdded:Once(applyPlayer)
	end

	if type(onConfig) == "function" then
		configBtn.MouseButton1Click:Connect(onConfig)
	end

	return {
		Dock = dock,
		Card = profileCard,
		ConfigButton = configBtn,
		Avatar = avatar,
		DisplayName = displayName,
		UserName = userName,
		UserId = userIdLabel,
		SetPlayer = applyPlayer,
	}
end

-- --- window ---

function iFrame.window(options)
	options = options or {}
	local title = options.name or "iFrame"

	local legacyBlur = game:GetService("Lighting"):FindFirstChild("iFrame_BackdropBlur")
	if legacyBlur and legacyBlur:IsA("BlurEffect") then
		legacyBlur:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = title .. "_iFrame"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = getGuiParent()

	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = WINDOW_POSITION
	holder.Size = UDim2.fromOffset(SPLASH_SIZE.X, SPLASH_SIZE.Y)
	holder.BorderSizePixel = 0
	holder.ClipsDescendants = true
	applyGlassShell(holder, SPLASH_CORNER_RADIUS)
	applyFrostBackdrop(holder, SPLASH_CORNER_RADIUS)
	local holderCorner = holder:FindFirstChildOfClass("UICorner") :: UICorner
	holder.Parent = gui

	local clipRoot = Instance.new("Frame")
	clipRoot.Name = "ClipRoot"
	clipRoot.Size = UDim2.fromScale(1, 1)
	clipRoot.BackgroundTransparency = 1
	clipRoot.ZIndex = 2
	clipRoot.ClipsDescendants = true
	local clipCorner = applyCorner(clipRoot, SPLASH_CORNER_RADIUS)
	clipRoot.Parent = holder

	local splash = Instance.new("Frame")
	splash.Name = "Splash"
	splash.Size = UDim2.fromScale(1, 1)
	splash.BorderSizePixel = 0
	splash.ZIndex = 5
	styleGlass(splash, Theme.Glass, 0.12)
	applyCorner(splash, SPLASH_CORNER_RADIUS)
	splash.Parent = holder

	local brandRow = Instance.new("Frame")
	brandRow.Name = "BrandRow"
	brandRow.BackgroundTransparency = 1
	brandRow.AnchorPoint = Vector2.new(0.5, 0.5)
	brandRow.Position = UDim2.new(0.5, 0, 0.42, 0)
	brandRow.Size = UDim2.fromOffset(120, 28)
	brandRow.Parent = splash

	local brandLayout = Instance.new("UIListLayout")
	brandLayout.FillDirection = Enum.FillDirection.Horizontal
	brandLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	brandLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	brandLayout.Padding = UDim.new(0, 4)
	brandLayout.Parent = brandRow

	local brandLabel = Instance.new("TextLabel")
	brandLabel.Name = "Brand"
	brandLabel.BackgroundTransparency = 1
	brandLabel.Size = UDim2.fromOffset(0, 22)
	brandLabel.AutomaticSize = Enum.AutomaticSize.X
	brandLabel.Font = Enum.Font.Bodoni
	brandLabel.TextSize = 20
	brandLabel.TextColor3 = Theme.Title
	brandLabel.Text = SPLASH_BRAND
	brandLabel.Parent = brandRow

	local subLabel = Instance.new("TextLabel")
	subLabel.Name = "Sub"
	subLabel.BackgroundTransparency = 1
	subLabel.Size = UDim2.fromOffset(0, 18)
	subLabel.AutomaticSize = Enum.AutomaticSize.X
	subLabel.Font = Enum.Font.Gotham
	subLabel.TextSize = 13
	subLabel.TextColor3 = Color3.fromRGB(160, 160, 168)
	subLabel.Text = SPLASH_SUB
	subLabel.Parent = brandRow

	local spinner = Instance.new("Frame")
	spinner.Name = "Spinner"
	spinner.AnchorPoint = Vector2.new(0.5, 0.5)
	spinner.Position = UDim2.new(0.5, 0, 0.78, 0)
	spinner.Size = UDim2.fromOffset(20, 20)
	spinner.BackgroundTransparency = 1
	spinner.Parent = splash

	local spinnerDot = Instance.new("Frame")
	spinnerDot.Name = "Dot"
	spinnerDot.Size = UDim2.fromOffset(5, 5)
	spinnerDot.Position = UDim2.fromOffset(7.5, 0)
	spinnerDot.BackgroundColor3 = Theme.Title
	spinnerDot.BorderSizePixel = 0
	spinnerDot.Parent = spinner
	applyCorner(spinnerDot, 3)

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
	header.BackgroundTransparency = 1
	header.BorderSizePixel = 0
	header.Parent = clipRoot

	local headerDivider = Instance.new("Frame")
	headerDivider.Name = "Divider"
	headerDivider.AnchorPoint = Vector2.new(0, 1)
	headerDivider.Position = UDim2.new(0, 0, 1, 0)
	headerDivider.Size = UDim2.new(1, 0, 0, 1)
	headerDivider.BackgroundColor3 = Theme.Divider
	headerDivider.BorderSizePixel = 0
	headerDivider.Parent = header

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.fromOffset(12, 0)
	titleLabel.Size = UDim2.new(1, -24, 1, 0)
	titleLabel.Font = Enum.Font.Bodoni
	titleLabel.TextSize = 22
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextColor3 = Theme.Title
	titleLabel.Text = title
	titleLabel.Parent = header

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(0, HEADER_HEIGHT)
	body.Size = UDim2.new(1, 0, 1, -HEADER_HEIGHT)
	body.Parent = clipRoot

	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, 0)
	sidebar.BackgroundTransparency = 1
	sidebar.BorderSizePixel = 0
	sidebar.Parent = body

	local sidebarDivider = Instance.new("Frame")
	sidebarDivider.Name = "Divider"
	sidebarDivider.AnchorPoint = Vector2.new(1, 0)
	sidebarDivider.Position = UDim2.new(1, 0, 0, 6)
	sidebarDivider.Size = UDim2.new(0, 1, 1, -12)
	sidebarDivider.BackgroundColor3 = Theme.Divider
	sidebarDivider.BorderSizePixel = 0
	sidebarDivider.Parent = sidebar

	local tabScroll = Instance.new("ScrollingFrame")
	tabScroll.Name = "TabScroll"
	tabScroll.Size = UDim2.new(1, 0, 1, -SIDEBAR_PROFILE_H)
	tabScroll.BackgroundTransparency = 1
	tabScroll.BorderSizePixel = 0
	tabScroll.ScrollBarThickness = 4
	tabScroll.ScrollBarImageColor3 = Theme.Divider
	tabScroll.CanvasSize = UDim2.fromOffset(0, 0)
	tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	tabScroll.Parent = sidebar

	local tabList = Instance.new("Frame")
	tabList.Name = "TabList"
	tabList.BackgroundTransparency = 1
	tabList.Size = UDim2.new(1, 0, 0, 0)
	tabList.AutomaticSize = Enum.AutomaticSize.Y
	tabList.Parent = tabScroll

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Padding = UDim.new(0, 6)
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabLayout.Parent = tabList

	local tabPadding = Instance.new("UIPadding")
	tabPadding.PaddingTop = UDim.new(0, 8)
	tabPadding.PaddingBottom = UDim.new(0, 8)
	tabPadding.PaddingLeft = UDim.new(0, 8)
	tabPadding.PaddingRight = UDim.new(0, 8)
	tabPadding.Parent = tabList

	local profile = createSidebarProfile(sidebar, nil, options.configIcon)

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.Position = UDim2.fromOffset(SIDEBAR_WIDTH, 0)
	content.Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, 0)
	content.Parent = body

	local pages = Instance.new("Frame")
	pages.Name = "Pages"
	pages.BackgroundTransparency = 1
	pages.Size = UDim2.fromScale(1, 1)
	pages.Parent = content

	local configPage = Instance.new("ScrollingFrame")
	configPage.Name = "Config_Page"
	configPage.BackgroundTransparency = 1
	configPage.Size = UDim2.fromScale(1, 1)
	configPage.ScrollBarThickness = 5
	configPage.ScrollBarImageColor3 = Theme.Divider
	configPage.Visible = false
	configPage.Parent = pages

	local configList = newListParent(configPage)

	local menuState = {
		visible = true,
		toggleKey = options.menuKey or options.toggleMenuKey or Enum.KeyCode.RightControl,
	}
	local menuKeyConn: RBXScriptConnection? = nil
	local configOpen = false
	local configMounted = false
	local lastTabBeforeConfig: any = nil
	local windowTitle = title

	local function setMenuVisible(visible: boolean)
		menuState.visible = visible
		holder.Visible = visible
	end

	local function toggleMenu()
		setMenuVisible(not menuState.visible)
	end

	local function bindToggleMenuKey()
		if menuKeyConn then
			menuKeyConn:Disconnect()
			menuKeyConn = nil
		end
		menuKeyConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end
			if input.UserInputType ~= Enum.UserInputType.Keyboard then
				return
			end
			if input.KeyCode == menuState.toggleKey then
				toggleMenu()
			end
		end)
	end

	bindToggleMenuKey()

	local function buildDefaultConfigSchema(): { any }
		local schema: { any } = {
			{ type = "section", title = "Ventana" },
			{
				type = "keybind",
				title = "Toggle menu",
				id = "toggleMenuKey",
				default = menuState.toggleKey,
				callback = function(key: KeyCode)
					menuState.toggleKey = key
					bindToggleMenuKey()
				end,
			},
			{
				type = "toggle",
				title = "Mostrar menu",
				default = menuState.visible,
				callback = function(on: boolean)
					setMenuVisible(on)
				end,
			},
		}
		if type(options.configMount) == "function" then
			local extra = options.configMount()
			if type(extra) == "table" then
				for _, item in extra do
					table.insert(schema, item)
				end
			end
		end
		return schema
	end

	local function styleConfigButton(active: boolean)
		local btn = profile.ConfigButton
		if active then
			btn.BackgroundColor3 = Theme.Accent
			btn.BackgroundTransparency = 0.06
		else
			styleControl(btn)
		end
	end

	local function ensureConfigMounted()
		if configMounted then
			return
		end
		mountList(configList, buildDefaultConfigSchema())
		configMounted = true
	end

	local windowApiRef: any = nil

	local function applyTabSelection(activeTab: any)
		configOpen = false
		configPage.Visible = false
		titleLabel.Text = windowTitle
		styleConfigButton(false)
		if not windowApiRef then
			return
		end
		for _, other in windowApiRef._tabs do
			local active = other == activeTab
			other.Page.Visible = active
			other.Button.BackgroundColor3 = if active then Theme.Accent else Theme.Control
			other.Button.BackgroundTransparency = if active then 0.06 else Theme.ControlTrans
			local tabTitle = getTabTitleLabel(other.Button)
			if tabTitle then
				tabTitle.TextColor3 = Theme.Title
			else
				other.Button.TextColor3 = Theme.Title
			end
			local row = other.Button:FindFirstChild("TabRow")
			local tabIcon = if row then row:FindFirstChild("Icon") else nil
			if tabIcon and tabIcon:IsA("ImageLabel") then
				tabIcon.ImageColor3 = Theme.Title
			end
		end
		windowApiRef._activeTab = activeTab
	end

	local function showConfigInContent()
		if not windowApiRef then
			return
		end
		lastTabBeforeConfig = windowApiRef._activeTab
		configOpen = true
		ensureConfigMounted()
		for _, other in windowApiRef._tabs do
			other.Page.Visible = false
			other.Button.BackgroundColor3 = Theme.Control
			other.Button.BackgroundTransparency = Theme.ControlTrans
		end
		configPage.Visible = true
		titleLabel.Text = "Configuracion"
		styleConfigButton(true)
		windowApiRef._activeTab = nil
	end

	local function closeConfigInContent()
		if lastTabBeforeConfig then
			applyTabSelection(lastTabBeforeConfig)
		elseif windowApiRef and #windowApiRef._tabs > 0 then
			applyTabSelection(windowApiRef._tabs[1])
		else
			configOpen = false
			configPage.Visible = false
			titleLabel.Text = windowTitle
			styleConfigButton(false)
		end
	end

	local function toggleConfigPanel()
		if configOpen then
			closeConfigInContent()
		else
			showConfigInContent()
		end
	end

	profile.ConfigButton.MouseButton1Click:Connect(function()
		if type(options.onConfig) == "function" then
			options.onConfig()
		else
			toggleConfigPanel()
		end
	end)

	header.Active = false
	local dragConnections = bindWindowDrag(header, holder)
	local introConnection: RBXScriptConnection? = nil

	local skipIntro = options.intro == false
	if skipIntro then
		holder.Size = UDim2.fromOffset(WINDOW_SIZE.X, WINDOW_SIZE.Y)
		setCornerRadius(holderCorner, WINDOW_CORNER_RADIUS)
		setCornerRadius(clipCorner, WINDOW_CORNER_RADIUS)
		splash.Visible = false
		header.Active = true
	else
		introConnection = playWindowIntro(holder, clipRoot, splash, header, body, holderCorner, clipCorner, function()
			header.Active = true
		end)
		table.insert(dragConnections, introConnection)
	end

	local windowApi = {
		Gui = gui,
		Holder = holder,
		Splash = splash,
		Header = header,
		Title = titleLabel,
		Body = body,
		Sidebar = sidebar,
		TabScroll = tabScroll,
		TabList = tabList,
		Profile = profile,
		Content = content,
		Pages = pages,
		ConfigPage = configPage,
		ConfigList = configList,
		_tabs = {},
		_activeTab = nil :: any,
	}
	windowApiRef = windowApi

	function windowApi:SetMenuVisible(visible: boolean)
		setMenuVisible(visible)
	end

	function windowApi:ToggleMenu()
		toggleMenu()
	end

	function windowApi:IsMenuVisible(): boolean
		return menuState.visible
	end

	function windowApi:GetToggleMenuKey(): KeyCode
		return menuState.toggleKey
	end

	function windowApi:SetToggleMenuKey(key: KeyCode)
		menuState.toggleKey = key
		bindToggleMenuKey()
	end

	function windowApi:OpenConfig()
		toggleConfigPanel()
	end

	function windowApi:CloseConfig()
		if configOpen then
			closeConfigInContent()
		end
	end

	function windowApi:IsConfigOpen(): boolean
		return configOpen
	end

	function windowApi:CreateTab(tabOptions)
		tabOptions = tabOptions or {}
		local tabName = tabOptions.name or ("Tab " .. tostring(#self._tabs + 1))

		local btn = Instance.new("TextButton")
		btn.Name = tabName
		btn.Size = UDim2.new(1, -4, 0, 36)
		btn.BorderSizePixel = 0
		styleControl(btn)
		btn.AutoButtonColor = false
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 13
		btn.TextColor3 = Theme.Text
		btn.LayoutOrder = #self._tabs + 1
		btn.Parent = tabList
		applyCorner(btn, CONTROL_RADIUS)
		if type(tabOptions.icon) == "string" and tabOptions.icon ~= "" then
			applyTabButtonIcon(btn, tabOptions.icon, tabName)
		else
			btn.Text = tabName
		end

		local page = Instance.new("ScrollingFrame")
		page.Name = tabName .. "_Page"
		page.BackgroundTransparency = 1
		page.Size = UDim2.fromScale(1, 1)
		page.ScrollBarThickness = 5
		page.ScrollBarImageColor3 = Theme.Divider
		page.Visible = false
		page.Parent = pages

		local list = newListParent(page)

		local tab = {
			Name = tabName,
			Button = btn,
			Page = page,
			_list = list,
			Mount = function(_, schema)
				return mountList(list, schema)
			end,
		}

		local function selectThis()
			applyTabSelection(tab)
		end

		btn.MouseButton1Click:Connect(selectThis)
		table.insert(self._tabs, tab)

		if #self._tabs == 1 then
			selectThis()
		end

		return tab
	end

	function windowApi:Destroy()
		closeDropdownMenus()
		if menuKeyConn then
			menuKeyConn:Disconnect()
			menuKeyConn = nil
		end
		if introConnection then
			introConnection:Disconnect()
			introConnection = nil
		end
		for _, conn in dragConnections do
			conn:Disconnect()
		end
		if self.Gui then
			self.Gui:Destroy()
		end
	end

	return windowApi
end

-- --- bootstrap local ---
print("[iFrame local]", iFrame.VERSION)

local function devLog(name: string, value: any)
	print(string.lower(name) .. " " .. tostring(value))
end

local win = iFrame.window({
	name = "eyeLib",
	configIcon = "lucide:settings",
	menuKey = Enum.KeyCode.RightControl,
})

local tabMain = win:CreateTab({ name = "Main", icon = "lucide:sliders-horizontal" })
local handles = tabMain:Mount({
	{ type = "section", title = "Acciones" },
	{
		type = "button",
		title = "Probar",
		callback = function()
			devLog("Probar", "click")
		end,
	},
	{
		type = "toggle",
		title = "Auto",
		default = true,
		id = "auto",
		callback = function(on)
			devLog("Auto", on)
		end,
	},
	{
		type = "slider",
		title = "Velocidad",
		min = 1,
		max = 20,
		default = 8,
		id = "speed",
		callback = function(value)
			devLog("Velocidad", value)
		end,
	},
	{ type = "section", title = "Datos" },
	{
		type = "dropdown",
		title = "Modo",
		options = { "Normal", "Rapido", "Seguro" },
		default = "Normal",
		callback = function(value)
			devLog("Modo", value)
		end,
	},
	{
		type = "input",
		title = "Nombre",
		placeholder = "Escribe aqui...",
		callback = function(text)
			devLog("Nombre", text)
		end,
	},
	{
		type = "color",
		title = "Tema",
		default = Color3.fromRGB(88, 148, 255),
		callback = function(c)
			devLog(
				"Tema",
				string.format("#%02X%02X%02X", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
			)
		end,
	},
	{ type = "status", title = "Estado", text = "Listo", id = "status" },
})

local tabExtra = win:CreateTab({ name = "Extra", icon = "lucide:layers" })
tabExtra:Mount({
	{ type = "text", text = "Segunda pestana. Mas controles aqui." },
	{
		type = "button",
		title = "Actualizar estado",
		callback = function()
			if handles.status then
				handles.status:SetText("OK " .. os.date("%X"))
			end
		end,
	},
})

-- Rejoin dev (no forma parte de iFrame)
do
	local TeleportService = game:GetService("TeleportService")
	local localPlayer = Players.LocalPlayer

	local rejoinGui = Instance.new("ScreenGui")
	rejoinGui.Name = "DevRejoin"
	rejoinGui.ResetOnSpawn = false
	rejoinGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	rejoinGui.Parent = getGuiParent()

	local rejoinButton = Instance.new("TextButton")
	rejoinButton.Name = "Rejoin"
	rejoinButton.Size = UDim2.fromOffset(88, 34)
	rejoinButton.Position = UDim2.fromOffset(12, 12)
	rejoinButton.BackgroundColor3 = Color3.fromRGB(42, 42, 48)
	rejoinButton.BorderSizePixel = 0
	rejoinButton.Font = Enum.Font.GothamMedium
	rejoinButton.TextSize = 14
	rejoinButton.TextColor3 = Color3.fromRGB(235, 235, 235)
	rejoinButton.Text = "Rejoin"
	rejoinButton.Parent = rejoinGui

	local rejoinCorner = Instance.new("UICorner")
	rejoinCorner.CornerRadius = UDim.new(0, 6)
	rejoinCorner.Parent = rejoinButton

	rejoinButton.MouseButton1Click:Connect(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
	end)
end
