-- Original, self-contained articulated low-poly characters; no external assets.
local CollectionService = game:GetService("CollectionService")
local Characters = {}
local bone = Color3.fromRGB(191, 182, 148)
local iron = Color3.fromRGB(54, 64, 83)
local violet = Color3.fromRGB(177, 90, 255)
local function piece(model, name, size, cf, color, material, group, pivot)
    local part = Instance.new("Part")
    part.Name = name; part.Size = size; part.CFrame = cf; part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.Anchored = true; part.CanCollide = false; part.CanTouch = false; part.CanQuery = false
    part:SetAttribute("LocalPose", cf); part:SetAttribute("Limb", group or "body")
    part:SetAttribute("Pivot", pivot or Vector3.zero); part.Parent = model
    return part
end
function Characters.create(parent, name, position, kind)
    local model = Instance.new("Model"); model.Name = name
    local boss = kind == "warden"
    local caster = kind == "shade"
    local human = kind == "elder" or kind == "merchant"
    local scale = if boss then 1.65 else 1
    local glow = if human or caster then Color3.fromRGB(120, 225, 225) else violet
    local armor = if human then Color3.fromRGB(75, 90, 125) else iron
    local root = Instance.new("Part"); root.Name = "Root"; root.Anchored = true
    root.Size = Vector3.new(3, 5, 2) * scale; root.Transparency = 1
    root.CanCollide = false; root.CanTouch = false; root.CFrame = CFrame.new(position)
    root.Parent = model; model.PrimaryPart = root
    local function add(n, size, pos, color, group, pivot, material)
        return piece(model, n, size * scale, CFrame.new(pos * scale), color, material, group, pivot and pivot * scale)
    end
    local skin = if human then Color3.fromRGB(199, 159, 118) else bone
    add("Spine", Vector3.new(0.5, 2, 0.6), Vector3.new(0, 0.3, 0), skin)
    for i = 1, 3 do
        add("Rib", Vector3.new(2.1 - i * 0.18, 0.23, 0.9), Vector3.new(0, 1.2 - i * 0.45, 0), skin)
    end
    add("Armor", Vector3.new(2.25, 0.9, 1.1), Vector3.new(0, 0.8, 0.05), armor)
    add("Core", Vector3.new(0.4, 0.5, 0.25), Vector3.new(0, 0.85, -0.63), glow, nil, nil, Enum.Material.Neon)
    add("Belt", Vector3.new(1.8, 0.45, 1), Vector3.new(0, -0.8, 0), armor)
    add("Skull", Vector3.new(1.35, 1.25, 1.15), Vector3.new(0, 2.1, 0), skin, "head", Vector3.new(0, 1.45, 0))
    add("Jaw", Vector3.new(0.95, 0.28, 0.9), Vector3.new(0, 1.4, -0.05), skin, "head", Vector3.new(0, 1.45, 0))
    for _, side in {-1, 1} do
        add("EyeSocket", Vector3.new(0.47, 0.4, 0.12), Vector3.new(side * 0.34, 2.2, -0.59), iron, "head", Vector3.new(0, 1.45, 0))
        add("Eye", Vector3.new(0.24, 0.18, 0.13), Vector3.new(side * 0.34, 2.2, -0.67), glow, "head", Vector3.new(0, 1.45, 0), Enum.Material.Neon)
        local arm = if side == -1 then "leftArm" else "rightArm"
        local leg = if side == -1 then "leftLeg" else "rightLeg"
        local ap = Vector3.new(side * 1.4, 1, 0)
        local lp = Vector3.new(side * 0.6, -0.9, 0)
        add("Pauldron", Vector3.new(0.95, 0.7, 1.2), Vector3.new(side * 1.4, 1, 0), armor, arm, ap)
        add("Arm", Vector3.new(0.45, 1.9, 0.5), Vector3.new(side * 1.4, -0.1, 0), skin, arm, ap)
        add("Gauntlet", Vector3.new(0.7, 0.65, 0.8), Vector3.new(side * 1.4, -0.95, 0), armor, arm, ap)
        add("Leg", Vector3.new(0.5, 1.65, 0.55), Vector3.new(side * 0.6, -1.7, 0), skin, leg, lp)
        add("Boot", Vector3.new(0.8, 0.6, 1.1), Vector3.new(side * 0.6, -2.45, -0.2), armor, leg, lp)
    end
    if human or caster then
        add("Robe", Vector3.new(2, 2.5, 1.3), Vector3.new(0, -0.2, 0.1), if kind == "elder" then Color3.fromRGB(83, 63, 122) else Color3.fromRGB(107, 79, 46))
        add("Hood", Vector3.new(1.6, 0.4, 1.4), Vector3.new(0, 2.85, 0), armor, "head", Vector3.new(0, 1.45, 0))
    end
    if not human then
        local ap = Vector3.new(1.4, 1, 0)
        add("SwordGrip", Vector3.new(0.25, 0.8, 0.25), Vector3.new(1.4, -1, -0.7), iron, "rightArm", ap)
        add("SwordGuard", Vector3.new(1, 0.18, 0.3), Vector3.new(1.4, -0.6, -0.7), armor, "rightArm", ap)
        add("SwordBlade", Vector3.new(0.35, 2.5, 0.16), Vector3.new(1.4, 0.7, -0.7), glow, "rightArm", ap, Enum.Material.Neon)
    end
    if boss then
        for i = -2, 2 do
            add("CrownSpike", Vector3.new(0.2, 0.75 + math.abs(i) * 0.2, 0.3), Vector3.new(i * 0.3, 3, 0), glow, "head", Vector3.new(0, 1.45, 0), Enum.Material.Neon)
        end
    end
    for _, part in model:GetChildren() do
        if part:IsA("BasePart") and part ~= root then part.CFrame = root.CFrame * part:GetAttribute("LocalPose") end
    end
    model:SetAttribute("Style", kind); model.Parent = parent
    CollectionService:AddTag(model, "EldoriaRig")
    return model, root
