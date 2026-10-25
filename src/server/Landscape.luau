-- Authored silhouettes around the traversable flat combat area; no external assets.
local CollectionService=game:GetService("CollectionService")
local Landscape={}
function Landscape.build(parent,World)
    local root=Instance.new("Folder"); root.Name="Башня и ландшафт"; root.Parent=parent
    local stone=Color3.fromRGB(69,81,91)
    local function part(name,size,cf,color,material,solid,class)
        local p=Instance.new(class or "Part"); p.Name=name; p.Size=size; p.CFrame=cf; p.Anchored=true
        p.Color=color; p.Material=material or Enum.Material.Rock
        p.CanCollide=solid~=false; p.CanQuery=solid~=false; p.CanTouch=false; p.Parent=root; return p
    end
    -- Main landmark, visible from the sanctuary through gaps in the forest.
    local origin=CFrame.new(232,0,69)
    part("Основание древней башни",Vector3.new(24,4,24),origin*CFrame.new(0,2,0),stone)
    part("Ствол башни",Vector3.new(16,46,16),origin*CFrame.new(0,25,0),stone,Enum.Material.Brick)
    for y=7,43,12 do
        part("Каменный пояс",Vector3.new(18,1.3,18),origin*CFrame.new(0,y,0),Color3.fromRGB(113,119,129))
        part("Окно башни",Vector3.new(2,5,0.3),origin*CFrame.new(0,y+4,-8.2),Color3.fromRGB(156,99,216),Enum.Material.Neon,false)
    end
    for _, x in {-9,9} do
        for _, z in {-9,9} do
            part("Контрфорс",Vector3.new(4,30,4),origin*CFrame.new(x,15,z),stone)
            part("Зубец",Vector3.new(4,7,4),origin*CFrame.new(x,49,z),stone)
        end
    end
    part("Кристалл над башней",Vector3.new(4,11,4),origin*CFrame.new(0,57,0)*CFrame.Angles(0.4,0.3,0.4),Color3.fromRGB(181,108,248),Enum.Material.Neon,false)
    -- Scenic waterfall and shallow pool; the main road and shrine remain unobstructed.
    for i=1,7 do
        part("Утёс источника",Vector3.new(12,18+i%3*6,14),CFrame.new(98+i*8,7,105)*CFrame.Angles(0,0.2*i,0),stone)
    end
    local water=Color3.fromRGB(91,168,193)
    for i=1,5 do
        local strip=part("Поток водопада",Vector3.new(1.8,25,0.4),CFrame.new(133+i*1.7,13,97),water,Enum.Material.Glass,false)
        strip.Transparency=0.25; CollectionService:AddTag(strip,"EldoriaWater")
    end
    local pool=part("Мелководье",Vector3.new(22,0.12,33),CFrame.new(137,0.22,76),water,Enum.Material.Glass,false)
    pool.Transparency=0.35
    for i=1,10 do
        local a=i*math.pi/5
        part("Береговые валуны",Vector3.new(4,2.2,4),CFrame.new(137+math.cos(a)*13,0.8,76+math.sin(a)*19)*CFrame.Angles(0,i*0.3,0.2),stone)
    end
    for i=1,11 do
        part("Настил мостика",Vector3.new(5,0.5,1.2),CFrame.new(137,0.9,66+i*1.3),Color3.fromRGB(98,74,53),Enum.Material.WoodPlanks)
    end
    for _, x in {134,140} do
        for _, z in {67,81} do part("Опора моста",Vector3.new(0.5,3.5,0.5),CFrame.new(x,1.5,z),Color3.fromRGB(94,65,42),Enum.Material.Wood) end
        part("Перила",Vector3.new(0.35,0.35,14),CFrame.new(x,3,74),Color3.fromRGB(94,65,42),Enum.Material.Wood)
    end
    -- A broken aqueduct gives the burned chapel a different horizon.
    for i=1,5 do
        local x=64+i*10
        part("Остатки акведука",Vector3.new(3,12,3),CFrame.new(x,6,-87),stone,Enum.Material.Brick)
        if i~=3 then part("Перекрытие акведука",Vector3.new(11,2,4),CFrame.new(x+5,13,-87),stone) end
    end
    for i=1,9 do
        part("Обугленная балка",Vector3.new(0.8,0.8,5),CFrame.new(70+i*3,0.7,-52)*CFrame.Angles(0,i*0.75,0.2),Color3.fromRGB(40,34,33),Enum.Material.Wood,false)
    end
    local rng=Random.new(728)
    for i=1,36 do
        local x,z=rng:NextNumber(-70,240),rng:NextNumber(-100,100)
        if math.abs(z)<20 then continue end
        local patch=part("Оттенок почвы",Vector3.new(rng:NextNumber(8,20),0.04,rng:NextNumber(8,18)),CFrame.new(x,0.025,z)*CFrame.Angles(0,rng:NextNumber(0,math.pi),0),Color3.fromRGB(46+i%4*4,64+i%3*4,48),Enum.Material.Grass,false)
        patch.Shape=Enum.PartType.Cylinder; patch.Size=Vector3.new(0.04,patch.Size.Z,patch.Size.X); patch.CFrame*=CFrame.Angles(0,0,math.pi/2)
    end
    for _, item in parent:GetDescendants() do
        if item:IsA("BasePart") and item.Name=="Листва" then CollectionService:AddTag(item,"EldoriaWind") end
    end
end
return Landscape
