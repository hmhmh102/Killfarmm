local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

if getgenv().AutoKillLoaded then return end
getgenv().AutoKillLoaded = true

local Character, Humanoid, Hand, Punch, Animator
local LastAttack, LastRespawn, LastCheck = 0, 0, 0
local Running = true
local StartTime = os.time()
local WhitelistFriends = true
local KillOnlyWeaker = true

-- Auto Server Hop
local AutoHopEnabled = false
local LastHopTime = 0
local HopCooldown = 300 -- 5 minutes

getgenv().WhitelistedPlayers = getgenv().WhitelistedPlayers or {}
getgenv().TempWhitelistStronger = getgenv().TempWhitelistStronger or {}

-- Blocked animations (your old code)
local BlockedAnimations = {
    ["rbxassetid://3638729053"] = true,
    ["rbxassetid://3638749874"] = true,
    ["rbxassetid://3638767427"] = true,
    ["rbxassetid://102357151005774"] = true
}

---------------------------------------------------
-- SERVER HOP FUNCTION
---------------------------------------------------
local function ServerHop()
    if os.time() - LastHopTime < 15 then return end
    LastHopTime = os.time()

    local success, servers = pcall(function()
        local req = game:HttpGet(
            "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        )
        return HttpService:JSONDecode(req)
    end)

    if success and servers and servers.data then
        local available = {}
        for _, v in pairs(servers.data) do
            if v.playing < v.maxPlayers then
                table.insert(available, v.id)
            end
        end
        if #available > 0 then
            local serverId = available[math.random(1,#available)]
            TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
        end
    end
end

-- Auto Hop Loop
task.spawn(function()
    while true do
        task.wait(10)
        if AutoHopEnabled then
            -- Hop if server is empty
            if #Players:GetPlayers() <= 1 then
                ServerHop()
            end
            -- Hop every 5 minutes
            if os.time() - LastHopTime >= HopCooldown then
                ServerHop()
            end
        end
    end
end)

---------------------------------------------------
-- Your old UI + character / attack code
---------------------------------------------------

-- (You can paste your full old code here for updating Character, Humanoid, auto attack, punch, whitelist, etc.)

-- Example GUI creation snippet from old script:

local Screen = Instance.new("ScreenGui")
Screen.Parent = game:GetService("CoreGui")
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.ResetOnSpawn = false

local Main = Instance.new("Frame")
Main.Parent = Screen
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Main.BackgroundTransparency = 0.1
Main.Position = UDim2.new(0.5, -90, 0.1, 0)
Main.Size = UDim2.new(0, 180, 0, 180) -- increased height to fit new button

-- (TitleBar, Labels, Start/Stop, WhitelistToggle, WeakerToggle as in your old script)

-- NEW Auto Hop Toggle Button
local AutoHopToggle = Instance.new("TextButton")
AutoHopToggle.Parent = Main
AutoHopToggle.BackgroundColor3 = Color3.fromRGB(30,30,30)
AutoHopToggle.Position = UDim2.new(0,8,0,168) -- fits below other buttons
AutoHopToggle.Size = UDim2.new(1,-16,0,18)
AutoHopToggle.Font = Enum.Font.Code
AutoHopToggle.TextSize = 13
AutoHopToggle.TextColor3 = Color3.fromRGB(255,255,255)
AutoHopToggle.Text = "Auto Server Hop: OFF"

AutoHopToggle.MouseButton1Click:Connect(function()
    AutoHopEnabled = not AutoHopEnabled
    AutoHopToggle.Text = "Auto Server Hop: " .. (AutoHopEnabled and "ON" or "OFF")
    AutoHopToggle.TextColor3 = AutoHopEnabled and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,255,255)
end)

---------------------------------------------------
-- Continue your old code here for:
-- Whitelist, Weaker Only, Start/Stop, FPS, Time, Exec labels, draggable window, etc.
---------------------------------------------------