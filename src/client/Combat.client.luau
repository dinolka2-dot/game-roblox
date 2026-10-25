local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Eldoria")
local Motion = require(script.Parent.Motion)
local player = Players.LocalPlayer
local target; local shake = 0; local reduceMotion = false
local gui = Instance.new("ScreenGui"); gui.Name="EldoriaCombat"; gui.ResetOnSpawn=false; gui.Parent=player:WaitForChild("PlayerGui")
local function button(text,y,fn)
    local b=Instance.new("TextButton"); b.Size=UDim2.fromOffset(140,30); b.Position=UDim2.new(1,-155,0,y)
    b.BackgroundColor3=Color3.fromRGB(25,32,45); b.TextColor3=Color3.fromRGB(225,205,151)
    b.Text=text; b.TextSize=13; b.Parent=gui; b.Activated:Connect(fn); return b
end
local title=Instance.new("TextLabel"); title.Size=UDim2.fromOffset(320,40); title.AnchorPoint=Vector2.new(0.5,0)
title.Position=UDim2.new(0.5,0,0,140); title.BackgroundColor3=Color3.fromRGB(25,29,40)
title.TextColor3=Color3.fromRGB(235,215,170); title.Font=Enum.Font.GothamBold; title.TextSize=17; title.Visible=false; title.Parent=gui
local mark=Instance.new("BillboardGui"); mark.Size=UDim2.fromOffset(22,22); mark.AlwaysOnTop=true; mark.Parent=gui
local dot=Instance.new("TextLabel"); dot.Size=UDim2.fromScale(1,1); dot.BackgroundTransparency=1; dot.Text="◇"; dot.TextSize=24; dot.TextColor3=Color3.fromRGB(245,200,100); dot.Parent=mark
local function unlock() target=nil; mark.Adornee=nil; title.Visible=false end
local function toggle()
    if target then unlock(); return end
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local camera=workspace.CurrentCamera; if not root or not camera then return end
    local best=math.huge
    for _, model in CollectionService:GetTagged("EldoriaRig") do
        local r=model:FindFirstChild("Root")
        if r and (r:GetAttribute("Health") or 0)>0 then
            local delta=r.Position-root.Position
            local screen,onScreen=camera:WorldToViewportPoint(r.Position)
            if onScreen and delta.Magnitude<65 then
                local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={player.Character}
                local hit=workspace:Raycast(root.Position,delta,params)
                local score=delta.Magnitude+(Vector2.new(screen.X,screen.Y)-camera.ViewportSize/2).Magnitude*0.04
                if score<best and (not hit or hit.Instance:IsDescendantOf(model)) then target=r; best=score end
            end
        end
    end
    if target then mark.Adornee=target end
end
button("Захват · Ctrl",225,toggle)
local motionButton
motionButton=button("Тряска: вкл",260,function() reduceMotion=not reduceMotion; motionButton.Text=if reduceMotion then "Тряска: выкл" else "Тряска: вкл" end)
UIS.InputBegan:Connect(function(input,processed) if not processed and input.KeyCode==Enum.KeyCode.LeftControl then toggle() end end)
player.CharacterAdded:Connect(unlock)
RunService:BindToRenderStep("EldoriaCamera",Enum.RenderPriority.Camera.Value+1,function(dt)
    local camera=workspace.CurrentCamera
    local char=player.Character; local root=char and char:FindFirstChild("HumanoidRootPart")
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not camera or not root or not hum or hum.Health<=0 then unlock(); return end
    if target then
        if not target.Parent or (target:GetAttribute("Health") or 0)<=0 or (target.Position-root.Position).Magnitude>80 then unlock()
        else
            local flat=Vector3.new(target.Position.X-root.Position.X,0,target.Position.Z-root.Position.Z)
            if flat.Magnitude>0.1 then
                local focus=root.Position:Lerp(target.Position,0.35)+Vector3.new(0,2,0)
                local desired=root.Position-flat.Unit*13+Vector3.new(0,5,0)+flat.Unit:Cross(Vector3.yAxis)*2
                local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances={char,target.Parent}
                local delta=desired-focus
                local hit=workspace:Spherecast(focus,0.5,delta,params)
                if hit then desired=focus+delta.Unit*math.max(0.5,hit.Distance-0.5) end
                camera.CFrame=camera.CFrame:Lerp(CFrame.lookAt(desired,focus),1-math.exp(-dt*12))
                root.CFrame=CFrame.lookAt(root.Position,root.Position+flat.Unit)
            end
            title.Visible=true
            title.Text=target.Parent.Name.." · "..math.ceil(target:GetAttribute("Health") or 0).." / "..(target:GetAttribute("MaxHealth") or 0)
        end
    end
    shake=math.max(0,shake-dt*2)
    if not reduceMotion and shake>0 then
        camera.CFrame*=CFrame.Angles(math.sin(os.clock()*47)*shake*0.01,math.cos(os.clock()*61)*shake*0.01,0)
    end
end)
Shared:WaitForChild("Remotes"):WaitForChild("Visual").OnClientEvent:Connect(function(kind,data)
    if kind=="meleePose" then
        local p=Players:GetPlayerByUserId(data.user)
        if p and p.Character then
            Motion.play(p.Character,"melee",data.duration,data.combo)
            local blade=p.Character:FindFirstChild("EldoriaBlade")
            local trail=blade and blade:FindFirstChildWhichIsA("Trail",true)
            if trail then
                trail.Enabled=true
                task.delay(0.38,function() if trail.Parent then trail.Enabled=false end end)
            end
        end
    elseif kind=="hit" or kind=="spellHit" then
        local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if root and (root.Position-data.position).Magnitude<25 then shake=math.min(1,shake+0.3) end
    end
end)
