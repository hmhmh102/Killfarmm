-- ===== AUTO-KILL SCRIPT START =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

if getgenv().AutoKillLoaded then
    return
end
getgenv().AutoKillLoaded = true

local Character, Humanoid, Hand, Punch, Animator
local LastAttack, LastRespawn, LastCheck = 0, 0, 0
local Running = true
local StartTime = os.time()
local WhitelistFriends = true
local KillOnlyWeaker = true

if getgenv().AutoStartEnabled then
    Running = true
end

getgenv().WhitelistedPlayers = getgenv().WhitelistedPlayers or {}
getgenv().TempWhitelistStronger = getgenv().TempWhitelistStronger or {}

local BlockedAnimations = {
    ["rbxassetid://3638729053"] = true,
    ["rbxassetid://3638749874"] = true,
    ["rbxassetid://3638767427"] = true,
    ["rbxassetid://102357151005774"] = true
}

for _, obj in pairs(ReplicatedStorage:GetChildren()) do
    if obj.Name:match("Frame$") then
        obj.Visible = false
    end
end

local function GetPlayerStatValue(Player, StatNames)
    if not Player then return nil end
    if type(StatNames) == "string" then StatNames = {StatNames} end
    for _, Name in ipairs(StatNames) do
        local Attr
        if typeof(Player.GetAttribute) == "function" then
            Attr = Player:GetAttribute(Name)
        end
        if Attr ~= nil then return tonumber(Attr) end
    end
    local Leaderstats = Player:FindFirstChild("leaderstats")
    if Leaderstats then
        for _, Name in ipairs(StatNames) do
            local V = Leaderstats:FindFirstChild(Name)
            if V and V.Value ~= nil then return tonumber(V.Value) end
        end
    end
    if Player.Character then
        for _, Name in ipairs(StatNames) do
            local V = Player.Character:FindFirstChild(Name)
            if V and V.Value ~= nil then return tonumber(V.Value) end
        end
    end
    return nil
end

local function GetLocalPlayerDamage()
    return GetPlayerStatValue(LocalPlayer, {"Damage","DMG","Attack","Strength","Str"}) or 1
end

local function GetTargetHealth(Player)
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        return Player.Character.Humanoid.MaxHealth
    end
    return 100
end

local function UpdateWhitelist()
    if WhitelistFriends then
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer ~= LocalPlayer and targetPlayer:IsFriendsWith(LocalPlayer.UserId) then
                local playerName = targetPlayer.Name
                local alreadyWhitelisted = false
                for _, name in ipairs(getgenv().WhitelistedPlayers) do
                    if name:lower() == playerName:lower() then
                        alreadyWhitelisted = true
                        break
                    end
                end
                if not alreadyWhitelisted then
                    table.insert(getgenv().WhitelistedPlayers, playerName)
                end
            end
        end
    else
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer ~= LocalPlayer and targetPlayer:IsFriendsWith(LocalPlayer.UserId) then
                local playerName = targetPlayer.Name
                for i = #getgenv().WhitelistedPlayers, 1, -1 do
                    if getgenv().WhitelistedPlayers[i]:lower() == playerName:lower() then
                        table.remove(getgenv().WhitelistedPlayers, i)
                    end
                end
            end
        end
    end
end

local function IsWhitelisted(player)
    if not WhitelistFriends then return false end
    for _, name in ipairs(getgenv().WhitelistedPlayers) do
        if name:lower() == player.Name:lower() then
            return true
        end
    end
    return false
end

local function IsTempWhitelisted(player)
    for _, name in ipairs(getgenv().TempWhitelistStronger) do
        if name:lower() == player.Name:lower() then
            return true
        end
    end
    return false
end

local function ShouldKillPlayer(player)
    if not KillOnlyWeaker then return true end
    if IsTempWhitelisted(player) then return false end
    local MyDamage = GetLocalPlayerDamage()
    local Health = GetTargetHealth(player)
    if Health and MyDamage and MyDamage > 0 then
        local HitsNeeded = math.ceil(Health / MyDamage)
        if HitsNeeded > 5 then
            local AlreadyWhitelisted = false
            for _, Name in ipairs(getgenv().TempWhitelistStronger) do
                if Name:lower() == player.Name:lower() then
                    AlreadyWhitelisted = true
                    break
                end
            end
            if not AlreadyWhitelisted then
                table.insert(getgenv().TempWhitelistStronger, player.Name)
            end
            return false
        end
        return true
    end
    return true
end

local function UpdateAll()
    Character = LocalPlayer.Character
    if Character then
        Humanoid = Character:FindFirstChildOfClass("Humanoid")
        Hand = Character:FindFirstChild("LeftHand") or Character:FindFirstChild("Left Arm")
        Animator = Humanoid and (Character:FindFirstChildOfClass("Animator") or Humanoid:FindFirstChildOfClass("Animator"))
        Punch = Character:FindFirstChild("Punch")
    else
        Character, Humanoid, Hand, Animator, Punch = nil, nil, nil, nil, nil
    end
end