end
function Characters.equip(character)
    local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
    if not hand or character:FindFirstChild("EldoriaBlade") then return end
    local model = Instance.new("Model"); model.Name = "EldoriaBlade"
    local handle = Instance.new("Part"); handle.Name = "Handle"; handle.Size = Vector3.new(0.25, 1, 0.25)
    handle.CFrame = hand.CFrame; handle.Color = iron; handle.CanCollide = false
    handle.CanTouch = false; handle.CanQuery = false; handle.Massless = true; handle.Parent = model
    local grip = Instance.new("Motor6D"); grip.Name = "BladeGrip"; grip.Part0 = hand; grip.Part1 = handle
    grip.C0 = CFrame.new(0, -0.6, -0.4) * CFrame.Angles(math.rad(-90), 0, 0); grip.Parent = handle
    for _, spec in {
        {"Guard", Vector3.new(1.2, 0.18, 0.35), CFrame.new(0, 0.55, 0), Color3.fromRGB(203, 167, 85)},
        {"Blade", Vector3.new(0.42, 2.8, 0.16), CFrame.new(0, 2, 0), Color3.fromRGB(184, 209, 224)},
        {"RuneEdge", Vector3.new(0.1, 2.5, 0.19), CFrame.new(0, 2, 0), Color3.fromRGB(100, 230, 244)},
    } do
        local p = Instance.new("Part"); p.Name = spec[1]; p.Size = spec[2]; p.CFrame = handle.CFrame * spec[3]
        p.Color = spec[4]; p.Material = if spec[1] == "RuneEdge" then Enum.Material.Neon else Enum.Material.Metal
        p.CanCollide = false; p.CanTouch = false; p.CanQuery = false; p.Massless = true; p.Parent = model
        local weld = Instance.new("WeldConstraint"); weld.Part0 = handle; weld.Part1 = p; weld.Parent = p
    end
    local a = Instance.new("Attachment"); a.Position = Vector3.new(0, 0.8, 0); a.Parent = handle
    local b = Instance.new("Attachment"); b.Position = Vector3.new(0, 3.4, 0); b.Parent = handle
    local trail = Instance.new("Trail"); trail.Attachment0 = a; trail.Attachment1 = b
    trail.Lifetime = 0.18; trail.Color = ColorSequence.new(Color3.fromRGB(120, 225, 255))
    trail.Transparency = NumberSequence.new(0.2, 1); trail.Enabled = false; trail.Parent = handle
    model.Parent = character
end
return Characters
