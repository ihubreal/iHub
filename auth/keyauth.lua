--[[
  Cliente KeyAuth para Loader (init + license + HWID).
  Docs: https://keyauth.cc/docs
]]

local KeyAuth = {}

KeyAuth.API_URL = "https://keyauth.win/api/1.3/"

function KeyAuth.getHwid()
	if type(gethwid) == "function" then
		local ok, id = pcall(gethwid)
		if ok and type(id) == "string" and id ~= "" then
			return id
		end
	end
	if type(getsynapsehwid) == "function" then
		local ok, id = pcall(getsynapsehwid)
		if ok and type(id) == "string" and id ~= "" then
			return id
		end
	end
	local Players = game:GetService("Players")
	local lp = Players.LocalPlayer
	if lp then
		return "roblox-" .. tostring(lp.UserId)
	end
	return "unknown"
end

local function getHttp()
	if type(request) == "function" then
		return function(url)
			local res = request({ Url = url, Method = "GET" })
			if type(res) == "table" and type(res.Body) == "string" then
				return res.Body
			end
			return nil
		end
	end
	return function(url)
		return game:HttpGet(url)
	end
end

local function decodeJson(raw)
	local HttpService = game:GetService("HttpService")
	if type(raw) ~= "string" or raw == "" then
		return nil
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if ok then
		return data
	end
	return nil
end

local function buildUrl(params)
	local HttpService = game:GetService("HttpService")
	local parts = {}
	for key, value in params do
		table.insert(parts, HttpService:UrlEncode(tostring(key)) .. "=" .. HttpService:UrlEncode(tostring(value)))
	end
	return KeyAuth.API_URL .. "?" .. table.concat(parts, "&")
end

function KeyAuth.init(config)
	config = config or {}
	local name = config.name
	local ownerid = config.ownerid
	local version = config.version or "1.0"
	if type(name) ~= "string" or type(ownerid) ~= "string" then
		return false, "KeyAuth: name u ownerid invalidos"
	end

	local httpGet = getHttp()
	local url = buildUrl({
		type = "init",
		name = name,
		ownerid = ownerid,
		ver = version,
	})

	local ok, raw = pcall(function()
		return httpGet(url)
	end)
	if not ok or type(raw) ~= "string" then
		return false, "KeyAuth: sin respuesta (init)"
	end

	local data = decodeJson(raw)
	if type(data) ~= "table" then
		return false, "KeyAuth: JSON invalido (init)"
	end
	if data.success ~= true then
		return false, data.message or "KeyAuth: init fallo"
	end
	if type(data.sessionid) ~= "string" or data.sessionid == "" then
		return false, "KeyAuth: sin sessionid"
	end

	return true, data.sessionid
end

function KeyAuth.license(config, key, sessionid)
	config = config or {}
	local name = config.name
	local ownerid = config.ownerid
	if type(key) ~= "string" or key == "" then
		return false, "Escribe tu license key"
	end
	if type(sessionid) ~= "string" or sessionid == "" then
		return false, "KeyAuth: sesion invalida"
	end

	local hwid = KeyAuth.getHwid()
	local httpGet = getHttp()
	local url = buildUrl({
		type = "license",
		name = name,
		ownerid = ownerid,
		key = key,
		sessionid = sessionid,
		hwid = hwid,
	})

	local ok, raw = pcall(function()
		return httpGet(url)
	end)
	if not ok or type(raw) ~= "string" then
		return false, "KeyAuth: sin respuesta (license)"
	end

	local data = decodeJson(raw)
	if type(data) ~= "table" then
		return false, "KeyAuth: JSON invalido (license)"
	end
	if data.success ~= true then
		return false, data.message or "KeyAuth: key invalida"
	end

	return true, "OK"
end

function KeyAuth.verify(config, key)
	local okInit, sessionidOrErr = KeyAuth.init(config)
	if not okInit then
		return false, sessionidOrErr
	end
	return KeyAuth.license(config, key, sessionidOrErr)
end

return KeyAuth