local function UpdateAntiKnockback()
    local RootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if RootPart and not getgenv().AntiKnockbackVelocity then
        getgenv().AntiKnockbackVelocity = Instance.new("BodyVelocity")
        getgenv().AntiKnockbackVelocity.MaxForce = Vector3.new(100000, 0, 100000)
        getgenv().AntiKnockbackVelocity.Velocity = Vector3.new(0, 0, 0)
        getgenv().AntiKnockbackVelocity.P = 1250
        getgenv().AntiKnockbackVelocity.Parent = RootPart
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    UpdateAll()
    task.wait(1)
    UpdateAntiKnockback()
end)
Players.PlayerAdded:Connect(function()
    UpdateWhitelist()
    getgenv().TempWhitelistStronger = {}
end)
Players.PlayerRemoving:Connect(function(player)
    for i = #getgenv().TempWhitelistStronger, 1, -1 do
        if getgenv().TempWhitelistStronger[i]:lower() == player.Name:lower() then
            table.remove(getgenv().TempWhitelistStronger, i)
        end
    end
end)
UpdateAll()
UpdateAntiKnockback()
UpdateWhitelist()

if not getgenv().AnimBlockConnection then
    getgenv().AnimBlockConnection = RunService.RenderStepped:Connect(function()
        if Character and Humanoid then
            for _, Track in ipairs(Humanoid:GetPlayingAnimationTracks()) do
                if Track.Animation then
                    local AnimId = Track.Animation.AnimationId
                    local AnimName = Track.Name:lower()
                    if BlockedAnimations[AnimId] or AnimName:match("punch") or AnimName:match("attack") then
                        Track:Stop()
                    end
                end
            end
        end
    end)
end

RunService.RenderStepped:Connect(function()
    if not Running then return end
    local TimeNow = os.clock()
    if TimeNow - LastAttack < 0.05 then return end
    LastAttack = TimeNow
    if not Character or not Humanoid or TimeNow - LastCheck > 1 then
        UpdateAll()
        LastCheck = TimeNow
        if not Character or not Humanoid then return end
    end
    if not Hand then
        Hand = Character:FindFirstChild("LeftHand") or Character:FindFirstChild("Left Arm")
        if not Hand then return end
    end
    if not Punch or not Punch.Parent then
        Punch = Character:FindFirstChild("Punch")
        if not Punch then
            local Tool = LocalPlayer.Backpack:FindFirstChild("Punch")
            if Tool then
                Humanoid:EquipTool(Tool)
                Punch = Character:FindFirstChild("Punch")
            else
                if TimeNow - LastRespawn > 3 and Humanoid and Humanoid.Health > 0 then
                    Humanoid.Health = 0
                    LastRespawn = TimeNow
                end
                return
            end
        end
    end
    if Punch and Punch.Parent then
        Punch.attackTime.Value = 0
        Punch:Activate()
        for _, Player in ipairs(Players:GetPlayers()) do
            if Player ~= LocalPlayer and not IsWhitelisted(Player) and ShouldKillPlayer(Player) then
                local Character2 = Player.Character
                if Character2 and Character2.Parent then
                    local Humanoid2 = Character2:FindFirstChildOfClass("Humanoid")
                    local Head = Character2:FindFirstChild("Head")
                    local RootPart = Character2:FindFirstChild("HumanoidRootPart")
                    if Humanoid2 and Head and RootPart and Humanoid2.Health > 0 then
                        local WasAnchored = RootPart.Anchored
                        RootPart.Anchored = true
                        firetouchinterest(Head, Hand, 0)
                        firetouchinterest(Head, Hand, 1)
                        RootPart.Anchored = WasAnchored
                    end
                end
            end
        end
    end
end)

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ===== GUI SETUP (UNCHANGED) =====
-- [Your GUI code stays exactly the same]

RunService.RenderStepped:Connect(function()
    FpsLabel.Text = "fps: " .. math.floor(1/RunService.RenderStepped:Wait())
    TimeLabel.Text = "time: " .. os.date("%H:%M:%S")
    local Elapsed = os.time() - StartTime
    ExecLabel.Text = string.format("exec: %02d:%02d:%02d", Elapsed/3600%24, Elapsed/60%60, Elapsed%60)
end)

-- ===== COMPACT SERVER HOP WHEN ONLY 1 PLAYER =====
local HttpService, TeleportService, PlaceId = game:GetService("HttpService"), game:GetService("TeleportService"), game.PlaceId

task.spawn(function()
    while task.wait(5) do
        if #game:GetService("Players"):GetPlayers() <= 1 then
            local servers, cursor = {}, nil
            repeat
                local url = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
                if cursor then url = url.."&cursor="..cursor end
                local success, response = pcall(game.HttpGet, game, url)
                if not success or not response then break end
                local data = HttpService:JSONDecode(response)
                for _, s in ipairs(data.data) do if s.playing < s.maxPlayers and s.id ~= game.JobId then table.insert(servers, s.id) end end
                cursor = data.nextPageCursor
            until not cursor
            if #servers > 0 then TeleportService:TeleportToPlaceInstance(PlaceId, servers[math.random(#servers)], game.Players.LocalPlayer) end
            break
        end
    end
end)