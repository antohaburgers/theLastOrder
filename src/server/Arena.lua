--!strict
-- Builds the temporary greybox battlefield entirely from trusted Roblox primitives.
local Workspace = game:GetService("Workspace")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local Arena = {}

local function part(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material?): Part
    local item = Instance.new("Part")
    item.Name = name
    item.Anchored = true
    item.Size = size
    item.Position = position
    item.Color = color
    item.Material = material or Enum.Material.Concrete
    item.TopSurface = Enum.SurfaceType.Smooth
    item.BottomSurface = Enum.SurfaceType.Smooth
    item.Parent = parent
    return item
end

function Arena.Build()
    local existing = Workspace:FindFirstChild("TheLastOrderPrototype")
    if existing then
        existing:Destroy()
    end
    local world = Instance.new("Folder")
    world.Name = "TheLastOrderPrototype"
    world.Parent = Workspace

    part(world, "Ground", Config.ArenaSize, Vector3.new(0, -1, 0), Color3.fromRGB(79, 111, 80), Enum.Material.Grass)

    -- Keep the core lanes open; obstacles are deliberately sparse for the first AI test.
    for _, x in ipairs({-43, -23, 23, 43}) do
        for _, z in ipairs({-31, 31}) do
            part(world, "Cover", Vector3.new(14, 6, 6), Vector3.new(x, 3, z), Color3.fromRGB(105, 108, 102))
        end
    end
    for _, z in ipairs({-46, 46}) do
        part(world, "FlankCover", Vector3.new(10, 6, 10), Vector3.new(0, 3, z), Color3.fromRGB(92, 96, 93))
    end

    for team, spawnPos in pairs(Config.BasePositions) do
        local plate = part(world, team .. "Base", Vector3.new(24, 1, 28), Vector3.new(spawnPos.X, 0.5, 0), Config.TeamColors[team])
        plate.Transparency = 0.35
        plate.CanCollide = true
        local marker = part(world, team .. "Flag", Vector3.new(1, 18, 1), Vector3.new(spawnPos.X, 9, -10), Config.TeamColors[team], Enum.Material.Neon)
        marker.CanCollide = false
    end

    local point = part(world, "ObjectiveB", Vector3.new(0.5, 30, 30), Vector3.new(0, 0.25, 0), Color3.fromRGB(231, 185, 73), Enum.Material.Neon)
    point.Shape = Enum.PartType.Cylinder
    point.CFrame = CFrame.new(0, 0.25, 0) * CFrame.Angles(0, 0, math.rad(90))
    point.CanCollide = false
    point.Transparency = 0.45

    local sign = Instance.new("BillboardGui")
    sign.Name = "CaptureDisplay"
    sign.Adornee = point
    sign.AlwaysOnTop = true
    sign.Size = UDim2.fromOffset(240, 64)
    sign.StudsOffset = Vector3.new(0, 7, 0)
    sign.Parent = point
    local label = Instance.new("TextLabel")
    label.Name = "Status"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 0.3
    label.BackgroundColor3 = Color3.fromRGB(18, 23, 30)
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Text = "B - NEUTRAL"
    label.Parent = sign

    return world, label
end

return Arena
