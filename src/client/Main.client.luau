local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Eldoria")
local Rules = require(Shared:WaitForChild("Rules"))
local Config = require(Shared:WaitForChild("Config"))
local remotes = Shared:WaitForChild("Remotes")
local action = remotes:WaitForChild("Action")
local state = remotes:WaitForChild("State")
local notice = remotes:WaitForChild("Notice")
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui"); gui.Name = "EldoriaHUD"; gui.ResetOnSpawn = false
-- Respect device safe areas and the Roblox top bar.
gui.IgnoreGuiInset = false; gui.Parent = player:WaitForChild("PlayerGui")
local canvas = Instance.new("Frame"); canvas.Name = "Canvas"; canvas.BackgroundTransparency = 1
canvas.Size = UDim2.fromOffset(960, 600); canvas.AnchorPoint = Vector2.new(0.5, 0.5)
canvas.Position = UDim2.fromScale(0.5, 0.5); canvas.Parent = gui
local scale = Instance.new("UIScale"); scale.Parent = canvas
local function resize()
    local camera = workspace.CurrentCamera
    if camera then scale.Scale = math.min(camera.ViewportSize.X / 980, math.max(200, camera.ViewportSize.Y - 60) / 600) end
end
resize()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(resize)
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
local gold = Color3.fromRGB(225, 193, 127)
local function panel(name, x, y, w, h)
    local f = Instance.new("Frame"); f.Name = name; f.Position = UDim2.fromOffset(x, y); f.Size = UDim2.fromOffset(w, h)
    f.BackgroundColor3 = Color3.fromRGB(17, 24, 32); f.BackgroundTransparency = 0.12
    f.BorderSizePixel = 0; f.Parent = canvas
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 10); corner.Parent = f
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(77, 88, 94); stroke.Transparency = 0.3; stroke.Parent = f
    return f
end
local function text(parent, value, x, y, w, h, size, color)
    local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Position = UDim2.fromOffset(x, y); t.Size = UDim2.fromOffset(w, h)
    t.Font = Enum.Font.Gotham; t.TextSize = size or 16; t.TextColor3 = color or Color3.fromRGB(228, 232, 231)
    t.TextXAlignment = Enum.TextXAlignment.Left; t.TextWrapped = true; t.Text = value; t.Parent = parent
    return t
end
local function button(parent, label, x, y, w, h, callback)
    local b = Instance.new("TextButton"); b.Position = UDim2.fromOffset(x, y); b.Size = UDim2.fromOffset(w, h)
    b.BackgroundColor3 = Color3.fromRGB(43, 54, 67); b.TextColor3 = gold; b.Font = Enum.Font.GothamBold
    b.TextSize = 15; b.TextWrapped = true; b.Text = label; b.Parent = parent
    local corner = Instance.new("UICorner"); corner.Parent = b
    b.Activated:Connect(callback); return b
end
local stats = panel("Resources", 20, 20, 290, 160)
text(stats, "E L D O R I A", 16, 8, 260, 28, 22, gold)
local level = text(stats, "Загрузка профиля…", 16, 37, 260, 24, 14)
local function bar(y, color)
    local bg = Instance.new("Frame"); bg.Position = UDim2.fromOffset(16, y); bg.Size = UDim2.fromOffset(258, 23)
    bg.BackgroundColor3 = Color3.fromRGB(30, 35, 45); bg.BorderSizePixel = 0; bg.Parent = stats
    local fill = Instance.new("Frame"); fill.Size = UDim2.fromScale(1, 1); fill.BackgroundColor3 = color; fill.BorderSizePixel = 0; fill.Parent = bg
    local label = text(bg, "", 8, 0, 240, 23, 13)
    return function(name, value, maximum)
        fill.Size = UDim2.fromScale(math.clamp(value / maximum, 0, 1), 1)
        label.Text = name .. "  " .. math.ceil(value) .. " / " .. maximum
    end
end
local health = bar(66, Color3.fromRGB(139, 60, 67))
local mana = bar(95, Color3.fromRGB(54, 99, 155))
local stamina = bar(124, Color3.fromRGB(74, 122, 92))
local quest = panel("Quest", 640, 20, 300, 122)
text(quest, "ТРЕЩИНА В ЗАВЕСЕ", 16, 10, 270, 24, 16, gold)
local questText = text(quest, "Найдите хранителя Иара\nв святилище.", 16, 38, 270, 65, 15)
local toast = panel("Notification", 225, 190, 510, 60); toast.Visible = false
local toastText = text(toast, "", 16, 8, 478, 44, 17)
local toastVersion = 0
local function notify(message)
    toastVersion += 1; local id = toastVersion
    toastText.Text = message; toast.Visible = true
    task.delay(4, function() if id == toastVersion then toast.Visible = false end end)
