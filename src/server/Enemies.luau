local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local Debris = game:GetService("Debris")
local Shared = game:GetService("ReplicatedStorage").Eldoria
local Config = require(Shared.Config)
local Encounter = require(Shared.Encounter)
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
    e.sequence = 0; e.stunned = 0; e.pending = nil; e.waypoints = nil; e.pathBusy = false; e.generation = (e.generation or 0) + 1
    e.model, e.body = Characters.create(self.root, c.Name, e.home, e.kind)
    e.label = World.label(e.body, c.Name)
    e.body:SetAttribute("Health",e.hp); e.body:SetAttribute("MaxHealth",c.Health)
    e.body:SetAttribute("EnemyKind",e.kind)
end
function Enemies:hit(e, player, damage, slow)
    if self.callbacks.canEngage and not self.callbacks.canEngage(player, e) then return end
    if e.hp <= 0 then return end
    e.hp = math.max(0, e.hp - damage); e.body:SetAttribute("Health",e.hp); e.hits[player] = os.clock()
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
function Enemies:target(player, range, aim, minimumDot)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local best, distance = nil, range
    local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {player.Character}
    for _, e in self.list do
        if e.hp > 0 then
            local delta = e.body.Position - root.Position
            local d = delta.Magnitude
            if d <= distance and d > 0.01 and delta.Unit:Dot(aim) > (minimumDot or 0.25) then
                local result = workspace:Raycast(root.Position, delta, params)
                if result == nil or result.Instance:IsDescendantOf(e.model) then best = e; distance = d end
            end
        end
    end
    return best
end
function Enemies:telegraph(e, radius, center, shape, facing)
    center = center or e.body.Position
    e.body:SetAttribute("AttackStart", workspace:GetServerTimeNow())
    local p = World.part(self.root, "Опасная область", Vector3.new(0.12, radius * 2, radius * 2), Vector3.new(center.X, 0.25, center.Z), Color3.fromRGB(255, 78, 80), Enum.Material.Neon)
    p.Shape = Enum.PartType.Cylinder; p.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
    if shape == "cleave" then
        p.Shape = Enum.PartType.Block; p.Size = Vector3.new(9,0.12,radius)
        p.CFrame = CFrame.lookAt(Vector3.new(center.X,0.25,center.Z),Vector3.new(center.X+facing.X,0.25,center.Z+facing.Z))*CFrame.new(0,0,-radius/2)
    end
    p.Transparency = 0.5; p.CanCollide = false; p.CanQuery = false
    Debris:AddItem(p, 0.9)
    if shape == "shockwave" then
        local safe=World.part(self.root,"Внутренняя безопасная зона",Vector3.new(0.14,10,10),Vector3.new(center.X,0.3,center.Z),Color3.fromRGB(95,215,162),Enum.Material.Neon)
        safe.Shape=Enum.PartType.Cylinder; safe.CFrame*=CFrame.Angles(0,0,math.pi/2)
        safe.Transparency=0.4; safe.CanCollide=false; safe.CanQuery=false; safe.CanTouch=false
        Debris:AddItem(safe,0.9)
    end
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
        if e.pending and now >= e.pending.time then
            local pending = e.pending; e.pending = nil
            for _, player in Players:GetPlayers() do
                local root = self.callbacks.character(player)
                if root and (not self.callbacks.canEngage or self.callbacks.canEngage(player,e)) then
                    for _, zone in pending.zones do
                        local delta = root.Position-zone.center
                        if Encounter.contains(zone.shape,delta.X,delta.Z,zone.radius,zone.facing.X,zone.facing.Z) then
                            local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
                            params.FilterDescendantsInstances = {e.model}
                            local result = workspace:Raycast(e.body.Position,root.Position-e.body.Position,params)
                            if not result or result.Instance:IsDescendantOf(player.Character) then
                                local parried = self.callbacks.damage(player,pending.damage,e.body.Position)
                                if parried then e.stunned = now+1.3 end
                            end
                            break
                        end
                    end
                end
            end
        end
        if targetRoot and now >= e.stunned and distance < (if e.kind == "warden" then 28 elseif e.kind == "shade" then 32 else 6) and now > e.attack and not e.pending then
            local phase = Encounter.phase(e.hp,config.Health)
            e.sequence += 1
            local pattern = if e.kind == "warden" then Encounter.pattern(e.sequence,phase) else "circle"
            local facing = Vector3.new(targetRoot.Position.X-e.body.Position.X,0,targetRoot.Position.Z-e.body.Position.Z)
            if facing.Magnitude < 0.01 then facing = Vector3.new(0,0,-1) end
            facing = facing.Unit; e.body.CFrame = CFrame.lookAt(e.body.Position,e.body.Position+facing)
            local zones = {}
            if pattern == "barrage" then
                for _, offset in {-8,0,8} do
                    table.insert(zones,{center=targetRoot.Position+Vector3.new(offset,0,0),radius=6,shape="circle",facing=facing})
                end
            else
                table.insert(zones,{center=if e.kind=="shade" then targetRoot.Position else e.body.Position,
                    radius=if e.kind=="warden" then (if pattern=="cleave" then 20 else 16) else 6,shape=pattern,facing=facing})
            end
            e.attack = now+(if phase==2 then 2.3 else 3)
            for _, zone in zones do self:telegraph(e,zone.radius,zone.center,zone.shape,zone.facing) end
            e.body:SetAttribute("AttackPattern",pattern)
            e.pending = {time=now+0.8,zones=zones,damage=config.Damage}
        end
        if now >= e.stunned and not e.pending and not (e.kind == "shade" and targetRoot and distance < 24) then
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
