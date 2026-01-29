local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

if getgenv().AutoKillLoaded then return end
getgenv().AutoKillLoaded = true

local Character, Humanoid, Hand, Punch, Animator
local LastAttack, LastRespawn, LastCheck = 0, 0, 0
local Running = true
local StartTime = os.time()
local WhitelistFriends = true
local KillOnlyWeaker = true

-- ⭐ Auto Hop Toggle
local AutoHopEnabled = false

getgenv().WhitelistedPlayers = getgenv().WhitelistedPlayers or {}
getgenv().TempWhitelistStronger = getgenv().TempWhitelistStronger or {}

---------------------------------------------------
-- SERVER HOP FUNCTION
---------------------------------------------------

local function ServerHop()
    local success, servers = pcall(function()
        local req = game:HttpGet(
            "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
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
            local serverId = available[math.random(1, #available)]
            TeleportService:TeleportToPlaceInstance(PlaceId, serverId, LocalPlayer)
        end
    end
end

-- Auto hop loop
task.spawn(function()
    while true do
        task.wait(10)
        if AutoHopEnabled and #Players:GetPlayers() <= 1 then
            ServerHop()
        end
    end
end)

---------------------------------------------------
-- CHARACTER UPDATE
---------------------------------------------------

local function UpdateAll()
    Character = LocalPlayer.Character
    if Character then
        Humanoid = Character:FindFirstChildOfClass("Humanoid")
        Hand = Character:FindFirstChild("LeftHand") or Character:FindFirstChild("Left Arm")
        Punch = Character:FindFirstChild("Punch")
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    UpdateAll()
end)

UpdateAll()

---------------------------------------------------
-- AUTO ATTACK LOOP
---------------------------------------------------

RunService.RenderStepped:Connect(function()
    if not Running then return end

    if not Character or not Humanoid then
        UpdateAll()
        return
    end

    if not Punch then
        local Tool = LocalPlayer.Backpack:FindFirstChild("Punch")
        if Tool then
            Humanoid:EquipTool(Tool)
            Punch = Character:FindFirstChild("Punch")
        end
        return
    end

    Punch.attackTime.Value = 0
    Punch:Activate()

    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character then
            local Head = Player.Character:FindFirstChild("Head")
            local Root = Player.Character:FindFirstChild("HumanoidRootPart")
            local Hum2 = Player.Character:FindFirstChildOfClass("Humanoid")

            if Head and Root and Hum2 and Hum2.Health > 0 then
                firetouchinterest(Head, Hand, 0)
                firetouchinterest(Head, Hand, 1)
            end
        end
    end
end)

---------------------------------------------------
-- ANTI AFK
---------------------------------------------------

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

---------------------------------------------------
-- GUI
---------------------------------------------------

local Screen = Instance.new("ScreenGui", game.CoreGui)
Screen.ResetOnSpawn = false

local Main = Instance.new("Frame", Screen)
Main.Size = UDim2.new(0, 200, 0, 180)
Main.Position = UDim2.new(0.5, -100, 0.1, 0)
Main.BackgroundColor3 = Color3.fromRGB(25,25,25)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1,0,0,25)
Title.Text = "Auto Kill Panel"
Title.TextColor3 = Color3.new(1,1,1)
Title.BackgroundTransparency = 1

local StartButton = Instance.new("TextButton", Main)
StartButton.Position = UDim2.new(0,10,0,40)
StartButton.Size = UDim2.new(0,80,0,25)
StartButton.Text = "Start"

local StopButton = Instance.new("TextButton", Main)
StopButton.Position = UDim2.new(0,110,0,40)
StopButton.Size = UDim2.new(0,80,0,25)
StopButton.Text = "Stop"

local HopToggle = Instance.new("TextButton", Main)
HopToggle.Position = UDim2.new(0,10,0,80)
HopToggle.Size = UDim2.new(0,180,0,25)
HopToggle.Text = "Auto Server Hop: OFF"

---------------------------------------------------
-- BUTTON LOGIC
---------------------------------------------------

StartButton.MouseButton1Click:Connect(function()
    Running = true
end)

StopButton.MouseButton1Click:Connect(function()
    Running = false
end)

HopToggle.MouseButton1Click:Connect(function()
    AutoHopEnabled = not AutoHopEnabled
    HopToggle.Text = "Auto Server Hop: " .. (AutoHopEnabled and "ON" or "OFF")
end)