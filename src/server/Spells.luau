-- Authoritative timed spell simulation. Visuals never select damage or targets.
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage").Eldoria
local Book = require(Shared.Spellbook)
local Config = require(Shared.Config)
local Spells = {}; Spells.__index = Spells
function Spells.new(enemies, callbacks)
    return setmetatable({enemies = enemies, callbacks = callbacks, active = {}, serial = 0}, Spells)
end
function Spells:cancel(player)
    local token = self.active[player]; self.active[player] = nil
    if token then self.callbacks.visual("spellCancel", {user = player.UserId, serial = token.serial}) end
end
function Spells:cast(player, id, direction, level)
    local definition = Book.Definitions[id]
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not definition or not root then return end
    self:cancel(player); self.serial += 1
    local token = {serial = self.serial}; self.active[player] = token
    local origin = root.Position
    local color = Config.Spells[definition.Rune].Color
    local expires = os.clock() + 8
    local function valid()
        return self.active[player] == token and os.clock() < expires and self.callbacks.valid(player, character) and (root.Position-origin).Magnitude < 14
    end
    local function emit(kind, data)
        data.id = id; data.color = color; data.user = player.UserId; data.serial = token.serial
        self.callbacks.visual(kind, data)
    end
    local function params()
        local p = RaycastParams.new(); p.FilterType = Enum.RaycastFilterType.Exclude
        local ignored = {}
        for _, other in Players:GetPlayers() do if other.Character then table.insert(ignored, other.Character) end end
        p.FilterDescendantsInstances = ignored; return p
    end
    local function allowed(e)
        return e.hp > 0 and self.enemies.callbacks.canEngage(player, e)
    end
    local function visible(position, e)
        local delta = e.body.Position - position
        if delta.Magnitude < 0.01 then return true end
        local hit = workspace:Raycast(position, delta, params())
        return not hit or hit.Instance:IsDescendantOf(e.model)
    end
    local function hit(e, multiplier)
        if not valid() or not allowed(e) then return end
        local damage = (definition.Damage + level) * (multiplier or 1)
        self.enemies:hit(e, player, damage, definition.Rune == "frost")
        emit("spellHit", {position = e.body.Position, damage = damage})
    end
    local function area(position, radius, seen)
        for _, e in self.enemies.list do
            if allowed(e) and not (seen and seen[e]) and (e.body.Position-position).Magnitude <= radius and visible(position,e) then
                if seen then seen[e] = true end
                hit(e)
            end
        end
    end
    -- Ground targeting is clipped by the world; never accepts a client-supplied position.
    local target = self.enemies:target(player, definition.Range, direction)
    local destination = origin + direction * definition.Range
    if target and allowed(target) then destination = target.body.Position end
    local obstruction = workspace:Raycast(origin,destination-origin,params())
    if obstruction then destination = obstruction.Position end
    emit("spellCharge", {origin = origin, duration = definition.Windup, direction = direction})
    task.spawn(function()
        task.wait(definition.Windup)
        if not valid() then return end
        local kind = definition.Kind
        emit("spellRelease", {origin = origin, position = destination, direction = direction, duration = definition.Duration})
        if kind == "projectile" then
            local position = origin; local travelled = 0; local last = os.clock()
            while valid() and travelled < definition.Range do
                task.wait(0.03)
                local now = os.clock(); local step = math.min(definition.Range-travelled,definition.Speed*math.min(now-last,0.1)); last = now
                local collision = workspace:Spherecast(position,0.65,direction*step,params())
                position = if collision then collision.Position else position+direction*step
                travelled += step
                if collision then
                    emit("spellImpact",{position = position, radius = definition.Radius})
                    area(position,definition.Radius+2)
                    break
                end
            end
            emit("spellEnd",{position = position})
        elseif kind == "ring" then
            local seen = {}; local steps = 10
            for i = 1, steps do
                task.wait(definition.Duration/steps); if not valid() then break end
                area(origin,definition.Radius*i/steps,seen)
            end
        elseif kind == "meteor" then
            emit("spellZone",{position = destination, radius = definition.Radius, duration = definition.Duration})
            task.wait(definition.Duration)
            if valid() then emit("spellImpact",{position = destination,radius = definition.Radius}); area(destination,definition.Radius) end
        elseif kind == "line" then
            local flat = Vector3.new(direction.X,0,direction.Z)
            if flat.Magnitude < 0.01 then flat = Vector3.new(0,0,-1) end
            local seen = {}; local previous = origin
            for i = 1, 6 do
                task.wait(definition.Duration/6); if not valid() then break end
                local position = origin + flat.Unit * (i*5)
                if workspace:Raycast(previous,position-previous,params()) then break end
                emit("spellSpike",{position = position}); area(position,definition.Radius,seen); previous = position
            end
        elseif kind == "chain" then
            local previous = origin; local seen = {}
            for index = 1, 4 do
                if not valid() then break end
                local best, distance = nil, if index == 1 then definition.Range else definition.Radius
                for _, e in self.enemies.list do
                    local d = if allowed(e) then (e.body.Position-previous).Magnitude else math.huge
                    if d < distance and not seen[e] and visible(previous,e) and (index > 1 or (e.body.Position-origin).Unit:Dot(direction)>0.5) then best = e; distance = d end
                end
                if not best then break end
                local position = best.body.Position; seen[best] = true
                emit("spellArc",{origin = previous,position = position}); hit(best,1-(index-1)*0.15); previous = position
                task.wait(0.1)
            end
        elseif kind == "vortex" then
            emit("spellZone",{position = destination,radius = definition.Radius,duration = definition.Duration})
            for _ = 1, 6 do task.wait(definition.Duration/6); if not valid() then break end; area(destination,definition.Radius) end
        elseif kind == "beam" then
            for _ = 1, 4 do
                if not valid() then break end
                local collision = workspace:Raycast(origin,direction*definition.Range,params())
                local ending = if collision then collision.Position else origin+direction*definition.Range
                emit("spellArc",{origin = origin,position = ending})
                if collision then area(ending,definition.Radius+2) end
                task.wait(definition.Duration/4)
            end
        end
        if self.active[player] == token then self.active[player] = nil end
    end)
end
return Spells
