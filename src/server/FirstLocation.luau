local Chapter = require(game:GetService("ReplicatedStorage").Eldoria.Chapter)
local Location = {}
function Location.build(root, World, callbacks)
    local folder = Instance.new("Folder"); folder.Name = "Долина первой зари"; folder.Parent = root
    local stone = Color3.fromRGB(96, 106, 115)
    local colors = {Color3.fromRGB(246, 139, 64), Color3.fromRGB(103, 220, 246), Color3.fromRGB(192, 140, 255)}
    local function block(name, size, cf, color, material, solid)
        local p = World.part(folder, name, size, cf.Position, color, material)
        p.CFrame = cf
        if solid == false then p.CanCollide = false; p.CanQuery = false; p.CanTouch = false end
        return p
    end
    for index, seal in Chapter.Seals do
        local origin = CFrame.new(seal.X, 0, seal.Z)
        local color = colors[index]
        local platform = block(seal.Name, Vector3.new(17, 0.6, 17), origin * CFrame.new(0, 0.3, 0), stone, Enum.Material.Cobblestone)
        World.label(platform, seal.Name .. "\nПечать " .. ({"огня", "льда", "бури"})[index], Vector3.new(0, 10, 0))
        for side = -1, 1, 2 do
            block("Колонна печати", Vector3.new(2, 7, 2), origin * CFrame.new(side*6, 4, 5), stone, Enum.Material.Marble)
            local crystal = block("Кристалл", Vector3.new(1.4, 2.2, 1.4), origin * CFrame.new(side*6, 8, 5) * CFrame.Angles(0, 0, math.pi/4), color, Enum.Material.Neon, false)
            local light = Instance.new("PointLight"); light.Color = color; light.Brightness = 0.7; light.Range = 14; light.Parent = crystal
        end
        block("Перемычка", Vector3.new(15, 1.5, 3), origin * CFrame.new(0, 7.5, 5), stone)
        local altar = block("Рунический алтарь", Vector3.new(4, 2.2, 3), origin * CFrame.new(0, 1.7, 0), stone, Enum.Material.Marble)
        local rune = block("Символ стихии", Vector3.new(1.4, 0.15, 1.4), origin * CFrame.new(0, 2.9, 0) * CFrame.Angles(0, math.pi/4, 0), color, Enum.Material.Neon, false)
        World.prompt(altar, "Пробудить печать", seal.Name, function(player, position) callbacks.seal(player, position, index) end)
        -- Three silhouettes: ruined chapel, shallow moon pool, broken observatory.
        if index == 1 then
            for side = -1, 1, 2 do
                block("Стена часовни", Vector3.new(1, 5, 12), origin * CFrame.new(side*8, 2.5, 0), Color3.fromRGB(119, 96, 83), Enum.Material.Brick)
            end
            block("Стела часовни", Vector3.new(3, 10, 2), origin * CFrame.new(0, 5, 8), stone)
        elseif index == 2 then
            local water = block("Лунный бассейн", Vector3.new(11, 0.12, 6), origin * CFrame.new(0, 0.68, 5), color, Enum.Material.Glass, false)
            water.Transparency = 0.4
            for i = 1, 8 do
                local angle = i * math.pi/4
                block("Камни источника", Vector3.new(2, 0.8, 2), origin * CFrame.new(math.cos(angle)*6, 0.9, 5 + math.sin(angle)*3), stone)
            end
        else
            for i = 1, 12 do
                local angle = i * math.pi/6
                block("Звёздный круг", Vector3.new(0.2, 0.15, 2.4), origin * CFrame.new(math.cos(angle)*5, 0.68, math.sin(angle)*5) * CFrame.Angles(0, -angle, 0), color, Enum.Material.Neon, false)
            end
            block("Обелиск", Vector3.new(2, 12, 2), origin * CFrame.new(0, 6, 9) * CFrame.Angles(0, 0, -0.12), stone)
        end
        for z = 14, math.abs(seal.Z) - 12, 6 do
            block("Ответвление тропы", Vector3.new(5, 0.15, 4.5), CFrame.new(seal.X, 0.18, z * math.sign(seal.Z)), Color3.fromRGB(115, 113, 94), Enum.Material.Cobblestone)
        end
    end
    for index, point in {Vector3.new(107, 1.5, -74), Vector3.new(172, 1.5, 76)} do
        local chest = block("Тайник исследователя", Vector3.new(3.5, 2.5, 2.5), CFrame.new(point), Color3.fromRGB(109, 74, 43), Enum.Material.Wood)
        block("Обруч сундука", Vector3.new(3.65, 0.3, 2.6), CFrame.new(point + Vector3.new(0, 0.7, 0)), Color3.fromRGB(201, 163, 85), Enum.Material.Metal, false)
        World.prompt(chest, "Открыть тайник", "Забытые припасы", function(player, position) callbacks.cache(player, position, index) end)
    end
    local rest = block("Чаша святилища", Vector3.new(3, 2, 3), CFrame.new(7, 1.3, -7), Color3.fromRGB(109, 219, 231), Enum.Material.Neon)
    World.prompt(rest, "Восстановить силы", "Источник первой зари", callbacks.rest)
    local board = block("Карта долины", Vector3.new(5, 4, 0.6), CFrame.new(29, 3, 8) * CFrame.Angles(0, -0.4, 0), Color3.fromRGB(108, 77, 51), Enum.Material.Wood)
    World.label(board, "Три печати → Хранитель → Иар\nM — карта долины", Vector3.new(0, 4, 0))
    -- Bounds align with the existing static Ground. Walls stop falls beyond the first region.
    for _, spec in {
        {Vector3.new(360, 18, 2), Vector3.new(80, 8, -119)},
        {Vector3.new(360, 18, 2), Vector3.new(80, 8, 119)},
        {Vector3.new(2, 18, 240), Vector3.new(-99, 8, 0)},
        {Vector3.new(2, 18, 240), Vector3.new(259, 8, 0)},
    } do
        local wall = block("Граница долины", spec[1], CFrame.new(spec[2]), stone)
        wall.Transparency = 1
    end
end
return Location
