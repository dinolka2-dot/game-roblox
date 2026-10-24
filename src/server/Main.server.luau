local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Shared = ReplicatedStorage:WaitForChild("Eldoria")
local Config = require(Shared.Config)
local Rules = require(Shared.Rules)
local Profiles = require(script.Parent.Profiles)
local World = require(script.Parent.World)
local Enemies = require(script.Parent.Enemies)
local remotes = Instance.new("Folder"); remotes.Name = "Remotes"; remotes.Parent = Shared
local action = Instance.new("RemoteEvent"); action.Name = "Action"; action.Parent = remotes
local state = Instance.new("RemoteEvent"); state.Name = "State"; state.Parent = remotes
local notice = Instance.new("RemoteEvent"); notice.Name = "Notice"; notice.Parent = remotes
local sessions = {}
local closing = false
local function character(player)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if root and hum then return root, hum end
    return nil, nil
end
local function message(player, text) if player.Parent then notice:FireClient(player, text) end end
local function publish(player)
    local s = sessions[player]
    if not s or not Profiles.isActive(player) then return end
    local _, hum = character(player)
    state:FireClient(player, {profile = table.clone(s.profile), mana = s.mana, stamina = s.stamina,
        health = if hum then hum.Health else 0, maxHealth = if hum then hum.MaxHealth else 100,
        temporary = Profiles.isTemporary()})
end
local function permitted(player, position)
    local s = sessions[player]; local root, hum = character(player)
    if closing or not s or not Profiles.isActive(player) or not root or hum.Health <= 0 then return false end
    if position and (root.Position - position).Magnitude > 14 then return false end
    return true
end
local function interact(player, position, kind)
    if not permitted(player, position) then return end
    local s = sessions[player]; local now = os.clock()
    if now - s.interact < 0.6 then return end
    s.interact = now
    message(player, if kind == "quest" then Rules.quest(s.profile) else Rules.trade(s.profile, kind))
    publish(player)
end
local world = World.build({
    quest = function(p, pos) interact(p, pos, "quest") end,
    sell = function(p, pos) interact(p, pos, "sell") end,
    upgrade = function(p, pos) interact(p, pos, "upgrade") end,
})
local enemies = Enemies.new(world, {
    character = function(player)
        if not permitted(player) then return nil, nil end
        return character(player)
    end,
    damage = function(player, amount)
        if not permitted(player) then return end
        local s = sessions[player]; local root, hum = character(player)
        if Vector3.new(root.Position.X, 0, root.Position.Z).Magnitude <= Config.SafeRadius or os.clock() < s.invulnerable then return end
        if s.blocking and s.stamina >= 10 then s.stamina -= 10; amount *= 0.3 end
        hum:TakeDamage(amount); publish(player)
    end,
    reward = function(player, reward)
        if not permitted(player) then return end
        local s = sessions[player]; local before = Rules.level(s.profile.xp)
        Rules.reward(s.profile, reward.XP, reward.Gold, reward.Shards)
        local _, hum = character(player)
        hum.MaxHealth = 100 + (Rules.level(s.profile.xp) - 1) * 5
        if Rules.level(s.profile.xp) > before then hum.Health = hum.MaxHealth; message(player, "Новый уровень!") end
        message(player, "+" .. reward.XP .. " опыта · +" .. reward.Gold .. " золота · осколки +" .. reward.Shards)
        publish(player)
    end,
})
local function effect(origin, destination, color)
    local delta = destination - origin
    local p = World.part(world, "Магический след", Vector3.new(0.3, 0.3, math.max(0.1, delta.Magnitude)), (origin + destination) / 2, color, Enum.Material.Neon)
    p.CFrame = CFrame.lookAt((origin + destination) / 2, destination)
    p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
    Debris:AddItem(p, 0.18)
end
local function finiteVector(v)
    return typeof(v) == "Vector3" and v.X == v.X and v.Y == v.Y and v.Z == v.Z
        and math.abs(v.X) < 100000 and math.abs(v.Y) < 100000 and math.abs(v.Z) < 100000
