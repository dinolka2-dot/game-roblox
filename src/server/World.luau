local World = {}
function World.part(parent, name, size, position, color, material)
    local p = Instance.new("Part")
    p.Name = name; p.Size = size; p.Position = position; p.Anchored = true
    p.Color = color; p.Material = material or Enum.Material.Slate; p.Parent = parent
    return p
end
function World.label(part, text, offset)
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.fromOffset(190, 58); gui.StudsOffset = offset or Vector3.new(0, 5, 0)
    gui.AlwaysOnTop = false; gui.MaxDistance = 90; gui.Parent = part
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1); label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(245, 227, 180); label.TextStrokeTransparency = 0.4
    label.Font = Enum.Font.GothamBold; label.TextSize = 16; label.TextWrapped = true
    label.Text = text; label.Parent = gui
    return label
end
function World.prompt(part, action, title, callback)
    local p = Instance.new("ProximityPrompt")
    p.ActionText = action; p.ObjectText = title; p.MaxActivationDistance = 12
    p.HoldDuration = 0.3; p.RequiresLineOfSight = true; p.Parent = part
    p.Triggered:Connect(function(player) callback(player, part.Position) end)
end
function World.build(callbacks)
    assert(not workspace:FindFirstChild("EldoriaWorld"), "World already exists")
    local root = Instance.new("Folder"); root.Name = "EldoriaWorld"; root.Parent = workspace
    World.part(root, "Земля", Vector3.new(360, 4, 240), Vector3.new(80, -2, 0), Color3.fromRGB(53, 73, 53), Enum.Material.Grass)
    World.part(root, "Тропа", Vector3.new(180, 0.15, 12), Vector3.new(80, 0.1, 0), Color3.fromRGB(116, 100, 76), Enum.Material.Ground)
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "Святилище"; spawn.Anchored = true; spawn.Size = Vector3.new(12, 1, 12)
    spawn.Position = Vector3.new(0, 0.7, 0); spawn.Neutral = true; spawn.Duration = 3
    spawn.Color = Color3.fromRGB(118, 163, 164); spawn.Material = Enum.Material.Marble; spawn.Parent = root
    World.label(spawn, "ЭЛЬДОРИЯ\nСвятилище · безопасная зона", Vector3.new(0, 8, 0))
    local elder = World.part(root, "Хранитель Иар", Vector3.new(3, 5, 3), Vector3.new(14, 2.5, -12), Color3.fromRGB(133, 105, 185))
    World.label(elder, "Иар · хранитель\nЗадание: трещина в завесе")
    World.prompt(elder, "Поговорить", "Хранитель Иар", callbacks.quest)
    local forge = World.part(root, "Кузница", Vector3.new(5, 3, 4), Vector3.new(-12, 1.5, -12), Color3.fromRGB(87, 94, 108), Enum.Material.Metal)
    World.label(forge, "Кузница\n3 осколка + золото")
    World.prompt(forge, "Улучшить клинок", "Кузница", callbacks.upgrade)
    local trader = World.part(root, "Торговец", Vector3.new(4, 4, 4), Vector3.new(-12, 2, 13), Color3.fromRGB(157, 116, 65), Enum.Material.Wood)
    World.label(trader, "Лавка\nОсколок → 8 золота")
    World.prompt(trader, "Продать осколок", "Торговец", callbacks.sell)
    local sign = World.part(root, "Указатель", Vector3.new(1, 5, 5), Vector3.new(46, 2.5, -10), Color3.fromRGB(108, 84, 59), Enum.Material.Wood)
    World.label(sign, "→ Сумрачная роща\nОпасность за границей святилища")
    local rng = Random.new(173)
    for i = 1, 45 do
        local x, z = rng:NextNumber(-65, 240), rng:NextNumber(-100, 100)
        if math.abs(z) > 18 then
            World.part(root, "Ствол", Vector3.new(3, 12, 3), Vector3.new(x, 6, z), Color3.fromRGB(80, 61, 46), Enum.Material.Wood)
            local crown = World.part(root, "Крона", Vector3.new(15, 16, 15), Vector3.new(x, 17, z), Color3.fromRGB(40, 70, 61), Enum.Material.Grass)
            crown.Shape = Enum.PartType.Ball; crown.CanCollide = false
        end
    end
    local gate = World.part(root, "Разлом", Vector3.new(5, 18, 13), Vector3.new(220, 9, 0), Color3.fromRGB(143, 89, 255), Enum.Material.Neon)
    gate.CanCollide = false
    World.label(gate, "РАЗЛОМ\nХранитель пробуждается", Vector3.new(0, 13, 0))
    local light = Instance.new("PointLight"); light.Color = gate.Color; light.Range = 30; light.Brightness = 2; light.Parent = gate
    return root
end
return World
