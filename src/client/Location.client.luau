local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Eldoria")
local Chapter = require(Shared:WaitForChild("Chapter"))
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui"); gui.Name = "EldoriaLocation"; gui.ResetOnSpawn = false; gui.Parent = player:WaitForChild("PlayerGui")
local map = Instance.new("Frame"); map.Size = UDim2.fromOffset(500, 390); map.AnchorPoint = Vector2.new(0.5, 0.5)
map.Position = UDim2.fromScale(0.5, 0.5); map.BackgroundColor3 = Color3.fromRGB(23, 34, 39)
map.BorderSizePixel = 0; map.Visible = false; map.Parent = gui
local scale = Instance.new("UIScale"); scale.Parent = map
local function resize()
    local camera = workspace.CurrentCamera
    if camera then scale.Scale = math.min(1, (camera.ViewportSize.X-24)/500, (camera.ViewportSize.Y-70)/390) end
end
resize()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
local function label(parent, text, x, y, w, h, size)
    local l = Instance.new("TextLabel"); l.BackgroundTransparency = 1; l.TextColor3 = Color3.fromRGB(231, 219, 179)
    l.Font = Enum.Font.Gotham; l.TextSize = size or 14; l.TextWrapped = true; l.Text = text
    l.Position = UDim2.fromOffset(x,y); l.Size = UDim2.fromOffset(w,h); l.Parent = parent; return l
end
label(map, "ДОЛИНА ПЕРВОЙ ЗАРИ", 20, 10, 460, 30, 21)
label(map, "Карта · M — закрыть · точки обозначают реальные места", 20, 42, 460, 25, 12)
local field = Instance.new("Frame"); field.Position = UDim2.fromOffset(20, 80); field.Size = UDim2.fromOffset(460, 220)
field.BackgroundColor3 = Color3.fromRGB(42, 61, 54); field.BorderSizePixel = 0; field.Parent = map
local function point(x,z) return UDim2.fromScale((x+100)/360,(z+120)/240) end
local road = Instance.new("Frame"); road.BorderSizePixel = 0; road.BackgroundColor3 = Color3.fromRGB(115, 103, 76)
road.Position = point(0,-3); road.Size = UDim2.fromScale(220/360,6/240); road.Parent = field
local function marker(x,z,name,color)
    local dot = Instance.new("TextLabel"); dot.Size = UDim2.fromOffset(14,14); dot.AnchorPoint = Vector2.new(0.5,0.5)
    dot.Position = point(x,z); dot.BackgroundColor3 = color; dot.BorderSizePixel = 0; dot.Text = ""; dot.Parent = field
    local title = label(dot,name,-38,14,90,30,11)
    return dot, title
end
marker(0,0,"Святилище",Color3.fromRGB(220,190,110))
marker(220,0,"Хранитель",Color3.fromRGB(190,95,115))
local seals = {}
for i, seal in Chapter.Seals do
    local dot, title = marker(seal.X,seal.Z,({"Часовня", "Источник", "Обсерватория"})[i],Color3.fromRGB(130,150,180))
    seals[i] = {dot = dot, title = title}
end
local you = marker(0,0,"Вы",Color3.fromRGB(230,240,255)); you.ZIndex = 3
local objective = label(map,"",20,310,460,65,14)
local open = Instance.new("TextButton"); open.Size = UDim2.fromOffset(140,30); open.Position = UDim2.new(1,-155,0,190)
open.BackgroundColor3 = Color3.fromRGB(25,32,45); open.TextColor3 = Color3.fromRGB(220,203,151)
open.TextSize = 13; open.Font = Enum.Font.Gotham; open.Text = "Карта долины · M"; open.Parent = gui
local close = Instance.new("TextButton"); close.Size = UDim2.fromOffset(30,30); close.Position = UDim2.new(1,-35,0,5)
close.Text = "×"; close.TextSize = 22; close.Parent = map
local function toggle() map.Visible = not map.Visible end
open.Activated:Connect(toggle); close.Activated:Connect(function() map.Visible = false end)
UIS.InputBegan:Connect(function(input,processed)
    if not processed and not UIS:GetFocusedTextBox() and input.KeyCode == Enum.KeyCode.M then toggle() end
end)
Shared:WaitForChild("Remotes"):WaitForChild("State").OnClientEvent:Connect(function(snapshot)
    local p = snapshot.profile; local c = Chapter.ensure(p)
    objective.Text = Chapter.objective(p)
    local world = workspace:FindFirstChild("EldoriaWorld")
    local gate = world and world:FindFirstChild("Разлом")
    if gate then
        gate.Transparency = if c.boss then 1 else 0.15
        local light = gate:FindFirstChildOfClass("PointLight")
        if light then light.Enabled = not c.boss end
        local billboard = gate:FindFirstChildOfClass("BillboardGui")
        local caption = billboard and billboard:FindFirstChildOfClass("TextLabel")
        if caption and c.boss then caption.Text = "РАЗЛОМ ЗАКРЫТ\nВернитесь к Иару" end
    end
    for i, view in seals do
        view.dot.BackgroundColor3 = if Chapter.has(c.seals,i) then Color3.fromRGB(117,223,157) else Color3.fromRGB(130,150,180)
    end
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then you.Position = point(root.Position.X,root.Position.Z) end
end)
