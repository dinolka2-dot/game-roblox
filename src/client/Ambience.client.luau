local CollectionService=game:GetService("CollectionService")
local RunService=game:GetService("RunService")
local leaves={}; local water={}
local function bind(instance,tableRef)
    if instance:IsA("BasePart") then tableRef[instance]={base=instance.CFrame,phase=instance.Position.X*0.1+instance.Position.Z*0.07} end
end
for _, p in CollectionService:GetTagged("EldoriaWind") do bind(p,leaves) end
for _, p in CollectionService:GetTagged("EldoriaWater") do bind(p,water) end
CollectionService:GetInstanceAddedSignal("EldoriaWind"):Connect(function(p) bind(p,leaves) end)
CollectionService:GetInstanceAddedSignal("EldoriaWater"):Connect(function(p) bind(p,water) end)
CollectionService:GetInstanceRemovedSignal("EldoriaWind"):Connect(function(p) leaves[p]=nil end)
CollectionService:GetInstanceRemovedSignal("EldoriaWater"):Connect(function(p) water[p]=nil end)
local accumulated=0
RunService.Heartbeat:Connect(function(dt)
    accumulated+=dt; if accumulated<0.07 then return end; accumulated=0
    local camera=workspace.CurrentCamera; if not camera then return end
    local time=os.clock()
    for p,data in leaves do
        if not p.Parent then leaves[p]=nil
        elseif (camera.CFrame.Position-data.base.Position).Magnitude<110 then
            p.CFrame=data.base*CFrame.Angles(math.sin(time+data.phase)*0.025,0,math.cos(time*0.8+data.phase)*0.025)
        end
    end
    for p,data in water do
        if not p.Parent then water[p]=nil else p.Transparency=0.22+math.sin(time*4+data.phase)*0.08 end
    end
end)
