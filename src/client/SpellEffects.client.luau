-- Authored motion timelines: charge, body pose, release, travel, impact and recovery.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Eldoria")
local Book = require(Shared:WaitForChild("Spellbook"))
local effects = Instance.new("Folder"); effects.Name = "SpellEffects"; effects.Parent = workspace
local moving = {}; local poses = {}
local cancelled = {}; local zones = {}
local function track(serial, instance)
    zones[serial] = zones[serial] or {}
    table.insert(zones[serial],instance)
end
local bases = setmetatable({}, {__mode = "k"})
local owners = setmetatable({}, {__mode = "k"})
local poseTweens = setmetatable({}, {__mode = "k"})
local function part(size, cf, color, shape)
    local p = Instance.new("Part"); p.Size = size; p.CFrame = cf; p.Color = color
    p.Shape = shape or Enum.PartType.Ball; p.Material = Enum.Material.Neon
    p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false
    p.CastShadow = false; p.Parent = effects; return p
end
local function fade(p, duration, size)
    local goal = {Transparency = 1}
    if size then goal.Size = size end
    TweenService:Create(p,TweenInfo.new(duration),goal):Play()
    Debris:AddItem(p,duration+0.05)
end
local function segment(a,b,color,width,life)
    if (b-a).Magnitude < 0.01 then return end
    local p = part(Vector3.new(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),color,Enum.PartType.Block)
    fade(p,life); return p
end
local function ring(position,color,radius,life)
    local model = Instance.new("Model"); model.Parent = effects
    for i = 1, 24 do
        local a,b = i*math.pi/12,(i+1)*math.pi/12
        local p = segment(position+Vector3.new(math.cos(a)*radius,0,math.sin(a)*radius),position+Vector3.new(math.cos(b)*radius,0,math.sin(b)*radius),color,0.12,life)
        if p then p.Parent = model end
    end
    Debris:AddItem(model,life+0.1); return model
end
local function flash(position,color,radius)
    local p = part(Vector3.one,CFrame.new(position),color); fade(p,0.4,Vector3.one*radius*2)
    for i = 1, 8 do
        local a = i*math.pi/4
        local spark = part(Vector3.one*0.25,CFrame.new(position),color)
        TweenService:Create(spark,TweenInfo.new(0.5),{Position = position+Vector3.new(math.cos(a)*radius,radius*0.6,math.sin(a)*radius),Transparency = 1}):Play()
        Debris:AddItem(spark,0.6)
    end
end
local function stopPose(serial)
    local pose = poses[serial]; if not pose then return end
    poses[serial] = nil
    for motor, base in pose.joints do
        if motor.Parent and owners[motor] == serial then
            owners[motor] = nil
            if poseTweens[motor] then poseTweens[motor]:Cancel() end
            poseTweens[motor] = TweenService:Create(motor,TweenInfo.new(0.18),{C0 = base})
            poseTweens[motor]:Play()
        end
    end
end
local function bodyPose(data)
    local player = Players:GetPlayerByUserId(data.user); local char = player and player.Character
    if not char then return end
    for serial, pose in poses do if pose.char == char then stopPose(serial) end end
    local pose = {char = char,joints = {}}; poses[data.serial] = pose
    for _, motor in char:GetDescendants() do
        if motor:IsA("Motor6D") then
            local offset
            if motor.Name == "RightShoulder" or motor.Name == "Right Shoulder" then offset = CFrame.Angles(-1.4,0,0.35)
            elseif motor.Name == "LeftShoulder" or motor.Name == "Left Shoulder" then offset = CFrame.Angles(-1.1,0,-0.4)
            elseif motor.Name == "Waist" then offset = CFrame.Angles(0.12,-0.2,0)
            elseif motor.Name == "Neck" then offset = CFrame.Angles(-0.12,0.12,0) end
            if offset then
                local base = bases[motor] or motor.C0; bases[motor] = base
                if poseTweens[motor] then poseTweens[motor]:Cancel() end
                motor.C0 = base; owners[motor] = data.serial; pose.joints[motor] = base
                poseTweens[motor] = TweenService:Create(motor,TweenInfo.new(data.duration),{C0 = base*offset})
                poseTweens[motor]:Play()
            end
        end
    end
    task.delay(data.duration+0.25,function() stopPose(data.serial) end)
