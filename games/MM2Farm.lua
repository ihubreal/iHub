--[[ MM2 Farm | Place 142823291 | Build 66 | Starlight (Nebula oficial vía HttpGet) ]]

print("[MM2 Farm] build 66 starting...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local PhysicsService = game:GetService("PhysicsService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local VirtualUser = nil
pcall(function()
	VirtualUser = game:GetService("VirtualUser")
end)

local LocalPlayer = Players.LocalPlayer
local SCRIPT_STARTED_AT = os.clock()

local function getLocalPlayer()
	local lp = Players.LocalPlayer
	if not lp or lp.Parent == nil then
		return nil
	end
	return lp
end

-- Puente I-Hub (monta toggles/sliders como antes). Starlight = repo oficial Nebula, no iHub.
local function createIHubUi()
	local IHubUi = {}
	local STARLIGHT_URL = "https://raw.githubusercontent.com/Nebula-Softworks/Starlight-Interface-Suite/master/Source.lua"
	local ICONS_URL = "https://raw.githubusercontent.com/Nebula-Softworks/Nebula-Icon-Library/master/Loader.luau"
	IHubUi.Flags = {}

	local NebulaIcons = nil
	local function loadIconPacks()
		if NebulaIcons ~= nil then
			return
		end
		local compile = loadstring or load
		pcall(function()
			local mod = compile(game:HttpGet(ICONS_URL))()
			if type(mod) == "table" then
				NebulaIcons = mod
			elseif type(mod) == "function" then
				NebulaIcons = mod()
			end
		end)
	end

	local ICON_ALIASES = {
		coins = { "paid", "Material" },
		package = { "inventory_2", "Material" },
	}

	function IHubUi.resolveIcon(icon)
		if type(icon) == "number" then
			return icon
		end
		if type(icon) ~= "string" or icon == "" then
			return nil
		end
		loadIconPacks()
		local alias = ICON_ALIASES[icon:lower()]
		if alias and NebulaIcons and NebulaIcons.GetIcon then
			local ok, asset = pcall(function()
				return NebulaIcons:GetIcon(alias[1], alias[2])
			end)
			if ok and asset then
				return asset
			end
		end
		return nil
	end

	function IHubUi.load()
		local compile = loadstring or load
		local ok, Starlight = pcall(function()
			return compile(game:HttpGet(STARLIGHT_URL))()
		end)
		if not ok or type(Starlight) ~= "table" then
			error("[MM2 Farm] Starlight oficial no compilo.")
		end
		return Starlight
	end

	local function setFlag(flagName, value)
		if type(flagName) == "string" and flagName ~= "" then
			IHubUi.Flags[flagName] = { CurrentValue = value }
		end
	end

	local function unwrapDropdownChoice(selected)
		if type(selected) == "table" then
			return selected[1]
		end
		return selected
	end

	function IHubUi.statusLabel(group, title, initialText)
		local index = "status_" .. tostring(title):gsub("%s+", "_")
		local element = group:CreateParagraph({
			Name = title,
			Content = initialText or "",
		}, index)
		return {
			SetText = function(_, text)
				element:Set({ Name = title, Content = text or "" })
			end,
		}
	end

	local function mountOne(group, item, handles)
		local kind = item.type
		local flag = item.flag
		local index = flag or ("el_" .. tostring(item.name):gsub("%s+", "_"))

		if kind == "text" then
			if type(item.name) == "string" and item.name ~= "" then
				group:CreateParagraph({ Name = item.name, Content = item.text or "" }, index .. "_p")
			end
			return
		end
		if kind == "toggle" then
			setFlag(flag, item.value)
			group:CreateToggle({
				Name = item.name,
				CurrentValue = item.value == true,
				Callback = function(value)
					setFlag(flag, value)
					if item.callback then
						item.callback(value)
					end
				end,
			}, index)
			return
		end
		if kind == "slider" then
			setFlag(flag, item.value)
			group:CreateSlider({
				Name = item.name,
				Range = item.range,
				Increment = item.increment or 1,
				CurrentValue = item.value,
				Callback = function(value)
					setFlag(flag, value)
					if item.callback then
						item.callback(value)
					end
				end,
			}, index)
			return
		end
		if kind == "dropdown" then
			local initial = item.value
			if type(initial) == "string" then
				initial = { initial }
			end
			setFlag(flag, unwrapDropdownChoice(initial))
			local label = group:CreateLabel({ Name = item.name }, index .. "_lbl")
			label:AddDropdown({
				Options = item.options or {},
				CurrentOption = initial,
				Callback = function(selected)
					local choice = unwrapDropdownChoice(selected)
					setFlag(flag, choice)
					if item.callback then
						item.callback(choice)
					end
				end,
			}, index)
			return
		end
		if kind == "input" then
			setFlag(flag, item.value or "")
			group:CreateInput({
				Name = item.name,
				PlaceholderText = item.placeholder or "",
				CurrentValue = item.value or "",
				RemoveTextOnFocus = false,
				Callback = function(value)
					setFlag(flag, value)
					if item.callback then
						item.callback(value)
					end
				end,
			}, index)
			return
		end
		if kind == "button" then
			group:CreateButton({
				Name = item.name,
				Callback = function()
					if item.callback then
						item.callback()
					end
				end,
			}, index)
			return
		end
		if kind == "status" then
			local handle = IHubUi.statusLabel(group, item.name, item.text)
			if item.id and handles then
				handles[item.id] = handle
			end
		end
	end

	function IHubUi.mount(tabApi, items)
		local handles = {}
		local group = tabApi._group
		for _, item in items do
			if item.type == "section" then
				tabApi._nextSectionIndex = tabApi._nextSectionIndex + 1
				local col = item.column or 1
				if col < 1 then
					col = 1
				end
				if tabApi._columns and col > tabApi._columns then
					col = tabApi._columns
				end
				group = tabApi._tab:CreateGroupbox({
					Name = item.name,
					Column = col,
				}, tabApi._tabKey .. "_s" .. tostring(tabApi._nextSectionIndex))
				tabApi._group = group
			else
				if not group then
					group = tabApi._tab:CreateGroupbox({ Name = "Options", Column = 1 }, tabApi._tabKey .. "_main")
					tabApi._group = group
				end
				mountOne(group, item, handles)
			end
		end
		return handles
	end

	function IHubUi.window(Starlight, options)
		options = options or {}
		IHubUi._lastStarlight = Starlight
		local configFolder = options.customFolder or options.fileName or "I-Hub"
		local win = Starlight:CreateWindow({
			Name = options.name or "I-Hub",
			Subtitle = options.subtitle or "",
			Icon = IHubUi.resolveIcon(options.icon),
			LoadingEnabled = false,
			BuildWarnings = false,
			InterfaceAdvertisingPrompts = false,
			NotifyOnCallbackError = false,
			KeySystem = { Enabled = false },
			FileSettings = { ConfigFolder = configFolder },
		})
		local section = win:CreateTabSection("Main")
		local tabCounter = 0
		local api = { _win = win, _section = section }
		function api:CreateTab(cfg)
			cfg = cfg or {}
			tabCounter = tabCounter + 1
			local tabKey = "tab_" .. tostring(cfg.name or tabCounter):gsub("%s+", "_"):lower()
			local columns = cfg.columns or 1
			if columns < 1 then
				columns = 1
			end
			if columns > 3 then
				columns = 3
			end
			local tab = section:CreateTab({
				Name = cfg.name or "Tab",
				Columns = columns,
				Icon = IHubUi.resolveIcon(cfg.icon),
			}, tabKey)
			return {
				_tab = tab,
				_group = nil,
				_tabKey = tabKey,
				_columns = columns,
				_nextSectionIndex = 0,
			}
		end
		return api
	end

	return IHubUi
end

local IHubUi = createIHubUi()

local Starlight
local slOk, slErr = pcall(function()
	Starlight = IHubUi.load()
end)
if not slOk or type(Starlight) ~= "table" then
	warn("[MM2 Farm] Starlight no cargo:", slErr)
	return
end

local Window = IHubUi.window(Starlight, {
	name = "MM2 Farm",
	subtitle = "Coins",
	customFolder = "MM2-Farm",
	fileName = "MM2Farm",
})
print("[MM2 Farm] UI lista.")

local checkerSettings = {
	enabled = true,
}

local perfSettings = {
	disable3dRender = false,
	backdropStyle = 1,
	antiAfk = true,
	fullscreenOverlay = false,
	autoRejoinOnKick = true,
	rejoinSameServer = false,
}

local rejoinRuntime = {
	lastJobId = "",
	inProgress = false,
	lastAttemptAt = 0,
	ourTeleport = false,
}

local REJOIN_ATTEMPT_COOLDOWN = 4
local REJOIN_RETRY_COUNT = 15
local REJOIN_RETRY_INTERVAL = 0.35

local NO_RENDER_BACKDROP_STYLES = {
	{ name = "Charcoal", color = Color3.fromRGB(14, 14, 16) },
	{ name = "Black", color = Color3.fromRGB(0, 0, 0) },
	{ name = "Dark blue", color = Color3.fromRGB(10, 12, 22) },
}

local inventoryCoins = nil

local OVERLAY_TOGGLE_KEY = Enum.KeyCode.K
local OVERLAY_CONTEXT_ACTION = "MM2Farm_OverlayToggle"

local ANTI_AFK_PULSE_INTERVAL = 480

local antiAfkIdledConn: RBXScriptConnection? = nil
local antiAfkLoopStarted = false

local function pulseAntiAfk()
	if not perfSettings.antiAfk then
		return
	end
	if VirtualUser then
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
		return
	end
	local camera = Workspace.CurrentCamera
	if camera then
		pcall(function()
			camera.CFrame = camera.CFrame * CFrame.Angles(0, 0.0001, 0)
		end)
	end
end

local function setAntiAfkEnabled(enabled)
	perfSettings.antiAfk = enabled == true

	if antiAfkIdledConn then
		antiAfkIdledConn:Disconnect()
		antiAfkIdledConn = nil
	end

	if not perfSettings.antiAfk then
		return
	end

	antiAfkIdledConn = LocalPlayer.Idled:Connect(function()
		pulseAntiAfk()
	end)

	if not antiAfkLoopStarted then
		antiAfkLoopStarted = true
		task.spawn(function()
			while true do
				task.wait(ANTI_AFK_PULSE_INTERVAL)
				pulseAntiAfk()
			end
		end)
	end

	pulseAntiAfk()
end

local function kickMessageLooksLikeDisconnect(message)
	local text = string.lower(tostring(message))
	if text:find("you have been kicked", 1, true) then
		return true
	end
	if text:find("kicked by this experience", 1, true) then
		return true
	end
	if text:find("kicked from this experience", 1, true) then
		return true
	end
	if text:find("you were kicked", 1, true) then
		return true
	end
	if text:find("disconnected from the experience", 1, true) then
		return true
	end
	if text:find("invalid position", 1, true) then
		return true
	end
	if text:find("error code: 267", 1, true) then
		return true
	end
	if text:find("disconnected", 1, true) and text:find("kick", 1, true) then
		return true
	end
	return false
end

local function performRejoinTeleport(): boolean
	local lp = Players.LocalPlayer
	if not lp then
		return false
	end
	rejoinRuntime.ourTeleport = true
	local ok = pcall(function()
		if perfSettings.rejoinSameServer and rejoinRuntime.lastJobId ~= "" then
			TeleportService:TeleportToPlaceInstance(game.PlaceId, rejoinRuntime.lastJobId, lp)
		else
			TeleportService:Teleport(game.PlaceId, lp)
		end
	end)
	return ok
end

local function tryAutoRejoin(trigger)
	if not perfSettings.autoRejoinOnKick then
		return
	end
	local now = os.clock()
	if rejoinRuntime.inProgress then
		return
	end
	if now - rejoinRuntime.lastAttemptAt < REJOIN_ATTEMPT_COOLDOWN then
		return
	end
	rejoinRuntime.inProgress = true
	rejoinRuntime.lastAttemptAt = now
	warn("[MM2 Farm] Auto rejoin:", tostring(trigger))

	if farmSettings then
		farmSettings.autofarm = false
	end

	performRejoinTeleport()

	task.spawn(function()
		for _ = 1, REJOIN_RETRY_COUNT do
			if not perfSettings.autoRejoinOnKick then
				rejoinRuntime.inProgress = false
				return
			end
			if performRejoinTeleport() then
				return
			end
			task.wait(REJOIN_RETRY_INTERVAL)
		end
		rejoinRuntime.inProgress = false
		rejoinRuntime.ourTeleport = false
		warn("[MM2 Farm] Auto rejoin: no se pudo iniciar teleport (reintentos agotados).")
	end)
end

local function initAutoRejoinWatch()
	rejoinRuntime.lastJobId = tostring(game.JobId)

	local lp = Players.LocalPlayer
	if lp then
		pcall(function()
			lp.OnTeleport:Connect(function(state)
				if state == Enum.TeleportState.Started or state == Enum.TeleportState.InProgress then
					rejoinRuntime.ourTeleport = true
				end
			end)
		end)
	end

	pcall(function()
		TeleportService.LocalPlayerTeleportFailed:Connect(function(result, errorMessage)
			rejoinRuntime.ourTeleport = false
			rejoinRuntime.inProgress = false
			rejoinRuntime.lastAttemptAt = 0
			tryAutoRejoin(errorMessage or tostring(result))
		end)
	end)

	pcall(function()
		local LogService = game:GetService("LogService")
		LogService.MessageOut:Connect(function(message, _messageType)
			if kickMessageLooksLikeDisconnect(message) then
				tryAutoRejoin(message)
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		if player ~= Players.LocalPlayer then
			return
		end
		if rejoinRuntime.ourTeleport then
			return
		end
		tryAutoRejoin("PlayerRemoving")
	end)

	if typeof(hookmetamethod) == "function" and typeof(getnamecallmethod) == "function" then
		local oldNamecall
		oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
			local method = getnamecallmethod()
			if method == "Kick" then
				local who = Players.LocalPlayer
				if who and (self == who or self == LocalPlayer) then
					task.defer(function()
						tryAutoRejoin("Kick")
					end)
				end
			end
			return oldNamecall(self, ...)
		end)
	end
end

local farmSettings = {
	autofarm = false,
	cooldown = 1,
	webhookUrl = "",
	depthBelow = 7,
	horizontalSpeed = 16,
	riseSpeed = 18,
	sinkSpeed = 20,
	horizontalArrive = 1.5,
	surfaceHold = 0.85,
	collectArrive = 0.85,
	autoResetOnFullBag = true,
	avoidMurdererCoins = true,
	murdererAvoidRadius = 26,
	diveOnRoundStart = true,
}

local partySettings = {
	enabled = true,
	groupKey = "default",
	serverHopIfTogether = true,
	deferResetForParty = true,
	hopSameRegion = true,
}

local PARTY_STALE_SECONDS = 60
local PARTY_HOP_COOLDOWN = 28
local PARTY_TICK_INTERVAL = 2
local PARTY_HOP_STARTUP_DELAY = 25
local PARTY_HOP_STUCK_SECONDS = 15
local PARTY_REGISTRY_FILE = "party.json"

local partyRuntime = {
	lastPublishAt = 0,
	lastHopAttempt = 0,
	hopInProgress = false,
	hopStartedAt = 0,
	lastTickAt = 0,
	lastRegistryPeerCount = 0,
	hopRegionPrefix = nil :: string?,
}

type CrateOption = {
	id: string,
	crateType: string,
	currency: string,
	label: string,
	cost: number,
}

local CRATE_OPTIONS: { CrateOption } = {
	{ id = "MysteryBox2", crateType = "MysteryBox", currency = "Coins", label = "Mystery Box 2", cost = 1000 },
	{ id = "MysteryBox", crateType = "MysteryBox", currency = "Coins", label = "Mystery Box", cost = 1000 },
	{ id = "ChromaBox", crateType = "MysteryBox", currency = "Coins", label = "Chroma Box", cost = 1000 },
	{ id = "ChristmasBox", crateType = "MysteryBox", currency = "Coins", label = "Christmas Box", cost = 1000 },
	{ id = "Candies2023", crateType = "Eggs", currency = "Coins", label = "Candies Egg", cost = 1000 },
	{ id = "Pumpkin2023", crateType = "Eggs", currency = "Coins", label = "Pumpkin Egg", cost = 1000 },
}

local autoOpenSettings = {
	enabled = false,
	crateIndex = 1,
	cooldown = 1.25,
	minCoins = 1000,
}

local autoOpenRuntime = {
	lastOpenAt = 0,
}

local autoOpenStatusLabel = nil
local autoOpenStatusText = ""

type BagCountEntry = {
	current: number,
	max: number,
	lastPickup: number?,
}

local bagCounts: { [string]: BagCountEntry } = {}
local mapLabel = nil
local inventoryLabel = nil
local roundLabel = nil
local farmStatusLabel = nil
local partyStatusLabel = nil
local clock = 0

local farmRuntime = {
	phase = "dive",
	targetCoin = nil,
	diveTargetY = nil,
	lastWebhookThousand = 0,
	webhookInventorySynced = false,
	peekUntil = 0,
	pauseUntil = 0,
	lastResetAttempt = 0,
	bagFullResetDone = false,
	waitingNextRound = false,
	coinCache = nil,
	coinCacheAt = 0,
	murderPosCache = nil,
	murderPosAt = 0,
	lastNoclipPartRefresh = 0,
	lastTouchCollect = 0,
	roundStartNoclipUntil = 0,
	roundStartFastSinkUntil = 0,
	pendingRoundStartDive = false,
	localRole = nil,
}

local savedPartPhysics = {}
local savedHumanoid = nil

local apply3dRenderingSetting
local setFullscreenOverlayEnabled
local publishPartyState
local refreshFullscreenOverlay
local getOverlayPartyText
local refreshNoRenderBackdropColor

local fullscreenOverlayRefs: { [string]: TextLabel } = {}

local function initMm2FarmOverlay()
	local OVERLAY_GUI_NAME = "MM2Farm_FullOverlay"
	local fullscreenOverlayGui: ScreenGui? = nil
	local suppressedGuiEnabled: { [ScreenGui]: boolean } = {}
	local overlayGuiWatchConn: RBXScriptConnection? = nil

	local noRenderBackdropGui: ScreenGui? = nil

	local function getNoRenderBackdropColor()
		local style = NO_RENDER_BACKDROP_STYLES[perfSettings.backdropStyle]
		if style then
			return style.color
		end
		return NO_RENDER_BACKDROP_STYLES[1].color
	end

	local function ensureNoRenderBackdrop()
		if noRenderBackdropGui and noRenderBackdropGui.Parent then
			return noRenderBackdropGui
		end

		local playerGui = LocalPlayer:WaitForChild("PlayerGui")
		local gui = Instance.new("ScreenGui")
		gui.Name = "MM2Farm_NoRenderBackdrop"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = -1000
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = playerGui

		local frame = Instance.new("Frame")
		frame.Name = "Backdrop"
		frame.Size = UDim2.fromScale(1, 1)
		frame.Position = UDim2.fromOffset(0, 0)
		frame.BackgroundColor3 = getNoRenderBackdropColor()
		frame.BackgroundTransparency = 0
		frame.BorderSizePixel = 0
		frame.Active = false
		frame.ZIndex = 0
		frame.Parent = gui

		noRenderBackdropGui = gui
		return gui
	end

	refreshNoRenderBackdropColor = function()
		if not noRenderBackdropGui then
			return
		end
		local frame = noRenderBackdropGui:FindFirstChild("Backdrop")
		if frame and frame:IsA("Frame") then
			frame.BackgroundColor3 = getNoRenderBackdropColor()
		end
		if fullscreenOverlayGui and fullscreenOverlayGui.Enabled then
			local overlayBackdrop = fullscreenOverlayGui:FindFirstChild("Backdrop")
			if overlayBackdrop and overlayBackdrop:IsA("Frame") then
				overlayBackdrop.BackgroundColor3 = getNoRenderBackdropColor()
			end
		end
	end

	local function setNoRenderBackdropVisible(visible: boolean)
		if visible then
			local gui = ensureNoRenderBackdrop()
			refreshNoRenderBackdropColor()
			gui.Enabled = true
		elseif noRenderBackdropGui then
			noRenderBackdropGui.Enabled = false
		end
	end

	local function formatOverlayRuntime()
		local elapsed = math.max(0, math.floor(os.clock() - SCRIPT_STARTED_AT))
		local hours = math.floor(elapsed / 3600)
		local minutes = math.floor((elapsed % 3600) / 60)
		local seconds = elapsed % 60
		return string.format("%02d:%02d:%02d", hours, minutes, seconds)
	end

	local function getOverlayAccountName()
		local display = LocalPlayer.DisplayName
		if type(display) == "string" and display ~= "" then
			return display
		end
		return LocalPlayer.Name
	end

	local function getOverlayCoinsText()
		if inventoryCoins == nil then
			return "Coins: waiting..."
		end
		return "Coins: " .. tostring(inventoryCoins)
	end

	refreshFullscreenOverlay = function()
		if not fullscreenOverlayGui or not fullscreenOverlayGui.Enabled then
			return
		end
		local nameLabel = fullscreenOverlayRefs.account
		local coinsLabel = fullscreenOverlayRefs.coins
		local runtimeLabel = fullscreenOverlayRefs.runtime
		if nameLabel then
			nameLabel.Text = getOverlayAccountName()
		end
		if coinsLabel then
			coinsLabel.Text = getOverlayCoinsText()
		end
		if runtimeLabel then
			runtimeLabel.Text = "Runtime: " .. formatOverlayRuntime()
		end
		local partyLabel = fullscreenOverlayRefs.party
		if partyLabel and getOverlayPartyText then
			partyLabel.Text = getOverlayPartyText()
		end
	end

	local function ensureFullscreenOverlayGui()
		if fullscreenOverlayGui and fullscreenOverlayGui.Parent then
			return fullscreenOverlayGui
		end

		local playerGui = LocalPlayer:WaitForChild("PlayerGui")
		local gui = Instance.new("ScreenGui")
		gui.Name = OVERLAY_GUI_NAME
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = 100000
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Enabled = false
		gui.Parent = playerGui

		local backdrop = Instance.new("Frame")
		backdrop.Name = "Backdrop"
		backdrop.Size = UDim2.fromScale(1, 1)
		backdrop.BackgroundColor3 = getNoRenderBackdropColor()
		backdrop.BorderSizePixel = 0
		backdrop.ZIndex = 1
		backdrop.Parent = gui

		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 48)
		pad.PaddingLeft = UDim.new(0, 56)
		pad.Parent = backdrop

		local list = Instance.new("UIListLayout")
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Padding = UDim.new(0, 14)
		list.Parent = backdrop

		local function makeLine(name, layoutOrder, textSize)
			local label = Instance.new("TextLabel")
			label.Name = name
			label.LayoutOrder = layoutOrder
			label.Size = UDim2.new(1, -56, 0, textSize + 8)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.GothamBold
			label.TextSize = textSize
			label.TextColor3 = Color3.fromRGB(245, 245, 250)
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextYAlignment = Enum.TextYAlignment.Center
			label.Text = ""
			label.Parent = backdrop
			return label
		end

		fullscreenOverlayRefs.account = makeLine("Account", 1, 36)
		fullscreenOverlayRefs.coins = makeLine("Coins", 2, 28)
		fullscreenOverlayRefs.runtime = makeLine("Runtime", 3, 28)
		fullscreenOverlayRefs.party = makeLine("Party", 4, 20)
		fullscreenOverlayRefs.party.Font = Enum.Font.Gotham
		fullscreenOverlayRefs.party.TextColor3 = Color3.fromRGB(170, 175, 190)

		local hint = Instance.new("TextLabel")
		hint.Name = "Hint"
		hint.LayoutOrder = 99
		hint.AnchorPoint = Vector2.new(0.5, 1)
		hint.Position = UDim2.new(0.5, 0, 1, -24)
		hint.Size = UDim2.new(1, 0, 0, 20)
		hint.BackgroundTransparency = 1
		hint.Font = Enum.Font.Gotham
		hint.TextSize = 14
		hint.TextColor3 = Color3.fromRGB(140, 140, 150)
		hint.Text = "K: mostrar / ocultar overlay y menus"
		hint.Parent = backdrop

		fullscreenOverlayGui = gui
		refreshFullscreenOverlay()
		return gui
	end

	local function suppressOtherPlayerGuis()
		local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
		if not playerGui then
			return
		end
		for _, child in playerGui:GetChildren() do
			if not child:IsA("ScreenGui") then
				continue
			end
			if child == fullscreenOverlayGui or child.Name == "MM2Farm_NoRenderBackdrop" then
				continue
			end
			if suppressedGuiEnabled[child] == nil then
				suppressedGuiEnabled[child] = child.Enabled
			end
			child.Enabled = false
		end
	end

	local function restoreSuppressedPlayerGuis()
		for gui, wasEnabled in suppressedGuiEnabled do
			if gui.Parent and gui:IsA("ScreenGui") then
				gui.Enabled = wasEnabled
			end
		end
		table.clear(suppressedGuiEnabled)
	end

	local function bindOverlayGuiWatch()
		if overlayGuiWatchConn then
			return
		end
		local playerGui = LocalPlayer:WaitForChild("PlayerGui")
		overlayGuiWatchConn = playerGui.ChildAdded:Connect(function(child)
			if not perfSettings.fullscreenOverlay then
				return
			end
			if not child:IsA("ScreenGui") then
				return
			end
			if child == fullscreenOverlayGui or child.Name == "MM2Farm_NoRenderBackdrop" then
				return
			end
			if suppressedGuiEnabled[child] == nil then
				suppressedGuiEnabled[child] = child.Enabled
			end
			child.Enabled = false
		end)
	end

	local function unbindOverlayGuiWatch()
		if overlayGuiWatchConn then
			overlayGuiWatchConn:Disconnect()
			overlayGuiWatchConn = nil
		end
	end

	setFullscreenOverlayEnabled = function(enabled: boolean)
		perfSettings.fullscreenOverlay = enabled == true
		local gui = ensureFullscreenOverlayGui()
		if enabled then
			refreshNoRenderBackdropColor()
			local backdrop = gui:FindFirstChild("Backdrop")
			if backdrop and backdrop:IsA("Frame") then
				backdrop.BackgroundColor3 = getNoRenderBackdropColor()
			end
			suppressOtherPlayerGuis()
			bindOverlayGuiWatch()
			gui.Enabled = true
			refreshFullscreenOverlay()
		else
			gui.Enabled = false
			unbindOverlayGuiWatch()
			restoreSuppressedPlayerGuis()
		end
	end

	apply3dRenderingSetting = function()
		local disable = perfSettings.disable3dRender
		setNoRenderBackdropVisible(disable)

		local enabled = not disable
		local ok, err = pcall(function()
			RunService:Set3dRenderingEnabled(enabled)
		end)
		if not ok then
			perfSettings.disable3dRender = false
			setNoRenderBackdropVisible(false)
			warn("[MM2 Farm] Set3dRenderingEnabled no disponible en este cliente:", err)
		end
		return ok
	end
