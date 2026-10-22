--!strict
-- Prototype combat server: one authoritative source for health, shots and NPC decisions.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local PathfindingService = game:GetService("PathfindingService")
local PhysicsService = game:GetService("PhysicsService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Arena = require(script.Parent:WaitForChild("Arena"))

local _, captureLabel = Arena.Build()
local botFolder = Instance.new("Folder")
botFolder.Name = "PrototypeBots"
botFolder.Parent = workspace:WaitForChild("TheLastOrderPrototype")

local remotes = Instance.new("Folder")
remotes.Name = "TLO_Remotes"
remotes.Parent = ReplicatedStorage
local requestFire = Instance.new("RemoteEvent")
requestFire.Name = "RequestFire"
requestFire.Parent = remotes
local shotVisual = Instance.new("RemoteEvent")
shotVisual.Name = "ShotVisual"
shotVisual.Parent = remotes

local collisionGroup = "TLO_Bots"
pcall(function() PhysicsService:RegisterCollisionGroup(collisionGroup) end)
PhysicsService:CollisionGroupSetCollidable(collisionGroup, collisionGroup, false)

type Bot = {
    Model: Model,
    Humanoid: Humanoid,
    Root: BasePart,
    Team: string,
    Slot: number,
    LastShot: number,
    LastMove: number,
    PathBusy: boolean,
}
local bots: {Bot} = {}
local playerShotTime: {[Player]: number} = {}

local function alive(model: Model): boolean
    local h = model:FindFirstChildOfClass("Humanoid")
    return h ~= nil and h.Health > 0 and model:FindFirstChild("HumanoidRootPart") ~= nil
end

local function characterTeam(character: Model): string?
    local team = character:GetAttribute("TLOTeam")
    if typeof(team) == "string" then
        return team
    end
    return nil
end

local function fireRay(owner: Model, startPosition: Vector3, direction: Vector3, damage: number): boolean
    local ownTeam = characterTeam(owner)
    if ownTeam == nil or not alive(owner) or direction.Magnitude < 0.01 then
        return false
    end
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {owner}
    rayParams.IgnoreWater = true
    local result = workspace:Raycast(startPosition, direction.Unit * Config.MaxWeaponRange, rayParams)
    local endpoint = startPosition + direction.Unit * Config.MaxWeaponRange
    if result then
        endpoint = result.Position
        local model = result.Instance:FindFirstAncestorOfClass("Model")
        if model and characterTeam(model) and characterTeam(model) ~= ownTeam then
            local victim = model:FindFirstChildOfClass("Humanoid")
            if victim and victim.Health > 0 then
                victim:TakeDamage(damage)
            end
        end
    end
    shotVisual:FireAllClients(startPosition, endpoint, Config.TeamColors[ownTeam])
    return true
end

local function isFiniteVector(v: Vector3): boolean
    return v.X == v.X and v.Y == v.Y and v.Z == v.Z
        and math.abs(v.X) < 100000 and math.abs(v.Y) < 100000 and math.abs(v.Z) < 100000
end

requestFire.OnServerEvent:Connect(function(player: Player, aimPoint: any)
    if typeof(aimPoint) ~= "Vector3" or not isFiniteVector(aimPoint) then
        return
    end
    local now = os.clock()
    if now - (playerShotTime[player] or 0) < Config.PlayerFireInterval then
        return
    end
    local character = player.Character
    if not character or not alive(character) then return end
    local head = character:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then return end
    local startPosition = head.Position
    local direction = aimPoint - startPosition
    if direction.Magnitude < 1 then return end
    playerShotTime[player] = now
    fireRay(character, startPosition, direction, Config.PlayerDamage)
end)

local function nearestEnemy(bot: Bot): (Model?, number)
    local closest: Model? = nil
    local best = math.huge
    for _, other in ipairs(bots) do
        if other.Team ~= bot.Team and other.Humanoid.Health > 0 then
            local distance = (other.Root.Position - bot.Root.Position).Magnitude
            if distance < best then
                closest, best = other.Model, distance
            end
        end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character and characterTeam(character) ~= bot.Team and alive(character) then
            local root = character:FindFirstChild("HumanoidRootPart")
            if root and root:IsA("BasePart") then
                local distance = (root.Position - bot.Root.Position).Magnitude
                if distance < best then
                    closest, best = character, distance
                end
            end
        end
    end
    return closest, best
end

local function hasSight(bot: Bot, target: Model): boolean
    local targetRoot = target:FindFirstChild("HumanoidRootPart")
    if not targetRoot or not targetRoot:IsA("BasePart") then return false end
    local origin = bot.Root.Position + Vector3.new(0, 1.5, 0)
    local direction = targetRoot.Position + Vector3.new(0, 1.5, 0) - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {bot.Model}
    local hit = workspace:Raycast(origin, direction, params)
    return hit ~= nil and hit.Instance:IsDescendantOf(target)
end

local function moveTo(bot: Bot, destination: Vector3)
    if bot.PathBusy or os.clock() - bot.LastMove < 1.8 then return end
    bot.LastMove = os.clock()
    bot.PathBusy = true
    task.spawn(function()
        local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = false})
        local success = pcall(function() path:ComputeAsync(bot.Root.Position, destination) end)
        local waypoint = destination
        if success and path.Status == Enum.PathStatus.Success then
            local points = path:GetWaypoints()
            if #points > 1 then waypoint = points[2].Position end
        end
        if bot.Humanoid.Health > 0 then
            bot.Humanoid:MoveTo(waypoint)
        end
        bot.PathBusy = false
    end)