end
local function clear(serial)
    local entry = moving[serial]
    if entry then
        moving[serial] = nil
        if entry.model then entry.model:Destroy() end
    end
end
local function projectile(data)
    clear(data.serial)
    local definition = Book.Definitions[data.id]
    local model = Instance.new("Model"); model.Parent = effects
    local count = if definition.Rune == "fire" then 4 else 1
    for i = 1, count do
        local p = part(if definition.Rune == "fire" then Vector3.one*(1.5-i*0.2) else Vector3.new(0.5,0.5,3),CFrame.lookAt(data.origin,data.origin+data.direction),data.color,if definition.Rune == "fire" then Enum.PartType.Ball else Enum.PartType.Block)
        p.Parent = model
        local a = Instance.new("Attachment"); a.Position = Vector3.new(0,0.4,0); a.Parent = p
        local b = Instance.new("Attachment"); b.Position = Vector3.new(0,-0.4,0); b.Parent = p
        local trail = Instance.new("Trail"); trail.Attachment0 = a; trail.Attachment1 = b
        trail.Color = ColorSequence.new(data.color); trail.Lifetime = 0.22; trail.Parent = p
    end
    moving[data.serial] = {model = model, origin = data.origin, direction = data.direction, speed = definition.Speed, start = os.clock(),range = definition.Range}
end
RunService.RenderStepped:Connect(function()
    local now = os.clock()
    for serial, e in moving do
        local age = now-e.start
        if age > e.range/e.speed+0.5 then clear(serial); continue end
        local travel = math.min(e.range,age*e.speed)
        for i,p in e.model:GetChildren() do
            if p:IsA("BasePart") then
                local position = e.origin+e.direction*math.max(0,travel-(i-1)*0.7)
                p.CFrame = CFrame.lookAt(position,position+e.direction)*CFrame.Angles(0,0,age*8)
            end
        end
    end
end)
local function arc(a,b,color,life)
    local previous = a
    for i = 1, 12 do
        local point = a:Lerp(b,i/12)
        if i < 12 then point += Vector3.new(math.sin(i*7)*1.1,math.cos(i*5)*0.9,math.sin(i*3)) end
        segment(previous,point,color,0.18,life); previous = point
    end
