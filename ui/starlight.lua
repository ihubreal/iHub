--[[ I-Hub | Starlight oficial (Nebula) — helper opcional para Loader / MM2.lua ]]

local StarlightBootstrap = {}

StarlightBootstrap.URL = "https://raw.githubusercontent.com/Nebula-Softworks/Starlight-Interface-Suite/master/Source.lua"

function StarlightBootstrap.load()
	local compile = loadstring or load
	local ok, Starlight = pcall(function()
		return compile(game:HttpGet(StarlightBootstrap.URL))()
	end)
	if not ok or type(Starlight) ~= "table" then
		return nil, Starlight
	end
	return Starlight, nil
end

function StarlightBootstrap.defaultWindowOptions(overrides)
	local base = {
		Name = "I-Hub",
		Subtitle = "",
		LoadingEnabled = false,
		BuildWarnings = false,
		InterfaceAdvertisingPrompts = false,
		NotifyOnCallbackError = false,
		KeySystem = { Enabled = false },
	}
	if type(overrides) == "table" then
		for key, value in overrides do
			base[key] = value
		end
	end
	return base
end

function StarlightBootstrap.createWindow(Starlight, overrides)
	if type(Starlight) ~= "table" or type(Starlight.CreateWindow) ~= "function" then
		return nil
	end
	return Starlight:CreateWindow(StarlightBootstrap.defaultWindowOptions(overrides))
end

return StarlightBootstrap
