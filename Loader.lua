--[[
    I-Hub loader flow:
    Loader -> fetch hub script from GitHub -> destroy loader UI -> wait -> run hub
]]

local AfterDestroyWait = 0.3
local LoaderVisibleSeconds = 0.6

local MarketplaceService = game:GetService("MarketplaceService")

local Base = "https://raw.githubusercontent.com/ihubreal/iHub/refs/heads/main"

local LoaderState = {}

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
    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ImInsane-1337/neverlose-ui/refs/heads/main/source/library.lua"))()
    Library.Folders = {
        Directory = "I-Hub",
        Configs = "I-Hub/Configs",
        Assets = "I-Hub/Assets",
    }
    Library.MenuKeybind = tostring(Enum.KeyCode.RightShift)

    local Window = Library:Window({
        Name = "I-Hub",
        SubName = "Loader",
    })

    Window:Category("Main")
    local Page = Window:Page({ Name = "Game", Columns = 1 })
    local Panel = Page:Section({ Name = "Game", Side = 1 })

    LoaderState.library = Library
    LoaderState.holder = Library.Holder and Library.Holder.Instance
    LoaderState.unused = Library.UnusedHolder and Library.UnusedHolder.Instance

    return Library, Window, Panel
end

local function destroyLoader()
    local library = LoaderState.library

    if type(library) == "table" and type(library.Connections) == "table" then
        for _, entry in library.Connections do
            pcall(function()
                if entry and entry.Connection then
                    entry.Connection:Disconnect()
                end
            end)
        end
    end

    if LoaderState.holder and LoaderState.holder.Parent then
        LoaderState.holder:Destroy()
    end
    if LoaderState.unused and LoaderState.unused.Parent then
        LoaderState.unused:Destroy()
    end

    if type(library) == "table" and type(library.Unload) == "function" then
        pcall(function()
            library:Unload()
        end)
    end

    getgenv().Library = nil
    LoaderState = {}
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
    local _, Window, Panel = openLoader()
    Panel:Label(placeName(game.PlaceId))
    if games then
        Panel:Label("This place is not in the hub list.")
    else
        Panel:Label("Could not read games/list.lua from GitHub.")
    end
    Window:Init()
    return
end

-- Loader (Neverlose opens the window in Library:Window; no Init here)
local _, _, Panel = openLoader()
Panel:Label(placeName(game.PlaceId))
Panel:Label("Hub: games/" .. fileName)
Panel:Label("Fetching script from GitHub...")

task.wait(LoaderVisibleSeconds)

-- Real load: HttpGet returns Lua source, not a file on disk
local hubSource = fetch("games/" .. fileName)
if not hubSource then
    Panel:Label("Could not fetch the hub script.")
    return
end

-- Destroy loader UI (Unload alone often fails on coroutine.close)
destroyLoader()

-- Wait
task.wait(AfterDestroyWait)

-- Juego
local loaded, loadError = pcall(function()
    loadstring(hubSource)()
end)
if not loaded then
    warn("[I-Hub] " .. tostring(loadError))
end
