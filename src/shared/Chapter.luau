--!strict
-- First location progression. All mutations are invoked by the server only.
local Chapter = {}
export type Progress = {seals: number, caches: number, boss: boolean, finished: boolean}
Chapter.Seals = {
    {Name = "Угольная часовня", Rune = "fire", X = 84, Z = -40},
    {Name = "Лунный источник", Rune = "frost", X = 137, Z = 42},
    {Name = "Обсерватория бури", Rune = "storm", X = 181, Z = -42},
}
function Chapter.ensure(p: any): Progress
    if p.chapter == nil then p.chapter = {seals = 0, caches = 0, boss = false, finished = false} end
    return p.chapter
end
function Chapter.has(mask: number, index: number): boolean
    return math.floor(mask / 2 ^ (index - 1)) % 2 == 1
end
function Chapter.count(mask: number): number
    local total = 0
    for i = 1, 3 do if Chapter.has(mask, i) then total += 1 end end
    return total
end
local function reward(p: any, xp: number, gold: number)
    p.xp = math.min(1000000000, p.xp + xp); p.gold = math.min(1000000000, p.gold + gold)
end
function Chapter.seal(p: any, index: number): string
    local c = Chapter.ensure(p); local definition = Chapter.Seals[index]
    if not definition then return "Неизвестная печать." end
    if p.quest ~= "complete" then return "Сначала выполните поручение Иара и вернитесь к нему." end
    if Chapter.has(c.seals, index) then return "Эта печать уже пробуждена." end
    if p.rune ~= definition.Rune then return "Нужна руна: " .. definition.Rune .. ". Смените руну кнопкой Q." end
    c.seals += 2 ^ (index - 1); reward(p, 40, 20)
    return "Печать пробуждена: " .. Chapter.count(c.seals) .. " / 3. +40 опыта, +20 золота."
end
function Chapter.cache(p: any, index: number): string
    if index ~= 1 and index ~= 2 then return "Неизвестный тайник." end
    local c = Chapter.ensure(p)
    if Chapter.has(c.caches, index) then return "Тайник уже найден этим персонажем." end
    c.caches += 2 ^ (index - 1); reward(p, 25, 25); p.shards = math.min(999, p.shards + 2)
    return "Тайник исследователя: +25 опыта, +25 золота, +2 осколка."
end
function Chapter.canFightBoss(p: any): boolean
    local c = Chapter.ensure(p)
    return p.quest == "complete" and c.seals == 7
end
function Chapter.defeat(p: any): boolean
    if not Chapter.canFightBoss(p) then return false end
    Chapter.ensure(p).boss = true; return true
end
function Chapter.turnIn(p: any): string
    local c = Chapter.ensure(p)
    if c.finished then return "Долина спасена. Исследуйте тайники и совершенствуйте клинок." end
    if not c.boss then return "Пробудите три печати и победите Хранителя у разлома." end
    c.finished = true; reward(p, 250, 150)
    return "ГЛАВА ЗАВЕРШЕНА: Долина первой зари. +250 опыта, +150 золота."
end
function Chapter.objective(p: any): string
    local c = Chapter.ensure(p)
    if p.quest == "available" then return "Поговорите с Иаром в святилище." end
    if p.quest == "active" then return "Победите стражей: " .. p.kills .. " / 3.\nЗатем вернитесь к Иару." end
    if c.finished then return "Долина первой зари спасена!\nТайники: " .. Chapter.count(c.caches) .. " / 2. Клинок можно улучшать дальше." end
    if c.boss then return "Вернитесь к Иару за наградой главы." end
    if c.seals ~= 7 then return "Пробудите печати: " .. Chapter.count(c.seals) .. " / 3.\nЧасовня — огонь; источник — лёд; обсерватория — буря." end
    return "Победите Хранителя у разлома.\nУклоняйтесь из красных кругов!"
end
return Chapter
