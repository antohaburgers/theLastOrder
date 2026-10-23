--!strict
-- PC test controls: WASD default Roblox movement; left-click fire; V toggles camera.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local remotes = ReplicatedStorage:WaitForChild("TLO_Remotes")
local requestFire = remotes:WaitForChild("RequestFire") :: RemoteEvent
local shotVisual = remotes:WaitForChild("ShotVisual") :: RemoteEvent
local camera = workspace.CurrentCamera

local firstPerson = false
local firing = false
local lastShot = 0
local fireInterval = Config.PlayerFireInterval

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

-- Client-only effects; hit detection/damage stay exclusively on the server.
-- Projectile start time uses synchronized server clock to compensate latency.
local effects = Instance.new("Folder")
effects.Name = "TLOCombatFX"
effects.Parent = workspace

type BulletFx = {
    Part: Part,
    Trail: Trail,
    Origin: Vector3,
    Direction: Vector3,
    Speed: number,
    SpawnTime: number,
}
local bullets: {[number]: BulletFx} = {}

local function makeFlash(origin: Vector3, color: Color3)
    local flash = Instance.new("Part")
    flash.Name = "MuzzleFlash"
    flash.Shape = Enum.PartType.Ball
    flash.Anchored = true
    flash.CanCollide = false
    flash.CanTouch = false
    flash.CanQuery = false
    flash.CastShadow = false
    flash.Material = Enum.Material.Neon
    flash.Color = color
    flash.Size = Vector3.new(0.5, 0.5, 0.5)
    flash.Position = origin
    flash.Parent = effects
    local light = Instance.new("PointLight")
    light.Range = 8
    light.Brightness = 1.2
    light.Color = color
    light.Parent = flash
    TweenService:Create(flash, TweenInfo.new(0.10), {
        Size = Vector3.new(1.15, 1.15, 1.15),
        Transparency = 1,
    }):Play()
    Debris:AddItem(flash, 0.12)
end

local function finishBullet(id: number, endpoint: Vector3?)
    local bullet = bullets[id]
    if not bullet then return end
    bullets[id] = nil
    if endpoint then bullet.Part.Position = endpoint end
    bullet.Part.Transparency = 1
    bullet.Trail.Enabled = false
    -- Keep the old trail briefly so it fades naturally instead of popping.
    Debris:AddItem(bullet.Part, 0.20)
end

local function makeImpact(position: Vector3, normal: Vector3, hitEnemy: boolean)
    local impactColor = if hitEnemy then Color3.fromRGB(255, 112, 86) else Color3.fromRGB(255, 205, 124)
    local anchor = Instance.new("Part")
    anchor.Name = "BulletImpact"
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanTouch = false
    anchor.CanQuery = false
    anchor.CastShadow = false
    anchor.Transparency = 1
    anchor.Size = Vector3.new(0.2, 0.2, 0.2)
    anchor.CFrame = CFrame.lookAt(position, position + normal)
    anchor.Parent = effects
    local sparks = Instance.new("ParticleEmitter")
    sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    sparks.Color = ColorSequence.new(impactColor)
    sparks.LightEmission = 1
    sparks.Lifetime = NumberRange.new(0.12, 0.28)
    sparks.Speed = NumberRange.new(5, 11)
    sparks.Drag = 7
    sparks.SpreadAngle = Vector2.new(65, 65)
    sparks.EmissionDirection = Enum.NormalId.Front
    sparks.Size = NumberSequence.new(0.24, 0)
    sparks.Enabled = false
    sparks.Parent = anchor
    sparks:Emit(if hitEnemy then 8 else 5)
    Debris:AddItem(anchor, 0.40)

    local burst = Instance.new("Part")
    burst.Name = "ImpactBurst"
    burst.Shape = Enum.PartType.Ball
    burst.Anchored = true
    burst.CanCollide = false
    burst.CanTouch = false
    burst.CanQuery = false
    burst.CastShadow = false
    burst.Material = Enum.Material.Neon
    burst.Color = impactColor
    burst.Size = Vector3.new(0.25, 0.25, 0.25)
    burst.Position = position
    burst.Parent = effects
    TweenService:Create(burst, TweenInfo.new(0.15), {
        Size = Vector3.new(0.9, 0.9, 0.9),
        Transparency = 1,
    }):Play()
    Debris:AddItem(burst, 0.17)
end

shotVisual.OnClientEvent:Connect(function(eventType: string, id: number, a: any, b: any, c: any, d: any, e: any)
    if typeof(id) ~= "number" then return end
    if eventType == "spawn" then
        local origin, direction, speed, color, spawnTime = a, b, c, d, e
        if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3"
            or typeof(speed) ~= "number" or speed <= 0
            or typeof(color) ~= "Color3" or typeof(spawnTime) ~= "number" then
            return
        end
        finishBullet(id, nil)
        local bullet = Instance.new("Part")
        bullet.Name = "VisibleProjectile"
        bullet.Shape = Enum.PartType.Ball
        bullet.Anchored = true
        bullet.CanCollide = false
        bullet.CanTouch = false
        bullet.CanQuery = false
        bullet.CastShadow = false
        bullet.Material = Enum.Material.Neon
        bullet.Color = color
        bullet.Size = Vector3.new(0.36, 0.36, 0.36)
        bullet.CFrame = CFrame.lookAt(origin, origin + direction)
        bullet.Parent = effects

        local front = Instance.new("Attachment")
        front.Position = Vector3.new(0, 0, -0.22)
        front.Parent = bullet
        local back = Instance.new("Attachment")
        back.Position = Vector3.new(0, 0, 0.22)
        back.Parent = bullet
        local trail = Instance.new("Trail")
        trail.Name = "ProjectileTrail"
        trail.Attachment0 = front
        trail.Attachment1 = back
        trail.Color = ColorSequence.new(color)
        trail.FaceCamera = true
        trail.LightEmission = 1
        trail.Lifetime = 0.15
        trail.MinLength = 0.05
        trail.WidthScale = NumberSequence.new(0.45, 0.05)
        trail.Parent = bullet
        bullets[id] = {
            Part = bullet, Trail = trail, Origin = origin, Direction = direction,
            Speed = speed, SpawnTime = spawnTime,
        }
        makeFlash(origin, color)
    elseif eventType == "impact" then
        if typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then return end
        finishBullet(id, a)
        makeImpact(a, b, c == true)
    elseif eventType == "expire" then
        finishBullet(id, nil)
    end
end)

RunService.RenderStepped:Connect(function()
    local currentTime = workspace:GetServerTimeNow()
    for id, shot in pairs(bullets) do
        local elapsed = math.max(0, currentTime - shot.SpawnTime)
        if elapsed > Config.MaxWeaponRange / shot.Speed + 0.5 then
            finishBullet(id, nil) -- safety cleanup if a packet is missed
        else
            local travelled = math.min(elapsed * shot.Speed, Config.MaxWeaponRange)
            local position = shot.Origin + shot.Direction * travelled
            shot.Part.CFrame = CFrame.lookAt(position, position + shot.Direction)
        end
    end
end)
