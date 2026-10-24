--!strict
-- Pure domain rules: runnable in the standalone Luau VM without Roblox services.
local Rules = {}
export type Profile = {
    version: number, xp: number, gold: number, shards: number, blade: number,
    quest: string, kills: number, rune: string,
}
function Rules.integer(value: any, low: number, high: number): boolean
    return type(value) == "number" and value == value and value % 1 == 0 and value >= low and value <= high
end
function Rules.new(): Profile
    return {version = 1, xp = 0, gold = 0, shards = 0, blade = 0, quest = "available", kills = 0, rune = "fire"}
end
function Rules.validate(value: any): boolean
    if type(value) ~= "table" or value.version ~= 1 then return false end
    for _, key in {"xp", "gold"} do
        if not Rules.integer(value[key], 0, 1000000000) then return false end
    end
    return Rules.integer(value.shards, 0, 999) and Rules.integer(value.blade, 0, 5)
        and Rules.integer(value.kills, 0, 3)
        and (value.quest == "available" or value.quest == "active" or value.quest == "complete")
        and (value.rune == "fire" or value.rune == "frost" or value.rune == "storm")
end
function Rules.level(xp: number): number
    return math.min(200, math.floor(math.sqrt(xp / 50)) + 1)
end
function Rules.threshold(level: number): number
    return 50 * (level - 1) ^ 2
end
function Rules.reward(p: Profile, xp: number, gold: number, shards: number)
    p.xp = math.min(1000000000, p.xp + xp)
    p.gold = math.min(1000000000, p.gold + gold)
    p.shards = math.min(999, p.shards + shards)
    if p.quest == "active" then p.kills = math.min(3, p.kills + 1) end
end
function Rules.quest(p: Profile): string
    if p.quest == "available" then p.quest = "active"; return "Задание принято: победите трёх стражей." end
    if p.quest == "active" and p.kills >= 3 then
        p.quest = "complete"
        p.xp = math.min(1000000000, p.xp + 120)
        p.gold = math.min(1000000000, p.gold + 60)
        return "Разлом сдержан! +120 опыта, +60 золота."
    end
    return if p.quest == "complete" then "Спасибо, защитник Эльдории." else "Победите трёх врагов и вернитесь."
end
function Rules.trade(p: Profile, action: string): string
    if action == "sell" then
        if p.shards < 1 then return "Нет осколков для продажи." end
        p.shards -= 1; p.gold = math.min(1000000000, p.gold + 8)
        return "Осколок продан за 8 золота."
    end
    if action == "upgrade" then
        local cost = 30 * (p.blade + 1)
        if p.blade >= 5 then return "Клинок уже максимального уровня." end
        if p.gold < cost or p.shards < 3 then return "Нужно 3 осколка и " .. cost .. " золота." end
        p.gold -= cost; p.shards -= 3; p.blade += 1
        return "Клинок улучшен до +" .. p.blade .. "."
    end
    return "Неизвестная операция."
end
return Rules
