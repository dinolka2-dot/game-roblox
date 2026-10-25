--!strict
-- Server and UI share one immutable catalogue. No client-defined damage or prices.
local Book = {}
Book.Order = {fire = {"ember", "inferno", "meteor"}, frost = {"lance", "glacier", "nova"}, storm = {"lightning", "cyclone", "tempest"}}
Book.Definitions = {
    ember = {Name = "Огненная комета", Rune = "fire", Kind = "projectile", Cost = 20, Cooldown = 1.8, Windup = 0.3, Damage = 34, Range = 70, Speed = 65, Radius = 3, Duration = 0.5},
    inferno = {Name = "Кольцо пламени", Rune = "fire", Kind = "ring", Cost = 30, Cooldown = 4, Windup = 0.5, Damage = 30, Range = 18, Speed = 25, Radius = 18, Duration = 0.8},
    meteor = {Name = "Падение звезды", Rune = "fire", Kind = "meteor", Cost = 42, Cooldown = 6, Windup = 0.65, Damage = 65, Range = 55, Speed = 65, Radius = 10, Duration = 1.1},
    lance = {Name = "Ледяное копьё", Rune = "frost", Kind = "projectile", Cost = 18, Cooldown = 2, Windup = 0.25, Damage = 25, Range = 70, Speed = 90, Radius = 2, Duration = 0.5},
    glacier = {Name = "Ледниковый разлом", Rune = "frost", Kind = "line", Cost = 32, Cooldown = 4.5, Windup = 0.45, Damage = 34, Range = 30, Speed = 30, Radius = 5, Duration = 1},
    nova = {Name = "Снежная нова", Rune = "frost", Kind = "ring", Cost = 30, Cooldown = 4, Windup = 0.45, Damage = 24, Range = 20, Speed = 28, Radius = 20, Duration = 0.8},
    lightning = {Name = "Цепная молния", Rune = "storm", Kind = "chain", Cost = 26, Cooldown = 2.8, Windup = 0.3, Damage = 32, Range = 55, Speed = 120, Radius = 13, Duration = 0.5},
    cyclone = {Name = "Око бури", Rune = "storm", Kind = "vortex", Cost = 40, Cooldown = 6, Windup = 0.5, Damage = 12, Range = 45, Speed = 30, Radius = 9, Duration = 2.4},
    tempest = {Name = "Грозовой поток", Rune = "storm", Kind = "beam", Cost = 36, Cooldown = 5, Windup = 0.45, Damage = 15, Range = 55, Speed = 120, Radius = 3, Duration = 1.2},
}
function Book.get(rune: string, slot: number)
    local order = (Book.Order :: any)[rune]
    if not order or slot % 1 ~= 0 or slot < 1 or slot > 3 then return nil end
    return (Book.Definitions :: any)[order[slot]]
end
function Book.id(rune: string, slot: number): string?
    local order = (Book.Order :: any)[rune]
    if not order or slot % 1 ~= 0 or slot < 1 or slot > 3 then return nil end
    return order[slot]
end
for _, definition in (Book.Definitions :: any) do table.freeze(definition) end
for _, order in (Book.Order :: any) do table.freeze(order) end
table.freeze(Book.Definitions); table.freeze(Book.Order)
return table.freeze(Book)
