local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local Debris = game:GetService("Debris")
local Shared = game:GetService("ReplicatedStorage").Eldoria
local Config = require(Shared.Config)
local World = require(script.Parent.World)
local Characters = require(Shared.Characters)
local Enemies = {}; Enemies.__index = Enemies
function Enemies.new(root, callbacks)
    local self = setmetatable({root = root, list = {}, callbacks = callbacks}, Enemies)
    for _, pos in {Vector3.new(90, 3, -15), Vector3.new(110, 3, 20), Vector3.new(140, 3, -20), Vector3.new(165, 3, 18), Vector3.new(195, 3, -20), Vector3.new(210, 4.6, 0)} do
        local kind = if pos.X > 200 then "warden" elseif pos.X == 140 or pos.X == 195 then "shade" else "sentinel"
        local e = {kind = kind, home = pos, deadUntil = 0}
        table.insert(self.list, e); self:spawn(e)
    end
    return self
end
function Enemies:spawn(e)
    local c = Config.Enemies[e.kind]; e.hp = c.Health; e.hits = {}; e.attack = 0; e.slow = 0; e.nextPath = 0
    e.pending = nil; e.waypoints = nil; e.pathBusy = false; e.generation = (e.generation or 0) + 1
    e.model, e.body = Characters.create(self.root, c.Name, e.home, e.kind)
    e.label = World.label(e.body, c.Name)
end
function Enemies:hit(e, player, damage, slow)
    if self.callbacks.canEngage and not self.callbacks.canEngage(player, e) then return end
    if e.hp <= 0 then return end
    e.hp = math.max(0, e.hp - damage); e.hits[player] = os.clock()
    if slow then e.slow = os.clock() + 3 end
    if e.hp == 0 then
        if self.callbacks.death then self.callbacks.death(e.body.Position) end
        e.model:Destroy(); e.deadUntil = os.clock() + Config.Enemies[e.kind].Respawn
        for contributor, time in e.hits do
            local root = contributor.Character and contributor.Character:FindFirstChild("HumanoidRootPart")
            if contributor.Parent and root and (root.Position - e.home).Magnitude < 100 and os.clock() - time < 20 then
                self.callbacks.reward(contributor, Config.Enemies[e.kind], e.kind)
            end
        end
        e.hits = {}
    end
end
function Enemies:target(player, range, aim)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local best, distance = nil, range
    local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {player.Character}
    for _, e in self.list do
        if e.hp > 0 then
            local delta = e.body.Position - root.Position
            local d = delta.Magnitude
            if d <= distance and d > 0.01 and delta.Unit:Dot(aim) > 0.25 then
                local result = workspace:Raycast(root.Position, delta, params)
                if result == nil or result.Instance:IsDescendantOf(e.model) then best = e; distance = d end
            end
        end
    end
    return best
end
function Enemies:telegraph(e, radius, center)
    center = center or e.body.Position
    e.body:SetAttribute("AttackStart", workspace:GetServerTimeNow())
    local p = World.part(self.root, "Опасная область", Vector3.new(0.12, radius * 2, radius * 2), Vector3.new(center.X, 0.25, center.Z), Color3.fromRGB(255, 78, 80), Enum.Material.Neon)
    p.Shape = Enum.PartType.Cylinder; p.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
    p.Transparency = 0.5; p.CanCollide = false; p.CanQuery = false
    Debris:AddItem(p, 0.9)
end
function Enemies:step(dt)
    local now = os.clock()
    for _, e in self.list do
        if e.hp <= 0 then
            if now >= e.deadUntil then self:spawn(e) end
            continue
        end
        local config = Config.Enemies[e.kind]
        e.label.Text = config.Name .. "\n" .. math.ceil(e.hp) .. " / " .. config.Health
        local target, distance = nil, config.Aggro
        for _, player in Players:GetPlayers() do
            local root, hum = self.callbacks.character(player)
            if root and hum.Health > 0 and (not self.callbacks.canEngage or self.callbacks.canEngage(player, e)) and Vector3.new(root.Position.X, 0, root.Position.Z).Magnitude > Config.SafeRadius then
                local d = (root.Position - e.body.Position).Magnitude
                if d < distance and (root.Position - e.home).Magnitude < 70 then target = player; distance = d end
            end
        end
        local targetRoot = target and self.callbacks.character(target)
        local destination = if targetRoot then targetRoot.Position else e.home
        -- Boss AoE is telegraphed, then rechecks current positions when it lands.
        if e.pending and now >= e.pending.time then
            local pending = e.pending; e.pending = nil
            for _, player in Players:GetPlayers() do
                local root = self.callbacks.character(player)
                if root and (not self.callbacks.canEngage or self.callbacks.canEngage(player, e)) and (root.Position - pending.center).Magnitude <= pending.radius then self.callbacks.damage(player, pending.damage) end
            end
        end
        if targetRoot and distance < (if e.kind == "warden" then 15 elseif e.kind == "shade" then 32 else 6) and now > e.attack and not e.pending then
            local phaseTwo = e.hp < config.Health * 0.5
            e.attack = now + (if phaseTwo then 1.7 else 2.5)
            local radius = if e.kind == "warden" then (if phaseTwo then 14 else 10) else 6
            local center = if e.kind == "shade" then targetRoot.Position else e.body.Position
            self:telegraph(e, radius, center)
            e.pending = {time = now + 0.8, center = center, radius = radius, damage = config.Damage}
        end
        if not e.pending and not (e.kind == "shade" and targetRoot and distance < 24) then
            local delta = Vector3.new(destination.X, e.body.Position.Y, destination.Z) - e.body.Position
            if delta.Magnitude > 4 then
                if now > e.nextPath and not e.pathBusy then
                    e.nextPath = now + 2; e.pathBusy = true
                    local generation = e.generation
                    task.spawn(function()
                        local path = PathfindingService:CreatePath({AgentRadius = 3, AgentHeight = 6, AgentCanJump = false})
                        local ok = pcall(function() path:ComputeAsync(e.body.Position, destination) end)
                        if e.hp > 0 and e.generation == generation then
                            e.waypoints = if ok and path.Status == Enum.PathStatus.Success then path:GetWaypoints() else nil
                            e.waypoint = 2; e.pathBusy = false
                        end
                        path:Destroy()
                    end)
                end
                local point = e.waypoints and e.waypoints[e.waypoint]
                if point then
                    delta = Vector3.new(point.Position.X, e.body.Position.Y, point.Position.Z) - e.body.Position
                    if delta.Magnitude < 3 then e.waypoint += 1 end
                end
                if delta.Magnitude > 0.01 then
                    local step = delta.Unit * math.min(delta.Magnitude, config.Speed * dt * (if now < e.slow then 0.45 else 1))
                    local params = RaycastParams.new(); params.FilterDescendantsInstances = {e.model}; params.FilterType = Enum.RaycastFilterType.Exclude
                    if not workspace:Raycast(e.body.Position, step * 2, params) then
                        local pos = e.body.Position + step
                        e.body.CFrame = CFrame.lookAt(pos, pos + delta.Unit)
                    end
                end
            end
        end
    end
end
return Enemies
