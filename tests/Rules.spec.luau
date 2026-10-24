local Rules = require("../src/shared/Rules")
local total = 0
local function test(name, callback)
    local ok, err = pcall(callback)
    if not ok then error(name .. ": " .. tostring(err)) end
    total += 1; print("PASS " .. name)
end
test("new profile is independently allocated and valid", function()
    local a, b = Rules.new(), Rules.new(); a.gold = 10
    assert(b.gold == 0 and Rules.validate(a))
end)
test("invalid data is rejected rather than silently reset", function()
    assert(not Rules.validate(nil)); assert(not Rules.validate({version = 2}))
    for _, value in {-1, 1.5, math.huge, 0/0, "100"} do
        local p = Rules.new(); p.gold = value; assert(not Rules.validate(p))
    end
    local p = Rules.new(); p.rune = "admin"; assert(not Rules.validate(p))
end)
test("all 200 level thresholds are monotonic and exact", function()
    for level = 1, 200 do
        assert(Rules.level(Rules.threshold(level)) == level)
        if level > 1 then assert(Rules.level(Rules.threshold(level) - 1) == level - 1) end
    end
    assert(Rules.level(1000000000) == 200)
end)
test("kills before accepting a quest do not count", function()
    local p = Rules.new(); Rules.reward(p, 35, 12, 1); assert(p.kills == 0)
end)
test("quest completion rewards exactly once", function()
    local p = Rules.new(); Rules.quest(p)
    Rules.quest(p); assert(p.gold == 0)
    for _ = 1, 3 do Rules.reward(p, 35, 12, 1) end
    assert(p.kills == 3); Rules.quest(p)
    assert(p.quest == "complete" and p.xp == 225 and p.gold == 96)
    for _ = 1, 20 do Rules.quest(p) end
    assert(p.xp == 225 and p.gold == 96)
end)
test("trade is atomic when resources are insufficient", function()
    local p = Rules.new(); p.gold = 100; p.shards = 2
    Rules.trade(p, "upgrade"); assert(p.gold == 100 and p.shards == 2 and p.blade == 0)
    p.gold = 1; p.shards = 5; Rules.trade(p, "upgrade")
    assert(p.gold == 1 and p.shards == 5 and p.blade == 0)
end)
test("upgrade cost scales and maximum cannot be exceeded", function()
    local p = Rules.new(); p.gold = 1000; p.shards = 100
    for _ = 1, 6 do Rules.trade(p, "upgrade") end
    assert(p.blade == 5 and p.gold == 550 and p.shards == 85)
end)
test("repeated sales cannot create negative inventory", function()
    local p = Rules.new(); p.shards = 2
    for _ = 1, 20 do Rules.trade(p, "sell") end
    assert(p.shards == 0 and p.gold == 16)
end)
test("unrecognized trade changes nothing", function()
    local p = Rules.new(); Rules.trade(p, "grant_gold"); assert(p.gold == 0)
end)
test("rewards saturate safely at schema limits", function()
    local p = Rules.new(); p.xp = 1000000000; p.gold = 1000000000; p.shards = 999
    Rules.reward(p, 200, 80, 5); assert(Rules.validate(p))
    assert(p.shards == 999 and p.xp == 1000000000 and p.gold == 1000000000)
end)
print(total .. " tests passed")
