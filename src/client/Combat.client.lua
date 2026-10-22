--!strict
-- PC test controls: WASD default Roblox movement; left-click fire; V toggles camera.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local remotes = ReplicatedStorage:WaitForChild("TLO_Remotes")
local requestFire = remotes:WaitForChild("RequestFire") :: RemoteEvent
local shotVisual = remotes:WaitForChild("ShotVisual") :: RemoteEvent
local camera = workspace.CurrentCamera

local firstPerson = false
local firing = false
local lastShot = 0
local fireInterval = 0.38

local gui = Instance.new("ScreenGui")
gui.Name = "TLOPrototypeHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local hud = Instance.new("TextLabel")
hud.Name = "Instructions"
hud.Position = UDim2.fromOffset(16, 18)
hud.Size = UDim2.fromOffset(330, 74)
hud.BackgroundColor3 = Color3.fromRGB(20, 25, 33)
hud.BackgroundTransparency = 0.2
hud.TextColor3 = Color3.new(1, 1, 1)
hud.TextSize = 16
hud.Font = Enum.Font.Gotham
hud.TextXAlignment = Enum.TextXAlignment.Left
hud.TextYAlignment = Enum.TextYAlignment.Center
hud.Text = "THE LAST ORDER — PROTOTYPE\nWASD: move | LMB: fire | V: camera"
hud.Parent = gui
local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 12)
padding.Parent = hud

local function setMode(useFirstPerson: boolean)
    firstPerson = useFirstPerson
    camera = workspace.CurrentCamera
    if firstPerson then
        player.CameraMode = Enum.CameraMode.LockFirstPerson
        camera.CameraType = Enum.CameraType.Custom
    else
        player.CameraMode = Enum.CameraMode.Classic
        camera.CameraType = Enum.CameraType.Scriptable
    end
    hud.Text = "THE LAST ORDER — PROTOTYPE\nWASD / LMB / V | " .. (firstPerson and "FPS" or "TACTICAL")
end
setMode(false)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.V then
        setMode(not firstPerson)
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        firing = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then firing = false end
end)

local function aimPoint(root: BasePart): Vector3
    if firstPerson then
        return camera.CFrame.Position + camera.CFrame.LookVector * 200
    end
    -- Intersect mouse ray with a horizontal plane through character's upper torso.
    local ray = mouse.UnitRay
    local planeY = root.Position.Y + 2
    if math.abs(ray.Direction.Y) < 0.001 then
        return root.Position + root.CFrame.LookVector * 120
    end
    local distance = (planeY - ray.Origin.Y) / ray.Direction.Y
    if distance <= 0 then return root.Position + root.CFrame.LookVector * 120 end
    return ray.Origin + ray.Direction * distance
end

RunService.RenderStepped:Connect(function()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") and not firstPerson then
        local focus = root.Position + Vector3.new(0, 2, 0)
        camera.CFrame = CFrame.lookAt(focus + Vector3.new(0, 53, 48), focus)
    end
    if firing and root and root:IsA("BasePart") and os.clock() - lastShot >= fireInterval then
        lastShot = os.clock()
        requestFire:FireServer(aimPoint(root))
    end
end)

shotVisual.OnClientEvent:Connect(function(origin: Vector3, endpoint: Vector3, color: Color3)
    if typeof(origin) ~= "Vector3" or typeof(endpoint) ~= "Vector3" then return end
    local distance = (endpoint - origin).Magnitude
    if distance < 0.1 then return end
    local tracer = Instance.new("Part")
    tracer.Name = "ShotTracer"
    tracer.Anchored = true
    tracer.CanCollide = false
    tracer.CanQuery = false
    tracer.CanTouch = false
    tracer.Material = Enum.Material.Neon
    tracer.Color = color
    tracer.Size = Vector3.new(0.12, 0.12, distance)
    tracer.CFrame = CFrame.lookAt((origin + endpoint) * 0.5, endpoint)
    tracer.Parent = workspace
    Debris:AddItem(tracer, 0.09)
end)