end
-- One bounded input channel. Clients send intent, never damage, rewards or a profile.
action.OnServerEvent:Connect(function(player, kind, payload)
    if not permitted(player) or type(kind) ~= "string" then return end
    local s = sessions[player]; local now = os.clock()
    s.tokens = math.min(12, s.tokens + (now - s.tokenTime) * 8); s.tokenTime = now
    if s.tokens < 1 then return end
    s.tokens -= 1
    local root, hum = character(player)
    if kind == "sync" then publish(player); return end
    if kind == "rune" then
        if type(payload) == "string" and Config.Spells[payload] then s.profile.rune = payload; publish(player) end
        return
    end
    if kind == "block" then
        if type(payload) == "boolean" then s.blocking = payload; hum.WalkSpeed = if payload then 9 else 16 end
        return
    end
    if s.blocking then return end
    if kind == "dodge" then
        if now < s.dodge or s.stamina < Config.Dodge.Cost then return end
        s.dodge = now + Config.Dodge.Cooldown; s.stamina -= Config.Dodge.Cost
        s.invulnerable = now + Config.Dodge.Duration
        local delta = root.CFrame.LookVector * 10
        local params = RaycastParams.new(); params.FilterDescendantsInstances = {player.Character}
        local hit = workspace:Raycast(root.Position, delta, params)
        if hit then delta = delta.Unit * math.max(0, hit.Distance - 3) end
        player.Character:PivotTo(player.Character:GetPivot() + delta)
        publish(player); return
    end
    if kind ~= "attack" and kind ~= "cast" then return end
    if Vector3.new(root.Position.X, 0, root.Position.Z).Magnitude <= Config.SafeRadius then return end
    local aim = root.CFrame.LookVector
    if payload ~= nil then
        if not finiteVector(payload) then return end
        local direction = payload - root.Position
        if direction.Magnitude < 0.01 then return end
        aim = direction.Unit
    end
    local spell = Config.Spells[s.profile.rune]
    local range, damage, color
    if kind == "attack" then
        if now < s.attack or s.stamina < Config.Attack.Stamina then return end
        s.attack = now + Config.Attack.Cooldown; s.stamina -= Config.Attack.Stamina
        s.combo = if now - s.lastAttack <= 1.2 then s.combo % 3 + 1 else 1
        s.lastAttack = now
        range = Config.Attack.Range
        damage = Config.Attack.Damage + s.profile.blade * 6 + Rules.level(s.profile.xp) * 2
        if s.combo == 3 then damage *= 1.4 end
        color = Color3.fromRGB(240, 218, 155)
    else
        if now < s.cast or s.mana < spell.Cost then return end
        s.cast = now + spell.Cooldown; s.mana -= spell.Cost
        range = spell.Range; damage = spell.Damage + Rules.level(s.profile.xp) * 2; color = spell.Color
    end
    local target = enemies:target(player, range, aim)
    if target then
        local destination = target.body.Position
        enemies:hit(target, player, damage, kind == "cast" and s.profile.rune == "frost")
        effect(root.Position, destination, color)
        if kind == "cast" and s.profile.rune == "storm" then
            for _, other in enemies.list do
                if other ~= target and other.hp > 0 and (other.body.Position - destination).Magnitude <= 12 then
                    enemies:hit(other, player, damage * 0.5, false)
                end
            end
        end
    else
        effect(root.Position, root.Position + aim * math.min(range, 18), color)
    end
    publish(player)
end)
local function setupCharacter(player, char)
    local hum = char:WaitForChild("Humanoid", 10)
    local root = char:WaitForChild("HumanoidRootPart", 10)
    local s = sessions[player]
    if not hum or not root or not s then return end
    s.mana = 100; s.stamina = 100; s.blocking = false; s.invulnerable = os.clock() + 3
    hum.MaxHealth = 100 + (Rules.level(s.profile.xp) - 1) * 5; hum.Health = hum.MaxHealth
    hum.WalkSpeed = 16
    publish(player)
end
local function join(player)
    local profile = Profiles.load(player)
    if not profile then player:Kick("Не удалось безопасно загрузить данные. Повторите вход позже."); return end
    if closing or not player.Parent then Profiles.save(player, true); return end
    sessions[player] = {profile = profile, mana = 100, stamina = 100, tokens = 12, tokenTime = os.clock(),
        attack = 0, cast = 0, dodge = 0, invulnerable = 0, interact = 0, combo = 0, lastAttack = 0, blocking = false}
    player.CharacterAdded:Connect(function(char) setupCharacter(player, char) end)
    if player.Character then task.spawn(setupCharacter, player, player.Character) end
    message(player, "Добро пожаловать в Эльдорию. Поговорите с Иаром у святилища.")
end
Players.PlayerAdded:Connect(join)
for _, player in Players:GetPlayers() do task.spawn(join, player) end
Players.PlayerRemoving:Connect(function(player)
    Profiles.save(player, true); sessions[player] = nil
end)
local elapsed, broadcast = 0, 0
RunService.Heartbeat:Connect(function(dt)
    elapsed += dt; broadcast += dt
    if elapsed < 0.2 or closing then return end
    local step = math.min(elapsed, 0.5); elapsed = 0
    for player, s in sessions do
        s.mana = math.min(100, s.mana + step * 7)
        s.stamina = math.min(100, s.stamina + step * (if s.blocking then 0 else 16))
        local root, hum = character(player)
        if root and hum.Health > 0 and root.Position.Y < -25 then hum.Health = 0 end
        if broadcast >= 1 then publish(player) end
    end
    enemies:step(step)
    if broadcast >= 1 then broadcast = 0 end
end)
task.spawn(function()
    while not closing do
        task.wait(Config.Persistence.Autosave)
        if closing then break end
        for player in sessions do task.spawn(Profiles.save, player, false) end
    end
end)
game:BindToClose(function()
    closing = true
    local pending = 0
    for player in sessions do
        pending += 1
        task.spawn(function() Profiles.save(player, true); pending -= 1 end)
    end
    local deadline = os.clock() + 25
    while pending > 0 and os.clock() < deadline do task.wait(0.1) end
end)