end
Shared:WaitForChild("Remotes"):WaitForChild("Visual").OnClientEvent:Connect(function(kind,data)
    local definition = data.id and Book.Definitions[data.id]
    local camera = workspace.CurrentCamera
    local position = data.origin or data.position
    if camera and position and (camera.CFrame.Position-position).Magnitude > 220 then return end
    if kind == "spellCharge" then
        task.delay(8,function() cancelled[data.serial] = nil; zones[data.serial] = nil end)
        bodyPose(data)
        local glyph = ring(data.origin+Vector3.new(0,-2.5,0),data.color,2.7,data.duration+0.1)
        local start = glyph:GetPivot()
        local connection; local age = 0
        connection = RunService.RenderStepped:Connect(function(dt)
            age += dt
            if age > data.duration or not glyph.Parent then connection:Disconnect(); return end
            glyph:PivotTo(start*CFrame.Angles(0,age*3,0))
        end)
        local orb = part(Vector3.one*0.2,CFrame.new(data.origin+data.direction*2),data.color)
        TweenService:Create(orb,TweenInfo.new(data.duration),{Size = Vector3.one*2}):Play()
        fade(orb,data.duration+0.1)
    elseif kind == "spellRelease" and definition then
        if definition.Kind == "projectile" then projectile(data)
        elseif definition.Kind == "ring" then
            for i = 1, 10 do task.delay(i*definition.Duration/10,function()
                if cancelled[data.serial] then return end
                track(data.serial,ring(data.origin+Vector3.new(0,-2.5,0),data.color,definition.Radius*i/10,0.18))
            end) end
        end
    elseif kind == "spellZone" and definition then
        local ground = Vector3.new(data.position.X,0.3,data.position.Z)
        track(data.serial,ring(ground,data.color,data.radius,data.duration))
        if definition.Kind == "meteor" then
            local rock = part(Vector3.one*5,CFrame.new(data.position+Vector3.new(0,40,0)),data.color)
            track(data.serial,rock)
            TweenService:Create(rock,TweenInfo.new(data.duration,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position = data.position,Size = Vector3.one*3}):Play()
            Debris:AddItem(rock,data.duration+0.05)
        elseif definition.Kind == "vortex" then
            local model = Instance.new("Model"); model.Parent = effects
            track(data.serial,model)
            local pieces = {}
            for i = 1, 20 do
                local p = part(Vector3.new(0.3,0.3,2),CFrame.new(data.position),data.color,Enum.PartType.Block)
                p.Parent = model; table.insert(pieces,p)
            end
            local age = 0; local connection
            connection = RunService.RenderStepped:Connect(function(dt)
                age += dt
                if age > data.duration or not model.Parent then connection:Disconnect(); model:Destroy(); return end
                for i,p in pieces do
                    local a = age*7+i*math.pi/5; local h = i/20*8
                    p.CFrame = CFrame.new(ground+Vector3.new(math.cos(a)*(3+h*0.4),h,math.sin(a)*(3+h*0.4)))*CFrame.Angles(0,-a,0.4)
                    p.Transparency = math.max(0,(age/data.duration-0.8)*5)
                end
            end)
        end
    elseif kind == "spellSpike" then
        local p = part(Vector3.new(1.3,0.1,1.3),CFrame.new(data.position.X,0,data.position.Z),data.color,Enum.PartType.Block)
        TweenService:Create(p,TweenInfo.new(0.15),{Size = Vector3.new(1.3,6,1.3),CFrame = CFrame.new(data.position.X,3,data.position.Z)*CFrame.Angles(0.1,0,0.2)}):Play()
        task.delay(0.4,function() fade(p,0.3,Vector3.new(0.1,0.1,0.1)) end)
    elseif kind == "spellArc" then arc(data.origin,data.position,data.color,0.2); flash(data.position,data.color,1.5)
    elseif kind == "spellImpact" then clear(data.serial); flash(data.position,data.color,data.radius); ring(Vector3.new(data.position.X,0.3,data.position.Z),data.color,data.radius,0.5)
    elseif kind == "spellEnd" then clear(data.serial)
    elseif kind == "spellCancel" then
        cancelled[data.serial] = true; clear(data.serial); stopPose(data.serial)
        for _, object in zones[data.serial] or {} do object:Destroy() end
        zones[data.serial] = nil
    elseif kind == "spellHit" then
        -- Reuse the established hit-number presentation without accepting client damage.
        local anchor = part(Vector3.one*0.1,CFrame.new(data.position+Vector3.new(0,3,0)),data.color); anchor.Transparency = 1
        local gui = Instance.new("BillboardGui"); gui.Size = UDim2.fromOffset(90,40); gui.AlwaysOnTop = true; gui.Parent = anchor
        local label = Instance.new("TextLabel"); label.Size = UDim2.fromScale(1,1); label.BackgroundTransparency = 1
        label.Text = tostring(math.floor(data.damage)); label.TextSize = 26; label.Font = Enum.Font.GothamBold
        label.TextColor3 = data.color; label.TextStrokeTransparency = 0.4; label.Parent = gui
        TweenService:Create(anchor,TweenInfo.new(0.7),{Position = anchor.Position+Vector3.new(0,3,0)}):Play()
        Debris:AddItem(anchor,0.75)
    end
end)