end

local refreshLabels

local function initMm2FarmCore()
	local function getActiveMapModel()
		for _, tagged in CollectionService:GetTagged("CurrentMap") do
			if not tagged:IsDescendantOf(Workspace) then
				continue
			end
			if tagged:IsA("Model") and tagged.Parent == Workspace then
				return tagged
			end
			local model = tagged:FindFirstAncestorWhichIsA("Model")
			if model and model.Parent == Workspace then
				return model
			end
		end
		return nil
	end

	local function isAvailableMapCoin(coin)
		if not coin or coin.Name ~= "Coin_Server" then
			return false
		end
		if coin:GetAttribute("CoinID") == nil then
			return false
		end
		local visual = coin:FindFirstChild("CoinVisual", true)
		if visual and visual:GetAttribute("Collected") == true then
			return false
		end
		return true
	end

	local COIN_CACHE_INTERVAL = 0.4
	local MURDER_POS_CACHE_INTERVAL = 0.3
	local FARM_NOCLIP_GROUP = "MM2FarmNoclip"
	local farmNoclipDescendantConn: RBXScriptConnection? = nil
	local farmNoclipPartConns: { [BasePart]: RBXScriptConnection } = {}
	local farmNoclipWasActive = false
	local farmNoclipGroupReady = false
	local TOUCH_COLLECT_INTERVAL = 0.14
	local FARM_UPDATE_INTERVAL = 1 / 60
	local FARM_MAX_DEPTH_BELOW_FLOOR = 6.5
	local FARM_SLIDER_MAX_HORIZONTAL = 50
	local FARM_SLIDER_MAX_VERTICAL = 70

	local function listAvailableCoins()
		local map = getActiveMapModel()
		if not map then
			return {}
		end
		local container = map:FindFirstChild("CoinContainer")
		if not container then
			return {}
		end
		local list = {}
		for _, child in container:GetChildren() do
			if isAvailableMapCoin(child) then
				table.insert(list, child)
			end
		end
		return list
	end

	local function getCachedAvailableCoins()
		local now = os.clock()
		if farmRuntime.coinCache == nil or now - farmRuntime.coinCacheAt >= COIN_CACHE_INTERVAL then
			farmRuntime.coinCache = listAvailableCoins()
			farmRuntime.coinCacheAt = now
		end
		return farmRuntime.coinCache
	end

	local function invalidateCoinCache()
		farmRuntime.coinCache = nil
		farmRuntime.coinCacheAt = 0
	end

	local function countCoinsInMapContainer()
		local list = listAvailableCoins()
		return #list, (#list == 0 and "no coins") or nil
	end

	local function getCoinWorldPosition(coin)
		if coin:IsA("BasePart") then
			return coin.Position
		end
		if coin:IsA("Model") then
			return coin:GetPivot().Position
		end
		local part = coin:FindFirstChildWhichIsA("BasePart", true)
		if part then
			return part.Position
		end
		return nil
	end

	local fireTouchInterest = (typeof(firetouchinterest) == "function" and firetouchinterest)
		or (typeof(FireTouchInterest) == "function" and FireTouchInterest)
		or nil

	local coinTouchPartCache = {}

	local function getCoinTouchPart(coin)
		if not coin then
			return nil
		end
		local cached = coinTouchPartCache[coin]
		if cached and cached.Parent then
			return cached
		end
		local targetPart = nil
		if coin:IsA("BasePart") then
			targetPart = coin
		else
			for _, desc in coin:GetDescendants() do
				if desc:IsA("BasePart") and (desc.Name == "Touch" or desc.Name == "Hitbox" or desc.Name == "Coin") then
					targetPart = desc
					break
				end
			end
			if not targetPart then
				targetPart = coin:FindFirstChildWhichIsA("BasePart", true)
			end
		end
		coinTouchPartCache[coin] = targetPart
		return targetPart
	end

	local function tryTouchCollectCoin(coin)
		if not fireTouchInterest or not coin or not isAvailableMapCoin(coin) then
			return
		end
		local now = os.clock()
		if now - farmRuntime.lastTouchCollect < TOUCH_COLLECT_INTERVAL then
			return
		end
		farmRuntime.lastTouchCollect = now

		local character = LocalPlayer.Character
		local targetPart = getCoinTouchPart(coin)
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root or not targetPart then
			return
		end
		if not root.Parent or not targetPart.Parent then
			return
		end
		if not root:IsDescendantOf(Workspace) or not targetPart:IsDescendantOf(Workspace) then
			return
		end
		if (root.Position - targetPart.Position).Magnitude > 14 then
			return
		end
		local ok = pcall(function()
			fireTouchInterest(root, targetPart, 0)
			fireTouchInterest(root, targetPart, 1)
		end)
		if not ok then
			coinTouchPartCache[coin] = nil
		end
	end

	local function isLocalPlayerAlive()
		local player = getLocalPlayer()
		if not player then
			return false
		end
		return player:GetAttribute("Alive") == true
	end

	local function hasNamedTool(parent, toolName)
		if not parent then
			return false
		end
		if parent:FindFirstChild(toolName) then
			return true
		end
		for _, child in parent:GetDescendants() do
			if child.Name == toolName then
				return true
			end
		end
		return false
	end

	local function isAlivePlayer(player)
		return player:GetAttribute("Alive") == true
	end

	local function playerHasKnife(player)
		local workspacePlayers = Workspace:FindFirstChild("Players")
		local playerFolder = workspacePlayers and workspacePlayers:FindFirstChild(player.Name)
		local backpack = player:FindFirstChildOfClass("Backpack")
		local character = player.Character
		return hasNamedTool(playerFolder, "Knife")
			or hasNamedTool(backpack, "Knife")
			or hasNamedTool(character, "Knife")
	end

	local function getMurdererPlayer()
		for _, player in Players:GetPlayers() do
			if player == LocalPlayer then
				continue
			end
			if not isAlivePlayer(player) then
				continue
			end
			if not playerHasKnife(player) then
				continue
			end
			if not player.Character then
				continue
			end
			return player
		end
		return nil
	end

	local function getMurdererRootPosition()
		local murderer = getMurdererPlayer()
		if not murderer then
			return nil
		end
		local character = murderer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			return root.Position
		end
		return nil
	end

	local function getMurdererRootPositionCached()
		local now = os.clock()
		if farmRuntime.murderPosCache ~= nil and now - farmRuntime.murderPosAt < MURDER_POS_CACHE_INTERVAL then
			return farmRuntime.murderPosCache
		end
		farmRuntime.murderPosAt = now
		farmRuntime.murderPosCache = getMurdererRootPosition()
		return farmRuntime.murderPosCache
	end

	local function isCoinSafeFromMurderer(coinPosition)
		if not farmSettings.avoidMurdererCoins then
			return true
		end
		if playerHasKnife(LocalPlayer) then
			return true
		end

		local murderPos = getMurdererRootPositionCached()
		if not murderPos then
			return true
		end

		local radius = farmSettings.murdererAvoidRadius
		if radius <= 0 then
			return true
		end

		return (coinPosition - murderPos).Magnitude > radius
	end

	local function getCharacterRoot()
		local player = getLocalPlayer()
		if not player then
			return nil
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			return root
		end
		return nil
	end

	local function ensureLinearVelocity(root)
		local att = root:FindFirstChild("MM2FarmAtt")
		if not att then
			att = Instance.new("Attachment")
			att.Name = "MM2FarmAtt"
			att.Parent = root
		end

		local mover = root:FindFirstChild("MM2FarmLV")
		if not mover then
			mover = Instance.new("LinearVelocity")
			mover.Name = "MM2FarmLV"
			mover.Attachment0 = att
			mover.RelativeTo = Enum.ActuatorRelativeTo.World
			mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
			mover.Parent = root
		end

		local force = math.clamp(root.AssemblyMass * 1200, 8000, 50000)
		mover.MaxForce = force

		return mover
	end

	local function clearFarmStabilizer(root)
		local align = root:FindFirstChild("MM2FarmAlign")
		if align then
			align:Destroy()
		end
	end

	local function clearFarmMover()
		local root = getCharacterRoot()
		if not root then
			return
		end
		local mover = root:FindFirstChild("MM2FarmLV")
		if mover then
			mover:Destroy()
		end
		clearFarmStabilizer(root)
		local att = root:FindFirstChild("MM2FarmAtt")
		if att then
			att:Destroy()
		end
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end

	local function stabilizeFarmRoot(root)
		root.AssemblyAngularVelocity = Vector3.zero
	end

	local function ensureFarmStabilizer(root)
		local att = root:FindFirstChild("MM2FarmAtt")
		if not att then
			att = Instance.new("Attachment")
			att.Name = "MM2FarmAtt"
			att.Parent = root
		end

		local align = root:FindFirstChild("MM2FarmAlign")
		if not align then
			align = Instance.new("AlignOrientation")
			align.Name = "MM2FarmAlign"
			align.Mode = Enum.OrientationAlignmentMode.OneAttachment
			align.Attachment0 = att
			align.RigidityEnabled = false
			align.Responsiveness = 45
			align.MaxTorque = 6000
			align.Parent = root
		end
		align.CFrame = CFrame.identity
	end

	local function applyFarmHumanoidState(humanoid, softOnly)
		if savedHumanoid == nil then
			savedHumanoid = {
				PlatformStand = humanoid.PlatformStand,
				AutoRotate = humanoid.AutoRotate,
			}
		end
		humanoid.AutoRotate = false
		if softOnly then
			return
		end
		humanoid.PlatformStand = true
		pcall(function()
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		end)
	end

	local function getMapFloorY()
		local map = getActiveMapModel()
		if not map then
			return nil
		end
		local ok, cf, size = pcall(function()
			return map:GetBoundingBox()
		end)
		if ok and cf and size then
			return cf.Position.Y - size.Y * 0.5
		end
		return nil
	end

	local function getEffectiveDepthBelow()
		return math.min(farmSettings.depthBelow, FARM_MAX_DEPTH_BELOW_FLOOR)
	end

	local function getSafeMinFarmY(referenceY)
		local destroyHeight = Workspace.FallenPartsDestroyHeight + 45
		local depth = getEffectiveDepthBelow()
		local floorY = getMapFloorY()
		local fromMap = floorY and (floorY - depth) or nil

		if referenceY then
			if not fromMap or fromMap > referenceY - 1 then
				fromMap = referenceY - depth
			end
		elseif not fromMap then
			return destroyHeight
		end

		return math.max(fromMap, destroyHeight)
	end

	local function clampFarmY(y, referenceY)
		return math.max(y, getSafeMinFarmY(referenceY))
	end

	local function computeDiveTargetY(referenceY)
		local floorY = getMapFloorY()
		local target = floorY and (floorY - getEffectiveDepthBelow()) or (referenceY - getEffectiveDepthBelow())
		return clampFarmY(target, referenceY)
	end

	local function computeRoundStartHideTargetY(referenceY)
		local shallow = math.clamp(getEffectiveDepthBelow() * 0.55, 2.5, 4.5)
		local floorY = getMapFloorY()
		local target = floorY and (floorY - shallow) or (referenceY - math.min(5, getEffectiveDepthBelow()))
		return clampFarmY(target, referenceY)
	end

	local function clampFarmVelocity(velocity)
		local maxH = math.clamp(farmSettings.horizontalSpeed, 0, FARM_SLIDER_MAX_HORIZONTAL)
		local maxV = math.clamp(math.max(farmSettings.sinkSpeed, farmSettings.riseSpeed), 0, FARM_SLIDER_MAX_VERTICAL)
		local flat = Vector3.new(velocity.X, 0, velocity.Z)
		if flat.Magnitude > maxH then
			flat = flat.Unit * maxH
		end
		local y = math.clamp(velocity.Y, -maxV, maxV)
		return Vector3.new(flat.X, y, flat.Z)
	end

	local function isRoundStartDiveWindow()
		return farmRuntime.pendingRoundStartDive or farmRuntime.roundStartNoclipUntil > os.clock()
	end

	local function shouldDisableCoinTouchForHide()
		if not farmRuntime.pendingRoundStartDive and farmRuntime.roundStartNoclipUntil <= os.clock() then
			return false
		end
		local root = getCharacterRoot()
		if not root then
			return true
		end
		local floorY = getMapFloorY()
		if floorY and root.Position.Y > floorY - 2 then
			return true
		end
		local target = farmRuntime.diveTargetY
		if target and root.Position.Y > target + 2 then
			return true
		end
		return false
	end

	local function ensureFarmNoclipCollisionGroup()
		if farmNoclipGroupReady then
			return
		end
		local ok = pcall(function()
			if not PhysicsService:IsCollisionGroupRegistered(FARM_NOCLIP_GROUP) then
				PhysicsService:RegisterCollisionGroup(FARM_NOCLIP_GROUP)
			end
			PhysicsService:CollisionGroupSetCollidable(FARM_NOCLIP_GROUP, "Default", false)
			local groups = PhysicsService:GetRegisteredCollisionGroups()
			for _, entry in groups do
				local groupName = typeof(entry) == "table" and entry.name or entry
				if type(groupName) == "string" and groupName ~= FARM_NOCLIP_GROUP then
					PhysicsService:CollisionGroupSetCollidable(FARM_NOCLIP_GROUP, groupName, false)
				end
			end
		end)
		if ok then
			farmNoclipGroupReady = true
		end
	end

	local function isFarmNoclipDesired()
		if farmRuntime.waitingNextRound then
			return false
		end
		if farmSettings.autofarm then
			return isLocalPlayerAlive()
		end
		if farmSettings.diveOnRoundStart and isRoundStartDiveWindow() then
			return true
		end
		return false
	end

	local function clearFarmNoclipPartConns()
		for _, conn in farmNoclipPartConns do
			conn:Disconnect()
		end
		table.clear(farmNoclipPartConns)
	end

	local function bindFarmNoclipPart(part: BasePart)
		if farmNoclipPartConns[part] then
			return
		end
		farmNoclipPartConns[part] = part:GetPropertyChangedSignal("CanCollide"):Connect(function()
			if not isFarmNoclipDesired() then
				return
			end
			if part.CanCollide then
				part.CanCollide = false
			end
		end)
	end

	local function applyFarmNoclipToPart(part: BasePart, enableCoinTouch: boolean)
		if savedPartPhysics[part] == nil then
			savedPartPhysics[part] = {
				CanCollide = part.CanCollide,
				CanTouch = part.CanTouch,
				CollisionGroup = part.CollisionGroup,
			}
		end
		part.CanCollide = false
		part.CanTouch = enableCoinTouch
		pcall(function()
			part.CollisionGroup = FARM_NOCLIP_GROUP
		end)
		bindFarmNoclipPart(part)
	end

	local function refreshFarmNoclipParts(character, enableCoinTouch)
		if not character then
			return
		end
		ensureFarmNoclipCollisionGroup()
		if enableCoinTouch == nil then
			enableCoinTouch = not shouldDisableCoinTouchForHide()
		end
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") then
				applyFarmNoclipToPart(part, enableCoinTouch)
			end
		end
	end

	local function stopFarmNoclipWatch()
		if farmNoclipDescendantConn then
			farmNoclipDescendantConn:Disconnect()
			farmNoclipDescendantConn = nil
		end
	end

	local function startFarmNoclipWatch(character)
		stopFarmNoclipWatch()
		if not character then
			return
		end
		farmNoclipDescendantConn = character.DescendantAdded:Connect(function(desc)
			if not isFarmNoclipDesired() then
				return
			end
			if desc:IsA("BasePart") then
				task.defer(function()
					if desc.Parent and isFarmNoclipDesired() then
						local touch = not shouldDisableCoinTouchForHide()
						applyFarmNoclipToPart(desc, touch)
					end
				end)
			end
		end)
	end

	local function applyFarmNoclipFrame()
		local character = LocalPlayer.Character
		if not character then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local softOnly = shouldDisableCoinTouchForHide() and not farmSettings.autofarm
			applyFarmHumanoidState(humanoid, softOnly)
		end

		refreshFarmNoclipParts(character)

		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end

	local function restoreFarmNoclip()
		stopFarmNoclipWatch()
		clearFarmNoclipPartConns()
		for part, state in savedPartPhysics do
			if part.Parent and state then
				part.CanCollide = state.CanCollide
				part.CanTouch = state.CanTouch
				pcall(function()
					part.CollisionGroup = state.CollisionGroup or "Default"
				end)
			end
		end
		table.clear(savedPartPhysics)

		local player = getLocalPlayer()
		local character = player and player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and savedHumanoid then
			humanoid.PlatformStand = savedHumanoid.PlatformStand
			humanoid.AutoRotate = savedHumanoid.AutoRotate
		end
		savedHumanoid = nil
	end

	local function tickFarmNoclipEngine()
		local desired = isFarmNoclipDesired()
		if not desired then
			if farmNoclipWasActive then
				restoreFarmNoclip()
			end
			farmNoclipWasActive = false
			return
		end

		farmNoclipWasActive = true
		local player = getLocalPlayer()
		local character = player and player.Character
		if not character then
			return
		end
		if not farmNoclipDescendantConn then
			startFarmNoclipWatch(character)
		end
		applyFarmNoclipFrame()
	end

	local function armRoundStartProtection()
		local now = os.clock()
		farmRuntime.roundStartNoclipUntil = now + 5
		farmRuntime.roundStartFastSinkUntil = now + 3
	end

	local function getFarmSinkSpeed()
		local speed = farmSettings.sinkSpeed
		if farmRuntime.roundStartFastSinkUntil > os.clock() then
			speed *= 1.2
		end
		return speed
	end

	local function setFarmVelocity(velocity)
		local root = getCharacterRoot()
		if not root then
			return
		end

		local character = root.Parent
		if character and character:IsA("Model") then
			refreshFarmNoclipParts(character)
		end

		velocity = clampFarmVelocity(velocity)
		local posY = root.Position.Y
		local minY = getSafeMinFarmY(posY)
		if velocity.Y < 0 and posY <= minY + 0.35 then
			velocity = Vector3.new(velocity.X, 0, velocity.Z)
		end

		local mover = ensureLinearVelocity(root)
		if velocity.Magnitude > 0.08 then
			ensureFarmStabilizer(root)
		else
			clearFarmStabilizer(root)
		end
		mover.VectorVelocity = velocity
		stabilizeFarmRoot(root)
	end

	local function stopFarmMotion()
		local root = getCharacterRoot()
		if not root then
			return
		end
		local mover = root:FindFirstChild("MM2FarmLV")
		if mover then
			mover.VectorVelocity = Vector3.zero
		end
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end

	local function depthYForCoin(coinY, referenceY)
		return clampFarmY(coinY - getEffectiveDepthBelow(), referenceY or coinY)
	end

	local function pickYForCoin(coinY)
		return coinY + 2.8
	end

	local function flatVelocityToward(position, targetPosition, speed, arriveDistance)
		local flatDelta = Vector3.new(targetPosition.X - position.X, 0, targetPosition.Z - position.Z)
		local flatDist = flatDelta.Magnitude
		if flatDist <= arriveDistance then
			return Vector3.zero, flatDist
		end
		local moveSpeed = math.min(speed, flatDist * 10)
		return flatDelta.Unit * moveSpeed, flatDist
	end

	local function syncWebhookThousandAfterInventoryChange(coins)
		local thousand = math.floor(coins / 1000)
		if thousand < farmRuntime.lastWebhookThousand then
			farmRuntime.lastWebhookThousand = thousand
		end
	end

	local function postDiscordWebhook(coins)
		local url = farmSettings.webhookUrl
		if type(url) ~= "string" or url == "" then
			return
		end

		local thousand = math.floor(coins / 1000)
		if thousand < 1 or thousand <= farmRuntime.lastWebhookThousand then
			return
		end
		farmRuntime.lastWebhookThousand = thousand

		local milestone = thousand * 1000
		local boxes = thousand
		local description = "Hito: "
			.. tostring(milestone)
			.. " monedas\nCoins actuales: "
			.. tostring(coins)
			.. "\nPuede abrir: "
			.. tostring(boxes)
			.. " cajas"
		local footerText = os.date("%Y-%m-%d %H:%M:%S")

		local payload = HttpService:JSONEncode({
			embeds = {
				{
					title = LocalPlayer.Name,
					description = description,
					footer = {
						text = footerText,
					},
				},
			},
		})

		local ok = false
		local requestFn = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
		if type(requestFn) == "function" then
			ok = pcall(function()
				requestFn({
					Url = url,
					Method = "POST",
					Headers = {
						["Content-Type"] = "application/json",
					},
					Body = payload,
				})
			end)
		end

		if not ok and HttpService.RequestAsync then
			pcall(function()
				HttpService:RequestAsync({
					Url = url,
					Method = "POST",
					Headers = {
						["Content-Type"] = "application/json",
					},
					Body = payload,
				})
			end)
		end
	end

	local farmStatusText = ""

	local function setFarmStatus(text)
		if text == farmStatusText then
			return
		end
		farmStatusText = text
		if farmStatusLabel then
			farmStatusLabel:SetText(text)
		end
	end

	local function farmFullStop(statusText: string?)
		stopFarmMotion()
		clearFarmMover()
		restoreFarmNoclip()
		if statusText then
			setFarmStatus(statusText)
		end
	end

	local function setAutoOpenStatus(text)
		if text == autoOpenStatusText then
			return
		end
		autoOpenStatusText = text
		if autoOpenStatusLabel then
			autoOpenStatusLabel:SetText(text)
		end
	end

	local function getSelectedCrateOption(): CrateOption
		return CRATE_OPTIONS[autoOpenSettings.crateIndex] or CRATE_OPTIONS[1]
	end

	local function setCrateIndexByLabel(label: string)
		for index, option in CRATE_OPTIONS do
			if option.label == label then
				autoOpenSettings.crateIndex = index
				return
			end
		end
	end

	local function getCrateDropdownLabels()
		local labels = {}
		for _, option in CRATE_OPTIONS do
			table.insert(labels, option.label)
		end
		return labels
	end

	local function openCrateOption(option: CrateOption): (boolean, string?)
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local shop = remotes and remotes:FindFirstChild("Shop")
		if not shop then
			return false, "no Shop remotes"
		end

		local openCrate = shop:FindFirstChild("OpenCrate")
		if openCrate and openCrate:IsA("RemoteFunction") then
			local ok, result = pcall(function()
				return openCrate:InvokeServer(option.id, option.crateType, option.currency)
			end)
			if ok and result then
				return true
			end
			if not ok then
				return false, tostring(result)
			end
		end

		return false, "OpenCrate rejected"
	end

	local function updateAutoOpenCrates()
		if not autoOpenSettings.enabled then
			setAutoOpenStatus("Auto open: off")
			return
		end

		local coins = inventoryCoins
		if type(coins) ~= "number" then
			setAutoOpenStatus("Auto open: waiting coins...")
			return
		end

		local option = getSelectedCrateOption()
		local needCoins = math.max(autoOpenSettings.minCoins, option.cost)
		if coins < needCoins then
			setAutoOpenStatus("Auto open: need " .. tostring(needCoins) .. "+ coins")
			return
		end

		local now = os.clock()
		if now - autoOpenRuntime.lastOpenAt < autoOpenSettings.cooldown then
			return
		end

		local opened, err = openCrateOption(option)
		autoOpenRuntime.lastOpenAt = now
		if opened then
			setAutoOpenStatus("Auto open: " .. option.label)
		else
			setAutoOpenStatus("Auto open: failed (" .. tostring(err) .. ")")
		end
	end

	refreshLabels = function()
		local updaters = {
			function()
				if not (checkerSettings.enabled and mapLabel) then
					return
				end
				local count, err = countCoinsInMapContainer()
				if err then
					mapLabel:SetText("Map coins: — (" .. err .. ")")
				else
					mapLabel:SetText("Map coins: " .. tostring(count))
				end
			end,
			function()
				if not (checkerSettings.enabled and inventoryLabel) then
					return
				end
				if inventoryCoins == nil then
					inventoryLabel:SetText("Inventory coins: waiting...")
				else
					local boxes = math.floor(inventoryCoins / 1000)
					inventoryLabel:SetText(
						"Inventory coins: " .. tostring(inventoryCoins) .. " | cajas: " .. tostring(boxes)
					)
				end
			end,
			function()
				if not (checkerSettings.enabled and roundLabel) then
					return
				end
				local parts = {}
				for bagName, data in bagCounts do
					local line = bagName .. " " .. tostring(data.current) .. "/" .. tostring(data.max)
					if data.lastPickup then
						line ..= " (+" .. tostring(data.lastPickup) .. ")"
					end
					table.insert(parts, line)
				end
				table.sort(parts)
				if #parts == 0 then
					roundLabel:SetText("Round bag: waiting...")
				else
					roundLabel:SetText("Round bag: " .. table.concat(parts, " | "))
				end
			end,
			function()
				if not partyStatusLabel then
					return
				end
				if getOverlayPartyText then
					partyStatusLabel:SetText(getOverlayPartyText())
				end
			end,
		}
		for _, fn in updaters do
			fn()
		end
	end

	local function isRoundBagFull()
		for _, data in bagCounts do
			if data.max > 0 and data.current >= data.max then
				return true
			end
		end
		return false
	end

	local function getLocalBagSummary()
		local bestCurrent = 0
		local bestMax = 0
		for _, data in bagCounts do
			if data.max > bestMax then
				bestMax = data.max
				bestCurrent = data.current
			end
		end
		local full = bestMax > 0 and bestCurrent >= bestMax
		return bestCurrent, bestMax, full
	end

	local function partyFileApiReady()
		return type(writefile) == "function" and type(readfile) == "function" and type(makefolder) == "function"
	end

	local function httpGetString(url: string): string?
		local ok, body = pcall(function()
			return game:HttpGet(url)
		end)
		if ok and type(body) == "string" and body ~= "" then
			return body
		end
		if type(request) == "function" then
			local okReq, response = pcall(function()
				return request({
					Url = url,
					Method = "GET",
				})
			end)
			if okReq and type(response) == "table" and type(response.Body) == "string" and response.Body ~= "" then
				return response.Body
			end
		end
		return nil
	end

	local function normalizeWorkspacePath(path: string): string
		return string.gsub(path, "\\", "/")
	end

	local function safeOsGetEnv(name: string): string?
		local osTable = os :: any
		local getter = osTable.getenv
		if type(getter) ~= "function" then
			return nil
		end
		local ok, value = pcall(getter, name)
		if ok and type(value) == "string" and value ~= "" then
			return value
		end
		return nil
	end

	local function partyGroupKeyNormalized()
		local key = string.gsub(partySettings.groupKey or "default", "[^%w_-]", "")
		if key == "" then
			key = "default"
		end
		return key
	end

	local function getPartyStorageDirs(): { string }
		local key = partyGroupKeyNormalized()
		local dirs: { string } = {}
		local seen: { [string]: boolean } = {}
		local function addDir(path: string)
			path = normalizeWorkspacePath(path)
			if path == "" or seen[path] then
				return
			end
			seen[path] = true
			table.insert(dirs, path)
		end

		local public = safeOsGetEnv("PUBLIC")
		if public then
			addDir(public .. "/IHubMM2FarmParty/" .. key)
		end
		local userProfile = safeOsGetEnv("USERPROFILE")
		if userProfile then
			addDir(userProfile .. "/Documents/IHubMM2FarmParty/" .. key)
		end
		local localApp = safeOsGetEnv("LOCALAPPDATA")
		if localApp then
			addDir(localApp .. "/IHubMM2FarmParty/" .. key)
		end
		addDir("I-Hub/MM2FarmParty/" .. key)
		return dirs
	end

	local function partyMemberUserId(data): number?
		if typeof(data) ~= "table" then
			return nil
		end
		local raw = data.userId
		if type(raw) == "number" then
			return raw
		end
		if type(raw) == "string" then
			return tonumber(raw)
		end
		return nil
	end

	local function syncPartySettingsFromFlags()
		if typeof(IHubUi.Flags) ~= "table" then
			return
		end
		local function flagValue(flagName: string)
			local entry = IHubUi.Flags[flagName]
			if typeof(entry) == "table" and entry.CurrentValue ~= nil then
				return entry.CurrentValue
			end
			if entry ~= nil and typeof(entry) ~= "table" then
				return entry
			end
			return nil
		end

		local enabled = flagValue("Farm_PartyEnabled")
		if enabled ~= nil then
			partySettings.enabled = enabled == true
		end
		local groupKey = flagValue("Farm_PartyGroupKey")
		if type(groupKey) == "string" and groupKey ~= "" then
			partySettings.groupKey = groupKey
		end
		local hop = flagValue("Farm_PartyServerHop")
		if hop ~= nil then
			partySettings.serverHopIfTogether = hop == true
		end
		local deferReset = flagValue("Farm_PartyDeferReset")
		if deferReset ~= nil then
			partySettings.deferResetForParty = deferReset == true
		end
		local hopSameRegion = flagValue("Farm_PartyHopSameRegion")
		if hopSameRegion ~= nil then
			partySettings.hopSameRegion = hopSameRegion == true
		end
	end

	local function normalizePartyEntry(data: any): any?
		if typeof(data) ~= "table" then
			return nil
		end
		local userId = partyMemberUserId(data)
		if not userId then
			return nil
		end
		data.userId = userId
		if type(data.jobId) == "string" or type(data.jobId) == "number" then
			data.jobId = tostring(data.jobId)
		end
		return data
	end

	local function loadPartyRegistry(dir: string): { [string]: any }
		local path = normalizeWorkspacePath(dir) .. "/" .. PARTY_REGISTRY_FILE
		local ok, raw = pcall(function()
			return readfile(path)
		end)
		if not ok or type(raw) ~= "string" or raw == "" then
			return {}
		end
		local okDecode, decoded = pcall(function()
			return HttpService:JSONDecode(raw)
		end)
		if okDecode and typeof(decoded) == "table" then
			return decoded
		end
		return {}
	end

	local function savePartyRegistry(dir: string, registry: { [string]: any })
		local path = normalizeWorkspacePath(dir) .. "/" .. PARTY_REGISTRY_FILE
		pcall(function()
			writefile(path, HttpService:JSONEncode(registry))
		end)
	end

	local function prunePartyRegistry(registry: { [string]: any })
		local now = os.time()
		for userKey, data in registry do
			if typeof(data) ~= "table" or type(data.t) ~= "number" or now - data.t > PARTY_STALE_SECONDS then
				registry[userKey] = nil
			end
		end
	end

	local function loadMergedPartyRegistry(): { [string]: any }
		local merged: { [string]: any } = {}
		for _, dir in getPartyStorageDirs() do
			local registry = loadPartyRegistry(dir)
			for userKey, rawEntry in registry do
				local data = normalizePartyEntry(rawEntry)
				if not data then
					continue
				end
				local key = tostring(data.userId)
				local existing = merged[key]
				if
					not existing or (type(data.t) == "number" and (type(existing.t) ~= "number" or data.t > existing.t))
				then
					merged[key] = data
				end
			end
		end
		prunePartyRegistry(merged)
		return merged
	end

	local function readPartyStates()
		local states = {}
		if not partySettings.enabled or not partyFileApiReady() then
			return states
		end
		local now = os.time()
		local registry = loadMergedPartyRegistry()
		for _, data in registry do
			local userId = partyMemberUserId(data)
			if not userId or userId == LocalPlayer.UserId then
				continue
			end
			if type(data.t) ~= "number" or now - data.t > PARTY_STALE_SECONDS then
				continue
			end
			table.insert(states, data)
		end
		partyRuntime.lastRegistryPeerCount = #states
		return states
	end

	local function getPartyActiveOnPc()
		local active = {}
		local myJob = tostring(game.JobId)
		for _, state in readPartyStates() do
			if tostring(state.jobId) ~= myJob then
				table.insert(active, state)
			end
		end
		return active
	end

	local function ensurePartyStorageDir(root: string)
		root = normalizeWorkspacePath(root)
		local parts = {}
		for segment in string.gmatch(root, "[^/]+") do
			table.insert(parts, segment)
		end
		local path = ""
		for _, segment in parts do
			path = path == "" and segment or path .. "/" .. segment
			if type(isfolder) == "function" and not isfolder(path) then
				makefolder(path)
			elseif type(isfolder) ~= "function" then
				makefolder(path)
			end
		end
	end

	local function ensureAllPartyStorageDirs()
		for _, dir in getPartyStorageDirs() do
			pcall(ensurePartyStorageDir, dir)
		end
	end

	local function getPartyPublishedRole()
		if farmRuntime.localRole then
			return farmRuntime.localRole
		end
		if playerHasKnife(LocalPlayer) then
			return "Murderer"
		end
		return "Innocent"
	end

	publishPartyState = function()
		if not partySettings.enabled then
			return
		end
		if not partyFileApiReady() then
			return
		end
		ensureAllPartyStorageDirs()
		local current, max, full = getLocalBagSummary()
		local payload = {
			userId = LocalPlayer.UserId,
			name = LocalPlayer.Name,
			jobId = tostring(game.JobId),
			placeId = game.PlaceId,
			role = getPartyPublishedRole(),
			bagCurrent = current,
			bagMax = max,
			bagFull = full or isRoundBagFull(),
			alive = isLocalPlayerAlive(),
			t = os.time(),
		}
		local userKey = tostring(LocalPlayer.UserId)
		for _, dir in getPartyStorageDirs() do
			local registry = loadPartyRegistry(dir)
			prunePartyRegistry(registry)
			registry[userKey] = payload
			savePartyRegistry(dir, registry)
		end
		partyRuntime.lastPublishAt = os.clock()
	end

	local function getPartyPeersOnSameJob()
		local peers = {}
		local myJob = tostring(game.JobId)
		for _, state in readPartyStates() do
			if state.userId ~= LocalPlayer.UserId and tostring(state.jobId) == myJob then
				table.insert(peers, state)
			end
		end
		return peers
	end

	getOverlayPartyText = function()
		if not partySettings.enabled then
			return "Party: desactivado"
		end
		if not partyFileApiReady() then
			return "Party: sin writefile/readfile"
		end
		local peers = getPartyPeersOnSameJob()
		local onPc = getPartyActiveOnPc()
		local hop = partySettings.serverHopIfTogether
		local key = partyGroupKeyNormalized()
		local roomCount = #peers
		local pcCount = #onPc
		local totalInRegistry = partyRuntime.lastRegistryPeerCount
		local storeHint = getPartyStorageDirs()[1] or ""

		if roomCount >= 1 then
			return "Party [" .. key .. "]: " .. tostring(roomCount) .. " misma sala -> hop " .. (hop and "on" or "off")
		end
		if pcCount >= 1 then
			return "Party ["
				.. key
				.. "]: "
				.. tostring(pcCount)
				.. " en PC (otro servidor) | hop "
				.. (hop and "on" or "off")
		end
		if totalInRegistry >= 1 then
			return "Party [" .. key .. "]: " .. tostring(totalInRegistry) .. " en party.json, ninguno en esta sala"
		end
		return "Party [" .. key .. "]: solo tu | " .. PARTY_REGISTRY_FILE .. " en " .. storeHint
	end

	local function memberBagNotFull(member)
		if member.bagFull == true then
			return false
		end
		local max = tonumber(member.bagMax) or 0
		local current = tonumber(member.bagCurrent) or 0
		if max <= 0 then
			return true
		end
		return current < max
	end

	local function partyBlocksReset()
		if not partySettings.enabled or not partySettings.deferResetForParty then
			return false
		end
		local peers = getPartyPeersOnSameJob()
		if #peers == 0 then
			return false
		end

		local selfCurrent, selfMax = getLocalBagSummary()
		local members = {}
		table.insert(members, {
			userId = LocalPlayer.UserId,
			role = getPartyPublishedRole(),
			bagFull = isRoundBagFull(),
			bagCurrent = selfCurrent,
			bagMax = selfMax,
		})
		for _, peer in peers do
			table.insert(members, peer)
		end

		local hasMurder = false
		local innocentNotFull = false
		for _, member in members do
			if member.role == "Murderer" then
				hasMurder = true
			end
			if member.role ~= "Murderer" and memberBagNotFull(member) then
				innocentNotFull = true
			end
		end

		if hasMurder and innocentNotFull then
			return true
		end
		if isRoundBagFull() and innocentNotFull then
			return true
		end
		return false
	end

	local function partyOccupiedJobIds(): { [string]: boolean }
		local occupied: { [string]: boolean } = {
			[tostring(game.JobId)] = true,
		}
		for _, state in readPartyStates() do
			if state.jobId then
				occupied[tostring(state.jobId)] = true
			end
		end
		return occupied
	end

	local function regionPrefix(region: string?): string?
		if type(region) ~= "string" or region == "" then
			return nil
		end
		return string.lower(region):match("^([%w]+)")
	end

	local function serverRegionAllowed(entryRegion: string?, policyPrefix: string?): boolean
		if not policyPrefix or policyPrefix == "" then
			return true
		end
		local prefix = regionPrefix(entryRegion)
		if not prefix then
			return false
		end
		return prefix == policyPrefix
	end

	local function fetchPublicServerPage(cursor: string?): (any?, string?)
		local base = "https://games.roblox.com/v1/games/"
			.. tostring(game.PlaceId)
			.. "/servers/Public?sortOrder=Asc&limit=100"
		local url = base
		if type(cursor) == "string" and cursor ~= "" then
			url = base .. "&cursor=" .. HttpService:UrlEncode(cursor)
		end
		local body = httpGetString(url)
		if not body then
			return nil, nil
		end
		local okDecode, decoded = pcall(function()
			return HttpService:JSONDecode(body)
		end)
		if not okDecode or typeof(decoded) ~= "table" then
			return nil, nil
		end
		local nextCursor = decoded.nextPageCursor
		if type(nextCursor) ~= "string" then
			nextCursor = ""
		end
		return decoded, nextCursor
	end

	local function resolveHopRegionPrefix(occupied: { [string]: boolean }): string?
		if partyRuntime.hopRegionPrefix then
			return partyRuntime.hopRegionPrefix
		end
		if not partySettings.hopSameRegion then
			return nil
		end
		local myJob = tostring(game.JobId)
		local cursor: string? = nil
		for _ = 1, 8 do
			local decoded, nextCursor = fetchPublicServerPage(cursor)
			if not decoded or typeof(decoded.data) ~= "table" then
				break
			end
			for _, entry in decoded.data do
				if typeof(entry) == "table" and entry.id == myJob then
					local prefix = regionPrefix(entry.region)
					if prefix then
						partyRuntime.hopRegionPrefix = prefix
						return prefix
					end
				end
			end
			cursor = nextCursor
			if cursor == "" then
				break
			end
		end
		return nil
	end

	local function pickPublicServerJobId()
		local occupied = partyOccupiedJobIds()
		local regionPolicy = resolveHopRegionPrefix(occupied)
		local scored = {}
		local cursor: string? = nil

		for _ = 1, 6 do
			local decoded, nextCursor = fetchPublicServerPage(cursor)
			if not decoded or typeof(decoded.data) ~= "table" then
				break
			end
			for _, entry in decoded.data do
				if typeof(entry) ~= "table" or type(entry.id) ~= "string" then
					continue
				end
				local jobId = entry.id
				if occupied[jobId] then
					continue
				end
				local playing = tonumber(entry.playing) or 0
				local maxPlayers = tonumber(entry.maxPlayers) or 12
				if playing >= maxPlayers then
					continue
				end
				if not serverRegionAllowed(entry.region, regionPolicy) then
					continue
				end
				local ping = tonumber(entry.ping)
				if not ping or ping < 1 then
					ping = 500
				end
				table.insert(scored, {
					id = jobId,
					ping = ping,
					playing = playing,
				})
			end
			cursor = nextCursor
			if cursor == "" or #scored >= 40 then
				break
			end
		end

		if #scored == 0 and regionPolicy then
			cursor = nil
			for _ = 1, 4 do
				local decoded, nextCursor = fetchPublicServerPage(cursor)
				if not decoded or typeof(decoded.data) ~= "table" then
					break
				end
				for _, entry in decoded.data do
					if typeof(entry) ~= "table" or type(entry.id) ~= "string" then
						continue
					end
					local jobId = entry.id
					if occupied[jobId] then
						continue
					end
					local playing = tonumber(entry.playing) or 0
					local maxPlayers = tonumber(entry.maxPlayers) or 12
					if playing >= maxPlayers then
						continue
					end
					local ping = tonumber(entry.ping) or 500
					table.insert(scored, { id = jobId, ping = ping, playing = playing })
				end
				cursor = nextCursor
				if cursor == "" or #scored >= 20 then
					break
				end
			end
		end

		if #scored == 0 then
			return nil
		end

		table.sort(scored, function(a, b)
			if a.ping ~= b.ping then
				return a.ping < b.ping
			end
			return a.playing > b.playing
		end)

		local bucketSize = math.min(8, #scored)
		local bucket = {}
		for i = 1, bucketSize do
			bucket[i] = scored[i]
		end
		local pick = bucket[(LocalPlayer.UserId % #bucket) + 1]
		return pick and pick.id
	end

	local function attemptPartyServerHop()
		if partyRuntime.hopInProgress then
			return false
		end
		local now = os.clock()
		if now - partyRuntime.lastHopAttempt < PARTY_HOP_COOLDOWN then
			return false
		end
		partyRuntime.lastHopAttempt = now

		local jobId = pickPublicServerJobId()
		partyRuntime.hopInProgress = true
		partyRuntime.hopStartedAt = os.clock()
		setFarmStatus("Party: server hop...")

		if not jobId then
			partyRuntime.hopInProgress = false
			partyRuntime.hopStartedAt = 0
			local regionNote = partySettings.hopSameRegion and partyRuntime.hopRegionPrefix
			if regionNote then
				setFarmStatus("Party: sin servidor en region " .. tostring(regionNote))
			else
				setFarmStatus("Party: sin servidor publico (reintento)")
			end
			return false
		end

		local ok = pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
		end)
		if not ok then
			partyRuntime.hopInProgress = false
			partyRuntime.hopStartedAt = 0
			setFarmStatus("Party: hop fallo (reintento luego)")
		end
		return ok
	end

	local function clearStuckPartyHop()
		if not partyRuntime.hopInProgress then
			return
		end
		if partyRuntime.hopStartedAt <= 0 then
			return
		end
		if os.clock() - partyRuntime.hopStartedAt < PARTY_HOP_STUCK_SECONDS then
			return
		end
		partyRuntime.hopInProgress = false
		partyRuntime.hopStartedAt = 0
	end

	local function tickPartyCoordination()
		if not partySettings.enabled then
			return
		end
		clearStuckPartyHop()
		publishPartyState()
		if not partySettings.serverHopIfTogether then
			return
		end
		if os.clock() - SCRIPT_STARTED_AT < PARTY_HOP_STARTUP_DELAY then
			return
		end
		local peers = getPartyPeersOnSameJob()
		if #peers >= 1 then
			attemptPartyServerHop()
		end
	end

	local function applyBagsTable(bagsTable)
		table.clear(bagCounts)
		if typeof(bagsTable) ~= "table" then
			return
		end

		for bagName, value in bagsTable do
			if typeof(value) == "table" then
				local current = value.Current or value.current or value.Count or value.count or 0
				local max = value.Max or value.max or value.Capacity or value.capacity or 0
				bagCounts[bagName] = {
					current = tonumber(current) or 0,
					max = tonumber(max) or 0,
					lastPickup = nil,
				}
			elseif typeof(value) == "number" then
				bagCounts[bagName] = {
					current = 0,
					max = value,
					lastPickup = nil,
				}
			end
		end
	end

	local function onRoundEnded()
		table.clear(bagCounts)
		farmRuntime.waitingNextRound = true
		refreshLabels()
		setFarmStatus("Autofarm: ronda terminada, esperando...")
	end

	local function tryFireResetRemote(remote)
		if remote:IsA("RemoteEvent") then
			pcall(function()
				remote:FireServer()
			end)
			return true
		end
		if remote:IsA("RemoteFunction") then
			pcall(function()
				remote:InvokeServer()
			end)
			return true
		end
		return false
	end

	local function fireResetRemotes()
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		if not remotes then
			return false
		end

		local names = { "ResetCharacter", "RequestRespawn", "Respawn", "SelfKill", "Reset" }
		for _, remoteName in names do
			local remote = remotes:FindFirstChild(remoteName, true)
			if remote and tryFireResetRemote(remote) then
				return true
			end
		end

		local gameplay = remotes:FindFirstChild("Gameplay")
		if gameplay then
			for _, child in gameplay:GetChildren() do
				local lower = string.lower(child.Name)
				if
					(lower:find("reset") or lower:find("respawn") or lower:find("suicide"))
					and tryFireResetRemote(child)
				then
					return true
				end
			end
		end

		return false
	end

	local function killLocalCharacter()
		local character = LocalPlayer.Character
		if not character then
			return false
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = 0
			pcall(function()
				humanoid:ChangeState(Enum.HumanoidStateType.Dead)
			end)
			return true
		end

		pcall(function()
			character:BreakJoints()
		end)
		return true
	end

	local function requestFarmCharacterReset(reason)
		if farmRuntime.bagFullResetDone then
			return
		end

		if partyBlocksReset() then
			setFarmStatus("Party: esperando bolsa del grupo...")
			return
		end

		local now = os.clock()
		if now - farmRuntime.lastResetAttempt < 2.2 then
			return
		end
		farmRuntime.lastResetAttempt = now
		farmRuntime.bagFullResetDone = true
		farmRuntime.waitingNextRound = true
		farmRuntime.targetCoin = nil
		farmRuntime.peekUntil = 0
		farmRuntime.pauseUntil = 0

		farmFullStop("Autofarm: reset (" .. reason .. ")...")

		if fireResetRemotes() then
			return
		end

		if killLocalCharacter() then
			return
		end

		pcall(function()
			LocalPlayer:LoadCharacter()
		end)
	end

	-- ChangeInventoryItem: ("Materials", "Coins", amount)
	local function onChangeInventoryItem(category, itemName, amount)
		if category ~= "Materials" or itemName ~= "Coins" then
			return
		end
		local total = tonumber(amount)
		if not total then
			return
		end
		inventoryCoins = total
		refreshLabels()
		refreshFullscreenOverlay()

		if not farmRuntime.webhookInventorySynced then
			farmRuntime.webhookInventorySynced = true
			farmRuntime.lastWebhookThousand = math.floor(total / 1000)
			return
		end

		syncWebhookThousandAfterInventoryChange(total)
		postDiscordWebhook(total)
	end

	local function parseCoinCollectedEvent(a1, a2, a3, a4)
		if typeof(a1) == "string" then
			return a1, tonumber(a2) or 0, tonumber(a3) or 0, a4
		end
		if typeof(a1) == "number" then
			return "Coin", tonumber(a1) or 0, tonumber(a2) or 0, a3
		end
		return nil
	end

	local function onCoinCollected(a1, a2, a3, a4)
		local bagKey, currentCount, maxCount, payload = parseCoinCollectedEvent(a1, a2, a3, a4)
		if not bagKey then
			return
		end

		local lastPickup = nil
		if typeof(payload) == "table" then
			lastPickup = tonumber(payload.Value)
		end

		bagCounts[bagKey] = {
			current = currentCount,
			max = maxCount,
			lastPickup = lastPickup,
		}
		invalidateCoinCache()
		refreshLabels()

		if not farmSettings.autofarm then
			return
		end

		if farmSettings.autoResetOnFullBag and maxCount > 0 and currentCount >= maxCount then
			if partyBlocksReset() then
				setFarmStatus("Party: bolsa llena local, esperando grupo...")
				return
			end
			requestFarmCharacterReset("bolsa " .. tostring(currentCount) .. "/" .. tostring(maxCount))
			return
		end

		farmRuntime.targetCoin = nil
		farmRuntime.peekUntil = 0
		farmRuntime.pauseUntil = 0
		farmRuntime.phase = "dive"
		local root = getCharacterRoot()
		farmRuntime.diveTargetY = root and computeDiveTargetY(root.Position.Y) or nil
		setFarmStatus("Autofarm: moneda tomada, bajando...")
	end

	local function beginDiveFromPosition(positionY)
		farmRuntime.diveTargetY = computeDiveTargetY(positionY)
		farmRuntime.phase = "dive"
	end

	local function resetFarmCycle()
		farmRuntime.targetCoin = nil
		farmRuntime.peekUntil = 0
		farmRuntime.pauseUntil = 0
		local root = getCharacterRoot()
		if root then
			beginDiveFromPosition(root.Position.Y)
		else
			farmRuntime.phase = "dive"
			farmRuntime.diveTargetY = nil
		end
	end

	local function normalizeFadeRole(roleName)
		if type(roleName) ~= "string" then
			return nil
		end
		if roleName == "Murderer" or roleName == "Sheriff" or roleName == "Innocent" then
			return roleName
		end
		return nil
	end

	local function getLocalRoleFromFade(data)
		if typeof(data) ~= "table" then
			return nil
		end
		local info = data[LocalPlayer.Name] or data[tostring(LocalPlayer.UserId)]
		if typeof(info) ~= "table" or not info.Role then
			return nil
		end
		return normalizeFadeRole(info.Role)
	end

	local function armRoundStartHide()
		if not farmSettings.diveOnRoundStart then
			return
		end

		armRoundStartProtection()
		farmRuntime.pendingRoundStartDive = true
		farmRuntime.waitingNextRound = false
		farmRuntime.targetCoin = nil
		farmRuntime.peekUntil = 0
		farmRuntime.pauseUntil = 0
		farmRuntime.phase = "dive"
		farmRuntime.diveTargetY = nil
		setFarmStatus("Autofarm: bajando suave (inicio ronda)...")
	end

	local function tryCompletePendingRoundStartDive()
		if not farmRuntime.pendingRoundStartDive then
			return
		end
		if not farmSettings.diveOnRoundStart then
			farmRuntime.pendingRoundStartDive = false
			return
		end
		if not isLocalPlayerAlive() then
			return
		end
		local root = getCharacterRoot()
		if not root then
			return
		end
		if not farmRuntime.diveTargetY then
			farmRuntime.diveTargetY = computeRoundStartHideTargetY(root.Position.Y)
		end
	end

	local function shouldDiveOnRoundFade(role)
		return role ~= "Murderer"
	end

	local function onRoundFade(data)
		local fadeRole = getLocalRoleFromFade(data)
		if fadeRole then
			farmRuntime.localRole = fadeRole
		end

		if not farmSettings.diveOnRoundStart then
			return
		end

		local role = fadeRole
		if shouldDiveOnRoundFade(role) then
			armRoundStartHide()
		end

		task.delay(0.5, function()
			if not farmSettings.diveOnRoundStart or not farmRuntime.pendingRoundStartDive then
				return
			end
			local fadeRole = getLocalRoleFromFade(data)
			if fadeRole == "Murderer" then
				farmRuntime.pendingRoundStartDive = false
				return
			end
			if fadeRole == nil and playerHasKnife(LocalPlayer) then
				farmRuntime.pendingRoundStartDive = false
				return
			end
			tryCompletePendingRoundStartDive()
		end)
	end

	local function onCoinsStarted(bagsTable)
		applyBagsTable(bagsTable)
		farmRuntime.bagFullResetDone = false
		farmRuntime.lastResetAttempt = 0
		farmRuntime.waitingNextRound = false
		refreshLabels()

		if farmSettings.autofarm then
			if isRoundStartDiveWindow() then
				setFarmStatus("Autofarm: nueva ronda (bajando al inicio)...")
			else
				task.defer(resetFarmCycle)
				setFarmStatus("Autofarm: nueva ronda, farm on")
			end
		end
	end

	local function findNearestCoin(fromPosition)
		local nearest = nil
		local nearestDist = math.huge

		for _, coin in getCachedAvailableCoins() do
			local coinPos = getCoinWorldPosition(coin)
			if not coinPos then
				continue
			end
			if not isCoinSafeFromMurderer(coinPos) then
				continue
			end
			local flatDist = (Vector3.new(coinPos.X, 0, coinPos.Z) - Vector3.new(fromPosition.X, 0, fromPosition.Z)).Magnitude
			if flatDist < nearestDist then
				nearestDist = flatDist
				nearest = coin
			end
		end

		return nearest
	end

	local function getTargetCoin()
		if farmRuntime.targetCoin and isAvailableMapCoin(farmRuntime.targetCoin) then
			local coinPos = getCoinWorldPosition(farmRuntime.targetCoin)
			if coinPos and isCoinSafeFromMurderer(coinPos) then
				return farmRuntime.targetCoin
			end
		end
		farmRuntime.targetCoin = nil
		return nil
	end

	local function farmSinkVelocity()
		return Vector3.new(0, -getFarmSinkSpeed(), 0)
	end

	local function farmDiveAfterLostCoin(posY, status)
		farmRuntime.targetCoin = nil
		beginDiveFromPosition(posY)
		setFarmStatus(status)
		setFarmVelocity(farmSinkVelocity())
	end

	local function farmEnsureDiveTargetY(pos)
		if farmRuntime.diveTargetY then
			return
		end
		if farmRuntime.pendingRoundStartDive then
			farmRuntime.diveTargetY = computeRoundStartHideTargetY(pos.Y)
		else
			farmRuntime.diveTargetY = computeDiveTargetY(pos.Y)
		end
	end

	local function farmPhaseDive(pos)
		farmEnsureDiveTargetY(pos)
		local sink = farmSinkVelocity()
		local target = farmRuntime.diveTargetY
		if pos.Y > target + 1 then
			setFarmStatus("Autofarm: bajando...")
			return sink
		end
		if farmRuntime.pendingRoundStartDive then
			farmRuntime.pendingRoundStartDive = false
			farmRuntime.diveTargetY = computeDiveTargetY(pos.Y)
		end
		farmRuntime.targetCoin = findNearestCoin(pos)
		if farmRuntime.targetCoin then
			farmRuntime.phase = "advance"
			setFarmStatus("Autofarm: moneda cercana encontrada")
			return Vector3.zero
		end
		if pos.Y > target + 0.5 then
			setFarmStatus("Autofarm: ajustando profundidad...")
			return sink
		end
		invalidateCoinCache()
		setFarmStatus("Autofarm: esperando monedas (profundidad segura)")
		return Vector3.zero
	end

	local function farmPhaseAdvance(pos)
		local coin = getTargetCoin() or findNearestCoin(pos)
		farmRuntime.targetCoin = coin
		if not coin then
			beginDiveFromPosition(pos.Y)
			setFarmStatus("Autofarm: buscando moneda...")
			return Vector3.zero
		end
		local coinPos = getCoinWorldPosition(coin)
		if not coinPos then
			farmRuntime.targetCoin = nil
			beginDiveFromPosition(pos.Y)
			return Vector3.zero
		end
		local depthY = depthYForCoin(coinPos.Y, pos.Y)
		local flatDelta = Vector3.new(coinPos.X - pos.X, 0, coinPos.Z - pos.Z)
		local flatDist = flatDelta.Magnitude
		if flatDist <= farmSettings.collectArrive then
			farmRuntime.phase = "rise"
			setFarmStatus("Autofarm: debajo, subiendo...")
			return Vector3.zero
		end
		local flatVel = flatDelta.Unit * farmSettings.horizontalSpeed
		local yGain = math.clamp(6 + farmSettings.sinkSpeed * 0.08, 6, 14)
		local yPull = math.clamp((depthY - pos.Y) * yGain, -farmSettings.sinkSpeed, farmSettings.riseSpeed)
		setFarmStatus("Autofarm: avanzando debajo")
		return Vector3.new(flatVel.X, yPull, flatVel.Z)
	end

	local function farmPhaseRise(pos, now)
		local coin = getTargetCoin()
		local coinPos = coin and getCoinWorldPosition(coin)
		if not coinPos or not isAvailableMapCoin(coin) then
			farmDiveAfterLostCoin(pos.Y, "Autofarm: moneda tomada, bajando...")
			return nil
		end
		local flatVel, flatDist =
			flatVelocityToward(pos, coinPos, farmSettings.horizontalSpeed * 1.25, farmSettings.collectArrive)
		local pickY = pickYForCoin(coinPos.Y)
		local vel = Vector3.new(flatVel.X, farmSettings.riseSpeed, flatVel.Z)
		if flatDist <= farmSettings.collectArrive + 0.5 and pos.Y >= coinPos.Y - 1.2 then
			tryTouchCollectCoin(coin)
		end
		local throughCoin = pos.Y >= coinPos.Y - 0.35 and flatDist <= farmSettings.collectArrive + 0.35
		if pos.Y >= pickY - 0.5 or throughCoin then
			farmRuntime.phase = "peek"
			farmRuntime.peekUntil = now + farmSettings.surfaceHold
			vel = Vector3.zero
		end
		setFarmStatus("Autofarm: subiendo (dist " .. string.format("%.1f", flatDist) .. ")")
		return vel
	end

	local function farmPhasePeek(pos, now)
		local coin = getTargetCoin()
		if not coin then
			farmDiveAfterLostCoin(pos.Y, "Autofarm: moneda tomada, bajando...")
			return nil
		end
		local vel = Vector3.zero
		local coinPos = getCoinWorldPosition(coin)
		if coinPos then
			local flatVel, flatDist =
				flatVelocityToward(pos, coinPos, farmSettings.horizontalSpeed, farmSettings.collectArrive)
			vel = Vector3.new(flatVel.X, 0, flatVel.Z)
			if flatDist <= farmSettings.collectArrive + 0.6 then
				tryTouchCollectCoin(coin)
			end
		end
		if now >= farmRuntime.peekUntil then
			if isAvailableMapCoin(coin) then
				farmRuntime.phase = "rise"
				setFarmStatus("Autofarm: reintento subida...")
			else
				farmDiveAfterLostCoin(pos.Y, "Autofarm: moneda tomada, bajando...")
				return nil
			end
		else
			setFarmStatus("Autofarm: recolectando...")
		end
		return vel
	end

	local farmPhases = {
		dive = function(pos)
			return farmPhaseDive(pos)
		end,
		advance = function(pos)
			return farmPhaseAdvance(pos)
		end,
		rise = function(pos, now)
			return farmPhaseRise(pos, now)
		end,
		peek = function(pos, now)
			return farmPhasePeek(pos, now)
		end,
	}

	local function updateDragFarm()
		if not getLocalPlayer() then
			return
		end

		local roundStartDive = farmSettings.diveOnRoundStart and isRoundStartDiveWindow()

		if not farmSettings.autofarm and not roundStartDive then
			farmFullStop()
			return
		end

		if farmRuntime.waitingNextRound then
			farmFullStop("Autofarm: esperando nueva ronda...")
			return
		end

		if farmSettings.autoResetOnFullBag and isRoundBagFull() then
			if not (farmRuntime.pendingRoundStartDive or isRoundStartDiveWindow()) then
				if partyBlocksReset() then
					farmFullStop("Party: bolsa llena, esperando grupo...")
					return
				end
				if farmRuntime.bagFullResetDone then
					farmRuntime.waitingNextRound = true
					farmFullStop("Autofarm: bolsa llena, esperando ronda...")
					return
				end
				requestFarmCharacterReset("bolsa llena")
				return
			end
		end

		if not isLocalPlayerAlive() then
			if roundStartDive or farmRuntime.pendingRoundStartDive then
				tryCompletePendingRoundStartDive()
				setFarmStatus("Autofarm: esperando Alive para bajar...")
				return
			end
			farmFullStop("Autofarm: waiting (not Alive)")
			return
		end

		local player = getLocalPlayer()
		local character = player and player.Character
		if character and (farmSettings.autofarm or roundStartDive) and not farmNoclipDescendantConn then
			startFarmNoclipWatch(character)
		end
		applyFarmNoclipFrame()

		local now = os.clock()
		if farmRuntime.pauseUntil > now then
			stopFarmMotion()
			setFarmStatus("Autofarm: pause")
			return
		end

		tryCompletePendingRoundStartDive()

		local availableCoins = getCachedAvailableCoins()
		local divingWithoutCoins = roundStartDive
		if #availableCoins == 0 and not divingWithoutCoins then
			stopFarmMotion()
			farmRuntime.targetCoin = nil
			farmRuntime.phase = "dive"
			setFarmStatus("Autofarm: no coins on map")
			return
		end

		local root = getCharacterRoot()
		if not root then
			return
		end

		local pos = root.Position

		if
			farmSettings.avoidMurdererCoins
			and not divingWithoutCoins
			and not findNearestCoin(pos)
			and getMurdererRootPositionCached()
		then
			stopFarmMotion()
			farmRuntime.targetCoin = nil
			setFarmStatus("Autofarm: monedas cerca del murder")
			return
		end

		local phaseFn = farmPhases[farmRuntime.phase]
		local vel
		if phaseFn then
			vel = phaseFn(pos, now)
		else
			beginDiveFromPosition(pos.Y)
			vel = Vector3.zero
		end
		if vel ~= nil then
			setFarmVelocity(vel)
		end
	end

	local function connectRemoteEvent(remote, handler)
		if remote and remote:IsA("RemoteEvent") then
			remote.OnClientEvent:Connect(handler)
		end
	end

	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes", 25)
		if not remotes then
			return
		end
		local gameplay = remotes:WaitForChild("Gameplay", 25)
		if not gameplay then
			return
		end
		local gameplayBinds = {
			{ "CoinCollected", onCoinCollected },
			{ "CoinsStarted", onCoinsStarted },
			{ "RoundEndFade", onRoundEnded },
			{ "Fade", onRoundFade },
		}
		for _, bind in gameplayBinds do
			local name, handler = bind[1], bind[2]
			local remote
			if name == "RoundEndFade" or name == "Fade" then
				remote = gameplay:FindFirstChild(name)
			else
				remote = gameplay:WaitForChild(name, 25)
			end
			connectRemoteEvent(remote, handler)
		end

		local inventory = remotes:WaitForChild("Inventory", 25)
		if inventory then
			connectRemoteEvent(inventory:WaitForChild("ChangeInventoryItem", 25), onChangeInventoryItem)
		end
	end)

	local lastFarmUpdateAt = 0

	RunService.Stepped:Connect(function()
		tickFarmNoclipEngine()
	end)

	RunService.Heartbeat:Connect(function()
		clock += 1
		if checkerSettings.enabled and clock % 90 == 0 then
			refreshLabels()
		end

		tickFarmNoclipEngine()

		local now = os.clock()
		if partySettings.enabled and now - partyRuntime.lastTickAt >= PARTY_TICK_INTERVAL then
			partyRuntime.lastTickAt = now
			tickPartyCoordination()
		end

		if perfSettings.fullscreenOverlay and clock % 30 == 0 and refreshFullscreenOverlay then
			refreshFullscreenOverlay()
		end

		if rejoinRuntime.inProgress then
			return
		end

		if now - lastFarmUpdateAt < FARM_UPDATE_INTERVAL then
			return
		end
		lastFarmUpdateAt = now
		updateDragFarm()
		updateAutoOpenCrates()
	end)

	LocalPlayer:GetAttributeChangedSignal("Alive"):Connect(function()
		if LocalPlayer:GetAttribute("Alive") == true then
			tryCompletePendingRoundStartDive()
		end
	end)

	LocalPlayer.CharacterAdded:Connect(function(character)
		if not isRoundStartDiveWindow() then
			restoreFarmNoclip()
			clearFarmMover()
		end
		farmRuntime.lastNoclipPartRefresh = 0
		table.clear(coinTouchPartCache)
		if not farmSettings.autofarm or farmRuntime.waitingNextRound then
			return
		end
		task.defer(function()
			if farmRuntime.waitingNextRound then
				return
			end
			local root = character:WaitForChild("HumanoidRootPart", 12)
			if not root then
				farmRuntime.phase = "dive"
				farmRuntime.diveTargetY = nil
				return
			end
			if farmSettings.diveOnRoundStart and isRoundStartDiveWindow() then
				tryCompletePendingRoundStartDive()
			else
				beginDiveFromPosition(root.Position.Y)
			end
			startFarmNoclipWatch(character)
			refreshFarmNoclipParts(character)
			applyFarmNoclipFrame()
		end)
	end)

	local function mountMm2FarmUi()
		local backdropDropdownOptions = {}
		for _, style in NO_RENDER_BACKDROP_STYLES do
			table.insert(backdropDropdownOptions, style.name)
		end

		local function onAutofarmToggle(value)
			farmSettings.autofarm = value
			if value then
				local character = LocalPlayer.Character
				if character then
					startFarmNoclipWatch(character)
					refreshFarmNoclipParts(character)
					applyFarmNoclipFrame()
				end
				if farmRuntime.waitingNextRound then
					setFarmStatus("Autofarm: on (esperando ronda)")
				else
					resetFarmCycle()
					setFarmStatus("Autofarm: on")
				end
			else
				farmFullStop("Autofarm: off")
			end
		end

		local FarmTab = Window:CreateTab({ name = "Farm", icon = "coins", columns = 2 })
		local farmLabels = IHubUi.mount(FarmTab, {
			{ type = "section", name = "Coins", column = 1 },
			{
				type = "toggle",
				name = "Show coin counter",
				flag = "Farm_ShowCoinCounter",
				value = true,
				callback = function(value)
					checkerSettings.enabled = value
					refreshLabels()
				end,
			},
			{ type = "status", id = "map", name = "Map coins", text = "Map coins: —" },
			{ type = "status", id = "inventory", name = "Inventory coins", text = "Inventory coins: waiting..." },
			{ type = "status", id = "round", name = "Round bag", text = "Round bag: waiting..." },
			{ type = "section", name = "Performance", column = 1 },
			{
				type = "toggle",
				name = "Disable 3D render",
				flag = "Farm_Disable3dRender",
				value = false,
				callback = function(value)
					perfSettings.disable3dRender = value == true
					apply3dRenderingSetting()
				end,
			},
			{
				type = "toggle",
				name = "Fullscreen overlay",
				flag = "Farm_FullscreenOverlay",
				value = false,
				callback = function(value)
					setFullscreenOverlayEnabled(value == true)
				end,
			},
			{
				type = "dropdown",
				name = "Backdrop color",
				flag = "Farm_NoRenderBackdrop",
				options = backdropDropdownOptions,
				value = backdropDropdownOptions[perfSettings.backdropStyle] or backdropDropdownOptions[1],
				callback = function(value)
					for index, style in NO_RENDER_BACKDROP_STYLES do
						if style.name == value then
							perfSettings.backdropStyle = index
							refreshNoRenderBackdropColor()
							break
						end
					end
				end,
			},
			{
				type = "toggle",
				name = "Anti AFK",
				flag = "Farm_AntiAFK",
				value = true,
				callback = function(value)
					setAntiAfkEnabled(value)
				end,
			},
			{
				type = "toggle",
				name = "Auto rejoin on kick",
				flag = "Farm_AutoRejoinKick",
				value = true,
				callback = function(value)
					perfSettings.autoRejoinOnKick = value == true
				end,
			},
			{
				type = "toggle",
				name = "Rejoin same server",
				flag = "Farm_RejoinSameServer",
				value = false,
				callback = function(value)
					perfSettings.rejoinSameServer = value == true
					rejoinRuntime.lastJobId = tostring(game.JobId)
				end,
			},
			{ type = "section", name = "Party (varias cuentas)", column = 2 },
			{
				type = "toggle",
				name = "Party sync",
				flag = "Farm_PartyEnabled",
				value = true,
				callback = function(value)
					partySettings.enabled = value == true
					if value and not partyFileApiReady() then
						setFarmStatus("Party: sin writefile/readfile")
					end
					publishPartyState()
				end,
			},
			{
				type = "input",
				name = "Party group key",
				flag = "Farm_PartyGroupKey",
				placeholder = "default",
				value = "default",
				callback = function(value)
					partySettings.groupKey = value ~= "" and value or "default"
					publishPartyState()
				end,
			},
			{ type = "status", id = "partyFarm", name = "Party status", text = "Party: ..." },
			{
				type = "toggle",
				name = "Server hop si coinciden",
				flag = "Farm_PartyServerHop",
				value = true,
				callback = function(value)
					partySettings.serverHopIfTogether = value == true
				end,
			},
			{
				type = "toggle",
				name = "Hop misma region (menos ping)",
				flag = "Farm_PartyHopSameRegion",
				value = true,
				callback = function(value)
					partySettings.hopSameRegion = value == true
					partyRuntime.hopRegionPrefix = nil
				end,
			},
			{
				type = "toggle",
				name = "Esperar grupo antes de reset",
				flag = "Farm_PartyDeferReset",
				value = true,
				callback = function(value)
					partySettings.deferResetForParty = value == true
				end,
			},
			{ type = "section", name = "Autofarm", column = 2 },
			{
				type = "toggle",
				name = "Auto reset when bag full",
				flag = "Farm_AutoResetFullBag",
				value = true,
				callback = function(v)
					farmSettings.autoResetOnFullBag = v
				end,
			},
			{
				type = "toggle",
				name = "Avoid coins near murder",
				flag = "Farm_AvoidMurdererCoins",
				value = true,
				callback = function(v)
					farmSettings.avoidMurdererCoins = v
					farmRuntime.targetCoin = nil
				end,
			},
			{
				type = "slider",
				name = "Murder avoid radius",
				flag = "Farm_MurdererAvoidRadius",
				range = { 10, 55 },
				value = 26,
				callback = function(v)
					farmSettings.murdererAvoidRadius = v
					farmRuntime.targetCoin = nil
				end,
			},
			{
				type = "toggle",
				name = "Dive on round start",
				flag = "Farm_DiveOnRoundStart",
				value = true,
				callback = function(v)
					farmSettings.diveOnRoundStart = v
				end,
			},
			{
				type = "toggle",
				name = "Auto collect coins",
				flag = "Farm_AutoCollect",
				value = false,
				callback = onAutofarmToggle,
			},
			{
				type = "slider",
				name = "Pause between coins (s)",
				flag = "Farm_PauseBetweenCoins",
				range = { 0, 3 },
				increment = 0.1,
				value = 1,
				callback = function(v)
					farmSettings.cooldown = v
				end,
			},
			{
				type = "slider",
				name = "Depth below coin",
				flag = "Farm_DepthBelow",
				range = { 4, 30 },
				value = 7,
				callback = function(v)
					farmSettings.depthBelow = v
				end,
			},
			{
				type = "slider",
				name = "Horizontal speed",
				flag = "Farm_HorizontalSpeed",
				range = { 10, 50 },
				value = 16,
				callback = function(v)
					farmSettings.horizontalSpeed = v
				end,
			},
			{
				type = "slider",
				name = "Rise / sink speed",
				flag = "Farm_RiseSinkSpeed",
				range = { 12, 70 },
				value = 18,
				callback = function(v)
					farmSettings.riseSpeed = v
					farmSettings.sinkSpeed = v
				end,
			},
			{
				type = "input",
				name = "Discord webhook",
				flag = "Farm_DiscordWebhook",
				placeholder = "https://discord.com/api/webhooks/...",
				value = "",
				callback = function(value)
					farmSettings.webhookUrl = value
				end,
			},
			{ type = "status", id = "farm", name = "Autofarm status", text = "Autofarm: off" },
		})
		mapLabel = farmLabels.map
		inventoryLabel = farmLabels.inventory
		roundLabel = farmLabels.round
		farmStatusLabel = farmLabels.farm
		partyStatusLabel = farmLabels.partyFarm

		local OpenTab = Window:CreateTab({ name = "Auto open", icon = "package" })
		local openLabels = IHubUi.mount(OpenTab, {
			{ type = "section", name = "Crates" },
			{
				type = "toggle",
				name = "Auto open crates",
				flag = "Farm_AutoOpenCrates",
				value = false,
				callback = function(value)
					autoOpenSettings.enabled = value
					if not value then
						setAutoOpenStatus("Auto open: off")
					end
				end,
			},
			{
				type = "dropdown",
				name = "Crate",
				flag = "Farm_CrateSelect",
				options = getCrateDropdownLabels(),
				value = CRATE_OPTIONS[1].label,
				callback = function(value)
					setCrateIndexByLabel(value)
				end,
			},
			{
				type = "slider",
				name = "Min coins to keep",
				flag = "Farm_AutoOpenMinCoins",
				range = { 0, 50000 },
				value = 1000,
				callback = function(v)
					autoOpenSettings.minCoins = v
				end,
			},
			{
				type = "slider",
				name = "Delay between opens (s)",
				flag = "Farm_AutoOpenCooldown",
				range = { 0.5, 5 },
				increment = 0.05,
				value = 1.25,
				callback = function(v)
					autoOpenSettings.cooldown = v
				end,
			},
			{ type = "status", id = "open", name = "Auto open status", text = "Auto open: off" },
		})
		autoOpenStatusLabel = openLabels.open
		mapLabel = farmLabels.map
		inventoryLabel = farmLabels.inventory
		roundLabel = farmLabels.round
		farmStatusLabel = farmLabels.farm
	end
	mountMm2FarmUi()

	task.defer(function()
		task.wait(0.5)
		local ok, err = pcall(function()
			syncPartySettingsFromFlags()
			if not partyFileApiReady() then
				warn("[MM2 Farm] Party: hace falta writefile/readfile/makefolder.")
			end
			if publishPartyState then
				publishPartyState()
			end
			if refreshLabels then
				refreshLabels()
			end
		end)
		if not ok then
			warn("[MM2 Farm] Party init:", err)
		end
	end)
end

initMm2FarmOverlay()
initMm2FarmCore()

if refreshLabels then
	task.defer(refreshLabels)
end

task.defer(function()
	if apply3dRenderingSetting then
		apply3dRenderingSetting()
	end
end)
task.defer(function()
	setAntiAfkEnabled(perfSettings.antiAfk)
end)

initAutoRejoinWatch()

local function toggleFullscreenOverlay()
	if setFullscreenOverlayEnabled then
		setFullscreenOverlayEnabled(not perfSettings.fullscreenOverlay)
	end
end

local function bindOverlayToggleInput()
	pcall(function()
		ContextActionService:UnbindAction(OVERLAY_CONTEXT_ACTION)
		ContextActionService:BindAction(OVERLAY_CONTEXT_ACTION, function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				toggleFullscreenOverlay()
			end
		end, false, OVERLAY_TOGGLE_KEY)
	end)
end

UserInputService.InputBegan:Connect(function(input, _gameProcessed)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end
	if input.KeyCode ~= OVERLAY_TOGGLE_KEY then
		return
	end
	if UserInputService:GetFocusedTextBox() then
		return
	end
	toggleFullscreenOverlay()
end)

task.defer(bindOverlayToggleInput)

print("[MM2 Farm] loaded (build 63).")
