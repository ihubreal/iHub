--[[
    I-Hub for Murder Mystery 2.
    Place id 142823291. UI: Player, Visuals, Autofarm, WIP. Build 9.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local LocalPlayer = Players.LocalPlayer

local WalkSpeed = 16
local JumpPower = 50

local function applyMovement()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end
    humanoid.WalkSpeed = WalkSpeed
    humanoid.UseJumpPower = true
    humanoid.JumpPower = JumpPower
end

LocalPlayer.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.WalkSpeed = WalkSpeed
    humanoid.UseJumpPower = true
    humanoid.JumpPower = JumpPower
end)

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ImInsane-1337/neverlose-ui/refs/heads/main/source/library.lua"))()

Library.Folders = {
    Directory = "I-Hub",
    Configs = "I-Hub/Configs",
    Assets = "I-Hub/Assets",
}
Library.MenuKeybind = tostring(Enum.KeyCode.RightShift)

local Window = Library:Window({
    Name = "I-Hub",
    SubName = "MM2",
})

Window:Category("Murder Mystery 2")

local PlayerPage = Window:Page({ Name = "Player", Columns = 1 })
local PlayerSection = PlayerPage:Section({ Name = "Movement", Side = 1 })

PlayerSection:Label("Right Shift hides the menu.")
PlayerSection:Slider({
    Name = "Walk speed",
    Min = 16,
    Max = 100,
    Default = 16,
    Callback = function(value)
        WalkSpeed = value
        applyMovement()
    end,
})
PlayerSection:Slider({
    Name = "Jump power",
    Min = 50,
    Max = 200,
    Default = 50,
    Callback = function(value)
        JumpPower = value
        applyMovement()
    end,
})

local EspSettings = {
    innocent = false,
    sheriff = false,
    murder = false,
}

local EspColors = {
    Innocent = Color3.fromRGB(50, 255, 90),
    Sheriff = Color3.fromRGB(70, 130, 255),
    Murderer = Color3.fromRGB(255, 55, 55),
}

local EspHighlights = {}
local RoundRoles = {}
local EspLastRole = {}
local EspClock = 0
local LobbyModel = nil
local LobbyParts = {}

local function hasNamedTool(parent, toolName)
    if not parent then
        return false
    end
    return parent:FindFirstChild(toolName) ~= nil
end

local function normalizeRole(roleName)
    if roleName == "Murderer" then
        return "Murderer"
    end
    if roleName == "Sheriff" then
        return "Sheriff"
    end
    return "Innocent"
end

local function roleFromGear(player)
    local backpack = player:FindFirstChildOfClass("Backpack")
    local character = player.Character

    if hasNamedTool(backpack, "Gun") or hasNamedTool(character, "Gun") then
        return "Sheriff"
    end
    if hasNamedTool(backpack, "Knife") or hasNamedTool(character, "Knife") then
        return "Murderer"
    end

    return "Innocent"
end

local function isAlivePlayer(player)
    local attributes = player:GetAttributes()
    return attributes.Alive == true
end

local function getPlayerRole(player)
    if not isAlivePlayer(player) then
        return "Dead"
    end

    local fromRound = RoundRoles[player]
    if fromRound then
        return normalizeRole(fromRound)
    end

    return roleFromGear(player)
end

local function clearAllEsp()
    for _, highlight in EspHighlights do
        if highlight then
            highlight:Destroy()
        end
    end
    table.clear(EspHighlights)
    table.clear(EspLastRole)
end

local function removeEsp(player)
    local highlight = EspHighlights[player]
    if highlight then
        highlight:Destroy()
        EspHighlights[player] = nil
    end
    EspLastRole[player] = nil
end

local function refreshLobbyParts()
    local lobby = Workspace:FindFirstChild("RegularLobby")
    if lobby == LobbyModel then
        return
    end

    LobbyModel = lobby
    table.clear(LobbyParts)

    if lobby and lobby:IsA("Model") then
        for _, part in lobby:GetDescendants() do
            if part:IsA("BasePart") then
                table.insert(LobbyParts, part)
            end
        end
    end
end

local function pointInsidePart(point, part)
    local localPos = part.CFrame:PointToObjectSpace(point)
    local half = part.Size * 0.5
    return math.abs(localPos.X) <= half.X
        and math.abs(localPos.Y) <= half.Y
        and math.abs(localPos.Z) <= half.Z
end

local function isPlayerInRegularLobby(player)
    if EspClock % 90 == 0 then
        refreshLobbyParts()
    end

    if not LobbyModel or #LobbyParts == 0 then
        return false
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return false
    end

    for _, part in LobbyParts do
        if part.Parent and pointInsidePart(root.Position, part) then
            return true
        end
    end

    return false
end

local function applyEsp(player, role)
    if role == "Dead" then
        removeEsp(player)
        return
    end

    local character = player.Character
    if not character then
        removeEsp(player)
        return
    end

    if isPlayerInRegularLobby(player) then
        removeEsp(player)
        return
    end

    local enabled = false
    if role == "Murderer" and EspSettings.murder then
        enabled = true
    elseif role == "Sheriff" and EspSettings.sheriff then
        enabled = true
    elseif role == "Innocent" and EspSettings.innocent then
        enabled = true
    end

    if not enabled then
        removeEsp(player)
        return
    end

    if EspLastRole[player] ~= role then
        removeEsp(player)
        EspLastRole[player] = role
    end

    local highlight = EspHighlights[player]
    if not highlight or not highlight.Parent or highlight.Parent ~= character then
        removeEsp(player)
        EspLastRole[player] = role
        highlight = Instance.new("Highlight")
        highlight.Name = "IHubESP"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 0.55
        highlight.OutlineTransparency = 0.15
        EspHighlights[player] = highlight
    end

    highlight.Adornee = character
    highlight.Parent = character
    highlight.FillColor = EspColors[role]
    highlight.OutlineColor = EspColors[role]
    highlight.Enabled = true
end

local function updateEsp()
    for _, player in Players:GetPlayers() do
        if player == LocalPlayer then
            continue
        end
        applyEsp(player, getPlayerRole(player))
    end
end

local function applyFadeRoles(data)
    if typeof(data) ~= "table" then
        return
    end
    for _, player in Players:GetPlayers() do
        local info = data[player.Name]
        if typeof(info) == "table" and info.Role then
            RoundRoles[player] = info.Role
        else
            RoundRoles[player] = nil
        end
    end
end

local function bindRoundRemotes()
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
    if not remotes then
        return
    end

    local gameplay = remotes:WaitForChild("Gameplay", 15)
    if not gameplay then
        return
    end

    local fade = gameplay:FindFirstChild("Fade")
    if fade and fade:IsA("RemoteEvent") then
        fade.OnClientEvent:Connect(function(data)
            clearAllEsp()
            table.clear(RoundRoles)
            applyFadeRoles(data)
            task.delay(0.35, updateEsp)
            task.delay(0.9, updateEsp)
            task.delay(1.6, updateEsp)
        end)
    end

    local roundEnd = gameplay:FindFirstChild("RoundEndFade")
    if roundEnd and roundEnd:IsA("RemoteEvent") then
        roundEnd.OnClientEvent:Connect(function()
            clearAllEsp()
            table.clear(RoundRoles)
        end)
    end
end

local function hookPlayer(player)
    player.CharacterAdded:Connect(function()
        removeEsp(player)
        task.delay(0.4, updateEsp)
        task.delay(1, updateEsp)
    end)

    player.AttributeChanged:Connect(function(name)
        if name ~= "Alive" then
            return
        end
        if not isAlivePlayer(player) then
            RoundRoles[player] = nil
            removeEsp(player)
        end
        task.defer(updateEsp)
    end)
end

bindRoundRemotes()
for _, player in Players:GetPlayers() do
    hookPlayer(player)
end
Players.PlayerAdded:Connect(hookPlayer)

local VisualsPage = Window:Page({ Name = "Visuals", Columns = 1 })
local EspSection = VisualsPage:Section({ Name = "ESP", Side = 1 })

EspSection:Label("Green = innocent, blue = sheriff, red = murder.")
EspSection:Toggle({
    Name = "All",
    Default = false,
    Callback = function(value)
        EspSettings.innocent = value
        updateEsp()
    end,
})
EspSection:Toggle({
    Name = "Sheriff",
    Default = false,
    Callback = function(value)
        EspSettings.sheriff = value
        updateEsp()
    end,
})
EspSection:Toggle({
    Name = "Murder",
    Default = false,
    Callback = function(value)
        EspSettings.murder = value
        updateEsp()
    end,
})

Players.PlayerRemoving:Connect(removeEsp)

local ExtraSettings = {
    coins = false,
    gun = false,
}

local WorldHighlights = {}
local WorldKinds = {}

local WorldColors = {
    coin = Color3.fromRGB(255, 220, 60),
    gun = Color3.fromRGB(70, 140, 255),
}

local function removeWorldHighlight(part)
    local highlight = WorldHighlights[part]
    if highlight then
        highlight:Destroy()
    end
    WorldHighlights[part] = nil
    WorldKinds[part] = nil
end

local function clearWorldHighlights(kind)
    for part, highlight in WorldHighlights do
        if not kind or WorldKinds[part] == kind then
            if highlight then
                highlight:Destroy()
            end
            WorldHighlights[part] = nil
            WorldKinds[part] = nil
        end
    end
end

local function applyWorldHighlight(target, kind)
    local highlight = WorldHighlights[target]
    if not highlight or not highlight.Parent then
        highlight = Instance.new("Highlight")
        highlight.Name = "IHubWorldESP"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 0.45
        highlight.OutlineTransparency = 0.2
        WorldHighlights[target] = highlight
    end

    WorldKinds[target] = kind
    highlight.Adornee = target
    highlight.Parent = target
    highlight.FillColor = WorldColors[kind]
    highlight.OutlineColor = WorldColors[kind]
    highlight.Enabled = true
end

local function getActiveMap()
    for _, inst in CollectionService:GetTagged("CurrentMap") do
        if not inst:IsDescendantOf(Workspace) then
            continue
        end

        local map = inst:IsA("Model") and inst or inst:FindFirstAncestorWhichIsA("Model")
        if map and map:IsDescendantOf(Workspace) then
            return map
        end
    end

    return nil
end

local function isCoinReady(coin)
    if coin.Name ~= "Coin_Server" then
        return false
    end
    if coin:GetAttribute("CoinID") == nil then
        return false
    end
    if not (coin:IsA("Model") or coin:IsA("BasePart")) then
        return false
    end

    local visual = coin:FindFirstChild("CoinVisual")
    if visual and visual:GetAttribute("Collected") == true then
        return false
    end

    return true
end

local function updateWorldExtras()
    if not ExtraSettings.coins and not ExtraSettings.gun then
        return
    end

    local seen = {}

    if ExtraSettings.coins then
        local map = getActiveMap()
        local container = map and map:FindFirstChild("CoinContainer")
        if container then
            for _, coin in container:GetChildren() do
                if isCoinReady(coin) then
                    applyWorldHighlight(coin, "coin")
                    seen[coin] = true
                end
            end
        end
    end

    if ExtraSettings.gun then
        local gun = Workspace:FindFirstChild("GunDrop")
        if gun and (gun:IsA("Model") or gun:IsA("BasePart")) then
            applyWorldHighlight(gun, "gun")
            seen[gun] = true
        end
    end

    for target in WorldHighlights do
        if not seen[target] or not target.Parent then
            removeWorldHighlight(target)
        end
    end
end

local ExtrasSection = VisualsPage:Section({ Name = "Extras", Side = 1 })

ExtrasSection:Toggle({
    Name = "Coins",
    Default = false,
    Callback = function(value)
        ExtraSettings.coins = value
        if not value then
            clearWorldHighlights("coin")
        else
            updateWorldExtras()
        end
    end,
})
ExtrasSection:Toggle({
    Name = "Gun",
    Default = false,
    Callback = function(value)
        ExtraSettings.gun = value
        if not value then
            clearWorldHighlights("gun")
        else
            updateWorldExtras()
        end
    end,
})

RunService.Heartbeat:Connect(function()
    EspClock += 1
    if EspClock % 4 == 0 then
        updateEsp()
    end
    if (ExtraSettings.coins or ExtraSettings.gun) and EspClock % 6 == 0 then
        updateWorldExtras()
    end
end)

local AutofarmPage = Window:Page({ Name = "Autofarm", Columns = 1 })
local AutofarmSection = AutofarmPage:Section({ Name = "Autofarm", Side = 1 })

AutofarmSection:Label("Autofarm modules will go here.")

local WipPage = Window:Page({ Name = "WIP", Columns = 1 })
local WipSection = WipPage:Section({ Name = "Work in progress", Side = 1 })

WipSection:Label("Features in development.")
WipSection:Label("Check back in a later update.")

Window:Init()

print("[I-Hub] MM2 hub loaded (build 9).")