end

local function spawnBot(team: string, slot: number)
    local description = Instance.new("HumanoidDescription")
    description.HeadColor = Config.TeamColors[team]
    description.LeftArmColor = Config.TeamColors[team]
    description.RightArmColor = Config.TeamColors[team]
    description.LeftLegColor = Config.TeamColors[team]
    description.RightLegColor = Config.TeamColors[team]
    description.TorsoColor = Config.TeamColors[team]
    local ok, generated = pcall(function()
        return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
    end)
    description:Destroy()
    if not ok or not generated then
        warn("[TLO] R15 bot creation failed: " .. tostring(generated))
        return
    end
    local model = generated :: Model
    local root = model:FindFirstChild("HumanoidRootPart")
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not root or not root:IsA("BasePart") or not humanoid then
        model:Destroy()
        warn("[TLO] Generated character lacks Humanoid/RootPart")
        return
    end
    model.Name = team .. "_NPC_" .. tostring(slot)
    model:SetAttribute("TLOTeam", team)
    model.Parent = botFolder
    local position = Config.BasePositions[team]
    model:PivotTo(CFrame.new(position + Vector3.new((slot % 3 - 1) * 5, 3, math.floor(slot / 3) * 5)))
    humanoid.MaxHealth = Config.BotHealth
    humanoid.Health = Config.BotHealth
    humanoid.WalkSpeed = Config.BotWalkSpeed
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then item.CollisionGroup = collisionGroup end
    end
    local bot: Bot = {
        Model = model,
        Humanoid = humanoid,
        Root = root,
        Team = team,
        Slot = slot,
        LastShot = 0,
        LastMove = -10,
        PathBusy = false,
    }
    table.insert(bots, bot)
    humanoid.Died:Connect(function()
        Debris:AddItem(model, 6)
    end)
end

local playerIndex = 0
local function registerPlayer(player: Player)
    playerIndex += 1
    local team = (playerIndex % 2 == 1) and Config.HUMANS or Config.MACHINES
    player:SetAttribute("TLOTeam", team)
    local function onCharacter(character: Model)
        character:SetAttribute("TLOTeam", team)
        local root = character:WaitForChild("HumanoidRootPart", 10)
        if root and root:IsA("BasePart") then
            task.wait(0.1)
            if character.Parent then
                character:PivotTo(CFrame.new(Config.BasePositions[team] + Vector3.new(0, 5, 0)))
            end
        end
    end
    player.CharacterAdded:Connect(onCharacter)
    if player.Character then task.spawn(onCharacter, player.Character) end