end
notice.OnClientEvent:Connect(notify)
local bag = panel("Inventory", 285, 255, 390, 190); bag.Visible = false
text(bag, "СНАРЯЖЕНИЕ И РЕСУРСЫ", 16, 12, 355, 25, 18, gold)
local bagText = text(bag, "", 16, 43, 355, 132, 16)
local hotbar = panel("Actions", 235, 510, 705, 70)
local rune = "fire"; local blocking = false; local menuOpen = true
local function aim()
    if UIS.TouchEnabled then return nil end
    return player:GetMouse().Hit.Position
end
local function send(kind, payload)
    if menuOpen then return end
    action:FireServer(kind, payload)
end
button(hotbar, "Клинок\nЛКМ", 8, 8, 100, 54, function() send("attack", aim()) end)
local spellButton = button(hotbar, "Огонь\nE", 116, 8, 110, 54, function() send("cast", aim()) end)
button(hotbar, "Уклонение\nR", 234, 8, 110, 54, function() send("dodge") end)
local blockButton
blockButton = button(hotbar, "Блок\nF", 352, 8, 100, 54, function()
    if menuOpen then return end
    blocking = not blocking; send("block", blocking)
    blockButton.Text = if blocking then "Блок: ВКЛ\nF" else "Блок\nF"
end)
button(hotbar, "Руна\nQ", 460, 8, 100, 54, function()
    local nextRune = ({fire = "frost", frost = "storm", storm = "fire"})[rune]
    send("rune", nextRune)
end)
button(hotbar, "Рюкзак\nI", 568, 8, 125, 54, function() bag.Visible = not bag.Visible end)
local menu = panel("Welcome", 220, 175, 520, 300)
text(menu, "E L D O R I A", 30, 25, 460, 45, 34, gold)
text(menu, "Завеса раскололась. Стражи покинули рощу.\nВерните осколки к святилищу и закройте разлом.", 30, 82, 460, 65, 18)
text(menu, "WASD — движение · E — магия · R — уклонение\nF — блок · Q — смена руны · I — рюкзак\nНа телефоне используйте кнопки снизу.", 30, 150, 460, 70, 15)
button(menu, "ВОЙТИ В ЭЛЬДОРИЮ", 80, 235, 360, 45, function()
    menu.Visible = false; menuOpen = false; action:FireServer("sync")
end)
UIS.InputBegan:Connect(function(input, processed)
    if processed or menuOpen or UIS:GetFocusedTextBox() then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then send("attack", aim()); return end
    local key = input.KeyCode
    if key == Enum.KeyCode.E then send("cast", aim())
    elseif key == Enum.KeyCode.R then send("dodge")
    elseif key == Enum.KeyCode.F then
        blocking = not blocking; send("block", blocking)
        blockButton.Text = if blocking then "Блок: ВКЛ\nF" else "Блок\nF"
    elseif key == Enum.KeyCode.Q then send("rune", ({fire = "frost", frost = "storm", storm = "fire"})[rune])
    elseif key == Enum.KeyCode.I then bag.Visible = not bag.Visible end
end)
player.CharacterAdded:Connect(function() blocking = false; blockButton.Text = "Блок\nF" end)
state.OnClientEvent:Connect(function(snapshot)
    local p = snapshot.profile; rune = p.rune
    local currentLevel = Rules.level(p.xp)
    level.Text = "Уровень " .. currentLevel .. " · опыт " .. p.xp .. (if currentLevel < 200 then " / " .. Rules.threshold(currentLevel + 1) else " · MAX")
    health("Здоровье", snapshot.health, snapshot.maxHealth); mana("Мана", snapshot.mana, 100); stamina("Выносливость", snapshot.stamina, 100)
    spellButton.Text = Config.Spells[rune].Name .. "\nE · " .. Config.Spells[rune].Cost .. " маны"
    questText.Text = if p.quest == "available" then "Поговорите с Иаром у святилища."
        elseif p.quest == "complete" then "Разлом сдержан.\nИсследуйте рощу и победите Хранителя."
        else "Победите стражей: " .. p.kills .. " / 3\n" .. (if p.kills >= 3 then "Вернитесь к Иару за наградой." else "Роща находится к востоку от святилища.")
    bagText.Text = "Клинок святилища +" .. p.blade .. " (макс. +5)\nЗолото: " .. p.gold .. "\nОсколки: " .. p.shards .. " / 999\nУлучшение: 3 осколка + " .. (30 * (p.blade + 1)) .. " золота\n" .. (if snapshot.temporary then "STUDIO: прогресс временный, не сохраняется." else "Прогресс сохраняется автоматически.")
end)
-- Connect listeners first; don't rely on the initial server message arriving after UI creation.
action:FireServer("sync")
