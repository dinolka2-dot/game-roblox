-- Original modular scenery, created without Toolbox scripts or asset downloads.
local Lighting = game:GetService("Lighting")
local Chapter = require(game:GetService("ReplicatedStorage").Eldoria.Chapter)
local Scenery = {}
function Scenery.build(root, World)
    local decor = Instance.new("Folder"); decor.Name = "Окружение"; decor.Parent = root
    local stone = Color3.fromRGB(94, 103, 106)
    local wood = Color3.fromRGB(91, 66, 46)
    local gold = Color3.fromRGB(219, 166, 74)
    local function part(name, size, cf, color, material, collide)
        local p = World.part(decor, name, size, cf.Position, color, material)
        p.CFrame = cf
        if collide == false then p.CanCollide = false; p.CanQuery = false; p.CanTouch = false end
        return p
    end
    local function house(x, z, yaw, color)
        local origin = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0)
        local function p(n, s, v, c, m, rotation)
            return part(n, s, origin * CFrame.new(v) * (rotation or CFrame.identity), c, m)
        end
        p("Каменное основание", Vector3.new(16, 1, 14), Vector3.new(0, 0.5, 0), stone)
        p("Штукатурка", Vector3.new(15, 7, 0.6), Vector3.new(0, 4.5, 6), color)
        for _, side in {-1, 1} do
            p("Боковая стена", Vector3.new(0.6, 7, 12), Vector3.new(side * 7.5, 4.5, 0), color)
            p("Вход", Vector3.new(5.4, 7, 0.6), Vector3.new(side * 4.8, 4.5, -6), color)
            p("Стойка", Vector3.new(0.6, 8, 0.8), Vector3.new(side * 7.5, 4.5, -6.2), wood, Enum.Material.Wood)
            p("Скат крыши", Vector3.new(9.5, 0.7, 15), Vector3.new(side * 4, 9, 0), Color3.fromRGB(70, 85, 98), Enum.Material.Slate, CFrame.Angles(0, 0, math.rad(-side * 28)))
            p("Окно", Vector3.new(1.8, 2.4, 0.3), Vector3.new(side * 4.5, 4.7, -6.4), gold, Enum.Material.Neon)
            p("Переплёт", Vector3.new(0.15, 2.6, 0.4), Vector3.new(side * 4.5, 4.7, -6.6), wood)
        end
        p("Балка", Vector3.new(16, 0.6, 0.8), Vector3.new(0, 7.8, -6.1), wood, Enum.Material.Wood)
        p("Над дверью", Vector3.new(4, 2, 0.6), Vector3.new(0, 7, -6), color)
        p("Труба", Vector3.new(2, 5, 2), Vector3.new(4, 10, 2), stone, Enum.Material.Brick)
        p("Ступень", Vector3.new(4, 0.4, 2), Vector3.new(0, 0.2, -8), stone)
    end
    house(-32, -28, -25, Color3.fromRGB(178, 163, 130))
    house(22, 34, 180, Color3.fromRGB(160, 149, 129))
    house(-38, 25, 135, Color3.fromRGB(146, 154, 147))
    -- Paved circle and segmented paths leave the main combat corridor unobstructed.
    for i = 1, 20 do
        local angle = i * math.pi / 10
        part("Камни святилища", Vector3.new(3, 0.25, 4), CFrame.new(math.cos(angle) * 20, 0.2, math.sin(angle) * 20) * CFrame.Angles(0, -angle, 0), stone)
    end
    for x = 26, 204, 6 do
        for _, z in {-3, 3} do
            part("Плита тропы", Vector3.new(4.5, 0.2, 3.5), CFrame.new(x, 0.24, z), Color3.fromRGB(106, 107, 94), Enum.Material.Cobblestone)
        end
    end
    for _, x in {30, 54, 78, 122, 158, 188} do
        local lantern = part("Фонарь", Vector3.new(0.8, 1.2, 0.8), CFrame.new(x, 6, -10), gold, Enum.Material.Neon, false)
        part("Столб фонаря", Vector3.new(0.3, 6, 0.3), CFrame.new(x, 3, -10), wood, Enum.Material.Wood)
        local light = Instance.new("PointLight"); light.Color = gold; light.Range = 14; light.Brightness = 0.7; light.Shadows = false; light.Parent = lantern
    end
    local rng = Random.new(173)
    for i = 1, 56 do
        local x, z = rng:NextNumber(52, 246), rng:NextNumber(-96, 96)
        if math.abs(z) < 25 or (x > 193 and math.abs(z) < 35) then continue end
        local reserved = false
        for _, seal in Chapter.Seals do
            if (Vector3.new(x, 0, z) - Vector3.new(seal.X, 0, seal.Z)).Magnitude < 17 then reserved = true end
        end
        for _, cache in {Vector3.new(107,0,-74), Vector3.new(172,0,76)} do
            if (Vector3.new(x,0,z)-cache).Magnitude < 10 then reserved = true end
        end
        if reserved then continue end
        local height = rng:NextNumber(10, 19)
        local trunk = part("Кора", Vector3.new(2.3, height, 2.3), CFrame.new(x, height/2, z), wood, Enum.Material.Wood)
        trunk.Shape = Enum.PartType.Cylinder; trunk.Size = Vector3.new(height, 2.3, 2.3); trunk.CFrame *= CFrame.Angles(0, 0, math.pi/2)
        for tier = 1, 3 do
            local width = 15 - tier * 2
            local crown = part("Листва", Vector3.new(width, 8, width), CFrame.new(x, height - 2 + tier * 3, z), Color3.fromRGB(32 + tier*5, 64 + i%4*6, 54 + tier*3), Enum.Material.Grass, false)
            crown.Shape = Enum.PartType.Ball
        end
        if i % 3 == 0 then
            local rock = part("Валун", Vector3.new(5, 3, 4), CFrame.new(x + 4, 1.5, z + 4) * CFrame.Angles(0.2, i, 0.3), stone, Enum.Material.Rock)
            rock.Shape = Enum.PartType.Ball
        end
        if i % 2 == 0 then
            for j = 1, 3 do
                part("Лунный цветок", Vector3.new(0.3, 0.7, 0.3), CFrame.new(x + j, 0.7, z - j), Color3.fromRGB(112, 192, 207), Enum.Material.Neon, false)
            end
        end
    end
    -- Ruined colonnade around the boss, with a broad, unobstructed centre.
    for _, z in {-25, 25} do
        for x = 185, 235, 25 do
            part("Основание колонны", Vector3.new(6, 1, 6), CFrame.new(x, 0.5, z), stone)
            part("Колонна", Vector3.new(3, 13, 3), CFrame.new(x, 7, z), stone, Enum.Material.Marble)
            part("Капитель", Vector3.new(5, 1, 5), CFrame.new(x, 14, z), stone)
        end
        part("Разрушенная арка", Vector3.new(31, 2, 4), CFrame.new(197, 15, z), stone)
    end
    for i = 1, 9 do
        local angle = i * math.pi * 2/9
        local pos = Vector3.new(220 + math.cos(angle)*15, 0.3, math.sin(angle)*15)
        part("Руна разлома", Vector3.new(0.4, 0.1, 3), CFrame.new(pos) * CFrame.Angles(0, -angle, 0), Color3.fromRGB(169, 89, 231), Enum.Material.Neon, false)
    end
    local fire = part("Угли костра", Vector3.new(2, 0.4, 2), CFrame.new(7, 0.3, 14), Color3.fromRGB(210, 105, 40), Enum.Material.Neon, false)
    local flame = Instance.new("Fire"); flame.Size = 4; flame.Heat = 3; flame.Parent = fire
    for i = 1, 8 do
        local a = i * math.pi/4
        part("Очаг", Vector3.new(1, 0.7, 1), CFrame.new(7 + math.cos(a)*2, 0.35, 14 + math.sin(a)*2), stone)
    end
    -- Distant silhouettes also hide the rectangular edges of the small first region.
    for i = 1, 24 do
        local x = -65 + i * 13
        for _, z in {-112, 112} do
            local peak = part("Скалы на горизонте", Vector3.new(24, rng:NextNumber(20, 42), 22), CFrame.new(x, 5, z) * CFrame.Angles(0.15, i*0.7, 0.25), Color3.fromRGB(66, 79, 85), Enum.Material.Rock)
            peak.Shape = Enum.PartType.Ball
        end
    end
    local function lighting(class, name)
        local instance = Lighting:FindFirstChild(name) or Instance.new(class)
        instance.Name = name; instance.Parent = Lighting; return instance
    end
    Lighting.ClockTime = 17.3; Lighting.Brightness = 2
    Lighting.Ambient = Color3.fromRGB(94, 103, 120); Lighting.OutdoorAmbient = Color3.fromRGB(114, 128, 142)
    local atmosphere = lighting("Atmosphere", "EldoriaAtmosphere")
    atmosphere.Density = 0.28; atmosphere.Offset = 0.1
    atmosphere.Color = Color3.fromRGB(180, 198, 211); atmosphere.Decay = Color3.fromRGB(104, 91, 129)
    local bloom = lighting("BloomEffect", "EldoriaBloom"); bloom.Intensity = 0.25; bloom.Size = 24; bloom.Threshold = 1.2
    local grade = lighting("ColorCorrectionEffect", "EldoriaGrade")
    grade.Saturation = -0.08; grade.Contrast = 0.1; grade.TintColor = Color3.fromRGB(235, 239, 255)
end
return Scenery
