local Book = require("../src/shared/Spellbook")
local count = 0
local seen = {}
for rune, order in Book.Order do
    assert(#order == 3)
    for slot,id in order do
        local d = Book.get(rune,slot)
        assert(d == Book.Definitions[id] and d.Rune == rune and Book.id(rune,slot) == id)
        assert(not seen[id]); seen[id] = true
        assert(d.Cost > 0 and d.Cost <= 100 and d.Windup > 0 and d.Cooldown > d.Windup)
        assert(d.Range > 0 and d.Range <= 100 and d.Damage > 0 and d.Duration > 0 and d.Duration < 4)
        assert(table.isfrozen(d))
        count += 1; print("PASS spell definition " .. id)
    end
end
assert(count == 9)
assert(Book.get("unknown",1) == nil)
for _, slot in {0,4,-1,1.5,math.huge,0/0} do assert(Book.get("fire",slot) == nil) end
print("PASS unknown rune and invalid slots rejected")
print("10 spell catalogue checks passed")
