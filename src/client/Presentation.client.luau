-- Local presentation only; this script cannot grant damage, loot or invulnerability.
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Eldoria")
local rigs = {}
local fx = Instance.new("Folder"); fx.Name = "EldoriaLocalEffects"; fx.Parent = workspace
local function register(model)
    local root = model:WaitForChild("Root", 10)
    if not root then return end
    local pieces = {}
    for _, p in model:GetChildren() do
        if p:IsA("BasePart") and p:GetAttribute("LocalPose") then table.insert(pieces, p) end
    end
    if not model.Parent then return end
    rigs[model] = {root = root, pieces = pieces, previous = root.Position, display = root.CFrame, phase = 0, speed = 0}
end
for _, model in CollectionService:GetTagged("EldoriaRig") do task.spawn(register, model) end
CollectionService:GetInstanceAddedSignal("EldoriaRig"):Connect(function(model) task.spawn(register, model) end)
CollectionService:GetInstanceRemovedSignal("EldoriaRig"):Connect(function(model) rigs[model] = nil end)
local frame = 0
RunService.RenderStepped:Connect(function(dt)
    frame += dt
    if frame < 1/30 then return end
    local step = frame; frame = 0
    local camera = workspace.CurrentCamera
    for model, rig in rigs do
        if not model.Parent then rigs[model] = nil; continue end
        local root = rig.root
        local delta = root.Position - rig.previous; rig.previous = root.Position
        rig.speed += (math.min(16, delta.Magnitude / step) - rig.speed) * math.min(1, step * 8)
        rig.phase += step * (2 + rig.speed * 0.7)
        if camera and (camera.CFrame.Position - root.Position).Magnitude > 180 then continue end
        rig.display = if (rig.display.Position-root.Position).Magnitude>20 then root.CFrame else rig.display:Lerp(root.CFrame,1-math.exp(-step*14))
        local walk = math.sin(rig.phase) * math.min(0.65, rig.speed * 0.075)
        local age = workspace:GetServerTimeNow() - (root:GetAttribute("AttackStart") or -100)
        local swing = if age >= 0 and age < 1 then math.sin(math.min(1, age / 0.8) * math.pi) else 0
        local pattern = root:GetAttribute("AttackPattern")
        local idle = math.sin(rig.phase) * 0.04
        for _, p in rig.pieces do
            local group = p:GetAttribute("Limb")
            local rotation = CFrame.identity
            if group == "leftArm" then rotation = CFrame.Angles(-walk + swing * 0.8, 0, -0.08)
            elseif group == "rightArm" then rotation = CFrame.Angles(walk - swing * 2.2, swing * 0.3, 0.08)
            elseif group == "leftLeg" then rotation = CFrame.Angles(walk, 0, 0)
            elseif group == "rightLeg" then rotation = CFrame.Angles(-walk, 0, 0)
            elseif group == "head" then rotation = CFrame.Angles(idle, idle * 2, 0) end
            if swing>0 and pattern=="barrage" and (group=="rightArm" or group=="leftArm") then rotation=CFrame.Angles(-swing*2.4,0,if group=="rightArm" then 0.2 else -0.2)
            elseif swing>0 and pattern=="cleave" and group=="body" then rotation=CFrame.Angles(0,swing*0.4,0) end
            local pivot = p:GetAttribute("Pivot")
            p.CFrame = rig.display * CFrame.new(0, idle, 0) * CFrame.new(pivot) * rotation * CFrame.new(-pivot) * p:GetAttribute("LocalPose")
        end
    end
end)
local function ball(position, color, startSize, endSize, duration)
    local p = Instance.new("Part"); p.Shape = Enum.PartType.Ball; p.Size = Vector3.one * startSize
    p.Position = position; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
    p.Material = Enum.Material.Neon; p.Color = color; p.Transparency = 0.25; p.Parent = fx
    TweenService:Create(p, TweenInfo.new(duration), {Size = Vector3.one * endSize, Transparency = 1}):Play()
    Debris:AddItem(p, duration)
end
local function hitNumber(position, damage, color)
    local anchor = Instance.new("Part"); anchor.Anchored = true; anchor.Transparency = 1
    anchor.Size = Vector3.one * 0.1; anchor.Position = position + Vector3.new(0, 3, 0)
    anchor.CanCollide = false; anchor.CanQuery = false; anchor.CanTouch = false; anchor.Parent = fx
    local gui = Instance.new("BillboardGui"); gui.Size = UDim2.fromOffset(100, 50); gui.AlwaysOnTop = true; gui.Parent = anchor
    local text = Instance.new("TextLabel"); text.Size = UDim2.fromScale(1, 1); text.BackgroundTransparency = 1
    text.Font = Enum.Font.GothamBold; text.TextSize = 27; text.TextColor3 = color
    text.TextStrokeTransparency = 0.5; text.Text = tostring(math.floor(damage)); text.Parent = gui
    TweenService:Create(anchor, TweenInfo.new(0.8), {Position = anchor.Position + Vector3.new(0, 3, 0)}):Play()
    TweenService:Create(text, TweenInfo.new(0.8), {TextTransparency = 1}):Play(); Debris:AddItem(anchor, 0.85)
