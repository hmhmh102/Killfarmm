-- Roblox script
local Players = game:GetService("Players")

print("Roblox script loaded")

Players.PlayerAdded:Connect(function(player)
    print("Player joined:", player.Name)
end)

-- Create a visible anchored part in Workspace
local part = Instance.new("Part")
part.Name = "HelloPart"
part.Size = Vector3.new(6, 1, 6)
part.Position = Vector3.new(0, 5, 0)
part.Anchored = true
part.BrickColor = BrickColor.new("Bright green")
part.Parent = workspace
