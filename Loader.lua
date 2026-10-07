--[[
    I-Hub loader flow:
    License (KeyAuth) -> fetch hub script from GitHub -> destroy loader UI -> run hub
]]

local AfterDestroyWait = 0.3
local LoaderVisibleSeconds = 0.6

local STARLIGHT_URL = "https://raw.githubusercontent.com/Nebula-Softworks/Starlight-Interface-Suite/master/Source.lua"

local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")

local Base = "https://raw.githubusercontent.com/ihubreal/iHub/refs/heads/main"

-- KeyAuth (mismos valores que en el panel: Application, no Seller key)
local keyauthConfig = {
	enabled = true,
	name = "i-Hub",
	ownerid = "XAJER0bAfC",
	version = "1.0",
}
local keyauthEnabled = keyauthConfig.enabled == true

local LoaderState = {}

local function loadModule(path)
	local source = nil
	if type(readfile) == "function" then
		local localPaths = {
			"I-Hub/" .. path,
			"ihub/" .. path,
			path,
		}
		for _, p in localPaths do
			local ok, src = pcall(readfile, p)
			if ok and type(src) == "string" and src ~= "" then
				source = src
				break
			end
		end
	end
	if not source then
		source = nil
		local ok, src = pcall(function()
			return game:HttpGet(Base .. "/" .. path .. "?_=" .. tostring(os.time()))
		end)
		if ok and type(src) == "string" and src ~= "" and not src:find("404: Not Found", 1, true) then
			source = src
		end
	end
	if not source then
		return nil
	end
	local compile = loadstring or load
	local chunk, err = compile(source, path)
	if not chunk then
		warn("[I-Hub] compile " .. path .. ":", err)
		return nil
	end
	local ok, mod = pcall(chunk)
	if ok then
		return mod
	end
	warn("[I-Hub] run " .. path .. ":", mod)
	return nil
end

local KeyAuth = loadModule("auth/keyauth.lua")

local function placeName(placeId)
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(placeId)
	end)
	if ok and type(info) == "table" and type(info.Name) == "string" and info.Name ~= "" then
		return info.Name
	end
	return "Place " .. tostring(placeId)
end

local function fetch(path)
	local url = Base .. "/" .. path .. "?_=" .. tostring(os.time())
	local ok, source = pcall(function()
		return game:HttpGet(url)
	end)
	if not ok or type(source) ~= "string" or source == "" then
		return nil
	end
	if source:find("404: Not Found", 1, true) then
		return nil
	end
	return source
end

local function openLoader()
	local compile = loadstring or load
	local Starlight = compile(game:HttpGet(STARLIGHT_URL))()

	local win = Starlight:CreateWindow({
		Name = "I-Hub",
		Subtitle = "Loader",
		LoadingEnabled = false,
		BuildWarnings = false,
		InterfaceAdvertisingPrompts = false,
		NotifyOnCallbackError = false,
		KeySystem = { Enabled = false },
	})

	local section = win:CreateTabSection("Main")
	local tab = section:CreateTab({ Name = "Game", Columns = 1 }, "loader_tab")
	local group = tab:CreateGroupbox({ Name = "Access", Column = 1 }, "loader_group")

	LoaderState.starlight = Starlight
	LoaderState.group = group
	LoaderState.lineIndex = 0
	LoaderState.authenticated = not keyauthEnabled
	LoaderState.pendingKey = ""

	function LoaderState.addLine(text)
		LoaderState.lineIndex = LoaderState.lineIndex + 1
		group:CreateParagraph({
			Name = " ",
			Content = text,
		}, "loader_line_" .. tostring(LoaderState.lineIndex))
	end

	if keyauthEnabled and type(KeyAuth) == "table" then
		group:CreateParagraph({
			Name = "License",
			Content = "Pega la key que obtuviste tras el link (LootLabs / Linkvertise).",
		}, "loader_key_hint")

		group:CreateInput({
			Name = "License key",
			PlaceholderText = "XXXX-XXXX-...",
			CurrentValue = "",
			RemoveTextOnFocus = false,
			Callback = function(value)
				LoaderState.pendingKey = value or ""
			end,
		}, "loader_key_input")

		group:CreateButton({
			Name = "Verify key",
			Callback = function()
				if LoaderState.authenticated then
					return
				end
				local key = LoaderState.pendingKey
				if type(key) ~= "string" or key:gsub("%s", "") == "" then
					LoaderState.addLine("Key vacia.")
					return
				end
				key = key:gsub("^%s+", ""):gsub("%s+$", "")
				local ok, msg = KeyAuth.verify(keyauthConfig, key)
				if ok then
					LoaderState.authenticated = true
					LoaderState.addLine("License OK. Cargando...")
					if type(Starlight.Notification) == "function" then
						Starlight:Notification({
							Title = "I-Hub",
							Content = "Key valida",
							Duration = 3,
						})
					end
				else
					LoaderState.addLine(tostring(msg))
				end
			end,
		}, "loader_key_btn")
	elseif keyauthEnabled then
		warn("[I-Hub] KeyAuth activo pero auth/keyauth.lua no cargo; sigue sin validar.")
		LoaderState.authenticated = true
	end

	return Starlight, win
end

local function destroyLoader()
	if type(LoaderState.starlight) == "table" and type(LoaderState.starlight.Destroy) == "function" then
		pcall(function()
			LoaderState.starlight:Destroy()
		end)
	end
	LoaderState = {}
end

local function waitForLicense()
	if not keyauthEnabled then
		return true
	end
	local deadline = os.clock() + 600
	while not LoaderState.authenticated do
		if os.clock() > deadline then
			return false
		end
		task.wait(0.2)
	end
	return true
end

local listSource = fetch("games/list.lua")
local games = nil
if listSource then
	local run, parsed = pcall(function()
		return loadstring(listSource)()
	end)
	if run and type(parsed) == "table" then
		games = parsed
	end
end

local fileName = games and games[game.PlaceId]
if type(fileName) ~= "string" or fileName == "" or fileName:find("[/\\]") then
	openLoader()
	LoaderState.addLine(placeName(game.PlaceId))
	if games then
		LoaderState.addLine("This place is not in the hub list.")
	else
		LoaderState.addLine("Could not read games/list.lua from GitHub.")
	end
	return
end

openLoader()
LoaderState.addLine(placeName(game.PlaceId))
LoaderState.addLine("Hub: games/" .. fileName)

if keyauthEnabled then
	LoaderState.addLine("Verifica tu key para continuar.")
	if not waitForLicense() then
		LoaderState.addLine("Tiempo agotado sin key valida.")
		return
	end
end

LoaderState.addLine("Fetching script from GitHub...")
task.wait(LoaderVisibleSeconds)

local hubSource = fetch("games/" .. fileName)
if not hubSource then
	LoaderState.addLine("Could not fetch the hub script.")
	return
end

destroyLoader()
task.wait(AfterDestroyWait)

local loaded, loadError = pcall(function()
	loadstring(hubSource)()
end)
if not loaded then
	warn("[I-Hub] " .. tostring(loadError))
end