end
local function line(a, b, color, width, lifetime)
    if (b-a).Magnitude < 0.01 then return end
    local p = Instance.new("Part"); p.Size = Vector3.new(width, width, (b-a).Magnitude)
    p.CFrame = CFrame.lookAt((a+b)/2,b); p.Anchored = true; p.CanCollide = false
    p.CanQuery = false; p.CanTouch = false; p.Material = Enum.Material.Neon; p.Color = color; p.Parent = fx
    TweenService:Create(p,TweenInfo.new(lifetime),{Transparency = 1}):Play(); Debris:AddItem(p,lifetime)
end
local function glyph(position, color, radius, lifetime)
    for i = 1, 12 do
        local a, b = i*math.pi/6, (i+1)*math.pi/6
        line(position+Vector3.new(math.cos(a)*radius,0,math.sin(a)*radius),position+Vector3.new(math.cos(b)*radius,0,math.sin(b)*radius),color,0.1,lifetime)
    end
    for i = 1, 3 do
        local a = i*math.pi*2/3
        line(position+Vector3.new(math.cos(a)*radius,0,math.sin(a)*radius),position+Vector3.new(math.cos(a+math.pi*2/3)*radius,0,math.sin(a+math.pi*2/3)*radius),color,0.09,lifetime)
    end
end
local swings = {}
local function swing(character, cast)
    if not character then return end
    local weapon = character:FindFirstChild("EldoriaBlade")
    local handle = weapon and weapon:FindFirstChild("Handle")
    local grip = handle and handle:FindFirstChild("BladeGrip")
    if not grip then return end
    local entry = swings[grip]
    if entry then entry.tween:Cancel() end
    local base = if entry then entry.base else grip.C0
    local tween = TweenService:Create(grip, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true),
        {C0 = base * CFrame.Angles(math.rad(if cast then -40 else -110), 0, math.rad(if cast then 0 else -45))})
    local state = {base = base, tween = tween}; swings[grip] = state
    local trail = handle:FindFirstChildOfClass("Trail"); if trail then trail.Enabled = true end
    tween:Play()
    task.delay(0.45, function()
        if swings[grip] ~= state then return end
        swings[grip] = nil
        if grip.Parent then grip.C0 = base end
        if trail and trail.Parent then trail.Enabled = false end
    end)
end
local visual = Shared:WaitForChild("Remotes"):WaitForChild("Visual")
visual.OnClientEvent:Connect(function(kind, data)
    if kind == "swing" then
        local player = Players:GetPlayerByUserId(data.user)
        swing(player and player.Character, data.cast)
    elseif kind == "hit" then
        task.delay(data.delay or 0, function()
            ball(data.position, data.color, 0.5, 4, 0.25); hitNumber(data.position, data.damage, data.color)
        end)
    elseif kind == "death" then
        ball(data.position, Color3.fromRGB(183, 110, 255), 2, 9, 0.7)
        for i = 1, 8 do
            local angle = i * math.pi / 4
            ball(data.position + Vector3.new(math.cos(angle) * 2, 0.5, math.sin(angle) * 2), Color3.fromRGB(160, 220, 250), 0.6, 0.05, 0.6)
        end
    elseif kind == "dodge" then ball(data.position, Color3.fromRGB(130, 220, 230), 2, 6, 0.35)
    elseif kind == "ritual" then
        glyph(data.position + Vector3.new(0, 1.3, 0), data.color, 6, 1.8)
        ball(data.position, data.color, 1, 12, 1.2)

    end
end)

-- Small, functional quality switch; remains usable if the main HUD fails to initialise.
local gui = Instance.new("ScreenGui"); gui.Name = "EldoriaGraphics"; gui.ResetOnSpawn = false
local button = Instance.new("TextButton"); button.Size = UDim2.fromOffset(140, 30)
button.Position = UDim2.new(1, -155, 0, 155); button.BackgroundColor3 = Color3.fromRGB(25, 32, 45)
button.TextColor3 = Color3.fromRGB(220, 203, 151); button.TextSize = 13; button.Font = Enum.Font.Gotham
button.Text = "Свечение: вкл"; button.Parent = gui; gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
local enabled = true
button.Activated:Connect(function()
    enabled = not enabled; button.Text = if enabled then "Свечение: вкл" else "Свечение: выкл"
    local bloom = game:GetService("Lighting"):FindFirstChild("EldoriaBloom")
    if bloom then bloom.Enabled = enabled end
end)