end
Players.PlayerAdded:Connect(registerPlayer)
for _, existingPlayer in ipairs(Players:GetPlayers()) do
    task.spawn(registerPlayer, existingPlayer)
end
Players.PlayerRemoving:Connect(function(player) playerShotTime[player] = nil end)

-- PlayerAdded must be connected before yielding while generating NPC rigs.
for _, team in ipairs({Config.HUMANS, Config.MACHINES}) do
    for slot = 1, Config.BotsPerTeam do
        spawnBot(team, slot)
    end
end

local capture = 0 -- -100 Machines; +100 Humans
local lastCapture = os.clock()
task.spawn(function()
    while task.wait(0.25) do
        local now = os.clock()
        local dt = math.min(now - lastCapture, 0.5)
        lastCapture = now
        local blue = 0
        local red = 0
        for _, bot in ipairs(bots) do
            if bot.Humanoid.Health > 0 and (bot.Root.Position - Config.Center).Magnitude <= Config.CaptureRadius then
                if bot.Team == Config.HUMANS then blue += Config.BotCaptureWeight else red += Config.BotCaptureWeight end
            end
        end
        for _, player in ipairs(Players:GetPlayers()) do
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if character and alive(character) and root and root:IsA("BasePart") then
                if (root.Position - Config.Center).Magnitude <= Config.CaptureRadius then
                    if characterTeam(character) == Config.HUMANS then blue += Config.PlayerCaptureWeight else red += Config.PlayerCaptureWeight end
                end
            end
        end
        if blue > 0 and red == 0 then
            capture = math.clamp(capture + math.min(blue, Config.CaptureMaxWeight) * Config.CapturePointsPerSecond * dt, -100, 100)
        elseif red > 0 and blue == 0 then
            capture = math.clamp(capture - math.min(red, Config.CaptureMaxWeight) * Config.CapturePointsPerSecond * dt, -100, 100)
        end
        if blue > 0 and red > 0 then
            captureLabel.Text = "B - CONTESTED"
        elseif capture >= 100 then
            captureLabel.Text = "B - HUMANS CONTROL"
        elseif capture <= -100 then
            captureLabel.Text = "B - MACHINES CONTROL"
        elseif capture > 0 then
            captureLabel.Text = string.format("B - HUMANS %.0f%%", capture)
        elseif capture < 0 then
            captureLabel.Text = string.format("B - MACHINES %.0f%%", -capture)
        else
            captureLabel.Text = "B - NEUTRAL"
        end
    end
end)

task.spawn(function()
    while task.wait(0.28) do
        local now = os.clock()
        for _, bot in ipairs(bots) do
            if bot.Humanoid.Health > 0 then
                local enemy, distance = nearestEnemy(bot)
                if enemy and distance < Config.BotEngageRange and hasSight(bot, enemy) then
                    bot.Humanoid:MoveTo(bot.Root.Position)
                    if now - bot.LastShot >= Config.BotFireInterval then
                        local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
                        if enemyRoot and enemyRoot:IsA("BasePart") then
                            bot.LastShot = now
                            local origin = bot.Root.Position + Vector3.new(0, 1.5, 0)
                            local aim = enemyRoot.Position + Vector3.new(0, 1.5, 0)
                            fireRay(bot.Model, origin, aim - origin, Config.BotDamage)
                        end
                    end
                else
                    local spread = Vector3.new((bot.Slot % 3 - 1) * 5, 0, math.floor(bot.Slot / 3) * 6 - 6)
                    local goal = Config.Center + spread
                    if enemy and distance < Config.BotEngageRange * 1.5 then
                        local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
                        if enemyRoot and enemyRoot:IsA("BasePart") then goal = enemyRoot.Position end
                    end
                    moveTo(bot, goal)
                end
            end
        end
    end
end)
print("[TLO] Prototype 0.1 server initialized. Temporary R15 units and debug capture point B active.")
